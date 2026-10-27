# E9/E8 — Coordenação no ZooKeeper

> Roteiro: PDF §9.5, ênfase D. Rodar `scripts/validar.sh zk` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Repetir o E8 da bateria comum no ensemble ZooKeeper. Comparar com `etcdctl lock/elect` (lease × sessão).

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Registrada em 2026-10-26 21:11, antes de qualquer execução (ver `docs/uso-ia.md`).

- **Trava e eleição:** esperamos que só o próximo da fila seja avisado (cada cliente observa o znode anterior) e que, parando o dono, a trava libere quando a sessão expira (cerca de 10 s no kazoo), como o lease do etcd.
- **Época × termo:** esperamos que sejam a mesma ideia: um número de mandato que sobe a cada novo líder e faz os servidores recusarem mensagens do líder antigo.

## Procedimento
Trava (kazoo `Lock`) e eleição (kazoo `Election`) com **znodes efêmeros e sequenciais**, com 2 clientes cada; matar o detentor e medir o tempo de troca (session timeout) ≥ 5×.

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
