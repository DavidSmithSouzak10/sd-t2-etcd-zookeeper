#!/usr/bin/env bash
# E3: replicação no etcd: escrever em um membro, ler em outro, watch em um terceiro; latências; check perf.
# Uso (da raiz do repositório): experimentos/E3-replicacao/executar.sh
source "$(dirname "$0")/../../scripts/lib.sh"
DIR="$RAIZ/experimentos/E3-replicacao"

if ! bash "$RAIZ/scripts/validar.sh" etcd; then erro "cluster não saudável: E3 abortado"; exit 1; fi
evidencia "$DIR" estado_inicial -- docker exec etcd1 etcdctl --endpoints="$EP" endpoint status -w table

# 1. escreve em etcd1, lê logo em seguida em etcd3 (leitura padrão), watch em etcd2: 20 repetições
evidencia "$DIR" escreve1_le3_watch2 -- docker exec etcd-cliente python /app/e3_replicacao.py \
  --escreve 172.31.0.31 --le 172.31.0.33 --watch 172.31.0.32 --n 20
# mesmo procedimento só para o CSV do atraso do watch (put enviado -> evento recebido)
csv="$RAIZ/resultados/$(ts)_e3_atraso_watch_etcd2.csv"
docker exec etcd-cliente python /app/e3_replicacao.py --escreve 172.31.0.31 --le 172.31.0.33 --watch 172.31.0.32 --n 20 --csv-watch > "$csv"

# 2. latências no mesmo membro (seguidor ou líder registrado no estado inicial), 20 repetições cada
{
  info "líder: $(etcd_lider)"
  "$PY" "$(caminho_host "$RAIZ/scripts/estatistica.py")" "$(caminho_host "$csv")"
  scripts/latencia.sh etcd e3_put_etcd3 20 -- --op put --endpoint 172.31.0.33:2379 --chave /e3/lat
  scripts/latencia.sh etcd e3_get_lin_etcd3 20 -- --op get --endpoint 172.31.0.33:2379 --chave /e3/lat
  scripts/latencia.sh etcd e3_get_ser_etcd3 20 -- --op get --endpoint 172.31.0.33:2379 --chave /e3/lat --serializavel
} | tee "$DIR/evidencias/$(ts)_latencias.txt"

# 3. check perf com carga pequena (cerca de 60 s)
evidencia "$DIR" check_perf_s -- docker exec etcd1 etcdctl --endpoints="$EP" check perf --load=s
evidencia "$DIR" memoria_apos_carga -- docker stats --no-stream --format "{{.Name}} {{.MemUsage}} {{.CPUPerc}}" etcd1 etcd2 etcd3 etcd-cliente

evidencia "$DIR" validacao_final -- bash "$RAIZ/scripts/validar.sh" etcd
