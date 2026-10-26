# E8 — Coordenação e ordem (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Mostrar quem coordena e o mecanismo de versionamento/ordenação.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: 2026-10-26 20:58 — respostas de Samuel (em call com David) a um questionário de múltipla escolha; texto montado pelo Claude Code a partir das escolhas, sem correção (ver `docs/uso-ia.md`)
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. Com o cliente A segurando `etcdctl lock`, o cliente B fica bloqueado até quando?
> 2. Se o processo de A morrer, quanto tempo até B pegar a trava? (TTL do lease padrão: 10 s)
> 3. A revisão MVCC é crescente para **todas** as chaves (ordem total)? Isso lembra que relógio lógico?
> 4. Que diferença esperam entre o `elect` do etcd e o algoritmo do Valentão (Bully)?
> O que esperamos observar e por quê (citar Raft/ZAB, quórum etc.):

1. **Trava ocupada:** esperamos que o cliente B **fique esperando** até o A soltar ou morrer.
2. **Dono morre:** esperamos que B pegue a trava em **cerca de 10 s**, só quando o lease de A expirar sem renovação.
3. **Revisão:** esperamos que seja **crescente para todas as chaves juntas (ordem total)**, como um relógio lógico de Lamport compartilhado.
4. **`elect` × Valentão (Bully):** esperamos que o `elect` **não dependa do maior ID**: vence quem pediu primeiro (a ordem da revisão).

## Procedimento
1. Mostrar a sequência de termos e revisões ao longo das falhas e explicá-los como relógios lógicos (termo: época de liderança; revisão: ordem total das escritas).
2. Dois terminais competindo por `etcdctl lock trava` (exclusão mútua) e dois candidatos em `etcdctl elect eleicao <nome>` (eleição). Parar o contêiner do detentor e medir o tempo até o outro assumir (lease; kit mediu ~11 s com TTL 10 s).
3. Comparar a eleição do Raft com Bully e Anel (Unidade 2).

Script reproduzível: `executar.sh` (_pendente_).

## Evidências
Arquivos em `evidencias/` (gerados por `scripts/lib.sh::evidencia`, nunca editados à mão). Evidência mínima: troca de líder com termo maior + tempos de troca do lock/elect.

| Arquivo | O que mostra |
|---|---|
| _pendente_ | |

## Medições (≥ 5 repetições — R7)
CSV em `resultados/`; tabela gerada por `scripts/estatistica.py`.

_pendente_

## Análise: previsão × resultado × teoria
_pendente_

## Questões que este experimento sustenta
_preencher (ex.: Q5, Q6, Q11)_
