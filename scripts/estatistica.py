"""Média, desvio padrão amostral, mínimo e máximo de CSVs de medição.

Uso: python scripts/estatistica.py <arquivo.csv> [...] [--coluna duracao_ms]
Imprime uma tabela Markdown pronta para colar no README do experimento / relatório.
Linhas com exit != 0 são contadas como falhas e excluídas da estatística.
"""
import csv
import statistics
import sys
from pathlib import Path


def resumir(caminho, coluna):
    valores, falhas = [], 0
    with open(caminho, newline="", encoding="utf-8") as f:
        for linha in csv.DictReader(f):
            if linha.get("exit", "0") not in ("0", ""):
                falhas += 1
                continue
            valores.append(float(linha[coluna]))
    return valores, falhas


def main():
    args = sys.argv[1:]
    coluna = "duracao_ms"
    if "--coluna" in args:
        i = args.index("--coluna")
        coluna = args[i + 1]
        del args[i:i + 2]
    if not args:
        sys.exit(__doc__)

    print(f"| Medição | n | média ({coluna}) | desvio padrão | mín | máx | falhas |")
    print("|---|---|---|---|---|---|---|")
    for caminho in args:
        valores, falhas = resumir(caminho, coluna)
        nome = Path(caminho).stem
        if len(valores) < 2:
            print(f"| {nome} | {len(valores)} | - | - | - | - | {falhas} |")
        else:
            media = statistics.mean(valores)
            desvio = statistics.stdev(valores)
            print(f"| {nome} | {len(valores)} | {media:.2f} | {desvio:.2f} | {min(valores):.2f} | {max(valores):.2f} | {falhas} |")
        if len(valores) < 5:
            print(f"> aviso: {nome} tem menos de 5 repetições válidas — não atende R7.", file=sys.stderr)


if __name__ == "__main__":
    main()
