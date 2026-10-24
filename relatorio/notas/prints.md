# Prints (capturas de tela) a produzir

O roteiro aceita como evidência log, saída de comando ou captura de tela. As saídas brutas em `evidencias/` são a evidência principal.
Os prints servem para o **relatório** (legibilidade) e para os **slides e vídeos** do seminário.

**Como capturar**
- Terminal com fonte grande e tema claro.
- `Win + Shift + S`.
- Salvar em `relatorio/figuras/` com o nome do ID, por exemplo `P1_validacao_etcd.png`.
- Depois marcar como ✅ abaixo.

| ID | O que capturar | Comando | Para | Status |
|---|---|---|---|---|
| P1 | Validação OK dos dois clusters, lado a lado | `scripts/validar.sh todos` | Seção 4 (ambiente), slide 2 | ⬜ |
| P2 | Uso de memória dos 7 contêineres | `docker stats --no-stream` | Seção 4.3 (memória medida) | ⬜ |
| P3 | Tabela `endpoint status` com IS LEADER, RAFT TERM e RAFT INDEX | `docker exec etcd1 etcdctl --endpoints=$EP endpoint status -w table` | E1, slide de arquitetura | ⬜ |
| P4 | `put -w json` num seguidor mostrando `revision` e `raft_term` | E2 | E2 | ⬜ |
| P5 | `watch` recebendo a notificação em outro membro | E3 | E3, demo | ⬜ |
| P6 | Novo líder com termo maior após parar o líder | E5 | E5, Q8 | ⬜ |
| P7 | `put` falhando com *context deadline exceeded* sem maioria; serializável ainda respondendo | E5 | E5, Q7 | ⬜ |
| P8 | Os dois lados da partição: lado isolado × lado majoritário | E6 | E6, Q11 (slide C × A) | ⬜ |
| P9 | Log do membro que volta recebendo snapshot | E7 | E7, Q12 | ⬜ |
| P10 | Dois terminais disputando `etcdctl lock` | E8 | E8, demo | ⬜ |
| P11 | `srvr.py` mostrando a nova época no zxid após a eleição do ZK | E9-E5 | E9, comparação época × termo | ⬜ |
| P12 | Trava/eleição com znodes efêmeros sequenciais (`ls /` no zkCli) | E9-E8 | E9 | ⬜ |
