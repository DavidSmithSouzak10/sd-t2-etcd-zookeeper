# E7 — Recuperação (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Religar o nó e observar como ele se atualiza; medir o tempo até o cluster ficar saudável.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: 2026-10-26 20:58 — respostas de Samuel (em call com David) a um questionário de múltipla escolha; texto montado pelo Claude Code a partir das escolhas, sem correção (ver `docs/uso-ia.md`)
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. Religado, o antigo líder volta como líder ou seguidor? Por quê (termo)?
> 2. Quanto tempo até o RAFT INDEX dele alcançar o dos outros?
> 3. Com `--snapshot-count` baixo e muitas escritas enquanto ele estava fora, ele recupera pelo log ou por snapshot? Que mensagem esperam no log?
> 4. O estado final (chaves e revisão) fica idêntico nos 3?
> O que esperamos observar e por quê (citar Raft/ZAB, quórum etc.):

1. **Papel ao voltar:** esperamos que o antigo líder volte como **seguidor**, porque já existe um líder com **termo maior** e ele adota esse termo.
2. **Tempo até alcançar o RAFT INDEX:** esperamos **vários segundos**, porque ele precisa reprocessar tudo desde o começo.
3. **Log × snapshot:** com `--snapshot-count` baixo e mais escritas do que isso enquanto ele estava fora, esperamos recuperação **por snapshot**: o líder já não tem as entradas antigas no log e envia a foto.
4. **Estado final:** esperamos chaves e revisão **idênticas nos 3**.

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
