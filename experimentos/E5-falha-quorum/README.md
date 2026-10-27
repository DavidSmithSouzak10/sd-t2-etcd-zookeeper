# E5 — Falha e quórum (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Derrubar 1 nó (minoria) e depois 2 (maioria); observar o que continua funcionando.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Registrada em 2026-10-26 21:11, antes de qualquer execução (ver `docs/uso-ia.md`).

- **Parar o líder:** esperamos um novo líder em 1 a 3 s, com termo maior (+1, ou mais se houver empate de votos), e as escritas voltando a funcionar. Porque os seguidores só se candidatam depois do *election timeout* (sorteado entre 1 e 2 s) sem *heartbeat*, e os 2 membros restantes ainda são maioria.
- **Parar o segundo membro:** esperamos que o `put` falhe (timeout), o `get` linearizável falhe e o `get` serializável responda. Porque sem maioria nada é confirmado, e a leitura linearizável precisa confirmar com a maioria, enquanto a serializável lê só a cópia local.

## Procedimento
1. Parar o **líder**: medir o tempo até um novo líder ser eleito (≥ 5 repetições) e mostrar o termo incrementado. As escritas continuam?
2. Parar um segundo membro: sem maioria, `put` falha (*context deadline exceeded*), leitura linearizável falha e leitura serializável ainda responde.
3. Montar o quadro "membros ativos × leitura linearizável × leitura serializável × escrita".

Script reproduzível: `executar.sh` (escrito em 26/10, antes da previsão; ainda não executado).

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
