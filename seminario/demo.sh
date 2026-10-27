#!/usr/bin/env bash
# Demonstrações curtas para o seminário (cada uma roda em segundos). Roteiro de fala: seminario/roteiro-demos.md
# Uso (da raiz do repositório, em bash): seminario/demo.sh <preparar|e2|e3|e5|e6|e7|e9|limpar>
#   preparar  sobe os dois clusters e valida (antes da apresentação / da gravação)
#   e2        caminho de uma escrita: put num seguidor, revisão/termo, RAFT INDEX avançando nos 3
#   e3        replicação: watch num membro, put em outro, get no terceiro
#   e5        falha: docker kill no líder, novo líder com termo maior; religa o antigo
#   e6        partição: isola o líder; o isolado recusa escrita, a maioria elege outro (deixa isolado para o e7)
#   e7        recuperação: religa o membro isolado no e6; volta como seguidor e alcança o RAFT INDEX
#   e9        ZooKeeper: docker kill no líder, novo líder com época maior no zxid; religa o antigo
source "$(dirname "$0")/../scripts/lib.sh"
IMG="quay.io/coreos/etcd:v3.5.17"

titulo() { printf '\n\033[1;33m=== %s ===\033[0m\n' "$*"; }
mostra() { printf '\033[1;32m$ %s\033[0m\n' "$*"; }   # imprime o comando antes de rodá-lo
pausa()  { sleep "${PAUSA:-1}"; }
status() { mostra "etcdctl endpoint status -w table"; docker exec etcd1 etcdctl --endpoints="$EP" --command-timeout=3s endpoint status -w table 2>/dev/null; }
seguidor_de() { local m; for m in "${ETCD_MEMBROS[@]}"; do [ "$m" != "$1" ] && [ "$m" != "$2" ] && { echo "$m"; return; }; done; }
isolado() {  # membro etcd fora da rede interna (se houver)
  local m; for m in "${ETCD_MEMBROS[@]}"; do
    docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' "$m" | grep -q t5-etcd_interna || { echo "$m"; return; }
  done
}

preparar() {
  titulo "subindo os clusters"
  docker compose -f "$(caminho_host "$RAIZ/etcd/docker-compose.yml")" up -d
  docker compose -f "$(caminho_host "$RAIZ/zookeeper/docker-compose.yml")" up -d
  info "aguardando o cliente do ZooKeeper (kazoo)"
  local i; for i in $(seq 1 40); do docker exec zk-cliente python -c "import kazoo" 2>/dev/null && break; sleep 1; done
  bash "$RAIZ/scripts/validar.sh" todos
}

e2() {
  local L S; L="$(etcd_lider)"; S="$(seguidor_de "$L")"
  titulo "E2: caminho de uma escrita (líder = $L; escrevendo no seguidor $S)"
  status; pausa
  mostra "docker exec $S etcdctl --endpoints=${ETCD_IP_CLIENTE[$S]}:2379 put /demo/modo producao -w json"
  docker exec "$S" etcdctl --endpoints="${ETCD_IP_CLIENTE[$S]}:2379" put /demo/modo producao -w json \
    | "$PY" -c "import json,sys; h=json.load(sys.stdin)['header']; print('resposta: revision', h['revision'], '| raft_term', h['raft_term'], '| respondido pelo membro', format(int(h['member_id']), 'x'))"
  pausa; status
  info "o seguidor $S encaminhou ao líder $L, que replicou aos dois; o RAFT INDEX subiu igual nos 3"
}

e3() {
  local A=etcd1 B=etcd2 C=etcd3
  titulo "E3: replicação: watch em $C, put em $A, get em $B"
  docker rm -f demo-watch >/dev/null 2>&1
  mostra "etcdctl --endpoints=${ETCD_IP_CLIENTE[$C]}:2379 watch /demo/cor   (em segundo plano)"
  docker run -d --rm --name demo-watch --network t5-etcd_clientes "$IMG" \
    etcdctl --endpoints="${ETCD_IP_CLIENTE[$C]}:2379" watch /demo/cor >/dev/null
  sleep 1.5
  local valor="azul-$(date +%H%M%S)"
  mostra "etcdctl --endpoints=${ETCD_IP_CLIENTE[$A]}:2379 put /demo/cor $valor"
  docker exec "$A" etcdctl --endpoints="${ETCD_IP_CLIENTE[$A]}:2379" put /demo/cor "$valor"
  mostra "etcdctl --endpoints=${ETCD_IP_CLIENTE[$B]}:2379 get /demo/cor"
  docker exec "$B" etcdctl --endpoints="${ETCD_IP_CLIENTE[$B]}:2379" get /demo/cor
  sleep 0.5
  mostra "saída do watch em $C"
  docker logs demo-watch 2>&1
  docker rm -f demo-watch >/dev/null 2>&1
  info "escrito em $A, lido em $B e notificado em $C"
}

e5() {
  local L N i
  L="$(etcd_lider)"
  titulo "E5: falha do líder ($L) com docker kill"
  status; pausa
  mostra "docker kill $L"
  docker kill "$L" >/dev/null
  for i in $(seq 1 100); do
    N="$(docker exec "$(seguidor_de "$L")" etcdctl --endpoints="$EP" --command-timeout=1s endpoint status -w simple 2>/dev/null | awk -F', ' '$5=="true"{print $1}')"
    [ -n "$N" ] && break; sleep 0.1
  done
  info "novo líder eleito, termo +1 (tempo de eleição medido no E5: 1,46 ± 0,18 s, n = 5):"
  docker exec "$(seguidor_de "$L")" etcdctl --endpoints="$EP" --command-timeout=2s endpoint status -w table 2>/dev/null
  pausa
  mostra "docker start $L"
  docker start "$L" >/dev/null; sleep 3
  status
  info "$L voltou como seguidor"
}

