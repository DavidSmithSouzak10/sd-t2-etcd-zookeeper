# E6 — Partição de rede (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Isolar o líder do restante, mantendo-o acessível ao cliente; observar os dois lados.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Data/hora do registro: 2026-10-26 20:58 — respostas de Samuel (em call com David) a um questionário de múltipla escolha; texto montado pelo Claude Code a partir das escolhas, sem correção (ver `docs/uso-ia.md`)
>
> **Perguntas-guia** (do assistente: são só perguntas; a resposta e a justificativa são da dupla):
> 1. Com o líder fora da rede interna, o lado majoritário (2 nós) elege outro líder? Em quanto tempo?
> 2. O líder isolado continua se achando líder? Por quanto tempo?
> 3. Um cliente ligado ao nó isolado recebe o quê em `put`, `get` linearizável e `get` serializável?
> 4. O etcd escolhe C ou A na partição? Qual parte do resultado prova isso?
> O que esperamos observar e por quê (citar Raft/ZAB, quórum etc.):

1. **Lado majoritário:** esperamos que **eleja um novo líder em poucos segundos**, porque os 2 nós param de ouvir o líder e têm maioria para votar.
2. **Líder isolado:** esperamos que **continue se achando líder** até a rede voltar.
3. **Put no nó isolado:** esperamos que o cliente receba **OK**: o nó grava e sincroniza depois.
4. **C × A:** esperamos que o etcd prefira **consistência (C)**: recusa operações do lado minoritário para não haver duas versões dos dados.

## Procedimento
1. Desconectar o **líder** da rede interna (`scripts/particionar.sh isolar etcdN`).
2. Observar o lado majoritário elegendo novo líder com termo maior e o antigo líder deixando de aceitar escritas. O que um cliente conectado só a ele recebe?
3. Concluir sobre a escolha entre consistência e disponibilidade (C × A).

Script reproduzível: `executar.sh` (escrito em 26/10, antes da previsão; ainda não executado).

## Evidências
Arquivos em `evidencias/` (gerados por `scripts/lib.sh::evidencia`, nunca editados à mão). Evidência mínima: comportamento do lado minoritário e do majoritário + conclusão C × A.

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
