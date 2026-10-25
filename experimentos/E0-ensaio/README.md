# E0: Ensaio do ciclo experimental (limite e custo do tamanho da requisição)

> ⚠️ **Não faz parte da bateria avaliada (E1–E9).** É um ensaio para a dupla ver o ciclo completo: previsão, commit, execução, evidência, medição e análise.
> **A previsão abaixo foi escrita pelo Claude Code (assistente), não pela dupla**, e está registrada em `docs/uso-ia.md`.
> O resultado pode ser citado na **Q14** (limitações do etcd e do ZooKeeper) como evidência complementar, sempre com essa ressalva.

## Objetivo
1. Descobrir o maior valor que cada sistema aceita numa única escrita e o que o cliente recebe quando o limite é ultrapassado.
2. Medir como a latência da escrita cresce com o tamanho do valor (1 KiB, 100 KiB e 512 KiB; 5 repetições cada).

## Previsão (escrita pelo assistente ANTES de executar; não editar depois)
> Data/hora do registro: 2026-10-25, antes da primeira execução (o commit desta previsão vem antes do commit das evidências)

**P1. Limite do etcd.** O etcd aceita requisições de até **1,5 MiB** (1.572.864 bytes); fonte: `etcd --help`, flag `--max-request-bytes`, valor padrão. Previsão:
- valores de 1,0 e 1,4 MiB são aceitos;
- valores de 1,6 e 2,0 MiB são recusados com um erro explícito do servidor (algo como "request is too large");
- o cluster continua saudável depois das recusas.

Motivo do limite: no Raft, cada escrita vira uma entrada de log que o líder precisa enviar a todos os seguidores e gravar em disco antes do commit. Entradas grandes atrasam a replicação e os próprios heartbeats.

**P2. Limite do ZooKeeper.** O limite é `jute.maxbuffer`, com padrão de cerca de **1 MB** (0xfffff = 1.048.575 bytes); fonte: Guia do Administrador do ZooKeeper. Previsão:
- 900 KB é aceito;
- 1,1 MB e 2,0 MB são recusados.

Ao contrário do etcd, esperamos que a recusa **não** chegue como um erro claro: o servidor deve fechar a conexão, e o cliente verá uma perda de conexão (`ConnectionLoss`). O motivo é que o pacote acima do limite é tratado como inválido na camada de rede, antes de virar uma operação.

**P3. Latência × tamanho.** A latência da escrita cresce com o tamanho, porque mais bytes precisam ir do cliente ao líder, do líder aos seguidores e para o disco (fsync). Previsão para o etcd:
- 1 KiB fica perto do put curto medido no teste da ferramenta (cerca de 4 ms);
- 512 KiB fica na casa de **dezenas de ms**;
- o crescimento é aproximadamente linear acima de cerca de 100 KiB, quando a transferência passa a dominar o custo fixo.

Para o ZooKeeper, o comportamento deve ser parecido, mas com valores absolutos maiores, porque no teste da ferramenta o set curto já foi cerca de 2× mais lento.

## Procedimento
Script reproduzível: [`executar.sh`](executar.sh), rodado a partir da raiz do repositório.
1. `scripts/validar.sh todos`. Se falhar, o script para.
2. Registra quem é o líder (etcd) e o modo de cada servidor (ZK).
3. Testa o limite: escreve valores de tamanho crescente. Cada tentativa usa uma conexão nova e registra se foi aceita e qual erro veio.
4. Mede a latência: `scripts/latencia.sh` com 5 repetições para cada tamanho (1 KiB, 100 KiB, 512 KiB), no etcd e no ZK.
5. Roda `scripts/validar.sh todos` de novo: o cluster precisa continuar saudável.

## Evidências
Executado em 25/10/2026 às 11:59, depois do commit da previsão (`efcd7c5`, 11:58).

| Arquivo | O que mostra |
|---|---|
| `evidencias/2026-10-25_1159_estado_inicial.txt` | líder etcd1, termo 3; ZK com líder zk3, época 3 |
| `evidencias/2026-10-25_1159_limite_etcd.txt` | 1,0 e 1,4 MiB aceitos; 1,6 MiB → HTTP 400 `request is too large`; 2,0 MiB → HTTP 429 `grpc: received message larger than max (2097169 vs. 2097152)` |
| `evidencias/2026-10-25_1159_limite_zk.txt` | 900 KB aceito; 1,1 MB e 2,0 MB → `ConnectionLoss` (sem mensagem de erro) |
| `evidencias/2026-10-25_1159_latencia_tamanho.txt` | tabelas de latência × tamanho |
| `evidencias/2026-10-25_1159_validacao_final.txt` | os dois clusters continuam saudáveis depois das recusas |

