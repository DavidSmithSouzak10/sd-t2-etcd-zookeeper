#!/usr/bin/env bash
# E5: falha do líder e perda de quórum no etcd.
#   1. queda do líder por SIGKILL (docker kill = falha abrupta): tempo até novo líder e termo, 5 repetições;
#   2. parada do líder por SIGTERM (docker stop = parada ordenada), 5 repetições, para comparar;
#   3. quadro membros ativos (3, 2, 1) × escrita × leitura linearizável × leitura serializável.
# Uso (da raiz do repositório): experimentos/E5-falha-quorum/executar.sh
source "$(dirname "$0")/../../scripts/lib.sh"
DIR="$RAIZ/experimentos/E5-falha-quorum"
N="${N:-5}"

if ! bash "$RAIZ/scripts/validar.sh" etcd; then erro "cluster não saudável: E5 abortado"; exit 1; fi
evidencia "$DIR" estado_inicial -- docker exec etcd1 etcdctl --endpoints="$EP" endpoint status -w table

# espera o cluster voltar a ficar saudável (até 60 s) depois de religar um membro
esperar_saudavel() {
  local i; for i in $(seq 1 30); do
    bash "$RAIZ/scripts/validar.sh" etcd >/dev/null 2>&1 && return 0; sleep 2
  done
  erro "cluster não voltou a ficar saudável"; bash "$RAIZ/scripts/validar.sh" etcd; return 1
}

# uma bateria de N quedas do líder com o sinal dado: medir_queda <kill|stop> <nome-do-csv>
# t0 = evento "kill" do Docker (sinal enviado: 9 no kill, 15 no stop); t1 = 1º sobrevivente que informa o novo líder.
# Coluna extra deteccao_ms = quando o cliente deixou de obter resposta do líder antigo, contado de t0.
medir_queda() {
  local modo="$1" csv="$RAIZ/resultados/$(ts)_$2.csv" r L pid desde t0 res q n ta td la ln
  echo "rep,inicio_iso,duracao_ms,exit,deteccao_ms,termo_antes,termo_depois,lider_antigo,lider_novo" > "$csv"
  for r in $(seq 1 "$N"); do
    L="$(etcd_lider)"
    [ -n "$L" ] || { erro "sem líder antes da repetição $r"; return 1; }
    docker exec etcd-cliente python /app/e5_eleicao.py > "$DIR/evidencias/.rep.tmp" &
    pid=$!
    sleep 1.5
    desde=$(( $(date +%s) - 30 ))
    info "rep $r: docker $modo $L ($(agora_iso))"
    docker "$modo" "$L" >/dev/null
    wait "$pid"
    cat "$DIR/evidencias/.rep.tmp"
    t0="$(evento_epoch "$L" kill "$desde")"
    read -r _ q n ta td la ln < <(grep '^RES' "$DIR/evidencias/.rep.tmp")
    res="$(ms_entre "$t0" "$n")"
    echo "$r,$(date -d "@${t0%.*}" +%Y-%m-%dT%H:%M:%S),$res,$([ "$res" = nan ] && echo 1 || echo 0),$(ms_entre "$t0" "$q"),$ta,$td,$la,$ln" | tee -a "$csv"
    if [ "$r" = 1 ]; then  # guarda o log do Raft de um sobrevivente durante a eleição
      local s; for s in "${ETCD_MEMBROS[@]}"; do [ "$s" != "$L" ] && break; done
      echo "--- log do Raft em $s (último minuto)"
      docker logs --since 1m "$s" 2>&1 | grep -E 'raft|leader|term|candidate|vote' | tail -25
    fi
    docker start "$L" >/dev/null
    esperar_saudavel || return 1
  done
  rm -f "$DIR/evidencias/.rep.tmp"
  "$PY" "$(caminho_host "$RAIZ/scripts/estatistica.py")" "$(caminho_host "$csv")"
}
evidencia "$DIR" queda_lider_kill -- medir_queda kill e5_eleicao_kill
evidencia "$DIR" parada_lider_stop -- medir_queda stop e5_eleicao_stop

# quadro: para cada membro vivo, escrita, leitura linearizável e serializável por endpoint único (prazo de 3 s)
operacoes() {
  local m saida
  for m in "$@"; do
    saida="$(docker exec "$m" etcdctl --endpoints=127.0.0.1:2379 --command-timeout=3s put /e5/k "v-$(date +%s)" 2>&1 | tail -1)"
    echo "$(agora_iso) $m escrita            -> $saida"
    saida="$(docker exec "$m" etcdctl --endpoints=127.0.0.1:2379 --command-timeout=3s get /e5/k --print-value-only 2>&1 | tail -1)"
    echo "$(agora_iso) $m leitura linearizável -> $saida"
    saida="$(docker exec "$m" etcdctl --endpoints=127.0.0.1:2379 --command-timeout=3s get /e5/k --print-value-only --consistency=s 2>&1 | tail -1)"
    echo "$(agora_iso) $m leitura serializável -> $saida"
    echo "$(agora_iso) $m status: $(docker exec "$m" etcdctl --endpoints=127.0.0.1:2379 --command-timeout=3s endpoint status -w simple 2>&1 | tail -1)"
  done
}
quadro() {
  local L S1 S2 m
  L="$(etcd_lider)"; S1=""; S2=""
  for m in "${ETCD_MEMBROS[@]}"; do [ "$m" = "$L" ] && continue; [ -z "$S1" ] && S1="$m" || S2="$m"; done
  echo "=== 3 membros ativos (líder $L)"; operacoes "$L" "$S1" "$S2"
  echo "=== 2 membros ativos: docker stop $S2 (seguidor)"; docker stop "$S2" >/dev/null; sleep 2
  operacoes "$L" "$S1"
  echo "=== 1 membro ativo: docker stop $S1"; docker stop "$S1" >/dev/null
  echo "--- aguardando 5 s (election timeout + check quorum)"; sleep 5
  operacoes "$L"
  echo "=== religando $S1 e $S2"; docker start "$S1" "$S2" >/dev/null
  esperar_saudavel && docker exec etcd1 etcdctl --endpoints="$EP" endpoint status -w table
}
evidencia "$DIR" quadro_quorum -- quadro

evidencia "$DIR" validacao_final -- bash "$RAIZ/scripts/validar.sh" etcd
