# 5. Experimentos

Cada experimento seguiu o mesmo ciclo: validação do cluster (`scripts/validar.sh`), previsão da dupla registrada em commit **antes** da execução, execução por script (`experimentos/EX/executar.sh`), evidência bruta salva com data e hora e análise. As medições de tempo têm no mínimo 5 repetições (R7). Os detalhes completos, com a tabela previsão × resultado de cada um, estão no `README.md` de cada pasta em `experimentos/`.

Placar das previsões: E1–E4 e E9-E3/E4 (David), 14 confirmadas, 5 erradas e 1 não observada; E5–E8 e E9-E5..E8 (Samuel), 12 confirmadas, 1 errada e 1 parcial.

## 5.1 E1 — Subida e topologia
**Objetivo:** cluster com 3 membros no ar e papéis identificados. **Procedimento:** 5 subidas do zero (`down -v` + `up -d`), `member list`, `endpoint status` e `endpoint health`.
**Resultado:** exatamente 1 líder em todas as subidas, escolhido ao acaso (etcd2, etcd1, etcd1, etcd3, etcd2); termo e RAFT INDEX iguais nos 3; saudável em 2,9 ± 0,8 s. A previsão de que o RAFT INDEX ficaria parado em repouso errou: ele sobe cerca de 0,6 entrada/s, porque o `endpoint health` do healthcheck do Compose é uma proposta pelo Raft.
**Evidência:** `experimentos/E1-subida/evidencias/`; Figura 1 (topologia).

## 5.2 E2 — Caminho de uma operação
**Objetivo:** mostrar quem recebe, decide, replica e responde. **Procedimento:** `put` num seguidor por endpoint único, `-w json`, métricas de bytes entre pares e RAFT INDEX nos 3.
**Resultado:** o seguidor **encaminha** ao líder (103 KB ao líder, 60 B ao outro seguidor), e o líder replica aos dois; a escrita é confirmada com 2 de 3 membros. O put via seguidor custou 8,25 ± 2,83 ms contra 6,91 ± 2,36 ms direto no líder (20 repetições). Revisão e RAFT INDEX são contadores diferentes (revisão 58 × índice 248). Achado: com só o líder vivo (`docker pause` nos outros dois) o cliente recebeu timeout, mas a escrita acabou confirmada ao despausar, ou seja, para o cliente um timeout é um resultado indeterminado.
**Evidência:** `experimentos/E2-caminho/evidencias/`; Figura 2 (`diagramas/sequencia-escrita.png`).

## 5.3 E3 — Replicação
**Objetivo:** escrever num membro, ler em outro e medir a propagação. **Procedimento:** 20 repetições de `put` no etcd1, `get` no etcd3 e *watch* no etcd2; latências; `check perf --load=s`.
**Resultado:** 20 de 20 leituras no outro membro viram o valor novo. *Watch* em 6,4 ± 1,3 ms; put 3,28 ms > get linearizável 1,46 ms > get serializável 0,76 ms. `check perf` passou (151 escritas/s), com no máximo 87 MiB por membro.
**Evidência:** `experimentos/E3-replicacao/evidencias/`; `resultados/2026-10-25_1308_e3_*.csv`.

## 5.4 E4 — Consistência
**Objetivo:** evidenciar o modelo de consistência. **Procedimento:** linearizável × serializável no mesmo seguidor (20×); RAFT INDEX antes e depois de 100 leituras; seguidor isolado da rede interna.
**Resultado:** serializável em 0,65 ms contra 1,82 ms da linearizável. 100 leituras linearizáveis não alteram o RAFT INDEX além da linha de base: o ReadIndex não grava no log (a previsão de que gravaria errou). Isolado, o seguidor falha na linearizável (`context deadline exceeded`, 5 de 5) e devolve `ANTIGO` na serializável (5 de 5) enquanto a maioria já tinha `NOVO`.
**Evidência:** `experimentos/E4-consistencia/evidencias/2026-10-25_1310_seguidor_isolado.txt`.

## 5.5 E5 — Falha e quórum
**Objetivo:** derrubar 1 e depois 2 membros. **Procedimento:** 5 quedas do líder com `docker kill` e 5 com `docker stop`; quadro com 3, 2 e 1 membros.
**Resultado:** novo líder em **1,46 ± 0,18 s** após `kill`, dentro do *election timeout* sorteado (1–2 s), com termo +1. Com `stop`, a troca levou 9,0 ± 1,7 ms, porque o etcd transfere a liderança antes de sair (não previsto). Com 2 membros tudo funciona; com 1, escrita e leitura linearizável falham e a serializável responde.

| Membros ativos | Escrita | Leitura linearizável | Leitura serializável |
|---|---|---|---|
| 3 | OK | OK | OK |
| 2 | OK | OK | OK |
| 1 | falha (`context deadline exceeded`) | falha | responde |

**Evidência:** `experimentos/E5-falha-quorum/evidencias/2026-10-26_2120_quadro_quorum.txt`; `resultados/2026-10-26_2118_e5_eleicao_kill.csv`.

