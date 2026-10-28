# Contexto para um novo chat (relatório e slides)

> Este documento orienta um assistente de IA que vai continuar o trabalho em outro chat.
> Leia-o inteiro antes de responder. Foi gerado em 28/10/2026 a partir do repositório no commit `69d29ed`.
> Responda sempre em **português do Brasil**.

---

## 1. Quem são e o que é o trabalho

- **Disciplina:** Sistemas Distribuídos, Trabalho 2 (M2), UNIVALI, 2º semestre de 2026. Prof. Ramices dos Santos Silva.
- **Dupla:** David Smith (o usuário deste chat) e Samuel Cesário Pereira Trizotto de Andrade.
- **Tema:** T5, replicação de estado e configuração com o **etcd v3.5.17** (Raft), nos experimentos E1–E8.
- **Ênfase D (E9):** repetir E3–E8 no **ZooKeeper 3.9.6** (ZAB) e comparar ZAB com Raft.
- **Prazo: hoje, 28/10/2026 (quarta).** O relatório vai pelo AVA e o seminário é em aula: 10 min de apresentação mais 5 min de arguição, com os dois apresentando. O professor escolhe quem responde.
- **Repositório (privado):** https://github.com/DavidSmithSouzak10/sd-t2-etcd-zookeeper
  - Na máquina do David, ele está em `C:\Documentos\Faculdade\8-semestre\Sistemas_Distribuidos`.
  - Na do Samuel, a pasta-mãe se chama `SISTEMAS_DISTRIBUIDOS_M2`.

## 2. Material que você precisa pedir ao usuário (não está no repositório)

1. **O PDF do roteiro oficial** ("Roteiro Trabalho M2"). Em caso de conflito, ele é a fonte que manda.
   - As seções 12–15 e o Anexo A estão quebradas no PDF ("Erro! Indicador não definido").
2. **O arquivo dos slides.** São 11 slides, feitos pelo Samuel, organizados nos 5 blocos do roteiro e com notas do apresentador. Ficam fora do repositório.
3. **O vídeo das demos** (94 MB, fora do repositório). Você só precisa dele se o usuário quiser revisar a fala.

Se o usuário não anexar algum desses, trabalhe com os arquivos do repositório listados abaixo e diga qual material faltou.

## 3. Arquivos do repositório que são a fonte da verdade

| Para… | Leia |
|---|---|
| Regras do trabalho e convenções | `CLAUDE.md` (raiz) |
| O que é avaliado, com status | `docs/criterios-avaliacao.md` (IDs A, R, H, I, K…) |
| Status de cada entrega | `CHECKLIST.md` |
| Histórico das sessões, problemas e soluções | `relatorio/notas/diario.md` (mais recente no topo) |
| Achados e prints sugeridos | `relatorio/notas/achados.md`, `relatorio/notas/prints.md` |
| Relatório (12 seções) | `relatorio/01-identificacao.md` … `relatorio/12-referencias.md`; PDF montado em `relatorio/relatorio.pdf` (24 páginas) |
| Cada experimento (previsão, procedimento, evidência, análise) | `experimentos/E1..E8/README.md`, `experimentos/E9-zookeeper/E3..E8/README.md` |
| Quadro comparativo do E9 | `experimentos/E9-zookeeper/comparacao.md` |
| Medições brutas | `resultados/*.csv` (estatística: `python scripts/estatistica.py <csv>`) |
| Seminário | `seminario/roteiro-demos.md` (fala das demos), `seminario/demo.sh`, `seminario/arguicao.md` (respostas curtas Q1–Q14 e S1–S4), `seminario/mini-aula.pdf` |
| Diagramas próprios | `diagramas/topologia.png`, `diagramas/sequencia-escrita.png` (fontes `.mmd`) |
| Uso de IA declarado | `docs/uso-ia.md` e `relatorio/11-uso-ia.md` |

Para gerar o PDF do relatório de novo: `python scripts/gerar_pdf.py relatorio`. Para a verificação automática: `python scripts/revisar.py`.

## 4. Estado em 28/10 (revisão feita contra os critérios)

**Concluído e com evidência:**
- Ambiente reprodutível (R1), testado do zero na máquina do Samuel.
- E1–E8 e E9-E3..E8 executados, com previsão registrada antes de cada um (R3, R4).
- Medições com 5 repetições, média e desvio (R7).
- As 12 seções do relatório, **revisadas e aprovadas pela dupla em 28/10** (R2, R5, R6, R8):
  - os links das referências foram abertos em 28/10;
  - o link do ZooKeeper, que estava quebrado, foi corrigido;
  - a S3 foi atualizada conforme a documentação atual do Kubernetes.
- Vídeo das demos gravado e mini-aula pronta.
- `scripts/revisar.py`: **95 de 98**.

