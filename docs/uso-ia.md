# Registro de uso de IA generativa (alimenta a seção 11 do relatório)

| Data | Ferramenta | Parte do trabalho | Como o resultado foi verificado |
|---|---|---|---|
| 2026-10 | Claude (web) | Rascunho do CLAUDE.md (regras do roteiro) | Conferido contra o PDF do roteiro |
| 2026-10-24 | Claude Code (VS Code) | Estrutura do repositório, docker-compose etcd/ZooKeeper, scripts de validação/medição, modelos dos experimentos | Clusters subidos e `scripts/validar.sh etcd` e `zk` executados com sucesso; `medir.sh` testado com 5 repetições |
| 2026-10-24 | Claude Code (VS Code) | Lista de critérios (`docs/criterios-avaliacao.md`) derivada do PDF, `scripts/revisar.py`, estrutura do relatório e notas; observação exploratória sobre o RAFT INDEX | Critérios conferidos contra o PDF seção a seção; `revisar.py` executado; observação gravada como evidência bruta e marcada como exploratória (será formalizada no E4) |
| 2026-10-25 | Claude Code (VS Code) | Ferramenta de latência (`etcd-cliente`, `etcd/cliente/latencia.py`, `zookeeper/cliente/latencia.py`, `scripts/latencia.sh`); rascunho da divisão de papéis em `docs/equipe.md`; orientação teórica para a previsão do E1 (a previsão foi escrita pela dupla) | Ferramenta testada nos dois sistemas com 10 repetições por operação e comparada com `docker exec` (evidência `docs/ambiente/evidencias/2026-10-25_1035_teste_ferramenta_latencia.txt`); divisão de papéis pendente de acordo da dupla |
