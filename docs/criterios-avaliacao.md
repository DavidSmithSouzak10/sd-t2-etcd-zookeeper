# Critérios de avaliação: T5 (etcd) com Ênfase D (ZooKeeper)

Lista verificável derivada do roteiro oficial (PDF "Roteiro Trabalho M2", Prof. Ramices, 2º sem/2026).
Cada critério tem um **ID**, a **origem no PDF** e **como verificar**.

**Como usar**
- Revisem esta lista juntos **toda semana** e antes da entrega.
- Atualizem a coluna *Status*:
  - ⬜ pendente
  - 🟨 em andamento
  - ✅ cumprido (com evidência)
  - ❌ bloqueado
  - ➖ não se aplica (com justificativa)
- Os itens marcados 🤖 são conferidos automaticamente por `python scripts/revisar.py`.
- Os demais são revisão humana.

> **Regra de equidade (PDF §2.1, quadro azul):** onde o sistema **não tem** um mecanismo, a resposta esperada é **demonstrar e justificar a ausência**. Isso vale tanto quanto demonstrar a presença.

---

## A. Regras gerais e organização (PDF §2, §4.3)

| ID | Critério | Origem | Como verificar | Status |
|---|---|---|---|---|
| A1 | Equipe com no máximo 4 alunos (dupla David + Samuel) | §2 | `docs/equipe.md` | ✅ |
| A2 | Tema T5 e Ênfase D registrados em aula; nenhuma outra equipe do T5 com a ênfase D | §2 | confirmação do professor | ⬜ |
| A3 | Só contêineres pequenos (Docker Compose) ou apps instalados; **nenhuma VM** | §2, §4.3 | compose files | ✅ |
| A4 🤖 | Pelo menos 3 nós do componente principal (3 membros etcd **e** 3 servidores ZK) | §2 | `revisar.py` | ✅ |
| A5 🤖 | `mem_limit` declarado em **todo** serviço | §2, R1 | `revisar.py` | ✅ |
| A6 | Limites respeitados na prática (uso medido < limite, total ≤ 8 GB) | R1, §4.3 | `docker stats` salvo em `docs/ambiente/evidencias/` | ✅ (repouso e após carga: etcd 80–87 MiB, ZK 83–133 MiB; limite 256 MB) |
| A7 | Só ferramentas open-source | §2 | etcd, ZooKeeper, kazoo, Docker | ✅ |
| A8 🤖 | Imagens com versão fixa (sem `latest` nem tag flutuante) | R1 (reprodutível) | `revisar.py` | ✅ |
| A9 | Repositório "derivado do kit": o PDF cita um kit (compose, scripts) que não recebemos | R1 | pedir ao professor (ver `duvidas-professor.md`) | ⬜ |

## B. Requisitos avaliados R1–R10 (PDF §3)

