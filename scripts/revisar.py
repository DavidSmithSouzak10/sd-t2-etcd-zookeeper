"""Confere automaticamente os critérios marcados com 🤖 em docs/criterios-avaliacao.md.

Uso (na raiz do repositório): python scripts/revisar.py
Não substitui a revisão humana: confere estrutura (existe? está preenchido? tem >= 5 medições?),
não a qualidade do conteúdo. Saída: tabela Markdown; termina com o total de pendências.
"""
import csv
import json
import re
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
PENDENTE = "_pendente_"
resultados = []  # (id, descrição, ok: bool | None, detalhe)


def registrar(id_, desc, ok, detalhe=""):
    resultados.append((id_, desc, ok, detalhe))


def secao(texto, titulo):
    """Conteúdo de uma seção '## <titulo>...' até o próximo '## '."""
    m = re.search(rf"^## {re.escape(titulo)}.*?$(.*?)(?=^## |\Z)", texto, re.M | re.S)
    return m.group(1) if m else ""


def compose(caminho):
    try:
        saida = subprocess.run(["docker", "compose", "-f", str(caminho), "config", "--format", "json"],
                               capture_output=True, text=True, timeout=60, check=True).stdout
        return json.loads(saida)["services"]
    except (OSError, subprocess.SubprocessError, ValueError, KeyError) as e:
        registrar("A5", f"ler {caminho.relative_to(RAIZ)}", None, f"não foi possível (Docker parado?): {e.__class__.__name__}")
        return None


def checar_ambiente():
    for nome, arq, prefixo in [("etcd", "etcd/docker-compose.yml", "etcd"), ("ZooKeeper", "zookeeper/docker-compose.yml", "zk")]:
        servicos = compose(RAIZ / arq)
        if servicos is None:
            continue
        nos = [s for s in servicos if re.fullmatch(rf"{prefixo}\d+", s)]
        registrar("A4", f"{nome}: ≥ 3 nós", len(nos) >= 3, f"{len(nos)} nós: {', '.join(sorted(nos))}")
        sem_limite = [s for s, cfg in servicos.items() if not cfg.get("mem_limit")]
        registrar("A5", f"{nome}: mem_limit em todo serviço", not sem_limite, "faltando: " + ", ".join(sem_limite) if sem_limite else "ok")
        # versão fixa = tag com x.y.z; python:3.12-alpine é aceito (só roda o cliente, dependência kazoo fixada)
        flutuantes = [cfg["image"] for cfg in servicos.values()
                      if not re.search(r":v?\d+\.\d+\.\d+", cfg["image"]) and not cfg["image"].startswith("python:")]
        registrar("A8", f"{nome}: imagens com versão fixa", not flutuantes, ", ".join(flutuantes) or "ok")


def checar_experimento(id_, pasta):
    readme = pasta / "README.md"
    if not readme.exists():
        registrar(id_, "README do experimento", False, "não existe")
        return
    texto = readme.read_text(encoding="utf-8")
    prev = secao(texto, "Previsão")
    analise = secao(texto, "Análise")
    evid = [p for p in (pasta / "evidencias").rglob("*") if p.is_file() and p.name != ".gitkeep"] if (pasta / "evidencias").exists() else []
    registrar(id_, "previsão registrada", PENDENTE not in prev and prev.strip() != "", "")
    registrar(id_, "evidências salvas", len(evid) > 0, f"{len(evid)} arquivo(s)")
    registrar(id_, "análise escrita", PENDENTE not in analise and analise.strip() != "", "")


def checar_experimentos():
    exps = RAIZ / "experimentos"
    for pasta in sorted(exps.glob("E[1-8]-*")):
        checar_experimento(f"R3/{pasta.name.split('-')[0]}", pasta)
    e9 = exps / "E9-zookeeper"
    for sub in sorted(p for p in e9.iterdir() if p.is_dir()):
        checar_experimento(f"R4/E9-{sub.name.split('-')[0]}", sub)
    comp = e9 / "comparacao.md"
    if comp.exists():
        linhas = [l for l in comp.read_text(encoding="utf-8").splitlines() if l.startswith("|") and "---" not in l][1:]
        vazias = [l.split("|")[1].strip() for l in linhas if any(c.strip() == "" for c in l.split("|")[2:4])]
        registrar("R4/Z9", "quadro comparativo preenchido", not vazias, f"{len(vazias)} linha(s) vazia(s)")


def checar_medicoes():
    # o E0 é ensaio fora da bateria avaliada: não conta como medição
    csvs = sorted(c for c in (RAIZ / "resultados").glob("*.csv") if "_e0_" not in c.name)
    if not csvs:
        registrar("R7", "medições em resultados/", False, "nenhum CSV ainda")
        return
    for c in csvs:
        with open(c, newline="", encoding="utf-8") as f:
            linhas = list(csv.DictReader(f))
        validas = [l for l in linhas if l.get("exit", "0") in ("0", "")]
        registrar("R7", f"{c.name}: ≥ 5 repetições válidas", len(validas) >= 5, f"{len(validas)} válidas de {len(linhas)}")


def checar_relatorio():
    rel = RAIZ / "relatorio"
    secoes = sorted(rel.glob("[0-1][0-9]-*.md"))
    registrar("R8", "12 seções do relatório existem", len(secoes) >= 12, f"{len(secoes)} arquivo(s)")
    for s in secoes:
        n = s.read_text(encoding="utf-8").count(PENDENTE)
        registrar("R8", f"{s.name} sem pendências", n == 0, f"{n} pendência(s)")
    for arq, prefixo, total, req in [("06-questoes-comuns.md", "Q", 14, "R5"), ("07-questoes-especificas.md", "S", 4, "R6")]:
        p = rel / arq
        if not p.exists():
            continue
        texto = p.read_text(encoding="utf-8")
        sem_evid = []
        for i in range(1, total + 1):
            bloco = re.search(rf"^### {prefixo}{i}\b(.*?)(?=^### |\Z)", texto, re.M | re.S)
            ev = re.search(r"\*\*Evidência:\*\*(.*)", bloco.group(1)) if bloco else None
            if not ev or PENDENTE in ev.group(1) or not ev.group(1).strip():
                sem_evid.append(f"{prefixo}{i}")
        registrar(req, f"{prefixo}1–{prefixo}{total} com evidência apontada", not sem_evid, "faltam: " + ", ".join(sem_evid) if sem_evid else "ok")


def checar_docs():
    uso = RAIZ / "docs" / "uso-ia.md"
    linhas = [l for l in uso.read_text(encoding="utf-8").splitlines() if l.startswith("| 20")] if uso.exists() else []
    registrar("H11", "registro de uso de IA", len(linhas) > 0, f"{len(linhas)} registro(s)")
    diario = RAIZ / "relatorio" / "notas" / "diario.md"
    registrar("K3", "diário de bordo existe", diario.exists(), "")


def main():
    checar_ambiente()
    checar_experimentos()
    checar_medicoes()
    checar_relatorio()
    checar_docs()
    icone = {True: "✅", False: "⬜", None: "⚠️"}
    print("| Critério | Verificação | Status | Detalhe |")
    print("|---|---|---|---|")
    for id_, desc, ok, det in resultados:
        print(f"| {id_} | {desc} | {icone[ok]} | {det} |")
    pend = sum(1 for r in resultados if r[2] is not True)
    print(f"\n**{len(resultados) - pend} de {len(resultados)} verificações automáticas cumpridas; {pend} pendente(s).**")
    print("Revisão humana: docs/criterios-avaliacao.md")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
