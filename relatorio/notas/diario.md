# Diário de bordo

Uma entrada por sessão de trabalho, a mais recente no topo. Registrar:
- o que foi feito e quem fez;
- os resultados, com o caminho da evidência;
- os problemas e como foram resolvidos;
- os prints sugeridos;
- o que fica para depois.

Este diário é a fonte das seções 4 (ambiente), 5 (experimentos) e 9 (limitações) do relatório.

---

## 2026-10-24 (sábado), sessão 2: repositório remoto (David + Claude Code)
- Repositório privado criado por David: https://github.com/DavidSmithSouzak10/sd-t2-etcd-zookeeper. Visibilidade privada confirmada (a API anônima responde 404).
- Remoto `origin` ligado e push da `main` (commit inicial `7ff3319`).
- GitHub CLI 2.103.2 instalado (winget); `gh auth login` ainda não feito, porque o push usou as credenciais do Git Credential Manager.
- **Próximo:** convidar o Samuel como colaborador; ele clona o repositório e testa a subida do zero só com o README (critério R1).

## 2026-10-24 (sábado), sessão 1: montagem do ambiente (David + Claude Code)

**Feito**
- Repositório criado (git local, branch `main`) com a estrutura do CLAUDE.md.
- `etcd/docker-compose.yml` com 3 membros (etcd 3.5.17), redes `interna` 172.30.0.0/24 e `clientes` 172.31.0.0/24, `mem_limit` de 256 MB e healthcheck.
- `zookeeper/docker-compose.yml` com 3 servidores (ZooKeeper 3.9.6) e um cliente Python com kazoo 2.10.0, nas redes 172.32/172.33.
- Scripts: `validar.sh`, `medir.sh`, `estatistica.py`, `particionar.sh`, `lib.sh` e `revisar.py` (critérios automáticos).
- Modelos dos READMEs de E1–E9, estrutura do relatório (`relatorio/01..12`) e lista de critérios (`docs/criterios-avaliacao.md`).

**Resultados**
- Os dois clusters sobem e passam no `validar.sh`:
  - etcd: líder = etcd2, termo 2, RAFT INDEX igual nos 3;
  - ZooKeeper: líder = zk2, época 1, zxid igual nos 3.
  - Evidência: `docs/ambiente/evidencias/2026-10-24_161*_validacao_*.txt`.
- Memória em repouso: etcd de 23,7 a 29,7 MB por membro; ZK de 46,8 a 55,7 MB por servidor; cliente com 3,9 MB. Tudo muito abaixo dos limites. Evidência: `docs/ambiente/evidencias/2026-10-24_1614_memoria_repouso.txt`.
- Teste do `medir.sh` com 5 execuções de `get` via `docker exec`: 256,6 ± 37,2 ms. Esse número é quase todo **overhead do docker exec**, não latência do etcd. O CSV de teste foi descartado (não é experimento).

**Problemas e soluções**
1. *Falso negativo na validação (RAFT INDEX diferente):*
   - Causa: os membros eram consultados um de cada vez, e o índice avança entre as consultas.
   - Solução: os 3 passam a ser lidos numa única chamada, com até 3 tentativas.
   - Daí veio o achado A1 (ver `achados.md`).
2. *zxid diferente logo após a eleição do ZK:*
   - Causa: um seguidor sem nenhuma transação reporta zxid 0x0.
   - Solução: o validador agora faz uma escrita de teste antes de comparar.
3. *Falso erro no zkCli:*
   - O log do zkCli sempre contém "unknown error" (linha do SASL), mesmo quando a operação dá certo.
   - Solução: usar o código de saída (o zkCli sai com 1 em caso de falha).
4. *Git Bash no Windows:*
   - Converte `/config/x` em `C:/Program Files/Git/...` e imprime acentos errados no Python.
   - Solução: `MSYS_NO_PATHCONV=1`, `cygpath` e `PYTHONIOENCODING=utf-8` em `lib.sh`.
5. *Imagem flutuante:* `zookeeper:3.9` resolvia para 3.9.6. Agora a tag está fixada em `3.9.6`, por reprodutibilidade.

**Prints sugeridos:** ver `prints.md` (P1, P2).

**Próximos passos**
- Criar o repositório privado no GitHub e dar acesso ao Samuel.
- Preencher `docs/equipe.md`.
- Escrever a previsão do E1 e só depois rodá-lo.
- Antes do E3, decidir como medir latência sem o overhead do `docker exec`.
