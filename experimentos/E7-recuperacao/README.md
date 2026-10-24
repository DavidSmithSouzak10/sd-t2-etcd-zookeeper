# E7 — Recuperação (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Religar o nó e observar como ele se atualiza; medir o tempo até o cluster ficar saudável.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: _preencher_
> O que esperamos observar e por quê (citar Raft/ZAB, quórum etc.):

_pendente_

## Procedimento
1. Reconectar o membro isolado e mostrá-lo voltando como seguidor, com termo atualizado, alcançando o mesmo RAFT INDEX (medir o tempo, ≥ 5 repetições).
2. Recriar o cluster com `SNAPSHOT_COUNT=1000` (`etcd/.env`), deixar um membro parado enquanto faz milhares de escritas e mostrar que ele se recupera por **snapshot** em vez de reaplicar o log inteiro.

Script reproduzível: `executar.sh` (_pendente_).

## Evidências
Arquivos em `evidencias/` (gerados por `scripts/lib.sh::evidencia`, nunca editados à mão). Evidência mínima: logs de sincronização + tempos + estado final idêntico nas réplicas.

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
