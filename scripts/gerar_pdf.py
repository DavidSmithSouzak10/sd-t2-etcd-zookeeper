"""Gera PDF a partir de Markdown, imprimindo HTML com o Microsoft Edge (ou Chrome/Chromium) em modo headless.

Uso (da raiz do repositório):
  python scripts/gerar_pdf.py relatorio               -> relatorio/relatorio.pdf (capa, sumário e as seções 01..12)
  python scripts/gerar_pdf.py seminario/mini-aula.md  -> seminario/mini-aula.pdf
Requer o pacote `markdown` (pip install markdown) e um navegador Chromium (o Edge já vem no Windows).
"""
import html
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import markdown

RAIZ = Path(__file__).resolve().parent.parent
NAVEGADORES = [
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "msedge", "google-chrome", "chromium", "chromium-browser",
]

CSS = """
@page { size: A4; margin: 3cm 2cm 2cm 3cm; @bottom-right { content: counter(page); font: 10pt Arial, sans-serif; } }
body { font-family: Arial, Helvetica, sans-serif; font-size: 12pt; line-height: 1.5; color: #111; }
h1 { font-size: 14pt; margin: 0 0 12pt; }
.relatorio h1 { text-transform: uppercase; margin-top: 24pt; break-after: avoid; }
h2 { font-size: 12pt; margin: 16pt 0 6pt; break-after: avoid; }
h3 { font-size: 12pt; margin: 12pt 0 4pt; break-after: avoid; }
p, li { text-align: justify; margin: 0 0 8pt; }
table { border-collapse: collapse; width: 100%; font-size: 10pt; line-height: 1.3; margin: 6pt 0 12pt; }
th, td { border: 1px solid #999; padding: 3pt 5pt; text-align: left; vertical-align: top; }
th { background: #eee; }
tr { break-inside: avoid; }
code { font-family: Consolas, 'Courier New', monospace; font-size: 9.5pt; }
pre { white-space: pre-wrap; font-size: 9pt; background: #f4f4f4; padding: 6pt; }
img { display: block; max-width: 100%; max-height: 18cm; margin: 8pt auto; }
blockquote { margin: 0 0 8pt 1cm; color: #333; }
.capa { height: 24.5cm; display: flex; flex-direction: column; justify-content: space-between; text-align: center; break-after: page; }
.capa p { text-align: center; margin: 0; }
.capa .titulo { font-size: 16pt; font-weight: bold; text-transform: uppercase; }
.sumario { break-after: page; }
.sumario p { text-align: left; }
"""


def para_html(texto, pasta):
    """Markdown -> HTML; imagens relativas viram caminhos absolutos (file://)."""
    corpo = markdown.markdown(texto, extensions=["tables", "fenced_code", "sane_lists"])

    def absoluto(m):
        src = m.group(1)
        if re.match(r"^(https?:|file:|data:)", src):
            return m.group(0)
        return f'src="{(pasta / src).resolve().as_uri()}"'

    return re.sub(r'src="([^"]+)"', absoluto, corpo)


def identificacao(texto):
    """Lê a tabela da seção 01 (Item | Valor) para montar a capa."""
    campos = {}
    for linha in texto.splitlines():
        partes = [p.strip() for p in linha.strip().strip("|").split("|")]
        if len(partes) == 2 and partes[0] not in ("Item", "---"):
            campos[partes[0]] = partes[1]
    return campos


def relatorio():
    pasta = RAIZ / "relatorio"
    secoes = sorted(p for p in pasta.glob("[01][0-9]-*.md"))
    textos = [s.read_text(encoding="utf-8") for s in secoes]
    c = identificacao(textos[0])
    autores = "".join(f"<p>{html.escape(a.strip())}</p>" for a in c.get("Integrantes", "").split(";"))
    instituicao = html.escape(c.get("Instituição / disciplina", ""))
    capa = f"""<div class="capa">
<div><p>{instituicao}</p></div>
<div>{autores}</div>
<div><p class="titulo">Replicação de estado e configuração com consenso</p>
<p>etcd (Raft) e Apache ZooKeeper (ZAB): experimentos de liderança, quórum, partição e recuperação</p></div>
<div><p>Professor: {html.escape(c.get("Professor", ""))}</p><p>{html.escape(c.get("Data", ""))}</p></div>
</div>"""
    titulos = [re.match(r"#\s+(.+)", t).group(1) for t in textos]
    sumario = '<div class="sumario"><h1 style="break-before:auto">Sumário</h1>' + "".join(
        f"<p>{html.escape(t)}</p>" for t in titulos) + "</div>"
    corpo = capa + sumario + "\n".join(para_html(t, pasta) for t in textos)
    return corpo, "relatorio", pasta / "relatorio.pdf", "Relatório: replicação de estado com etcd e ZooKeeper"


def documento(caminho):
    texto = caminho.read_text(encoding="utf-8")
    titulo = re.match(r"#\s+(.+)", texto).group(1)
    return para_html(texto, caminho.parent), "simples", caminho.with_suffix(".pdf"), titulo


def navegador():
    for n in NAVEGADORES:
        if Path(n).exists() or shutil.which(n):
            return n
    sys.exit("nenhum navegador Chromium encontrado (Edge, Chrome ou Chromium)")


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    alvo = sys.argv[1]
    corpo, classe, saida, titulo = relatorio() if alvo.rstrip("/\\") == "relatorio" else documento((RAIZ / alvo).resolve())
    pagina = (f'<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>{html.escape(titulo)}</title>'
              f"<style>{CSS}</style></head><body class=\"{classe}\">{corpo}</body></html>")
    with tempfile.TemporaryDirectory() as tmp:
        arq = Path(tmp) / "doc.html"
        arq.write_text(pagina, encoding="utf-8")
        subprocess.run([navegador(), "--headless", "--disable-gpu", f"--user-data-dir={Path(tmp) / 'perfil'}",
                        "--no-pdf-header-footer", "--print-to-pdf-no-header", f"--print-to-pdf={saida}", arq.as_uri()],
                       check=True, timeout=180, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    paginas = len(re.findall(rb"/Type\s*/Page[^s]", saida.read_bytes()))
    print(f"{saida.relative_to(RAIZ)}: {paginas} páginas")


if __name__ == "__main__":
    main()
