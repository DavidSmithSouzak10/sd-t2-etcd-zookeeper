# 9. Limitações e ameaças à validade

Pontos já identificados (desenvolver com dados):
- Todos os nós no **mesmo host**: rede sem latência/perda reais; disco e CPU compartilhados.
- **Relógio compartilhado** pelos contêineres: não aparecem desvios de relógio (relevantes para leases e sessões).
- Medições via `docker exec` incluem **~200–300 ms de overhead** do próprio Docker (medido em 24/10/2026: 256,6 ± 37,2 ms para um `get`).
- Comunicação em **texto plano**, sem TLS nem autenticação (só laboratório).
- Docker Desktop no Windows (VM WSL 2 com 8 GB) — desempenho difere de Linux nativo.
- O healthcheck do Docker Compose gera entradas no log do Raft (ver `notas/achados.md`) — o RAFT INDEX não fica parado em repouso.

_pendente_
