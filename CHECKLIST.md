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
| `scripts/validar.sh`, `medir.sh`, `estatistica.py`, `particionar.sh` | 🟨 | D | validar/medir/estatística testados; `particionar.sh isolar/religar` ainda não exercitado |
| Medição de latência sem overhead (`latencia.sh` + `etcd-cliente`/`zk-cliente`) | ✅ | D | testado em 25/10: `docs/ambiente/evidencias/2026-10-25_1035_teste_ferramenta_latencia.txt` |
| Divisão de papéis (`docs/equipe.md`) | 🟨 | D+S | rascunho em 25/10; falta o acordo da dupla |
| `docs/criterios-avaliacao.md` + `scripts/revisar.py` | ✅ | D | revisar.py: 9/67 itens automáticos em 24/10 |
| Estrutura do relatório + notas (diário, achados, prints) | ✅ | D | `relatorio/` |
| Imagens com versão fixa (ZK 3.9.6) | ✅ | D | |
| Repositório remoto (GitHub) privado | ✅ | D | https://github.com/DavidSmithSouzak10/sd-t2-etcd-zookeeper, push inicial em 24/10/2026 |
| Samuel com acesso de escrita ao repositório | 🟨 | D | convidado em 24/10/2026; aguardando aceite |
| Samuel subiu tudo do zero só com o README (teste de reprodutibilidade) | ⬜ | S | |

## Experimentos etcd (R3)
| Exp. | Previsão registrada | Executado | Medições ≥5× | Análise | Resp. |
|---|---|---|---|---|---|
| E1 Subida e topologia | ⬜ | ⬜ | n/a | ⬜ | |
| E2 Caminho de uma operação | ⬜ | ⬜ | n/a | ⬜ | |
| E3 Replicação | ⬜ | ⬜ | ⬜ | ⬜ | |
| E4 Consistência | ⬜ | ⬜ | ⬜ | ⬜ | |
| E5 Falha e quórum | ⬜ | ⬜ | ⬜ | ⬜ | |
| E6 Partição | ⬜ | ⬜ | n/a | ⬜ | |
| E7 Recuperação | ⬜ | ⬜ | ⬜ | ⬜ | |
| E8 Coordenação e ordem | ⬜ | ⬜ | ⬜ | ⬜ | |

## E9 — ZooKeeper (R4)
| Sub | Previsão | Executado | Medições ≥5× | Análise | Resp. |
|---|---|---|---|---|---|
| E3 | ⬜ | ⬜ | ⬜ | ⬜ | |
| E4 | ⬜ | ⬜ | ⬜ | ⬜ | |
| E5 | ⬜ | ⬜ | ⬜ | ⬜ | |
| E6 | ⬜ | ⬜ | n/a | ⬜ | |
| E7 | ⬜ | ⬜ | ⬜ | ⬜ | |
| E8 (trava/eleição kazoo) | ⬜ | ⬜ | ⬜ | ⬜ | |
| Quadro comparativo `comparacao.md` | ⬜ | | | | |

## Relatório (R2, R5, R6, R8)
| Seção | Status | Resp. |
|---|---|---|
| 01 Identificação | ⬜ | |
| 02 Resumo | ⬜ | |
| 03 Fundamentação + diagrama próprio | ⬜ | |
| 04 Ambiente e reprodutibilidade | 🟨 | D (hardware/versões/memória preenchidos) |
| 05 Experimentos E1–E9 | ⬜ | |
| 06 Q1–Q14 (com evidência) | ⬜ | |
| 07 S1–S4 | ⬜ | |
| 08 Quadro-síntese | ⬜ | |
| 09 Limitações | ⬜ | |
| 10 Papel de cada integrante | ⬜ | |
| 11 Declaração de uso de IA | 🟨 | `docs/uso-ia.md` sendo mantido |
| 12 Referências ABNT | ⬜ | |

## Seminário (R9, R10)
| Item | Status | Resp. |
|---|---|---|
| Slides (5 blocos, 10 min) | ⬜ | |
| Vídeos de contingência (E2, E3, E5/E6, E7, E9) | ⬜ | |
| Ensaio cronometrado com os dois apresentando | ⬜ | D+S |
| Roteiro de arguição Q1–Q14 / S1–S4 (`seminario/arguicao.md`) | ⬜ | D+S |

## Dúvidas com o professor
| Item | Status |
|---|---|
| Ver `docs/duvidas-professor.md` | ⬜ não enviadas |
