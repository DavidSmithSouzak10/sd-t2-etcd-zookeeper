#!/usr/bin/env bash
# Gera os PNG dos diagramas a partir das fontes Mermaid (.mmd). Precisa de Node.js (npx).
# Uso (da raiz do repositório): diagramas/renderizar.sh
set -e
cd "$(dirname "$0")"
for f in *.mmd; do
  npx -y @mermaid-js/mermaid-cli@11.4.2 -i "$f" -o "${f%.mmd}.png" -b white -s 2
done
