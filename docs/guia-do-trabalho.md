# Guia do trabalho: o que é, como funciona e como avançar

Para David e Samuel. Leitura de 10 minutos. As regras detalhadas estão no `CLAUDE.md`, e a lista do que é avaliado em `docs/criterios-avaliacao.md`.

## 1. O trabalho em uma frase
Subir um **serviço de coordenação replicado**, o etcd, com 3 nós; **provocar** nele as situações clássicas de sistemas distribuídos (falha, partição, recuperação, eleição); **medir** o que acontece; e **comparar** com o ZooKeeper, que resolve o mesmo problema com outro protocolo.

## 2. Que problema esses sistemas resolvem
Vários programas espalhados precisam **concordar** sobre algumas informações: quem é o líder, qual é a configuração atual, quem está com a trava. Se cada um guarda a sua cópia, as cópias divergem. etcd e ZooKeeper guardam esses dados pequenos em **3 ou mais réplicas idênticas**, que **só aceitam uma escrita quando a maioria concorda**. Por isso:
- um nó pode cair sem que nada se perca (2 de 3 ainda formam maioria);
- se cair a maioria, o sistema **para de aceitar escritas** em vez de arriscar respostas inconsistentes. Essa escolha é a "C" do CAP, que a Q11 pede para demonstrar.

Exemplo real: o Kubernetes guarda **todo** o estado do cluster no etcd.

## 3. Os dois protocolos

| | etcd: **Raft** | ZooKeeper: **ZAB** |
|---|---|---|
| Quem decide | 1 líder; os seguidores replicam | 1 líder; os seguidores replicam |
| "Relógio" de mandatos | **termo** (sobe a cada eleição) | **época** (32 bits altos do zxid) |
| Ordem das escritas | RAFT INDEX e revisão MVCC | zxid = época + contador |
| Leitura padrão | **linearizável**: sempre o valor mais novo (ReadIndex) | **local**: o servidor responde o que tem e pode estar atrasado |
| Leitura garantidamente atual | já é o padrão | chamar `sync` antes |
| Trava / eleição | lease (TTL) + `etcdctl lock`/`elect` | znode **efêmero** + **sequencial** (morre com a sessão) |

A Ênfase D é exatamente esta tabela, provada com experimentos (E9).

## 4. O ciclo de cada experimento (o que dá nota)
O E0 (`experimentos/E0-ensaio/`) é um exemplo completo.

1. **Previsão:** escrever o que vai acontecer e **por quê** (citar a teoria) **antes** de rodar. Fazer commit; o commit é a prova da ordem.
2. **Pré-condição:** `scripts/validar.sh`. Se falhar, não seguir.
3. **Execução:** um `executar.sh` reproduzível. As saídas brutas vão para `evidencias/` com data e hora e nunca são editadas.
4. **Medição:** tempos com no mínimo 5 repetições, média e desvio (`latencia.sh` ou `medir.sh`, que geram CSV e tabela).
5. **Análise:** previsão × resultado × teoria. **Errar a previsão não tira nota; deixar de explicar o erro, sim.**
6. **Ligação com as questões:** cada Q1–Q14 e S1–S4 aponta para a evidência que a sustenta.

## 5. Os experimentos em linguagem simples

| Exp. | Pergunta que responde | Quem (rascunho) |
|---|---|---|
| E1 | O cluster está de pé? Quem é o líder? | D |
| E2 | Por onde passa uma escrita? (seguidor → líder → maioria → resposta) | D |
| E3 | O dado escrito num nó aparece nos outros? Em quanto tempo? | D |
| E4 | Uma leitura pode devolver um valor velho? Quando? | D |
| E5 | O que acontece quando o líder cai? E quando cai a maioria? | S |
| E6 | E se a rede se partir em dois lados? | S |
| E7 | Um nó que volta se atualiza sozinho? Como (log ou snapshot)? | S |
| E8 | Como funcionam a trava e a eleição de aplicação? E o termo como relógio lógico? | S |
| E9 | E3–E8 de novo no ZooKeeper, com comparação | D: E3/E4; S: E5–E8 |

## 6. Como o professor avalia (R1–R10)
Ambiente reprodutível (R1) · pesquisa com artigo e diagrama próprio (R2) · E1–E8 (R3) · E9 (R4) · Q1–Q14 com evidência (R5) · S1–S4 (R6) · medições com 5 ou mais repetições (R7) · relatório de 12 seções (R8) · seminário de 10 min (R9) · **os dois dominam tudo** (R10).

## 7. Plano até 28/11 (sugestão)

> ⚠️ **Substituído em 25/10:** o prazo real é **28/10/2026** (relatório e seminário). O plano vigente está em `PLANO-28-10.md`.

| Semana | Período | Meta |
|---|---|---|
| 1 | 26/10–01/11 | Samuel valida o ambiente (R1); papéis acordados; dúvidas enviadas ao professor; **E1–E4** (D) e **E5** (S); leitura do artigo do Raft |
| 2 | 02/11–08/11 | **E6–E8** (S); **E9-E3/E4** (D); fundamentação (seção 3) e diagramas |
| 3 | 09/11–15/11 | **E9-E5..E8** (S); quadro comparativo; rascunho de Q1–Q14 e S1–S4 |
| 4 | 16/11–22/11 | Relatório completo; quadro-síntese; slides; **vídeos de contingência** das demos |
| 5 | 23/11–27/11 | Revisão cruzada; cada um treina as Q/S do outro; ensaio cronometrado; `python scripts/revisar.py` sem pendências |
| — | **28/11** | Entrega no AVA + seminário |

## 8. Rotina de cada sessão
```bash
git pull                                   # pegar o que o outro fez
docker compose -f etcd/docker-compose.yml up -d
docker compose -f zookeeper/docker-compose.yml up -d
scripts/validar.sh todos                   # precisa dar VALIDAÇÃO OK
# ... trabalhar ...
python scripts/revisar.py                  # o que ainda falta
git add -A && git commit -m "exp(E3): ..." && git push
```
Ao terminar, abrir uma entrada nova no topo de `relatorio/notas/diario.md`.
