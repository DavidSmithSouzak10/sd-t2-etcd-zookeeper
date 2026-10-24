# E2 — Caminho de uma operação (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Percurso de uma escrita e de uma leitura: quem recebe, quem decide, quem replica, quem responde.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: _preencher_
> O que esperamos observar e por quê (citar Raft/ZAB, quórum etc.):

_pendente_

## Procedimento
1. Enviar um `put` para um **seguidor** (endpoint único) e mostrar que é encaminhado ao líder.
2. Usar `-w json` para exibir o cabeçalho da resposta (`revision`, `raft_term`) e mostrar o RAFT INDEX avançando nos três membros.
3. Desenhar o diagrama de sequência: cliente → seguidor → líder → AppendEntries → commit com maioria → resposta.

Script reproduzível: `executar.sh` (_pendente_).

## Evidências
Arquivos em `evidencias/` (gerados por `scripts/lib.sh::evidencia`, nunca editados à mão). Evidência mínima: saídas + diagrama de sequência.

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
