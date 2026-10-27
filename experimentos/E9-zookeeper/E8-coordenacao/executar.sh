#!/usr/bin/env bash
# E9-E8: coordenação no ZooKeeper com znodes efêmeros e sequenciais (kazoo Lock e Election).
#   A pega a trava (ou vence a eleição) e "morre" sem fechar a sessão; B, que espera na fila, assume quando
#   a sessão de A expira. Tempo de troca = ADQUIRIU B - MORREU A (mesmo relógio, dentro do zk-cliente), 5×.
#   Também: época ZAB (zxid) × termo Raft, para o quadro comparativo.
# Uso (da raiz do repositório): experimentos/E9-zookeeper/E8-coordenacao/executar.sh
source "$(dirname "$0")/../../../scripts/lib.sh"
DIR="$RAIZ/experimentos/E9-zookeeper/E8-coordenacao"
N="${N:-5}"

if ! bash "$RAIZ/scripts/validar.sh" zk; then erro "ensemble não saudável: E9-E8 abortado"; exit 1; fi

# troca <trava|eleicao> <rep> <csv>
troca() {
  local tipo="$1" r="$2" csv="$3" pa pb morreu adquiriu d
  local sa="$DIR/evidencias/.A.tmp" sb="$DIR/evidencias/.B.tmp"
  docker exec zk-cliente python /app/e9_coordenacao.py --tipo "$tipo" --ident A --morrer-em 6 > "$sa" & pa=$!
  sleep 2
  docker exec zk-cliente python /app/e9_coordenacao.py --tipo "$tipo" --ident B > "$sb" & pb=$!
  wait "$pa"
  local i; for i in $(seq 1 120); do grep -q '^[0-9.]* ADQUIRIU B' "$sb" && break; sleep 0.25; done
  sleep 0.5
  if [ "$r" = 1 ]; then echo "--- A"; cat "$sa"; echo "--- B"; cat "$sb"; fi
  docker exec zk-cliente pkill -f "e9_coordenacao.py --tipo $tipo --ident B" ; wait "$pb" 2>/dev/null
  morreu="$(awk '/ MORREU /{print $1}' "$sa")"; adquiriu="$(awk '/ ADQUIRIU B/{print $1}' "$sb")"
  d="$(ms_entre "$morreu" "$adquiriu")"
  echo "$r,$(date +%Y-%m-%dT%H:%M:%S),$d,$([ "$d" = nan ] && echo 1 || echo 0),$tipo,$(grep -o 'negociado [0-9.]* s' "$sa" | head -1)" | tee -a "$csv"
  rm -f "$sa" "$sb"
  sleep 1
}
medir() {
  local tipo csv r
  for tipo in trava eleicao; do
    csv="$RAIZ/resultados/$(ts)_e9e8_troca_${tipo}.csv"
    echo "rep,inicio_iso,duracao_ms,exit,tipo,session_timeout" > "$csv"
    for r in $(seq 1 "$N"); do troca "$tipo" "$r" "$csv"; done
    "$PY" "$(caminho_host "$RAIZ/scripts/estatistica.py")" "$(caminho_host "$csv")"
  done
}
evidencia "$DIR" troca_detentor -- medir

epoca_x_termo() {
  echo "--- ZooKeeper: época ZAB = 32 bits altos do zxid"
  docker exec zk-cliente python /app/srvr.py
  local s; for s in "${ZK_SERVIDORES[@]}"; do
    echo "$s currentEpoch=$(docker exec "$s" cat /data/version-2/currentEpoch) acceptedEpoch=$(docker exec "$s" cat /data/version-2/acceptedEpoch)"
  done
  echo "--- etcd: termo Raft (RAFT TERM)"
  docker exec etcd1 etcdctl --endpoints="$EP" endpoint status -w table 2>&1 || echo "(cluster etcd fora do ar)"
}
evidencia "$DIR" epoca_x_termo -- epoca_x_termo

evidencia "$DIR" validacao_final -- bash "$RAIZ/scripts/validar.sh" zk