| ID | Critério de aceite | Como verificar | Status |
|---|---|---|---|
| R1 | Repositório Git com compose, configs, scripts e README. Sobe **do zero** seguindo só o README. Limites de memória declarados e respeitados | Samuel clona numa máquina limpa e roda o README; evidência do teste | ✅ (26/10: `docs/ambiente/evidencias/2026-10-26_2029_validacao_samuel.txt`) |
| R2 | Relatório cita os **artigos seminais**: Raft (Ongaro & Ousterhout 2014) e, pela ênfase, ZooKeeper (Hunt et al. 2010) e Zab (Junqueira et al. 2011). Cita também a **documentação oficial** e traz arquitetura com **diagrama próprio** | `relatorio/03-fundamentacao.md`, `diagramas/` | ✅ |
| R3 🤖 | Cada um dos E1 a E8 tem **previsão, procedimento, evidência e análise** | `experimentos/E1..E8/README.md` | ✅ (E1–E8 com previsão, procedimento, evidência e análise) |
| R4 🤖 | E9 (Ênfase D) com evidências e análise | `experimentos/E9-zookeeper/` | ✅ (E9-E3..E8 e `comparacao.md`) |
| R5 | Q1 a Q14 respondidas, **cada uma apontando para a evidência** experimental | `relatorio/06-questoes-comuns.md` | ✅ (revisado em 28/10) |
| R6 | S1 a S4 respondidas com fundamentação na pesquisa | `relatorio/07-questoes-especificas.md` | ✅ (revisado em 28/10) |
| R7 🤖 | Tempos (propagação, eleição, recuperação, latência) medidos **≥ 5 vezes** com **média e desvio padrão** | `resultados/*.csv` + tabelas nos READMEs | ✅ (todas as medições exigidas com n ≥ 5; 3 contrastes de 1 repetição, declarados) |
| R8 | Relatório com todos os 12 itens da §10 | seção H abaixo | ✅ (`relatorio/relatorio.pdf`) |
| R9 | Seminário de 10 min demonstrando o conhecimento, com vídeos, imagens e diagramas | seção I abaixo | 🟨 (vídeo gravado; slides em esboço) |
| R10 | **Os dois** apresentam e respondem à arguição sobre Q1 a Q14 | ensaio + `seminario/arguicao.md` | ⬜ (falta o ensaio e o treino da arguição) |

## C. Pesquisa obrigatória (PDF §9.1 + Ênfase D)

Cada ponto precisa aparecer na fundamentação (seção 3 do relatório) com fonte primária.

| ID | Tópico | Onde aparece no trabalho | Status |
|---|---|---|---|
| P1 | Raft: papéis (líder, seguidor, candidato), **termos**, eleição com **timeout aleatório** | E5, E6, E8, S1 | ✅ (seções 3, 6 e 7) |
| P2 | Raft: replicação do log, **regra de commit por maioria** | E2, E3 | ✅ (seções 3, 6 e 7) |
| P3 | Raft: **pre-vote** e **check quorum** (o que evitam, se o etcd 3.5 liga por padrão: **verificar na doc/flags**) | E6, E7 (nó que volta não derruba o líder) | ✅ (seções 3, 6 e 7) |
| P4 | Modelo de dados do etcd: chave-valor com **MVCC** e **revisões globais**; **watch**; **leases** (TTL); **transações** (compare-and-swap) | E3, E8, S4 | ✅ (seções 3, 6 e 7) |
| P5 | Leitura **linearizável** (padrão) × **serializável**; mecanismo **ReadIndex** | E4, S3 | ✅ (seções 3, 6 e 7) |
| P6 | **Snapshots** e **compactação** do log; entrada de membros novos e **learners** | E7, S2 | ✅ (seções 3, 6 e 7) |
| P7 | ZooKeeper: znodes **efêmeros** e **sequenciais**, **ZAB**, receitas de **trava** e **eleição**; comparação com Raft | E9 | ✅ (seções 3, 6 e 7) |
| P8 | ZAB: épocas e zxid (época + contador), fases (descoberta, sincronização, broadcast), sincronização DIFF/SNAP/TRUNC | E9-E5, E9-E7 | ✅ (seções 3, 6 e 7) |
| P9 | ZooKeeper: leitura local (consistência sequencial por cliente) × `sync`; ordem FIFO por cliente; escritas linearizáveis | E9-E4 | ✅ (seções 3, 6 e 7) |
| P10 | CAP e **PACELC** (exigido pela Q11) | E6, Q11 | ✅ (seções 3, 6 e 7) |
| P11 | Bully e Anel (U2) para comparar com Raft/ZAB | E8, Q8, S1 | ✅ (seções 3, 6 e 7) |
| P12 | Lamport, relógios vetoriais e multicast ordenado (para relacionar termo, revisão e zxid) | E8, Q9 | ✅ (seções 3, 6 e 7) |
| P13 | Chandy-Lamport e estado global (relacionar com snapshot) | E7, Q12 | ✅ (seções 3, 6 e 7) |
| P14 | Referências da §9.7: Raft (ATC 2014), ZooKeeper (ATC 2010), Zab (DSN 2011), Chubby (OSDI 2006), Kleppmann (2016), etcd.io/docs, raft.github.io | `relatorio/12-referencias.md` em ABNT | ✅ (seções 3, 6 e 7) |

