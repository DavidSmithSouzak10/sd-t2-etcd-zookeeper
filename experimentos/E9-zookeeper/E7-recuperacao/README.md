# E9/E7 — Recuperação no ZooKeeper

> Roteiro: PDF §9.5, ênfase D. Rodar `scripts/validar.sh zk` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Repetir o E7 da bateria comum no ensemble ZooKeeper. Comparar com catch-up por log/snapshot do etcd.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: 2026-10-26 20:58 — respostas de Samuel (em call com David) a um questionário de múltipla escolha; texto montado pelo Claude Code a partir das escolhas, sem correção (ver `docs/uso-ia.md`)
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. Religado, o servidor sincroniza por DIFF, SNAP ou TRUNC? Do que isso depende?
> 2. Quanto tempo até o zxid dele igualar o dos outros?

1. **Modo de sincronização:** esperamos **DIFF**, porque faltam poucas transações e o líder as tem em memória.
2. **Tempo até o zxid igualar:** esperamos **vários segundos**.

## Procedimento
Religar e observar a sincronização com o líder nos logs (DIFF, SNAP ou TRUNC); tempo até o zxid igualar ≥ 5×.

Script reproduzível: `executar.sh` (_pendente_).

## Evidências
| Arquivo | O que mostra |
|---|---|
| _pendente_ | |

## Medições (≥ 5 repetições — R7)
_pendente_

## Análise: previsão × resultado × teoria × etcd
_pendente_

## Questões que este experimento sustenta
_preencher_
