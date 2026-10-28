# CHECKLIST — Trabalho 2 (T5 etcd + Ênfase D ZooKeeper)

Legenda: `⬜ pendente` · `🟨 em andamento` · `✅ validado (com evidência)` · `❌ bloqueado (motivo)`
Responsável: D = David, S = Samuel, D+S = ambos.

> Este arquivo é o **painel de progresso**. A lista detalhada do que o roteiro exige está em `docs/criterios-avaliacao.md`.
> Conferência automática: `python scripts/revisar.py`.

## Ambiente (R1)
| Item | Status | Resp. | Evidência / observação |
|---|---|---|---|
| Repositório + CLAUDE.md + estrutura | ✅ | D | criado em 24/10/2026 |
| `etcd/docker-compose.yml` (3 membros, mem_limit, 2 redes) | ✅ | D | `validar.sh etcd` OK em 24/10/2026; ~15–23 MB por membro em repouso |
| `zookeeper/docker-compose.yml` (3 servidores + cliente kazoo) | ✅ | D | `validar.sh zk` OK em 24/10/2026; ~46–54 MB por servidor |
| `scripts/validar.sh`, `medir.sh`, `estatistica.py`, `particionar.sh` | ✅ | D | `particionar.sh` exercitado em E4, E6, E7 e E9 |
| Medição de latência sem overhead (`latencia.sh` + `etcd-cliente`/`zk-cliente`) | ✅ | D | testado em 25/10: `docs/ambiente/evidencias/2026-10-25_1035_teste_ferramenta_latencia.txt` |
| Divisão de papéis (`docs/equipe.md`) | 🟨 | D+S | rascunho em 25/10; falta o acordo da dupla |
| `docs/criterios-avaliacao.md` + `scripts/revisar.py` | ✅ | D | revisar.py: 9/67 itens automáticos em 24/10 |
| Estrutura do relatório + notas (diário, achados, prints) | ✅ | D | `relatorio/` |
| Imagens com versão fixa (ZK 3.9.6) | ✅ | D | |
| Repositório remoto (GitHub) privado | ✅ | D | https://github.com/DavidSmithSouzak10/sd-t2-etcd-zookeeper, push inicial em 24/10/2026 |
| Samuel com acesso de escrita ao repositório | ✅ | D | convite aceito em 26/10/2026 |
| **Professor com acesso ao repositório (privado)** | ⬜ | D | convidar o professor ou tornar público antes da entrega: sem isso ele não consegue reproduzir (R1) |
| Samuel subiu tudo do zero só com o README (teste de reprodutibilidade) | ✅ | S | 26/10/2026, Windows 11 + Docker Engine 29.9.2: `docs/ambiente/evidencias/2026-10-26_2029_validacao_samuel.txt` (VALIDAÇÃO OK todos) |

## Experimentos etcd (R3)
| Exp. | Previsão registrada | Executado | Medições ≥5× | Análise | Resp. |
|---|---|---|---|---|---|
| E1 Subida e topologia | ✅ | ✅ | ✅ (5 subidas) | ✅ | David |
| E2 Caminho de uma operação | ✅ | ✅ | ✅ (20×) | ✅ | David |
| E3 Replicação | ✅ | ✅ | ✅ (20×) | ✅ | David |
| E4 Consistência | ✅ | ✅ | ✅ (20×) | ✅ | David |
| E5 Falha e quórum | ✅ | ✅ | ✅ | ✅ | Samuel |
| E6 Partição | ✅ | ✅ | ✅ (eleição 5×) | ✅ | Samuel |
| E7 Recuperação | ✅ | ✅ | ✅ | ✅ | Samuel |
| E8 Coordenação e ordem | ✅ | ✅ | ✅ | ✅ | Samuel |

## E9 — ZooKeeper (R4)
| Sub | Previsão | Executado | Medições ≥5× | Análise | Resp. |
|---|---|---|---|---|---|
| E3 | ✅ | ✅ | ✅ (20×) | ✅ | David |
| E4 | ✅ | ✅ | ✅ (20×) | ✅ | David |
| E5 | ✅ | ✅ | ✅ | ✅ | Samuel |
| E6 | ✅ | ✅ | ✅ (eleição 5×) | ✅ | Samuel |
| E7 | ✅ | ✅ | ✅ | ✅ | Samuel |
| E8 (trava/eleição kazoo) | ✅ | ✅ | ✅ | ✅ | Samuel |
| Quadro comparativo `comparacao.md` | ✅ | | | | |

## Relatório (R2, R5, R6, R8)
| Seção | Status | Resp. |
|---|---|---|
| 01 Identificação | ✅ | D |
| 02 Resumo | 🟨 | rascunho em 26/10 (Claude Code); falta revisão da dupla |
| 03 Fundamentação + diagrama próprio | 🟨 | rascunho em 26/10 (Claude Code); falta revisão da dupla |
| 04 Ambiente e reprodutibilidade | ✅ | D; máquina 2 e memória do ZK acrescentadas em 26/10 |
| 05 Experimentos E1–E9 | 🟨 | rascunho em 26/10 (Claude Code); falta revisão da dupla |
| 06 Q1–Q14 (com evidência) | 🟨 | rascunho em 26/10 (Claude Code); falta revisão da dupla |
| 07 S1–S4 | 🟨 | rascunho em 26/10 (Claude Code); falta revisão da dupla |
| 08 Quadro-síntese | 🟨 | rascunho em 26/10 (Claude Code); falta revisão da dupla |
| 09 Limitações | 🟨 | rascunho em 26/10 (Claude Code); falta revisão da dupla |
| 10 Papel de cada integrante | 🟨 | rascunho em 26/10 (Claude Code); falta revisão da dupla |
| 11 Declaração de uso de IA | 🟨 | consolidada em 26/10; falta revisão da dupla |
| 12 Referências ABNT | 🟨 | faltam as datas de acesso das fontes online |
| Relatório montado em PDF (`relatorio/relatorio.pdf`) | 🟨 | 24 p. com capa e sumário, por `python scripts/gerar_pdf.py relatorio` (28/10); gerar de novo depois da revisão |
| Entrega do relatório no AVA (28/10) | ⬜ | D+S |

## Seminário (R9, R10)
| Item | Status | Resp. |
|---|---|---|
| Slides (5 blocos, 10 min) | 🟨 | S: esboço em 28/10, 11 slides; falta inserir os vídeos e revisar |
| Vídeos das demos (E2, E3, E5, E6, E7, E9) | ✅ | S: gravados em 27/10 com `seminario/demo.sh` (vídeo fora do repositório, 94 MB) |
| Ensaio cronometrado com os dois apresentando | ⬜ | D+S |
| Mini-aula de estudo (`seminario/mini-aula.pdf`) | ✅ | S (Claude Code), 28/10 |
| Roteiro de arguição Q1–Q14 / S1–S4 (`seminario/arguicao.md`) | 🟨 | rascunho em 26/10; falta o treino da dupla |

## Dúvidas com o professor
| Item | Status |
|---|---|
| Ver `docs/duvidas-professor.md` | ⬜ não enviadas (decisão da dupla em 26/10) |
