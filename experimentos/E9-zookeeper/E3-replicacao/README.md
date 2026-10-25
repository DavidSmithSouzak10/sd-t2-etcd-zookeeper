# E9/E3 — Replicação no ZooKeeper

> Roteiro: PDF §9.5, ênfase D. Rodar `scripts/validar.sh zk` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Repetir o E3 da bateria comum no ensemble ZooKeeper. Comparar com E3 do etcd (watch, latência).

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: 2026-10-25 12:57 — respostas de David a um questionário de múltipla escolha; texto montado pelo Claude Code a partir das escolhas (ver `docs/uso-ia.md`)
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. `set` em zk1 e `get` em zk3 logo depois: o valor novo aparece sempre? Por quê?
> 2. Um watch (`get -w`) dispara uma vez ou a cada mudança?
> 3. A latência de escrita do ZK será maior ou menor que a do etcd? (E0 deu uma pista: e a margem de erro?)

1. **Ler em outro servidor logo após escrever:** esperamos que **possa vir o valor antigo**, porque a leitura padrão do ZooKeeper é local: se o zk3 ainda não aplicou a escrita, responde o valor velho por um instante. É diferente do etcd, onde a leitura padrão é linearizável.
2. **Watch:** esperamos que **dispare uma vez só**. O watch do ZooKeeper é de disparo único; depois de avisar, o cliente precisa registrá-lo de novo. Também diferente do etcd, onde o watch fica ativo.

## Procedimento
Os papéis são definidos na hora pelo `srvr` (`zk_papeis` em `scripts/lib.sh`). Nesta execução: líder **zk3**, escrita em **zk1**, leitura em **zk2**, watch em **zk3**. Assim a escrita e a leitura passam por seguidores diferentes, que é o pior caso para a leitura local.

1. `e9_replicacao.py` (cliente kazoo no `zk-cliente`, uma conexão por servidor):
   - (a) 20 vezes: `set` no zk1 e logo em seguida `get` no zk2, sem `sync`;
   - (b) watch registrado **uma vez** no zk3, seguido de 3 mudanças;
   - (c) 20 vezes: o atraso entre o `set` no zk1 e o callback do watch no zk3, registrando o watch de novo a cada vez.
2. `scripts/latencia.sh zk`: `set`, `get` local e `sync`+`get` no seguidor zk2, 20 repetições cada.
3. `docker stats` (memória) e `validar.sh zk`.

Script reproduzível: `executar.sh`. Execução: 25/10/2026, 13:15.

> Uma execução anterior (13:13) foi descartada e apagada. Os rótulos impressos pelo script estavam fixos ("zk2", "zk1") e não batiam com os papéis reais. Os números eram equivalentes (0/20 leituras antigas, 1 disparo, watch 6,9 ms).

## Evidências
| Arquivo | O que mostra |
|---|---|
| `evidencias/2026-10-25_1315_estado_inicial.txt` | `srvr`: zk3 líder, época 3, mesmo zxid nos 3 |
| `evidencias/2026-10-25_1315_replicacao_e_watch.txt` | 20 pares set/get, watch de disparo único e atraso do watch |
| `evidencias/2026-10-25_1315_latencias.txt` | tabelas de média e desvio (set, get local, sync+get, watch) |
| `evidencias/2026-10-25_1316_memoria.txt` | memória dos 3 servidores e do cliente |
| `evidencias/2026-10-25_1316_validacao_final.txt` | ensemble saudável depois do experimento |

## Medições (20 repetições, R7)
| Medição | n | média (ms) | desvio padrão | mín | máx | falhas |
|---|---|---|---|---|---|---|
| atraso do watch (set no zk1 até o callback no zk3) | 20 | 5,93 | 0,82 | 4,68 | 7,14 | 0 |
| set no seguidor zk2 | 20 | 7,00 | 0,97 | 5,94 | 9,88 | 0 |
| get local no zk2 | 20 | 1,53 | 0,26 | 1,17 | 2,07 | 0 |
| sync + get no zk2 | 20 | 3,89 | 0,52 | 3,26 | 5,22 | 0 |