e6() {
  local L S
  [ -n "$(isolado)" ] && { erro "já existe membro isolado: rode 'seminario/demo.sh e7' antes"; return 1; }
  L="$(etcd_lider)"; S="$(seguidor_de "$L")"
  titulo "E6: partição: isolando o líder $L da rede interna"
  mostra "docker exec $L etcdctl put /demo/k ANTIGO"
  docker exec "$L" etcdctl --endpoints=127.0.0.1:2379 put /demo/k ANTIGO
  mostra "docker network disconnect t5-etcd_interna $L"
  bash "$RAIZ/scripts/particionar.sh" isolar "$L" >/dev/null
  sleep 3
  titulo "lado minoritário ($L, sozinho)"
  mostra "docker exec $L etcdctl put /demo/k ISOLADO"
  docker exec "$L" etcdctl --endpoints=127.0.0.1:2379 --command-timeout=3s put /demo/k ISOLADO 2>&1 | tail -1
  mostra "docker exec $L etcdctl get /demo/k --consistency=s   (serializável: cópia local)"
  docker exec "$L" etcdctl --endpoints=127.0.0.1:2379 --command-timeout=3s get /demo/k --print-value-only --consistency=s 2>&1 | tail -1
  titulo "lado majoritário ($S)"
  mostra "docker exec $S etcdctl put /demo/k NOVO"
  docker exec "$S" etcdctl --endpoints=127.0.0.1:2379 --command-timeout=3s put /demo/k NOVO 2>&1 | tail -1
  mostra "etcdctl endpoint status -w table   (visto pelo lado majoritário + o isolado)"
  docker exec "$S" etcdctl --endpoints="$EP" --command-timeout=2s endpoint status -w table 2>&1 | grep -v '^{'
  info "a maioria elegeu outro líder com termo maior; o isolado não é mais líder e recusou a escrita (C, não A)"
  info "$L continua isolado: rode 'seminario/demo.sh e7' para religar"
}

e7() {
  local X t0 i a b
  X="$(isolado)"; [ -n "$X" ] || { erro "nenhum membro isolado: rode 'seminario/demo.sh e6' antes"; return 1; }
  titulo "E7: recuperação: religando $X"
  mostra "docker network connect --ip ${ETCD_IP_INTERNA[$X]} t5-etcd_interna $X"
  t0="$(agora_ms)"
  bash "$RAIZ/scripts/particionar.sh" religar "$X" >/dev/null
  for i in $(seq 1 150); do
    if docker exec etcd1 etcdctl --endpoints="$EP" --command-timeout=1s endpoint status -w simple 2>/dev/null \
       | awk -F', ' '{print $8}' | sort -u | wc -l | grep -qx 1; then
      a="$(docker exec "$X" etcdctl --endpoints=127.0.0.1:2379 get /demo/k --print-value-only --consistency=s 2>/dev/null)"
      [ "$a" = NOVO ] && break
    fi
    sleep 0.2
  done
  info "$X alcançou os outros em cerca de $(( $(agora_ms) - t0 )) ms (no host; medido no E7: cerca de 6,5 s em 4 de 5, quase todo de reconexão)"
  status
  mostra "docker exec $X etcdctl get /demo/k --consistency=s   (no membro religado)"
  docker exec "$X" etcdctl --endpoints=127.0.0.1:2379 get /demo/k --print-value-only --consistency=s
  info "$X voltou como seguidor, com o termo novo, o mesmo RAFT INDEX e o valor NOVO; a escrita ISOLADO nunca existiu"
}

e9() {
  local L N i
  read -r L _ < <(zk_papeis)
  titulo "E9: ZooKeeper: falha do líder ($L) com docker kill"
  mostra "srvr (modo, zxid, época)"; docker exec zk-cliente python /app/srvr.py; pausa
  mostra "docker kill $L"
  docker kill "$L" >/dev/null
  for i in $(seq 1 100); do read -r N _ < <(zk_papeis); [ -n "$N" ] && [ "$N" != "$L" ] && break; sleep 0.1; done
  info "novo líder: $N; a época do zxid subiu 1 (eleição medida no E9-E5: 0,38 ± 0,09 s, contra 1,46 s no etcd):"
  docker exec zk-cliente python /app/srvr.py
  pausa
  mostra "docker start $L"
  docker start "$L" >/dev/null
  for i in $(seq 1 60); do bash "$RAIZ/scripts/validar.sh" zk >/dev/null 2>&1 && break; sleep 1; done
  docker exec zk-cliente python /app/srvr.py
  info "$L voltou como seguidor (follower) na época nova"
}

limpar() {  # deixa os dois clusters como estavam, caso uma demo seja interrompida
  local X; X="$(isolado)"; [ -n "$X" ] && bash "$RAIZ/scripts/particionar.sh" religar "$X"
  docker rm -f demo-watch >/dev/null 2>&1
  local c; for c in etcd1 etcd2 etcd3 zk1 zk2 zk3; do
    [ "$(docker inspect -f '{{.State.Running}}' "$c" 2>/dev/null)" = true ] || docker start "$c" >/dev/null
  done
  sleep 3; bash "$RAIZ/scripts/validar.sh" todos
}

case "${1:-}" in
  preparar|e2|e3|e5|e6|e7|e9|limpar) "$1" ;;
  *) sed -n '2,12p' "$0"; exit 2 ;;
esac
