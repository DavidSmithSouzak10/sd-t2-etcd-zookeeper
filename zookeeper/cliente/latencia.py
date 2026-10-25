"""Mede a latência de set/get no ZooKeeper de dentro da rede de clientes (equivalente ao etcd/cliente/latencia.py).

Uso (dentro do contêiner zk-cliente):
  python /app/latencia.py --op set --servidor 172.33.0.52:2181 --n 20
  python /app/latencia.py --op get --servidor 172.33.0.53:2181 --n 20 [--sync]

Conecta a UM servidor (como o endpoint único no etcd). A 1ª operação é aquecimento e não entra na medição.
--sync faz sync(caminho) antes de cada get (leitura atualizada; equivale ao get linearizável do etcd).
Saída (stdout): CSV rep,inicio_iso,duracao_ms,exit, o mesmo formato de scripts/medir.sh.
"""
import argparse
import logging
import sys
import time
from datetime import datetime

from kazoo.client import KazooClient


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--op", choices=["set", "get"], required=True)
    p.add_argument("--servidor", required=True, help="host:porta de UM servidor")
    p.add_argument("--n", type=int, default=5)
    p.add_argument("--caminho", default="/lat/chave")
    p.add_argument("--sync", action="store_true", help="sync antes de cada get")
    a = p.parse_args()

    logging.basicConfig(level=logging.ERROR)
    zk = KazooClient(hosts=a.servidor, timeout=5.0, connection_retry={"max_tries": 0})
    zk.start(timeout=5.0)

    def operacao(i):
        if a.op == "set":
            return zk.set(a.caminho, f"v{i}".encode())
        if a.sync:
            zk.sync(a.caminho)
        return zk.get(a.caminho)

    # aquecimento: garante que o znode existe
    zk.ensure_path(a.caminho)
    operacao(0)

    print("rep,inicio_iso,duracao_ms,exit")
    for i in range(1, a.n + 1):
        inicio = datetime.now().astimezone().isoformat(timespec="milliseconds")
        t0 = time.perf_counter()
        try:
            operacao(i)
            rc = 0
        except Exception as e:
            rc = 1
            print(f"rep {i}: {e!r}", file=sys.stderr)
        ms = (time.perf_counter() - t0) * 1000
        print(f"{i},{inicio},{ms:.3f},{rc}", flush=True)
    zk.stop()


if __name__ == "__main__":
    main()
