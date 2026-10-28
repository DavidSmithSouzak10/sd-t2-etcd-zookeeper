# Diário de bordo

Uma entrada por sessão de trabalho, a mais recente no topo. Registrar:
- o que foi feito e quem fez;
- os resultados, com o caminho da evidência;
- os problemas e como foram resolvidos;
- os prints sugeridos;
- o que fica para depois.

Este diário é a fonte das seções 4 (ambiente), 5 (experimentos) e 9 (limitações) do relatório.

---

## 2026-10-28 (quarta), sessão 14: seminário apresentado

**Feito:** seminário apresentado em aula em 28/10/2026 pela dupla, com o vídeo das demonstrações (E2, E3, E5, E6, E7 e E9) e os slides (o que cada demo prova, quadro comparativo do E9, previsão × resultado, quadro-síntese). Segundo o Samuel, o professor gostou do trabalho. Versão marcada no repositório com a tag `entrega-final`.

**Pendente:** confirmar a entrega do relatório no AVA e o acesso do professor ao repositório.

---

## 2026-10-28 (quarta), sessão 13: correções da revisão do David (Samuel + Claude Code, máquina do Samuel)

**Feito:** incorporada a revisão do Claude Code do David.
- Partição: o ZooKeeper isolado ainda serve leitura local antiga por alguns segundos antes de parar; o texto (Q11, quadro-síntese, mini-aula e slides) agora diz isso, e a conclusão passou a ser "no lado minoritário nenhum dos dois confirma escrita".
- Diagrama de sequência: no etcd, o seguidor que recebeu o `put` aplica a entrada ao saber do commit e só então responde ao cliente; o líder não devolve o resultado. Corrigidos `diagramas/sequencia-escrita.mmd` e o PNG; a Figura 2 entrou no relatório (seção 5.2).
- S3: os números de leitura do ZooKeeper agora dizem de qual experimento vêm (E9-E4: 1,03 × 3,25 ms; E9-E3: 1,53 × 3,89 ms). Os dois pares conferem com os CSVs.
- Placar do Samuel explicitado: 1 errada (E7) e 1 parcial (E8, o `elect`). Medições de 1 repetição chamadas de "contraste". README do E9 sem a pendência antiga dos scripts kazoo.
- Slides: placar de previsões (26 de 34), quadro comparativo do E9 com média ± desvio, desvios nas barras de eleição, média de recuperação no E6+E7, "líder (sorteado)", fluxo da escrita legível.

**Não alterado:** na demo do E3, o watch fica no etcd3 e a leitura no etcd2 (no experimento E3 é o contrário); não muda o resultado.

---

## 2026-10-28 (quarta), sessão 12: revisão contra os critérios e passagem de contexto (David + Claude Code, máquina do David)

**Feito:** revisão do repositório em `69d29ed` contra `docs/criterios-avaliacao.md` e `CHECKLIST.md`; `scripts/revisar.py` em 95 de 98. Gerado um documento local (não versionado) com orientações para continuar relatório e slides em outro chat.

**Achados:** `experimentos/E9-zookeeper/README.md` (linha 22) ainda marca os scripts kazoo como pendentes; as 3 medições de rodada única (E8 `stop`, E9-E7 com 5000 escritas) deveriam ser chamadas de "contraste" no texto.

**Pendente hoje:** entrega no AVA; acesso do professor ao repositório; revisão dos slides; ensaio cronometrado; treino da arguição; nome completo do David na capa.

---

## 2026-10-27/28 (terça para quarta), sessão 11: gravação, slides e montagem do relatório (Samuel + Claude Code, máquina do Samuel)

