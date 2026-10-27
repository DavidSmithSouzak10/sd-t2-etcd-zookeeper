# 6. Questões comuns (Q1–Q14)

> Formato fixo (conferido por `scripts/revisar.py`): cada questão tem **Resposta** e **Evidência** (arquivo ou experimento).

### Q1 — Que problema o sistema resolve? Quais transparências oferece?
**Resposta:** O etcd guarda pouca informação crítica (configuração, descoberta de serviços, travas, eleição de líder) de forma consistente e disponível mesmo com a falha de uma minoria das réplicas. Para isso replica um log de comandos por consenso (Raft), formando uma máquina de estados replicada. Transparências: **replicação** (o cliente vê um único armazenamento, mas há 3 cópias idênticas), **falha** (a queda de 1 membro é mascarada: o cluster elege outro líder e continua), **localização** (qualquer membro atende; com a lista de endpoints, o cliente troca de membro sozinho), **acesso** (a mesma API em qualquer membro) e **concorrência** (as escritas são serializadas pelo líder; transações e travas resolvem disputas).
**Evidência:** E3 (20 de 20 leituras corretas em outro membro); E5 (escritas continuam com 2 de 3).

### Q2 — Arquitetura: estilo, componentes, papéis (diagrama próprio).
**Resposta:** Cliente-servidor, em que o "servidor" é um grupo de 3 réplicas com um **líder** e dois **seguidores** (nenhum *learner*). O líder é o único que anexa entradas ao log; os seguidores replicam e encaminham ao líder as escritas que recebem. Há duas redes: a interna, só para o tráfego Raft entre pares (porta 2380), e a de clientes (porta 2379). O *watch* acrescenta um componente orientado a eventos (notificação por *push*). O ZooKeeper tem a mesma estrutura (líder, seguidores, rede de quórum 2888 e eleição 3888).
**Evidência:** Figura 1 (`diagramas/topologia.png`); Figura 2 (`diagramas/sequencia-escrita.png`); E1 (`member list`, `endpoint status`); E2 (encaminhamento ao líder).

### Q3 — Como um cliente localiza um dado ou serviço?
**Resposta:** Não há particionamento nem cálculo de posição (nada de *hash* ou DHT): cada membro guarda a base inteira, e o dado é localizado pela **chave** num espaço plano ordenado (buscas por prefixo e por intervalo). O cliente pode falar com qualquer membro, a partir de uma lista de endpoints configurada. Para o próprio uso como serviço de nomes, o etcd funciona como um **diretório central replicado**: aplicações registram endereços em chaves e outras os consultam ou observam com *watch*. No ZooKeeper a resolução é **hierárquica**, por caminho na árvore de znodes.
**Evidência:** E1 (RAFT INDEX igual nos 3 membros); E3 (valor escrito no etcd1 lido no etcd3).

### Q4 — Como os nós se comunicam? Protocolo, síncrono/assíncrono, semântica de entrega.
**Resposta:** Cliente ↔ membro: gRPC sobre HTTP/2, com mensagens Protocol Buffers, requisição e resposta **síncronas**; o *watch* é um *stream* assíncrono em que o servidor empurra eventos. Entre pares: mensagens Raft (AppendEntries, votos, *heartbeats*) por HTTP (rafthttp), de forma **assíncrona**. Semântica de entrega: cada entrada confirmada é aplicada **exatamente uma vez**, na ordem do log, em todas as réplicas; para o cliente, porém, um timeout é **indeterminado**, porque a escrita pode ter sido confirmada mesmo sem resposta. Se o cliente repete, a semântica efetiva vira "ao menos uma vez", e operações não idempotentes precisam de cuidado (por exemplo, transação condicionada à revisão). O ZooKeeper usa um protocolo próprio sobre TCP, com ordem FIFO por sessão.
**Evidência:** E2 (`2026-10-25_1305_metricas_encaminhamento.txt`; timeout com escrita confirmada em `2026-10-25_1306_logs_raft_pausa.txt`); E3 (*watch* em 6,4 ms).

