# E9/E7 — Recuperação no ZooKeeper

> Roteiro: PDF §9.5, ênfase D. Rodar `scripts/validar.sh zk` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Repetir o E7 da bateria comum no ensemble ZooKeeper. Comparar com catch-up por log/snapshot do etcd.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Registrada em 2026-10-26 21:11, antes de qualquer execução (ver `docs/uso-ia.md`).

- **Religar:** esperamos sincronização por DIFF, porque faltam poucas transações e o líder as tem em memória, e o zxid igual nos 3 alguns segundos depois de religar. A sincronização em si é rápida, mas o servidor precisa sair do LOOKING e reencontrar o líder, e o intervalo entre suas tentativas de eleição cresce enquanto ele está isolado.

## Procedimento
Religar e observar a sincronização com o líder nos logs (DIFF, SNAP ou TRUNC); tempo até o zxid igualar ≥ 5×.

Script reproduzível: [`executar.sh`](executar.sh) (da raiz). Cliente: [`zookeeper/cliente/e9_alcance.py`](../../../zookeeper/cliente/e9_alcance.py). Início = evento `connect`; fim = o servidor religado está em `follower` com o mesmo zxid dos outros. Tipo de sincronização lido no log do novo líder (`Sending DIFF|SNAP|TRUNC`).

## Evidências
Executado em 26/10/2026 na máquina do Samuel (Windows 11, Docker Engine 29.9.2), depois do registro da previsão (`5196dea`, revisada em `0dc40dd`). Horário: 21:33–21:35.

| Arquivo | O que mostra |
|---|---|
| `evidencias/2026-10-26_2133_reconexao_e_alcance.txt` | 5 ciclos isolar → 200 escritas pela maioria → religar; linhas `Sending DIFF` do líder |
| `evidencias/2026-10-26_2135_rodada_5000_escritas.txt` | 1 ciclo com 5000 escritas durante o isolamento |
| `evidencias/2026-10-26_2135_validacao_final.txt` | ensemble saudável no fim |

## Medições (5 repetições, R7)
| Medição | n | média (ms) | desvio padrão | mín | máx | falhas |
|---|---|---|---|---|---|---|
| religar → `follower` com o zxid dos outros (200 transações atrasadas) | 5 | 2520,3 | 678,6 | 1866,7 | 3287,0 | 0 |

Sincronização: DIFF nas 5 repetições. Rodada extra com 5000 transações (1 repetição, não atende R7): 6654,1 ms, também DIFF. CSVs: `resultados/2026-10-26_2133_e9e7_recuperacao.csv`, `resultados/2026-10-26_2135_e9e7_recuperacao_5000.csv`.

## Análise: previsão × resultado × teoria

| # | Previsão | Resultado | Situação |
|---|---|---|---|
| 1 | Sincroniza por DIFF; zxid igual alguns segundos depois de religar, porque o servidor precisa sair do LOOKING e reencontrar o líder | DIFF em 6 de 6; 2,5 ± 0,7 s | ✅ confirmada |

**Discussão**
1. **DIFF, SNAP e TRUNC (Q12).** O líder enviou só as transações que faltavam (DIFF), inclusive com 5000 escritas de atraso. O SNAP (estado inteiro) fica para atrasos grandes demais para mandar como diferença, e o TRUNC exige que o servidor que volta tenha transações que o grupo não confirmou; nenhum dos dois apareceu nestes cenários. É o equivalente ao par log × snapshot do etcd (E7).
2. **Onde está o tempo.** Como no etcd, o tempo é gasto para voltar ao grupo, e não para copiar dados: o servidor sai do LOOKING, encontra o líder e só então recebe o DIFF. Com 5000 transações o total subiu para 6,7 s.
3. **Comparação com o etcd.** O ZooKeeper voltou mais rápido (2,5 s × cerca de 6,5 s no E7), com volumes diferentes (200 × 1005 entradas). Os dois terminam com o estado idêntico ao do líder.

## Questões que este experimento sustenta
Q12 (recuperação incremental × completa).
