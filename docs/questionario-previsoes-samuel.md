# Questionário de previsões: Samuel (E5–E8 e E9-E5..E8)

**Como responder:** troque `[ ]` por `[x]` na opção que você acha que vai acontecer. Se quiser, escreva um comentário em "Obs.". Depois faça commit e push (`git commit -m "exp: respostas do questionario (Samuel)"`). O Claude monta o texto da previsão em cada README a partir das suas escolhas.

**Não existe resposta "certa" aqui.** É uma previsão: errar não tira nota, e a análise depois explica o porquê. Não pesquise a resposta nem rode nada antes; responda pelo raciocínio. Cada opção já traz uma justificativa diferente, e escolher a opção é escolher o raciocínio.

Leia antes o quadro Raft × ZAB em `docs/guia-do-trabalho.md` (seção 3).

---

## E5: falha do líder e perda de quórum (etcd)
**Mini-aula:**
- O líder manda um "estou vivo" (*heartbeat*) a cada 100 ms.
- Se um seguidor fica cerca de 1 s (*election timeout*, sorteado entre 1 e 2 s) sem ouvir o líder, ele se candidata, abre um novo **termo** e pede votos.
- Com 3 nós, a **maioria** é 2.

**1. Parando o líder, quanto tempo até existir um novo líder?**
- [ ] Menos de 100 ms: os seguidores percebem na hora.
- [ ] Entre 1 e 3 s: eles esperam o election timeout sem ouvir o líder e então fazem a eleição.
- [ ] Mais de 10 s: precisa de alguém (um administrador) para reconfigurar.

**2. O termo sobe quanto na nova eleição?**
- [ ] Sempre exatamente +1: cada eleição é um termo.
- [ ] +1 ou mais: se dois candidatos empatarem (*split vote*), há nova rodada com outro termo.
- [ ] Não muda: o termo só depende de escritas.

**3. Com 2 dos 3 membros parados (sem maioria), um `put` no único que restou…**
- [ ] Funciona: o nó grava sozinho e sincroniza quando os outros voltarem.
- [ ] Falha (timeout ou erro): sem maioria não há commit.

**4. E as leituras nesse nó único?**
- [ ] Linearizável falha e serializável responde: a linearizável precisa confirmar com a maioria, a serializável só lê a cópia local.
- [ ] Ambas respondem: ler não altera nada, então não precisa de maioria.
- [ ] Ambas falham: o nó para de atender quando perde a maioria.

Obs.:

---

## E6: partição de rede (etcd)
**Mini-aula:** vamos tirar o **líder** da rede interna. Ele continua ligado, e o cliente ainda o alcança, mas ele não fala mais com os outros 2. Agora existem dois "lados": o do líder sozinho (1 nó) e o da maioria (2 nós).

**1. O lado da maioria (2 nós)…**
- [ ] Elege um novo líder em poucos segundos: eles param de ouvir o líder e têm maioria para votar.
- [ ] Fica sem líder: o líder antigo ainda está vivo, então ninguém se candidata.

**2. O líder isolado…**
- [ ] Continua se achando líder para sempre, até a rede voltar.
- [ ] Percebe que perdeu a maioria e deixa de ser líder depois de algum tempo (*check quorum*).

**3. Um cliente ligado ao nó isolado tenta um `put`. Ele recebe…**
- [ ] Erro ou timeout: o nó isolado não consegue maioria para confirmar.
- [ ] OK: o nó grava e sincroniza depois.

**4. Na partição, o etcd prefere…**
- [ ] Consistência (C): recusa operações do lado minoritário para não haver duas versões dos dados.
- [ ] Disponibilidade (A): os dois lados continuam atendendo e resolvem os conflitos depois.

Obs.:

---

## E7: recuperação (etcd)
**Mini-aula:**
- Quando um nó volta, ele precisa receber o que perdeu.
- Se faltam poucas entradas, o líder envia **as linhas do log** que faltam.
- Se o log antigo já foi apagado (compactado depois de um **snapshot**, uma "foto" do estado), o líder envia **a foto inteira**.

**1. O antigo líder, ao voltar, retorna como…**
- [ ] Líder: ele era o líder e retoma o posto.
- [ ] Seguidor: já existe um líder com **termo maior**, e ele adota esse termo.

**2. Quanto tempo até o RAFT INDEX dele alcançar o dos outros?**
- [ ] Menos de 1 s: são poucas entradas e a rede é local.
- [ ] Vários segundos: ele precisa reprocessar tudo desde o começo.

**3. Com `--snapshot-count` baixo (snapshot a cada 1000 entradas) e mais de 1000 escritas enquanto ele estava fora, ele recupera…**
- [ ] Por snapshot: o líder já não tem as entradas antigas no log e envia a foto.
- [ ] Pelo log, normalmente: o líder guarda todo o log para sempre.

**4. O estado final (chaves e revisão) fica…**
- [ ] Idêntico nos 3.
- [ ] Parecido, mas com pequenas diferenças no nó que voltou.

