#!/usr/bin/env bash
# Isola um nó da rede INTERNA (tráfego de consenso) mantendo-o na rede de clientes.
# Uso: scripts/particionar.sh isolar|religar|estado <no>
#   nós: etcd1 etcd2 etcd3 zk1 zk2 zk3
source "$(dirname "$0")/lib.sh"

acao="$1"; no="$2"
case "$no" in
  etcd*) rede="t5-etcd_interna"; ip="${ETCD_IP_INTERNA[$no]}" ;;
  zk*)   rede="t5-zk_interna";   ip="${ZK_IP_INTERNA[$no]}" ;;
  *) erro "uso: $0 isolar|religar|estado <etcd1..3|zk1..3>"; exit 2 ;;
esac
[ -n "$ip" ] || { erro "nó desconhecido: $no"; exit 2; }

case "$acao" in
  isolar)
    docker network disconnect "$rede" "$no" && ok "$(agora_iso) $no desconectado de $rede (segue na rede de clientes)" ;;
  religar)
    # mesmo IP: os pares conhecem o nó pelo endereço anunciado
    docker network connect --ip "$ip" "$rede" "$no" && ok "$(agora_iso) $no religado a $rede com IP $ip" ;;
  estado)
    docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}={{$v.IPAddress}} {{end}}' "$no" ;;
  *) erro "ação inválida: $acao"; exit 2 ;;
esac
