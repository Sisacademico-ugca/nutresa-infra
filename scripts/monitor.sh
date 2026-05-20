#!/bin/bash
# ============================================================
#  monitor.sh — Monitoreo básico · Servicios Nutresa
#  Uso: ./scripts/monitor.sh
#       ./scripts/monitor.sh --watch   (actualiza cada 10s)
# ============================================================

WATCH_MODE=false
[[ "${1:-}" == "--watch" ]] && WATCH_MODE=true

# Colores
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# Contenedores del proyecto
CONTAINERS=("srv-web" "srv-db" "srv-ntp" "srv-nfs" "portainer")

check_container() {
  local name=$1
  local status
  status=$(docker inspect --format='{{.State.Status}}' "$name" 2>/dev/null || echo "no encontrado")
  local health
  health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}N/A{{end}}' "$name" 2>/dev/null || echo "N/A")

  if [[ "$status" == "running" ]]; then
    local symbol="${GREEN}●${NC}"
    local cpu mem
    cpu=$(docker stats --no-stream --format "{{.CPUPerc}}" "$name" 2>/dev/null || echo "N/A")
    mem=$(docker stats --no-stream --format "{{.MemUsage}}" "$name" 2>/dev/null || echo "N/A")
    printf "  $symbol ${BOLD}%-15s${NC}  estado: ${GREEN}%-10s${NC}  health: %-12s  CPU: %-8s  MEM: %s\n" \
      "$name" "$status" "$health" "$cpu" "$mem"
  else
    printf "  ${RED}●${NC} ${BOLD}%-15s${NC}  estado: ${RED}%s${NC}\n" "$name" "$status"
  fi
}

show_report() {
  clear
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║   Monitoreo Infraestructura — Servicios Nutresa      ║${NC}"
  echo -e "${BOLD}${CYAN}║   $(date '+%Y-%m-%d %H:%M:%S')                             ║${NC}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
  echo ""

  echo -e "${BOLD}[Contenedores]${NC}"
  for c in "${CONTAINERS[@]}"; do
    check_container "$c"
  done

  echo ""
  echo -e "${BOLD}[Host — Recursos del sistema]${NC}"
  echo -e "  CPU cores   : $(nproc)"
  echo -e "  Carga (1m)  : $(cat /proc/loadavg | awk '{print $1}')"
  MEM_TOTAL=$(free -h | awk '/^Mem:/{print $2}')
  MEM_USED=$(free -h  | awk '/^Mem:/{print $3}')
  echo -e "  Memoria     : ${MEM_USED} / ${MEM_TOTAL}"
  DISK=$(df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}')
  echo -e "  Disco (/)   : $DISK"

  echo ""
  echo -e "${BOLD}[Red Docker — VLANs simuladas]${NC}"
  docker network ls --filter "name=nutresa" --format \
    "  → {{.Name}} ({{.Driver}})" 2>/dev/null || echo "  (sin redes nutresa activas)"

  echo ""
  echo -e "${BOLD}[Comprobación de puertos]${NC}"
  for port_desc in "80:HTTP (srv-web)" "443:HTTPS (srv-web)" "9000:Portainer" "123:NTP (UDP)" "2049:NFS"; do
    port="${port_desc%%:*}"
    desc="${port_desc#*:}"
    if ss -tlnp 2>/dev/null | grep -q ":${port} " || \
       netstat -tlnp 2>/dev/null | grep -q ":${port} "; then
      echo -e "  ${GREEN}✓${NC} Puerto ${port} abierto  — ${desc}"
    else
      echo -e "  ${YELLOW}○${NC} Puerto ${port} no detectado — ${desc}"
    fi
  done

  echo ""
  echo -e "${BOLD}[Últimas 5 entradas de log — srv-web]${NC}"
  docker logs --tail 5 srv-web 2>/dev/null || echo "  (contenedor no disponible)"

  echo ""
  if $WATCH_MODE; then
    echo -e "${YELLOW}  Modo watch activo — actualizando cada 10s  (Ctrl+C para salir)${NC}"
  fi
}

if $WATCH_MODE; then
  while true; do
    show_report
    sleep 10
  done
else
  show_report
fi