**Feito:**
- Pasta-mãe renomeada para `SISTEMAS_DISTRIBUIDOS_M2`; clusters recriados do zero e validados no caminho novo.
- `seminario/demo.sh` refeito para a gravação: cada execução grava valores únicos (com a hora), mostra o valor na cópia local de cada nó antes e depois, mede os tempos pelo mesmo método dos experimentos (`docker events` + observador na rede de clientes) e termina com um quadro RESUMO. O termo do RESUMO é lido direto do líder antigo e do novo (o observador às vezes lia um membro ainda não atualizado, o mesmo artefato do "3 → 3" do E5).
- Vídeo das demos gravado pelo Samuel (fora do repositório: 94 MB). Roteiro de fala em `seminario/roteiro-demos.md`.
- Slides em esboço (11 slides nos 5 blocos do PDF, com notas do apresentador), fora do repositório.
- Mini-aula de estudo: `seminario/mini-aula.md` e `.pdf`.
- `scripts/gerar_pdf.py`: monta o relatório (capa, sumário e as 12 seções) em `relatorio/relatorio.pdf` (24 páginas) e converte a mini-aula. Retiradas do texto três notas internas (seções 6, 8 e 12).
- `docs/criterios-avaliacao.md` atualizado: estava sem status desde 24/10.

- Relatório revisado e aprovado pela dupla em 28/10. Os 5 links das referências foram abertos em 28/10 (acesso em 28 out. 2026): o da documentação do ZooKeeper estava quebrado (404) e foi corrigido; a S3 foi atualizada conforme a documentação atual do Kubernetes (leitura "mais recente" pode vir do cache do apiserver desde a 1.31).

**Pendente (ver `CHECKLIST.md`):** nome completo do David na capa; **acesso do professor ao repositório privado**; revisão dos slides (já com os prints das demos); ensaio e treino da arguição; entrega no AVA.

---

## 2026-10-26 (segunda), sessão 10: revisão do trabalho do Samuel (David + Claude Code, máquina do David)

**Feito:** revisão dos commits da sessão 9 (`0dc40dd` a `838a098`): previsões, execução, CSVs, análises, rascunho do relatório e roteiro das demos.

**Conclusões da revisão:**
- Previsões: a versão revisada (21:11) foi registrada antes da 1ª execução (21:18). David acompanhou em call e assume a versão como previsão da dupla; a versão anterior fica no histórico (`5196dea`) e o uso de IA está declarado em `docs/uso-ia.md`.
- Execução: todos os CSVs com `exit=0`; as duas correções de script do Samuel (E8 `elect` com sessão de 60 s; E9-E5 `makepath=True`) estão corretas.
- Ressalvas conferidas no texto: t0 dos eventos de rede atrasado (E6 README e seção 9), termo 3 → 3 na repetição 2 do E5, E7 bimodal (50 ms × cerca de 6,5 s).
- `scripts/revisar.py`: 92 de 98. Pendentes: 3 medições de contraste com 1 repetição (intencionais, o `stop` é só contraste), pendências nas seções 10, 11 e 12 (revisão da dupla e datas de acesso das referências).

**Próximo (27/10):** leitura e aprovação das análises e do relatório pela dupla; datas de acesso das referências; nome completo do David na capa; montar o PDF/DOCX; gravar os vídeos de contingência; slides. Docker Desktop na máquina do David para ensaiar a demo.

---

## 2026-10-26 (segunda), sessão 9: execução de E5–E8 e E9-E5..E8 (Samuel + Claude Code, máquina do Samuel)

**Feito:** os 8 `executar.sh` rodaram em sequência das 21:18 às 21:40 (Windows 11, Docker Engine 29.9.2), depois do registro das previsões (`5196dea`, `0dc40dd`). O E8 e o E9-E5 foram reexecutados com o script corrigido (21:41–21:50).

