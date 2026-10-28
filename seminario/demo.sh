#!/usr/bin/env bash
# Demonstrações curtas para o seminário (cada uma roda em segundos). Roteiro de fala: seminario/roteiro-demos.md
# Uso (da raiz do repositório, em bash): seminario/demo.sh <preparar|e2|e3|e5|e6|e7|e9|limpar>
#   preparar  sobe os dois clusters e valida (antes da apresentação / da gravação)
#   e2        caminho de uma escrita: put num seguidor; RAFT INDEX e valor nas 3 cópias, antes e depois
#   e3        replicação: watch num membro, put em outro, get no terceiro; valor nas 3 cópias
#   e5        falha: docker kill no líder; tempo de eleição e termo; escrita com 2 de 3; o antigo volta com o dado
#   e6        partição: isola o líder; eleição do lado majoritário; o isolado recusa escrita (deixa isolado para o e7)
#   e7        recuperação: religa o membro isolado no e6; tempo até alcançar o RAFT INDEX; valor nas 3 cópias
#   e9        ZooKeeper: docker kill no líder; tempo de eleição e época do zxid; o antigo volta com o dado
# Cada execução grava valores únicos (com a hora) e termina com um RESUMO dos valores e tempos.
# Os tempos são medidos como nos experimentos: início = evento do `docker events`; fim = observado de dentro da
# rede de clientes, a cada 10 ms (etcd/cliente/e5_eleicao.py, e7_alcance.py; zookeeper/cliente/e9_eleicao.py).
source "$(dirname "$0")/../scripts/lib.sh"
IMG="quay.io/coreos/etcd:v3.5.17"

titulo()    { printf '\n\033[1;33m=== %s ===\033[0m\n' "$*"; }
mostra()    { printf '\033[1;32m$ %s\033[0m\n' "$*"; }        # imprime o comando antes de rodá-lo
resultado() { printf '\033[1;36m>>> %s\033[0m\n' "$*"; }      # destaca um valor ou resultado
resumo() {
  printf '\n\033[1;35m━━━━━━━━━━━━━━━━━━━━━━━━━━ RESUMO ━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n'
  local l; for l in "$@"; do printf '\033[1;35m  %s\033[0m\n' "$l"; done
  printf '\033[1;35m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n'
}
pausa() { sleep "${PAUSA:-1}"; }
status() { mostra "etcdctl endpoint status -w table"; docker exec "${1:-etcd1}" etcdctl --endpoints="$EP" --command-timeout=3s endpoint status -w table 2>/dev/null; }
indices() {  # RAFT INDEX de cada membro que responde: "etcd1=10 etcd2=10 etcd3=10"
  docker exec "${1:-etcd1}" etcdctl --endpoints="$EP" --command-timeout=3s endpoint status -w simple 2>/dev/null \
    | awk -F', ' '{print $1"="$8}' | sed 's/172.31.0.31:2379/etcd1/;s/172.31.0.32:2379/etcd2/;s/172.31.0.33:2379/etcd3/' | tr '\n' ' '
}
termo_de() {  # termo Raft informado pelo próprio membro
  docker exec "$1" etcdctl --endpoints=127.0.0.1:2379 --command-timeout=3s endpoint status -w simple 2>/dev/null | awk -F', ' '{print $7}'
}
vivo() { [ "$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null)" = true ]; }
seguidor_de() { local m; for m in "${ETCD_MEMBROS[@]}"; do [ "$m" != "$1" ] && [ "$m" != "$2" ] && { echo "$m"; return; }; done; }
isolado() {  # membro etcd fora da rede interna (se houver)
  local m; for m in "${ETCD_MEMBROS[@]}"; do
    docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' "$m" | grep -q t5-etcd_interna || { echo "$m"; return; }
  done
}
ectl1() { local m="$1"; shift; docker exec "$m" etcdctl --endpoints=127.0.0.1:2379 --command-timeout=3s "$@" 2>&1 | tail -1; }
copias() {  # copias <chave>: valor na cópia local de cada membro (leitura serializável); guarda o resumo em COPIAS
  local k="$1" m v r=""
  mostra "etcdctl get $k --consistency=s   (cópia local de cada nó, sem consultar o líder)"
  for m in "${ETCD_MEMBROS[@]}"; do
    if vivo "$m"; then v="$(ectl1 "$m" get "$k" --print-value-only --consistency=s)"; v="${v:-(não existe)}"; else v="(desligado)"; fi
    resultado "$m: $k = $v"; r="$r${r:+ | }$m=$v"
  done
  COPIAS="$r"
}
esperar_etcd() { info "aguardando ${1:-o cluster} voltar e o etcd ficar saudável..."; local i; for i in $(seq 1 40); do bash "$RAIZ/scripts/validar.sh" etcd >/dev/null 2>&1 && return 0; sleep 1; done; }
esperar_zk()   { info "aguardando ${1:-o ensemble} voltar e o ZooKeeper ficar saudável..."; local i; for i in $(seq 1 60); do bash "$RAIZ/scripts/validar.sh" zk >/dev/null 2>&1 && return 0; sleep 1; done; }