**Pendente, em ordem de prioridade para hoje:**
1. **Entregar o relatório no AVA.** O horário limite não foi confirmado.
2. **Dar ao professor acesso ao repositório privado.** O R1 depende disso, porque o professor precisa conseguir subir tudo seguindo o README. O relatório diz "acesso ao professor a combinar".
3. **Revisar os slides** (🟨). Conferir:
   - os 5 blocos e os tempos (1 + 2 + 4 + 2 + 1 min);
   - os números batendo com o relatório (seção 6 deste documento);
   - diagramas próprios;
   - os prints reais das demos.
4. **Ensaio cronometrado** de no máximo 10 min, com os dois falando (I1, I2, R10).
5. **Treino da arguição** com `seminario/arguicao.md`: os dois precisam dominar Q1–Q14 e S1–S4. A coluna "Dono" diz quem revisou cada resposta, mas qualquer um pode ser perguntado.
6. **Confirmar o nome completo do David** na capa (H1). Hoje está "David Smith".

**Achados da revisão (pequenos, mas vale corrigir se houver tempo):**
- **Linha 22 de `experimentos/E9-zookeeper/README.md`:** ainda diz que os scripts kazoo estão "_pendente_". Os scripts existem (`zookeeper/cliente/e9_*.py`), então a marcação está desatualizada.
- **As 3 medições com uma só rodada** são o que fica nas pendências do `revisar.py`:
  - `resultados/2026-10-26_2142_e8_troca_lock_stop.csv`;
  - `resultados/2026-10-26_2147_e8_troca_elect_stop.csv`;
  - `resultados/2026-10-26_2135_e9e7_recuperacao_5000.csv`.

  Elas são **contrastes intencionais**: o `stop` para comparar com o `kill`, e as 5000 escritas para ver se o ZooKeeper ainda usa DIFF. Não fazem parte da exigência de 5 repetições. O texto do relatório e dos READMEs deveria dizer isso explicitamente, com "rodada única de contraste", para o avaliador não ler como falha do R7.
- **O formato do seminário está em aberto** (`docs/duvidas-professor.md`, item 2), e a dupla decidiu não enviar as dúvidas:
  - o R9 e a "Dica" do PDF falam em vídeos;
  - a seção 11 do PDF pede demonstração **ao vivo**.

  A dupla vai usar prints e vídeo. Recomende ter os clusters prontos na máquina da apresentação (`seminario/demo.sh preparar`, que deve terminar em `VALIDAÇÃO OK (todos)`) caso o professor peça ao vivo.
- **A2 e A9** (registro do tema e "kit" do professor) só se confirmam com o professor. Não há o que fazer neles no repositório.

## 5. Regras que você deve seguir

- **Não invente números nem saídas.** Todo número vem de um CSV em `resultados/` ou de um arquivo de evidência. Se algo não foi executado, diga que está pendente.
- **Não reescreva as previsões** dos experimentos. Elas foram registradas antes da execução e fazem parte da nota (previsão × resultado). Previsões erradas ficam como estão e são analisadas.
- **Toda resposta a Q1–Q14 e S1–S4 aponta para o experimento que a prova.** A Q11 (C ou A) precisa de evidência experimental (E6, E9-E6), não só documentação.
- **Diagramas sempre próprios:** nada copiado da documentação.
- **Referências em ABNT**, de fontes primárias:
  - Ongaro e Ousterhout (2014);
  - Hunt et al. (2010);
  - Junqueira, Reed e Serafini (2011);
  - Burrows (2006);
  - Kleppmann (2016);
  - documentação oficial do etcd e do ZooKeeper.
- **Registre o uso de IA** em `docs/uso-ia.md`: data, ferramenta, parte e como foi verificado. Se o texto da seção 11 mudar, ajuste `relatorio/11-uso-ia.md`.
- **Commits:** mensagens curtas no padrão `docs(relatorio): …`, `docs(seminario): …`. **Nunca inclua a linha `Co-Authored-By` de IA**: é pedido explícito do usuário.
- Ao fim de uma sessão que altere o repositório:
  - acrescente uma entrada no topo de `relatorio/notas/diario.md`;
  - atualize o `CHECKLIST.md`;
  - rode `python scripts/revisar.py`.
- **Transparência sobre as previsões de E5–E8 e E9-E5..E8:**
  - a primeira versão foi feita por questionário de múltipla escolha (commit `5196dea`, 20:59 de 26/10);
  - antes de qualquer execução, ela foi revisada com ajuda de IA e assumida pela dupla (commit `0dc40dd`, 21:11);
  - a execução começou às 21:18.

  Isso já está declarado em `docs/uso-ia.md`. Se o assunto aparecer no relatório ou na arguição, trate-o com essa transparência.

