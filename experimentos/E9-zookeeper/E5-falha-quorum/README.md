# E9/E5 — Falha e quórum no ZooKeeper

> Roteiro: PDF §9.5, ênfase D. Rodar `scripts/validar.sh zk` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Repetir o E5 da bateria comum no ensemble ZooKeeper. Comparar época ZAB × termo Raft e os tempos de eleição.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Registrada em 2026-10-26 21:11, antes de qualquer execução (ver `docs/uso-ia.md`).

- **Parar o líder:** esperamos uma eleição mais rápida que a do etcd, porque ao parar o contêiner as conexões TCP fecham e os seguidores percebem na hora, sem esperar timeout. A época do zxid sobe 1 e o contador recomeça.
- **Sem maioria:** esperamos que o servidor restante pare de atender leituras e escritas, porque sem quórum ele sai do ensemble (o modo *read-only* está desligado). Diferente do etcd, onde a leitura serializável ainda responde.

## Procedimento
Parar o líder: tempo até novo líder ≥ 5× e **nova época no zxid** (`srvr.py`, `currentEpoch`). Parar o 2º servidor: o que falha para leitura e escrita?

Script reproduzível: [`executar.sh`](executar.sh) (da raiz). Clientes: [`zookeeper/cliente/e9_eleicao.py`](../../../zookeeper/cliente/e9_eleicao.py) e [`e9_operacoes.py`](../../../zookeeper/cliente/e9_operacoes.py). Início = evento `kill` do `docker events`; fim = primeiro sobrevivente em `Mode: leader`.

## Evidências
Executado em 26/10/2026 na máquina do Samuel (Windows 11, Docker 28.0.1), depois do registro da previsão (`5196dea`, revisada em `0dc40dd`). Horário: 21:48–21:50. Uma primeira execução (21:29–21:31) foi descartada: o quadro de quórum deu `NoNodeError` porque o znode pai `/e9` não existia num ensemble novo; corrigido com `makepath=True` em `e9_operacoes.py` (ver diário, sessão 9).

| Arquivo | O que mostra |
|---|---|
| `evidencias/2026-10-26_2148_queda_lider_kill.txt` | 5 quedas do líder por `docker kill`: estados de cada servidor a cada 10 ms, épocas |
| `evidencias/2026-10-26_2149_parada_lider_stop.txt` | 5 paradas por `docker stop` |
| `evidencias/2026-10-26_2149_quadro_quorum.txt` | sessão, escrita, leitura local e `sync` + leitura com 3, 2 e 1 servidores |
| `evidencias/2026-10-26_2150_validacao_final.txt` | ensemble saudável no fim |

## Medições (5 repetições, R7)
| Medição | n | média (ms) | desvio padrão | mín | máx | falhas |
|---|---|---|---|---|---|---|
| eleição após `docker kill` do líder | 5 | 382,3 | 90,0 | 339,2 | 543,2 | 0 |
| eleição após `docker stop` do líder | 5 | 703,6 | 93,5 | 658,2 | 870,7 | 0 |

CSVs: `resultados/2026-10-26_2148_e9e5_eleicao_kill.csv`, `resultados/2026-10-26_2149_e9e5_eleicao_stop.csv`. A época subiu 1 em cada uma das 10 eleições (25 → 35).

**Quadro de quórum** (`2026-10-26_2149_quadro_quorum.txt`):

| Servidores ativos | Sessão | Escrita | Leitura local | `sync` + leitura |
|---|---|---|---|---|
| 3 | abre | OK | OK | OK |
| 2 | abre | OK | OK | OK |
| 1 | não abre (`KazooTimeoutError`); `srvr`: sem serviço | — | — | — |

## Análise: previsão × resultado × teoria

| # | Previsão | Resultado | Situação |
|---|---|---|---|
| 1 | Eleição mais rápida que a do etcd; época +1 e contador recomeça | 0,38 s no ZooKeeper × 1,46 s no etcd (`kill`); época +1 em 10 de 10; contador zera (por exemplo, `0x1200000000` no E9-E6) | ✅ confirmada |
| 2 | Sem maioria, o servidor para de atender leitura e escrita (diferente do etcd) | sem serviço; a sessão nem abre | ✅ confirmada |

**Discussão**
1. **Por que mais rápido que o etcd.** Com `kill`, as conexões TCP do líder se fecham e os seguidores percebem na hora (cerca de 7 ms, coluna `deteccao_ms`), entram em LOOKING e a eleição termina em cerca de 0,3 s. O Raft do etcd não usa o fechamento da conexão como sinal e espera o *election timeout*. Essa vantagem se inverte quando a conexão não fecha, como numa partição (E9-E6).
2. **`stop` mais lento que `kill` no ZooKeeper.** É o contrário do etcd: o ZooKeeper não transfere a liderança ao parar, e com SIGTERM os seguidores levaram cerca de 56 ms para perceber (contra 7 ms no `kill`), seguidos de uma eleição completa.
3. **Sem maioria (Q7, Q10).** O ZooKeeper é mais restritivo que o etcd: sem quórum o servidor sai do ensemble e não atende ninguém (o modo *read-only* está desligado), enquanto o etcd ainda responde leitura serializável. Os dois preferem consistência.

## Questões que este experimento sustenta
Q7 (quórum), Q8 (eleição: FLE × Raft), Q10 (detecção de falhas).