# observador de dentro da rede de clientes: observar <contêiner-cliente> <script.py> [args]; depois da ação, fim_observar
observar() { OBS="$(mktemp)"; docker exec "$1" python "${@:2}" > "$OBS" 2>&1 & OBS_PID=$!; sleep 1.5; DESDE=$(( $(date +%s) - 30 )); }
fim_observar() { wait "$OBS_PID"; RES="$(grep '^RES' "$OBS")"; rm -f "$OBS"; }

# ZooKeeper via kazoo: zk <ip> set <caminho> <valor> | zk <ip> local <caminho> (leitura da cópia local, sem sync)
zk() {
  docker exec zk-cliente python -c '
import sys, logging
logging.disable(logging.CRITICAL)
from kazoo.client import KazooClient
ip, op, caminho = sys.argv[1], sys.argv[2], sys.argv[3]
c = KazooClient(hosts=ip + ":2181", timeout=5)
try:
    c.start(timeout=5)
    if op == "set":
        c.ensure_path(caminho); c.set(caminho, sys.argv[4].encode()); print("OK")
    else:
        print(c.get(caminho)[0].decode())
except Exception as e:
    print("ERRO", type(e).__name__)
finally:
    try: c.stop()
    except Exception: pass
' "$@" 2>/dev/null
}
zk_copias() {  # zk_copias <caminho>: valor na cópia local de cada servidor; guarda o resumo em COPIAS
  local k="$1" s v r=""
  mostra "get $k em cada servidor (leitura local, sem sync)"
  for s in "${ZK_SERVIDORES[@]}"; do
    if vivo "$s"; then v="$(zk "${ZK_IP_CLIENTE[$s]}" local "$k")"; else v="(desligado)"; fi
    resultado "$s: $k = $v"; r="$r${r:+ | }$s=$v"
  done
  COPIAS="$r"
}
srvr() { mostra "srvr (modo, zxid, época e contador de cada servidor)"; docker exec zk-cliente python /app/srvr.py; }

preparar() {
  titulo "subindo os clusters"
  docker compose -f "$(caminho_host "$RAIZ/etcd/docker-compose.yml")" up -d
  docker compose -f "$(caminho_host "$RAIZ/zookeeper/docker-compose.yml")" up -d
  info "aguardando o cliente do ZooKeeper (kazoo)"
  local i; for i in $(seq 1 40); do docker exec zk-cliente python -c "import kazoo" 2>/dev/null && break; sleep 1; done
  bash "$RAIZ/scripts/validar.sh" todos
}

e2() {
  local L S v rev term mid antes ia id
  L="$(etcd_lider)"; S="$(seguidor_de "$L")"; v="producao-$(date +%H%M%S)"
  titulo "E2: caminho de uma escrita (líder = $L; escrevendo no seguidor $S)"
  status; ia="$(indices)"
  copias /demo/modo; antes="$COPIAS"
  pausa
  mostra "docker exec $S etcdctl --endpoints=${ETCD_IP_CLIENTE[$S]}:2379 put /demo/modo $v -w json"
  read -r rev term mid < <(docker exec "$S" etcdctl --endpoints="${ETCD_IP_CLIENTE[$S]}:2379" put /demo/modo "$v" -w json \
    | "$PY" -c "import json,sys; h=json.load(sys.stdin)['header']; print(h['revision'], h['raft_term'], format(int(h['member_id']), 'x'))")
  resultado "resposta: OK | revision $rev | raft_term $term"
  pausa; status; id="$(indices)"
  copias /demo/modo
  resumo "líder: $L (termo $term); escrita enviada ao seguidor $S" \
         "RAFT INDEX antes:  $ia" \
         "RAFT INDEX depois: $id" \
         "valor antes:  $antes" \
         "valor depois: $COPIAS"
}

