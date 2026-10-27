"""E5/E6: observa a troca de líder no etcd de dentro da rede de clientes.

Uso (dentro do etcd-cliente; o host derruba ou isola o líder ~1,5 s depois de iniciar):
  python /app/e5_eleicao.py [--particao] [--prazo 20]
Consulta /v3/maintenance/status nos 3 membros a cada ~10 ms e registra (epoch em s):
  - queda = 1ª de 2 consultas seguidas sem resposta do líder antigo (prazo de 50 ms cada);
    com --particao não se espera a queda (o líder isolado continua respondendo ao cliente);
  - novo  = 1º instante em que um sobrevivente informa um líder diferente do antigo (e diferente de 0).
Última linha: RES <queda> <novo> <termo_antes> <termo_depois> <lider_antigo> <lider_novo> ("nan" se não houve).
O t0 preciso (sinal ou desconexão) vem do `docker events` no host: ver evento_epoch em scripts/lib.sh.
"""
import argparse
import http.client
import json
import time

MEMBROS = {"etcd1": "172.31.0.31", "etcd2": "172.31.0.32", "etcd3": "172.31.0.33"}


def status(ip, prazo):
    c = http.client.HTTPConnection(ip, 2379, timeout=prazo)
    try:
        c.request("POST", "/v3/maintenance/status", "{}", {"Content-Type": "application/json"})
        r = json.loads(c.getresponse().read())
        return r["header"]["member_id"], r.get("leader", "0"), int(r.get("raftTerm", 0))
    finally:
        c.close()


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--particao", action="store_true")
    p.add_argument("--prazo", type=float, default=20.0)
    a = p.parse_args()

    ids, lider, termo_antes = {}, None, 0
    for nome, ip in MEMBROS.items():
        mid, lid, termo = status(ip, 1.0)
        ids[mid] = nome
        lider, termo_antes = lid, max(termo_antes, termo)
    antigo = ids[lider]
    sobreviventes = [n for n in MEMBROS if n != antigo]
    print(f"# pronto: líder={antigo} termo={termo_antes}", flush=True)

    queda = novo = None
    falhas_seguidas, t_primeira_falha = 0, None
    termo_depois, lider_novo = termo_antes, "nan"
    fim = time.time() + a.prazo
    while time.time() < fim:
        if novo is not None and (a.particao or queda is not None):
            break
        if queda is None and not a.particao:
            try:
                status(MEMBROS[antigo], 0.05)
                falhas_seguidas = 0
            except OSError:
                if falhas_seguidas == 0:
                    t_primeira_falha = time.time()
                falhas_seguidas += 1
                if falhas_seguidas >= 2:
                    queda = t_primeira_falha
        if novo is None:
            for n in sobreviventes:
                try:
                    _, lid, termo = status(MEMBROS[n], 0.2)
                except OSError:
                    continue
                if lid not in ("0", lider) and lid in ids:
                    novo, termo_depois, lider_novo = time.time(), termo, ids[lid]
                    print(f"# {n} informa novo líder {lider_novo} no termo {termo}", flush=True)
                    break
        time.sleep(0.01)

    f = lambda t: "nan" if t is None else f"{t:.6f}"
    print(f"RES {f(queda)} {f(novo)} {termo_antes} {termo_depois} {antigo} {lider_novo}", flush=True)


if __name__ == "__main__":
    main()