## Medições (5 repetições, R7)
Escrita num seguidor (etcd2 / zk2), medida dentro do contêiner cliente (`scripts/latencia.sh`). CSVs: `resultados/2026-10-25_1159_e0_*.csv`.

| Tamanho do valor | etcd put (ms) | ZooKeeper set (ms) |
|---|---|---|
| 1 KiB | 10,73 ± 3,89 | 7,47 ± 1,54 |
| 100 KiB | 13,38 ± 2,23 | 40,71 ± 60,73 (*) |
| 512 KiB | 36,43 ± 6,03 | 25,62 ± 5,33 |

(*) Uma repetição levou 149,2 ms; as outras 4 ficaram entre 10,9 e 18,9 ms, com média de 13,6 ms. Ver a análise.

## Análise: previsão × resultado × teoria

| Previsão | Resultado | Situação |
|---|---|---|
| P1: etcd aceita até 1,5 MiB e recusa acima com erro explícito | 1,4 MiB aceito, 1,6 MiB recusado com `request is too large` | ✅ confirmada |
| P1 (complemento) | Com 2,0 MiB o erro foi **outro**, de **outra camada**: o limite de mensagem do gRPC (2 MiB), atingido antes de a requisição chegar ao etcd | ➕ não previsto |
| P2: ZK aceita cerca de 1 MB e recusa acima com `ConnectionLoss` | 900 KB aceito, 1,1 e 2,0 MB → `ConnectionLoss` | ✅ confirmada |
| P3: a latência cresce com o tamanho | etcd: 10,7 → 13,4 → 36,4 ms | ✅ confirmada |
| P3: 1 KiB no etcd perto de 4 ms | 10,7 ± 3,9 ms | ❌ errada |
| P3: ZK mais lento que o etcd | ZK foi **mais rápido** em 1 KiB e em 512 KiB | ❌ errada |

**Discussão**
1. **O limite existe por causa da replicação.** No Raft (e no ZAB), toda escrita é uma entrada de log que o líder envia a cada seguidor e que precisa ser persistida pela maioria antes do commit. O sistema foi feito para guardar **metadados pequenos** (configuração, descoberta, travas), não arquivos. Isso apoia a Q14.
2. **A forma da recusa difere, e isso importa para quem usa.**
   - O etcd devolve um erro de aplicação claro. Um cliente pode distinguir "requisição grande demais" de "servidor fora do ar".
   - O ZooKeeper derruba a conexão. Para o cliente, é indistinguível de uma falha de rede, e um cliente que repete operações automaticamente pode ficar repetindo uma requisição que nunca vai passar.
3. **Duas camadas de limite no etcd.** O caminho cliente → gateway HTTP → gRPC tem um limite próprio de 2 MiB, acima do `--max-request-bytes`.
4. **Por que 1 KiB foi mais lento que o previsto.** No teste da ferramenta, com valor de 3 bytes, o put deu 3,8 ms. Aqui, com 1 KiB, deu 10,7 ms e desvio alto (3,9 ms). Hipótese, **não verificada**: a medição veio logo depois de escrever 2,4 MiB no banco (testes de limite), e o etcd ainda estava gravando e sincronizando o disco (fsync). Para separar os efeitos, seria preciso repetir com n maior e uma pausa antes. Isso mostra por que o R7 pede repetições: com n = 5, um efeito transitório pesa muito na média.
5. **Valores atípicos no ZooKeeper.** Uma repetição de 149 ms em 100 KiB elevou o desvio para 60 ms. Causas plausíveis, **não verificadas**: pausa do coletor de lixo da JVM (heap de 128 MB, alocando valores de 100 KiB) ou um fsync mais lento. Pela regra do trabalho, o valor **não foi descartado**: está na tabela, sinalizado.
6. **Por que o ZK foi mais rápido.** A previsão generalizou um único dado (o set curto do teste da ferramenta) e errou. Com n = 5 e desvios desse tamanho, não dá para afirmar qual dos dois é mais rápido; as faixas mín–máx se sobrepõem. A comparação de verdade fica para o E3 e o E9-E3, com n maior.

**Lição para a dupla:** a previsão errada **não tira nota**. O que conta é explicar o erro com teoria e com evidência, como nos itens 4 a 6.
