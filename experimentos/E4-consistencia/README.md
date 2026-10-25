# E4 — Consistência (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Evidenciar o modelo de consistência: leitura atualizada garantida ou janela de leitura desatualizada.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: 2026-10-25 12:55 — respostas de David a um questionário de múltipla escolha; texto montado pelo Claude Code a partir das escolhas (ver `docs/uso-ia.md`)
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. Qual leitura será mais rápida: linearizável ou serializável? Por quanto, aproximadamente?
> 2. Com um seguidor isolado da rede interna, um `get` **linearizável** nele responde, trava ou falha?
> 3. E um `get` **serializável** nele: responde valor novo, valor antigo ou falha?
> 4. O RAFT INDEX sobe com leituras linearizáveis? (achado A1: o que vocês acham?)
> O que esperamos observar e por quê (citar Raft/ZAB, quórum etc.):

1. **Velocidade:** esperamos a leitura **serializável mais rápida** (talvez metade do tempo), porque ela responde direto da cópia local, sem conversar com o líder.
2. **Linearizável no seguidor isolado:** esperamos que **falhe ou dê timeout**, porque ele não consegue falar com o líder para confirmar que está atualizado e prefere não responder.
3. **Serializável no seguidor isolado:** esperamos que **responda o valor antigo**, porque ela não pergunta a ninguém e devolve a cópia local, que parou no momento do isolamento.
4. **Leituras linearizáveis e o log:** esperamos que **cada leitura linearizável faça o RAFT INDEX subir +1**, porque, para garantir a ordem, a leitura seria registrada no log como uma escrita.

## Procedimento
Script reproduzível: [`executar.sh`](executar.sh) (da raiz).
1. Latência de `get` linearizável × serializável no **mesmo seguidor** (etcd1), 20 repetições cada.
2. **As leituras gravam no log?** RAFT INDEX antes e depois de um bloco de **100 leituras**, 5 rodadas para cada tipo (linearizável, serializável), mais uma linha de base de 5 × 1 s sem leitura nenhuma. A linha de base existe por causa do healthcheck, que gera cerca de 0,6 entrada/s (E1).
3. **Seguidor isolado.** Sequência temporal:
   - grava `ANTIGO`;
   - isola etcd1 da rede interna (`scripts/particionar.sh isolar etcd1`), mantendo-o acessível ao cliente;
   - grava `NOVO` pelo líder;
   - faz 5 vezes, em etcd1: `get` linearizável e `get` serializável, e na maioria um `get` linearizável;
   - registra o status de cada membro;
   - religa etcd1 e mede quanto tempo ele leva até ver `NOVO`.

## Evidências
Executado em 25/10/2026, 13:10–13:11, depois do commit da previsão (12:55). Líder: etcd3, termo 3.

| Arquivo | O que mostra |
|---|---|
| `evidencias/2026-10-25_1310_latencia_lin_x_ser.txt` | latência de leitura no seguidor etcd1 |
| `evidencias/2026-10-25_1310_leituras_x_raft_index.txt` | o delta do RAFT INDEX em 100 leituras (lin. ou ser.) é igual ao da linha de base |
| `evidencias/2026-10-25_1310_seguidor_isolado.txt` | sequência temporal completa (abaixo) |
| `evidencias/2026-10-25_1311_validacao_final.txt` | cluster saudável no fim |

**Sequência temporal (seguidor isolado):**

| Hora | Evento |
|---|---|
| 13:10:48.060 | `put /e4/k ANTIGO` (líder etcd3) |
| 13:10:50.637 | etcd1 **isolado** da rede interna |
| 13:10:51.696 | `put /e4/k NOVO` pelo lado majoritário → OK |
| 13:10:55–13:11:10 | 5 tentativas em etcd1: **linearizável → `context deadline exceeded`** (timeout de 3 s); **serializável → `ANTIGO`**. Na maioria (etcd3), linearizável → `NOVO` |
| durante | status de etcd1: `etcdserver: no leader`, índice 9582; etcd2 e etcd3: índice 9592; **termo 3 em todos** |
| 13:11:12.004 | etcd1 **religado** (mesmo IP) |
| 13:11:19.057 | etcd1 serializável → `NOVO` (7,05 s depois de religar); termo continua 3, índice igual nos 3 (9597) |