## D. Bateria comum E1–E8 no etcd (PDF §4.2 e §9.3)

Vale para **todo** experimento:
- **D0a.** A previsão está registrada **antes** da execução, com data, e nunca é reescrita.
- **D0b.** Há procedimento reproduzível (`executar.sh`).
- **D0c.** A evidência bruta tem timestamp.
- **D0d.** A análise compara **previsão × resultado × teoria**.
- **D0e.** O experimento indica quais Q/S ele sustenta.

| ID | Critério | Evidência mínima (§4.2) | Status |
|---|---|---|---|
| E1.1 | `member list`, `endpoint status` (líder, termo, índice) e `endpoint health` registrados | saídas | ✅ |
| E1.2 | Diagrama com membros, redes, portas e líder atual | `diagramas/` | ✅ |
| E2.1 | `put` enviado a um **seguidor** (endpoint único) e mostrado sendo encaminhado ao líder | saída + log | ✅ |
| E2.2 | `-w json` mostrando `revision` e `raft_term`; RAFT INDEX avançando nos 3 membros | saídas antes/depois | ✅ |
| E2.3 | Diagrama de sequência: cliente → seguidor → líder → AppendEntries → commit com maioria → resposta | `diagramas/` | ✅ |
| E3.1 | Escrever em um membro, ler em outro (endpoints únicos); `watch` num terceiro recebendo a notificação | saídas | ✅ |
| E3.2 🤖 | Latência de `put` e `get` medida ≥ 5× (média, desvio). **Atenção:** o `docker exec` acrescenta ~250 ms; medir a partir de um cliente que desconte isso | CSV + tabela | ✅ |
| E3.3 | `etcdctl check perf --load=s` como referência, sem estourar a memória | saída + `docker stats` | ✅ |
| E4.1 | `get` linearizável × `--consistency=s` em condição normal: mesma resposta? latências? | sequência temporal | ✅ |
| E4.2 | Seguidor isolado: o serializável devolve o valor **antigo** e o linearizável **falha** (registrar o erro) | sequência temporal com valores | ✅ |
| E5.1 🤖 | Parar o **líder**: tempo até novo líder (≥ 5×), termo incrementado, escritas continuam | CSV + saídas | ✅ |
| E5.2 | Parar o 2º membro: `put` falha (*context deadline exceeded*), leitura linearizável falha, serializável responde | saídas | ✅ |
| E5.3 | Quadro "membros ativos × leitura lin. × leitura ser. × escrita" (3, 2 e 1 ativos) | tabela | ✅ |
| E6.1 | **Líder** desconectado só da rede interna, continuando acessível ao cliente | saída do `particionar.sh` | ✅ |
| E6.2 | Lado majoritário elege novo líder com termo maior; o antigo líder para de aceitar escritas; registrar o que o cliente dele recebe | saídas dos dois lados | ✅ |
| E6.3 | Conclusão **C × A** sustentada pela evidência | análise | ✅ |
| E7.1 🤖 | Membro reconectado volta como seguidor, com termo atualizado, e alcança o RAFT INDEX; tempo medido ≥ 5× | CSV + logs | ✅ |
| E7.2 | Com `SNAPSHOT_COUNT=1000`, membro parado durante milhares de escritas se recupera **por snapshot** (log mostra envio/recebimento de snapshot) | logs | ✅ |
| E7.3 | Estado final idêntico nas réplicas (mesma revisão e hash: `endpoint hashkv`) | saída | ✅ |
| E8.1 | Sequência de termos e revisões ao longo das falhas, explicada como relógios lógicos | tabela/linha do tempo | ✅ |
| E8.2 | `etcdctl lock` com 2 concorrentes (exclusão mútua) e `etcdctl elect` com 2 candidatos | saídas | ✅ |
| E8.3 🤖 | Parar o detentor e medir o tempo até o outro assumir (≥ 5×; referência do kit: ~11 s com TTL 10 s) | CSV | ✅ |
| E8.4 | Comparação da eleição do Raft com **Bully** e **Anel** | análise | ✅ |

