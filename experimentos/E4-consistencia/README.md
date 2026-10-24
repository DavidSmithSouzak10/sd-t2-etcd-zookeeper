# E4 — Consistência (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Evidenciar o modelo de consistência: leitura atualizada garantida ou janela de leitura desatualizada.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: _preencher_
> O que esperamos observar e por quê (citar Raft/ZAB, quórum etc.):

_pendente_

## Procedimento
1. Comparar `get` linearizável (padrão) com `get --consistency=s` (serializável) em condições normais: mesma resposta, latências diferentes?
2. Isolar um seguidor (ver E6), escrever um valor novo pelo lado majoritário e ler no seguidor isolado com as duas consistências. Registrar qual devolve o valor antigo e qual falha.

Script reproduzível: `executar.sh` (_pendente_).

## Evidências
Arquivos em `evidencias/` (gerados por `scripts/lib.sh::evidencia`, nunca editados à mão). Evidência mínima: sequência temporal de escritas e leituras com valores observados.

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
