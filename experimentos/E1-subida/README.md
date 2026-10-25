# E1 — Subida e topologia (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Cluster com 3 membros no ar; papéis de cada nó identificados.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: 2026-10-25 12:37 — respostas de David a um questionário de múltipla escolha; texto montado pelo Claude Code a partir das escolhas (ver `docs/uso-ia.md`)
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. Quantos membros aparecem no `member list`? Algum é *learner*?
> 2. Quantos líderes? Por que o Raft garante isso (um voto por termo + maioria)?
> 3. Termo e RAFT INDEX serão iguais nos 3? Em que termo o cluster recém-criado deve estar?
> 4. Dá para prever qual membro será o líder? (timeout aleatório)
> 5. O RAFT INDEX fica parado em repouso? (healthcheck a cada 5 s)
> O que esperamos observar e por quê (citar Raft/ZAB, quórum etc.):

1. **Líderes:** esperamos **exatamente 1 líder**, porque no Raft cada nó vota uma única vez por termo e só vence quem obtém a maioria (2 de 3); dois candidatos não conseguem ter maioria no mesmo termo.
2. **Termo e RAFT INDEX:** esperamos valores **iguais nos 3 membros**, porque o líder replica o log para todos e quem recebe uma mensagem de termo maior adota esse termo.
3. **Quem será o líder:** **não dá para prever**. O tempo de espera (election timeout) de cada nó é sorteado, vence quem "acorda" primeiro, e isso pode mudar a cada subida.
4. **RAFT INDEX em repouso:** esperamos que **fique parado**, porque o índice só deveria subir quando um cliente grava algo, e ninguém está gravando.

## Procedimento
Script reproduzível: [`executar.sh`](executar.sh) (`experimentos/E1-subida/executar.sh [N=5]`, da raiz).
1. Recria o cluster **do zero** 5 vezes (`down -v` + `up -d`). Em cada subida mede o tempo até os 3 membros ficarem saudáveis e registra o líder, o termo e o RAFT INDEX.
2. Na última subida, roda `validar.sh etcd` e registra `member list`, `endpoint status`, `endpoint health` e as redes/IPs/`mem_limit` de cada contêiner.
3. **RAFT INDEX em repouso:** 7 amostras, uma a cada 10 s, sem nenhum cliente escrevendo.
4. Diagrama de topologia: [`diagramas/topologia.mmd`](../../diagramas/topologia.mmd) (PNG em `diagramas/`).

> Execução de 25/10 às 12:58 **descartada**: um erro no script (caminho do compose no formato `/c/...`, que o Docker do Windows não entende) fez o `down`/`up` falharem em silêncio, e os contêineres antigos continuaram rodando (termo 3, índice cerca de 8.000). O erro foi corrigido com `caminho_host` e o experimento foi refeito às 13:00. Registrado no diário.

## Evidências
Executado em 25/10/2026, 13:00–13:02, depois do commit da previsão (12:37).

| Arquivo | O que mostra |
|---|---|
| `evidencias/2026-10-25_1300_subidas_do_zero.txt` | `endpoint status` de cada uma das 5 subidas (líder, termo 2, índice 11, banco de 20 kB, ou seja, cluster novo) |
| `evidencias/2026-10-25_1300_member_list.txt` | 3 membros `started`, nenhum *learner*, com IPs de pares (2380) e de clientes (2379) |
| `evidencias/2026-10-25_1300_endpoint_status.txt` | 1 líder (etcd2), termo 2 e RAFT INDEX 18 nos 3 |
| `evidencias/2026-10-25_1300_endpoint_health.txt` | os 3 saudáveis: `successfully committed proposal: took = 3,4–4,6 ms` |
| `evidencias/2026-10-25_1300_redes.txt` | redes e IPs de cada contêiner; `mem_limit` de 256 MB (membros) e 128 MB (cliente) |
| `evidencias/2026-10-25_1300_raft_index_repouso.txt` | RAFT INDEX em repouso: 22 → 60 em 62 s |

## Medições (5 repetições, R7)
CSV: `resultados/2026-10-25_1300_e1_subida_ate_saudavel.csv`. O tempo vai do `docker compose up -d` até `endpoint health` OK nos 3 membros, e inclui a criação dos contêineres.

