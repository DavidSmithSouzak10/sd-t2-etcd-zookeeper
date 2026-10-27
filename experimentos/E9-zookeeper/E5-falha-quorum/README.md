# E9/E5 — Falha e quórum no ZooKeeper

> Roteiro: PDF §9.5, ênfase D. Rodar `scripts/validar.sh zk` antes (precisa terminar em `VALIDAÇÃO OK`).

## Objetivo
Repetir o E5 da bateria comum no ensemble ZooKeeper. Comparar época ZAB × termo Raft e os tempos de eleição.

## Previsão da dupla (escrever ANTES de executar — não editar depois)
> Registrada em 2026-10-26 21:11, antes de qualquer execução (ver `docs/uso-ia.md`).

- **Parar o líder:** esperamos uma eleição mais rápida que a do etcd, porque ao parar o contêiner as conexões TCP fecham e os seguidores percebem na hora, sem esperar timeout. A época do zxid sobe 1 e o contador recomeça.
- **Sem maioria:** esperamos que o servidor restante pare de atender leituras e escritas, porque sem quórum ele sai do ensemble (o modo *read-only* está desligado). Diferente do etcd, onde a leitura serializável ainda responde.

## Procedimento
Parar o líder: tempo até novo líder ≥ 5× e **nova época no zxid** (`srvr.py`, `currentEpoch`). Parar o 2º servidor: o que falha para leitura e escrita?

Script reproduzível: `executar.sh` (escrito em 26/10, antes da previsão; ainda não executado).

## Evidências
| Arquivo | O que mostra |
|---|---|
| _pendente_ | |

## Medições (≥ 5 repetições — R7)
_pendente_

## Análise: previsão × resultado × teoria × etcd
_pendente_

## Questões que este experimento sustenta
_preencher_
