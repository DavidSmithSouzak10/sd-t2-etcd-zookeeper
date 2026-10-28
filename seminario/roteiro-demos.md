# Roteiro de gravação das demonstrações

Usado nos blocos 3 e 4 do seminário (PDF, seção 11): caminho de uma operação (E2), replicação (E3), falha e partição (E5/E6), recuperação (E7) e a ênfase no ZooKeeper (E9).

Cada demo é um comando do `seminario/demo.sh`. Ele roda em segundos e mostra na tela cada comando antes de executá-lo.

Os nomes dos nós e os números (quem é o líder, o termo, a época) mudam a cada execução. Onde estiver `[X]`, leia o valor na tela.

<br>

---

<br>

## Antes de gravar

1. Abrir o Docker Desktop.
2. Abrir no VS Code só a pasta `sd-t2-etcd-zookeeper`.
3. Abrir um terminal **Git Bash** (setinha ao lado do `+` no painel do terminal). No PowerShell os `.sh` não rodam.
4. Deixar o prompt limpo, aumentar a fonte (Ctrl + `+` umas 3 vezes) e subir os clusters:
   ```bash
   export PS1='\n$ '
   seminario/demo.sh preparar
   clear
   ```
   O `preparar` precisa terminar em `VALIDAÇÃO OK (todos)`.
5. No Docker Desktop, clicar na setinha de `t5-etcd` e de `t5-zk` para mostrar os 4 contêineres de cada um.
6. Gravar com Win + Alt + R (o mesmo atalho começa e para). Um vídeo por demo, com `clear` antes de cada uma.

Se algo der errado no meio: `seminario/demo.sh limpar` e repetir aquela demo.

**Como falar:** diga o "antes", rode o comando, **espere a saída terminar** e só então diga o "depois", apontando na tela o que está falando. Se errar a fala, não precisa rodar de novo: corte na edição.

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

> "Agora nós vamos rodar o teste do **caminho de uma escrita**, que vai gravar um valor mandando o pedido para um nó **seguidor**, e não para o líder. O resultado esperado é que a escrita dê certo e que o **RAFT INDEX suba igual nos três nós**, porque no Raft só o líder escreve: o seguidor encaminha o pedido ao líder, o líder manda a entrada para os outros dois e confirma quando a maioria gravou."

**Depois do resultado:**

> "Na primeira tabela, o líder é o `[X]` e o RAFT INDEX é igual nos três. Gravamos pelo `[Y]`, que é seguidor, e a resposta trouxe a revisão e o termo. Na segunda tabela, o índice subiu igual nos três, então todos receberam a escrita. E o termo não mudou, porque escrita não muda o mandato do líder."

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

**Depois do resultado:**

> "O etcd2 devolveu o valor que acabamos de gravar no etcd1, e o *watch* no etcd3 recebeu o aviso com o novo valor. Nos nossos experimentos, esse aviso chegou em 6,4 milissegundos, em média."

<br>

---

<br>

## E5: falha do líder

```bash
seminario/demo.sh e5
```

**Antes de rodar:**

> "Agora nós vamos rodar o teste de **falha**, que vai derrubar o líder de forma abrupta, com `docker kill`. O resultado esperado é que os outros dois elejam um **novo líder em um a dois segundos, com o termo aumentado em um**. Isso acontece porque o líder para de mandar *heartbeats*: quando o tempo de espera de um seguidor estoura, ele se candidata num termo novo e, com 2 dos 3 votos, que é a maioria, vence."

**Depois do resultado:**

> "Antes, o líder era o `[X]`, no termo `[T]`. Depois do kill, sobraram dois nós: o `[Y]` virou líder e o termo foi para `[T+1]`. Quando religamos o `[X]`, ele voltou como **seguidor**, porque já existe um líder com termo maior. Medindo cinco vezes, a eleição levou 1,46 segundo, em média."

Se o termo subir 2: "Subiu dois porque houve empate na primeira votação e foi preciso uma segunda rodada."

<br>

---

<br>

## E6: partição

```bash
seminario/demo.sh e6
```

**Antes de rodar:**

> "Agora nós vamos rodar o teste de **partição**, que vai desconectar o líder da rede interna, mantendo ele acessível ao cliente. O resultado esperado é que o **lado com dois nós eleja outro líder e continue aceitando escritas**, enquanto o **líder isolado recusa escritas**, porque sozinho ele não tem maioria para confirmar nada. Com isso vemos se o etcd escolhe consistência ou disponibilidade."

**Depois do resultado:**

> "No lado isolado, a escrita deu erro de tempo esgotado, e a leitura da cópia local devolveu o valor **ANTIGO**. No lado da maioria, a escrita do valor **NOVO** deu certo. Na tabela, o nó isolado aparece com **'no leader'** e ainda no termo antigo, e os outros dois têm um novo líder num termo maior. Ou seja, diante de uma partição o etcd escolhe **consistência**: o lado minoritário fica indisponível, mas nunca existem duas versões do dado."

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

**Depois do resultado:**

> "Os três estão no mesmo termo e com o mesmo RAFT INDEX, o nó religado é seguidor e lê o valor **NOVO**. A escrita **ISOLADO**, que tentamos fazer nele enquanto estava isolado, nunca existiu, porque nunca teve a maioria."

<br>

---

<br>

## E9: ZooKeeper

```bash
seminario/demo.sh e9
```

**Antes de rodar:**

> "Agora nós vamos rodar o mesmo teste de falha no **ZooKeeper**, que é a nossa ênfase, derrubando o líder com `docker kill`. O resultado esperado é um novo líder com a **época aumentada em um e o contador zerado**, porque no ZooKeeper cada operação tem um zxid: a parte alta é a época, que é o equivalente do termo do Raft, e cada novo líder abre uma época nova."

**Depois do resultado:**

> "Antes, a época era `[N]`. O novo líder é o `[zkX]`, na época `[N+1]`, com contador zero. Quando religamos o antigo, ele voltou como *follower* na época nova. Nos nossos testes, essa eleição levou 0,38 segundo, contra 1,46 do etcd, porque no ZooKeeper os seguidores percebem na hora que a conexão com o líder caiu, enquanto o etcd espera o tempo de espera estourar."

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
