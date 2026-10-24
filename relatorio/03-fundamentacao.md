# 3. Fundamentação

## 3.1 O problema: coordenação e máquina de estados replicada
_pendente_

## 3.2 Raft (artigo seminal: Ongaro & Ousterhout, 2014)
Papéis, termos, eleição com timeout aleatório, replicação do log, commit por maioria, pre-vote, check quorum.
_pendente_

## 3.3 etcd: arquitetura e modelo de dados
MVCC e revisões, watch, leases, transações; leitura linearizável (ReadIndex) × serializável; snapshots, compactação, learners.
Diagrama próprio: `diagramas/arquitetura-etcd.*` → `figuras/`.
_pendente_

## 3.4 ZooKeeper e ZAB (Hunt et al., 2010; Junqueira, Reed & Serafini, 2011)
znodes efêmeros e sequenciais, sessões, zxid (época + contador), fases do ZAB, receitas de trava e eleição, leitura local e `sync`.
_pendente_

## 3.5 Conceitos da disciplina usados nos experimentos
Quórum, CAP/PACELC, Bully/Anel, relógios lógicos (Lamport), multicast de ordem total, estado global (Chandy-Lamport).
_pendente_
