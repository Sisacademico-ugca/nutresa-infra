#!/bin/bash
# ============================================================
#  firewall.sh — Reglas de seguridad · Servicios Nutresa
#  Aplica políticas de acceso por VLAN usando iptables
#  Uso: sudo ./scripts/firewall.sh [apply|status|reset]
# ============================================================

set -euo pipefail

ACTION="${1:-apply}"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

log()  { echo -e "[$(date '+%H:%M:%S')] $1"; }

require_root() {
  [[ $EUID -eq 0 ]] || { echo -e "${RED}Ejecutar como root: sudo $0${NC}"; exit 1; }
}

apply_rules() {
  log "${YELLOW}Aplicando reglas de firewall para Nutresa...${NC}"

  # ── Política por defecto: denegar todo ──────────────────
  iptables -P INPUT   DROP
  iptables -P FORWARD DROP
  iptables -P OUTPUT  ACCEPT

  # ── Permitir loopback ───────────────────────────────────
  iptables -A INPUT -i lo -j ACCEPT

  # ── Permitir conexiones establecidas ────────────────────
  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

  # ── SSH: solo desde VLAN Admin (192.168.20.0/24) ────────
  iptables -A INPUT -p tcp --dport 22 -s 192.168.20.0/24 -j ACCEPT
  log "  ✓ SSH permitido desde VLAN Admin (192.168.20.0/24)"

  # ── HTTP/HTTPS: acceso público (DMZ) ────────────────────
  iptables -A INPUT -p tcp --dport 80  -j ACCEPT
  iptables -A INPUT -p tcp --dport 443 -j ACCEPT
  log "  ✓ HTTP/HTTPS permitido públicamente"

  # ── MySQL: solo desde VLAN Servidores ───────────────────
  iptables -A INPUT -p tcp --dport 3306 -s 172.20.10.0/24 -j ACCEPT
  iptables -A INPUT -p tcp --dport 3306 -j DROP
  log "  ✓ MySQL restringido a VLAN 10 (172.20.10.0/24)"

  # ── NFS: solo desde VLAN Servidores ─────────────────────
  iptables -A INPUT -p tcp --dport 2049 -s 172.20.10.0/24 -j ACCEPT
  iptables -A INPUT -p udp --dport 2049 -s 172.20.10.0/24 -j ACCEPT
  iptables -A INPUT -p tcp --dport 2049 -j DROP
  log "  ✓ NFS restringido a VLAN 10"

  # ── NTP: UDP 123 ────────────────────────────────────────
  iptables -A INPUT -p udp --dport 123 -j ACCEPT
  log "  ✓ NTP UDP/123 permitido"

  # ── Portainer: solo local ────────────────────────────────
  iptables -A INPUT -p tcp --dport 9000 -s 127.0.0.1    -j ACCEPT
  iptables -A INPUT -p tcp --dport 9000 -s 192.168.20.0/24 -j ACCEPT
  iptables -A INPUT -p tcp --dport 9000 -j DROP
  log "  ✓ Portainer restringido a localhost y VLAN Admin"

  # ── ICMP (ping) permitido internamente ──────────────────
  iptables -A INPUT -p icmp --icmp-type echo-request -s 192.168.0.0/16 -j ACCEPT

  # ── Log de paquetes rechazados ───────────────────────────
  iptables -A INPUT -j LOG --log-prefix "NUTRESA-DROP: " --log-level 4

  log "${GREEN}Reglas de firewall aplicadas correctamente.${NC}"
}

show_status() {
  echo ""
  echo "── iptables INPUT ──────────────────────────────"
  iptables -L INPUT -n -v --line-numbers
  echo ""
  echo "── iptables FORWARD ────────────────────────────"
  iptables -L FORWARD -n -v --line-numbers
}

reset_rules() {
  log "${YELLOW}Limpiando todas las reglas de iptables...${NC}"
  iptables -F
  iptables -X
  iptables -P INPUT   ACCEPT
  iptables -P FORWARD ACCEPT
  iptables -P OUTPUT  ACCEPT
  log "${GREEN}Reglas limpiadas — tráfico libre.${NC}"
}

require_root
case "$ACTION" in
  apply)  apply_rules ;;
  status) show_status ;;
  reset)  reset_rules ;;
  *)
    echo "Uso: sudo $0 [apply|status|reset]"
    exit 1
    ;;
esac
