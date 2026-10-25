#!/usr/bin/env bash
# E4: consistência no etcd: leitura linearizável × serializável; seguidor isolado; leituras e o RAFT INDEX.
# Uso (da raiz do repositório): experimentos/E4-consistencia/executar.sh
source "$(dirname "$0")/../../scripts/lib.sh"
DIR="$RAIZ/experimentos/E4-consistencia"

if ! bash "$RAIZ/scripts/validar.sh" etcd; then erro "cluster não saudável: E4 abortado"; exit 1; fi
L="$(etcd_lider)"; SEG=(); for m in "${ETCD_MEMBROS[@]}"; do [ "$m" != "$L" ] && SEG+=("$m"); done
X="${SEG[0]}"; IP_X="${ETCD_IP_CLIENTE[$X]}"; IP_L="${ETCD_IP_CLIENTE[$L]}"
info "líder=$L  seguidor observado=$X"

# 1. latência linearizável × serializável no MESMO seguidor, 20 repetições cada
{ info "líder=$L seguidor=$X"
  scripts/latencia.sh etcd "e4_get_lin_${X}" 20 -- --op get --endpoint "$IP_X:2379" --chave /e4/lat
  scripts/latencia.sh etcd "e4_get_ser_${X}" 20 -- --op get --endpoint "$IP_X:2379" --chave /e4/lat --serializavel
} | tee "$DIR/evidencias/$(ts)_latencia_lin_x_ser.txt"

# 2. leituras gravam no log? RAFT INDEX antes/depois de 100 leituras (5 rodadas por tipo) + linha de base sem leituras
leituras_e_indice() {
  local tipo r antes depois t0 t1 flag
  echo "tipo,rodada,indice_antes,indice_depois,delta,duracao_ms"
  for tipo in nenhuma linearizavel serializavel; do
    for r in 1 2 3 4 5; do
      flag=""; [ "$tipo" = serializavel ] && flag="--serializavel"
      read -r antes _ _ < <(etcd_indice_revisao "$X")
      t0="$(agora_ms)"
      if [ "$tipo" = nenhuma ]; then sleep 1
      else docker exec etcd-cliente python /app/latencia.py --op get --endpoint "$IP_X:2379" --chave /e4/lat --n 100 $flag >/dev/null; fi
      t1="$(agora_ms)"
      read -r depois _ _ < <(etcd_indice_revisao "$X")
      echo "$tipo,$r,$antes,$depois,$((depois - antes)),$((t1 - t0))"
    done
  done
}
evidencia "$DIR" leituras_x_raft_index -- leituras_e_indice

# 3. seguidor isolado da rede interna (continua acessível ao cliente)
isolamento() {
  echo "$(agora_iso) valor inicial gravado: $(docker exec "$L" etcdctl --endpoints=127.0.0.1:2379 put /e4/k ANTIGO)"
  sleep 1
  echo "$(agora_iso) $X lê (serializável) antes do isolamento: $(docker exec "$X" etcdctl --endpoints=127.0.0.1:2379 get /e4/k --print-value-only --consistency=s)"
  bash "$RAIZ/scripts/particionar.sh" isolar "$X"
  sleep 1
  echo "$(agora_iso) escrita do lado majoritário ($L): $(docker exec "$L" etcdctl --endpoints=127.0.0.1:2379 --command-timeout=5s put /e4/k NOVO 2>&1)"
  local i saida rc
  for i in 1 2 3 4 5; do
    saida="$(docker exec "$X" etcdctl --endpoints=127.0.0.1:2379 --command-timeout=3s get /e4/k --print-value-only 2>&1 | tail -1)"; rc=$?
    echo "$(agora_iso) [$i] $X get LINEARIZÁVEL -> $saida"
    saida="$(docker exec "$X" etcdctl --endpoints=127.0.0.1:2379 --command-timeout=3s get /e4/k --print-value-only --consistency=s 2>&1 | tail -1)"
    echo "$(agora_iso) [$i] $X get SERIALIZÁVEL -> $saida"
    echo "$(agora_iso) [$i] $L (maioria) get linearizável -> $(docker exec "$L" etcdctl --endpoints=127.0.0.1:2379 --command-timeout=3s get /e4/k --print-value-only 2>&1 | tail -1)"
  done
  echo "--- status durante o isolamento (endpoint único de cada membro)"
  for m in "${ETCD_MEMBROS[@]}"; do
    echo "$m: $(docker exec "$m" etcdctl --endpoints=127.0.0.1:2379 --command-timeout=3s endpoint status -w simple 2>&1 | tail -1)"
  done
  bash "$RAIZ/scripts/particionar.sh" religar "$X"
  local t0; t0="$(agora_ms)"
  for i in $(seq 1 40); do
    saida="$(docker exec "$X" etcdctl --endpoints=127.0.0.1:2379 get /e4/k --print-value-only --consistency=s 2>/dev/null)"
    [ "$saida" = "NOVO" ] && break; sleep 0.25
  done
  echo "$(agora_iso) $X depois de religar (serializável): $saida  (em $(( $(agora_ms) - t0 )) ms)"
  sleep 2
  echo "--- status depois de religar"
  docker exec "$L" etcdctl --endpoints="$EP" endpoint status -w table
}
evidencia "$DIR" seguidor_isolado -- isolamento

evidencia "$DIR" validacao_final -- bash "$RAIZ/scripts/validar.sh" etcd
