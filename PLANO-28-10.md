# Plano de emergência: entrega e seminário em 28/10/2026 (quarta)

Criado em 25/10 (domingo). Restam **dom à noite, seg e ter**. Marcar `[x]` ao concluir.
Regra que **não** pode ser cortada: a previsão é da dupla, escrita **antes** de cada execução. Todo o resto pode ser acelerado.

**Divisão do trabalho:**
- **Dupla:** escrever as previsões, entender os resultados, revisar os textos, preparar a fala.
- **Claude:** scripts, execução, evidências, tabelas, rascunhos.
- Todo rascunho do Claude é declarado em `docs/uso-ia.md` e precisa ser lido e aprovado pela dupla, porque na arguição quem responde são vocês (R10).

## Domingo 25/10 (hoje)
- [ ] **D+S: previsões de TODOS os experimentos** (E1–E8 e E9-E3..E8). É o caminho crítico.
  - Cada `README.md` tem perguntas-guia; responder em 3 a 5 linhas, com o "porquê".
  - Commit e push **antes** de qualquer execução: `exp: previsoes da dupla`.
  - Sugestão: David faz E1–E4 e E9-E3/E4; Samuel faz E5–E8 e E9-E5..E8; cada um lê as do outro.
- [ ] **S:** aceitar o convite, `git clone`, `scripts/validar.sh todos`, commit da evidência (R1). Cerca de 15 min.
- [ ] **D:** informar seu nome completo para a capa (o relatório está com "David Smith").
- [ ] **Claude:** `executar.sh` de E1–E8 e E9 (prontos, mas sem rodar até as previsões chegarem); diagramas de topologia e de sequência do E2.

## Segunda 26/10
- [ ] **Claude:** rodar todos os experimentos (cerca de 1 h de máquina), salvar evidências e CSVs (5 repetições), preencher as tabelas e o rascunho de "previsão × resultado".
- [ ] **D+S:** ler cada resultado e corrigir ou completar a análise (onde a previsão errou, explicar por quê).
- [ ] **Claude:** rascunhos de Q1–Q14, S1–S4, quadro comparativo do E9, quadro-síntese e seções 3, 5 e 9, cada um apontando a evidência.
- [ ] **D+S:** estudar o artigo do Raft (§5, cerca de 10 páginas) e o quadro Raft × ZAB do `docs/guia-do-trabalho.md`.
- [ ] Enviar ao professor só o essencial: horário limite do AVA e o formato do seminário (ao vivo × vídeo).

## Terça 27/10
- [ ] **D+S:** revisar o relatório inteiro; escrever o resumo (seção 2), os papéis (seção 10) e a declaração de IA (seção 11).
- [ ] **Claude:** montar o relatório final (12 seções, ABNT) em .docx/PDF, com figuras e tabelas.
- [ ] **Claude + D+S:** slides de 10 min (5 blocos) e roteiro de fala dividido entre os dois.
- [ ] **D+S:** gravar os vídeos de contingência (E2, E3, E5/E6, E7, E9), cerca de 1 min cada, com o terminal e `executar.sh`.
- [ ] **D+S:** ensaio cronometrado (≤ 10 min) e treino de arguição: cada um responde as Q/S do outro.

## Quarta 28/10
- [ ] Entregar o relatório no AVA (confirmar o horário).
- [ ] Antes da aula: `docker compose up -d` nos dois clusters + `scripts/validar.sh todos` → `VALIDAÇÃO OK`.
- [ ] Apresentar. Se a demo ao vivo falhar, usar os vídeos.

## Cortes já aceitos, se faltar tempo
- Medições com exatamente **n = 5** (o mínimo do R7).
- Sem o `check perf` pesado (E3): citar como limitação.
- O E9-E7 pode ficar com 5 religamentos de **um** servidor só.
- O seminário usa vídeos em vez de demonstração ao vivo (a "Dica" do PDF recomenda isso).
