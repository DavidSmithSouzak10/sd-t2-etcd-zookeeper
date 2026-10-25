#!/usr/bin/env bash
# E9-E3: replicação no ZooKeeper: set em um seguidor, get imediato (local) em outro seguidor, watch no líder; latências.
# Uso (da raiz do repositório): experimentos/E9-zookeeper/E3-replicacao/executar.sh
source "$(dirname "$0")/../../../scripts/lib.sh"
DIR="$RAIZ/experimentos/E9-zookeeper/E3-replicacao"

if ! bash "$RAIZ/scripts/validar.sh" zk; then erro "ensemble não saudável: E9-E3 abortado"; exit 1; fi
read -r L S1 S2 < <(zk_papeis)
info "líder=$L  escreve=$S1  lê=$S2  watch=$L"
evidencia "$DIR" estado_inicial -- docker exec zk-cliente python /app/srvr.py

saida="$DIR/evidencias/$(ts)_replicacao_e_watch.txt"
evidencia "$DIR" replicacao_e_watch -- docker exec zk-cliente python /app/e9_replicacao.py \
  --escreve "${ZK_IP_CLIENTE[$S1]}:2181" --le "${ZK_IP_CLIENTE[$S2]}:2181" --watch "${ZK_IP_CLIENTE[$L]}:2181" --n 20
csv="$RAIZ/resultados/$(ts)_e9e3_atraso_watch_${L}.csv"
sed -n '/^## 3/,$p' "$saida" | grep -E '^(rep,|[0-9]+,)' > "$csv"

{ info "papéis: líder=$L seguidores=$S1 $S2"
  "$PY" "$(caminho_host "$RAIZ/scripts/estatistica.py")" "$(caminho_host "$csv")"
  scripts/latencia.sh zk "e9e3_set_${S2}" 20 -- --op set --servidor "${ZK_IP_CLIENTE[$S2]}:2181" --caminho /e9/lat
  scripts/latencia.sh zk "e9e3_get_local_${S2}" 20 -- --op get --servidor "${ZK_IP_CLIENTE[$S2]}:2181" --caminho /e9/lat
  scripts/latencia.sh zk "e9e3_get_sync_${S2}" 20 -- --op get --servidor "${ZK_IP_CLIENTE[$S2]}:2181" --caminho /e9/lat --sync
} | tee "$DIR/evidencias/$(ts)_latencias.txt"
evidencia "$DIR" memoria -- docker stats --no-stream --format "{{.Name}} {{.MemUsage}} {{.CPUPerc}}" zk1 zk2 zk3 zk-cliente
evidencia "$DIR" validacao_final -- bash "$RAIZ/scripts/validar.sh" zk
