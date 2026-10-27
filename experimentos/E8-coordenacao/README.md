# E8 — Coordenação e ordem (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Mostrar quem coordena e o mecanismo de versionamento/ordenação.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Registrada em 2026-10-26 21:11, antes de qualquer execução (ver `docs/uso-ia.md`).

- **Relógios lógicos:** esperamos que o termo suba só a cada troca de líder e que a revisão suba a cada escrita, numa ordem única para todas as chaves. O termo funciona como época de liderança, e a revisão como um relógio de Lamport compartilhado.
- **Trava e eleição:** esperamos que o segundo cliente fique esperando e assuma cerca de 10 s depois que o detentor é parado, quando o lease (TTL de 10 s) vence sem renovação. No `elect`, vence quem pediu primeiro (menor revisão), e não o maior ID, como no Bully e no Anel.

## Procedimento
1. Mostrar a sequência de termos e revisões ao longo das falhas e explicá-los como relógios lógicos (termo: época de liderança; revisão: ordem total das escritas).
2. Dois terminais competindo por `etcdctl lock trava` (exclusão mútua) e dois candidatos em `etcdctl elect eleicao <nome>` (eleição). Parar o contêiner do detentor e medir o tempo até o outro assumir (lease; kit mediu ~11 s com TTL 10 s).
3. Comparar a eleição do Raft com Bully e Anel (Unidade 2).

Script reproduzível: `executar.sh` (escrito em 26/10, antes da previsão; ainda não executado).

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
