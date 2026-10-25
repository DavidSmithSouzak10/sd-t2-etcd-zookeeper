# E2 — Caminho de uma operação (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Percurso de uma escrita e de uma leitura: quem recebe, quem decide, quem replica, quem responde.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: 2026-10-25 12:45 — respostas de David a um questionário de múltipla escolha; texto montado pelo Claude Code a partir das escolhas (ver `docs/uso-ia.md`)
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. Um `put` enviado a um **seguidor** é atendido por ele ou encaminhado? A quem?
> 2. Quantas confirmações o líder precisa antes de responder ao cliente com 3 membros?
> 3. Depois de 1 `put`, quanto sobem a `revision` (MVCC) e o RAFT INDEX? São a mesma coisa?
> 4. O `raft_term` da resposta muda com uma escrita?
> O que esperamos observar e por quê (citar Raft/ZAB, quórum etc.):

1. **Put num seguidor:** esperamos que **o próprio seguidor grave** a escrita localmente e depois avise os outros, já que todos têm a cópia completa dos dados.
2. **Confirmação:** esperamos que o cliente receba "OK" quando **a maioria (2 de 3)** tiver gravado: o líder e mais 1 seguidor. Com maioria, qualquer maioria futura terá ao menos um nó com o dado.
3. **Contadores:** depois de 1 `put`, esperamos que **revisão e RAFT INDEX subam +1 e tenham o mesmo valor**, porque seriam o mesmo contador com nomes diferentes.
4. **Termo:** esperamos que **o termo não mude** com uma escrita, porque ele só muda quando há uma nova eleição.

## Procedimento
Script reproduzível: [`executar.sh`](executar.sh) (da raiz). Diagrama de sequência: [`diagramas/sequencia-escrita.mmd`](../../diagramas/sequencia-escrita.mmd).
1. Descobre o líder (L) e escolhe um seguidor (S) como **endpoint único**.
2. Faz `put` em S com `-w json` e registra `endpoint status` dos 3 antes e depois; em seguida, `get -w json` no outro seguidor (F).
3. Faz 5 `put` seguidos em S, registrando revisão, RAFT INDEX e termo antes e depois de cada um.
4. **Quem envia bytes para quem:** lê a métrica `etcd_network_peer_sent_bytes_total` dos 3 membros antes e depois de um `put` de 100 KiB em S.
5. **Quantas confirmações:**
   - pausa F (`docker pause`) e faz `put` no líder: restam 2 de 3;
   - pausa também S e faz `put` de novo: só o líder;
   - despausa os dois.
6. Mede a latência do put via seguidor × direto no líder (20 repetições cada, `scripts/latencia.sh`).

> Uma 1ª execução às 13:04 foi **descartada e refeita às 13:05**. Os trechos 3 e 4 tinham erros de script: um erro de sintaxe no Python e, no trecho 4, o `etcdctl` rodava dentro de um contêiner pausado. Os dados dos trechos válidos daquela execução (encaminhamento: 103 KB de etcd1 para o líder) foram iguais aos da execução final.

## Evidências
Executado em 25/10/2026, 13:05–13:06, depois do commit da previsão (12:45).

| Arquivo | O que mostra |
|---|---|
| `evidencias/2026-10-25_1305_put_em_seguidor.txt` | put em etcd1 (seguidor): resposta `revision 58, raft_term 2`; RAFT INDEX 247 → 248 **nos 3**; `get` em etcd3 já mostra o valor (`mod_revision 58`) |
| `evidencias/2026-10-25_1305_revisao_x_indice.txt` | 5 puts: a revisão sobe **exatamente +1** por put (58 → 63); o RAFT INDEX sobe de +1 a +3; o termo fica em 2 |
| `evidencias/2026-10-25_1305_metricas_encaminhamento.txt` | put de 100 KiB em etcd1: **etcd1 → etcd2 (líder) 103.273 B**; **etcd2 → etcd1 103.268 B** e **etcd2 → etcd3 103.268 B**; etcd1 → etcd3 só 60 B |
| `evidencias/2026-10-25_1305_confirmacao_maioria.txt` | 2 de 3 vivos: put `OK`; só o líder: `etcdserver: request timed out` (exit 1); depois de despausar, o valor final é `so_o_lider` |
| `evidencias/2026-10-25_1306_logs_raft_pausa.txt` | logs do Raft: *check quorum*, *pre-vote*, nova eleição no termo 3 (líder etcd3) |
| `evidencias/2026-10-25_1305_latencia_seguidor_x_lider.txt` | latência via seguidor × líder |
| `evidencias/2026-10-25_1306_validacao_final.txt` | cluster saudável no fim |

