#!/usr/bin/env bash
# E7: recuperação no etcd.
#   1. 5 repetições: isola o líder, a maioria elege outro e recebe 1000 escritas, religa (t0 = connect no
#      docker events); mede quando o antigo líder volta a ver um líder (reconexão) e alcança o RAFT INDEX;
#   2. snapshot: recria o cluster com --snapshot-count=1000, para um seguidor, faz 10000 escritas e religa:
#      o líder deve mandar um snapshot em vez do log (o etcd guarda só 5000 entradas depois de cada snapshot).
#      Estado final idêntico conferido com `endpoint hashkv`. No fim, recria o cluster com o padrão (100000).
#   ATENÇÃO: a parte 2 recria o cluster etcd (os dados de teste anteriores são perdidos; as evidências não).
# Uso (da raiz do repositório): experimentos/E7-recuperacao/executar.sh
source "$(dirname "$0")/../../scripts/lib.sh"
DIR="$RAIZ/experimentos/E7-recuperacao"
N="${N:-5}"
COMPOSE=(docker compose -f "$(caminho_host "$RAIZ/etcd/docker-compose.yml")")

if ! bash "$RAIZ/scripts/validar.sh" etcd; then erro "cluster não saudável: E7 abortado"; exit 1; fi
evidencia "$DIR" estado_inicial -- docker exec etcd1 etcdctl --endpoints="$EP" endpoint status -w table

esperar_saudavel() {
  local i; for i in $(seq 1 45); do
    bash "$RAIZ/scripts/validar.sh" etcd >/dev/null 2>&1 && return 0; sleep 2
  done
  erro "cluster não voltou a ficar saudável"; bash "$RAIZ/scripts/validar.sh" etcd; return 1
}

# 1. reconexão e alcance do RAFT INDEX
medir_recuperacao() {
  local csv="$RAIZ/resultados/$(ts)_e7_recuperacao.csv" r L N1 m pid desde t0 rc al i0 o0 ti tf d
  echo "rep,inicio_iso,duracao_ms,exit,reconexao_ms,atraso_indice,termo_antes,termo_depois" > "$csv"
  for r in $(seq 1 "$N"); do
    L="$(etcd_lider)"; [ -n "$L" ] || { erro "sem líder antes da repetição $r"; return 1; }
    bash "$RAIZ/scripts/particionar.sh" isolar "$L"
    sleep 3
    N1=""; for m in "${ETCD_MEMBROS[@]}"; do [ "$m" != "$L" ] && { N1="$m"; break; }; done
    info "rep $r: $L isolado; 1000 escritas pela maioria ($N1)"
    docker exec etcd-cliente python /app/latencia.py --op put --endpoint "${ETCD_IP_CLIENTE[$N1]}:2379" \
      --chave /e7/carga --n 1000 --timeout 5 >/dev/null
    docker exec etcd-cliente python /app/e7_alcance.py --alvo "$L" > "$DIR/evidencias/.rep.tmp" &
    pid=$!
    sleep 1.5
    desde=$(( $(date +%s) - 30 ))
    bash "$RAIZ/scripts/particionar.sh" religar "$L"
    wait "$pid"
    cat "$DIR/evidencias/.rep.tmp"
    t0="$(evento_epoch "$L" connect "$desde")"
    read -r _ rc al i0 o0 ti tf < <(grep '^RES' "$DIR/evidencias/.rep.tmp")
    d="$(ms_entre "$t0" "$al")"
    echo "$r,$(date -d "@${t0%.*}" +%Y-%m-%dT%H:%M:%S),$d,$([ "$d" = nan ] && echo 1 || echo 0),$(ms_entre "$t0" "$rc"),$((o0 - i0)),$ti,$tf" | tee -a "$csv"
    if [ "$r" = 1 ]; then
      echo "--- log do Raft em $L (religado)"
      docker logs --since 1m "$L" 2>&1 | grep -E 'term|leader|became|snapshot|peer' | tail -20
    fi
    esperar_saudavel || return 1
  done
  rm -f "$DIR/evidencias/.rep.tmp"
  "$PY" "$(caminho_host "$RAIZ/scripts/estatistica.py")" "$(caminho_host "$csv")"
  docker exec etcd1 etcdctl --endpoints="$EP" endpoint status -w table
}
evidencia "$DIR" reconexao_e_alcance -- medir_recuperacao

# 2. recuperação por snapshot
snapshot() {
  local L F m t0 i
  echo "=== recriando o cluster com SNAPSHOT_COUNT=1000"
  SNAPSHOT_COUNT=1000 "${COMPOSE[@]}" up -d --force-recreate etcd1 etcd2 etcd3 2>&1 | tail -3
  esperar_saudavel || return 1
  docker exec etcd1 etcdctl --endpoints="$EP" endpoint status -w table
  L="$(etcd_lider)"; for m in "${ETCD_MEMBROS[@]}"; do [ "$m" != "$L" ] && { F="$m"; break; }; done
  echo "=== parando o seguidor $F; 10000 escritas pelo líder $L"
  docker stop "$F" >/dev/null
  docker exec etcd-cliente python /app/latencia.py --op put --endpoint "${ETCD_IP_CLIENTE[$L]}:2379" \
    --chave /e7/snap --n 10000 --timeout 5 >/dev/null
  docker exec "$L" etcdctl --endpoints=127.0.0.1:2379 endpoint status -w table
  echo "=== religando $F ($(agora_iso))"
  t0="$(agora_ms)"
  docker start "$F" >/dev/null
  for i in $(seq 1 120); do
    read -r a _ _ < <(etcd_indice_revisao "$F"); read -r b _ _ < <(etcd_indice_revisao "$L")
    [ -n "$a" ] && [ -n "$b" ] && [ "$a" -ge "$b" ] && break; sleep 0.5
  done
  echo "$(agora_iso) $F alcançou o índice do líder (cerca de $(( $(agora_ms) - t0 )) ms desde o docker start, medido no host)"
  echo "--- log do líder $L (envio de snapshot)"
  docker logs --since 3m "$L" 2>&1 | grep -iE 'snapshot' | tail -10
  echo "--- log do seguidor $F (recebimento de snapshot)"
  docker logs --since 3m "$F" 2>&1 | grep -iE 'snapshot' | tail -10
  echo "--- estado final: hash do keyspace em cada membro (iguais = mesmo estado)"
  docker exec etcd1 etcdctl --endpoints="$EP" endpoint hashkv -w table
  docker exec etcd1 etcdctl --endpoints="$EP" endpoint status -w table
}
evidencia "$DIR" recuperacao_por_snapshot -- snapshot

restaurar() {
  echo "=== recriando o cluster com o padrão (SNAPSHOT_COUNT do etcd/.env)"
  "${COMPOSE[@]}" up -d --force-recreate etcd1 etcd2 etcd3 2>&1 | tail -3
  esperar_saudavel
}
evidencia "$DIR" restauracao -- restaurar
evidencia "$DIR" validacao_final -- bash "$RAIZ/scripts/validar.sh" etcd
