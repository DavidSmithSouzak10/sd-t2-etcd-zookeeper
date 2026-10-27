"""E7: quando um membro religado volta a ter líder e alcança o RAFT INDEX dos outros.

Uso (dentro do etcd-cliente; o host religa o membro ~1,5 s depois de iniciar):
  python /app/e7_alcance.py --alvo etcd1 [--prazo 60]
Consulta /v3/maintenance/status a cada ~10 ms e registra (epoch em s):
  - reconectou = 1º instante em que o alvo informa um líder (≠ 0) no mesmo termo dos outros;
  - alcancou   = 1º instante em que o RAFT INDEX do alvo ≥ o maior índice dos outros (lido logo antes).
Última linha: RES <reconectou> <alcancou> <indice_alvo_inicial> <indice_outros_inicial> <termo_alvo_inicial> <termo_final>
"""
import argparse
import http.client
import json
import time

MEMBROS = {"etcd1": "172.31.0.31", "etcd2": "172.31.0.32", "etcd3": "172.31.0.33"}


def status(ip, prazo=0.2):
    c = http.client.HTTPConnection(ip, 2379, timeout=prazo)
    try:
        c.request("POST", "/v3/maintenance/status", "{}", {"Content-Type": "application/json"})
        r = json.loads(c.getresponse().read())
        return int(r.get("raftIndex", 0)), r.get("leader", "0"), int(r.get("raftTerm", 0))
    finally:
        c.close()


def outros(alvo):
    idx, termo = 0, 0
    for n, ip in MEMBROS.items():
        if n == alvo:
            continue
        try:
            i, _, t = status(ip)
            idx, termo = max(idx, i), max(termo, t)
        except OSError:
            pass
    return idx, termo


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--alvo", required=True, choices=MEMBROS)
    p.add_argument("--prazo", type=float, default=60.0)
    a = p.parse_args()

    i0, _, t0 = status(MEMBROS[a.alvo], 1.0)
    o0, ot0 = outros(a.alvo)
    print(f"# pronto: {a.alvo} índice={i0} termo={t0}; outros índice={o0} termo={ot0}", flush=True)

    reconectou = alcancou = None
    termo_final = t0
    fim = time.time() + a.prazo
    while time.time() < fim and alcancou is None:
        oi, ot = outros(a.alvo)
        try:
            i, lid, t = status(MEMBROS[a.alvo])
        except OSError:
            time.sleep(0.01)
            continue
        termo_final = t
        if reconectou is None and lid != "0" and t >= ot:
            reconectou = time.time()
            print(f"# reconectou: líder visto, termo {t}", flush=True)
        if reconectou is not None and i >= oi:
            alcancou = time.time()
            print(f"# alcançou: índice {i} ≥ {oi}", flush=True)
        time.sleep(0.01)

    f = lambda x: "nan" if x is None else f"{x:.6f}"
    print(f"RES {f(reconectou)} {f(alcancou)} {i0} {o0} {t0} {termo_final}", flush=True)


if __name__ == "__main__":
    main()
