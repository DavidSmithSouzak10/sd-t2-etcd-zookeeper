#!/usr/bin/env bash
# E2: caminho de uma escrita no etcd (seguidor -> líder -> maioria -> resposta).
# Uso (da raiz do repositório): experimentos/E2-caminho/executar.sh
source "$(dirname "$0")/../../scripts/lib.sh"
DIR="$RAIZ/experimentos/E2-caminho"

if ! bash "$RAIZ/scripts/validar.sh" etcd; then erro "cluster não saudável: E2 abortado"; exit 1; fi
L="$(etcd_lider)"
SEG=(); for m in "${ETCD_MEMBROS[@]}"; do [ "$m" != "$L" ] && SEG+=("$m"); done
S="${SEG[0]}"; F="${SEG[1]}"
info "líder=$L  seguidor usado (endpoint único)=$S  outro seguidor=$F"
IP_S="${ETCD_IP_CLIENTE[$S]}"; IP_L="${ETCD_IP_CLIENTE[$L]}"

# 1. put em um seguidor (endpoint único), saída -w json; índice/revisão/termo antes e depois
evidencia "$DIR" put_em_seguidor -- bash -c "
  echo \"lider=$L seguidor=$S\"
  echo '--- antes (endpoint status dos 3 numa só chamada)'
  docker exec etcd1 etcdctl --endpoints=$EP endpoint status -w table
  echo '--- put no seguidor $S ($IP_S), -w json'
  docker exec etcd1 etcdctl --endpoints=$IP_S:2379 put /e2/chave valor1 -w json
  echo
  echo '--- depois'
  docker exec etcd1 etcdctl --endpoints=$EP endpoint status -w table
  echo '--- get no outro seguidor $F (-w json: revisão de criação/modificação)'
  docker exec etcd1 etcdctl --endpoints=${ETCD_IP_CLIENTE[$F]}:2379 get /e2/chave -w json"

# 2. 5 puts seguidos: quanto sobem a revisão e o RAFT INDEX a cada put (o healthcheck também entra no log)
revisao_x_indice() {
  local i ia ra ta id rd td rr resp
  for i in 1 2 3 4 5; do
    read -r ia ra ta < <(etcd_indice_revisao "$S")
    resp="$(docker exec etcd1 etcdctl --endpoints="$IP_S:2379" put /e2/chave "v$i" -w json)"
    read -r id rd td < <(etcd_indice_revisao "$S")
    rr="$(echo "$resp" | "$PY" -c "import json,sys; h=json.load(sys.stdin)['header']; print('revision', h['revision'], 'raft_term', h['raft_term'])")"
    echo "put $i: revisao $ra -> $rd | raft_index $ia -> $id | termo $ta -> $td | resposta: $rr"
  done
}
evidencia "$DIR" revisao_x_indice -- revisao_x_indice

# 3. quem envia bytes para quem: métricas etcd_network_peer_sent_bytes_total antes/depois de 1 put de 100 KiB no seguidor
evidencia "$DIR" metricas_encaminhamento -- docker exec -i etcd-cliente python - "$IP_S" <<'EOF'
import base64, http.client, json, re, sys, time, urllib.request
IPS = {"etcd1": "172.31.0.31", "etcd2": "172.31.0.32", "etcd3": "172.31.0.33"}
alvo = sys.argv[1]
def post(ip, caminho, corpo):
    c = http.client.HTTPConnection(ip, 2379, timeout=10)
    c.request("POST", caminho, json.dumps(corpo), {"Content-Type": "application/json"})
    return json.loads(c.getresponse().read())
membros = post("172.31.0.31", "/v3/cluster/member/list", {})["members"]
nome = {format(int(m["ID"]), "x"): m["name"] for m in membros}
def enviados():
    r = {}
    for n, ip in IPS.items():
        txt = urllib.request.urlopen(f"http://{ip}:2379/metrics", timeout=5).read().decode()
        for para, v in re.findall(r'etcd_network_peer_sent_bytes_total\{To="([0-9a-f]+)"\} ([0-9.e+]+)', txt):
            r[(n, nome.get(para, para))] = float(v)
    return r
antes = enviados()
valor = b"x" * 102400
resp = post(alvo, "/v3/kv/put", {"key": base64.b64encode(b"/e2/grande").decode(), "value": base64.b64encode(valor).decode()})
time.sleep(1.0)
depois = enviados()
print(f"put de {len(valor)} bytes enviado ao endpoint {alvo}; resposta: {resp['header']}")
print("bytes enviados entre pares durante o put (inclui heartbeats de ~1 s):")
for k in sorted(depois):
    print(f"  {k[0]} -> {k[1]}: {depois[k] - antes.get(k, 0):>10.0f} bytes")
EOF

# 4. confirmação: com 1 seguidor pausado o put funciona? com os 2 seguidores pausados (só o líder) funciona?
evidencia "$DIR" confirmacao_maioria -- bash -c "
  echo '--- pausando 1 seguidor ($F): restam líder $L + seguidor $S (2 de 3)'
  docker pause $F >/dev/null
  docker exec $L etcdctl --endpoints=127.0.0.1:2379 --command-timeout=5s put /e2/maioria com_2_de_3; echo \"exit=\$?\"
  echo '--- pausando também $S: só o líder $L (1 de 3)'
  docker pause $S >/dev/null
  docker exec $L etcdctl --endpoints=127.0.0.1:2379 --command-timeout=5s put /e2/maioria so_o_lider; echo \"exit=\$?\"
  docker unpause $S $F >/dev/null
  sleep 3
  echo '--- depois de despausar: valor final da chave'
  docker exec $L etcdctl --endpoints=$EP get /e2/maioria"

# 5. latência: put no seguidor (encaminhado) × put direto no líder, 20 repetições cada
L="$(etcd_lider)"; SEG=(); for m in "${ETCD_MEMBROS[@]}"; do [ "$m" != "$L" ] && SEG+=("$m"); done; S="${SEG[0]}"
{ info "líder agora: $L; seguidor: $S"
  scripts/latencia.sh etcd "e2_put_seguidor_${S}" 20 -- --op put --endpoint "${ETCD_IP_CLIENTE[$S]}:2379" --chave /e2/lat
  scripts/latencia.sh etcd "e2_put_lider_${L}" 20 -- --op put --endpoint "${ETCD_IP_CLIENTE[$L]}:2379" --chave /e2/lat
} | tee "$DIR/evidencias/$(ts)_latencia_seguidor_x_lider.txt"

evidencia "$DIR" validacao_final -- bash "$RAIZ/scripts/validar.sh" etcd
