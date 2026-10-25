# CLAUDE.md — Contexto obrigatório do Trabalho 2 (Sistemas Distribuídos)

> **Leia este arquivo inteiro antes de qualquer ação** (criar arquivo, alterar compose, rodar experimento, escrever relatório).
> Ele resume as regras do roteiro oficial (Prof. Ramices dos Santos Silva, UNIVALI, 2º sem/2026) e as convenções deste repositório.
> Em caso de conflito entre este arquivo e o PDF do roteiro, **o PDF vence** — e o conflito deve ser anotado em `docs/duvidas-professor.md`.

---

## 1. Identificação

| Item | Valor |
|---|---|
| Disciplina | Sistemas Distribuídos — Trabalho 2 |
| Tema | **T5 — Replicação de estado e configuração (etcd)** |
| Sistema principal (E1–E8) | **etcd v3.5.17** (Raft) — `quay.io/coreos/etcd:v3.5.17` |
| Ênfase (E9) | **D — ZooKeeper (ZAB)**: executar E3 a E8 em ensemble ZooKeeper de 3 nós e comparar com o etcd |
| Sistema da ênfase | **Apache ZooKeeper 3.9** — imagem oficial `zookeeper:3.9.6` |
| Equipe | **dupla: David Smith e Samuel Cesário Pereira Trizotto de Andrade** (papéis em `docs/equipe.md`) |
| Entrega 1 (relatório) | via AVA até **28/10/2026 (quarta)**: prazo informado pela dupla em 25/10; o PDF diz 28/11 |
| Etapa 2 (seminário) | em aula, **28/10/2026 (quarta)** |

**Leitura correta da Ênfase D:** a bateria comum E1–E8 é feita no **etcd**. O E9 consiste em **repetir E3–E8 no ZooKeeper** (com znodes efêmeros e sequenciais para trava e eleição) e **comparar ZAB × Raft**: épocas × termos, leitura local × linearizável, `sync`.

**Dupla:** o seminário exige que **todos apresentem** e a arguição pode cair para qualquer um — os dois precisam dominar Q1–Q14 e S1–S4. Dividir a execução, mas ambos revisam tudo.

---

## 2. Regras do roteiro que NUNCA podem ser quebradas

1. **Só contêineres leves** (Docker Compose) ou aplicações instaladas diretamente. **Nenhuma VM.**
2. **Mínimo de 3 nós** do componente principal (3 membros etcd; 3 servidores ZooKeeper).
3. **Limites de memória declarados** (`mem_limit`) em todo serviço e respeitados (a máquina-alvo tem 8 GB).
4. **Reprodutível do zero**: o professor precisa subir tudo seguindo só o README. Nada pode depender de estado local não versionado.
5. **Previsão antes de cada experimento** — registrada *antes* de executar (comparar previsão × resultado é parte central da nota).
6. **Medições de tempo ≥ 5 repetições**, com **média e desvio padrão** (propagação, eleição, recuperação, latência) — requisito R7.
7. **Toda resposta às questões Q1–Q14 aponta para a evidência experimental** correspondente.
8. **Fontes primárias**: artigo seminal (Raft — Ongaro & Ousterhout 2014; ZooKeeper — Hunt et al. 2010; Zab — Junqueira, Reed & Serafini 2011) + documentação oficial. Referências em **ABNT**.
9. **Diagramas próprios** (arquitetura, topologia, sequência) — nada copiado da documentação.
10. **Declaração de uso de IA generativa** no relatório (seção 11): manter `docs/uso-ia.md` atualizado a cada uso.

---

## 3. Requisitos avaliados (R1–R10) → onde cada um vive no repositório

