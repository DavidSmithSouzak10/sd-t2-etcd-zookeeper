# Trabalho 2 de Sistemas Distribuídos: etcd (Raft) e ZooKeeper (ZAB)

UNIVALI, 2º semestre de 2026, Prof. Ramices dos Santos Silva.
**Tema 5:** replicação de estado e configuração. **Ênfase D:** ZooKeeper (ZAB).
**Dupla:** David e Samuel.

- A bateria comum (E1 a E8) roda num cluster **etcd v3.5.17** com 3 membros.
- O experimento da ênfase (E9) repete E3 a E8 num ensemble **ZooKeeper 3.9** com 3 servidores e compara ZAB com Raft.

Tudo roda em contêineres (Docker Compose), sem nenhuma VM. Cada serviço declara `mem_limit`, e o total fica abaixo de 1 GB.

---

## 1. Pré-requisitos

| Ferramenta | Versão testada | Observação |
|---|---|---|
| Docker + Compose v2 | Docker 29.7 / Compose 5.5 | Windows: Docker Desktop com WSL 2 |
| Git | 2.55 | |
| Bash | Git Bash ou WSL (Windows); nativo no Linux/macOS | os scripts `.sh` **não** rodam no PowerShell |
| Python 3 | 3.11+ | só biblioteca padrão (`scripts/estatistica.py`) |

## 2. Topologia

| Nó | Rede interna (consenso) | Rede clientes | Portas | Memória |
|---|---|---|---|---|
| etcd1 | 172.30.0.31 | 172.31.0.31 | 2380 pares / 2379 clientes | 256 MB |
| etcd2 | 172.30.0.32 | 172.31.0.32 | 2380 / 2379 | 256 MB |
| etcd3 | 172.30.0.33 | 172.31.0.33 | 2380 / 2379 | 256 MB |
| zk1 | 172.32.0.51 | 172.33.0.51 | 2888 quorum, 3888 eleição / 2181 clientes | 256 MB (heap 128 MB) |
| zk2 | 172.32.0.52 | 172.33.0.52 | 2888, 3888 / 2181 | 256 MB |
| zk3 | 172.32.0.53 | 172.33.0.53 | 2888, 3888 / 2181 | 256 MB |
| zk-cliente | — | 172.33.0.100 | — | 128 MB (Python + kazoo) |

Os dois laboratórios usam sub-redes diferentes e por isso podem rodar ao mesmo tempo.

## 3. Subir do zero

Todos os comandos partem da raiz do repositório, num terminal bash.

```bash
# etcd (sistema principal)
docker compose -f etcd/docker-compose.yml up -d
scripts/validar.sh etcd          # precisa terminar em "VALIDAÇÃO OK (etcd)"

# ZooKeeper (Ênfase D). O cliente instala o kazoo na primeira subida, o que leva cerca de 20 s.
docker compose -f zookeeper/docker-compose.yml up -d
scripts/validar.sh zk            # precisa terminar em "VALIDAÇÃO OK (zk)"
```

**O que `validar.sh` verifica.** Esta checagem é a pré-condição de todo experimento.

| Sistema | Verificações |
|---|---|
| etcd | os 3 membros estão saudáveis em endpoint único; existe **exatamente 1 líder**; o termo é o mesmo nos 3; o RAFT INDEX é igual nos 3; o cluster aceita uma escrita de teste |
| ZooKeeper | o ensemble aceita uma escrita de teste; há 1 `leader` e 2 `follower`; o zxid é o mesmo nos 3 |

## 4. Comandos do dia a dia

```bash
EP=172.31.0.31:2379,172.31.0.32:2379,172.31.0.33:2379
docker exec etcd1 etcdctl --endpoints=$EP endpoint status -w table   # líder, termo, índice
docker exec zk-cliente python /app/srvr.py                           # modo, zxid, época do ZK

scripts/particionar.sh isolar etcd1      # tira o nó da rede interna, mas ele continua acessível ao cliente
scripts/particionar.sh religar etcd1     # religa com o mesmo IP
scripts/medir.sh <nome> <n> -- <comando> # mede n repetições e grava CSV + tabela em resultados/
```

> **Git Bash no Windows:** `scripts/lib.sh` já exporta `MSYS_NO_PATHCONV=1`. Quando você digitar comandos `docker exec` soltos que usam chaves como `/config/x`, rode `export MSYS_NO_PATHCONV=1` antes. Sem isso, o Git Bash troca `/config/x` por `C:/Program Files/Git/config/x`.

## 5. Parar e recriar

| Comando | O que faz | Quando usar |
|---|---|---|
| `docker compose -f etcd/docker-compose.yml stop` / `start` | para e retoma os contêineres, **mantendo os dados** | entre experimentos |
| `docker compose -f etcd/docker-compose.yml down -v` | apaga os contêineres e os dados | para recriar o cluster do zero, por exemplo depois de mudar `SNAPSHOT_COUNT` em `etcd/.env` |

O ZooKeeper usa os mesmos comandos com `-f zookeeper/docker-compose.yml`.

## 6. Organização

- O status de cada item está em [CHECKLIST.md](CHECKLIST.md).
- As regras do trabalho estão em [CLAUDE.md](CLAUDE.md).
- Cada experimento tem uma pasta `experimentos/EX-*/` com:
  - `README.md`: objetivo, previsão, procedimento, análise;
  - `executar.sh`: os passos reproduzíveis;
  - `evidencias/`: as saídas brutas, com data e hora.
- As medições (CSV) ficam em `resultados/`, os diagramas em `diagramas/`, o relatório em `relatorio/` e o seminário em `seminario/`.
