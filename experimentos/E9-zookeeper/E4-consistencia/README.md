# E9/E4 — Consistência no ZooKeeper

> Roteiro: PDF §9.5, ênfase D. Rodar `scripts/validar.sh zk` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Repetir o E4 da bateria comum no ensemble ZooKeeper. Comparar com E4 do etcd (serializável × linearizável).

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: 2026-10-25 12:57 — respostas de David a um questionário de múltipla escolha; texto montado pelo Claude Code a partir das escolhas (ver `docs/uso-ia.md`)
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. Uma leitura local num seguidor pode devolver valor antigo? Em que situação?
> 2. O `sync` antes da leitura resolve? Quanto custa a mais?
> 3. Um servidor isolado do ensemble ainda responde leituras? E escritas? (`readonlymode` está desligado)

1. **`sync` + get:** esperamos que **garanta o valor novo, mas seja mais lento** (talvez o dobro do tempo), porque o `sync` faz o servidor alcançar o líder antes de ler. É o equivalente do ZooKeeper à leitura linearizável do etcd.
2. **Servidor isolado (sem maioria):** esperamos que ele **continue respondendo leituras com a cópia local, mas recuse escritas**.

## Procedimento
Leitura local × `sync` + leitura. Isolar um seguidor, escrever pelo lado majoritário e ler no isolado: devolve o valor antigo, recusa ou desconecta? (**verificar, não assumir**).

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
