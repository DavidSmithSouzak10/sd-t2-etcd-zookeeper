"""E9-E4: o que um cliente ligado a UM servidor vê quando esse servidor é isolado do ensemble.

Uso (dentro do zk-cliente; o host isola o servidor ~2 s depois de iniciar):
  python /app/e9_isolado.py --alvo 172.33.0.51:2181 --maioria 172.33.0.53:2181 --escrever-em 4 --duracao 30
--alvo aceita uma lista "ip1:2181,ip2:2181,..." (usada na ordem dada, sem embaralhar): assim dá para ver se o
cliente troca de servidor sozinho; cada linha mostra o servidor ligado no momento.
A cada 0,5 s: get local e sync+get no servidor alvo. Em t = --escrever-em s, grava NOVO pela maioria.
Cada chamada ao alvo tem prazo de --prazo s: sem prazo, o kazoo enfileira o pedido enquanto a sessão está
SUSPENDED e espera a reconexão indefinidamente (observado na 1ª execução do E9-E4).
"""
import argparse
import logging
import time
from datetime import datetime

from kazoo.client import KazooClient
from kazoo.retry import KazooRetry

CAMINHO = "/e9/isolado"


def agora():
    return datetime.now().astimezone().strftime("%H:%M:%S.%f")[:-3]


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--alvo", required=True)
    p.add_argument("--maioria", required=True)
    p.add_argument("--escrever-em", type=float, default=4.0)
    p.add_argument("--duracao", type=float, default=30.0)
    p.add_argument("--prazo", type=float, default=2.0)
    a = p.parse_args()
    logging.basicConfig(level=logging.CRITICAL)

    maioria = KazooClient(hosts=a.maioria, timeout=10.0)
    maioria.start(timeout=5.0)
    maioria.ensure_path(CAMINHO)
    maioria.set(CAMINHO, b"ANTIGO")
    maioria.ensure_path(CAMINHO + "_escrita")
    # cliente só com o alvo; sem novas tentativas, para ver cada falha
    alvo = KazooClient(hosts=a.alvo, timeout=10.0, randomize_hosts=False,
                       connection_retry=KazooRetry(max_tries=-1, max_delay=1), command_retry=KazooRetry(max_tries=0))

    def ligado():
        try:
            return alvo._connection._socket.getpeername()[0]
        except Exception:
            return "-"

    alvo.add_listener(lambda estado: print(f"{agora()} [sessão do cliente no alvo] estado -> {estado} ({ligado()})",
                                           flush=True))
    alvo.start(timeout=5.0)
    time.sleep(0.5)
    print(f"{agora()} início: alvo={a.alvo} maioria={a.maioria}; valor inicial ANTIGO", flush=True)

    t0 = time.time(); escrito = False
    while time.time() - t0 < a.duracao:
        if not escrito and time.time() - t0 >= a.escrever_em:
            try:
                maioria.set(CAMINHO, b"NOVO")
                print(f"{agora()} >>> maioria gravou NOVO", flush=True)
            except Exception as e:
                print(f"{agora()} >>> maioria FALHOU ao gravar: {e!r}", flush=True)
            escrito = True
        try:
            v, _ = alvo.get_async(CAMINHO).get(timeout=a.prazo)
            local = v.decode()
        except Exception as e:
            local = f"ERRO {type(e).__name__}"
        try:
            alvo.sync_async(CAMINHO).get(timeout=a.prazo)
            v, _ = alvo.get_async(CAMINHO).get(timeout=a.prazo)
            comsync = v.decode()
        except Exception as e:
            comsync = f"ERRO {type(e).__name__}"
        try:
            alvo.set_async(CAMINHO + "_escrita", b"x").get(timeout=a.prazo)
            escrita = "OK"
        except Exception as e:
            escrita = f"ERRO {type(e).__name__}"
        print(f"{agora()} alvo({ligado()}): get local={local:<22} sync+get={comsync:<22} escrita={escrita}", flush=True)
        time.sleep(0.5)
    print(f"{agora()} fim", flush=True)
    maioria.stop()
    try:
        alvo.stop()
    except Exception:
        pass


if __name__ == "__main__":
    main()