| # | Requisito | Artefato no repo |
|---|---|---|
| R1 | Ambiente reprodutível ≥3 nós, só contêineres | `etcd/docker-compose.yml`, `zookeeper/docker-compose.yml`, `README.md` |
| R2 | Pesquisa fundamentada + diagrama próprio | `relatorio/03-fundamentacao.md`, `diagramas/` |
| R3 | E1–E8 executados (previsão, procedimento, evidência, análise) | `experimentos/E1..E8/` |
| R4 | E9 (Ênfase D) | `experimentos/E9-zookeeper/` |
| R5 | Q1–Q14 respondidas com evidência | `relatorio/06-questoes-comuns.md` |
| R6 | S1–S4 | `relatorio/07-questoes-especificas.md` |
| R7 | Medições ≥5×, média e desvio | `scripts/medir.sh`, `scripts/estatistica.py`, `resultados/*.csv` |
| R8 | Relatório completo (12 seções) | `relatorio/` |
| R9 | Seminário 10 min | `seminario/` (slides, vídeos de contingência) |
| R10 | Domínio de toda a equipe | `docs/equipe.md` (papéis) + roteiro de arguição em `seminario/arguicao.md` |

---

## 4. Estrutura do repositório (raiz = esta pasta)

```
Sistemas_Distribuidos/
├── CLAUDE.md                  ← este arquivo
├── README.md                  ← como subir/derrubar/testar do zero
├── CHECKLIST.md               ← controle de status de cada item (ver §8)
├── .gitignore / .gitattributes (força LF nos .sh)
├── etcd/
│   ├── docker-compose.yml     ← 3 membros, redes interna/clientes
│   └── .env                   ← EP (lista de endpoints), SNAPSHOT_COUNT
├── zookeeper/
│   ├── docker-compose.yml     ← 3 servidores + cliente Python (kazoo)
│   └── cliente/               ← scripts Python: srvr, trava, eleição, watch
├── scripts/
│   ├── lib.sh                 ← funções comuns (timestamp, salvar evidência, MSYS_NO_PATHCONV)
│   ├── medir.sh               ← executa N repetições e gera CSV
│   ├── estatistica.py         ← média, desvio padrão, tabela Markdown
│   ├── particionar.sh         ← desconecta/reconecta nó da rede interna
│   └── validar.sh             ← validação de saúde (pré-condição de todo experimento)
├── experimentos/
│   ├── E1-subida/  …  E8-coordenacao/
│   │   ├── README.md          ← objetivo, PREVISÃO, procedimento, análise
│   │   ├── executar.sh        ← passos reproduzíveis
│   │   └── evidencias/        ← saídas brutas com timestamp
│   └── E9-zookeeper/          ← E3–E8 repetidos no ZooKeeper + comparação
├── resultados/                ← CSVs das medições
├── diagramas/                 ← fontes (Mermaid/draw.io) + PNG exportado
├── relatorio/                 ← seções 01..12 do relatório
├── seminario/
└── docs/
    ├── equipe.md
    ├── uso-ia.md
    └── duvidas-professor.md
```

---

## 5. Ambiente

### 5.1 Pré-requisitos
- Docker (Docker Desktop + WSL 2 no Windows; Docker Engine no Linux; Docker Desktop/Colima no macOS) e Git.
- No Windows, os scripts `.sh` rodam no **Git Bash** ou no **WSL** (bash), não no PowerShell. `scripts/lib.sh` exporta `MSYS_NO_PATHCONV=1` para o Git Bash não reescrever caminhos como `/config/modo`.
- `python3` (ou `python`) no host para `scripts/estatistica.py` (só biblioteca padrão).

### 5.2 etcd (sistema principal)
- Projeto Compose com `name: t5-etcd` (assim as redes ficam `t5-etcd_interna` e `t5-etcd_clientes`).
- Rede **interna** `172.30.0.0/24` → tráfego Raft entre pares (porta **2380**).
- Rede **clientes** `172.31.0.0/24` → clientes (porta **2379**).
- Membros: `etcd1` .31, `etcd2` .32, `etcd3` .33 — `mem_limit: 256m`.
- `--initial-cluster` deve ficar **em uma única linha**.
- A imagem **não tem shell**: `etcdctl` roda via `docker exec etcdN etcdctl ...`; laços de medição rodam **no host**.
- `EP=172.31.0.31:2379,172.31.0.32:2379,172.31.0.33:2379`
- Comandos-base:
  ```bash
  docker exec etcd1 etcdctl --endpoints=$EP member list -w table
  docker exec etcd1 etcdctl --endpoints=$EP endpoint status -w table   # IS LEADER, RAFT TERM, RAFT INDEX
  docker exec etcd1 etcdctl --endpoints=$EP endpoint health
  ```