e3() {
  local A=etcd1 B=etcd2 C=etcd3 valor lido evento
  titulo "E3: replicação: watch em $C, put em $A, get em $B"
  docker rm -f demo-watch >/dev/null 2>&1
  mostra "etcdctl --endpoints=${ETCD_IP_CLIENTE[$C]}:2379 watch /demo/cor   (em segundo plano)"
  docker run -d --rm --name demo-watch --network t5-etcd_clientes "$IMG" \
    etcdctl --endpoints="${ETCD_IP_CLIENTE[$C]}:2379" watch /demo/cor >/dev/null
  sleep 1.5
  valor="azul-$(date +%H%M%S)"
  mostra "etcdctl --endpoints=${ETCD_IP_CLIENTE[$A]}:2379 put /demo/cor $valor"
  docker exec "$A" etcdctl --endpoints="${ETCD_IP_CLIENTE[$A]}:2379" put /demo/cor "$valor"
  mostra "etcdctl --endpoints=${ETCD_IP_CLIENTE[$B]}:2379 get /demo/cor --print-value-only"
  lido="$(docker exec "$B" etcdctl --endpoints="${ETCD_IP_CLIENTE[$B]}:2379" get /demo/cor --print-value-only)"
  resultado "$B leu: $lido"
  sleep 0.5
  mostra "saída do watch em $C"
  evento="$(docker logs demo-watch 2>&1 | tr '\n' ' ')"
  resultado "$C recebeu: $evento"
  docker rm -f demo-watch >/dev/null 2>&1
  copias /demo/cor
  resumo "escrito em $A: $valor" \
         "lido em $B: $lido" \
         "aviso do watch em $C: $evento" \
         "cópias: $COPIAS"
}

e5() {
  local L S q n ta td la ln h t r antes depois
  L="$(etcd_lider)"; S="$(seguidor_de "$L")"; h="$(date +%H%M%S)"
  titulo "E5: falha do líder ($L) com docker kill"
  status
  mostra "docker exec $L etcdctl put /demo/falha antes-$h"
  ectl1 "$L" put /demo/falha "antes-$h"
  copias /demo/falha; antes="$COPIAS"
  ta="$(termo_de "$L")"
  pausa
  observar etcd-cliente /app/e5_eleicao.py
  mostra "docker kill $L"
  docker kill "$L" >/dev/null
  fim_observar
  read -r _ q n _ _ la ln <<< "$RES"
  td="$(termo_de "$ln")"
  t="$(ms_entre "$(evento_epoch "$L" kill "$DESDE")" "$n")"
  resultado "líder antigo: $la (termo $ta)   →   novo líder: $ln (termo $td)"
  resultado "tempo de eleição: $t ms (do docker kill até um sobrevivente anunciar o novo líder)"
  status "$S"
  mostra "docker exec $ln etcdctl put /demo/falha depois-$h   (só 2 de 3 nós vivos)"
  r="$(ectl1 "$ln" put /demo/falha "depois-$h")"; resultado "resposta: $r"
  copias /demo/falha
  pausa
  mostra "docker start $L"
  docker start "$L" >/dev/null; esperar_etcd "$L"
  status
  copias /demo/falha; depois="$COPIAS"
  resumo "líder: $la (termo $ta) → $ln (termo $td)" \
         "tempo de eleição: $t ms" \
         "antes da queda: $antes" \
         "escrita depois-$h com 2 de 3 nós vivos: $r" \
         "depois que $L voltou: $depois"
}

e6() {
  local L S O q n ta td la ln h t rp rg rw
  [ -n "$(isolado)" ] && { erro "já existe membro isolado: rode 'seminario/demo.sh e7' antes"; return 1; }
  L="$(etcd_lider)"; S="$(seguidor_de "$L")"; O="$(seguidor_de "$L" "$S")"; h="$(date +%H%M%S)"
  titulo "E6: partição: isolando o líder $L da rede interna"
  mostra "docker exec $L etcdctl put /demo/k ANTIGO-$h"
  ectl1 "$L" put /demo/k "ANTIGO-$h"
  copias /demo/k
  ta="$(termo_de "$L")"
  pausa
  observar etcd-cliente /app/e5_eleicao.py --particao
  mostra "docker network disconnect t5-etcd_interna $L"
  bash "$RAIZ/scripts/particionar.sh" isolar "$L" >/dev/null
  fim_observar
  read -r _ q n _ _ la ln <<< "$RES"
  td="$(termo_de "$ln")"
  t="$(ms_entre "$(evento_epoch "$L" disconnect "$DESDE")" "$n")"
  resultado "líder antigo (isolado): $la (termo $ta)   →   novo líder da maioria: $ln (termo $td)"
  resultado "tempo de eleição do lado majoritário: $t ms (a partir da desconexão)"
  titulo "lado minoritário ($L, sozinho)"
  mostra "docker exec $L etcdctl put /demo/k ISOLADO-$h"
  rp="$(ectl1 "$L" put /demo/k "ISOLADO-$h")"; resultado "resposta: $rp"
  mostra "docker exec $L etcdctl get /demo/k   (leitura linearizável: precisa da maioria)"
  rg="$(ectl1 "$L" get /demo/k --print-value-only)"; resultado "resposta: $rg"
  titulo "lado majoritário ($S e $O; novo líder: $ln)"
  mostra "docker exec $S etcdctl put /demo/k NOVO-$h"
  rw="$(ectl1 "$S" put /demo/k "NOVO-$h")"; resultado "resposta: $rw"
  status "$S"
  copias /demo/k
  resumo "líder antigo isolado: $la (termo $ta); novo líder da maioria: $ln (termo $td)" \
         "tempo de eleição do lado majoritário: $t ms" \
         "isolado: escrita ISOLADO-$h → $rp; leitura → $rg" \
         "maioria: escrita NOVO-$h → $rw" \
         "cópias: $COPIAS"
  info "$L continua isolado: rode 'seminario/demo.sh e7' para religar"
}

