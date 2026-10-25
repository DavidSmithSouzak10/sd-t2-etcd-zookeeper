# E9/E3 — Replicação no ZooKeeper

> Roteiro: PDF §9.5, ênfase D. Rodar `scripts/validar.sh zk` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Repetir o E3 da bateria comum no ensemble ZooKeeper. Comparar com E3 do etcd (watch, latência).

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: 2026-10-25 12:57 — respostas de David a um questionário de múltipla escolha; texto montado pelo Claude Code a partir das escolhas (ver `docs/uso-ia.md`)
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. `set` em zk1 e `get` em zk3 logo depois: o valor novo aparece sempre? Por quê?
> 2. Um watch (`get -w`) dispara uma vez ou a cada mudança?
> 3. A latência de escrita do ZK será maior ou menor que a do etcd? (E0 deu uma pista: e a margem de erro?)

1. **Ler em outro servidor logo após escrever:** esperamos que **possa vir o valor antigo**, porque a leitura padrão do ZooKeeper é local: se o zk3 ainda não aplicou a escrita, responde o valor velho por um instante. É diferente do etcd, onde a leitura padrão é linearizável.
2. **Watch:** esperamos que **dispare uma vez só**. O watch do ZooKeeper é de disparo único; depois de avisar, o cliente precisa registrá-lo de novo. Também diferente do etcd, onde o watch fica ativo.

## Procedimento
`create`/`set` num servidor, `get` em outro; `get -w` (watch) num terceiro recebendo a notificação; latência de escrita e leitura ≥ 5×.

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