**Resultados principais** (n = 5, média ± desvio; CSVs em `resultados/2026-10-26_*`):
- E5: eleição após `docker kill` do líder 1,46 ± 0,18 s; após `docker stop` cerca de 9 ms (o etcd transfere a liderança antes de sair). Sem maioria: escrita e leitura linearizável com `context deadline exceeded`, serializável responde.
- E6: lado majoritário elege em 0,94 ± 0,24 s; o líder isolado fica sem líder (`etcdserver: no leader`), recusa escrita e linearizável; a serializável devolve o valor antigo.
- E7: reconexão + alcance do RAFT INDEX em cerca de 6,5 s em 4 de 5 repetições (uma em 50 ms); depois de reconectar, o alcance é imediato. Snapshot: o líder envia "merged snapshot" (701 kB) e o seguidor o restaura; `endpoint hashkv` igual nos 3.
- E8: revisão global crescente entre chaves; troca do `lock` 7,9 ± 1,5 s (TTL 10 s); troca do `elect` 57,2 ± 0,3 s (sessão de 60 s); com `docker stop`, cerca de 4 ms; fencing token recusa a gravação do detentor antigo.
- E9-E5: eleição após `kill` 0,38 ± 0,09 s; após `stop` 0,70 ± 0,09 s; época +1 a cada líder; sem maioria o servidor fica sem serviço e a sessão não abre.
- E9-E6: lado majoritário elege em 3,6 ± 0,3 s (mais lento que o etcd); líder isolado faz "Shutting down"; cliente com a lista dos 3 migra para outro servidor; cliente só com o líder perde a sessão.
- E9-E7: sincronização por DIFF em 5 de 5, 2,5 ± 0,7 s; com 5000 escritas, ainda DIFF, 6,7 s.
- E9-E8: troca da trava 7,9 s e da eleição 7,8 s (sessão de 10 s).

**Problemas e soluções:**
- E8: `etcdctl elect` não tem `--ttl` (o `lock` tem, padrão 10 s) e usa sessão de 60 s. A 1ª execução esperava só 40 s e não limpava a fila entre repetições; 4 de 5 repetições do `elect` falharam. Correção: espera de até 75 s e `del --prefix` da fila depois de cada repetição. A execução inválida foi descartada.
- E9-E5: o quadro de quórum deu `NoNodeError` em todas as operações, porque `/e9` não existia num ensemble recém-criado (na máquina do David existia desde o E9-E3). Correção: `makepath=True` em `e9_operacoes.py`. Os tempos de eleição da 1ª execução eram válidos, mas o experimento foi reexecutado inteiro. É um defeito de reprodutibilidade que só uma máquina limpa revelou (R1).
- E5: na repetição 2 do `kill` o CSV registra termo 3 → 3; o termo lido "depois" foi o de um membro ainda não atualizado. Citar na análise e na seção 9.

**Análises:** rascunhadas nos README de E5–E8 e E9-E5..E8 e em `comparacao.md` (pendente: leitura da dupla).

**Relatório:** rascunho das seções 2, 3, 5–11 e complementos de 4 e 12; `scripts/revisar.py` em 94 de 98 (pendentes: 3 medições de contraste com 1 repetição, datas de acesso das referências). Correção: o Docker Engine da máquina 2 é 29.9.2 (o 28.0.1 era a versão do cliente).

**Próximo:** revisão do relatório pela dupla; montar o PDF/DOCX; roteiro das demos e vídeos; slides.

---

## 2026-10-26 (segunda), sessão 8: scripts de E5–E8 e E9-E5..E8 (David + Claude Code)
**Feito:**
- Diagramas renderizados: `diagramas/topologia.png` e `diagramas/sequencia-escrita.png` (`diagramas/renderizar.sh`); a seção 4 agora cita a Figura 1.
- Scripts `executar.sh` de E5–E8 e E9-E5..E8 e ferramentas de medição escritos, **sem executar**. As previsões do Samuel entraram no commit `5196dea`, antes de qualquer execução.

**Decisões de procedimento** (tomadas antes da execução):
- Eleição medida tanto com `docker kill` (falha abrupta) quanto com `docker stop` (parada ordenada). No etcd, a parada ordenada pode transferir a liderança.
- O t0 vem do `docker events` (kill, disconnect, connect), no mesmo relógio dos contêineres. O fim é observado de dentro da rede de clientes, a cada 10 ms.
- No E8, cada competidor de `lock`/`elect` roda num contêiner leve próprio (64 MB), para que "parar o contêiner do detentor" seja literal.
- No E9-E6, entra um cliente com a lista dos 3 servidores, para testar a previsão 2 do Samuel.

**Pendente:** executar com o Docker Desktop ligado (cerca de 30 min no total); analisar; quadro comparativo do E9.

---

## 2026-10-26 (segunda), sessão 7: teste de reprodutibilidade R1 (Samuel + Claude Code)

**Feito:** Samuel aceitou o convite, clonou o repositório numa máquina que nunca tinha rodado o projeto (Windows 11, Docker Engine 29.9.2 / Docker Desktop, sem as imagens baixadas) e seguiu o README: `docker compose up -d` nos dois clusters e `scripts/validar.sh todos`.

