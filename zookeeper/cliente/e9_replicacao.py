"""E9-E3: set num servidor, get imediato (leitura local) em outro, watch de disparo único num terceiro.

Uso (dentro do zk-cliente):
  python /app/e9_replicacao.py --escreve 172.33.0.51:2181 --le 172.33.0.52:2181 --watch 172.33.0.53:2181 [--n 20]
(para o teste ser justo, --le deve ser um SEGUIDOR diferente de --escreve)
Saída: (1) leitura imediata em outro servidor, 20 vezes; (2) quantas vezes um watch registrado uma vez dispara
com 3 mudanças; (3) CSV do atraso do watch (set enviado -> callback), n repetições.
"""
import argparse
import logging
import threading
import time
from datetime import datetime

from kazoo.client import KazooClient

CAMINHO = "/e9/replicada"


def cliente(h):
    c = KazooClient(hosts=h, timeout=5.0)
    c.start(timeout=5.0)
    return c


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--n", type=int, default=20)
    p.add_argument("--escreve", required=True)
    p.add_argument("--le", required=True)
    p.add_argument("--watch", required=True)
    a = p.parse_args()
    logging.basicConfig(level=logging.ERROR)
    c1, c3, c2 = cliente(a.escreve), cliente(a.le), cliente(a.watch)
    c1.ensure_path(CAMINHO)

    print(f"## 1. set em {a.escreve} e get imediato (leitura local) em {a.le}")
    print("rep,valor_escrito,valor_lido,igual")
    antigos = 0
    for i in range(1, a.n + 1):
        v = f"v{i}-{time.time_ns()}".encode()
        c1.set(CAMINHO, v)
        lido, _ = c3.get(CAMINHO)
        antigos += lido != v
        print(f"{i},{v.decode()},{lido.decode()},{lido == v}")
    print(f"leituras com valor antigo: {antigos} de {a.n}")

    print(f"\n## 2. watch registrado UMA vez em {a.watch}, depois 3 mudanças via {a.escreve}")
    eventos = []
    c2.get(CAMINHO, watch=lambda ev: eventos.append(ev))
    for k in range(3):
        c1.set(CAMINHO, f"mudanca{k}".encode())
        time.sleep(0.3)
    time.sleep(0.5)
    print(f"mudanças: 3; disparos do watch: {len(eventos)}; eventos: {[(e.type, e.path) for e in eventos]}")

    print(f"\n## 3. atraso do watch (set em {a.escreve} -> callback em {a.watch}), re-registrando a cada vez")
    print("rep,inicio_iso,duracao_ms,exit")
    for i in range(1, a.n + 1):
        chegou = threading.Event()
        t = {}
        def cb(ev, t=t, chegou=chegou):
            t["fim"] = time.perf_counter()
            chegou.set()
        c2.get(CAMINHO, watch=cb)
        inicio = datetime.now().astimezone().isoformat(timespec="milliseconds")
        t0 = time.perf_counter()
        c1.set(CAMINHO, f"w{i}".encode())
        rc = 0 if chegou.wait(5) else 1
        ms = (t["fim"] - t0) * 1000 if rc == 0 else float("nan")
        print(f"{i},{inicio},{ms:.3f},{rc}", flush=True)
        time.sleep(0.05)
    for c in (c1, c2, c3):
        c.stop()


if __name__ == "__main__":
    main()
