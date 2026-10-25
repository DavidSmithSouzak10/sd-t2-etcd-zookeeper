# E1 — Subida e topologia (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Cluster com 3 membros no ar; papéis de cada nó identificados.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: _preencher_
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. Quantos membros aparecem no `member list`? Algum é *learner*?
> 2. Quantos líderes? Por que o Raft garante isso (um voto por termo + maioria)?
> 3. Termo e RAFT INDEX serão iguais nos 3? Em que termo o cluster recém-criado deve estar?
> 4. Dá para prever qual membro será o líder? (timeout aleatório)
> 5. O RAFT INDEX fica parado em repouso? (healthcheck a cada 5 s)
> O que esperamos observar e por quê (citar Raft/ZAB, quórum etc.):

_pendente_

## Procedimento
1. Registrar `member list -w table`, `endpoint status -w table` (líder, termo, índice Raft) e `endpoint health`.
2. Desenhar o diagrama com membros, redes, portas e o líder atual (`diagramas/`).

Script reproduzível: `executar.sh` (_pendente_).

## Evidências
Arquivos em `evidencias/` (gerados por `scripts/lib.sh::evidencia`, nunca editados à mão). Evidência mínima: saídas dos 3 comandos + diagrama com IPs/portas/líder.

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