Obs.:

---

## E8: trava, eleição e relógios lógicos (etcd)
**Mini-aula:**
- `etcdctl lock` é uma **trava** (exclusão mútua): só um cliente a segura por vez. Ela fica presa a um **lease**, um "aluguel" com prazo (TTL) de 10 s, renovado enquanto o dono estiver vivo.
- `etcdctl elect` faz uma eleição de líder **da aplicação**, usando o mesmo mecanismo.
- A **revisão** do etcd é um número global que sobe a cada mudança em qualquer chave.

**1. O cliente A segura a trava e o B pede a mesma trava. O B…**
- [ ] Fica esperando até o A soltar ou morrer.
- [ ] Recebe erro imediato e precisa tentar de novo.

**2. Se o processo de A morrer de repente, quanto tempo até o B pegar a trava?**
- [ ] Quase imediato: o etcd percebe a queda da conexão na hora.
- [ ] Cerca de 10 s: só quando o lease de A expira sem renovação.

**3. A revisão do etcd…**
- [ ] É crescente para todas as chaves juntas (ordem total), como um relógio lógico de Lamport compartilhado.
- [ ] É separada por chave; cada chave tem seu contador.

**4. Comparado ao algoritmo do Valentão (Bully), o `elect` do etcd…**
- [ ] Não depende de quem tem o maior ID: vence quem pediu primeiro (a ordem da revisão).
- [ ] Também escolhe o processo de maior ID.

Obs.:

---

## E9-E5: falha do líder e perda de quórum (ZooKeeper)
**Mini-aula:**
- No ZooKeeper, o "mandato" se chama **época**.
- Ela fica nos 32 bits mais altos do **zxid**, o número de cada transação (ex.: `0x300000006` = época 3, transação 6).
- A eleição usa o algoritmo FLE: vence quem tem o histórico mais novo e, em caso de empate, o maior ID.

**1. A eleição do ZooKeeper, comparada à do etcd, será…**
- [ ] Mais rápida.
- [ ] Parecida (alguns segundos).
- [ ] Mais lenta.

**2. Depois da eleição, no zxid…**
- [ ] A época sobe (+1) e o contador recomeça do zero.
- [ ] A época fica igual e só o contador continua.

**3. Sem maioria (2 servidores parados), o que restou…**
- [ ] Recusa escritas, mas responde leituras.
- [ ] Para de atender clientes totalmente.
- [ ] Atende tudo.

Obs.:

---

## E9-E6: partição (ZooKeeper)
**1. O líder isolado da rede interna…**
- [ ] Entra em estado de procura de líder (LOOKING) e deixa de ser líder.
- [ ] Continua líder até a rede voltar.

**2. Um cliente conectado a ele…**
- [ ] Perde a conexão e o kazoo tenta outro servidor (se tiver a lista).
- [ ] Continua lendo e escrevendo normalmente.

**3. O lado majoritário…**
- [ ] Elege outro líder em poucos segundos.
- [ ] Espera o líder antigo voltar.

Obs.:

---

## E9-E7: recuperação (ZooKeeper)
**Mini-aula:** ao voltar, o servidor sincroniza com o líder de um destes jeitos:
- **DIFF:** recebe só as transações que faltam;
- **SNAP:** recebe a foto inteira;
- **TRUNC:** apaga transações que ele tinha e o grupo não confirmou.

**1. Um servidor que ficou pouco tempo fora (poucas escritas) sincroniza por…**
- [ ] DIFF: faltam poucas transações, e o líder as tem em memória.
- [ ] SNAP: o ZooKeeper sempre envia a foto inteira.
- [ ] TRUNC.

**2. Até o zxid dele igualar o dos outros…**
- [ ] Menos de 1 s depois de ele voltar ao ensemble.
- [ ] Vários segundos.

Obs.:

---

## E9-E8: trava e eleição com znodes (ZooKeeper)
**Mini-aula:**
- Um znode **efêmero** some quando a **sessão** do cliente acaba.
- Um znode **sequencial** recebe um número crescente no nome (`trava-0000000001`).
- A receita de trava funciona assim: cada cliente cria um efêmero sequencial, e quem tem o **menor número** é o dono.

**1. Quando o dono solta a trava, quem é avisado?**
- [ ] Só o próximo da fila (cada um observa apenas o anterior), o que evita uma "manada" de avisos.
- [ ] Todos os que estão esperando, e eles disputam a trava.

**2. Se o cliente dono morrer de repente, a trava libera…**
- [ ] Quando a **sessão expira** (session timeout, alguns segundos), como o lease do etcd.
- [ ] Na hora, porque o znode some instantaneamente.

**3. Época (ZAB) × termo (Raft):**
- [ ] São a mesma ideia: um número de mandato que cresce a cada novo líder e serve para recusar mensagens de líderes antigos.
- [ ] São diferentes: a época conta transações, o termo conta líderes.

Obs.:
