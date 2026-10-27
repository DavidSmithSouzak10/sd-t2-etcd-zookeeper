"""E9-E5/E6: observa a troca de líder no ZooKeeper de dentro da rede de clientes.

Uso (dentro do zk-cliente; o host derruba ou isola o líder ~1,5 s depois de iniciar):
  python /app/e9_eleicao.py [--particao] [--prazo 30]
Consulta `srvr` (comando de 4 letras) nos 3 servidores a cada ~10 ms e registra (epoch em s):
  - queda = 1ª de 2 consultas seguidas sem resposta do líder antigo (prazo de 50 ms cada);
    com --particao não se espera a queda (o líder isolado continua acessível ao cliente);
  - novo  = 1º instante em que um sobrevivente se declara `leader` (Mode: leader);
  - sobreviventes "sem serviço" (eleição em curso) são impressos quando mudam de estado.
Última linha: RES <queda> <novo> <epoca_antes> <epoca_depois> <lider_antigo> <lider_novo> ("nan" se não houve).
A época ZAB são os 32 bits altos do zxid.
"""
import argparse
import time

from srvr import srvr

SERVIDORES = {"zk1": "172.33.0.51", "zk2": "172.33.0.52", "zk3": "172.33.0.53"}


def estado(ip, prazo):
    """(modo, época) do servidor; modo 'sem-servico' se ele responde mas não atende."""
    c = srvr(ip, timeout=prazo)
    if "Mode" not in c:
        return "sem-servico", None
    return c["Mode"], int(c["Zxid"], 16) >> 32


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--particao", action="store_true")
    p.add_argument("--prazo", type=float, default=30.0)
    a = p.parse_args()

    antigo, epoca_antes = None, 0
    for nome, ip in SERVIDORES.items():
        modo, ep = estado(ip, 1.0)
        if modo == "leader":
            antigo = nome
        epoca_antes = max(epoca_antes, ep or 0)
    sobreviventes = [n for n in SERVIDORES if n != antigo]
    print(f"# pronto: líder={antigo} época={epoca_antes}", flush=True)

    queda = novo = None
    falhas_seguidas, t_primeira_falha = 0, None
    epoca_depois, lider_novo = epoca_antes, "nan"
    ultimo = {}
    fim = time.time() + a.prazo
    while time.time() < fim:
        if novo is not None and (a.particao or queda is not None):
            break
        if queda is None and not a.particao:
            try:
                estado(SERVIDORES[antigo], 0.05)
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
                    modo, ep = estado(SERVIDORES[n], 0.2)
                except OSError:
                    modo, ep = "inacessivel", None
                if ultimo.get(n) != modo:
                    print(f"# {time.time():.3f} {n} -> {modo} (época {ep})", flush=True)
                    ultimo[n] = modo
                if modo == "leader":
                    novo, epoca_depois, lider_novo = time.time(), ep, n
                    break
        time.sleep(0.01)

    f = lambda t: "nan" if t is None else f"{t:.6f}"
    print(f"RES {f(queda)} {f(novo)} {epoca_antes} {epoca_depois} {antigo} {lider_novo}", flush=True)


if __name__ == "__main__":
    main()
