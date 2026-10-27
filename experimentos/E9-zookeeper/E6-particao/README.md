# E9/E6 — Partição de rede no ZooKeeper

> Roteiro: PDF §9.5, ênfase D. Rodar `scripts/validar.sh zk` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Repetir o E6 da bateria comum no ensemble ZooKeeper. Conclusão C × A comparada ao E6 do etcd.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Registrada em 2026-10-26 21:11, antes de qualquer execução (ver `docs/uso-ia.md`).

- **Partição:** esperamos que o líder isolado perca o quórum, deixe de ser líder (LOOKING) e derrube os clientes, que o kazoo reconecta em outro servidor; e que o lado majoritário eleja um novo líder, com época maior, em poucos segundos. Mesma escolha do etcd: consistência.

## Procedimento
Desconectar o líder da rede interna (`scripts/particionar.sh isolar zkN`); estado LOOKING no isolado; o que um cliente conectado a ele vê (desconexão, sessão expirada).

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
