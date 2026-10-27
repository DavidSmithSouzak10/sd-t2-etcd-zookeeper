# E7 — Recuperação (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Religar o nó e observar como ele se atualiza; medir o tempo até o cluster ficar saudável.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Registrada em 2026-10-26 21:11, antes de qualquer execução (ver `docs/uso-ia.md`).

- **Religar:** esperamos que o membro volte como seguidor, adote o termo maior e alcance o RAFT INDEX dos outros em menos de 1 s. Porque o líder envia só as entradas que faltam, numa rede local.
- **Snapshot:** com `--snapshot-count=1000` e milhares de escritas enquanto ele está parado, esperamos recuperação por snapshot, porque o líder já compactou as entradas antigas do log. O estado final (chaves e revisão) fica idêntico nos 3.

## Procedimento
1. Reconectar o membro isolado e mostrá-lo voltando como seguidor, com termo atualizado, alcançando o mesmo RAFT INDEX (medir o tempo, ≥ 5 repetições).
2. Recriar o cluster com `SNAPSHOT_COUNT=1000` (`etcd/.env`), deixar um membro parado enquanto faz milhares de escritas e mostrar que ele se recupera por **snapshot** em vez de reaplicar o log inteiro.

Script reproduzível: [`executar.sh`](executar.sh) (da raiz). Cliente de medição: [`etcd/cliente/e7_alcance.py`](../../etcd/cliente/e7_alcance.py). Início = evento `connect` do `docker events`; fim = o membro religado informa um líder e tem RAFT INDEX ≥ o dos outros.

## Evidências
Executado em 26/10/2026 na máquina do Samuel (Windows 11, Docker Engine 29.9.2), depois do registro da previsão (`5196dea`, revisada em `0dc40dd`). Horário: 21:22–21:24.

| Arquivo | O que mostra |
|---|---|
| `evidencias/2026-10-26_2122_reconexao_e_alcance.txt` | 5 ciclos isolar → 1000 escritas pela maioria → religar: índices e termos antes e depois |
| `evidencias/2026-10-26_2124_recuperacao_por_snapshot.txt` | cluster com `--snapshot-count=1000`, seguidor parado durante 10 000 escritas; logs de envio e recebimento do snapshot; `endpoint hashkv` |
| `evidencias/2026-10-26_2124_restauracao.txt` | cluster recriado com o padrão (100 000) |
| `evidencias/2026-10-26_2124_validacao_final.txt` | cluster saudável no fim |

## Medições (5 repetições, R7)
| Medição | n | média (ms) | desvio padrão | mín | máx | falhas |
|---|---|---|---|---|---|---|
| religar → alcançar o RAFT INDEX (1005 entradas atrasadas) | 5 | 5217,8 | 2895,5 | 49,8 | 6730,9 | 0 |

CSV: `resultados/2026-10-26_2122_e7_recuperacao.csv`. Valores por repetição: 49,8; 6358,8; 6730,9; 6670,7; 6279,0 ms. Em todas, o instante em que o membro volta a ver o líder coincide com o instante em que alcança o índice.

**Snapshot** (1 execução): o líder registra `sending merged snapshot` (701 kB, índice 10 026); o seguidor registra `restored snapshot [index: 10026]`. O seguidor alcançou o líder cerca de 1,05 s depois do `docker start` (medido no host, inclui a inicialização do processo). `endpoint hashkv`: 879865897 nos 3 membros.

## Análise: previsão × resultado × teoria

| # | Previsão | Resultado | Situação |
|---|---|---|---|
| 1 | Volta como seguidor, adota o termo maior e alcança o índice em menos de 1 s | seguidor com termo maior em 5 de 5; alcance em menos de 1 s só em 1 de 5 (50 ms); nas outras, 6,3–6,7 s | ❌ refutada no tempo |
| 2 | Recupera por snapshot; estado final idêntico | snapshot de 701 kB; hash igual nos 3 | ✅ confirmada |

**Discussão**
1. **Onde está o atraso.** O mecanismo previsto se confirmou: depois que o membro volta a falar com o líder, as 1005 entradas faltantes chegam no mesmo intervalo de consulta (10 ms). Os cerca de 6,5 s são gastos antes disso, para restabelecer a comunicação depois do `docker network connect`. A causa não foi isolada. Hipóteses a verificar: o intervalo de nova tentativa de conexão entre pares do etcd, ou a resolução do endereço físico do contêiner religado na rede do Docker. O ZooKeeper também levou segundos para voltar (E9-E7). Registrar na seção 9 (limitações).
2. **Log × snapshot (Q12).** Com `--snapshot-count=1000`, o líder mantém só as entradas recentes depois de cada snapshot. Com 10 000 escritas durante a ausência, as entradas antigas já tinham sido descartadas, e o líder enviou o estado inteiro (banco + log, *merged snapshot*). O snapshot do etcd é a cópia do estado de um nó num índice confirmado. Diferente do algoritmo de Chandy-Lamport, não precisa de marcadores para obter um corte consistente: todos aplicam a mesma sequência de entradas, então qualquer índice confirmado já é um estado global consistente.
3. **Estado idêntico.** O hash igual nos 3 membros é a garantia de segurança da máquina de estados do Raft na prática.
4. **Termo.** O membro isolado manteve o termo antigo (por exemplo, 19 com a maioria em 20) e adotou o maior ao voltar, como no E6 (*pre-vote*).

## Questões que este experimento sustenta
Q12 (recuperação, log × snapshot), Q10 (falha e retorno), Q5 (máquina de estados replicada).