### 5.3 ZooKeeper (Ênfase D)
- Projeto Compose com `name: t5-zk`.
- **Sub-redes diferentes do etcd** para os dois laboratórios poderem coexistir: interna `172.32.0.0/24` (quorum 2888, eleição 3888), clientes `172.33.0.0/24` (porta 2181).
- Servidores `zk1` .51, `zk2` .52, `zk3` .53 — `ZOO_MY_ID`, `ZOO_SERVERS="server.1=172.32.0.51:2888:3888;2181 server.2=... server.3=..."`, `JVMFLAGS=-Xmx128m`, `mem_limit: 256m`.
- `ZOO_4LW_COMMANDS_WHITELIST=srvr,stat,mntr,ruok,conf,cons` (necessário para `srvr`/`stat`).
- Cliente: `python:3.12-alpine` com `kazoo` (receitas `Lock` e `Election`), `mem_limit: 128m`, IP `172.33.0.100`. `zkCli.sh` roda dentro dos servidores.
- Ver líder: `docker exec zk1 zkServer.sh status` (Mode: leader/follower) ou `docker exec zk-cliente python /app/srvr.py`.
- Época ZAB: `Zxid` do `srvr` (32 bits altos = época) e arquivos `/data/version-2/currentEpoch` e `acceptedEpoch`.
- ⚠️ Pontos a **verificar experimentalmente, não assumir**: comportamento de um servidor isolado (espera-se que pare de atender clientes, salvo com `readonlymode.enabled=true`); leituras locais podem ser desatualizadas até um `sync`.

### 5.4 Partição de rede (E6)
```bash
scripts/particionar.sh isolar etcd1      # = docker network disconnect t5-etcd_interna etcd1
scripts/particionar.sh religar etcd1     # = docker network connect --ip 172.30.0.31 t5-etcd_interna etcd1 (MESMO IP)
```

---

## 6. Armadilhas conhecidas (do roteiro + práticas)

- Lista completa de endpoints **esconde falhas** (o cliente troca de membro sozinho). Para observar um membro, use **endpoint único**.
- `docker stop` (parada) ≠ `docker pause` (congelamento): efeito diferente sobre leases/sessões.
- Mudou a configuração inicial do cluster? `docker compose down -v` e recria do zero (evita erro de ID de cluster).
- Entre experimentos que dependem de estado, use `stop/start`, não `down`.
- `etcdctl check perf` gera carga pesada; com memória baixa o membro pode ser morto (manter 256 MB).
- Relógio do sistema não afeta a segurança do Raft, mas afeta **leases** (e sessões do ZooKeeper) — registrar essa diferença.
- Todos os contêineres compartilham o relógio do host → limitação a citar na seção 9 do relatório.
- `etcdctl lock`/`elect` liberam ao fim do lease (TTL padrão 10 s; kit mediu ~11 s); no ZooKeeper o equivalente é o **session timeout** do cliente.
- Windows: scripts `.sh` com CRLF quebram no bash — o `.gitattributes` força LF; não desligar.

---

## 7. Bateria de experimentos

