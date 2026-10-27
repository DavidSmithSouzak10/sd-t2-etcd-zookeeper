# 9. Limitações e ameaças à validade

**O que um laboratório num único computador não mostra**
- **Rede.** Todos os nós estão no mesmo host: não há latência, perda nem largura de banda reais entre membros. Os tempos de replicação (milissegundos) seriam maiores entre máquinas e muito maiores entre regiões, e a escrita seria mais afetada que a leitura serializável.
- **Disco e CPU compartilhados.** Os 6 nós disputam o mesmo SSD e a mesma CPU; uma falha de disco ou um disco lento de um único membro não pode ser simulado.
- **Relógio compartilhado.** Os contêineres usam o relógio do host, então desvios de relógio não aparecem. O Raft não depende de relógio para a segurança, mas leases e sessões dependem de medir tempo; num cluster real, desvio ou pausa do relógio afeta o momento em que uma trava se libera (S4).
- **Falhas simuladas.** `docker kill`, `docker stop`, `docker pause` e `docker network disconnect` imitam queda, parada ordenada, congelamento e partição, mas não falhas parciais (perda intermitente de pacotes, partição assimétrica).

**Ameaças à validade das medições**
- **Duas máquinas.** E1–E4 e E9-E3/E4 rodaram na máquina 1 (Intel i7, Docker Engine 29.7.2); E5–E8 e E9-E5..E8 na máquina 2 (AMD Ryzen 5, Docker Engine 29.9.2) (seção 4). Comparações de tempo entre experimentos de máquinas diferentes devem ser lidas com cuidado.
- **Amostras pequenas.** A maioria das medições tem n = 5 (o mínimo do R7) ou n = 20. Algumas observações têm uma única repetição e estão marcadas como tal: snapshot (E7), 5000 transações (E9-E7) e trocas com `docker stop` (E8).
- **Início dos eventos de rede.** Três das 5 eleições do E6 ficaram abaixo de 1 s, menos que o *election timeout* mínimo. Isso indica que o evento `disconnect` do Docker é registrado depois do corte real (o mínimo teórico é cerca de 0,9 s: o *election timeout* de 1 s menos um *heartbeat*). Os tempos medidos a partir de eventos de rede (`disconnect` no E6 e no E9-E6, `connect` no E7 e no E9-E7) podem estar subestimados em até cerca de 0,3–0,4 s; os tempos medidos a partir de `kill` (E5, E9-E5, E8) não são afetados.
- **Atraso não explicado no E7.** O membro religado levou cerca de 6,5 s para voltar a ouvir o líder em 4 de 5 repetições (50 ms em uma). A causa não foi isolada; as hipóteses são o intervalo de nova tentativa de conexão entre pares do etcd e a resolução do endereço do contêiner religado na rede do Docker. O E4 observou o mesmo fenômeno (7 s).
- **Leitura de estado durante a transição.** No E5, uma repetição registrou termo 3 → 3 porque o termo "depois" foi lido de um membro ainda não atualizado; o tempo medido não é afetado.
- **Overhead do Docker.** Comandos via `docker exec` custam de 250 a 400 ms (256,6 ± 37,2 ms em 24/10; 407,2 ± 35,7 ms em 25/10). Mitigação: latências medidas por um cliente dentro da rede de clientes (seção 4); eventos medidos com o horário do próprio Docker (`docker events`).
- **Atividade de fundo.** O healthcheck do Compose grava no log do Raft (cerca de 0,6 entrada/s), então o RAFT INDEX nunca fica parado; as comparações de índice usam linha de base (E1, E4).
- **Execuções descartadas.** Duas execuções com defeito de script foram descartadas e refeitas (E8: `elect` sem `--ttl`; E9-E5: znode pai inexistente). O motivo está no diário (`relatorio/notas/diario.md`, sessão 9).
- **Fuso horário.** Os registros dentro dos contêineres estão em UTC; o host está em UTC−3.

**Segurança**
- Comunicação em texto plano, sem TLS, sem autenticação e sem controle de acesso, o que é aceitável só em laboratório (Q14).
