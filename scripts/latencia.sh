#!/usr/bin/env bash
# Mede latência de operações de dentro da rede de clientes (sem o overhead do docker exec) e grava um CSV em resultados/.
# Uso: scripts/latencia.sh <etcd|zk> <nome> <repeticoes> -- <argumentos do latencia.py>
#   ex.: scripts/latencia.sh etcd e3_put_etcd2 20 -- --op put --endpoint 172.31.0.32:2379
#        scripts/latencia.sh etcd e4_get_ser_etcd3 20 -- --op get --endpoint 172.31.0.33:2379 --serializavel
#        scripts/latencia.sh zk e9_set_zk2 20 -- --op set --servidor 172.33.0.52:2181
# O laço roda dentro do contêiner cliente (etcd-cliente / zk-cliente); o relógio é time.perf_counter.
# CSV: rep,inicio_iso,duracao_ms,exit (mesmo formato de medir.sh); a tabela sai de scripts/estatistica.py.
source "$(dirname "$0")/lib.sh"

if [ $# -lt 5 ] || [ "$4" != "--" ]; then erro "uso: $0 <etcd|zk> <nome> <repeticoes> -- <args>"; exit 2; fi
sistema="$1"; nome="$2"; n="$3"; shift 4
case "$sistema" in
  etcd) cliente=etcd-cliente ;;
  zk)   cliente=zk-cliente ;;
  *) erro "sistema deve ser etcd ou zk"; exit 2 ;;
esac
if ! [ "$n" -ge 5 ] 2>/dev/null; then erro "R7 exige pelo menos 5 repetições"; exit 2; fi

mkdir -p "$RAIZ/resultados"
csv="$RAIZ/resultados/$(ts)_${nome}.csv"
info "medindo em $cliente: latencia.py $* x$n -> ${csv#$RAIZ/}"
if ! docker exec "$cliente" python /app/latencia.py --n "$n" "$@" > "$csv"; then
  erro "latencia.py falhou (CSV parcial em ${csv#$RAIZ/})"
fi
"$PY" "$(caminho_host "$RAIZ/scripts/estatistica.py")" "$(caminho_host "$csv")"
