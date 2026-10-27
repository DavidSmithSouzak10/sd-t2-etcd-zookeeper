"""E9-E7: quando um servidor ZooKeeper religado volta como seguidor e alcança o zxid do líder.

Uso (dentro do zk-cliente; o host religa o servidor ~1,5 s depois de iniciar):
  python /app/e9_alcance.py --alvo zk1 [--prazo 90]
Consulta `srvr` a cada ~10 ms e registra (epoch em s):
  - reconectou = 1º instante em que o alvo volta a responder como follower (ou leader);
  - alcancou   = 1º instante em que o zxid do alvo ≥ o maior zxid dos outros (lido logo antes).
Última linha: RES <reconectou> <alcancou> <modo_inicial> <zxid_outros_inicial> <modo_final> <zxid_final>
"""
import argparse
import time

from srvr import srvr

SERVIDORES = {"zk1": "172.33.0.51", "zk2": "172.33.0.52", "zk3": "172.33.0.53"}


def estado(ip, prazo=0.2):
    c = srvr(ip, timeout=prazo)
    if "Mode" not in c:
        return "sem-servico", 0
    return c["Mode"], int(c["Zxid"], 16)


def outros(alvo):
    z = 0
    for n, ip in SERVIDORES.items():
        if n == alvo:
            continue
        try:
            z = max(z, estado(ip)[1])
        except OSError:
            pass
    return z


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--alvo", required=True, choices=SERVIDORES)
    p.add_argument("--prazo", type=float, default=90.0)
    a = p.parse_args()

    try:
        m0 = estado(SERVIDORES[a.alvo], 1.0)[0]
    except OSError:
        m0 = "inacessivel"
    o0 = outros(a.alvo)
    print(f"# pronto: {a.alvo} modo={m0}; outros zxid={o0:#x}", flush=True)

    reconectou = alcancou = None
    modo, z = m0, 0
    fim = time.time() + a.prazo
    while time.time() < fim and alcancou is None:
        oz = outros(a.alvo)
        try:
            modo, z = estado(SERVIDORES[a.alvo])
        except OSError:
            time.sleep(0.01)
            continue
        if reconectou is None and modo in ("follower", "leader"):
            reconectou = time.time()
            print(f"# reconectou: modo {modo}, zxid {z:#x}", flush=True)
        if reconectou is not None and z >= oz:
            alcancou = time.time()
            print(f"# alcançou: zxid {z:#x} ≥ {oz:#x}", flush=True)
        time.sleep(0.01)

    f = lambda x: "nan" if x is None else f"{x:.6f}"
    print(f"RES {f(reconectou)} {f(alcancou)} {m0} {o0:#x} {modo} {z:#x}", flush=True)


if __name__ == "__main__":
    main()
