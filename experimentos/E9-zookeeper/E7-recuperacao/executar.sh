#!/usr/bin/env bash
# E9-E7: recuperação no ZooKeeper.
#   1. 5 repetições: isola o líder, a maioria elege outro e recebe 200 escritas, religa (t0 = connect no
#      docker events); mede quando o antigo líder volta como follower e alcança o zxid; tipo de sincronização
#      (DIFF / SNAP / TRUNC) lido no log do novo líder;
#   2. uma rodada extra com 5000 escritas durante o isolamento, para ver se a sincronização muda de tipo.
# Uso (da raiz do repositório): experimentos/E9-zookeeper/E7-recuperacao/executar.sh
source "$(dirname "$0")/../../../scripts/lib.sh"
DIR="$RAIZ/experimentos/E9-zookeeper/E7-recuperacao"
N="${N:-5}"

if ! bash "$RAIZ/scripts/validar.sh" zk; then erro "ensemble não saudável: E9-E7 abortado"; exit 1; fi
evidencia "$DIR" estado_inicial -- docker exec zk-cliente python /app/srvr.py

esperar_saudavel() {
  local i; for i in $(seq 1 45); do
    bash "$RAIZ/scripts/validar.sh" zk >/dev/null 2>&1 && return 0; sleep 2
  done
  erro "ensemble não voltou a ficar saudável"; bash "$RAIZ/scripts/validar.sh" zk; return 1
}

# uma rodada: rodada <rep> <escritas> <csv>
rodada() {
  local r="$1" k="$2" csv="$3" L N1 pid desde t0 rc al m0 o0 mf zf d sinc
  read -r L N1 _ < <(zk_papeis); [ -n "$L" ] || { erro "sem líder antes da repetição $r"; return 1; }
  bash "$RAIZ/scripts/particionar.sh" isolar "$L"
  # espera a maioria eleger outro líder
  local i; for i in $(seq 1 60); do read -r N1 _ < <(zk_papeis); [ -n "$N1" ] && [ "$N1" != "$L" ] && break; sleep 0.5; done
  info "rep $r: $L isolado; novo líder $N1; $k escritas pela maioria"
  docker exec zk-cliente python /app/latencia.py --op set --servidor "${ZK_IP_CLIENTE[$N1]}:2181" \
    --caminho /e9/carga --n "$k" >/dev/null
  docker exec zk-cliente python /app/e9_alcance.py --alvo "$L" > "$DIR/evidencias/.rep.tmp" &
  pid=$!
  sleep 1.5
  desde=$(( $(date +%s) - 30 ))
  bash "$RAIZ/scripts/particionar.sh" religar "$L"
  wait "$pid"
  cat "$DIR/evidencias/.rep.tmp"
  t0="$(evento_epoch "$L" connect "$desde")"
  read -r _ rc al m0 o0 mf zf < <(grep '^RES' "$DIR/evidencias/.rep.tmp")
  d="$(ms_entre "$t0" "$al")"
  # tipo de sincronização que o novo líder escolheu para este seguidor
  sinc="$(docker logs --since 2m "$N1" 2>&1 | grep -oE 'Sending (DIFF|SNAP|TRUNC)|Synchronizing with Learner[^)]*\)?|sync with[^,]*' | tail -3 | tr '\n' ' ')"
  echo "--- log do novo líder $N1: $sinc"
  docker logs --since 2m "$N1" 2>&1 | grep -E 'DIFF|SNAP|TRUNC|Synchronizing with Learner' | tail -4
  echo "$r,$(date -d "@${t0%.*}" +%Y-%m-%dT%H:%M:%S),$d,$([ "$d" = nan ] && echo 1 || echo 0),$(ms_entre "$t0" "$rc"),$k,$(echo "$sinc" | grep -oE 'DIFF|SNAP|TRUNC' | tail -1)" | tee -a "$csv"
  esperar_saudavel
}

medir() {
  local csv="$RAIZ/resultados/$(ts)_e9e7_recuperacao.csv" r
  echo "rep,inicio_iso,duracao_ms,exit,reconexao_ms,escritas,sincronizacao" > "$csv"
  for r in $(seq 1 "$N"); do rodada "$r" 200 "$csv" || return 1; done
  rm -f "$DIR/evidencias/.rep.tmp"
  "$PY" "$(caminho_host "$RAIZ/scripts/estatistica.py")" "$(caminho_host "$csv")"
  "$PY" "$(caminho_host "$RAIZ/scripts/estatistica.py")" "$(caminho_host "$csv")" --coluna reconexao_ms
}
evidencia "$DIR" reconexao_e_alcance -- medir

extra() {
  local csv="$RAIZ/resultados/$(ts)_e9e7_recuperacao_5000.csv"
  echo "rep,inicio_iso,duracao_ms,exit,reconexao_ms,escritas,sincronizacao" > "$csv"
  rodada 1 5000 "$csv"
  rm -f "$DIR/evidencias/.rep.tmp"
  docker exec zk-cliente python /app/srvr.py
}
evidencia "$DIR" rodada_5000_escritas -- extra

evidencia "$DIR" validacao_final -- bash "$RAIZ/scripts/validar.sh" zk
