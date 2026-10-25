# E9/E4 — Consistência no ZooKeeper

> Roteiro: PDF §9.5, ênfase D. Rodar `scripts/validar.sh zk` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Repetir o E4 da bateria comum no ensemble ZooKeeper. Comparar com E4 do etcd (serializável × linearizável).

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: 2026-10-25 12:57 — respostas de David a um questionário de múltipla escolha; texto montado pelo Claude Code a partir das escolhas (ver `docs/uso-ia.md`)
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. Uma leitura local num seguidor pode devolver valor antigo? Em que situação?
> 2. O `sync` antes da leitura resolve? Quanto custa a mais?
> 3. Um servidor isolado do ensemble ainda responde leituras? E escritas? (`readonlymode` está desligado)

1. **`sync` + get:** esperamos que **garanta o valor novo, mas seja mais lento** (talvez o dobro do tempo), porque o `sync` faz o servidor alcançar o líder antes de ler. É o equivalente do ZooKeeper à leitura linearizável do etcd.
2. **Servidor isolado (sem maioria):** esperamos que ele **continue respondendo leituras com a cópia local, mas recuse escritas**.

## Procedimento
Papéis nesta execução: líder **zk3**; seguidor observado e isolado: **zk1**.

1. `scripts/latencia.sh zk`: `get` local × `sync` + `get` no seguidor zk1, 20 repetições cada.
2. `e9_isolado.py`, com um cliente kazoo ligado **só** ao zk1 e outro ao líder (o lado majoritário):
   - a cada 0,5 s, faz no zk1 um get local, um sync+get e uma escrita, cada um com prazo de 2 s;
   - cerca de 3 s depois do início, o host isola o zk1 da rede interna (`particionar.sh isolar zk1`), mas o zk1 continua na rede de clientes;
   - em t = 4 s, o lado majoritário grava `NOVO` sobre `ANTIGO`;
   - um listener registra cada mudança de estado da sessão (CONNECTED, SUSPENDED, LOST);
   - o `srvr` dos 3 servidores é coletado durante o isolamento;
   - no fim, religa com o mesmo IP e espera o zk1 voltar como `follower`.
3. `validar.sh zk`.

Script reproduzível: `executar.sh`. Execução válida: 25/10/2026, 13:23.

> **1ª execução (13:16), mantida como evidência.** Ela travou: o cliente fazia chamadas síncronas sem prazo, e depois do SUSPENDED o kazoo **enfileira os pedidos e espera a reconexão indefinidamente**. Como o `executar.sh` esperava o cliente terminar para religar, o zk1 ficou isolado por cerca de 7 min, até o processo ser encerrado à mão. Foram feitas duas correções:
> - prazo por chamada (`*_async().get(timeout)`);
> - uma garantia no `executar.sh`, que encerra o cliente e religa o nó em no máximo 40 s.
>
> As latências e o `srvr` dessa execução são válidos e confirmam os da 2ª.

## Evidências
| Arquivo | O que mostra |
|---|---|
| `evidencias/2026-10-25_1323_latencia_local_x_sync.txt` | média e desvio do get local × sync+get no zk1 |
| `evidencias/2026-10-25_1323_seguidor_isolado.txt` | linha do tempo do cliente no zk1 isolado, `srvr` durante o isolamento e volta |
| `evidencias/2026-10-25_1324_validacao_final.txt` | ensemble saudável, mesmo zxid |
| `evidencias/2026-10-25_1326_zoo_cfg_zk1.txt` | configuração efetiva: `tickTime=2000`, `syncLimit=2`, sem `readonlymode` |
| `evidencias/2026-10-25_1316_*` e `..._1323_validacao_final.txt` | 1ª execução (a validação final dela saiu às 13:23, depois de religar): latências válidas; o cliente travou depois do SUSPENDED (ver nota acima) |

Horários: as linhas do cliente (`16:23:…`) estão em UTC, que é o relógio do contêiner. As linhas do host (`13:23:…`) estão no horário de Brasília (UTC−3). É o mesmo relógio físico (ver seção 9).

## Medições (R7)
| Medição | n | média (ms) | desvio padrão | mín | máx | falhas |
|---|---|---|---|---|---|---|
| get local no seguidor zk1 (13:23) | 20 | 1,03 | 0,22 | 0,70 | 1,42 | 0 |
| sync + get no zk1 (13:23) | 20 | 3,25 | 0,63 | 2,21 | 4,68 | 0 |
| get local no zk1 (1ª execução, 13:16) | 20 | 1,83 | 0,34 | 1,51 | 2,88 | 0 |
| sync + get no zk1 (1ª execução, 13:16) | 20 | 6,67 | 1,03 | 5,36 | 9,90 | 0 |

CSVs: `resultados/2026-10-25_1323_e9e4_*.csv` e `resultados/2026-10-25_1316_e9e4_*.csv`.

**Linha do tempo do isolamento (13:23, UTC no cliente):**

