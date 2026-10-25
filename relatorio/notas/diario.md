# Diário de bordo

Uma entrada por sessão de trabalho, a mais recente no topo. Registrar:
- o que foi feito e quem fez;
- os resultados, com o caminho da evidência;
- os problemas e como foram resolvidos;
- os prints sugeridos;
- o que fica para depois.

Este diário é a fonte das seções 4 (ambiente), 5 (experimentos) e 9 (limitações) do relatório.

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
