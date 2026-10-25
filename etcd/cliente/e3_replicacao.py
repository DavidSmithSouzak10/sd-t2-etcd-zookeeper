"""E3: escrita em um membro, leitura imediata em outro e atraso do watch em um terceiro.

Uso (dentro do etcd-cliente):
  python /app/e3_replicacao.py --escreve 172.31.0.31 --le 172.31.0.33 --watch 172.31.0.32 --n 20 [--csv-watch]
Para cada repetição: inicia (uma vez) um watch na chave pelo membro --watch; faz put no --escreve;
logo em seguida get (linearizável) no --le; registra se o valor lido é o novo e o atraso até o evento do watch.
Com --csv-watch imprime só o CSV do atraso do watch (rep,inicio_iso,duracao_ms,exit).
"""
import argparse
import base64
import http.client
import json
import socket
import time
from datetime import datetime


def b64(s):
    return base64.b64encode(s.encode()).decode()


def post(conn, caminho, corpo):
    conn.request("POST", caminho, json.dumps(corpo), {"Content-Type": "application/json"})
    return json.loads(conn.getresponse().read())


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--escreve", required=True)
    p.add_argument("--le", required=True)
    p.add_argument("--watch", required=True)
    p.add_argument("--n", type=int, default=20)
    p.add_argument("--chave", default="/e3/replicada")
    p.add_argument("--csv-watch", action="store_true")
    a = p.parse_args()

    ce = http.client.HTTPConnection(a.escreve, 2379, timeout=5)
    cl = http.client.HTTPConnection(a.le, 2379, timeout=5)
    post(ce, "/v3/kv/put", {"key": b64(a.chave), "value": b64("inicio")})

    # watch pela API HTTP (stream): socket cru, cada evento chega como um objeto JSON
    w = socket.create_connection((a.watch, 2379), timeout=5)
    corpo = json.dumps({"create_request": {"key": b64(a.chave)}})
    w.sendall((f"POST /v3/watch HTTP/1.1\r\nHost: {a.watch}\r\nContent-Type: application/json\r\n"
               f"Content-Length: {len(corpo)}\r\n\r\n{corpo}").encode())
    buf = b""
    while b"created" not in buf:
        buf += w.recv(65536)
    buf = b""

    if a.csv_watch:
        print("rep,inicio_iso,duracao_ms,exit")
    else:
        print("rep,valor_escrito,valor_lido_em_outro,igual,atraso_watch_ms")
    for i in range(1, a.n + 1):
        valor = f"v{i}-{time.time_ns()}"
        inicio = datetime.now().astimezone().isoformat(timespec="milliseconds")
        t0 = time.perf_counter()
        post(ce, "/v3/kv/put", {"key": b64(a.chave), "value": b64(valor)})
        lido = post(cl, "/v3/kv/range", {"key": b64(a.chave)})
        lido_v = base64.b64decode(lido["kvs"][0]["value"]).decode() if lido.get("kvs") else None
        # espera o evento com este valor no stream do watch
        alvo = b64(valor).encode()
        rc = 0
        try:
            while alvo not in buf:
                buf += w.recv(65536)
            t_watch = (time.perf_counter() - t0) * 1000
        except socket.timeout:
            t_watch, rc = float("nan"), 1
        buf = buf[buf.index(alvo) + len(alvo):] if rc == 0 else b""
        if a.csv_watch:
            print(f"{i},{inicio},{t_watch:.3f},{rc}", flush=True)
        else:
            print(f"{i},{valor},{lido_v},{lido_v == valor},{t_watch:.3f}", flush=True)
        time.sleep(0.05)


if __name__ == "__main__":
    main()
