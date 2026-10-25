#!/usr/bin/env bash
# E1: subida e topologia do etcd.
# Uso (da raiz do repositório): experimentos/E1-subida/executar.sh [repeticoes=5]
# 1) recria o cluster do zero N vezes: líder, termo, RAFT INDEX e tempo até ficar saudável -> CSV
# 2) na última subida: member list, endpoint status, endpoint health (evidência)
# 3) RAFT INDEX em repouso: 7 amostras a cada 10 s, sem nenhum cliente escrevendo
source "$(dirname "$0")/../../scripts/lib.sh"
DIR="$RAIZ/experimentos/E1-subida"
N="${1:-5}"
COMPOSE=(docker compose -f "$(caminho_host "$RAIZ/etcd/docker-compose.yml")")
declare -A NOME=([172.31.0.31:2379]=etcd1 [172.31.0.32:2379]=etcd2 [172.31.0.33:2379]=etcd3)

mkdir -p "$RAIZ/resultados" "$DIR/evidencias"
csv="$RAIZ/resultados/$(ts)_e1_subida_ate_saudavel.csv"
echo "rep,inicio_iso,duracao_ms,exit,lider,termo,raft_index" > "$csv"
log="$DIR/evidencias/$(ts)_subidas_do_zero.txt"

for i in $(seq 1 "$N"); do
  "${COMPOSE[@]}" down -v >/dev/null 2>&1 || { erro "down falhou"; exit 1; }
  ini_iso="$(agora_iso)"; t0="$(agora_ms)"
  "${COMPOSE[@]}" up -d >/dev/null 2>&1 || { erro "up falhou"; exit 1; }
  rc=1
  for _ in $(seq 1 120); do   # até 60 s
    if docker exec etcd1 etcdctl --endpoints="$EP" --command-timeout=1s endpoint health >/dev/null 2>&1; then rc=0; break; fi
    sleep 0.5
  done
  t1="$(agora_ms)"
  status="$(docker exec etcd1 etcdctl --endpoints="$EP" endpoint status -w simple 2>/dev/null)"
  lider="$(echo "$status" | awk -F', ' '$5=="true"{print $1}')"
  termo="$(echo "$status" | awk -F', ' '{print $7}' | sort -u | tr '\n' ' ' | sed 's/ $//')"
  indice="$(echo "$status" | awk -F', ' '{print $8}' | sort -u | tr '\n' ' ' | sed 's/ $//')"
  echo "$i,$ini_iso,$((t1 - t0)),$rc,${NOME[$lider]:-?},$termo,$indice" >> "$csv"
  { echo "## subida $i ($ini_iso): saudável em $((t1 - t0)) ms (exit=$rc)"; echo "$status"; echo; } | tee -a "$log"
done
info "subidas: ${csv#$RAIZ/}"
"$PY" "$(caminho_host "$RAIZ/scripts/estatistica.py")" "$(caminho_host "$csv")"
echo; info "líder por subida:"; cut -d, -f1,5,6,7 "$csv" | column -t -s,

# pré-condição para as evidências da topologia
if ! bash "$RAIZ/scripts/validar.sh" etcd; then erro "cluster não saudável"; exit 1; fi
evidencia "$DIR" member_list     -- docker exec etcd1 etcdctl --endpoints="$EP" member list -w table
evidencia "$DIR" endpoint_status -- docker exec etcd1 etcdctl --endpoints="$EP" endpoint status -w table
evidencia "$DIR" endpoint_health -- docker exec etcd1 etcdctl --endpoints="$EP" endpoint health
evidencia "$DIR" redes -- bash -c 'for m in etcd1 etcd2 etcd3 etcd-cliente; do
  echo "$m: $(docker inspect -f "{{range \$k,\$v := .NetworkSettings.Networks}}{{\$k}}={{\$v.IPAddress}} {{end}}" $m)  mem_limit=$(docker inspect -f "{{.HostConfig.Memory}}" $m)"; done'

# RAFT INDEX em repouso (nenhum cliente escreve; só o healthcheck do compose roda a cada 5 s)
evidencia "$DIR" raft_index_repouso -- bash -c '
  for k in 0 1 2 3 4 5 6; do
    echo "$(date +%H:%M:%S) $(docker exec etcd1 etcdctl --endpoints='"$EP"' endpoint status -w simple | awk -F", " "{printf \"%s idx=%s  \", \$1, \$8}")"
    [ $k -lt 6 ] && sleep 10
  done'
