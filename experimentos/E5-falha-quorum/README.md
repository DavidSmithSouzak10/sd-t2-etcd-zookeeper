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

Script reproduzível: [`executar.sh`](executar.sh) (da raiz). Cliente de medição: [`etcd/cliente/e5_eleicao.py`](../../etcd/cliente/e5_eleicao.py). Início = evento `kill` do `docker events`; fim = primeiro sobrevivente que informa o novo líder (consulta a cada 10 ms, de dentro da rede de clientes).

## Evidências
Executado em 26/10/2026 na máquina do Samuel (Windows 11, Docker 28.0.1), depois do registro da previsão (`5196dea`, revisada em `0dc40dd`). Horário: 21:18–21:20.

| Arquivo | O que mostra |
|---|---|
| `evidencias/2026-10-26_2118_queda_lider_kill.txt` | 5 quedas do líder por `docker kill`: líder antigo e novo, termos; log do Raft de um sobrevivente na 1ª |
| `evidencias/2026-10-26_2119_parada_lider_stop.txt` | 5 paradas do líder por `docker stop`, para comparar |
| `evidencias/2026-10-26_2120_quadro_quorum.txt` | escrita, leitura linearizável e serializável com 3, 2 e 1 membros ativos (endpoint único) |
| `evidencias/2026-10-26_2120_validacao_final.txt` | cluster saudável no fim |

## Medições (5 repetições, R7)
| Medição | n | média (ms) | desvio padrão | mín | máx | falhas |
|---|---|---|---|---|---|---|
| eleição após `docker kill` do líder | 5 | 1462,1 | 179,7 | 1220,2 | 1637,9 | 0 |
| eleição após `docker stop` do líder | 5 | 9,0 | 1,7 | 7,2 | 11,3 | 0 |

CSVs: `resultados/2026-10-26_2118_e5_eleicao_kill.csv`, `resultados/2026-10-26_2119_e5_eleicao_stop.csv`.

**Quadro de quórum** (`2026-10-26_2120_quadro_quorum.txt`):

| Membros ativos | Escrita | Leitura linearizável | Leitura serializável |
|---|---|---|---|
| 3 | OK | OK | OK |
| 2 | OK | OK | OK |
| 1 | `context deadline exceeded` | `context deadline exceeded` | responde (último valor aplicado) |

Com 1 membro, o `endpoint status` dele mostra `IS LEADER = false` e `etcdserver: no leader`.

## Análise: previsão × resultado × teoria

| # | Previsão | Resultado | Situação |
|---|---|---|---|
| 1 | Novo líder em 1–3 s, termo maior, escritas voltam | 1,46 ± 0,18 s com `kill`; termo +1; escritas OK com 2 membros | ✅ confirmada |
| 2 | Sem maioria: escrita e leitura linearizável falham, serializável responde | exatamente isso | ✅ confirmada |

**Discussão**
1. **Detecção por timeout (Q10).** Com `kill`, os seguidores não recebem aviso: só percebem a falta de *heartbeat* depois do *election timeout* (1 s, sorteado entre 1 e 2 s; Raft, §5.2). A média de 1,46 s cai dentro dessa janela.
2. **Parada ordenada (não previsto).** Com `docker stop` (SIGTERM), o etcd transfere a liderança a um seguidor antes de sair, e a troca leva cerca de 9 ms, 160 vezes menos que com `kill`. A eleição real só aparece na falha abrupta; por isso a demonstração deve usar `docker kill`.
3. **Quórum (Q7).** N = 3, maioria 2, tolera f = 1 falha. Com 2 membros tudo funciona. Com 1, escrita e leitura linearizável esperam a maioria até o prazo e falham. A leitura serializável continua respondendo com a cópia local: disponível, mas possivelmente desatualizada.
4. **Ressalva.** Na repetição 2 do `kill`, o CSV registra termo 3 → 3: o termo "depois" foi lido de um membro que ainda não tinha adotado o novo termo (a repetição 3 já começa no termo 4). O tempo medido não é afetado.

## Questões que este experimento sustenta
Q7 (quórum), Q8 (eleição), Q10 (falhas e detecção), S1 (timeout aleatório), S2 (por que 3 membros).
