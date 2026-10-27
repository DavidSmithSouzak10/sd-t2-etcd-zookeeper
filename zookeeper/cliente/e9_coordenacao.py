"""E9-E8: trava (kazoo Lock) e eleição (kazoo Election) sobre znodes efêmeros e sequenciais.

Uso (dentro do zk-cliente):
  python /app/e9_coordenacao.py --tipo trava|eleicao --ident A --morrer-em 6   # A pega e "morre" depois de 6 s
  python /app/e9_coordenacao.py --tipo trava|eleicao --ident B                 # B espera e assume
"Morrer" = os._exit sem fechar a sessão (como um processo derrubado): os znodes efêmeros de A só somem
quando a sessão expira no servidor (session timeout). Cada linha começa com o epoch (s) do evento.
"""
import argparse
import logging
import os
import time

from kazoo.client import KazooClient

HOSTS = "172.33.0.51:2181,172.33.0.52:2181,172.33.0.53:2181"
CAMINHOS = {"trava": "/e9/trava", "eleicao": "/e9/eleicao"}


def log(msg):
    print(f"{time.time():.6f} {msg}", flush=True)


def mostrar_fila(zk, caminho):
    for filho in sorted(zk.get_children(caminho), key=lambda n: n[-10:]):
        _, st = zk.get(f"{caminho}/{filho}")
        log(f"  znode {caminho}/{filho} ephemeralOwner=0x{st.ephemeralOwner:x} czxid=0x{st.czxid:x}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--tipo", choices=CAMINHOS, required=True)
    p.add_argument("--ident", required=True)
    p.add_argument("--morrer-em", type=float, default=0, help="0 = segura até ser derrubado de fora")
    p.add_argument("--timeout", type=float, default=10.0, help="session timeout pedido (s)")
    a = p.parse_args()
    logging.basicConfig(level=logging.CRITICAL)

    zk = KazooClient(hosts=HOSTS, timeout=a.timeout)
    zk.start(timeout=10)
    log(f"{a.ident}: sessão 0x{zk.client_id[0]:x}, timeout negociado {zk._session_timeout / 1000:.1f} s")
    caminho = CAMINHOS[a.tipo]

    def detentor():
        log(f"ADQUIRIU {a.ident} ({a.tipo})")
        mostrar_fila(zk, caminho)
        if a.morrer_em:
            time.sleep(a.morrer_em)
            log(f"MORREU {a.ident} (os._exit sem fechar a sessão)")
            os._exit(1)
        while True:
            time.sleep(1)

    if a.tipo == "trava":
        with zk.Lock(caminho, a.ident):
            detentor()
    else:
        zk.Election(caminho, a.ident).run(detentor)


if __name__ == "__main__":
    main()
