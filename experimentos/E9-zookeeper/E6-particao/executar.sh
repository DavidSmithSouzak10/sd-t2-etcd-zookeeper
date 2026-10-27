#!/usr/bin/env bash
# E9-E6: partição no ZooKeeper: o LÍDER é desconectado da rede interna (continua acessível aos clientes).
#   1. tempo até o lado majoritário ter novo líder (t0 = desconexão no docker events), 5 repetições;
#   2. linha do tempo: cliente ligado só ao líder isolado (sessão, leituras, escrita) × srvr dos 3.
# Uso (da raiz do repositório): experimentos/E9-zookeeper/E6-particao/executar.sh
source "$(dirname "$0")/../../../scripts/lib.sh"
DIR="$RAIZ/experimentos/E9-zookeeper/E6-particao"
N="${N:-5}"

if ! bash "$RAIZ/scripts/validar.sh" zk; then erro "ensemble não saudável: E9-E6 abortado"; exit 1; fi
evidencia "$DIR" estado_inicial -- docker exec zk-cliente python /app/srvr.py

esperar_saudavel() {
  local i; for i in $(seq 1 30); do
    bash "$RAIZ/scripts/validar.sh" zk >/dev/null 2>&1 && return 0; sleep 2
  done
  erro "ensemble não voltou a ficar saudável"; bash "$RAIZ/scripts/validar.sh" zk; return 1
}

medir_particao() {
  local csv="$RAIZ/resultados/$(ts)_e9e6_eleicao_particao.csv" r L pid desde t0 res n ea ed la ln
  echo "rep,inicio_iso,duracao_ms,exit,epoca_antes,epoca_depois,lider_antigo,lider_novo" > "$csv"
  for r in $(seq 1 "$N"); do
    read -r L _ < <(zk_papeis); [ -n "$L" ] || { erro "sem líder antes da repetição $r"; return 1; }
    docker exec zk-cliente python /app/e9_eleicao.py --particao > "$DIR/evidencias/.rep.tmp" &
    pid=$!
    sleep 1.5
    desde=$(( $(date +%s) - 30 ))
    info "rep $r: isolando o líder $L"
    bash "$RAIZ/scripts/particionar.sh" isolar "$L"
    wait "$pid"
    cat "$DIR/evidencias/.rep.tmp"
    t0="$(evento_epoch "$L" disconnect "$desde")"
    read -r _ _ n ea ed la ln < <(grep '^RES' "$DIR/evidencias/.rep.tmp")
    res="$(ms_entre "$t0" "$n")"
    echo "$r,$(date -d "@${t0%.*}" +%Y-%m-%dT%H:%M:%S),$res,$([ "$res" = nan ] && echo 1 || echo 0),$ea,$ed,$la,$ln" | tee -a "$csv"
    bash "$RAIZ/scripts/particionar.sh" religar "$L"
    esperar_saudavel || return 1
  done
  rm -f "$DIR/evidencias/.rep.tmp"
  "$PY" "$(caminho_host "$RAIZ/scripts/estatistica.py")" "$(caminho_host "$csv")"
}
evidencia "$DIR" eleicao_lado_majoritario -- medir_particao

linha_do_tempo() {
  local L S1 S2 pid i espera
  read -r L S1 S2 < <(zk_papeis)
  echo "líder (a isolar)=$L  cliente da maioria ligado a $S1"
  # cliente só no líder; a maioria grava NOVO em t = 8 s (dá tempo de eleger novo líder)
  docker exec zk-cliente python /app/e9_isolado.py --alvo "${ZK_IP_CLIENTE[$L]}:2181" \
    --maioria "${ZK_IP_CLIENTE[$S1]}:2181" --escrever-em 8 --duracao 25 --prazo 2 &
  pid=$!
  sleep 3
  bash "$RAIZ/scripts/particionar.sh" isolar "$L"
  for i in 1 2 3 4 5; do sleep 3; echo "--- srvr ($(agora_iso))"; docker exec zk-cliente python /app/srvr.py; done
  for espera in $(seq 1 40); do kill -0 "$pid" 2>/dev/null || break; sleep 1; done
  if kill -0 "$pid" 2>/dev/null; then
    echo "$(agora_iso) cliente não terminou no prazo: encerrado"; docker exec zk-cliente pkill -f e9_isolado.py; wait "$pid"
  fi
  echo "--- log do líder isolado"
  docker logs --since 2m "$L" 2>&1 | grep -E 'LOOKING|LEADING|FOLLOWING|shutdown|Shutting down|quorum|epoch' | tail -20
  bash "$RAIZ/scripts/particionar.sh" religar "$L"
  esperar_saudavel
  echo "--- depois de religar"; docker exec zk-cliente python /app/srvr.py
}
evidencia "$DIR" linha_do_tempo -- linha_do_tempo

evidencia "$DIR" validacao_final -- bash "$RAIZ/scripts/validar.sh" zk
