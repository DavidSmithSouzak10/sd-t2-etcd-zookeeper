"""E9-E5: o que um cliente ligado a UM servidor consegue fazer (quadro servidores ativos × operações).

Uso (dentro do zk-cliente): python /app/e9_operacoes.py 172.33.0.51 [172.33.0.52 ...] [--prazo 3]
Para cada servidor, com um cliente kazoo só para ele: abrir sessão, escrita (set), leitura local (get)
e sync + get, cada uma com prazo. Uma linha por operação, com o resultado ou o tipo do erro.
"""
import argparse
import logging
import time
from datetime import datetime

from kazoo.client import KazooClient
from kazoo.retry import KazooRetry

from srvr import srvr

CAMINHO = "/e9/quorum"


def agora():
    return datetime.now().astimezone().strftime("%H:%M:%S.%f")[:-3]


def tentar(rotulo, ip, f):
    try:
        r = f()
        print(f"{agora()} {ip} {rotulo:<16} -> {r}", flush=True)
    except Exception as e:
        print(f"{agora()} {ip} {rotulo:<16} -> ERRO {type(e).__name__}", flush=True)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("servidores", nargs="+")
    p.add_argument("--prazo", type=float, default=3.0)
    a = p.parse_args()
    logging.basicConfig(level=logging.CRITICAL)

    for ip in a.servidores:
        try:
            c = srvr(ip, timeout=a.prazo)
            print(f"{agora()} {ip} srvr             -> {c.get('Mode', 'sem serviço')}", flush=True)
        except OSError as e:
            print(f"{agora()} {ip} srvr             -> ERRO {type(e).__name__}", flush=True)
        cli = KazooClient(hosts=f"{ip}:2181", timeout=a.prazo,
                          connection_retry=KazooRetry(max_tries=0), command_retry=KazooRetry(max_tries=0))
        try:
            cli.start(timeout=a.prazo)
        except Exception as e:
            print(f"{agora()} {ip} sessão           -> ERRO {type(e).__name__} (não abriu)", flush=True)
            try:
                cli.stop()
            except Exception:
                pass
            continue
        print(f"{agora()} {ip} sessão           -> aberta", flush=True)
        valor = f"v-{int(time.time())}".encode()

        def escrever():
            if cli.exists_async(CAMINHO).get(timeout=a.prazo) is None:
                cli.create_async(CAMINHO, valor).get(timeout=a.prazo)
            else:
                cli.set_async(CAMINHO, valor).get(timeout=a.prazo)
            return "OK"

        tentar("escrita (set)", ip, escrever)
        tentar("leitura local", ip, lambda: cli.get_async(CAMINHO).get(timeout=a.prazo)[0].decode())

        def com_sync():
            cli.sync_async(CAMINHO).get(timeout=a.prazo)
            return cli.get_async(CAMINHO).get(timeout=a.prazo)[0].decode()

        tentar("sync + leitura", ip, com_sync)
        try:
            cli.stop()
        except Exception:
            pass


if __name__ == "__main__":
    main()
