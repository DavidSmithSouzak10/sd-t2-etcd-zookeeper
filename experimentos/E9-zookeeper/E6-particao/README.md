# E9/E6 — Partição de rede no ZooKeeper

> Roteiro: PDF §9.5, ênfase D. Rodar `scripts/validar.sh zk` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Repetir o E6 da bateria comum no ensemble ZooKeeper. Conclusão C × A comparada ao E6 do etcd.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: 2026-10-26 20:58 — respostas de Samuel (em call com David) a um questionário de múltipla escolha; texto montado pelo Claude Code a partir das escolhas, sem correção (ver `docs/uso-ia.md`)
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. O líder isolado entra em que estado (`srvr`: LOOKING?)
> 2. O que um cliente conectado a ele recebe (erro, valor antigo, reconexão)?
> 3. O lado majoritário elege novo líder? Em quanto tempo?

1. **Líder isolado:** esperamos que **continue líder** até a rede voltar.
2. **Cliente conectado a ele:** esperamos que **perca a conexão e o kazoo tente outro servidor** (se tiver a lista).
3. **Lado majoritário:** esperamos que **eleja outro líder em poucos segundos**.

## Procedimento
Desconectar o líder da rede interna (`scripts/particionar.sh isolar zkN`); estado LOOKING no isolado; o que um cliente conectado a ele vê (desconexão, sessão expirada).

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