## 5.6 E6 — Partição de rede
**Objetivo:** isolar o líder da rede interna, mantendo-o acessível ao cliente. **Procedimento:** 5 isolamentos com medição da eleição; linha do tempo dos dois lados.
**Resultado:** o lado majoritário elegeu novo líder em 0,94 ± 0,24 s (limite inferior, ver seção 9) com termo maior. O líder isolado deixou o cargo (`no leader`) já na primeira rodada; recusou as 6 escritas e todas as leituras linearizáveis; a leitura serializável devolveu `ANTIGO` enquanto a maioria lia `NOVO`. Depois de religar, os 3 membros ficaram com `NOVO`, sem divergência. Conclusão: o etcd escolhe **consistência** (PC/EC).
**Evidência:** `experimentos/E6-particao/evidencias/2026-10-26_2121_linha_do_tempo.txt`.

## 5.7 E7 — Recuperação
**Objetivo:** religar o membro e medir o tempo até o cluster voltar a ficar saudável. **Procedimento:** 5 ciclos isolar → 1000 escritas → religar; depois, `--snapshot-count=1000`, seguidor parado durante 10 000 escritas.
**Resultado:** o membro voltou como seguidor e com termo maior em 5 de 5, mas o tempo até alcançar o índice foi de 6,3–6,7 s em 4 de 5 repetições (50 ms em uma; média 5,2 ± 2,9 s). A cópia das entradas é imediata; o atraso está em restabelecer a comunicação após religar (causa não isolada, seção 9). A previsão de menos de 1 s errou. No teste de snapshot, o líder enviou um *merged snapshot* de 701 kB e o seguidor o restaurou; `endpoint hashkv` igual nos 3.
**Evidência:** `experimentos/E7-recuperacao/evidencias/2026-10-26_2124_recuperacao_por_snapshot.txt`; `resultados/2026-10-26_2122_e7_recuperacao.csv`.

## 5.8 E8 — Coordenação e ordem
**Objetivo:** mostrar o mecanismo de ordenação e resolver exclusão mútua e eleição com o etcd. **Procedimento:** escritas alternando chaves; `etcdctl lock` e `elect` com dois competidores em contêineres próprios; queda do detentor (5×); fencing token.
**Resultado:** a revisão cresce numa sequência única para todas as chaves; o termo só muda com eleição. Troca do `lock` em 7,9 ± 1,5 s (lease de 10 s). Troca do `elect` em **57,2 ± 0,3 s**: o `elect` não tem `--ttl` e usa a sessão padrão de 60 s (a previsão de cerca de 10 s errou). No `elect` venceu sempre a menor `create_revision`, isto é, quem pediu primeiro, e não o maior ID como no Bully. Com pausa longa do detentor, a gravação com fencing token foi recusada e a sem fencing sobrescreveu o trabalho do novo detentor.
**Evidência:** `experimentos/E8-coordenacao/evidencias/2026-10-26_2141_troca_detentor.txt`, `…_2148_fencing_token.txt`.

## 5.9 E9 — Ênfase D: ZooKeeper (E3–E8) e comparação ZAB × Raft
A bateria E3–E8 foi repetida num ensemble de 3 servidores ZooKeeper 3.9.6 com cliente kazoo.

| Sub | Resultado principal | Evidência |
|---|---|---|
| E3 | *watch* em 5,9 ± 0,8 ms (disparo único); `set` no seguidor 7,0 ms; leitura local 1,53 ms × `sync` + leitura 3,89 ms; nenhuma leitura antiga em 20 | `E9-zookeeper/E3-replicacao/` |
| E4 | servidor isolado ainda serve leitura local antiga por cerca de 3,6 s e depois para de atender qualquer cliente; o `sync` falha em vez de devolver valor antigo | `E9-zookeeper/E4-consistencia/` |
| E5 | eleição em **0,38 ± 0,09 s** após `kill` (a conexão fechada avisa os seguidores); 0,70 s após `stop`; época +1 em 10 de 10; sem maioria, o servidor fica sem serviço | `E9-zookeeper/E5-falha-quorum/` |
| E6 | eleição em **3,6 ± 0,3 s** na partição (`syncLimit × tickTime` = 4 s); o líder isolado faz `Shutting down`; o cliente com a lista dos 3 migra em 3 ms | `E9-zookeeper/E6-particao/` |
| E7 | sincronização por DIFF em 6 de 6, em 2,5 ± 0,7 s (200 transações) | `E9-zookeeper/E7-recuperacao/` |
| E8 | trava e eleição com znodes efêmeros e sequenciais trocam em 7,9 s (sessão de 10 s); a época faz o papel do termo | `E9-zookeeper/E8-coordenacao/` |

**Comparação ZAB × Raft.** Os dois garantem um líder por mandato (época ou termo), escrita confirmada pela maioria e consistência sob partição. As diferenças medidas são de projeto: o etcd lê de forma linearizável por padrão e detecta falhas só por tempo, com eleição em 1–2 s com ou sem partição; o ZooKeeper lê da cópia local por padrão (mais rápido, com janela de valor antigo, corrigida com `sync`) e elege em 0,4 s quando a conexão fecha, mas leva 3,6 s numa partição. O quadro completo está em `experimentos/E9-zookeeper/comparacao.md`.