e7() {
  local X rc al i0 o0 ti tf t
  X="$(isolado)"; [ -n "$X" ] || { erro "nenhum membro isolado: rode 'seminario/demo.sh e6' antes"; return 1; }
  titulo "E7: recuperação: religando $X"
  status
  observar etcd-cliente /app/e7_alcance.py --alvo "$X"
  mostra "docker network connect --ip ${ETCD_IP_INTERNA[$X]} t5-etcd_interna $X"
  bash "$RAIZ/scripts/particionar.sh" religar "$X" >/dev/null
  fim_observar
  read -r _ rc al i0 o0 ti tf <<< "$RES"
  t="$(ms_entre "$(evento_epoch "$X" connect "$DESDE")" "$al")"
  resultado "$X: termo $ti → $tf; RAFT INDEX $i0 → alcançou os outros (que estavam em $o0)"
  resultado "tempo até alcançar: $t ms (da religação até ter o mesmo RAFT INDEX)"
  esperar_etcd "$X"
  status
  copias /demo/k
  resumo "$X voltou como seguidor: termo $ti → $tf" \
         "RAFT INDEX: $(indices)" \
         "tempo até alcançar: $t ms" \
         "cópias: $COPIAS"
}

e9() {
  local L S q n ea ed la ln h t r antes depois
  read -r L S _ < <(zk_papeis); h="$(date +%H%M%S)"
  titulo "E9: ZooKeeper: falha do líder ($L) com docker kill"
  srvr
  mostra "set /demo/zk antes-$h   (no líder $L)"
  zk "${ZK_IP_CLIENTE[$L]}" set /demo/zk "antes-$h"
  zk_copias /demo/zk; antes="$COPIAS"
  pausa
  observar zk-cliente /app/e9_eleicao.py
  mostra "docker kill $L"
  docker kill "$L" >/dev/null
  fim_observar
  read -r _ q n ea ed la ln <<< "$RES"
  t="$(ms_entre "$(evento_epoch "$L" kill "$DESDE")" "$n")"
  resultado "líder antigo: $la (época $ea)   →   novo líder: $ln (época $ed)"
  resultado "tempo de eleição: $t ms (do docker kill até um sobrevivente virar leader)"
  srvr
  mostra "set /demo/zk depois-$h   (no novo líder $ln, com 2 de 3 servidores)"
  r="$(zk "${ZK_IP_CLIENTE[$ln]}" set /demo/zk "depois-$h")"; resultado "resposta: $r"
  zk_copias /demo/zk
  pausa
  mostra "docker start $L"
  docker start "$L" >/dev/null; esperar_zk "$L"
  srvr
  zk_copias /demo/zk; depois="$COPIAS"
  resumo "líder: $la (época $ea) → $ln (época $ed)" \
         "tempo de eleição: $t ms" \
         "antes da queda: $antes" \
         "escrita depois-$h com 2 de 3 servidores: $r" \
         "depois que $L voltou: $depois"
}

limpar() {  # deixa os dois clusters como estavam, caso uma demo seja interrompida
  local X; X="$(isolado)"; [ -n "$X" ] && bash "$RAIZ/scripts/particionar.sh" religar "$X"
  docker rm -f demo-watch >/dev/null 2>&1
  local c; for c in etcd1 etcd2 etcd3 zk1 zk2 zk3; do vivo "$c" || docker start "$c" >/dev/null; done
  sleep 3; bash "$RAIZ/scripts/validar.sh" todos
}

case "${1:-}" in
  preparar|e2|e3|e5|e6|e7|e9|limpar) "$1" ;;
  *) sed -n '2,13p' "$0"; exit 2 ;;
esac
