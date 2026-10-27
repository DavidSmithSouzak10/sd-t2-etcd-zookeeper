#!/usr/bin/env bash
# E6: partição de rede no etcd: o LÍDER é desconectado da rede interna (continua acessível aos clientes).
#   1. tempo até o lado majoritário eleger novo líder (t0 = desconexão no docker events), 5 repetições;
#   2. linha do tempo: o que um cliente ligado só ao líder isolado recebe × o lado majoritário.
# Uso (da raiz do repositório): experimentos/E6-particao/executar.sh
source "$(dirname "$0")/../../scripts/lib.sh"
DIR="$RAIZ/experimentos/E6-particao"
N="${N:-5}"

if ! bash "$RAIZ/scripts/validar.sh" etcd; then erro "cluster não saudável: E6 abortado"; exit 1; fi
evidencia "$DIR" estado_inicial -- docker exec etcd1 etcdctl --endpoints="$EP" endpoint status -w table

esperar_saudavel() {
  local i; for i in $(seq 1 30); do
    bash "$RAIZ/scripts/validar.sh" etcd >/dev/null 2>&1 && return 0; sleep 2
  done
  erro "cluster não voltou a ficar saudável"; bash "$RAIZ/scripts/validar.sh" etcd; return 1
}

# 1. eleição do lado majoritário
medir_particao() {
  local csv="$RAIZ/resultados/$(ts)_e6_eleicao_particao.csv" r L pid desde t0 res n ta td la ln
  echo "rep,inicio_iso,duracao_ms,exit,termo_antes,termo_depois,lider_antigo,lider_novo" > "$csv"
  for r in $(seq 1 "$N"); do
    L="$(etcd_lider)"; [ -n "$L" ] || { erro "sem líder antes da repetição $r"; return 1; }
    docker exec etcd-cliente python /app/e5_eleicao.py --particao > "$DIR/evidencias/.rep.tmp" &
    pid=$!
    sleep 1.5
    desde=$(( $(date +%s) - 30 ))
    info "rep $r: isolando o líder $L"
    bash "$RAIZ/scripts/particionar.sh" isolar "$L"
    wait "$pid"
    cat "$DIR/evidencias/.rep.tmp"
    t0="$(evento_epoch "$L" disconnect "$desde")"
    read -r _ _ n ta td la ln < <(grep '^RES' "$DIR/evidencias/.rep.tmp")
    res="$(ms_entre "$t0" "$n")"
    echo "$r,$(date -d "@${t0%.*}" +%Y-%m-%dT%H:%M:%S),$res,$([ "$res" = nan ] && echo 1 || echo 0),$ta,$td,$la,$ln" | tee -a "$csv"
    bash "$RAIZ/scripts/particionar.sh" religar "$L"
    esperar_saudavel || return 1
  done
  rm -f "$DIR/evidencias/.rep.tmp"
  "$PY" "$(caminho_host "$RAIZ/scripts/estatistica.py")" "$(caminho_host "$csv")"
}
evidencia "$DIR" eleicao_lado_majoritario -- medir_particao

# 2. linha do tempo dos dois lados (endpoint único em cada lado, prazo de 3 s por operação)
linha_do_tempo() {
  local L S1 m i
  L="$(etcd_lider)"; for m in "${ETCD_MEMBROS[@]}"; do [ "$m" != "$L" ] && { S1="$m"; break; }; done
  op() {  # op <membro> <rótulo> <args do etcdctl...>
    local membro="$1" rot="$2"; shift 2
    echo "$(agora_iso) [$membro] $rot -> $(docker exec "$membro" etcdctl --endpoints=127.0.0.1:2379 --command-timeout=3s "$@" 2>&1 | tail -1)"
  }
  echo "líder (a isolar)=$L  lado majoritário observado em $S1"
  op "$L" "put ANTIGO" put /e6/k ANTIGO
  bash "$RAIZ/scripts/particionar.sh" isolar "$L"
  for i in 1 2 3 4 5 6; do
    echo "--- rodada $i"
    op "$L" "put isolado-$i" put /e6/k "isolado-$i"
    op "$L" "get linearizável" get /e6/k --print-value-only
    op "$L" "get serializável" get /e6/k --print-value-only --consistency=s
    op "$L" "status" endpoint status -w simple
    op "$S1" "status" endpoint status -w simple
    [ "$i" = 2 ] && op "$S1" "put NOVO (maioria)" put /e6/k NOVO
    op "$S1" "get linearizável" get /e6/k --print-value-only
    sleep 1
  done
  echo "--- log do Raft no líder isolado"
  docker logs --since 2m "$L" 2>&1 | grep -E 'leader|term|quorum|step|candidate|vote' | tail -20
  bash "$RAIZ/scripts/particionar.sh" religar "$L"
  esperar_saudavel
  echo "--- depois de religar: valor em cada membro (serializável) e status"
  for m in "${ETCD_MEMBROS[@]}"; do op "$m" "get serializável" get /e6/k --print-value-only --consistency=s; done
  docker exec etcd1 etcdctl --endpoints="$EP" endpoint status -w table
}
evidencia "$DIR" linha_do_tempo -- linha_do_tempo

evidencia "$DIR" validacao_final -- bash "$RAIZ/scripts/validar.sh" etcd
