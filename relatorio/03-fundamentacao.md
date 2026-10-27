# 3. Fundamentação

## 3.1 O problema: coordenação e máquina de estados replicada
Sistemas distribuídos precisam de um lugar confiável para guardar pouca informação crítica: configuração, quem é o líder de um serviço, quem detém uma trava, quais nós estão vivos. Guardar isso num único servidor cria um ponto único de falha; copiar em vários servidores sem coordenação cria versões divergentes.

A solução usada pelo etcd e pelo ZooKeeper é a **máquina de estados replicada**: cada réplica começa no mesmo estado e aplica a mesma sequência de comandos, na mesma ordem. Se a sequência é igual, o estado é igual. O problema se reduz a fazer as réplicas concordarem sobre essa sequência mesmo com falhas, isto é, a um problema de **consenso**. O etcd resolve com o Raft e o ZooKeeper com o ZAB. Os dois toleram falhas por parada (*crash*) de uma minoria das réplicas, mas não falhas bizantinas.

## 3.2 Raft (artigo seminal: ONGARO; OUSTERHOUT, 2014)
O Raft divide o consenso em três partes:
- **Eleição de líder.** Cada nó é seguidor, candidato ou líder. O tempo é dividido em **termos** numerados; cada termo tem no máximo um líder. O líder envia *heartbeats* periódicos; um seguidor que fica um *election timeout* sem ouvi-lo vira candidato, incrementa o termo e pede votos. Cada nó vota uma vez por termo, e vence quem obtém a maioria. O timeout é **sorteado** dentro de um intervalo para que raramente dois nós se candidatem ao mesmo tempo (o que dividiria os votos).
- **Replicação do log.** Só o líder anexa entradas ao log. Ele as envia aos seguidores (AppendEntries) e considera uma entrada **confirmada** (*committed*) quando a maioria a gravou. Entradas confirmadas são aplicadas à máquina de estados em ordem.
- **Segurança.** Um candidato só recebe o voto de quem tem log igual ou mais antigo que o dele (**restrição de log**). Assim, todo líder eleito já contém todas as entradas confirmadas, e nenhuma entrada confirmada é perdida.

Duas extensões ligadas por padrão no etcd 3.5 aparecem nos experimentos: o **pre-vote**, em que um nó só incrementa o termo se uma maioria indicar que votaria nele (evita que um nó isolado force eleições ao voltar), e o **check quorum**, em que o líder deixa o cargo se não ouvir a maioria dentro de um *election timeout*.

## 3.3 etcd: arquitetura e modelo de dados
O etcd é um armazenamento chave-valor replicado pelo Raft, usado como banco de estado do Kubernetes. Cada membro guarda a base inteira; não há particionamento. Clientes falam com qualquer membro por gRPC; os membros falam entre si por HTTP na porta de pares (Figura 1, seção 4; caminho de uma escrita na Figura 2, E2).
- **MVCC e revisões.** Toda alteração gera uma nova **revisão** global; cada chave guarda `create_revision`, `mod_revision` e `version`. A revisão ordena todas as escritas e serve de base para *watch* (notificações a partir de uma revisão) e para transações condicionais.
- **Leases.** Uma chave pode ser presa a um lease com prazo (TTL), renovado pelo cliente; se ele para de renovar, o lease vence e a chave é apagada. Travas (`lock`) e eleições (`elect`) de aplicação são construídas sobre leases e sobre a ordem das revisões.
- **Leituras.** A leitura padrão é **linearizável**: o membro obtém do líder o índice já confirmado (*ReadIndex*), o líder confirma com um *heartbeat* que ainda é líder, e o membro responde depois de aplicar até esse índice, sem gravar nada no log. A leitura **serializável** responde com a cópia local, sem consultar ninguém.
- **Snapshots e learners.** A cada `--snapshot-count` entradas o membro grava um snapshot e descarta o log antigo; um membro muito atrasado recebe o snapshot inteiro. *Learners* são membros que recebem o log sem votar, usados para adicionar um membro sem afetar o quórum enquanto ele se atualiza.

## 3.4 ZooKeeper e ZAB (HUNT et al., 2010; JUNQUEIRA; REED; SERAFINI, 2011)
O ZooKeeper organiza os dados numa árvore de **znodes** (caminhos como `/e9/trava`). Um znode **efêmero** existe enquanto a **sessão** do cliente que o criou existir; um znode **sequencial** recebe um número crescente no nome. Com esses dois tipos se constroem as receitas de trava e de eleição: cada cliente cria um znode efêmero e sequencial, e o de menor número é o dono; cada um observa só o anterior, o que evita que todos acordem ao mesmo tempo.

As escritas passam pelo líder e são difundidas pelo **ZAB** (*ZooKeeper Atomic Broadcast*), em ordem total. Cada transação recebe um **zxid** de 64 bits: os 32 bits altos são a **época** (número do mandato do líder) e os 32 baixos um contador que recomeça a cada época. O ZAB opera em fases: descoberta e sincronização (o novo líder estabelece a época e alinha o histórico dos seguidores, por DIFF, SNAP ou TRUNC) e difusão (propostas confirmadas pela maioria). As **leituras** são servidas pela cópia local do servidor ao qual o cliente está ligado, e podem estar atrasadas; o cliente que precisa do valor mais recente chama `sync` antes de ler. O ZooKeeper garante escritas linearizáveis e ordem FIFO das operações de cada cliente.

## 3.5 Conceitos da disciplina usados nos experimentos
- **Quórum.** Com N réplicas, decisões exigem a maioria (⌊N/2⌋ + 1); duas maiorias sempre se cruzam, o que impede decisões conflitantes. Com N = 3, a maioria é 2 e o sistema tolera f = 1 falha.
- **CAP e PACELC.** Sob partição (P), um sistema escolhe entre consistência (C) e disponibilidade (A) (GILBERT; LYNCH, 2002). O PACELC acrescenta que, sem partição (E), a escolha é entre latência (L) e consistência (C) (ABADI, 2012).
- **Bully e Anel.** Algoritmos clássicos de eleição em que vence o processo de maior identificador (Bully) ou em que uma mensagem percorre um anel lógico. Não usam termos, e uma partição pode produzir dois líderes.
- **Relógios lógicos.** O relógio de Lamport (LAMPORT, 1978) atribui números crescentes a eventos de forma consistente com a relação "aconteceu antes"; termos, épocas e revisões são contadores desse tipo.
- **Multicast de ordem total.** Todas as réplicas entregam as mensagens na mesma ordem; é o que o log do Raft e a difusão do ZAB oferecem.
- **Estado global.** O algoritmo de Chandy-Lamport (CHANDY; LAMPORT, 1985) obtém um corte consistente com marcadores; numa máquina de estados replicada, o estado em qualquer índice confirmado já é consistente, e o snapshot é a cópia desse estado.
