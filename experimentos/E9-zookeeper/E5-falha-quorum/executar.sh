#!/usr/bin/env bash
# E9-E5: falha do líder e perda de maioria no ZooKeeper.
#   1. queda do líder por SIGKILL (docker kill): tempo até novo líder e nova época no zxid, 5 repetições;
#   2. parada do líder por SIGTERM (docker stop), 5 repetições, para comparar;
#   3. quadro servidores ativos (3, 2, 1) × sessão × escrita × leitura local × sync + leitura.
# Uso (da raiz do repositório): experimentos/E9-zookeeper/E5-falha-quorum/executar.sh
source "$(dirname "$0")/../../../scripts/lib.sh"
DIR="$RAIZ/experimentos/E9-zookeeper/E5-falha-quorum"
N="${N:-5}"

if ! bash "$RAIZ/scripts/validar.sh" zk; then erro "ensemble não saudável: E9-E5 abortado"; exit 1; fi

epocas() {
  local s; for s in "${ZK_SERVIDORES[@]}"; do
    echo "$s currentEpoch=$(docker exec "$s" cat /data/version-2/currentEpoch 2>/dev/null) acceptedEpoch=$(docker exec "$s" cat /data/version-2/acceptedEpoch 2>/dev/null)"
  done
}
estado() { docker exec zk-cliente python /app/srvr.py; epocas; }
evidencia "$DIR" estado_inicial -- estado

esperar_saudavel() {
  local i; for i in $(seq 1 30); do
    bash "$RAIZ/scripts/validar.sh" zk >/dev/null 2>&1 && return 0; sleep 2
  done
  erro "ensemble não voltou a ficar saudável"; bash "$RAIZ/scripts/validar.sh" zk; return 1
}

# medir_queda <kill|stop> <nome-do-csv>: t0 = evento "kill" do Docker; t1 = 1º sobrevivente em Mode: leader
medir_queda() {
  local modo="$1" csv="$RAIZ/resultados/$(ts)_$2.csv" r L pid desde t0 res q n ea ed la ln
  echo "rep,inicio_iso,duracao_ms,exit,deteccao_ms,epoca_antes,epoca_depois,lider_antigo,lider_novo" > "$csv"
  for r in $(seq 1 "$N"); do
    read -r L _ < <(zk_papeis)
    [ -n "$L" ] || { erro "sem líder antes da repetição $r"; return 1; }
    docker exec zk-cliente python /app/e9_eleicao.py > "$DIR/evidencias/.rep.tmp" &
    pid=$!
    sleep 1.5
    desde=$(( $(date +%s) - 30 ))
    info "rep $r: docker $modo $L ($(agora_iso))"
    docker "$modo" "$L" >/dev/null
    wait "$pid"
    cat "$DIR/evidencias/.rep.tmp"
    t0="$(evento_epoch "$L" kill "$desde")"
    read -r _ q n ea ed la ln < <(grep '^RES' "$DIR/evidencias/.rep.tmp")
    res="$(ms_entre "$t0" "$n")"
    echo "$r,$(date -d "@${t0%.*}" +%Y-%m-%dT%H:%M:%S),$res,$([ "$res" = nan ] && echo 1 || echo 0),$(ms_entre "$t0" "$q"),$ea,$ed,$la,$ln" | tee -a "$csv"
    if [ "$r" = 1 ]; then  # log da eleição (FastLeaderElection) num sobrevivente
      local s; for s in "${ZK_SERVIDORES[@]}"; do [ "$s" != "$L" ] && break; done
      echo "--- log de $s (último minuto)"
      docker logs --since 1m "$s" 2>&1 | grep -E 'LOOKING|LEADING|FOLLOWING|New election|Notification|epoch|Exception when following' | tail -25
    fi
    docker start "$L" >/dev/null
    esperar_saudavel || return 1
  done
  rm -f "$DIR/evidencias/.rep.tmp"
  "$PY" "$(caminho_host "$RAIZ/scripts/estatistica.py")" "$(caminho_host "$csv")"
  echo "--- épocas depois da bateria"; estado
}
evidencia "$DIR" queda_lider_kill -- medir_queda kill e9e5_eleicao_kill
evidencia "$DIR" parada_lider_stop -- medir_queda stop e9e5_eleicao_stop

quadro() {
  local L S1 S2
  read -r L S1 S2 < <(zk_papeis)
  echo "=== 3 servidores ativos (líder $L)"
  docker exec zk-cliente python /app/e9_operacoes.py "${ZK_IP_CLIENTE[$L]}" "${ZK_IP_CLIENTE[$S1]}" "${ZK_IP_CLIENTE[$S2]}"
  echo "=== 2 servidores ativos: docker stop $S2 (seguidor)"; docker stop "$S2" >/dev/null; sleep 2
  docker exec zk-cliente python /app/e9_operacoes.py "${ZK_IP_CLIENTE[$L]}" "${ZK_IP_CLIENTE[$S1]}"
  echo "=== 1 servidor ativo: docker stop $S1"; docker stop "$S1" >/dev/null
  echo "--- aguardando 5 s"; sleep 5
  docker exec zk-cliente python /app/e9_operacoes.py "${ZK_IP_CLIENTE[$L]}"
  docker exec zk-cliente python /app/srvr.py
  echo "=== religando $S1 e $S2"; docker start "$S1" "$S2" >/dev/null
  esperar_saudavel && estado
}
evidencia "$DIR" quadro_quorum -- quadro

evidencia "$DIR" validacao_final -- bash "$RAIZ/scripts/validar.sh" zk
