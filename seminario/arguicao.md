# Roteiro de arguição (5 min; o professor escolhe quem responde)

Resposta curta (2–3 frases) + o experimento que prova. A resposta completa está em `relatorio/06-questoes-comuns.md` e `relatorio/07-questoes-especificas.md`. Cada um estuda tudo, mas o "dono" de cada bloco revisa a resposta.

## Questões comuns
| Q | Pergunta | Resposta curta | Prova | Dono |
|---|---|---|---|---|
| Q1 | Que problema resolve? | Guardar pouca informação crítica (configuração, líder, travas) de forma consistente mesmo com a falha de uma minoria. Esconde do cliente a replicação e a falha. | E3, E5 | D |
| Q2 | Arquitetura? | Cliente-servidor; 3 réplicas, 1 líder e 2 seguidores; rede interna para o Raft, rede de clientes. | Figura 1, E1 | D |
| Q3 | Como o cliente acha o dado? | Pela chave; todo membro tem a base inteira, sem particionamento nem DHT. No ZK, pelo caminho na árvore. | E1, E3 | D |
| Q4 | Como os nós se comunicam? | Cliente por gRPC (síncrono; *watch* por *stream*); entre pares, mensagens Raft por HTTP. Timeout para o cliente é indeterminado: a escrita pode ter acontecido. | E2 | D |
| Q5 | Modelo de replicação? | Máquina de estados replicada com líder único; só o líder escreve; confirma com a maioria. | E2 (103 KB ao líder) | D |
| Q6 | Consistência? | etcd linearizável por padrão; serializável opcional, pode ser antiga. ZK: leitura local, `sync` para a atual. | E4, E9-E4 | D |
| Q7 | Quórum? | Maioria 2 de 3, tolera 1 falha. Sem maioria, escrita e linearizável falham; serializável responde. | E5 (quadro) | S |
| Q8 | Como escolhe o líder? Bully/Anel? | Timeout sorteado, voto único por termo, maioria. Bully: maior ID; Anel: mensagem circulando; sem termos, podem dar dois líderes. | E1, E5, E8 | S |
| Q9 | Ordenação? | Termo (mandato), índice do log, revisão global (ordem total, tipo Lamport, não vetorial). ZK: zxid = época + contador. | E8, E2 | S |
| Q10 | Modelo de falhas? | Parada (*crash*), não bizantina. Detecção por *heartbeat* (100 ms) e timeout. 1 nó: mascarado; maioria: para. | E5, E6 | S |
| Q11 | C ou A na partição? | **C.** O lado minoritário recusou todas as escritas; a maioria seguiu. PACELC: PC/EC. ZK também CP. | E6, E9-E6 | S |
| Q12 | Como um nó recupera? | Pelo log se o líder ainda tem as entradas; por snapshot se o log foi compactado. ZK: DIFF/SNAP/TRUNC. Estado final idêntico. | E7, E9-E7 | S |
| Q13 | Problemas clássicos? | Consenso, ordem total, eleição, exclusão mútua (lock com lease). Bizantino: não tratado. | E8, E9-E8 | S |
| Q14 | Uso, limites, segurança? | Kubernetes; dados pequenos (1,5 MiB por requisição); um líder limita a escrita. Precisa de TLS e controle de acesso; o laboratório não tem. | E0, E3 | S |

## Questões específicas
| S | Pergunta | Resposta curta | Prova | Dono |
|---|---|---|---|---|
| S1 | O que o Raft acrescenta a Bully/Anel? Por que timeout aleatório? | Termos (recusa líder velho), voto único por termo com maioria, restrição de log. Timeout aleatório para não empatar votos. | E1, E5 | S |
| S2 | Por que 3 ou 5 e não 4? Learners? | 4 tolera a mesma 1 falha que 3, mas espera mais um voto. Mais membros = commit mais lento. Learner: recebe o log sem votar até se atualizar. | E5, E2 | S |
| S3 | Linearizável × serializável; ReadIndex; Kubernetes? | ReadIndex: pergunta ao líder o índice confirmado, confirma liderança com *heartbeat*, responde; não grava no log. K8s: `resourceVersion` vazio = leitura de quórum; `"0"` = cache. | E4 (100 leituras não mexem no índice) | D |
| S4 | Pausa longa com lease; fencing token? | O lease vence, outro pega a trava, o antigo acorda e grava por cima. Fencing token (revisão da chave) cresce a cada aquisição; o recurso recusa o menor. | E8 (113 recusado × 114) | S |

## Perguntas prováveis sobre os resultados
- **"Onde a previsão de vocês errou?"** E7: previmos menos de 1 s e deu cerca de 6,5 s, mas o tempo é de reconexão, não de cópia. E8: previmos 10 s no `elect` e deu 57 s, porque ele usa sessão de 60 s. E1: o RAFT INDEX não fica parado, por causa do healthcheck. E4: achávamos que a leitura linearizável gravava no log, e não grava.
- **"Por que o ZooKeeper elegeu mais rápido na queda e mais devagar na partição?"** Na queda a conexão TCP fecha e os seguidores percebem na hora; na partição ela não fecha e o ZK espera `syncLimit × tickTime` = 4 s, contra 1–2 s do etcd.
- **"Por que o `docker stop` foi tão rápido no etcd?"** Na parada ordenada o etcd transfere a liderança antes de sair: 9 ms. A eleição de verdade só aparece com `kill`.
- **"As previsões foram feitas antes?"** Sim, cada uma em commit anterior à execução. As de E5–E9 foram reescritas antes de rodar, para ficarem coerentes com a teoria e no formato do roteiro; está declarado na seção 11.
- **"O que o laboratório não mostra?"** Rede, disco e relógio reais; tudo roda num host só (seção 9).
