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
| Arquivo | O que mostra |
|---|---|
| _preencher após executar_ | |

## Medições (5 repetições, R7)
_preencher após executar (tabela do `estatistica.py`)_

## Análise: previsão × resultado × teoria
_preencher após executar_
