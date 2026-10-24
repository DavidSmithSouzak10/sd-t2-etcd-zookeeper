#!/usr/bin/env bash
# Funções comuns aos scripts do Trabalho 2. Uso: source "$(dirname "$0")/lib.sh"

# Git Bash (Windows) reescreve argumentos que parecem caminhos (/config/x -> C:/Program Files/Git/config/x)
export MSYS_NO_PATHCONV=1

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export RAIZ

EP="172.31.0.31:2379,172.31.0.32:2379,172.31.0.33:2379"
ETCD_MEMBROS=(etcd1 etcd2 etcd3)
declare -A ETCD_IP_CLIENTE=([etcd1]=172.31.0.31 [etcd2]=172.31.0.32 [etcd3]=172.31.0.33)
declare -A ETCD_IP_INTERNA=([etcd1]=172.30.0.31 [etcd2]=172.30.0.32 [etcd3]=172.30.0.33)

ZK_SERVIDORES=(zk1 zk2 zk3)
declare -A ZK_IP_CLIENTE=([zk1]=172.33.0.51 [zk2]=172.33.0.52 [zk3]=172.33.0.53)
declare -A ZK_IP_INTERNA=([zk1]=172.32.0.51 [zk2]=172.32.0.52 [zk3]=172.32.0.53)

# python do host: no Windows o "python3" pode ser só o atalho da Microsoft Store
PY=""
for c in python3 python; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c "" >/dev/null 2>&1; then PY="$c"; break; fi
done
export PY
export PYTHONIOENCODING=utf-8   # acentos corretos no terminal do Windows

# caminho que o python do Windows entende (/c/x -> C:/x); em Linux/WSL devolve o mesmo caminho
caminho_host() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else echo "$1"; fi; }

ts()       { date +%Y-%m-%d_%H%M; }          # para nomes de arquivo
agora_iso(){ date +%Y-%m-%dT%H:%M:%S.%3N; }  # para dentro das evidências
agora_ms() { date +%s%3N; }                   # relógio em ms para medir intervalos

info() { printf '\033[36m[info]\033[0m %s\n' "$*"; }
ok()   { printf '\033[32m[ ok ]\033[0m %s\n' "$*"; }
erro() { printf '\033[31m[erro]\033[0m %s\n' "$*" >&2; }

# etcdctl dentro de um membro. ex.: ectl etcd1 --endpoints=$EP endpoint status -w table
ectl() { local m="$1"; shift; docker exec "$m" etcdctl "$@"; }

# Grava a saída de um comando como evidência: evidencia <dir-experimento> <descricao> -- <comando...>
# Acrescenta em <dir>/evidencias/AAAA-MM-DD_HHMM_<descricao>.txt um cabeçalho (data, comando) e a saída bruta.
evidencia() {
  local dir="$1" desc="$2"; shift 2
  [ "$1" = "--" ] && shift
  mkdir -p "$dir/evidencias"
  local arq="$dir/evidencias/$(ts)_${desc}.txt"
  {
    echo "# data: $(agora_iso)"
    echo "# comando: $*"
    echo "# ---"
  } >> "$arq"
  "$@" 2>&1 | tee -a "$arq"
  local rc=${PIPESTATUS[0]}
  echo "# exit=$rc" >> "$arq"
  info "evidência salva em ${arq#$RAIZ/}"
  return "$rc"
}
