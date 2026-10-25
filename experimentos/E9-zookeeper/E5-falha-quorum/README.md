# E9/E5 — Falha e quórum no ZooKeeper

> Roteiro: PDF §9.5, ênfase D. Rodar `scripts/validar.sh zk` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Repetir o E5 da bateria comum no ensemble ZooKeeper. Comparar época ZAB × termo Raft e os tempos de eleição.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: _preencher_
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. Parando o líder, a eleição (FLE) será mais rápida ou mais lenta que a do etcd?
> 2. O que muda no zxid: a época (32 bits altos) sobe? O contador reinicia?
> 3. Sem maioria: o servidor restante atende leituras? Escritas?

_pendente_

## Procedimento
Parar o líder: tempo até novo líder ≥ 5× e **nova época no zxid** (`srvr.py`, `currentEpoch`). Parar o 2º servidor: o que falha para leitura e escrita?

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
