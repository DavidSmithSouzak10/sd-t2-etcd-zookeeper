# E9/E6 — Partição de rede no ZooKeeper

> Roteiro: PDF §9.5, ênfase D. Rodar `scripts/validar.sh zk` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Repetir o E6 da bateria comum no ensemble ZooKeeper. Conclusão C × A comparada ao E6 do etcd.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Registrada em 2026-10-26 21:11, antes de qualquer execução (ver `docs/uso-ia.md`).

- **Partição:** esperamos que o líder isolado perca o quórum, deixe de ser líder (LOOKING) e derrube os clientes, que o kazoo reconecta em outro servidor; e que o lado majoritário eleja um novo líder, com época maior, em poucos segundos. Mesma escolha do etcd: consistência.

## Procedimento
Desconectar o líder da rede interna (`scripts/particionar.sh isolar zkN`); estado LOOKING no isolado; o que um cliente conectado a ele vê (desconexão, sessão expirada).

Script reproduzível: [`executar.sh`](executar.sh) (da raiz). Clientes: [`zookeeper/cliente/e9_eleicao.py`](../../../zookeeper/cliente/e9_eleicao.py) e [`e9_isolado.py`](../../../zookeeper/cliente/e9_isolado.py). Início = evento `disconnect`; fim = primeiro servidor do lado majoritário em `Mode: leader`.

## Evidências
Executado em 26/10/2026 na máquina do Samuel (Windows 11, Docker Engine 29.9.2), depois do registro da previsão (`5196dea`, revisada em `0dc40dd`). Horário: 21:31–21:33.

| Arquivo | O que mostra |
|---|---|
| `evidencias/2026-10-26_2131_eleicao_lado_majoritario.txt` | 5 isolamentos do líder: tempo até o lado majoritário eleger outro, épocas |
| `evidencias/2026-10-26_2132_linha_do_tempo_so_lider.txt` | cliente que conhece só o líder isolado × `srvr` dos 3; log do isolado |
| `evidencias/2026-10-26_2133_linha_do_tempo_lista.txt` | cliente com a lista dos 3 servidores, começando pelo líder isolado |
| `evidencias/2026-10-26_2133_validacao_final.txt` | ensemble saudável depois de religar |

## Medições (5 repetições, R7)
| Medição | n | média (ms) | desvio padrão | mín | máx | falhas |
|---|---|---|---|---|---|---|
| eleição do lado majoritário após isolar o líder | 5 | 3596,9 | 289,3 | 3150,6 | 3867,2 | 0 |

CSV: `resultados/2026-10-26_2131_e9e6_eleicao_particao.csv`.

**Linha do tempo**

| Instante | Cliente só com o líder isolado (zk2) | Cliente com a lista dos 3 (isolado = zk3) |
|---|---|---|
| isolamento | 21:32:32,6 | 21:33:13,5 |
| +2 s | escrita: timeout; leitura local ainda `ANTIGO` | escrita: timeout; leitura local ainda `ANTIGO` |
| +3,7 s / +5,1 s | sessão SUSPENDED; log do isolado: `Shutting down`; `srvr`: isolado sem serviço, novo líder com época 18 e contador 0 | sessão SUSPENDED e, 3 ms depois, CONNECTED em zk1 |
| depois | a maioria grava `NOVO`; este cliente só recebe timeout e a sessão termina LOST | escrita OK; lê `NOVO` |

## Análise: previsão × resultado × teoria

| # | Previsão | Resultado | Situação |
|---|---|---|---|
| 1 | O isolado perde o quórum, deixa de ser líder e derruba os clientes; o kazoo reconecta em outro servidor; a maioria elege outro líder, com época maior, em poucos segundos | isolado em `Shutting down` e sem serviço; o cliente com a lista migrou e o cliente só com o isolado perdeu a sessão; eleição em 3,6 ± 0,3 s, época +1 | ✅ confirmada |

**Discussão**
1. **Por que 3,6 s, contra 0,94 s no etcd.** Numa partição a conexão não se fecha, e vale o timeout. No ZooKeeper, o seguidor desiste do líder depois de `syncLimit × tickTime` = 2 × 2000 ms = 4 s sem resposta (padrões da imagem oficial `zookeeper:3.9.6`, conferidos em `ZOO_SYNC_LIMIT` e `ZOO_TICK_TIME`); no etcd, o *election timeout* é de 1 a 2 s. A mesma ressalva do E6 vale aqui: o evento `disconnect` pode ser registrado com atraso.
2. **Janela de leitura desatualizada.** Nos primeiros 2 a 4 s, antes de perceber o isolamento, o servidor isolado ainda respondeu a leitura local com o valor antigo, mas recusou a escrita. É a mesma janela observada no E9-E4 e a diferença central para a leitura linearizável do etcd.
3. **A lista de servidores dá disponibilidade ao cliente.** Quem só conhecia o isolado ficou sem serviço. Quem tinha a lista migrou em 3 ms depois de perceber a suspensão. No etcd vale o mesmo, e é por isso que os experimentos usam endpoint único: a lista esconde a falha.
4. **C × A (Q11).** O ZooKeeper também escolhe consistência: o lado minoritário para de atender. Ele é ainda mais restritivo que o etcd, porque depois de perceber o isolamento não serve nem leitura.

## Questões que este experimento sustenta
Q11 (C × A), Q10 (detecção por timeout), Q6 (leitura local desatualizada).