| Instante | Evento |
|---|---|
| 16:23:55,0 – 57,6 | 6 rodadas normais: get local, sync+get e escrita respondem (`ANTIGO`, `OK`) |
| 16:23:58,06 | zk1 desconectado da rede interna |
| 16:24:01,64 (+3,6 s) | sessão do cliente vai para **SUSPENDED**. Na mesma rodada: get local = `ANTIGO` (ainda respondeu); sync+get = timeout; escrita = `ConnectionLoss` |
| 16:24:02,15 | lado majoritário grava `NOVO` **com sucesso** |
| durante | `srvr`: zk1 **sem serviço** (não responde nem ao comando de 4 letras); zk2 seguidor e zk3 líder, zxid avançando |
| 16:24:08 – 27 | 4 rodadas: get local, sync+get e escrita dão **timeout**. O cliente **nunca** recebeu `NOVO` nem `ANTIGO` depois da escrita da maioria |
| 16:24:28,2 | sessão **LOST** (expirou) |
| 13:24:29,8 → 13:24:53,1 | religado; o zk1 volta como `follower` com o mesmo zxid dos outros em **cerca de 23 s** (pelos horários; o "~13 s" impresso pelo script subestima porque conta só as iterações do laço) |

## Análise: previsão × resultado × teoria × etcd

| # | Previsão | Resultado | Situação |
|---|---|---|---|
| 1 | `sync` + get garante o valor novo e é mais lento (cerca de 2×) | 3,25 contra 1,03 ms (3,2×); E3: 3,89 contra 1,53 ms (2,5×); 1ª execução: 3,6×. Sob isolamento, o `sync` **falhou** (timeout) em vez de devolver dado velho | ✅ confirmada (mais lento; nunca devolveu valor antigo) |
| 2 | O servidor isolado continua respondendo leituras com a cópia local e recusa escritas | Escrita recusada ✅. Leitura local respondida **uma única vez**, nos primeiros cerca de 3,6 s; depois disso o servidor **parou de atender** clientes (`sem serviço`) e todas as leituras deram timeout | ❌ errada na parte das leituras |

**Discussão**
1. **Por que a previsão 2 errou.** Sem `readonlymode.enabled=true`, que não aparece no `zoo.cfg`, um servidor que perde contato com o líder:
   - sai do papel de seguidor;
   - volta ao estado **LOOKING** (procurando líder);
   - **fecha as sessões de clientes** e deixa de atender.

   Quem ficou sem maioria não serve nada. O ZooKeeper tem um modo *read-only* que faria a previsão da dupla virar verdade, mas ele precisa ser ligado explicitamente. É uma **escolha CP**: no lado minoritário, recusar tudo em vez de servir dado possivelmente velho. Isso alimenta a Q11; o E9-E6 vai testar o mesmo com o **líder** isolado.
2. **A janela de cerca de 3,6 s.** Entre o isolamento e o SUSPENDED, o zk1 ainda se considerava seguidor e respondeu uma leitura local com `ANTIGO`. Naquela hora a maioria ainda não tinha gravado `NOVO`, então a resposta não estava errada, mas mostra a janela em que uma **leitura local num seguidor isolado é servida sem consultar ninguém**. O tamanho é compatível com o limite de sincronização configurado: `tickTime` 2000 ms × `syncLimit` 2 = 4 s (evidência `zoo_cfg_zk1`). A relação exata é uma hipótese, a confirmar no E9-E6.

   Se a maioria tivesse escrito dentro dessa janela, o cliente do zk1 poderia ler o valor antigo **depois** de a escrita já estar confirmada. Essa é a leitura desatualizada que o E9-E3 não conseguiu expor e que a garantia do ZK permite. Isso fica **pendente**: exige escrever na maioria antes de 3 s.
3. **Comparação com o etcd (E4).** Com um seguidor isolado no etcd:
   - leitura linearizável: falha por timeout;
   - leitura **serializável**: **continua respondendo** o valor antigo indefinidamente;
   - escrita: falha.

   No ZooKeeper o servidor isolado deixa de responder **qualquer** leitura depois de cerca de 3,6 s. Ou seja, a leitura "relaxada" do etcd pode ficar velha por tempo indeterminado durante uma partição, e a do ZK fica velha só pelo tempo até o servidor perceber que perdeu o líder. A diferença está no **ponto de partida**:
   - o etcd é linearizável por padrão e serializável sob pedido;
   - o ZK é local por padrão e usa `sync` sob pedido.
4. **Para o cliente, timeout é indeterminado (de novo).** Como no E2, as escritas do cliente no zk1 deram `ConnectionLoss` ou timeout, e o cliente não tem como saber, só por isso, se a operação foi aplicada. Aqui não foram, porque o zk1 não tinha líder. A receita do ZK para isso é escrever operações **idempotentes** ou conferir o `version` depois.
5. **Ferramenta: o kazoo esconde a falha.** O comportamento padrão do kazoo (achado da 1ª execução) é **esperar a reconexão em silêncio**. Uma aplicação sem prazo nas chamadas fica pendurada por quanto tempo durar a partição. É o mesmo tipo de armadilha da lista de endpoints do etcd, que "esconde falhas" (CLAUDE.md §6).
6. **Volta depois de religar: cerca de 23 s, contra cerca de 1 s na 1ª execução.** O tempo variou muito. Hipótese: enquanto isolado, o zk1 fica em LOOKING mandando notificações de eleição com **intervalo crescente** (o `FastLeaderElection` dobra o intervalo até um teto). Ao religar, ele só descobre o líder na próxima notificação. Isso será medido 5 vezes no E9-E7.

## Questões que este experimento sustenta
- **Q6:** sequencial × linearizável, e o `sync`.
- **Q10:** detecção de falha por *timeout* de sessão (SUSPENDED → LOST).
- **Q11:** o lado minoritário recusa tudo (CP).
- **S3:** `sync` × ReadIndex; custo medido.
- **Quadro do E9:** leitura padrão, mecanismo de leitura atual, comportamento do isolado.
- **Seção 9:** relógio compartilhado; fuso do contêiner × host.
