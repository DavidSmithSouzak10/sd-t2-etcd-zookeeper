# Roteiro de gravação das demonstrações

Usado nos blocos 3 e 4 do seminário (PDF, seção 11): caminho de uma operação (E2), replicação (E3), falha e partição (E5/E6), recuperação (E7) e a ênfase no ZooKeeper (E9).

Cada demo é um comando do `seminario/demo.sh`. Ele roda em segundos, mostra na tela cada comando antes de executá-lo, destaca os valores com `>>>` e **termina com um quadro RESUMO**: líder antes → depois, tempo medido, valor antes e valor depois.

Cada execução grava valores únicos, com a hora no final (`producao-234253`, `antes-234305`…). Assim, o que aparece nas cópias só pode ter vindo da escrita que acabou de acontecer.

Os nomes dos nós e os números mudam a cada execução. Onde estiver `[X]`, leia o valor no RESUMO.

<br>

---

<br>

## Antes de gravar

1. Docker Desktop aberto.
2. No VS Code, feche o painel do Claude Code (a conversa não se perde).
3. Abra um terminal **Git Bash** (setinha ao lado do `+`) e rode:
   ```bash
   cd sd-t2-etcd-zookeeper
   export PS1='\n$ '
   clear
   ```
4. Aumente a fonte do terminal (Ctrl + `+` umas 3 vezes).
5. Se os clusters não estiverem ligados: `seminario/demo.sh preparar` (precisa terminar em `VALIDAÇÃO OK (todos)`).
6. No Docker Desktop, abra a setinha de `t5-etcd` e de `t5-zk` para mostrar os 4 contêineres de cada um.
7. Grave com Win + Alt + R (o mesmo atalho começa e para). Um vídeo por demo, com `clear` antes de cada uma.

Se algo der errado no meio: `seminario/demo.sh limpar` e repetir aquela demo.

**Como falar:** diga o "antes", rode o comando, **espere o RESUMO aparecer** e só então diga o "depois", apontando as linhas do RESUMO. Se errar a fala, não precisa rodar de novo: corte na edição.

<br>

---

<br>

## Docker

> "Este é o nosso ambiente no Docker Desktop. Montamos dois laboratórios, cada um como um projeto do Docker Compose.
>
> O **t5-etcd** tem quatro contêineres. O **etcd1**, o **etcd2** e o **etcd3** são os três nós do etcd: cada um roda o programa etcd e guarda **a sua própria cópia do banco**. O **etcd-cliente** é um contêiner Python que usamos para fazer medições de dentro da rede.
>
> O **t5-zk** tem a mesma estrutura com o ZooKeeper: **zk1**, **zk2** e **zk3** são os três servidores, e o **zk-cliente** é o cliente.
>
> Tudo roda só em contêineres, sem máquina virtual. Cada nó tem limite de 256 MB de memória, e o total fica abaixo de 1 GB.
>
> Cada laboratório tem duas redes: a **interna**, por onde os nós conversam entre si para fazer o consenso, e a **de clientes**, por onde os programas fazem pedidos. Separar as duas é o que nos permite simular uma partição: tiramos um nó da rede interna, e ele continua acessível ao cliente."

Opcional, na aba **Images**:

> "As imagens têm versão fixa: etcd 3.5.17, ZooKeeper 3.9.6 e Python 3.12. Isso garante que qualquer pessoa suba exatamente o mesmo ambiente."

<br>

---

<br>

## E2: caminho de uma escrita

```bash
seminario/demo.sh e2
```

**Antes de rodar:**

> "Agora nós vamos rodar o teste do **caminho de uma escrita**, que vai gravar um valor mandando o pedido para um nó **seguidor**, e não para o líder. O resultado esperado é que a escrita dê certo e que o valor apareça **nas três cópias**, com o **RAFT INDEX subindo igual nos três**, porque no Raft só o líder escreve: o seguidor encaminha o pedido ao líder, o líder manda a entrada para os outros dois e confirma quando a maioria gravou."

**Depois do resultado (no RESUMO):**

> "O líder é o `[X]`, e mandamos a escrita para o seguidor `[Y]`. O RAFT INDEX estava igual nos três antes e subiu igual nos três depois. Lendo a cópia de cada nó, sem consultar o líder: antes, os três tinham o valor anterior; depois, os três têm `producao-[hora]`, o valor que acabamos de gravar. E o termo não mudou, porque escrita não muda o mandato do líder."

Se perguntarem por que o índice subiu mais de 1: o healthcheck do Docker também passa pelo log do Raft, a cada 5 segundos.

<br>

---

<br>

## E3: replicação

```bash
seminario/demo.sh e3
```

**Antes de rodar:**

> "Agora nós vamos rodar o teste de **replicação**, que vai abrir um *watch*, uma espécie de assinatura de mudanças, no etcd3, gravar um valor no etcd1 e ler esse valor no etcd2. O resultado esperado é que o etcd2 já devolva o valor novo e que o etcd3 seja avisado sozinho, porque toda escrita confirmada está replicada nos três nós, e a leitura padrão do etcd é **linearizável**: sempre vê a última escrita confirmada."

**Depois do resultado (no RESUMO):**

> "Escrevemos `azul-[hora]` no etcd1, o etcd2 leu exatamente esse valor, o *watch* no etcd3 recebeu o aviso `PUT` com o mesmo valor, e as três cópias têm esse valor. Nos nossos experimentos, o aviso do *watch* chegou em 6,4 milissegundos, em média."

