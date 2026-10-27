# E9 — Ênfase D: ZooKeeper (ZAB)

> Roteiro: PDF §9.5, ênfase D — "Executar a bateria E3 a E8 em um ensemble ZooKeeper de 3 nós, com znodes efêmeros e
> sequenciais para trava e eleição; comparar ZAB e Raft (épocas × termos, leitura local × linearizável, `sync`)."
> Rodar `scripts/validar.sh zk` antes de cada sub-experimento.

## Sub-experimentos
Cada subpasta segue o mesmo modelo dos E1–E8 (objetivo, **previsão antes**, procedimento, evidências, medições, análise).

| Sub | Equivalente no ZooKeeper | Status |
|---|---|---|
| E3-replicacao | `create`/`set` em um servidor, `get` em outro; `get -w` (watch) em terceiro; latência ≥ 5× | ✅ |
| E4-consistencia | leitura local × `sync` + leitura; servidor isolado | ✅ |
| E5-falha-quorum | parar líder (eleição ≥ 5×, nova época no zxid); perder maioria | ✅ |
| E6-particao | líder fora da rede interna; estado LOOKING; o que o cliente vê | ✅ |
| E7-recuperacao | religar; sincronização (DIFF/SNAP/TRUNC nos logs) ≥ 5× | ✅ |
| E8-coordenacao | trava e eleição com znodes efêmeros e sequenciais (kazoo); época ZAB × termo Raft | ✅ |

## Ferramentas
- `docker exec zk-cliente python /app/srvr.py` — modo, zxid, época e contador de cada servidor.
- `docker exec zk1 zkCli.sh -server 172.33.0.51:2181 <comando>` — cliente oficial.
- `zookeeper/cliente/*.py` — scripts kazoo (trava, eleição, watch) — _pendente_.

Comparação final: `comparacao.md`.
