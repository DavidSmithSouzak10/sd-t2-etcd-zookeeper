# E9/E8 — Coordenação no ZooKeeper

> Roteiro: PDF §9.5, ênfase D. Rodar `scripts/validar.sh zk` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Repetir o E8 da bateria comum no ensemble ZooKeeper. Comparar com `etcdctl lock/elect` (lease × sessão).

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Registrada em 2026-10-26 21:11, antes de qualquer execução (ver `docs/uso-ia.md`).

- **Trava e eleição:** esperamos que só o próximo da fila seja avisado (cada cliente observa o znode anterior) e que, parando o dono, a trava libere quando a sessão expira (cerca de 10 s no kazoo), como o lease do etcd.
- **Época × termo:** esperamos que sejam a mesma ideia: um número de mandato que sobe a cada novo líder e faz os servidores recusarem mensagens do líder antigo.

## Procedimento
Trava (kazoo `Lock`) e eleição (kazoo `Election`) com **znodes efêmeros e sequenciais**, com 2 clientes cada; matar o detentor e medir o tempo de troca (session timeout) ≥ 5×.

Script reproduzível: [`executar.sh`](executar.sh) (da raiz). Cliente: [`zookeeper/cliente/e9_coordenacao.py`](../../../zookeeper/cliente/e9_coordenacao.py) (receitas `Lock` e `Election` do kazoo). A morre com `os._exit` sem fechar a sessão; tempo de troca = `ADQUIRIU B` − `MORREU A`, no mesmo relógio.

## Evidências
Executado em 26/10/2026 na máquina do Samuel (Windows 11, Docker Engine 29.9.2), depois do registro da previsão (`5196dea`, revisada em `0dc40dd`). Horário: 21:35–21:40.

| Arquivo | O que mostra |
|---|---|
| `evidencias/2026-10-26_2135_troca_detentor.txt` | sessões, znodes efêmeros sequenciais (`…__lock__0000000000`, `…0000000001`), `ephemeralOwner`, `czxid`; 5 trocas de trava e 5 de eleição |
| `evidencias/2026-10-26_2139_epoca_x_termo.txt` | época ZAB (`srvr`, `currentEpoch`, `acceptedEpoch`) ao lado do termo Raft do etcd |
| `evidencias/2026-10-26_2140_validacao_final.txt` | ensemble saudável no fim |

## Medições (5 repetições, R7)
| Medição | n | média (ms) | desvio padrão | mín | máx | falhas |
|---|---|---|---|---|---|---|
| troca da trava após a morte do dono (sessão de 10 s) | 5 | 7946,5 | 114,1 | 7742,4 | 7999,5 | 0 |
| troca da eleição após a morte do líder (sessão de 10 s) | 5 | 7828,9 | 376,9 | 7154,7 | 7998,6 | 0 |

CSVs: `resultados/2026-10-26_2135_e9e8_troca_trava.csv`, `resultados/2026-10-26_2137_e9e8_troca_eleicao.csv`.

## Análise: previsão × resultado × teoria

| # | Previsão | Resultado | Situação |
|---|---|---|---|
| 1 | Só o próximo da fila é avisado; com a morte do dono, a trava libera quando a sessão expira (cerca de 10 s) | fila sequencial (`…0000` dono, `…0001` à espera); troca em 7,9 s, depois da expiração da sessão | ✅ confirmada (com 2 clientes, a ausência de "manada" não é observável; vem da receita) |
| 2 | Época e termo são a mesma ideia | a época sobe 1 a cada novo líder (25 → 35 no E9-E5), como o termo no etcd | ✅ confirmada |

**Discussão**
1. **Sessão × lease (Q13).** No ZooKeeper o znode efêmero vive enquanto a sessão vive; no etcd a chave vive enquanto o lease é renovado. Os dois liberaram a trava em cerca de 8 s, com prazo nominal de 10 s, porque o prazo conta a partir do último contato do cliente, não do instante da morte.
2. **Época × termo (Q9).** A época ocupa os 32 bits altos de cada zxid e sobe a cada líder eleito; o contador (32 bits baixos) recomeça. Ela tem o mesmo papel do termo do Raft: os seguidores recusam propostas de um líder com época menor. A diferença é de representação: no ZAB a época faz parte do identificador de cada transação; no Raft, termo e índice são campos separados de cada entrada.
3. **Fencing (S4).** O `czxid` do znode da trava cresce a cada nova aquisição (`0x19000013ae`, `0x19000013b0`) e pode servir de fencing token, como a revisão no etcd (E8).

## Questões que este experimento sustenta
Q8, Q9 (época como relógio lógico), Q13 (exclusão mútua e eleição), S4.
