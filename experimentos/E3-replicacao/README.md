# E3 — Replicação (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Escrever em um nó e ler em outro; medir latência/propagação.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: 2026-10-25 12:52 — respostas de David a um questionário de múltipla escolha; texto montado pelo Claude Code a partir das escolhas (ver `docs/uso-ia.md`)
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. Escrevendo em etcd1, um `get` em etcd3 logo em seguida já vê o valor? Por quê?
> 2. Um `watch` em etcd2 recebe a notificação em quanto tempo (ordem de grandeza)?
> 3. Qual é mais lento, `put` ou `get` linearizável? Por quê?
> 4. O `etcdctl check perf --load=s` vai passar nesta máquina (Docker no Windows)?
> O que esperamos observar e por quê (citar Raft/ZAB, quórum etc.):

1. **Ler em outro nó logo após escrever:** esperamos ver **sempre o valor novo**, porque a leitura padrão do etcd é linearizável: antes de responder, o nó confere com o líder que está atualizado.
2. **Watch:** esperamos que o aviso chegue em **milissegundos**, porque ele é enviado (*push*) assim que a escrita é confirmada pela maioria, sem consulta periódica.
3. **Put × get:** esperamos o **put mais lento**, porque a escrita precisa ir ao líder, ser gravada em disco e ser confirmada pela maioria, enquanto a leitura não grava nada.
4. **check perf (carga pequena):** esperamos que **passe**, porque a máquina (i7, SSD) é bem mais forte que o necessário para a carga pequena.

## Procedimento
Script reproduzível: [`executar.sh`](executar.sh) (da raiz). Cliente de medição: [`etcd/cliente/e3_replicacao.py`](../../etcd/cliente/e3_replicacao.py).
1. São 20 repetições, todas no `etcd-cliente` e com um único relógio:
   - `put` em **etcd1**;
   - logo em seguida, `get` (leitura padrão) em **etcd3**;
   - um **watch** aberto em **etcd2** registra o atraso entre o envio do put e a chegada do evento.
2. Latência de `put`, `get` linearizável e `get` serializável no mesmo membro (etcd3, que era o líder nesta execução), 20 repetições cada (`scripts/latencia.sh`).
3. `etcdctl check perf --load=s` (60 s) e `docker stats` logo depois (memória sob carga).

## Evidências
Executado em 25/10/2026, 13:08–13:09, depois do commit da previsão (12:52). Líder: etcd3, termo 3.

| Arquivo | O que mostra |
|---|---|
| `evidencias/2026-10-25_1308_escreve1_le3_watch2.txt` | 20/20 leituras em etcd3 devolveram o valor recém-escrito em etcd1 (`igual=True`); atraso do watch por repetição |
| `evidencias/2026-10-25_1308_latencias.txt` | tabelas de latência (watch, put, get lin., get ser.) |
| `evidencias/2026-10-25_1308_check_perf_s.txt` | `PASS: Throughput is 151 writes/s`, `Slowest request took 0.035908s`, `Stddev 0.001853s` |
| `evidencias/2026-10-25_1309_memoria_apos_carga.txt` | etcd1 86,9 MiB, etcd2 81,2 MiB, etcd3 80,2 MiB (limite 256 MiB) |

## Medições (20 repetições, R7)
| Medição | n | média (ms) | desvio padrão | mín | máx | falhas |
|---|---|---|---|---|---|---|
| atraso do watch em etcd2 (put enviado a etcd1 → evento) | 20 | 6,44 | 1,31 | 4,32 | 9,36 | 0 |
| put em etcd3 (líder) | 20 | 3,28 | 0,78 | 2,58 | 5,48 | 0 |
| get linearizável em etcd3 | 20 | 1,46 | 0,63 | 0,91 | 4,04 | 0 |
| get serializável em etcd3 | 20 | 0,76 | 0,28 | 0,42 | 1,66 | 0 |

CSVs: `resultados/2026-10-25_1308_e3_*.csv`.

## Análise: previsão × resultado × teoria

| # | Previsão | Resultado | Situação |
|---|---|---|---|
| 1 | A leitura em outro nó vê sempre o valor novo | 20 de 20 leituras corretas | ✅ confirmada |
| 2 | Watch avisa em milissegundos | 6,4 ± 1,3 ms do envio do put até o evento, incluindo o próprio put | ✅ confirmada |
| 3 | Put mais lento que get | put 3,28 ms > get lin. 1,46 ms > get ser. 0,76 ms | ✅ confirmada |
| 4 | `check perf` (carga pequena) passa | `PASS`, 151 escritas/s | ✅ confirmada |

**Discussão**
1. **Linearizabilidade na prática (Q6).** Mesmo lendo num membro diferente daquele que recebeu a escrita, imediatamente depois, nenhuma das 20 leituras viu valor antigo. A leitura padrão usa **ReadIndex**: o membro pergunta ao líder qual é o índice comprometido e espera tê-lo aplicado antes de responder. A comparação com o ZooKeeper, onde a leitura padrão é local, fica para o E9-E3.
2. **O watch é empurrado (*push*).** O atraso de 6,4 ms é a soma de três partes: o put (cerca de 3–5 ms, ida ao líder e commit na maioria), a aplicação no etcd2 e o envio do evento. Não há consulta periódica.
3. **O custo de cada garantia.** Escrita (3,3 ms) > leitura linearizável (1,5 ms) > leitura serializável (0,8 ms). Cada degrau acrescenta uma etapa de coordenação:
   - a escrita precisa de replicação na maioria e de fsync;
   - a leitura linearizável precisa de uma ida ao líder para obter o ReadIndex;
   - a serializável não precisa de nada.
   O E4 detalha o par linearizável × serializável.
4. **Desempenho e memória (seção 4).** O `check perf` passou com folga: 151 escritas/s e a requisição mais lenta em 36 ms. Mesmo depois dele, cada membro usou menos de 90 MiB dos 256 MiB permitidos. Isso fecha o critério A6 (memória sob carga).
5. **Ressalva.** Nesta execução, as latências do item 2 foram medidas no **líder**. O custo extra de usar um seguidor foi medido no E2 (cerca de 1,3 ms a mais no put).

## Questões que este experimento sustenta
- **Q3:** todos os membros têm a cópia.
- **Q5:** replicação.
- **Q6:** linearizável na prática.
- **Q14:** vazão e limites medidos.
- **S3:** custo do ReadIndex.
- **Seção 4:** memória sob carga.