## E. E9 — Ênfase D: ZooKeeper (PDF §9.5 D, §9.2)

| ID | Critério | Status |
|---|---|---|
| Z0 | Ensemble ZooKeeper de **3 nós** com imagem oficial, `JVMFLAGS=-Xmx128m` e `mem_limit` | ✅ |
| Z0b | Topologia do ZK documentada (diagrama + tabela). Não é exigido como E1, mas é necessário para entender o E9 | ✅ |
| Z3 | E3 no ZK: escrever em um servidor, ler em outro, **watch** num terceiro; latência ≥ 5× | ✅ |
| Z4 | E4 no ZK: leitura **local** × `sync` + leitura; servidor isolado: lê valor antigo ou recusa? (**verificar, não assumir**) | ✅ |
| Z5 | E5 no ZK: parar o líder, tempo de eleição ≥ 5×, **nova época no zxid**; perder a maioria (o que falha?) | ✅ |
| Z6 | E6 no ZK: líder fora da rede interna; servidor isolado em LOOKING; o que o cliente vê (desconexão/sessão) | ✅ |
| Z7 | E7 no ZK: religar; sincronização **DIFF/SNAP/TRUNC** nos logs; tempo ≥ 5× | ✅ |
| Z8a | **Trava** com znodes **efêmeros e sequenciais** (kazoo `Lock`), com 2 clientes | ✅ |
| Z8b | **Eleição** com znodes efêmeros e sequenciais (kazoo `Election`), com 2 candidatos; matar o detentor e medir o tempo de troca (session timeout) ≥ 5× | ✅ |
| Z9 | Quadro comparativo `comparacao.md` completo: protocolo, **época × termo**, **leitura local × linearizável**, **`sync` × ReadIndex**, lease × sessão, tempos medidos, partição, memória | ✅ |

## F. Questões comuns Q1–Q14 (PDF §4.1)

Cada resposta deve: (1) responder para o **etcd**; (2) quando fizer sentido, comparar com o **ZooKeeper** (enriquece a ênfase); (3) **apontar a evidência** (arquivo em `evidencias/` ou CSV).