<br>

---

<br>

## E5: falha do líder

```bash
seminario/demo.sh e5
```

**Antes de rodar:**

> "Agora nós vamos rodar o teste de **falha**, que vai derrubar o líder de forma abrupta, com `docker kill`. O resultado esperado é que os outros dois elejam um **novo líder em um a dois segundos, com o termo aumentado em um**. Isso acontece porque o líder para de mandar *heartbeats*: quando o tempo de espera de um seguidor estoura, ele se candidata num termo novo e, com 2 dos 3 votos, que é a maioria, vence."

**Depois do resultado (no RESUMO):**

> "O líder era o `[X]`, no termo `[T]`. Depois do kill, o `[Y]` virou líder no termo `[T+1]`, e a eleição levou `[tempo]` milissegundos, do kill até um sobrevivente anunciar o novo líder. Antes da queda, as três cópias tinham `antes-[hora]`. Com só dois dos três nós vivos, a escrita `depois-[hora]` foi aceita, porque dois ainda são maioria. E quando religamos o `[X]`, ele voltou como **seguidor** e já tem `depois-[hora]`, que foi gravado enquanto ele estava fora. Nos experimentos, medindo cinco vezes, a eleição levou 1,46 segundo, em média."

<br>

---

<br>

## E6: partição

```bash
seminario/demo.sh e6
```

**Antes de rodar:**

> "Agora nós vamos rodar o teste de **partição**, que vai desconectar o líder da rede interna, mantendo ele acessível ao cliente. O resultado esperado é que o **lado com dois nós eleja outro líder e continue aceitando escritas**, enquanto o **líder isolado recusa escritas**, porque sozinho ele não tem maioria para confirmar nada. Com isso vemos se o etcd escolhe consistência ou disponibilidade."

**Depois do resultado (no RESUMO):**

> "O líder `[X]` ficou isolado no termo `[T]`, e o lado com dois nós elegeu o `[Y]` no termo `[T+1]` em `[tempo]` milissegundos. No isolado, a escrita `ISOLADO-[hora]` e a leitura deram erro de tempo esgotado, porque as duas precisam da maioria. Na maioria, a escrita `NOVO-[hora]` deu OK. E nas cópias: o isolado ainda tem `ANTIGO-[hora]`, e os outros dois têm `NOVO-[hora]`. Ou seja, diante de uma partição o etcd escolhe **consistência**: o lado minoritário fica indisponível, e o valor dele nunca é confirmado como atual."

O E6 deixa o nó isolado: grave o E7 logo em seguida.

<br>

---

<br>

## E7: recuperação

```bash
seminario/demo.sh e7
```

**Antes de rodar:**

> "Agora nós vamos rodar o teste de **recuperação**, que vai religar o nó que isolamos. O resultado esperado é que ele **volte como seguidor, adote o termo novo e fique com o mesmo RAFT INDEX** dos outros, porque ele recebe do líder um termo maior que o dele, e o líder manda só as entradas que ele perdeu."

**Depois do resultado (no RESUMO):**

> "O `[X]` voltou como seguidor e foi do termo `[T]` para o `[T+1]`. O RAFT INDEX ficou igual nos três, e ele alcançou os outros em `[tempo]` milissegundos depois de religado. Nas cópias, os três têm `NOVO-[hora]`. A escrita `ISOLADO-[hora]`, que tentamos fazer nele enquanto estava isolado, nunca existiu, porque nunca teve a maioria."

<br>

---

<br>

## E9: ZooKeeper

```bash
seminario/demo.sh e9
```

**Antes de rodar:**

> "Agora nós vamos rodar o mesmo teste de falha no **ZooKeeper**, que é a nossa ênfase, derrubando o líder com `docker kill`. O resultado esperado é um novo líder com a **época aumentada em um e o contador zerado**, porque no ZooKeeper cada operação tem um zxid: a parte alta é a época, que é o equivalente do termo do Raft, e cada novo líder abre uma época nova."

**Depois do resultado (no RESUMO):**

> "O líder era o `[X]`, na época `[N]`. O `[Y]` virou líder na época `[N+1]`, e a eleição levou `[tempo]` milissegundos. Antes da queda, os três servidores tinham `antes-[hora]`. Com dois servidores, a escrita `depois-[hora]` foi aceita, e o servidor que voltou já tem esse valor. Nos experimentos, essa eleição levou 0,38 segundo, contra 1,46 do etcd, porque no ZooKeeper os seguidores percebem na hora que a conexão com o líder caiu, enquanto o etcd espera o tempo de espera estourar."

<br>

---

<br>

## Números para ter na ponta da língua

| | etcd | ZooKeeper |
|---|---|---|
| Eleição após queda abrupta | 1,46 ± 0,18 s | 0,38 ± 0,09 s |
| Eleição numa partição | 0,94 ± 0,24 s | 3,6 ± 0,3 s |
| Leitura padrão × leitura atual | linearizável 1,82 ms × serializável 0,65 ms | local 1,03 ms × `sync` + leitura 3,25 ms |
| Troca de trava após a morte do dono | `lock` 7,9 s; `elect` 57 s (aluguel de 60 s) | 7,9 s (sessão de 10 s) |
| Recuperação de um nó atrasado | cerca de 6,5 s (quase tudo reconexão); snapshot quando o log foi compactado | 2,5 s, DIFF |