### 7.1 etcd (E1–E8)
| Exp. | O que fazer | Evidência mínima |
|---|---|---|
| E1 | `member list`, `endpoint status`, `endpoint health`; diagrama | saídas + diagrama com IPs/portas/líder |
| E2 | `put` em seguidor (endpoint único) → encaminhado ao líder; `-w json` (revision, raft_term); RAFT INDEX avançando | saídas + diagrama de sequência (cliente→seguidor→líder→AppendEntries→commit maioria→resposta) |
| E3 | escrever em um, ler em outro; `watch` em terceiro; latência put/get ×5; `check perf --load=s` | tabela ≥5 medições, média, desvio |
| E4 | get linearizável × `--consistency=s`; seguidor isolado: qual responde valor antigo e qual falha | sequência temporal escrita/leitura |
| E5 | parar líder (tempo de eleição ×5, termo +1); parar 2º membro (put falha, linearizável falha, serializável responde) | quadro membros × leitura lin. × leitura ser. × escrita |
| E6 | líder fora da rede interna; lado majoritário elege novo líder; o que o cliente do isolado recebe | comportamento dos dois lados + conclusão C×A |
| E7 | religar; volta como seguidor e alcança RAFT INDEX (×5); `--snapshot-count` baixo → recuperação por snapshot | logs + tempos + estado final idêntico |
| E8 | termos e revisões como relógios lógicos; `etcdctl lock` e `elect`; parar detentor e medir troca; comparar com Bully/Anel | troca de líder com termo maior + tempos |

### 7.2 ZooKeeper — E9 (Ênfase D): E3–E8 equivalentes
| Exp. | Equivalente no ZooKeeper |
|---|---|
| E3 | `create`/`set` em um servidor, `get` em outro; `get -w` (watch) em terceiro; latência ×5 |
| E4 | leitura local × `sync` + leitura; servidor isolado |
| E5 | parar líder (eleição ×5, nova época no zxid); perder maioria |
| E6 | líder fora da rede interna; estado LOOKING; o que o cliente vê |
| E7 | religar; sincronização (DIFF/SNAP/TRUNC nos logs) ×5 |
| E8 | trava e eleição com **znodes efêmeros e sequenciais** (kazoo); época ZAB × termo Raft |

**Quadro comparativo obrigatório do E9** (`experimentos/E9-zookeeper/comparacao.md`): protocolo (Raft × ZAB), época × termo, leitura padrão (linearizável × local/sequencial), mecanismo para leitura atual (ReadIndex × `sync`), lease × sessão/efêmero, tempo de eleição medido, tempo de recuperação medido, comportamento sob partição, memória medida.

---

## 8. Protocolo de trabalho do assistente (validação e controle)

**Toda resposta que criar ou alterar algo DEVE terminar com estes 4 blocos:**

1. **▶ Como executar** — comandos exatos, a partir de qual pasta.
2. **✅ Como testar / critério de aceite** — comando de verificação e a saída esperada (ex.: “3 linhas `true` em `endpoint health`”, “`IS LEADER = true` em exatamente 1 membro”).
3. **📁 Evidência** — onde salvar a saída (`experimentos/EX/evidencias/AAAA-MM-DD_HHMM_descricao.txt`).
4. **☑ Controle** — qual item do `CHECKLIST.md` muda de status e qual é o próximo passo.

**Regras adicionais:**
- Antes de qualquer experimento: rodar `scripts/validar.sh` (cluster saudável, 1 líder, mesma RAFT INDEX/zxid). Se falhar, **não seguir** — diagnosticar primeiro.
- Escrever a **previsão** no `README.md` do experimento **antes** de rodar; nunca reescrever a previsão depois do resultado. A previsão é da **dupla** — o assistente não a escreve no lugar dela.
- Saídas brutas são salvas com `tee` e timestamp; nunca editar evidência à mão.
- Medições: `scripts/medir.sh` → CSV em `resultados/` → `scripts/estatistica.py` gera média/desvio. Mínimo 5 repetições.
- Não inventar números nem saídas: se algo não foi executado, marcar como **pendente**.
- Afirmações sobre comportamento do sistema devem vir de **evidência ou fonte primária**; documentação sozinha não basta para Q11 (C×A).
- Onde um mecanismo não existir, **demonstrar e justificar a ausência** (vale tanto quanto a presença).
- Registrar todo uso de IA em `docs/uso-ia.md` (data, parte, como foi verificado).
- Commits pequenos e descritivos: `feat(etcd): compose com 3 membros`, `exp(E5): medicoes eleicao lider`, `docs(relatorio): Q7 quorum`.