| ID | O que a resposta precisa conter | Evidência que a sustenta | Status |
|---|---|---|---|
| Q1 | Problema resolvido (coordenação, configuração e descoberta com consistência forte). Transparências: replicação, falha, localização (lista de endpoints), concorrência (txn/locks) | E3, E5 | ✅ (revisado em 28/10) |
| Q2 | Estilo (cliente-servidor + **máquina de estados replicada**, centrado em dados); componentes e papéis (líder, seguidor, candidato, learner); **diagrama próprio** | E1 | ✅ (revisado em 28/10) |
| Q3 | Localização: **todos os membros têm a cópia inteira** (sem particionamento/hash). O cliente usa a lista de endpoints. Keyspace plano (etcd) × árvore de znodes (ZK). **Justificar a ausência de DHT** | E1, E3 | ✅ (revisado em 28/10) |
| Q4 | Protocolo (cliente: gRPC/HTTP2 + protobuf; pares: rafthttp na 2380; ZK: TCP próprio/jute). Síncrono, direto. Semântica de entrega/invocação (o que acontece em *retry* de `put`: **investigar**) | E2 | ✅ (revisado em 28/10) |
| Q5 | Máquina de estados replicada com **líder único**: N = 3, só o líder aceita escritas, seguidores encaminham | E2, E3 | ✅ (revisado em 28/10) |
| Q6 | Linearizável para escritas e leituras padrão; serializável opcional. ZK: escritas linearizáveis, leituras sequenciais com `sync` | E4, Z4 | ✅ (revisado em 28/10) |
| Q7 | Maioria ⌊N/2⌋+1 = 2 de 3; f = 1 com 2f+1 = 3. Relação com R + W > N. **Demonstrar perdendo o quórum** | E5 | ✅ (revisado em 28/10) |
| Q8 | Líder eleito por **Raft** (ZK: **ZAB/FLE**); comparar com Bully e Anel | E5, E8, Z5 | ✅ (revisado em 28/10) |
| Q9 | Termo (época), índice do log, revisão MVCC (ordem total); ZK: zxid = época + contador. Relacionar com Lamport e com multicast de ordem total | E8, Z5 | ✅ (revisado em 28/10) |
| Q10 | Modelo de falhas: **parada/recuperação** (não bizantino). Detecção por heartbeat + election timeout (valores padrão do etcd: **verificar**). Falha de 1 × falha da maioria | E5 | ✅ (revisado em 28/10) |
| Q11 | Sob partição prioriza **consistência** (CP); PACELC (PC/EC). **Sustentar com E6**, não com a documentação | E6, Z6 | ✅ (revisado em 28/10) |
| Q12 | Recuperação por catch-up do log ou por **snapshot**; ZK por DIFF/SNAP/TRUNC; relação com estado global e Chandy-Lamport | E7, Z7 | ✅ (revisado em 28/10) |
| Q13 | Problemas clássicos: eleição, consenso, exclusão mútua (lock), multicast de ordem total (log). Generais bizantinos: **não tratado** (justificar) | E5, E8, Z8 | ✅ (revisado em 28/10) |
| Q14 | Uso real (Kubernetes, ZK em Kafka antigo, HBase...). Limitações (cota do banco, tamanho de requisição, vazão limitada pelo líder: **conferir números na doc**). Segurança (TLS, autenticação/RBAC; o laboratório usa texto plano, que é limitação) | pesquisa | ✅ (revisado em 28/10) |

## G. Questões específicas S1–S4 (PDF §9.4)

| ID | O que a resposta precisa conter | Apoio | Status |
|---|---|---|---|
| S1 | O que o Raft acrescenta a Bully/Anel: **termos**, **um voto por termo**, **restrição de log** (só vence quem tem log atualizado). Por que o timeout é **aleatório** (evitar votos divididos) | E5, E8 | ✅ (revisado em 28/10) |
| S2 | Por que 3 ou 5 e não 4 (4 tolera as mesmas falhas que 3, com quórum maior). Custo de latência com mais membros. Para que servem os **learners** | E5 (+ medição opcional com 5 membros) | ✅ (revisado em 28/10) |
| S3 | Linearizável × serializável; **ReadIndex** sem gravar no log; onde o Kubernetes usa cada uma | E4 + observação de 24/10 (`get` não avança o índice) | ✅ (revisado em 28/10) |
| S4 | Pausa longa do detentor de trava com lease; **fencing token** (revisão da chave) | E8 (demonstração opcional com `docker pause`) | ✅ (revisado em 28/10) |

## H. Relatório (PDF §10)

| ID | Critério | Status |
|---|---|---|
| H0 | 15 a 25 páginas sem anexos; **capa, sumário, referências ABNT** | ✅ (capa e sumário; sumário sem número de página) |
| H1 | Identificação: equipe, integrantes, tema, ênfase | 🟨 (confirmar o nome completo do David) |
| H2 | Resumo com até 15 linhas (o que, como, principais conclusões) | ✅ (revisado em 28/10) |
| H3 | Fundamentação: sistema, origem, artigo seminal, arquitetura com **diagrama próprio** | ✅ (revisado em 28/10) |
| H4 | Ambiente: hardware, versões, topologia, **tabela de nós/IPs/portas**, **link do repositório**, instruções | ✅ |
| H5 | E1 a E9 com objetivo, **previsão**, procedimento, evidências, medições (média e desvio), análise | ✅ (revisado em 28/10) |
| H6 | Q1 a Q14 apontando para os experimentos | ✅ (revisado em 28/10) |
| H7 | S1 a S4 | ✅ (revisado em 28/10) |
| H8 | **Quadro-síntese** com as 10 linhas do modelo (estilo, localização, replicação, consistência, quórum, líder, ordenação, partição, recuperação, problemas clássicos), cada uma com referência à evidência | ✅ (revisado em 28/10) |
| H9 | Limitações e ameaças à validade: relógio compartilhado, rede local sem latência real, disco compartilhado, overhead do `docker exec`, mesmo host para todos os nós, texto plano sem TLS | ✅ (revisado em 28/10) |
| H10 | Papel de cada integrante | ✅ (revisado em 28/10) |
| H11 | Declaração de uso de IA (em quais partes e como foi verificado) | ✅ |
| H12 | Referências em ABNT | ✅ (acesso em 28 out. 2026) |

