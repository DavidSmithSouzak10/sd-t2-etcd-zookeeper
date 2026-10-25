# Equipe

> **RASCUNHO (25/10/2026), proposto pelo Claude Code para David e Samuel discutirem.** Ajustar livremente e trocar este aviso por "acordado em DD/MM" quando os dois concordarem.

## Critério da divisão
Cada um fica com um **eixo temático inteiro**, no etcd **e** no ZooKeeper. Assim quem faz o experimento no etcd também faz o equivalente do E9 e escreve aquela linha do quadro comparativo. Ninguém fica só com um sistema, e os dois conseguem defender a comparação ZAB × Raft na arguição.

- **Eixo 1 (David): replicação e consistência**, ou seja, o caminho feliz.
- **Eixo 2 (Samuel): falhas, recuperação e coordenação.**

## Responsabilidades

| Item | David | Samuel |
|---|---|---|
| Ambiente (compose, scripts, validação) | ✅ responsável | testa a reprodução do zero (R1) |
| Experimentos etcd | E1 subida, E2 caminho da operação, E3 replicação, E4 consistência | E5 falha e quórum, E6 partição, E7 recuperação, E8 coordenação e ordem |
| Experimentos ZooKeeper (E9) | E9-E3, E9-E4 | E9-E5, E9-E6, E9-E7, E9-E8 |
| Quadro comparativo (`comparacao.md`) | linhas: leitura padrão, leitura atual (ReadIndex × `sync`), memória | linhas: época × termo, lease × sessão, eleição, recuperação, partição |
| Pesquisa | P2 replicação/commit, P4 MVCC/watch/lease, P5 ReadIndex, P9 leitura local × `sync` | P1 Raft/eleição, P3 pre-vote/check quorum, P6 snapshots/learners, P8 ZAB/zxid, P10 CAP/PACELC, P11 Bully/Anel, P12 Lamport, P13 Chandy-Lamport |
| Pesquisa em conjunto | P7 (visão geral do ZooKeeper) e P14 (referências) | idem |
| Questões comuns | Q1–Q6 | Q7–Q14 |
| Questões específicas | S3 | S1, S2, S4 |
| Relatório (redige) | 01, 03 (parte etcd/Raft), 04, 05 (E1–E4, E9-E3/E4) | 03 (parte ZAB e conceitos), 05 (E5–E8, E9-E5..E8), 09 |
| Relatório em conjunto | 02 resumo, 08 quadro-síntese, 10 papéis, 11 uso de IA, 12 referências | idem |
| Seminário | bloco 1 (problema/artigo), bloco 2 (arquitetura), demo de E2 e E3 | demo de E5/E6 e E7, bloco 4 (E9), bloco 5 (quadro-síntese) |

## Revisão cruzada (obrigatória: R10)
- Cada um **revisa tudo** o que o outro escreveu e marca a revisão no commit (`revisado por S`/`revisado por D`).
- Antes do seminário, cada um responde em voz alta as Q/S do **outro** (roteiro em `seminario/arguicao.md`).

> O seminário exige que **os dois apresentem**, e na arguição o professor escolhe quem responde (Q1–Q14, S1–S4).
> Por isso cada um revisa e domina a parte do outro. Esta tabela alimenta a seção 10 do relatório.
