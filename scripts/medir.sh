#!/usr/bin/env bash
# Mede o tempo de parede de um comando N vezes e grava um CSV em resultados/.
# Uso: scripts/medir.sh <nome> <repeticoes> -- <comando...>
#   ex.: scripts/medir.sh e3_put_etcd2 10 -- docker exec etcd2 etcdctl --endpoints=172.31.0.32:2379 put /k v
# CSV: rep,inicio_iso,duracao_ms,exit   (o tempo inclui o overhead do docker exec: registre isso na análise)
# Para latência de put/get use scripts/latencia.sh, que mede dentro do contêiner cliente (achado A3).
# Tempos de evento (eleição, recuperação) são medidos pelos executar.sh de cada experimento,
# que gravam no mesmo formato e também passam por scripts/estatistica.py.
source "$(dirname "$0")/lib.sh"

if [ $# -lt 4 ] || [ "$3" != "--" ]; then erro "uso: $0 <nome> <repeticoes> -- <comando...>"; exit 2; fi
nome="$1"; n="$2"; shift 3
if ! [ "$n" -ge 5 ] 2>/dev/null; then erro "R7 exige pelo menos 5 repetições"; exit 2; fi

mkdir -p "$RAIZ/resultados"
csv="$RAIZ/resultados/$(ts)_${nome}.csv"
echo "rep,inicio_iso,duracao_ms,exit" > "$csv"
info "medindo '$*' x$n -> ${csv#$RAIZ/}"
for i in $(seq 1 "$n"); do
  ini_iso="$(agora_iso)"; t0="$(agora_ms)"
  "$@" >/dev/null 2>&1; rc=$?
  t1="$(agora_ms)"
  echo "$i,$ini_iso,$((t1 - t0)),$rc" >> "$csv"
done
"$PY" "$(caminho_host "$RAIZ/scripts/estatistica.py")" "$(caminho_host "$csv")"
