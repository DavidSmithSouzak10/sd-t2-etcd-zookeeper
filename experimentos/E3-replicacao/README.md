# E3 — Replicação (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Escrever em um nó e ler em outro; medir latência/propagação.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: _preencher_
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. Escrevendo em etcd1, um `get` em etcd3 logo em seguida já vê o valor? Por quê?
> 2. Um `watch` em etcd2 recebe a notificação em quanto tempo (ordem de grandeza)?
> 3. Qual é mais lento, `put` ou `get` linearizável? Por quê?
> 4. O `etcdctl check perf --load=s` vai passar nesta máquina (Docker no Windows)?
> O que esperamos observar e por quê (citar Raft/ZAB, quórum etc.):

_pendente_

## Procedimento
1. Escrever em um membro e ler em outro (endpoints únicos). Abrir um `watch` em um terceiro membro e mostrar a notificação chegando.
2. Medir a latência de `put` e de `get` (≥ 5 repetições) e rodar `etcdctl check perf --load=s` como referência.

Script reproduzível: `executar.sh` (_pendente_).

## Evidências
Arquivos em `evidencias/` (gerados por `scripts/lib.sh::evidencia`, nunca editados à mão). Evidência mínima: tabela com ≥ 5 medições, média e desvio.

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