**Resultado:** `VALIDAÇÃO OK (todos)`. etcd com 1 líder (etcd1), termo 2 e RAFT INDEX 53 igual nos 3 membros. ZK com 1 leader (zk3), 2 followers e zxid 0x100000004 (época 1) nos 3. Evidência: `docs/ambiente/evidencias/2026-10-26_2029_validacao_samuel.txt`.

**Problemas e soluções:**
- Os comandos do README colados no **PowerShell** falham (`&&` não existe no Windows PowerShell 5.1, e `source` não é comando). Funcionou chamando o bash do Git: `& "C:\Program Files\Git\bin\bash.exe" -c '...'`. O README já diz para usar Git Bash; vale citar no relatório (seção 4/9) como ponto de atenção para o professor no Windows.
- O cliente ZK precisa de ~20 s para instalar o kazoo; rodar o `validar.sh zk` logo depois do `up -d` pode falhar. Usamos `sleep 20` antes.

**Previsões E5–E8 e E9-E5..E8:** registradas (`5196dea`) e, ainda antes de qualquer execução, revisadas para coerência com a teoria e reduzidas ao formato do PDF (§4.2); o questionário foi removido (ver `docs/uso-ia.md`).

**Próximo:** scripts `executar.sh` de E5–E8 e E9-E5..E8; execução.

---

## 2026-10-25 (domingo), sessão 6: execução de E1–E4 e E9-E3/E4 (David + Claude Code)

**Feito:** E1, E2, E3, E4 (etcd) e E9-E3, E9-E4 (ZooKeeper) executados com as previsões já commitadas. O README de cada um traz a previsão × resultado. Placar das previsões da dupla:

| Experimento | Confirmadas | Erradas | Observação |
|---|---|---|---|
| E1 | 3 | 1 | |
| E2 | 2 | 2 | |
| E3 | 4 | 0 | |
| E4 | 3 | 1 | a previsão 4 errou |
| E9-E3 | 1 | 0 | 1 não observada (leitura antiga) |
| E9-E4 | 1 | 1 | servidor isolado não serve leitura |

**Resultados principais:**
- etcd: watch 6,4 ms; put no líder 3,3 ms; get linearizável 1,5–1,8 ms × serializável 0,7 ms.
- ZK: watch 5,9 ms; set no seguidor 7,0 ms; get local 1,0–1,5 ms × sync+get 3,3–3,9 ms; memória 83–133 MiB.
- Detalhes em `experimentos/*/README.md` e em `relatorio/notas/achados.md` (A5–A11).

**Problemas e soluções:**
- E1: `MSYS_NO_PATHCONV` quebrava os caminhos do compose → `caminho_host`; a execução inválida foi apagada e documentada.
- E2: o `etcdctl` rodava dentro do membro pausado → passou a rodar no líder; o E2 foi refeito.
- E9-E3: rótulos fixos no script → corrigidos; a execução foi refeita.
- E9-E4: o cliente kazoo travou sem prazo e o zk1 ficou isolado por cerca de 7 min → prazo por chamada e garantia de religar; a 1ª execução foi mantida como evidência (A9).

**Prints sugeridos:**
- linha do tempo do zk1 isolado (`E9-zookeeper/E4-consistencia/evidencias/2026-10-25_1323_seguidor_isolado.txt`);
- tabela de latência linearizável × serializável (E4).

**Próximo:**
- previsões de E5–E8 e E9-E5..E8 (questionário do Samuel);
- depois, os scripts e as execuções;
- diagramas PNG;
- quadro comparativo.

---

## 2026-10-25 (domingo), sessão 5: prazo real e histórico do Git (David + Claude Code)
- Prazo real informado pelo David: **relatório e seminário em 28/10/2026** (o PDF diz 28/11). Plano de emergência em `PLANO-28-10.md`; perguntas-guia inseridas na previsão de todos os experimentos.
- Histórico do Git reescrito a pedido do David, para remover a linha `Co-Authored-By: Claude` dos 9 commits. O conteúdo e as datas não mudaram (`git diff` entre o histórico antigo e o novo: vazio); só os hashes mudaram. As referências foram atualizadas: a previsão do E0 agora é o commit `efcd7c5` (11:58), e o commit inicial é `57fe090`. O uso de IA continua declarado em `docs/uso-ia.md`.

