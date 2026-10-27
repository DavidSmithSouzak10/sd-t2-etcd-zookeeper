# E9 — Quadro comparativo etcd (Raft) × ZooKeeper (ZAB)

Toda célula aponta para a evidência (`experimentos/.../evidencias/...`) ou para a fonte primária. Tempos em média ± desvio padrão, n = 5.

| Aspecto | etcd (Raft) | ZooKeeper (ZAB) | Evidência / fonte |
|---|---|---|---|
| Protocolo de consenso | Raft: líder replica um log; entrada confirmada pela maioria | ZAB: líder difunde propostas em ordem; confirmadas pela maioria | Ongaro e Ousterhout (2014); Junqueira, Reed e Serafini (2011) |
| Época × termo | termo, +1 a cada eleição; campo separado do índice | época = 32 bits altos do zxid, +1 a cada líder; o contador zera | E5 (`2026-10-26_2118_queda_lider_kill.txt`); E9-E5 (`2026-10-26_2148_queda_lider_kill.txt`); E9-E8 (`2026-10-26_2139_epoca_x_termo.txt`) |
| Leitura padrão | linearizável | local (pode estar desatualizada) | E3, E4; E9-E3, E9-E4 |
| Leitura atual | ReadIndex, sem gravar no log: linearizável 1,82 ms × serializável 0,65 ms | `sync` + leitura: 3,25 ms × local 1,03 ms | E4; E9-E4 |
| Lease × sessão | lease com TTL; troca do `lock` 7,9 ± 1,5 s (TTL 10 s); `elect` 57,2 ± 0,3 s (sessão padrão de 60 s) | znode efêmero preso à sessão; troca da trava 7,9 ± 0,1 s, da eleição 7,8 ± 0,4 s (sessão de 10 s) | E8 (`2026-10-26_2141_troca_detentor.txt`); E9-E8 (`2026-10-26_2135_troca_detentor.txt`) |
| Eleição: falha abrupta (`kill`) | 1,46 ± 0,18 s (espera o *election timeout*) | 0,38 ± 0,09 s (a conexão fechada avisa os seguidores) | `resultados/2026-10-26_2118_e5_eleicao_kill.csv`; `resultados/2026-10-26_2148_e9e5_eleicao_kill.csv` |
| Eleição: parada ordenada (`stop`) | 0,009 ± 0,002 s (transfere a liderança) | 0,70 ± 0,09 s | `…_2119_e5_eleicao_stop.csv`; `…_2149_e9e5_eleicao_stop.csv` |
| Eleição: partição | 0,94 ± 0,24 s (limite inferior) | 3,60 ± 0,29 s (`syncLimit × tickTime` = 4 s) | `…_2120_e6_eleicao_particao.csv`; `…_2131_e9e6_eleicao_particao.csv` |
| Recuperação de um nó atrasado | 5,2 ± 2,9 s com 1005 entradas (6,3–6,7 s em 4 de 5); pelo log, ou por snapshot quando o log foi compactado | 2,5 ± 0,7 s com 200 transações; DIFF (também com 5000) | E7; E9-E7 |
| Sem maioria | escrita e linearizável falham; serializável responde | o servidor fica sem serviço; a sessão não abre | E5 (`2026-10-26_2120_quadro_quorum.txt`); E9-E5 (`2026-10-26_2149_quadro_quorum.txt`) |
| Partição: lado minoritário | sem líder; recusa escrita e linearizável; serializável devolve o valor antigo | perde o quórum e para de atender; antes disso, cerca de 2 a 4 s de leitura local antiga | E6 (`2026-10-26_2121_linha_do_tempo.txt`); E9-E6 (`2026-10-26_2132_linha_do_tempo_so_lider.txt`) |
| Partição: lado majoritário | elege novo líder com termo maior e continua atendendo | elege novo líder com época maior; o cliente com a lista migra | E6; E9-E6 (`2026-10-26_2133_linha_do_tempo_lista.txt`) |
| C × A | CP (PC/EC) | CP | E6, E9-E6 |
| Memória medida (repouso / após carga) | 23,7–29,7 MB / 80–87 MiB por membro | 46,8–55,7 MB / 83–133 MiB por servidor (JVM, heap de 128 MB) | `docs/ambiente/evidencias/2026-10-24_1614_memoria_repouso.txt`; E3 (`2026-10-25_1309_memoria_apos_carga.txt`); E9-E3 |

**Síntese.** Os dois sistemas garantem a mesma coisa: um líder por mandato, escrita confirmada pela maioria e consistência sob partição. As diferenças medidas estão nas escolhas de projeto. O etcd lê de forma linearizável por padrão e detecta falhas só por tempo, o que deixa a eleição previsível (1–2 s) com ou sem partição. O ZooKeeper lê da cópia local por padrão (mais rápido, com risco de valor antigo, corrigido com `sync`) e aproveita o fechamento da conexão para eleger em 0,4 s, mas numa partição depende de um timeout maior (4 s com os padrões da imagem).
