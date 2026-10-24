#!/usr/bin/env bash
# Pré-condição de todo experimento: cluster saudável, exatamente 1 líder, réplicas em dia.
# Uso: scripts/validar.sh [etcd|zk|todos]   (padrão: etcd)
# Código de saída 0 = OK; diferente de 0 = NÃO prosseguir com o experimento.
source "$(dirname "$0")/lib.sh"

validar_etcd() {
  local falhas=0 lideres=0 indices=() termos=()
  info "etcd: verificando ${ETCD_MEMBROS[*]}"
  for m in "${ETCD_MEMBROS[@]}"; do
    local ip="${ETCD_IP_CLIENTE[$m]}"
    if [ "$(docker inspect -f '{{.State.Running}}' "$m" 2>/dev/null)" != "true" ]; then
      erro "$m não está rodando"; falhas=$((falhas+1)); continue
    fi
    # endpoint único: não deixa o cliente esconder a falha trocando de membro
    if ! ectl "$m" --endpoints="$ip:2379" --command-timeout=3s endpoint health >/dev/null 2>&1; then
      erro "$m ($ip) não saudável"; falhas=$((falhas+1)); continue
    fi
    # formato simple: endpoint, ID, versão, db, is_leader, is_learner, term, index, applied, erros
    local linha lider termo indice
    linha="$(ectl "$m" --endpoints="$ip:2379" --command-timeout=3s endpoint status -w simple 2>/dev/null)"
    lider="$(echo "$linha"  | awk -F', ' '{print $5}')"
    termo="$(echo "$linha"  | awk -F', ' '{print $7}')"
    indice="$(echo "$linha" | awk -F', ' '{print $8}')"
    [ "$lider" = "true" ] && lideres=$((lideres+1))
    termos+=("$termo"); indices+=("$indice")
    ok "$m saudável  líder=$lider termo=$termo raft_index=$indice"
  done
  if [ "$lideres" -ne 1 ]; then erro "esperado exatamente 1 líder, encontrado $lideres"; falhas=$((falhas+1)); fi
  if [ "$(printf '%s\n' "${termos[@]}" | sort -u | wc -l)" -gt 1 ]; then
    erro "membros em termos diferentes: ${termos[*]}"; falhas=$((falhas+1))
  fi
  # RAFT INDEX: os índices acima foram lidos em momentos diferentes (o healthcheck do compose
  # também escreve no log). Para comparar, uma só chamada consulta os 3 juntos; tenta até 3 vezes.
  local iguais=0 tentativa
  for tentativa in 1 2 3; do
    indices=($(ectl etcd1 --endpoints="$EP" --command-timeout=3s endpoint status -w simple 2>/dev/null | awk -F', ' '{print $8}'))
    if [ "${#indices[@]}" -eq 3 ] && [ "$(printf '%s\n' "${indices[@]}" | sort -u | wc -l)" -eq 1 ]; then iguais=1; break; fi
    sleep 1
  done
  if [ "$iguais" -eq 1 ]; then
    ok "RAFT INDEX igual nos 3 membros (${indices[0]})"
  else
    erro "RAFT INDEX diferente entre membros: ${indices[*]}"; falhas=$((falhas+1))
  fi
  # o cluster aceita escrita? (chave reservada à validação)
  if ectl etcd1 --endpoints="$EP" --command-timeout=3s put /_validacao "$(agora_iso)" >/dev/null 2>&1; then
    ok "escrita de teste aceita"
  else
    erro "escrita de teste falhou"; falhas=$((falhas+1))
  fi
  return "$falhas"
}

validar_zk() {
  local falhas=0
  info "zookeeper: verificando ${ZK_SERVIDORES[*]}"
  if [ "$(docker inspect -f '{{.State.Running}}' zk-cliente 2>/dev/null)" != "true" ]; then
    erro "zk-cliente não está rodando"; return 1
  fi
  # escrita de teste: o ensemble aceita escrita? (e garante uma transação para comparar zxid,
  # já que logo após a eleição um seguidor sem transações ainda reporta zxid 0x0)
  docker exec zk1 zkCli.sh -server 172.33.0.51:2181 create /_validacao x >/dev/null 2>&1
  # zkCli sai com código 1 se a operação falhar (o log dele cita "unknown error" do SASL mesmo no sucesso)
  if docker exec zk1 zkCli.sh -server 172.33.0.51:2181 set /_validacao "$(agora_iso)" >/dev/null 2>&1; then
    ok "escrita de teste aceita"
  else
    erro "escrita de teste falhou"; falhas=$((falhas+1))
  fi
  local saida lideres seguidores zxids tentativa
  for tentativa in 1 2 3; do
    saida="$(docker exec zk-cliente python /app/srvr.py)"
    zxids="$(echo "$saida" | sed -n 's/.*zxid=\(0x[0-9a-f]*\).*/\1/p' | sort -u | wc -l)"
    [ "$zxids" -eq 1 ] && break
    sleep 1
  done
  echo "$saida"
  lideres="$(echo "$saida" | grep -c 'modo=leader')"
  seguidores="$(echo "$saida" | grep -c 'modo=follower')"
  if [ "$lideres" -eq 1 ]; then ok "1 líder"; else erro "esperado 1 líder, encontrado $lideres"; falhas=$((falhas+1)); fi
  if [ "$seguidores" -eq 2 ]; then ok "2 seguidores"; else erro "esperado 2 seguidores, encontrado $seguidores"; falhas=$((falhas+1)); fi
  if [ "$zxids" -eq 1 ]; then ok "mesmo zxid nos 3"; else erro "zxid diferente entre servidores"; falhas=$((falhas+1)); fi
  return "$falhas"
}

alvo="${1:-etcd}"
total=0
case "$alvo" in
  etcd)  validar_etcd; total=$? ;;
  zk)    validar_zk;   total=$? ;;
  todos) validar_etcd; total=$?; validar_zk; total=$((total+$?)) ;;
  *) erro "uso: $0 [etcd|zk|todos]"; exit 2 ;;
esac
if [ "$total" -eq 0 ]; then ok "VALIDAÇÃO OK ($alvo)"; else erro "VALIDAÇÃO FALHOU ($alvo): $total problema(s) — não prossiga"; fi
exit "$total"