## 2026-10-25 (domingo), sessão 4: ensaio E0 e guia do trabalho (David + Claude Code)
- A pedido do David, o ciclo completo foi simulado num **E0 (ensaio fora da bateria)**, para não contaminar a previsão do E1. O tema foi o limite de tamanho de requisição e a latência em função do tamanho. A previsão foi escrita pelo assistente e registrada no commit `efcd7c5` (11:58), antes da execução (11:59).
- Resultados: P1 e P2 (limites) confirmados; P3 parcialmente errada (1 KiB no etcd deu 10,7 ms, não os 4 previstos; o ZK não foi mais lento). Houve um valor atípico no ZK, 149 ms, mantido na tabela. Detalhes em `experimentos/E0-ensaio/README.md`; gerou o achado A5 (Q14).
- Criado `docs/guia-do-trabalho.md`: visão geral, Raft × ZAB, ciclo do experimento e plano semanal até 28/11.
- `relatorio/09-limitacoes.md` atualizado: overhead do docker exec mitigado; CSVs com timestamp em UTC.

## 2026-10-25 (domingo), sessão 3: ferramenta de latência e papéis (David + Claude Code)
- Docker Desktop iniciado. Os clusters voltaram com `up -d` e `validar.sh todos` deu OK. Depois do reinício, o etcd está no termo 3 (líder etcd1) e o ZK na época 3 (líder zk3): cada reinício gera uma nova eleição.
- K5 corrigido em `docs/criterios-avaliacao.md` (Samuel convidado, aguardando aceite).
- **Achado A3 resolvido.** Criados o serviço `etcd-cliente` (python:3.12-alpine, 172.31.0.100, 128 MB), `etcd/cliente/latencia.py` (API HTTP/JSON, conexão persistente), `zookeeper/cliente/latencia.py` (kazoo) e `scripts/latencia.sh`. Resultados do teste da ferramenta (não são experimento):
  - etcd: put em seguidor 3,77 ± 0,47 ms; get linearizável 1,67 ± 0,25 ms; get serializável 0,86 ± 0,10 ms (n = 10 cada);
  - ZK: set 7,15 ± 1,12 ms; get local 1,44 ± 0,22 ms; sync + get 2,73 ± 0,28 ms (n = 10);
  - o mesmo put via `docker exec` levou 407,2 ± 35,7 ms (n = 5).
  - Evidência: `docs/ambiente/evidencias/2026-10-25_1035_teste_ferramenta_latencia.txt`. Os CSVs de teste foram apagados de `resultados/`, para não serem contados como medição.
- Rascunho da divisão de papéis em `docs/equipe.md`, por eixo: David com replicação e consistência (E1–E4 e E9-E3/E4); Samuel com falhas e coordenação (E5–E8 e E9-E5..E8). Falta o Samuel concordar.

**Onde paramos / retomar daqui**
1. A dupla escreve a previsão do E1 no README (o Claude orientou com a teoria) e faz commit. Depois o Claude cria o `executar.sh`, roda o E1 e faz o diagrama de topologia.
2. O Samuel aceita o convite, roda `validar.sh todos` e confirma ou ajusta `docs/equipe.md`.
3. Enviar as dúvidas ao professor.
4. O A1 continua esperando formalização no E4.

## 2026-10-24 (sábado), sessão 2: repositório remoto (David + Claude Code)
- Repositório privado criado por David: https://github.com/DavidSmithSouzak10/sd-t2-etcd-zookeeper. Visibilidade privada confirmada (a API anônima responde 404).
- Remoto `origin` ligado e push da `main` (commit inicial `57fe090`).
- GitHub CLI 2.103.2 instalado (winget); `gh auth login` ainda não feito, porque o push usou as credenciais do Git Credential Manager.
- Samuel convidado como colaborador (por David, pelo site) e instruções de clone/teste enviadas a ele.

