# 11. Declaração de uso de ferramentas de IA generativa

Usamos o **Claude** (Anthropic), pela interface web e pelo **Claude Code** no VS Code, ao longo de todo o trabalho. O registro completo, com data, parte e forma de verificação, está em `docs/uso-ia.md`. Em resumo:

| Parte | Uso da IA | Como verificamos |
|---|---|---|
| Ambiente | escreveu os arquivos Compose, os scripts de validação, medição e partição e os clientes de medição | clusters subidos e validados em duas máquinas diferentes; teste de reprodutibilidade do zero (R1) |
| Previsões | apresentou perguntas e conceitos e redigiu o texto a partir das escolhas da dupla; nas previsões de E5–E9, a pedido da dupla, conferiu a coerência com a teoria e reescreveu no formato do roteiro, **antes de qualquer execução** | cada previsão foi registrada em commit anterior à execução; a dupla leu e aprovou o texto |
| Execução | rodou os scripts, diagnosticou e corrigiu defeitos (execuções com defeito descartadas e registradas) | evidências brutas geradas pelos scripts, com data e hora, sem edição manual |
| Análise e relatório | redigiu rascunhos das análises, das respostas Q1–Q14 e S1–S4, dos quadros e das seções 2, 3, 5, 8 e 9 | todo número conferido contra os CSVs (`scripts/estatistica.py`); toda afirmação aponta para uma evidência ou fonte primária; causas não verificadas marcadas como hipótese; leitura e revisão pela dupla: _pendente_ |

A IA não escolheu as previsões no lugar da dupla, não inventou resultados e não editou evidências. A responsabilidade pelo conteúdo e pela defesa na arguição é dos autores.