| Medição | n | média (ms) | desvio padrão | mín | máx | falhas |
|---|---|---|---|---|---|---|
| subida do zero até saudável | 5 | 2924,40 | 823,80 | 2121 | 3899 | 0 |

| Subida | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Líder | etcd2 | etcd1 | etcd1 | etcd3 | etcd2 |
| Termo | 2 | 2 | 2 | 2 | 2 |
| RAFT INDEX inicial | 11 | 11 | 11 | 11 | 11 |

**RAFT INDEX em repouso** (amostras a cada cerca de 10 s): 22, 29, 36, 42, 48, 54, 60. São **+38 entradas em 62 s ≈ 0,61 entrada/s**, com o mesmo valor nos 3 membros em cada amostra.

## Análise: previsão × resultado × teoria

| # | Previsão | Resultado | Situação |
|---|---|---|---|
| 1 | Exatamente 1 líder | 1 líder em todas as 5 subidas e na validação | ✅ confirmada |
| 2 | Termo e RAFT INDEX iguais nos 3 | Iguais nos 3 em todas as amostras | ✅ confirmada |
| 3 | Líder imprevisível | etcd2, etcd1, etcd1, etcd3, etcd2: os 3 membros venceram pelo menos uma vez | ✅ confirmada |
| 4 | RAFT INDEX parado em repouso | **Sobe cerca de 0,6 entrada/s** sem nenhum cliente | ❌ errada |

**Discussão**
1. **Um líder só (Election Safety).** O resultado bate com a propriedade *Election Safety* do Raft (ONGARO; OUSTERHOUT, 2014, §5.2): cada nó vota uma vez por termo e é preciso maioria. Com N = 3, dois candidatos precisariam de 2 + 2 = 4 votos, o que é impossível.
2. **Líder aleatório.** O *election timeout* é sorteado (no etcd, entre 1× e 2× o `--election-timeout`, padrão 1000 ms). Vence quem expira primeiro. Ao contrário do algoritmo do Valentão (Bully), o identificador do nó não decide a eleição (relevante para S1). Com 5 subidas, a amostra é pequena para falar em distribuição uniforme; ela mostra só que **não é determinístico**.
3. **Termo 2, e não 1, num cluster novo.** O termo chega a 2 já na 1ª eleição. Hipótese, a confirmar na fonte: o etcd cria a configuração inicial (a entrada dos 3 membros) como entradas do termo 1, e a 1ª eleição abre o termo 2. O valor foi idêntico nas 5 subidas, então o efeito é determinístico.
4. **RAFT INDEX inicial = 11, sem nenhuma escrita de cliente.** O log já começa com entradas internas: configuração dos membros, entrada do novo líder, publicação dos atributos dos membros e versão do cluster. A composição exata das 11 não foi verificada.
5. **Por que a previsão 4 errou.** O `endpoint health` do etcd faz uma **proposta pelo Raft**, e a própria saída diz isso: `successfully committed proposal`. O compose roda esse healthcheck **a cada 5 s em cada um dos 3 membros**, o que dá 3 × 2 = **6 entradas a cada 10 s**, e foi exatamente o que se observou (+6 ou +7 por intervalo). O índice conta **tudo** o que passa pelo consenso, não só as escritas de clientes. Isso confirma o achado exploratório A1 e prepara o E2 (revisão × RAFT INDEX) e o E4.
6. **Tempo de subida.** 2,9 ± 0,8 s do `up` até os 3 saudáveis. O valor inclui criar os contêineres e as redes, e uma eleição com timeout de 1 a 2 s. A variação é coerente com o sorteio do timeout, mas o tempo do Docker não foi separado do tempo da eleição. A eleição isolada é medida no E5.

## Questões que este experimento sustenta
- **Q2:** papéis de líder e seguidor; nenhum *learner*.
- **Q3:** os 3 membros com a cópia completa; o mesmo índice nos 3.
- **Q5:** máquina de estados replicada com líder único.
- **Q8:** eleição com resultado aleatório.
- **Q9:** termo e índice como contadores lógicos.
- **S1:** timeout aleatório × Bully.
- **Seção 4:** topologia.
