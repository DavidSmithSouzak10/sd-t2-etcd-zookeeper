"""Mostra o estado de cada servidor ZooKeeper (comando de 4 letras 'srvr').

Uso: python /app/srvr.py [ip ...]   (padrão: os 3 servidores da rede clientes)
Saída por servidor: modo (leader/follower/standalone/erro), zxid, época ZAB e contador.
"""
import socket
import sys

PADRAO = ["172.33.0.51", "172.33.0.52", "172.33.0.53"]


def srvr(ip, porta=2181, timeout=2.0):
    with socket.create_connection((ip, porta), timeout=timeout) as s:
        s.sendall(b"srvr")
        dados = b""
        while True:
            parte = s.recv(4096)
            if not parte:
                break
            dados += parte
    campos = {}
    for linha in dados.decode().splitlines():
        if ":" in linha:
            k, v = linha.split(":", 1)
            campos[k.strip()] = v.strip()
    return campos


def main():
    ips = sys.argv[1:] or PADRAO
    for ip in ips:
        try:
            c = srvr(ip)
            if "Mode" not in c:
                # servidor sem quórum responde "This ZooKeeper instance is not currently serving requests"
                print(f"{ip} modo=sem-servico zxid=- epoca=- contador=-")
                continue
            zxid = int(c["Zxid"], 16)
            print(f"{ip} modo={c['Mode']} zxid={c['Zxid']} epoca={zxid >> 32} contador={zxid & 0xFFFFFFFF}")
        except OSError as e:
            print(f"{ip} modo=inacessivel erro={e.__class__.__name__}")


if __name__ == "__main__":
    main()
