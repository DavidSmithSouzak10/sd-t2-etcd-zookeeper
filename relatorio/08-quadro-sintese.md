# 8. Quadro-síntese (modelo obrigatório do roteiro §10)

Coluna ZooKeeper acrescentada por causa da Ênfase D. Toda célula referencia a evidência.

| Aspecto | etcd | ZooKeeper | Evidência |
|---|---|---|---|
| Estilo arquitetural e papéis | cliente-servidor; grupo de 3 réplicas com 1 líder e 2 seguidores; *watch* orientado a eventos | idem (leader, 2 followers) | E1; E2; Figura 1 |
| Como o dado ou serviço é localizado | por chave, num espaço plano; cada membro tem a base inteira; qualquer membro atende | por caminho na árvore de znodes; cada servidor tem a árvore inteira | E1; E3; E9-E3 |
| Modelo de replicação (N réplicas; quem aceita escritas) | máquina de estados replicada; N = 3; só o líder escreve, seguidores encaminham | idem, por difusão atômica (ZAB) | E2; E9-E3 |
| Modelo de consistência observado | linearizável por padrão (ReadIndex); serializável opcional, pode devolver valor antigo | escritas linearizáveis; leitura local por padrão (pode ser antiga); `sync` para leitura atual | E4; E9-E4 |
| Quórum (N, R, W ou maioria) e falhas toleradas | maioria 2 de 3; tolera 1 falha; sem maioria só a leitura serializável responde | maioria 2 de 3; tolera 1; sem maioria não atende ninguém | E5; E9-E5 |
| Líder ou coordenador e forma de escolha | Raft: timeout sorteado (1–2 s), voto único por termo; 1,46 ± 0,18 s | FastLeaderElection (maior zxid, depois maior ID); 0,38 ± 0,09 s após queda abrupta | E5; E9-E5 |
| Mecanismo de ordenação ou versionamento | termo (mandato), índice do log, revisão global (ordem total) | zxid = época + contador | E8; E2; E9-E8 |
| Comportamento sob partição (C ou A) | C: minoria sem líder recusa escrita e leitura linearizável; maioria elege em 0,94 s (PC/EC) | C: minoria para de atender após cerca de 4 s; maioria elege em 3,6 s | E6; E9-E6 |
| Mecanismo de recuperação | entradas faltantes pelo log; snapshot se o log foi compactado; estado final idêntico (hash) | DIFF, SNAP ou TRUNC; DIFF observado em 6 de 6 | E7; E9-E7 |
| Problemas clássicos presentes e como são tratados | consenso e ordem total (Raft); eleição e exclusão mútua (`elect`, `lock` com lease); fencing token pela revisão; sem tolerância bizantina | consenso e ordem total (ZAB); trava e eleição com znodes efêmeros e sequenciais e sessão | E8; E9-E8 |
