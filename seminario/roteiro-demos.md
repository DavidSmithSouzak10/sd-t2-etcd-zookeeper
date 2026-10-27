# Roteiro das demonstrações (bloco 3 e 4 do seminário)

Cada demo é um comando de `seminario/demo.sh`, roda em segundos e imprime na tela cada comando antes de executá-lo. Grave a janela do terminal (Win + Alt + R) e corte só o tempo morto: nada de editar resultado.

## Antes de gravar
1. Docker Desktop aberto. Terminal **Git Bash** na raiz do repositório (no PowerShell os `.sh` não rodam).
2. Fonte do terminal grande (Ctrl + `+`) e janela maximizada.
3. `seminario/demo.sh preparar` → precisa terminar em `VALIDAÇÃO OK (todos)`.
4. Se algo der errado no meio: `seminario/demo.sh limpar` (religa e reinicia o que estiver fora e valida).

## Ordem e fala (cerca de 4 min no total)

| Vídeo | Comando | Quem | O que falar (enquanto roda) |
|---|---|---|---|
| 1. E2 caminho | `seminario/demo.sh e2` | David | "Escrevo num **seguidor**. Ele não grava sozinho: encaminha ao líder, que replica aos outros dois e confirma quando a **maioria** gravou. Repare no RAFT INDEX: subiu igual nos 3." |
| 2. E3 replicação | `seminario/demo.sh e3` | David | "Um *watch* aberto no etcd3, escrevo no etcd1 e leio no etcd2. O valor aparece no outro membro e o *watch* é avisado na hora: medimos 6,4 ms." |
| 3. E5 falha | `seminario/demo.sh e5` | Samuel | "Derrubo o líder com `kill`. Os seguidores ficam sem *heartbeat*, esperam o *election timeout* sorteado e elegem outro: o **termo** subiu 1. Medimos 1,46 s em 5 repetições. O antigo volta como seguidor." |
| 4. E6 partição | `seminario/demo.sh e6` | Samuel | "Tiro o líder da rede interna, mas o cliente ainda fala com ele. Sozinho, ele **recusa a escrita** e diz `no leader`; a leitura serializável devolve o valor **antigo**. Do outro lado, a maioria elegeu outro líder, termo maior, e aceitou `NOVO`. O etcd escolhe **consistência**." |
| 5. E7 recuperação | `seminario/demo.sh e7` | Samuel | "Religo o isolado. Ele volta como **seguidor**, adota o termo novo e alcança o mesmo RAFT INDEX; lê `NOVO`. A escrita que tentamos nele isolado nunca existiu." |
| 6. E9 ZooKeeper | `seminario/demo.sh e9` | Samuel | "Mesmo teste no ZooKeeper. O zxid tem a **época** nos bits altos: era 37, o novo líder abre a 38 e o contador zera. A eleição foi de 0,38 s, quase 4 vezes mais rápida que no etcd, porque a conexão fechada avisa os seguidores na hora." |

O vídeo 5 depende do 4 (o E7 religa o membro isolado no E6): grave os dois em sequência.

## Números para ter na ponta da língua
| | etcd | ZooKeeper |
|---|---|---|
| Eleição após queda abrupta | 1,46 ± 0,18 s | 0,38 ± 0,09 s |
| Eleição numa partição | 0,94 ± 0,24 s | 3,6 ± 0,3 s |
| Leitura padrão × leitura atual | linearizável 1,82 ms × serializável 0,65 ms | local 1,03 ms × `sync` + leitura 3,25 ms |
| Troca de trava após a morte do dono | `lock` 7,9 s; `elect` 57 s (sessão de 60 s) | 7,9 s (sessão de 10 s) |
| Recuperação de um nó atrasado | cerca de 6,5 s (quase tudo reconexão); snapshot quando o log foi compactado | 2,5 s, DIFF |
