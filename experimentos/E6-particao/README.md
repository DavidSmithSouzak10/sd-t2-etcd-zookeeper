# E6 — Partição de rede (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Isolar o líder do restante, mantendo-o acessível ao cliente; observar os dois lados.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Registrada em 2026-10-26 21:11, antes de qualquer execução (ver `docs/uso-ia.md`).

- **Os dois lados:** esperamos que o lado majoritário eleja um novo líder, com termo maior, em poucos segundos, e que o líder isolado deixe de ser líder (*check quorum*) e pare de aceitar escritas. O cliente ligado só a ele recebe erro ou timeout no `put` e no `get` linearizável; o `get` serializável pode devolver o valor antigo. Porque só o lado com maioria consegue confirmar operações.
- **C × A:** esperamos que o etcd escolha consistência: o lado minoritário fica indisponível para não existirem duas versões dos dados.

## Procedimento
1. Desconectar o **líder** da rede interna (`scripts/particionar.sh isolar etcdN`).
2. Observar o lado majoritário elegendo novo líder com termo maior e o antigo líder deixando de aceitar escritas. O que um cliente conectado só a ele recebe?
3. Concluir sobre a escolha entre consistência e disponibilidade (C × A).

Script reproduzível: [`executar.sh`](executar.sh) (da raiz). Partição: `scripts/particionar.sh isolar|religar`. Início da eleição = evento `disconnect` do `docker events`; fim = primeiro membro do lado majoritário que informa o novo líder.

## Evidências
Executado em 26/10/2026 na máquina do Samuel (Windows 11, Docker 28.0.1), depois do registro da previsão (`5196dea`, revisada em `0dc40dd`). Horário: 21:20–21:22.

| Arquivo | O que mostra |
|---|---|
| `evidencias/2026-10-26_2120_eleicao_lado_majoritario.txt` | 5 isolamentos do líder: tempo até o lado majoritário eleger outro, termos |
| `evidencias/2026-10-26_2121_linha_do_tempo.txt` | o que o líder isolado e o lado majoritário respondem, rodada a rodada |
| `evidencias/2026-10-26_2122_validacao_final.txt` | cluster saudável depois de religar |

## Medições (5 repetições, R7)
| Medição | n | média (ms) | desvio padrão | mín | máx | falhas |
|---|---|---|---|---|---|---|
| eleição do lado majoritário após isolar o líder | 5 | 940,9 | 242,7 | 629,2 | 1298,8 | 0 |

CSV: `resultados/2026-10-26_2120_e6_eleicao_particao.csv`.

**Linha do tempo** (`2026-10-26_2121_linha_do_tempo.txt`; isolado = etcd2, maioria observada em etcd1):

| Instante | Líder isolado (etcd2) | Lado majoritário (etcd1) |
|---|---|---|
| 21:21:27,5 | `put ANTIGO` → OK | |
| 21:21:28,5 | desconectado da rede interna | |
| rodada 1 | put: `request timed out`; get linearizável: `context deadline exceeded`; get serializável: `ANTIGO`; status: não é líder, `no leader`, termo 18 | líder, termo 19 |
| 21:21:44,4 | | `put NOVO` → OK |
| rodadas 2–6 (até 21:22:18) | put e linearizável sempre falham; serializável sempre `ANTIGO` | linearizável `NOVO` |
| 21:22:20,9 | religado | |
| depois | os 3 membros leem `NOVO`; termo 19 e RAFT INDEX 2026 iguais | |

## Análise: previsão × resultado × teoria

| # | Previsão | Resultado | Situação |
|---|---|---|---|
| 1 | Maioria elege em poucos segundos com termo maior; isolado deixa de ser líder e recusa escrita; o cliente dele recebe erro; a serializável pode devolver o valor antigo | eleição em 0,94 ± 0,24 s, termo +1; isolado sem líder já na 1ª rodada; escrita e linearizável com erro; serializável `ANTIGO` | ✅ confirmada |
| 2 | Escolhe consistência (C) | o lado minoritário não aceitou nenhuma das 6 escritas; depois de religar não há versão divergente | ✅ confirmada |

**Discussão**
1. **Check quorum.** O líder isolado deixou de ser líder porque não ouviu a maioria dentro de um *election timeout*. Assim, um líder antigo não continua atendendo como se nada tivesse acontecido.
2. **CAP e PACELC (Q11).** Sob partição (P), o etcd escolhe C: o lado minoritário fica indisponível para escrita e para leitura linearizável. O que ele ainda responde é a leitura serializável, que devolveu o valor antigo: o cliente só abre mão da consistência se pedir explicitamente. Sem partição (E), o etcd paga latência pela consistência (E4: linearizável 1,82 ms × serializável 0,65 ms). Classificação: PC/EC.
3. **Termo do isolado.** O isolado ficou no termo 18 enquanto a maioria foi para 19, e ao religar não provocou nova eleição (termo final 19). É o comportamento esperado do *pre-vote*: um nó que não alcança a maioria não incrementa o termo.
4. **Ressalva de medição.** Três das 5 medições ficaram abaixo de 1 s, menos que o *election timeout* mínimo. Isso indica que o evento `disconnect` do Docker é registrado depois que a rede já foi cortada. Os tempos do E6 são um limite inferior e não devem ser comparados diretamente com o E5.

## Questões que este experimento sustenta
Q10 (detecção), Q11 (C × A, com o experimento), Q6 (o lado majoritário sempre lê o valor novo).
