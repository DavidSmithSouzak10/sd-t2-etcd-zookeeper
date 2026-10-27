# E7 — Recuperação (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Religar o nó e observar como ele se atualiza; medir o tempo até o cluster ficar saudável.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Registrada em 2026-10-26 21:11, antes de qualquer execução (ver `docs/uso-ia.md`).

- **Religar:** esperamos que o membro volte como seguidor, adote o termo maior e alcance o RAFT INDEX dos outros em menos de 1 s. Porque o líder envia só as entradas que faltam, numa rede local.
- **Snapshot:** com `--snapshot-count=1000` e milhares de escritas enquanto ele está parado, esperamos recuperação por snapshot, porque o líder já compactou as entradas antigas do log. O estado final (chaves e revisão) fica idêntico nos 3.

## Procedimento
1. Reconectar o membro isolado e mostrá-lo voltando como seguidor, com termo atualizado, alcançando o mesmo RAFT INDEX (medir o tempo, ≥ 5 repetições).
2. Recriar o cluster com `SNAPSHOT_COUNT=1000` (`etcd/.env`), deixar um membro parado enquanto faz milhares de escritas e mostrar que ele se recupera por **snapshot** em vez de reaplicar o log inteiro.

Script reproduzível: `executar.sh` (escrito em 26/10, antes da previsão; ainda não executado).

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