## Medições (R7)
| Medição | n | média (ms) | desvio padrão | mín | máx | falhas |
|---|---|---|---|---|---|---|
| get linearizável no seguidor etcd1 | 20 | 1,82 | 0,30 | 1,25 | 2,69 | 0 |
| get serializável no seguidor etcd1 | 20 | 0,65 | 0,15 | 0,42 | 0,93 | 0 |

**Delta do RAFT INDEX por bloco** (5 rodadas cada):

| Bloco | Deltas | Duração do bloco |
|---|---|---|
| nenhuma leitura (1 s) | 0, 1, 2, 0, 1 | cerca de 1,05 s |
| 100 linearizáveis | 3, 1, 1, 2, 1 | 0,49–0,70 s |
| 100 serializáveis | 1, 1, 1, 1, 3 | 0,46–0,50 s |

CSVs: `resultados/2026-10-25_1310_e4_*.csv`.

## Análise: previsão × resultado × teoria

| # | Previsão | Resultado | Situação |
|---|---|---|---|
| 1 | Serializável mais rápida (talvez metade) | 0,65 ms × 1,82 ms: cerca de **1/3** do tempo | ✅ confirmada (diferença maior que a prevista) |
| 2 | Linearizável no isolado falha ou dá timeout | `context deadline exceeded` 5 de 5 | ✅ confirmada |
| 3 | Serializável no isolado responde o valor antigo | `ANTIGO` 5 de 5, enquanto a maioria já tinha `NOVO` | ✅ confirmada |
| 4 | Cada leitura linearizável sobe o RAFT INDEX em +1 | 100 leituras → delta de 1 a 3, **igual à linha de base** (healthcheck). Se cada leitura gravasse, o delta seria cerca de 100 | ❌ errada |

**Discussão**
1. **ReadIndex: leitura linearizável sem gravar no log (S3, P5).** A previsão 4 supunha que, para ordenar a leitura, o etcd a gravaria no log. O resultado mostra que não. O líder só registra o índice já comprometido (*read index*), confirma com um heartbeat que a maioria ainda o reconhece como líder, e o membro responde depois de aplicar até esse índice (ONGARO; OUSTERHOUT, 2014, §8). Isso **formaliza o achado exploratório A1**, agora com previsão e linha de base. O custo é uma ida ao líder (+1,2 ms), não uma escrita.
2. **O trade-off no lado minoritário (Q6, Q11).** No mesmo nó, no mesmo instante:
   - a leitura **linearizável recusou responder**, porque sem líder não há como provar que o dado está atualizado. É a escolha **C**;
   - a **serializável respondeu um valor desatualizado** (`ANTIGO`). É **disponível, mas não consistente**.
   O etcd deixa a escolha para o cliente, leitura a leitura, e o padrão é C. No Kubernetes, isso corresponde a leituras com `resourceVersion=""` (linearizáveis, padrão) × leituras de cache/`resourceVersion="0"` (a citar na S3, com fonte).
3. **pre-vote em ação.** Isolado, etcd1 ficou sem líder (`no leader`) por cerca de 20 s, mas o **termo não subiu** (3 antes, durante e depois). Sem pre-vote, ele teria incrementado o termo a cada election timeout e, ao voltar, forçaria uma eleição desnecessária no cluster. Com pre-vote, ele só se candidata se conseguir votos prévios de uma maioria (P3, S1; confirma o achado A7).
4. **A recuperação levou 7 s.** Depois de religado, etcd1 levou 7,05 s para enxergar `NOVO`, muito mais que a replicação normal (cerca de 6 ms, E3). Hipótese, **a verificar no E7**: o tempo é dominado pela reconexão dos canais rafthttp entre pares (novas tentativas com espera crescente) depois da troca de rede, e não pela transferência das 10 entradas que faltavam.

## Questões que este experimento sustenta
- **Q6:** linearizável × serializável, com evidência.
- **Q11:** C × A em nível de leitura.
- **Q10:** detecção de falta de líder.
- **S3:** ReadIndex, custo medido.
- **S1:** pre-vote.
- **Achado A1:** formalizado.