**Notas para o relatório (obrigatório a cada sessão):**
- `relatorio/notas/diario.md`: nova entrada no topo com o que foi feito, os resultados (com o caminho da evidência), os problemas e as soluções, e os próximos passos.
- `relatorio/notas/achados.md`: toda observação que ajude a responder uma Q ou S, com evidência. Se a observação for exploratória (sem previsão), marcar assim e formalizá-la num experimento.
- `relatorio/notas/prints.md`: os prints a tirar (o que, comando, para qual seção).
- Quando houver dado real, preencher a seção correspondente em `relatorio/NN-*.md`, por exemplo a 4 (ambiente) e a 9 (limitações).

**Revisão de critérios:**
- `docs/criterios-avaliacao.md` traz a lista completa derivada do PDF; atualizar o status quando algo mudar.
- `python scripts/revisar.py` confere os itens automáticos. Rodar ao fim de cada sessão e antes da entrega.

### Status do CHECKLIST.md
`⬜ pendente` · `🟨 em andamento` · `✅ validado (com evidência)` · `❌ bloqueado (motivo)`

---

## 9. Relatório (15–25 páginas, ABNT) — 12 seções obrigatórias

1 Identificação · 2 Resumo (≤15 linhas) · 3 Fundamentação (artigo seminal + diagrama próprio) · 4 Ambiente e reprodutibilidade (hardware, versões, topologia, tabela de nós/IPs/portas, link do repo) · 5 Experimentos E1–E9 (objetivo, previsão, procedimento, evidência, medição, análise) · 6 Q1–Q14 · 7 S1–S4 · 8 **Quadro-síntese** · 9 Limitações e ameaças à validade · 10 Papel de cada integrante · 11 Declaração de uso de IA · 12 Referências.

**Questões específicas do Tema 5:**
- **S1** Raft × Bully/Anel (termos, voto único por termo, restrição de log); por que timeout aleatório.
- **S2** Por que 3 ou 5 membros e não 4; custo de latência; learners.
- **S3** Linearizável × serializável; ReadIndex; onde o Kubernetes usa cada uma.
- **S4** Pausa longa do detentor de trava com lease; fencing token (revisão da chave).

**Referências-base:** Ongaro & Ousterhout (USENIX ATC 2014); Hunt et al. (USENIX ATC 2010); Junqueira, Reed & Serafini (DSN 2011); Burrows — Chubby (OSDI 2006); Kleppmann — *How to do distributed locking* (2016); docs etcd (etcd.io/docs) e raft.github.io; docs ZooKeeper (zookeeper.apache.org).

---

## 10. Seminário
- 10 min de apresentação + 5 min de arguição; **os dois apresentam**; o professor escolhe quem responde (Q1–Q14, S1–S4).
- Cluster **já rodando** no início. Blocos: problema/artigo (1 min) · arquitetura (2) · demo E2/E3/E5-E6/E7 (4) · E9 ZooKeeper (2) · quadro-síntese (1).
- **Sempre ter vídeo gravado de cada demo** como contingência.

---

## 11. Pontos em aberto para confirmar com o professor (`docs/duvidas-professor.md`)
- As seções 12–15 e o Anexo A do PDF estão quebradas (“Erro! Indicador não definido”): pedir **cronograma, checklist de autoavaliação e quadro de equipes**.
- Conflito no seminário: R9 e a “Dica” falam em **vídeos já produzidos**, mas a seção 11 exige **demonstração ao vivo de no mínimo 8 min** dentro de 10 min (e o roteiro de slides reserva só 4 min de demo). Confirmar o formato esperado.
- Confirmar que a Ênfase D = etcd em E1–E8 + ZooKeeper em E3–E8 como E9 (leitura adotada aqui).
- Prazo: o PDF diz 28/11, mas a dupla informou em 25/10 que **relatório e seminário são em 28/10/2026**. Vale 28/10; confirmar o horário limite do AVA.
