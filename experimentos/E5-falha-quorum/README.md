# E5 — Falha e quórum (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Derrubar 1 nó (minoria) e depois 2 (maioria); observar o que continua funcionando.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: _preencher_
> O que esperamos observar e por quê (citar Raft/ZAB, quórum etc.):

_pendente_

## Procedimento
1. Parar o **líder**: medir o tempo até um novo líder ser eleito (≥ 5 repetições) e mostrar o termo incrementado. As escritas continuam?
2. Parar um segundo membro: sem maioria, `put` falha (*context deadline exceeded*), leitura linearizável falha e leitura serializável ainda responde.
3. Montar o quadro "membros ativos × leitura linearizável × leitura serializável × escrita".

Script reproduzível: `executar.sh` (_pendente_).

## Evidências
Arquivos em `evidencias/` (gerados por `scripts/lib.sh::evidencia`, nunca editados à mão). Evidência mínima: quadro membros × leitura lin. × leitura ser. × escrita + tempos de eleição.

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
