#!/usr/bin/env bash
# E0 (ensaio): limite de tamanho de requisição e latência × tamanho, no etcd e no ZooKeeper.
# Uso (da raiz do repositório): experimentos/E0-ensaio/executar.sh
source "$(dirname "$0")/../../scripts/lib.sh"
DIR="$RAIZ/experimentos/E0-ensaio"

# 1. pré-condição
if ! bash "$RAIZ/scripts/validar.sh" todos; then erro "cluster não está saudável: E0 abortado"; exit 1; fi

# 2. estado inicial
evidencia "$DIR" estado_inicial -- bash -c "
  docker exec etcd1 etcdctl --endpoints=$EP endpoint status -w table
  docker exec zk-cliente python /app/srvr.py"

# 3. limite de tamanho (cada tentativa com conexão nova)
evidencia "$DIR" limite_etcd -- docker exec -i etcd-cliente python - <<'EOF'
import base64, http.client, json
MiB = 1024 * 1024
for tam in [int(1.0 * MiB), int(1.4 * MiB), int(1.6 * MiB), int(2.0 * MiB)]:
    conn = http.client.HTTPConnection("172.31.0.32", 2379, timeout=10)
    corpo = {"key": base64.b64encode(b"/e0/grande").decode(), "value": base64.b64encode(b"x" * tam).decode()}
    try:
        conn.request("POST", "/v3/kv/put", json.dumps(corpo), {"Content-Type": "application/json"})
        r = conn.getresponse(); dados = r.read().decode(errors="replace")
        print(f"valor={tam} bytes ({tam / MiB:.1f} MiB): HTTP {r.status} {dados[:300]}")
    except Exception as e:
        print(f"valor={tam} bytes ({tam / MiB:.1f} MiB): EXCECAO {e!r}")
    finally:
        conn.close()
EOF

evidencia "$DIR" limite_zk -- docker exec -i zk-cliente python - <<'EOF'
import logging
from kazoo.client import KazooClient
logging.basicConfig(level=logging.CRITICAL)
for tam in [900_000, 1_100_000, 2_000_000]:
    zk = KazooClient(hosts="172.33.0.52:2181", timeout=5.0, connection_retry={"max_tries": 0}, command_retry={"max_tries": 0})
    zk.start(timeout=5.0)
    zk.ensure_path("/e0/grande")
    try:
        zk.set("/e0/grande", b"x" * tam)
        print(f"valor={tam} bytes: ACEITO")
    except Exception as e:
        print(f"valor={tam} bytes: RECUSADO {type(e).__name__} {e}")
    finally:
        try:
            zk.stop(); zk.close()
        except Exception:
            pass
EOF

# 4. latência × tamanho (5 repetições cada)
for tam in 1024 102400 524288; do
  scripts/latencia.sh etcd "e0_put_etcd2_${tam}B" 5 -- --op put --endpoint 172.31.0.32:2379 --chave /e0/lat --tamanho "$tam"
  scripts/latencia.sh zk "e0_set_zk2_${tam}B" 5 -- --op set --servidor 172.33.0.52:2181 --caminho /e0/lat --tamanho "$tam"
done | tee "$DIR/evidencias/$(ts)_latencia_tamanho.txt"

# 5. pós-condição
evidencia "$DIR" validacao_final -- bash "$RAIZ/scripts/validar.sh" todos
