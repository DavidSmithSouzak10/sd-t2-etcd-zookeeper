# E9/E7 — Recuperação no ZooKeeper

> Roteiro: PDF §9.5, ênfase D. Rodar `scripts/validar.sh zk` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Repetir o E7 da bateria comum no ensemble ZooKeeper. Comparar com catch-up por log/snapshot do etcd.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Registrada em 2026-10-26 21:11, antes de qualquer execução (ver `docs/uso-ia.md`).

- **Religar:** esperamos sincronização por DIFF, porque faltam poucas transações e o líder as tem em memória, e o zxid igual nos 3 alguns segundos depois de religar. A sincronização em si é rápida, mas o servidor precisa sair do LOOKING e reencontrar o líder, e o intervalo entre suas tentativas de eleição cresce enquanto ele está isolado.

## Procedimento
Religar e observar a sincronização com o líder nos logs (DIFF, SNAP ou TRUNC); tempo até o zxid igualar ≥ 5×.

Script reproduzível: `executar.sh` (escrito em 26/10, antes da previsão; ainda não executado).

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
