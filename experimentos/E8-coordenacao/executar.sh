#!/usr/bin/env bash
# E8: coordenação e ordem no etcd.
#   1. relógios lógicos: revisão (ordem total das escritas em todas as chaves) e termos colhidos em E5–E7;
#   2. trava (`etcdctl lock`) e eleição (`etcdctl elect`) com dois competidores, cada um num contêiner leve
#      próprio (mesma imagem do etcd, 64 MB); o contêiner do detentor é derrubado com docker kill e mede-se
#      até o outro assumir (t0 = evento kill; t1 = linha do B no `docker logs --timestamps`), 5 repetições;
#      mais 1 repetição com docker stop (parada ordenada) para comparar;
#   3. S4: pausa longa do detentor e fencing token (e8_fencing.py).
# Uso (da raiz do repositório): experimentos/E8-coordenacao/executar.sh
source "$(dirname "$0")/../../scripts/lib.sh"
DIR="$RAIZ/experimentos/E8-coordenacao"
N="${N:-5}"
IMG="quay.io/coreos/etcd:v3.5.17"

if ! bash "$RAIZ/scripts/validar.sh" etcd; then erro "cluster não saudável: E8 abortado"; exit 1; fi

# 1. revisão como relógio lógico global + termos observados nos experimentos anteriores
relogios() {
  local k
  echo "--- 6 escritas alternando 3 chaves: a revisão cresce uma única sequência para todas"
  for k in /e8/a /e8/b /e8/c /e8/a /e8/b /e8/c; do
    docker exec etcd1 etcdctl --endpoints="$EP" put "$k" "x" -w json | "$PY" -c \
      "import json,sys; h=json.load(sys.stdin)['header']; print('$k', 'revision', h['revision'], 'raft_term', h['raft_term'])"
  done
  echo "--- mod_revision / create_revision / version de cada chave"
  for k in /e8/a /e8/b /e8/c; do
    docker exec etcd1 etcdctl --endpoints="$EP" get "$k" -w json | "$PY" -c \
      "import json,sys; kv=json.load(sys.stdin)['kvs'][0]; print('$k', 'create', kv['create_revision'], 'mod', kv['mod_revision'], 'version', kv['version'])"
  done
  echo "--- termos antes/depois de cada troca de líder (CSVs de E5, E6 e E7)"
  for f in "$RAIZ"/resultados/*_e5_eleicao_*.csv "$RAIZ"/resultados/*_e6_eleicao_particao.csv "$RAIZ"/resultados/*_e7_recuperacao.csv; do
    [ -f "$f" ] && { echo "## ${f##*/}"; cat "$f"; }
  done
  docker exec etcd1 etcdctl --endpoints="$EP" endpoint status -w table
}
evidencia "$DIR" relogios_logicos -- relogios

# 2. troca do detentor
competidor() {  # competidor <nome-do-contêiner> <args do etcdctl...>
  local nome="$1"; shift
  docker run -d --rm --name "$nome" --memory 64m --network t5-etcd_clientes "$IMG" \
    etcdctl --endpoints="$EP" "$@" >/dev/null
}
primeira_linha_epoch() {  # época (s) da 1ª linha de saída de um contêiner, no relógio do Docker
  local ts; ts="$(docker logs --timestamps "$1" 2>&1 | head -1 | cut -d' ' -f1)"
  [ -n "$ts" ] && date -d "$ts" +%s.%N
}
esperar_saida() {  # esperar_saida <contêiner> <segundos>
  local i; for i in $(seq 1 $(( $2 * 4 ))); do
    [ -n "$(docker logs "$1" 2>&1 | head -1)" ] && return 0; sleep 0.25
  done; return 1
}
# troca <lock|elect> <kill|stop> <rep> <csv>
troca() {
  local tipo="$1" modo="$2" r="$3" csv="$4" desde t0 t1 d argsA argsB
  if [ "$tipo" = lock ]; then argsA=(lock /e8/trava); argsB=(lock /e8/trava)
  else argsA=(elect /e8/eleicao candidatoA); argsB=(elect /e8/eleicao candidatoB); fi
  competidor e8-A "${argsA[@]}"
  esperar_saida e8-A 10 || { erro "A não obteve $tipo"; docker rm -f e8-A >/dev/null 2>&1; return 1; }
  competidor e8-B "${argsB[@]}"
  sleep 2
  if [ "$r" = 1 ]; then
    echo "--- A detém ($(docker logs e8-A 2>&1 | head -2 | tr '\n' ' ')); B saída até agora: '$(docker logs e8-B 2>&1)'"
    echo "--- chaves da fila (ordem = create_revision; vence a menor)"
    docker exec etcd1 etcdctl --endpoints="$EP" get "${argsA[1]}" --prefix -w json | "$PY" -c \
      "import json,sys,base64; [print(base64.b64decode(k['key']).decode(), 'create_revision', k['create_revision'], 'lease', format(int(k['lease']), 'x')) for k in json.load(sys.stdin).get('kvs', [])]"
  fi
  desde=$(( $(date +%s) - 30 ))
  docker "$modo" e8-A >/dev/null
  # elect não tem --ttl: a sessão usa o TTL padrão de 60 s (lock: --ttl=10); espera até 75 s
  if esperar_saida e8-B 75; then
    t0="$(evento_epoch e8-A kill "$desde")"; t1="$(primeira_linha_epoch e8-B)"; d="$(ms_entre "$t0" "$t1")"
    echo "$r,$(date -d "@${t0%.*}" +%Y-%m-%dT%H:%M:%S),$d,0,$tipo,$modo,$(docker logs e8-B 2>&1 | head -1)" | tee -a "$csv"
  else
    echo "$r,$(date +%Y-%m-%dT%H:%M:%S),nan,1,$tipo,$modo," | tee -a "$csv"
  fi
  docker rm -f e8-A e8-B >/dev/null 2>&1
  # o rm -f não revoga o lease de B: apaga as chaves da fila para a próxima repetição começar vazia
  docker exec etcd1 etcdctl --endpoints="$EP" del --prefix "${argsA[1]}/" >/dev/null
  sleep 1
}
medir_trocas() {
  local tipo csv r
  for tipo in lock elect; do
    csv="$RAIZ/resultados/$(ts)_e8_troca_${tipo}_kill.csv"
    echo "rep,inicio_iso,duracao_ms,exit,tipo,modo,saida_B" > "$csv"
    for r in $(seq 1 "$N"); do troca "$tipo" kill "$r" "$csv"; done
    "$PY" "$(caminho_host "$RAIZ/scripts/estatistica.py")" "$(caminho_host "$csv")"
    csv="$RAIZ/resultados/$(ts)_e8_troca_${tipo}_stop.csv"
    echo "rep,inicio_iso,duracao_ms,exit,tipo,modo,saida_B" > "$csv"
    troca "$tipo" stop 1 "$csv"
  done
}
evidencia "$DIR" troca_detentor -- medir_trocas

# 3. S4: fencing token
evidencia "$DIR" fencing_token -- docker exec etcd-cliente python /app/e8_fencing.py --ttl 5 --pausa 9

evidencia "$DIR" validacao_final -- bash "$RAIZ/scripts/validar.sh" etcd
