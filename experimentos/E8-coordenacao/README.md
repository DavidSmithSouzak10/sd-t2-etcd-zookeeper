# E8 — Coordenação e ordem (etcd)

> Roteiro: PDF §4.2 e §9.3. Rodar `scripts/validar.sh etcd` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Mostrar quem coordena e o mecanismo de versionamento/ordenação.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Registrada em 2026-10-26 21:11, antes de qualquer execução (ver `docs/uso-ia.md`).

- **Relógios lógicos:** esperamos que o termo suba só a cada troca de líder e que a revisão suba a cada escrita, numa ordem única para todas as chaves. O termo funciona como época de liderança, e a revisão como um relógio de Lamport compartilhado.
- **Trava e eleição:** esperamos que o segundo cliente fique esperando e assuma cerca de 10 s depois que o detentor é parado, quando o lease (TTL de 10 s) vence sem renovação. No `elect`, vence quem pediu primeiro (menor revisão), e não o maior ID, como no Bully e no Anel.

## Procedimento
1. Mostrar a sequência de termos e revisões ao longo das falhas e explicá-los como relógios lógicos (termo: época de liderança; revisão: ordem total das escritas).
2. Dois terminais competindo por `etcdctl lock trava` (exclusão mútua) e dois candidatos em `etcdctl elect eleicao <nome>` (eleição). Parar o contêiner do detentor e medir o tempo até o outro assumir (lease; kit mediu ~11 s com TTL 10 s).
3. Comparar a eleição do Raft com Bully e Anel (Unidade 2).

Script reproduzível: [`executar.sh`](executar.sh) (da raiz). Cada competidor de `lock`/`elect` roda num contêiner próprio (`e8-A`, `e8-B`); início = evento `kill` do detentor; fim = primeira linha de saída de B (`docker logs --timestamps`). Fencing: [`etcd/cliente/e8_fencing.py`](../../etcd/cliente/e8_fencing.py).

## Evidências
Executado em 26/10/2026 na máquina do Samuel (Windows 11, Docker 28.0.1), depois do registro da previsão (`5196dea`, revisada em `0dc40dd`). Horário: 21:41–21:48. Uma primeira execução (21:24–21:29) foi descartada: o `elect` usa sessão de 60 s, o script esperava só 40 s e não limpava a fila entre repetições (ver diário, sessão 9).

| Arquivo | O que mostra |
|---|---|
| `evidencias/2026-10-26_2141_relogios_logicos.txt` | 6 escritas alternando 3 chaves (revisão), `create`/`mod_revision`/`version`; termos colhidos nos CSVs de E5–E7 |
| `evidencias/2026-10-26_2141_troca_detentor.txt` | fila de `lock` e `elect` (ordem por `create_revision`) e 5 trocas de detentor de cada |
| `evidencias/2026-10-26_2148_fencing_token.txt` | pausa longa do detentor: gravação com e sem fencing token |
| `evidencias/2026-10-26_2148_validacao_final.txt` | cluster saudável no fim |

## Medições (5 repetições, R7)
| Medição | n | média (ms) | desvio padrão | mín | máx | falhas |
|---|---|---|---|---|---|---|
| troca do `lock` após `docker kill` do detentor | 5 | 7863,4 | 1456,1 | 6978,2 | 10448,5 | 0 |
| troca do `elect` após `docker kill` do detentor | 5 | 57177,7 | 319,3 | 56778,0 | 57563,0 | 0 |

Para contraste (1 repetição, não atende R7): com `docker stop`, `lock` troca em 5,0 ms e `elect` em 3,5 ms. CSVs: `resultados/2026-10-26_214*_e8_troca_*.csv`.

## Análise: previsão × resultado × teoria

| # | Previsão | Resultado | Situação |
|---|---|---|---|
| 1 | Termo sobe só com troca de líder; revisão sobe a cada escrita, em ordem única para todas as chaves | revisões 58–63 alternando `/e8/a`, `/e8/b`, `/e8/c`; termo constante (2) sem troca de líder; nos E5–E7 o termo sobe 1 a cada troca | ✅ confirmada |
| 2 | B espera e assume cerca de 10 s depois da queda; no `elect` vence quem pediu primeiro, não o maior ID | `lock`: B esperou e assumiu em 7,9 ± 1,5 s ✅. `elect`: venceu a menor `create_revision` ✅, mas a troca levou 57,2 s ❌ | ⚠️ parcial |

**Discussão**
1. **Relógios lógicos (Q9).** O termo é a época de liderança e só muda com eleição. A revisão é um contador global que dá ordem total a todas as escritas, como um relógio de Lamport único mantido pelo líder através do log. Não é um relógio vetorial: não registra concorrência, porque o Raft serializa todas as escritas.
2. **Por que menos de 10 s no `lock`.** O cliente renova o lease periodicamente (a cada cerca de um terço do TTL). Quando o detentor morre, o tempo restante do lease fica entre cerca de 2/3 do TTL e o TTL inteiro: 6,7 a 10 s. O medido foi 7,0 a 10,4 s.
3. **`elect` × `lock` (achado).** `etcdctl lock` tem `--ttl` (padrão 10 s); `etcdctl elect` não tem essa opção e usa a sessão padrão de 60 s. Pelo mesmo raciocínio do item 2, a troca levou cerca de 57 s. Consequência prática: um candidato que morre de forma abrupta segura a liderança da aplicação por até 1 minuto. Com `docker stop`, o `etcdctl` revoga o lease ao sair, e a troca é imediata (3,5–5 ms).
4. **Bully e Anel (Q8, S1).** No Bully vence o maior ID, e no Anel a mensagem de eleição circula pelo anel; nenhum dos dois tem termos, então numa partição podem existir dois líderes. No `elect` do etcd vence a menor `create_revision` (ordem de chegada), e a exclusão é garantida pelo consenso do Raft por baixo: um voto por termo, restrição de log e termo maior.
5. **Fencing token (S4).** A pegou a trava com token 113 (TTL 5 s) e pausou 9 s; o lease venceu e B pegou a trava com token 114. Quando A acordou, a gravação **com** fencing (condicionada à existência da chave com token 113) foi recusada, e a gravação **sem** fencing sobrescreveu o trabalho de B.

## Questões que este experimento sustenta
Q8 (eleição × Bully/Anel), Q9 (termo e revisão como relógios lógicos), Q13 (exclusão mútua e eleição), S1, S4 (fencing token).
