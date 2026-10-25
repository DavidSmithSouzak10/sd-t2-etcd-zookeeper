# E4 — Consistência (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Evidenciar o modelo de consistência: leitura atualizada garantida ou janela de leitura desatualizada.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: 2026-10-25 12:55 — respostas de David a um questionário de múltipla escolha; texto montado pelo Claude Code a partir das escolhas (ver `docs/uso-ia.md`)
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. Qual leitura será mais rápida: linearizável ou serializável? Por quanto, aproximadamente?
> 2. Com um seguidor isolado da rede interna, um `get` **linearizável** nele responde, trava ou falha?
> 3. E um `get` **serializável** nele: responde valor novo, valor antigo ou falha?
> 4. O RAFT INDEX sobe com leituras linearizáveis? (achado A1: o que vocês acham?)
> O que esperamos observar e por quê (citar Raft/ZAB, quórum etc.):

1. **Velocidade:** esperamos a leitura **serializável mais rápida** (talvez metade do tempo), porque ela responde direto da cópia local, sem conversar com o líder.
2. **Linearizável no seguidor isolado:** esperamos que **falhe ou dê timeout**, porque ele não consegue falar com o líder para confirmar que está atualizado e prefere não responder.
3. **Serializável no seguidor isolado:** esperamos que **responda o valor antigo**, porque ela não pergunta a ninguém e devolve a cópia local, que parou no momento do isolamento.
4. **Leituras linearizáveis e o log:** esperamos que **cada leitura linearizável faça o RAFT INDEX subir +1**, porque, para garantir a ordem, a leitura seria registrada no log como uma escrita.

## Procedimento
1. Comparar `get` linearizável (padrão) com `get --consistency=s` (serializável) em condições normais: mesma resposta, latências diferentes?
2. Isolar um seguidor (ver E6), escrever um valor novo pelo lado majoritário e ler no seguidor isolado com as duas consistências. Registrar qual devolve o valor antigo e qual falha.

Script reproduzível: `executar.sh` (_pendente_).

## Evidências
Arquivos em `evidencias/` (gerados por `scripts/lib.sh::evidencia`, nunca editados à mão). Evidência mínima: sequência temporal de escritas e leituras com valores observados.

| Arquivo | O que mostra |
|---|---|
| _pendente_ | |

## Medições (≥ 5 repetições — R7)
CSV em `resultados/`; tabela gerada por `scripts/estatistica.py`.

_pendente_

## Análise: previsão × resultado × teoria
_pendente_

## Questões que este experimento sustenta
_preencher (ex.: Q5, Q6, Q11)_