### Q5 — Modelo de replicação; quantas réplicas; quem aceita escritas.
**Resposta:** Máquina de estados replicada com **líder único**: 3 réplicas completas; só o líder aceita escritas (um seguidor que recebe uma escrita a encaminha ao líder), e cada escrita é confirmada quando a maioria (2 de 3) a grava. O ZooKeeper segue o mesmo modelo (líder + difusão atômica ZAB).
**Evidência:** E2 (103 KB do seguidor para o líder, 60 B para o outro seguidor; escrita confirmada com 2 de 3); E9-E3.

### Q6 — Modelo de consistência (demonstrar com experimento).
**Resposta:** etcd: **linearizável** por padrão, para escritas e leituras. A leitura padrão usa ReadIndex e, sem líder alcançável, falha em vez de devolver valor antigo. A leitura **serializável** (`--consistency=s`) é opcional e pode devolver valor antigo. ZooKeeper: escritas linearizáveis, mas leituras **locais** por padrão, com garantia de ordem por cliente (consistência sequencial); a leitura atual exige `sync`.
**Evidência:** E3 (20 de 20 leituras com o valor novo); E4 (no seguidor isolado, linearizável `context deadline exceeded` 5 de 5 e serializável `ANTIGO` 5 de 5); E9-E4 (servidor isolado serve leitura local antiga por cerca de 3,6 s); E6 (lado majoritário lê `NOVO`, minoritário serializável lê `ANTIGO`).

### Q7 — Quórum: N, R, W ou maioria; falhas toleradas; perder o quórum.
**Resposta:** Não há R e W configuráveis: toda escrita e toda leitura linearizável exigem a **maioria** (N = 3, maioria = 2). Com isso, duas maiorias sempre se cruzam (2 + 2 > 3, o equivalente a R + W > N), e o cluster tolera f = 1 falha (N = 2f + 1). Perdendo o quórum, escrita e leitura linearizável falham; só a leitura serializável responde. No ZooKeeper, sem quórum o servidor para de atender completamente.
**Evidência:** E5 (`2026-10-26_2120_quadro_quorum.txt`); E2 (`2026-10-25_1305_confirmacao_maioria.txt`); E9-E5 (`2026-10-26_2149_quadro_quorum.txt`).

### Q8 — Líder: como é escolhido; comparar com Bully e Anel.
**Resposta:** Pelo Raft: um seguidor que fica um *election timeout* (1–2 s, sorteado) sem *heartbeat* se candidata num termo novo; cada nó vota uma vez por termo e só em candidatos com log tão atualizado quanto o seu; vence quem tem a maioria. O resultado é imprevisível (qualquer membro pode vencer). No **Bully** vence sempre o maior identificador e no **Anel** uma mensagem de eleição percorre os processos; nenhum dos dois tem termos nem exige maioria, então uma partição pode gerar dois líderes. No ZooKeeper, a eleição (FastLeaderElection) prefere o servidor com o histórico mais novo (maior zxid) e, em empate, o maior ID.
**Evidência:** E1 (líder diferente a cada subida); E5 (eleição em 1,46 ± 0,18 s, termo +1); E8 (`elect` vence a menor `create_revision`); E9-E5 (0,38 ± 0,09 s, época +1).

### Q9 — Ordenação de eventos/versões; relação com Lamport, vetoriais, multicast ordenado.
**Resposta:** O etcd usa três contadores: o **termo** (época de liderança; só muda com eleição), o **índice** do log (posição de cada entrada no consenso) e a **revisão** (contador global do banco; sobe a cada escrita, em ordem total para todas as chaves). A revisão funciona como um relógio de Lamport único, mantido pelo líder: ordena tudo, mas não registra concorrência, como faria um relógio vetorial, porque o Raft serializa as escritas. O log replicado é um **multicast de ordem total**: todos aplicam as mesmas entradas na mesma ordem. No ZooKeeper o zxid junta época e contador num só número.
**Evidência:** E8 (`2026-10-26_2141_relogios_logicos.txt`: revisões 58–63 alternando chaves); E2 (revisão 58 × índice 248); E9-E8 (`2026-10-26_2139_epoca_x_termo.txt`).