## I. Seminário (PDF §11)

| ID | Critério | Status |
|---|---|---|
| I1 | 10 min de apresentação + 5 min de arguição; ensaio cronometrado ≤ 10 min | ⬜ (falta o ensaio cronometrado) |
| I2 | Os dois apresentam; ambos preparados para qualquer Q/S | ⬜ (falta o treino da arguição) |
| I3 | Cluster **já rodando** no início (subir antes e rodar `validar.sh`) | 🟨 (demonstração em vídeo; se o professor pedir ao vivo: `seminario/demo.sh preparar`) |
| I4 | Bloco 1 (1 min): problema, uso real, artigo seminal | 🟨 (slides em esboço) |
| I5 | Bloco 2 (2 min): arquitetura com diagrama próprio, papéis, localização dos dados | 🟨 (slides em esboço) |
| I6 | Bloco 3 (4 min): demonstração de E2, E3, E5/E6 e E7 | 🟨 (slides em esboço) |
| I7 | Bloco 4 (2 min): E9 ZooKeeper, resultado principal e medições | 🟨 (slides em esboço) |
| I8 | Bloco 5 (1 min): quadro-síntese | 🟨 (slides em esboço) |
| I9 | Vídeo gravado de cada demonstração (contingência; a "Dica" do PDF recomenda usá-lo) | ✅ (vídeo gravado em 27/10) |

## J. Armadilhas do tema (PDF §9.6) viram verificações

| ID | Verificação | Status |
|---|---|---|
| J1 | Experimentos que observam um membro usam **endpoint único** (não a lista toda) | ✅ |
| J2 | `docker stop` (parada) e `docker pause` (congelamento) usados conscientemente; a diferença sobre leases/sessões está registrada | ✅ |
| J3 | Mudança de configuração inicial → `down -v` e recriar (sem erro de ID de cluster) | ✅ (documentado no README) |
| J4 | `check perf` rodado com 256 MB, sem OOM (conferir `docker inspect -f '{{.State.OOMKilled}}'`) | ✅ (`check perf` passou; ≤ 87 MiB depois) |
| J5 | Registrado que o relógio **não** afeta a segurança do Raft, mas **afeta leases** (e sessões do ZK) | ✅ (seção 9) |

## K. Processo interno (boa prática que protege a nota)

| ID | Verificação | Status |
|---|---|---|
| K1 | `scripts/validar.sh` OK antes de cada experimento, com a saída salva | ✅ (todo `executar.sh` começa e termina com `validar.sh`) |
| K2 | Evidência bruta nunca editada à mão; números no relatório batem com os CSVs | ✅ |
| K3 | Diário de bordo (`relatorio/notas/diario.md`) atualizado a cada sessão | ✅ |
| K4 | `docs/uso-ia.md` atualizado a cada uso de IA | ✅ |
| K5 | Commits pequenos e enviados ao GitHub privado; Samuel com acesso | ✅ (Samuel aceitou o convite em 26/10) |
| K6 | Dúvidas enviadas ao professor e respostas registradas | ⬜ (a dupla decidiu não enviar, 26/10) |
