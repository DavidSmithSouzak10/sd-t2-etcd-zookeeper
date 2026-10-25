# E9/E8 — Coordenação no ZooKeeper

> Roteiro: PDF §9.5, ênfase D. Rodar `scripts/validar.sh zk` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Repetir o E8 da bateria comum no ensemble ZooKeeper. Comparar com `etcdctl lock/elect` (lease × sessão).

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: _preencher_
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. Na trava com znodes efêmeros sequenciais, quem pega a trava depois? Por que só o próximo da fila é avisado?
> 2. Se o cliente dono morrer, quanto tempo até a trava liberar? (session timeout × lease TTL do etcd)
> 3. Época ZAB × termo Raft: qual a semelhança e a diferença?

_pendente_

## Procedimento
Trava (kazoo `Lock`) e eleição (kazoo `Election`) com **znodes efêmeros e sequenciais**, com 2 clientes cada; matar o detentor e medir o tempo de troca (session timeout) ≥ 5×.

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
