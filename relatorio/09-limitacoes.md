# 9. Limitações e ameaças à validade

Pontos já identificados (desenvolver com dados):
- Todos os nós no **mesmo host**: rede sem latência/perda reais; disco e CPU compartilhados.
- **Relógio compartilhado** pelos contêineres: não aparecem desvios de relógio (relevantes para leases e sessões).
- Medições via `docker exec` incluem **cerca de 250 a 400 ms de overhead** do próprio Docker (256,6 ± 37,2 ms em 24/10; 407,2 ± 35,7 ms em 25/10). **Mitigação:** a latência é medida dentro do contêiner cliente (`scripts/latencia.sh`; ver seção 4).
- Timestamps dos CSVs de latência saem em UTC (relógio do contêiner); o host está em UTC−3.
- Comunicação em **texto plano**, sem TLS nem autenticação (só laboratório).
- Docker Desktop no Windows (VM WSL 2 com 8 GB) — desempenho difere de Linux nativo.
- O healthcheck do Docker Compose gera entradas no log do Raft (ver `notas/achados.md`) — o RAFT INDEX não fica parado em repouso.

_pendente_
