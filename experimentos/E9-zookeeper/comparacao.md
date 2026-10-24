# E9 — Quadro comparativo etcd (Raft) × ZooKeeper (ZAB)

Toda célula aponta para a evidência (`experimentos/.../evidencias/...`) ou para a fonte primária.

| Aspecto | etcd (Raft) | ZooKeeper (ZAB) | Evidência / fonte |
|---|---|---|---|
| Protocolo de consenso | | | |
| Época × termo (como aparece, quando incrementa) | | | |
| Leitura padrão (linearizável × local/sequencial) | | | |
| Mecanismo para leitura atual (ReadIndex × `sync`) | | | |
| Lease × sessão / znode efêmero | | | |
| Tempo de eleição medido (média ± desvio, n) | | | |
| Tempo de recuperação medido (média ± desvio, n) | | | |
| Comportamento sob partição (lado minoritário / majoritário) | | | |
| Memória medida (repouso / carga) | | | |