CSVs: `resultados/2026-10-25_1315_e9e3_*.csv`.

Memória logo depois: zk1 82,7 MiB, zk2 132,8 MiB, zk3 99,2 MiB (limite de 256 MiB cada); cliente 16,8 MiB.

## Análise: previsão × resultado × teoria × etcd

| # | Previsão | Resultado | Situação |
|---|---|---|---|
| 1 | Ler em outro servidor logo depois de escrever **pode** trazer o valor antigo | 0 de 20 leituras antigas | ⚠️ não observada (a possibilidade não foi refutada; ver discussão) |
| 2 | O watch dispara uma vez só | 3 mudanças, **1** disparo (`CHANGED`) | ✅ confirmada |

**Discussão**
1. **Leitura local: permitida, mas rara aqui (Q6).** A garantia do ZooKeeper para leituras é só a **consistência sequencial por cliente** (Hunt et al., 2010, §2.3): uma leitura num seguidor pode ficar atrás do líder. Mesmo assim, as 20 leituras no zk2 vieram com o valor novo. Hipótese para isso:
   - o `set` só retorna depois que o líder confirma o commit na maioria;
   - nessa hora o COMMIT já foi enviado ao zk2, e numa rede local sem carga ele chega em menos de 1 ms;
   - o `get` seguinte, mandado por outra conexão, chega depois disso.

   Por isso, "pode vir o antigo" continua sendo uma possibilidade do protocolo que este caminho normal não expôs. Para expô-la é preciso um seguidor atrasado: isso é feito no E9-E4, com isolamento. **Não dá para concluir** que a leitura local é linearizável só porque 20 tentativas não mostraram valor antigo: ausência de evidência não é garantia.
2. **Watch de disparo único × watch contínuo.** No ZooKeeper o watch avisa **uma vez** e some, e o cliente precisa registrá-lo de novo. A notificação também não traz o valor novo, só o tipo do evento: o cliente precisa fazer outro `get`. Entre a notificação e o novo registro pode haver mudanças que o cliente não vê uma a uma.

   No etcd (E3) o watch é um *stream* contínuo: cada evento chega com o valor e a revisão, e dá para retomar a partir de uma revisão. O atraso medido foi parecido nos dois: **5,9 ± 0,8 ms** no ZK contra **6,4 ± 1,3 ms** no etcd.
3. **O preço do `sync`.** O `sync` + `get` custou **3,89 ms**, cerca de 2,5 vezes o `get` local (1,53 ms). É o mesmo padrão do etcd, onde a linearizável custa mais que a serializável. A diferença é o padrão de cada sistema:
   - o etcd é **seguro por padrão** e se paga para relaxar (`--consistency=s`);
   - o ZooKeeper é **rápido por padrão** e se paga para ter a leitura atual (`sync`).
4. **Escrita mais cara no ZK.** O `set` num seguidor do ZK levou **7,0 ms**. O put no **líder** do etcd levou 3,3 ms (E3), e o custo extra de passar por um seguidor no etcd foi de cerca de 1,3 ms (E2). As duas escritas têm a mesma estrutura: o seguidor encaminha ao líder, que propõe, recebe confirmação da maioria (com fsync) e faz commit. A diferença é de implementação: JVM e fsync do log de transações. Comparar com a mesma configuração (os dois via seguidor) fica para o quadro do E9.
5. **Memória.** Os servidores ZK usam de 83 a 133 MiB, cerca de 1,5 vez o etcd sob carga (80–87 MiB) e cerca de 3 vezes o etcd em repouso. Isso se deve à JVM, com heap de 128 MB.

## Questões que este experimento sustenta
- **Q5:** replicação no ZooKeeper.
- **Q6:** consistência sequencial × linearizável, com a ressalva do item 1.
- **Q4:** watch como notificação assíncrona (*push*).
- **E9 / quadro comparativo:** leitura padrão, custo do `sync`, memória.
- **S3:** contraste com o ReadIndex.
