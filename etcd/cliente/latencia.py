"""Mede a latência de put/get no etcd de dentro da rede de clientes (sem o overhead do docker exec).

Uso (dentro do contêiner etcd-cliente):
  python /app/latencia.py --op put --endpoint 172.31.0.32:2379 --n 20 [--tamanho 102400]
  python /app/latencia.py --op get --endpoint 172.31.0.33:2379 --n 20 [--serializavel]

Fala com a API HTTP/JSON do etcd (gRPC-gateway, /v3/kv/put e /v3/kv/range) por uma conexão
persistente, como um cliente real. A 1ª operação é aquecimento e não entra na medição.
Saída (stdout): CSV rep,inicio_iso,duracao_ms,exit, o mesmo formato de scripts/medir.sh.
"""
import argparse
import base64
import http.client
import json
import sys
import time
from datetime import datetime


def b64(texto):
    return base64.b64encode(texto.encode()).decode()


def chamar(conn, caminho, corpo):
    conn.request("POST", caminho, json.dumps(corpo), {"Content-Type": "application/json"})
    resp = conn.getresponse()
    dados = resp.read()
    if resp.status != 200:
        raise RuntimeError(f"HTTP {resp.status}: {dados[:200]!r}")
    return json.loads(dados)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--op", choices=["put", "get"], required=True)
    p.add_argument("--endpoint", required=True, help="host:porta de UM membro (endpoint único)")
    p.add_argument("--n", type=int, default=5)
    p.add_argument("--chave", default="/lat/chave")
    p.add_argument("--serializavel", action="store_true", help="get serializável (local) em vez de linearizável")
    p.add_argument("--tamanho", type=int, default=0, help="put: tamanho do valor em bytes (0 = valor curto)")
    p.add_argument("--timeout", type=float, default=5.0)
    a = p.parse_args()

    host, porta = a.endpoint.split(":")
    conn = http.client.HTTPConnection(host, int(porta), timeout=a.timeout)

    def operacao(i):
        if a.op == "put":
            valor = "x" * a.tamanho if a.tamanho else f"v{i}"
            return chamar(conn, "/v3/kv/put", {"key": b64(a.chave), "value": b64(valor)})
        corpo = {"key": b64(a.chave)}
        if a.serializavel:
            corpo["serializable"] = True
        return chamar(conn, "/v3/kv/range", corpo)

    # aquecimento: abre a conexão e garante que a chave existe para o get
    try:
        chamar(conn, "/v3/kv/put", {"key": b64(a.chave), "value": b64("aquecimento")})
        operacao(0)
    except Exception as e:
        print(f"falha no aquecimento: {e}", file=sys.stderr)

    print("rep,inicio_iso,duracao_ms,exit")
    for i in range(1, a.n + 1):
        inicio = datetime.now().astimezone().isoformat(timespec="milliseconds")
        t0 = time.perf_counter()
        try:
            operacao(i)
            rc = 0
        except Exception as e:
            rc = 1
            print(f"rep {i}: {e}", file=sys.stderr)
            conn.close()
            conn = http.client.HTTPConnection(host, int(porta), timeout=a.timeout)
        ms = (time.perf_counter() - t0) * 1000
        print(f"{i},{inicio},{ms:.3f},{rc}", flush=True)


if __name__ == "__main__":
    main()
