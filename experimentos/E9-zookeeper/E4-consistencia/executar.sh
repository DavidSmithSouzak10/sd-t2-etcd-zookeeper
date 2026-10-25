#!/usr/bin/env bash
# E9-E4: consistência no ZooKeeper: leitura local × sync+get; o que um cliente vê quando o servidor dele é isolado.
# Uso (da raiz do repositório): experimentos/E9-zookeeper/E4-consistencia/executar.sh
source "$(dirname "$0")/../../../scripts/lib.sh"
DIR="$RAIZ/experimentos/E9-zookeeper/E4-consistencia"

if ! bash "$RAIZ/scripts/validar.sh" zk; then erro "ensemble não saudável: E9-E4 abortado"; exit 1; fi
read -r L S1 S2 < <(zk_papeis)
X="$S1"; info "líder=$L  seguidor a isolar=$X"

# 1. latência leitura local × sync + leitura no mesmo seguidor (20 repetições)
{ info "líder=$L seguidor=$X"
  scripts/latencia.sh zk "e9e4_get_local_${X}" 20 -- --op get --servidor "${ZK_IP_CLIENTE[$X]}:2181" --caminho /e9/lat
  scripts/latencia.sh zk "e9e4_get_sync_${X}" 20 -- --op get --servidor "${ZK_IP_CLIENTE[$X]}:2181" --caminho /e9/lat --sync
} | tee "$DIR/evidencias/$(ts)_latencia_local_x_sync.txt"

# 2. seguidor isolado: o cliente (ligado só a ele) faz get local, sync+get e escrita a cada 0,5 s
isolamento() {
  docker exec zk-cliente python /app/e9_isolado.py --alvo "${ZK_IP_CLIENTE[$X]}:2181" \
    --maioria "${ZK_IP_CLIENTE[$L]}:2181" --escrever-em 4 --duracao 30 &
  local pid=$!
  sleep 3
  bash "$RAIZ/scripts/particionar.sh" isolar "$X"
  sleep 8
  echo "--- srvr durante o isolamento"; docker exec zk-cliente python /app/srvr.py
  # garantia: se o cliente não terminar em 30 s + folga, encerra-o e religa mesmo assim
  local espera; for espera in $(seq 1 40); do kill -0 "$pid" 2>/dev/null || break; sleep 1; done
  if kill -0 "$pid" 2>/dev/null; then
    echo "$(agora_iso) cliente não terminou no prazo: encerrado"; docker exec zk-cliente pkill -f e9_isolado.py; wait "$pid"
  fi
  bash "$RAIZ/scripts/particionar.sh" religar "$X"
  local i; for i in $(seq 1 60); do
    docker exec zk-cliente python /app/srvr.py | grep -q "${ZK_IP_CLIENTE[$X]} modo=follower" && break; sleep 0.5; done
  echo "$(agora_iso) $X de volta como seguidor (após ~$((i / 2)) s)"
  docker exec zk-cliente python /app/srvr.py
}
evidencia "$DIR" seguidor_isolado -- isolamento

evidencia "$DIR" validacao_final -- bash "$RAIZ/scripts/validar.sh" zk
