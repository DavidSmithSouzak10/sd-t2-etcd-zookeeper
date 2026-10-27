"""E8/S4: pausa longa do detentor de uma trava com lease, e o fencing token (revisão da chave da trava).

Uso (dentro do etcd-cliente): python /app/e8_fencing.py [--endpoint 172.31.0.32:2379] [--ttl 5] [--pausa 9]
  A pega a trava com um lease de TTL curto e "pausa" (como uma pausa de GC ou um docker pause): para de renovar.
  B pede a mesma trava e espera. Quando o lease de A expira, B pega a trava e grava o recurso.
  A "acorda" achando que ainda tem a trava e tenta gravar de dois jeitos:
    - ingênuo: put direto  -> sobrescreve o trabalho de B (violação da exclusão mútua);
    - com fencing: txn que só grava se a chave da trava de A ainda existir com a mesma revisão (o token).
"""
import argparse
import base64
import http.client
import json
import threading
import time


def b64(s):
    return base64.b64encode(s.encode()).decode()


def d64(s):
    return base64.b64decode(s).decode()


class Cliente:
    def __init__(self, endpoint, prazo=30):
        host, porta = endpoint.split(":")
        self.c = http.client.HTTPConnection(host, int(porta), timeout=prazo)

    def post(self, caminho, corpo):
        self.c.request("POST", caminho, json.dumps(corpo), {"Content-Type": "application/json"})
        r = self.c.getresponse()
        dados = json.loads(r.read())
        if r.status != 200:
            raise RuntimeError(f"HTTP {r.status}: {dados}")
        return dados


def criacao(cli, chave):
    """create_revision da chave da trava: é o fencing token (cresce a cada nova aquisição)."""
    return int(cli.post("/v3/kv/range", {"key": b64(chave)})["kvs"][0]["create_revision"])


T0 = time.time()


def log(quem, msg):
    print(f"t={time.time() - T0:6.2f}s [{quem}] {msg}", flush=True)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--endpoint", default="172.31.0.32:2379")
    p.add_argument("--ttl", type=int, default=5)
    p.add_argument("--pausa", type=float, default=9.0)
    a = p.parse_args()
    trava, recurso = "/e8/fencing/trava", "/e8/fencing/recurso"

    ca = Cliente(a.endpoint)
    ca.post("/v3/kv/put", {"key": b64(recurso), "value": b64("inicial")})
    lease_a = ca.post("/v3/lease/grant", {"TTL": a.ttl})["ID"]
    chave_a = d64(ca.post("/v3/lock/lock", {"name": b64(trava), "lease": lease_a})["key"])
    token_a = criacao(ca, chave_a)
    log("A", f"pegou a trava: chave {chave_a}, fencing token (revisão) = {token_a}; lease TTL {a.ttl} s")

    def b():
        cb = Cliente(a.endpoint)
        lease_b = cb.post("/v3/lease/grant", {"TTL": 30})["ID"]
        log("B", "pede a mesma trava e espera")
        r = cb.post("/v3/lock/lock", {"name": b64(trava), "lease": lease_b})
        token_b = criacao(cb, d64(r["key"]))
        log("B", f"pegou a trava: chave {d64(r['key'])}, fencing token = {token_b}")
        cb.post("/v3/kv/put", {"key": b64(recurso), "value": b64(f"escrito por B (token {token_b})")})
        log("B", "gravou o recurso")
        cb.post("/v3/lock/unlock", {"key": r["key"]})
        cb.post("/v3/lease/revoke", {"ID": lease_b})

    tb = threading.Thread(target=b)
    tb.start()
    log("A", f"PAUSA de {a.pausa} s sem renovar o lease (o processo continua achando que tem a trava)")
    time.sleep(a.pausa)
    tb.join()
    log("A", "acordou; vai gravar o recurso")

    ca = Cliente(a.endpoint)
    r = ca.post("/v3/kv/txn", {
        "compare": [{"key": b64(chave_a), "target": "CREATE", "result": "EQUAL", "create_revision": str(token_a)}],
        "success": [{"request_put": {"key": b64(recurso), "value": b64(f"escrito por A (token {token_a})")}}],
    })
    log("A", f"gravação COM fencing (só se a chave da trava com token {token_a} ainda existir): "
             f"{'ACEITA' if r.get('succeeded') else 'RECUSADA'}")
    v = ca.post("/v3/kv/range", {"key": b64(recurso)})["kvs"][0]
    log("-", f"recurso agora: {d64(v['value'])!r}")
    ca.post("/v3/kv/put", {"key": b64(recurso), "value": b64(f"escrito por A SEM fencing (token {token_a})")})
    v = ca.post("/v3/kv/range", {"key": b64(recurso)})["kvs"][0]
    log("A", f"gravação SEM fencing: aceita; recurso agora: {d64(v['value'])!r}  <- o trabalho de B foi perdido")


if __name__ == "__main__":
    main()
