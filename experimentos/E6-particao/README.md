# E6 — Partição de rede (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Isolar o líder do restante, mantendo-o acessível ao cliente; observar os dois lados.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Registrada em 2026-10-26 21:11, antes de qualquer execução (ver `docs/uso-ia.md`).

- **Os dois lados:** esperamos que o lado majoritário eleja um novo líder, com termo maior, em poucos segundos, e que o líder isolado deixe de ser líder (*check quorum*) e pare de aceitar escritas. O cliente ligado só a ele recebe erro ou timeout no `put` e no `get` linearizável; o `get` serializável pode devolver o valor antigo. Porque só o lado com maioria consegue confirmar operações.
- **C × A:** esperamos que o etcd escolha consistência: o lado minoritário fica indisponível para não existirem duas versões dos dados.

## Procedimento
1. Desconectar o **líder** da rede interna (`scripts/particionar.sh isolar etcdN`).
2. Observar o lado majoritário elegendo novo líder com termo maior e o antigo líder deixando de aceitar escritas. O que um cliente conectado só a ele recebe?
3. Concluir sobre a escolha entre consistência e disponibilidade (C × A).

Script reproduzível: `executar.sh` (escrito em 26/10, antes da previsão; ainda não executado).

## Evidências
Arquivos em `evidencias/` (gerados por `scripts/lib.sh::evidencia`, nunca editados à mão). Evidência mínima: comportamento do lado minoritário e do majoritário + conclusão C × A.

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