## Medições (20 repetições, R7)
CSVs: `resultados/2026-10-25_1305_e2_put_seguidor_etcd1.csv`, `resultados/2026-10-25_1306_e2_put_lider_etcd3.csv`.

| Medição | n | média (ms) | desvio padrão | mín | máx | falhas |
|---|---|---|---|---|---|---|
| put via seguidor (etcd1) | 20 | 8,25 | 2,83 | 6,12 | 17,89 | 0 |
| put direto no líder (etcd3) | 20 | 6,91 | 2,36 | 5,53 | 15,68 | 0 |

## Análise: previsão × resultado × teoria

| # | Previsão | Resultado | Situação |
|---|---|---|---|
| 1 | O seguidor grava ele mesmo e avisa os outros | O seguidor **encaminha ao líder**: enviou 103 KB ao líder e só 60 B ao outro seguidor. Quem distribui o dado é o líder (103 KB para cada seguidor) | ❌ errada |
| 2 | Confirmação com a maioria (2 de 3) | Com 2 de 3 vivos o put deu OK; com só o líder, timeout | ✅ confirmada |
| 3 | Revisão e RAFT INDEX sobem +1 e têm o mesmo valor | São **contadores diferentes**: revisão 58 contra índice 248. A revisão sobe exatamente +1 por put; o índice sobe +1 a +3, porque o log também recebe as entradas do healthcheck (E1) | ❌ errada |
| 4 | O termo não muda com escritas | Termo 2 em todos os puts; ele só mudou (2 → 3) quando houve eleição, no trecho 5 | ✅ confirmada |

**Discussão**
1. **Líder único (Q5).** No Raft só o líder anexa entradas ao log (ONGARO; OUSTERHOUT, 2014, §5.3). A métrica de bytes mostra o caminho completo do diagrama de sequência: cliente → seguidor → **líder** → AppendEntries para os 2 seguidores. O seguidor não replica para o outro seguidor; os 60 B são só heartbeat.
2. **Dois contadores (Q9).**
   - A **revisão** é o relógio lógico do *banco* (MVCC): sobe só quando dados mudam, e cada chave guarda a `create_revision` e a `mod_revision`.
   - O **RAFT INDEX** é a posição no *log de consenso*: conta tudo o que passa pelo Raft, inclusive operações internas como o `endpoint health`.
   - Por isso a revisão é a escolhida como *fencing token* (S4).
3. **Maioria, e não todos (Q7).** Com 2 de 3 a escrita foi confirmada, porque a maioria de 3 é 2. Esperar todos faria um único nó lento travar o cluster.
4. **Achado: timeout não significa "não gravou".**
   - Com só o líder, o cliente recebeu `request timed out`, mas depois de despausar, o valor gravado era `so_o_lider`. Os logs mostram os 3 membros no **mesmo índice 263, termo 2** antes da nova eleição, e o novo líder (etcd3, termo 3) confirmou essa entrada.
   - **Hipótese consistente com os logs:** o `docker pause` congela o processo, mas não a rede do kernel. As mensagens AppendEntries enviadas pelo líder ficaram no buffer TCP dos seguidores congelados e foram processadas ao despausar.
   - **Consequência prática:** para o cliente, um timeout é um resultado **indeterminado**. A escrita pode ou não ter acontecido, e repetir uma operação que não é idempotente exige cuidado.
   - **Diferença em relação ao E6:** isso distingue o `docker pause` (congelamento) de uma falha de rede real (`docker network disconnect`).
5. **check quorum e pre-vote estão ligados no etcd 3.5 (P3, S1).** Os logs mostram dois mecanismos:
   - o líder sem maioria **deixou o posto sozinho** (`stepped down to follower since quorum is not active`);
   - os seguidores **ignoraram** o pre-vote dele enquanto ainda achavam que havia líder (`lease is not expired`).
   - Os dois evitam eleições desnecessárias e líderes "fantasmas"; são aprofundados no E6.
6. **Custo do encaminhamento.** Via seguidor, o put levou 1,3 ms a mais em média (8,25 contra 6,91 ms), o que é coerente com o salto extra seguidor → líder. Mas os desvios (2,4 a 2,8 ms) se sobrepõem, então a diferença é pequena diante da variação. O líder mudou de etcd2 para etcd3 entre os trechos 5 e 6.

## Questões que este experimento sustenta
- **Q2, Q5:** líder único; seguidor encaminha.
- **Q4:** gRPC entre cliente e membro, rafthttp entre pares.
- **Q7:** maioria de 2 de 3.
- **Q9:** revisão × índice × termo.
- **Q10:** check quorum.
- **S1:** pre-vote.
- **S4:** revisão como *fencing token*.
