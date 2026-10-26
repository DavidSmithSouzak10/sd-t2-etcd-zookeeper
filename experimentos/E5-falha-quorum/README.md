# E5 — Falha e quórum (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Derrubar 1 nó (minoria) e depois 2 (maioria); observar o que continua funcionando.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: 2026-10-26 20:58 — respostas de Samuel (em call com David) a um questionário de múltipla escolha; texto montado pelo Claude Code a partir das escolhas, sem correção (ver `docs/uso-ia.md`)
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. Parando o líder, quanto tempo até haver novo líder? (heartbeat padrão 100 ms, election timeout 1000 ms)
> 2. O termo sobe quanto? Sempre exatamente +1?
> 3. Com 2 membros parados (sem maioria): `put` funciona? `get` linearizável? `get` serializável?
> 4. O membro restante ainda se considera líder ou seguidor?
> O que esperamos observar e por quê (citar Raft/ZAB, quórum etc.):

1. **Tempo de eleição:** esperamos um novo líder **entre 1 e 3 s**, porque os seguidores esperam o *election timeout* sem ouvir o líder e só então fazem a eleição.
2. **Termo:** esperamos que suba **+1 ou mais**: se dois candidatos empatarem (*split vote*), há nova rodada com outro termo.
3. **Put sem maioria (2 membros parados):** esperamos que **falhe** (timeout ou erro), porque sem maioria não há commit.
4. **Leituras sem maioria:** esperamos que a **linearizável falhe e a serializável responda**: a linearizável precisa confirmar com a maioria, a serializável só lê a cópia local.

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