### Q10 — Modelo de falhas; detecção; falha de 1 nó × da maioria.
**Resposta:** Falhas por parada (*crash*) com recuperação; mensagens podem se perder ou atrasar; não há tolerância a falhas bizantinas. Detecção por *heartbeat* e timeout: o líder envia *heartbeats* a cada 100 ms; sem eles por um *election timeout*, os seguidores elegem outro; com *check quorum*, o líder que não ouve a maioria deixa o cargo. Falha de 1 nó: mascarada (nova eleição em 1–2 s, se era o líder). Falha da maioria: o cluster para de aceitar escritas e leituras linearizáveis.
**Evidência:** E5 (eleição após `kill`; quadro com 1 membro: `etcdserver: no leader`); E6 (líder isolado sem líder já na 1ª rodada); E9-E6 (detecção do ZooKeeper em cerca de 4 s, `syncLimit × tickTime`).

### Q11 — Partição: consistência ou disponibilidade? (CAP, PACELC; sustentar com E6).
**Resposta:** **Consistência.** No E6, o lado majoritário elegeu outro líder e continuou atendendo; o lado minoritário (o antigo líder) recusou todas as escritas e leituras linearizáveis, e nenhuma versão divergente surgiu. A única resposta do lado minoritário foi a leitura serializável, com o valor antigo, que o cliente precisa pedir explicitamente. Pelo PACELC, o etcd é PC/EC: sem partição, também paga latência pela consistência (leitura linearizável 1,82 ms × serializável 0,65 ms). O ZooKeeper também é CP, e ainda mais restritivo: o isolado para de responder até leituras.
**Evidência:** E6 (`2026-10-26_2121_linha_do_tempo.txt`); E4 (latências); E9-E6 (`2026-10-26_2132_linha_do_tempo_so_lider.txt`).

### Q12 — Recuperação de estado: log, snapshot; relação com estado global.
**Resposta:** **Incremental** quando o líder ainda tem as entradas que faltam: ele envia só essas entradas. **Completa** (snapshot) quando o log já foi compactado: o líder envia o estado inteiro. No ZooKeeper o equivalente é DIFF (incremental), SNAP (completo) ou TRUNC (descartar transações não confirmadas). Relação com estado global: numa máquina de estados replicada, o estado em qualquer índice confirmado já é um corte consistente, porque todos aplicam a mesma sequência; por isso o snapshot não precisa de marcadores como no algoritmo de Chandy-Lamport.
**Evidência:** E7 (1005 entradas recuperadas pelo log; snapshot de 701 kB, `restored snapshot`; `endpoint hashkv` igual nos 3); E9-E7 (DIFF em 6 de 6).

### Q13 — Problemas clássicos presentes e como são resolvidos/evitados.
**Resposta:** **Consenso** e **multicast de ordem total**: resolvidos pelo Raft (log replicado) e pelo ZAB. **Eleição de líder**: interna (Raft, com termos e maioria) e oferecida às aplicações (`etcdctl elect`; receita de eleição do ZooKeeper). **Exclusão mútua**: `etcdctl lock` com lease, e receita de trava com znodes efêmeros e sequenciais; a trava se libera sozinha quando o detentor morre (lease ou sessão expira). **Generais bizantinos**: não tratado, porque o modelo assume falhas por parada. Limite conhecido: trava com lease não protege contra detentor pausado; é preciso fencing token (S4).
**Evidência:** E8 (troca do `lock` em 7,9 s; fencing); E9-E8 (troca da trava em 7,9 s).

### Q14 — Uso na prática, limitações, cuidados de segurança.
**Resposta:** **Uso:** o etcd é o banco de estado do Kubernetes (todos os objetos do cluster) e é usado para descoberta de serviços e configuração; o ZooKeeper coordena sistemas como HBase, Hadoop e, nas versões anteriores ao KRaft, o Kafka. **Limitações:** guarda pouco dado (requisição de até 1,5 MiB no etcd e cerca de 1 MB no ZooKeeper); a vazão de escrita é limitada por um único líder e pelo fsync; a latência cresce com a distância entre membros; sem maioria, o sistema para. **Segurança:** usar TLS mútuo entre membros e com clientes, autenticação e controle de acesso (RBAC no etcd, ACLs no ZooKeeper), e restringir a rede de pares. O laboratório usa texto plano sem autenticação (seção 9).
**Evidência:** E0 (1,4 MiB aceito e 1,6 MiB recusado no etcd com `request is too large`; ZooKeeper aceita 900 KB e derruba a conexão com 1,1 MB); E3 (`check perf`: 151 escritas/s).