**Onde paramos / retomar daqui**
1. Samuel aceita o convite, clona e roda `scripts/validar.sh todos`. Ele salva a evidência com `evidencia docs/ambiente validacao_samuel -- bash scripts/validar.sh todos`, faz commit e push. Isso fecha o R1.
2. Preencher `docs/equipe.md` (divisão de papéis D/S) e a coluna "Resp." do CHECKLIST.
3. Enviar ao professor as 6 dúvidas de `docs/duvidas-professor.md`; a mais importante é sobre o kit.
4. Escrever a **previsão do E1** (a dupla escreve, antes de rodar). Depois o Claude cria o `executar.sh` do E1 e o diagrama de topologia.
5. Antes do E3: decidir como medir latência sem o overhead do `docker exec` (achado A3).
6. Formalizar o achado A1 (RAFT INDEX × leituras) no E4, com previsão.

## 2026-10-24 (sábado), sessão 1: montagem do ambiente (David + Claude Code)

**Feito**
- Repositório criado (git local, branch `main`) com a estrutura do CLAUDE.md.
- `etcd/docker-compose.yml` com 3 membros (etcd 3.5.17), redes `interna` 172.30.0.0/24 e `clientes` 172.31.0.0/24, `mem_limit` de 256 MB e healthcheck.
- `zookeeper/docker-compose.yml` com 3 servidores (ZooKeeper 3.9.6) e um cliente Python com kazoo 2.10.0, nas redes 172.32/172.33.
- Scripts: `validar.sh`, `medir.sh`, `estatistica.py`, `particionar.sh`, `lib.sh` e `revisar.py` (critérios automáticos).
- Modelos dos READMEs de E1–E9, estrutura do relatório (`relatorio/01..12`) e lista de critérios (`docs/criterios-avaliacao.md`).

**Resultados**
- Os dois clusters sobem e passam no `validar.sh`:
  - etcd: líder = etcd2, termo 2, RAFT INDEX igual nos 3;
  - ZooKeeper: líder = zk2, época 1, zxid igual nos 3.
  - Evidência: `docs/ambiente/evidencias/2026-10-24_161*_validacao_*.txt`.
- Memória em repouso: etcd de 23,7 a 29,7 MB por membro; ZK de 46,8 a 55,7 MB por servidor; cliente com 3,9 MB. Tudo muito abaixo dos limites. Evidência: `docs/ambiente/evidencias/2026-10-24_1614_memoria_repouso.txt`.
- Teste do `medir.sh` com 5 execuções de `get` via `docker exec`: 256,6 ± 37,2 ms. Esse número é quase todo **overhead do docker exec**, não latência do etcd. O CSV de teste foi descartado (não é experimento).

**Problemas e soluções**
1. *Falso negativo na validação (RAFT INDEX diferente):*
   - Causa: os membros eram consultados um de cada vez, e o índice avança entre as consultas.
   - Solução: os 3 passam a ser lidos numa única chamada, com até 3 tentativas.
   - Daí veio o achado A1 (ver `achados.md`).
2. *zxid diferente logo após a eleição do ZK:*
   - Causa: um seguidor sem nenhuma transação reporta zxid 0x0.
   - Solução: o validador agora faz uma escrita de teste antes de comparar.
3. *Falso erro no zkCli:*
   - O log do zkCli sempre contém "unknown error" (linha do SASL), mesmo quando a operação dá certo.
   - Solução: usar o código de saída (o zkCli sai com 1 em caso de falha).
4. *Git Bash no Windows:*
   - Converte `/config/x` em `C:/Program Files/Git/...` e imprime acentos errados no Python.
   - Solução: `MSYS_NO_PATHCONV=1`, `cygpath` e `PYTHONIOENCODING=utf-8` em `lib.sh`.
5. *Imagem flutuante:* `zookeeper:3.9` resolvia para 3.9.6. Agora a tag está fixada em `3.9.6`, por reprodutibilidade.

**Prints sugeridos:** ver `prints.md` (P1, P2).

**Próximos passos**
- Criar o repositório privado no GitHub e dar acesso ao Samuel.
- Preencher `docs/equipe.md`.
- Escrever a previsão do E1 e só depois rodá-lo.
- Antes do E3, decidir como medir latência sem o overhead do `docker exec`.