## 6. Números principais (para slides e arguição; n = 5, média ± desvio)

| Exp. | etcd (Raft) | ZooKeeper (ZAB) |
|---|---|---|
| Eleição após `kill` do líder (E5) | **1,46 ± 0,18 s**, termo +1 | **0,38 ± 0,09 s**, época +1 (a conexão TCP fechada avisa os seguidores) |
| Eleição após `stop` do líder | cerca de 9 ms (o etcd transfere a liderança antes de sair) | 0,70 ± 0,09 s |
| Sem maioria (E5) | escrita e linearizável falham; a serializável responde | o servidor fica sem serviço; nem a sessão abre |
| Partição do líder (E6) | a maioria elege em 0,94 ± 0,24 s\*; o isolado dá `etcdserver: no leader` e a serializável devolve o valor antigo → **C** (PC/EC) | a maioria elege em 3,6 ± 0,3 s\* (`syncLimit` × `tickTime`); o isolado faz "Shutting down"; o cliente com a lista dos 3 migra de servidor → **C** |
| Recuperação (E7) | cerca de 6,5 s em 4 de 5 repetições (uma em 50 ms)\*. Quase todo o tempo é reconexão entre pares; as 1005 entradas chegam quase na hora. Com `SNAPSHOT_COUNT=1000`, o líder envia um *merged snapshot* de 701 kB e o `hashkv` sai idêntico nos 3 | DIFF em 5 de 5, 2,5 ± 0,7 s\*; com 5000 escritas ainda é DIFF (6,7 s, rodada única) |
| Trava e eleição (E8) | `lock` (TTL 10 s): troca em 7,9 ± 1,5 s; `elect` (sessão de 60 s, sem `--ttl`): 57,2 ± 0,3 s. **Fencing token** = `create_revision`: a gravação do detentor antigo (113) é recusada depois que o novo tem 114 | znodes efêmeros e sequenciais (kazoo): trava 7,9 s, eleição 7,8 s (sessão de 10 s); só o próximo da fila é avisado |
| Relógios lógicos | termo (mandato), índice do log, revisão global (ordem total, tipo Lamport) | zxid = época (32 bits altos) + contador |

\* **Ressalva de medição** (seção 9 do relatório): o início das medições de partição e religação é o evento `disconnect`/`connect` do `docker events`. Esse evento é registrado **depois** do corte real (3 de 5 eleições do E6 ficaram abaixo do mínimo teórico de cerca de 0,9 s). Por isso, E6, E9-E6, E7 e E9-E7 são **limites inferiores**, que podem estar subestimados em até cerca de 0,3–0,4 s. As medições com `kill` não são afetadas.

**Outras anomalias já documentadas:**
- **E5, repetição 2:** o termo saiu 3 → 3, porque líder e termo foram lidos de forma não atômica (o status leu um membro ainda não atualizado).
- **E7 bimodal (50 ms × 6,5 s):** a hipótese é o *backoff* na reconexão do rafthttp. Está marcada como hipótese, não como fato.

**Limitações gerais** (seção 9):
- todos os contêineres compartilham o relógio do host;
- as falhas são simuladas com o Docker, sem perda parcial de pacotes nem partição assimétrica;
- há uma única máquina por execução;
- não há TLS nem controle de acesso.

## 7. Estrutura esperada dos slides (seção 10 do `CLAUDE.md` / roteiro)

| Bloco | Tempo | Conteúdo |
|---|---|---|
| 1 | 1 min | problema, uso real (o Kubernetes guarda todo o estado no etcd), artigo seminal (Raft, 2014) |
| 2 | 2 min | arquitetura com o diagrama próprio: 3 membros, rede interna com Raft na porta 2380 e rede de clientes na 2379, líder e seguidores, onde ficam os dados |
| 3 | 4 min | demos: E2 (caminho da escrita), E3 (replicação), E5/E6 (falha e partição), E7 (recuperação), com prints ou vídeo |
| 4 | 2 min | E9 ZooKeeper: o resultado principal e as medições comparadas |
| 5 | 1 min | quadro-síntese (`relatorio/08-quadro-sintese.md`, versão resumida) |

Os dois apresentam. Sugira a divisão das falas se o usuário pedir. Na arguição, o "dono" de cada resposta está em `seminario/arguicao.md`.

## 8. Como começar no novo chat

1. Peça o PDF do roteiro e o arquivo dos slides, se ainda não foram anexados.
2. Pergunte ao usuário qual das pendências da seção 4 ele quer atacar primeiro. A sugestão é: slides → ensaio e arguição → entrega no AVA e acesso ao repositório.
3. Se for editar o relatório, depois de editar regenere o PDF (`python scripts/gerar_pdf.py relatorio`) e confira se ele continua entre 15 e 25 páginas.
