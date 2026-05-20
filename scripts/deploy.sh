#!/bin/bash
# ============================================================
#  deploy.sh — Despliegue de servicios · Servicios Nutresa
#  Uso: ./scripts/deploy.sh [up|down|restart|status|logs]
# ============================================================

set -euo pipefail

ACTION="${1:-up}"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

COMPOSE_FILE="./docker-compose.yml"
ENV_FILE="./.env"

log()  { echo -e "[$(date '+%H:%M:%S')] $1"; }
ok()   { log "${GREEN}✓ $1${NC}"; }
warn() { log "${YELLOW}⚠ $1${NC}"; }
err()  { log "${RED}✗ $1${NC}"; exit 1; }

banner() {
  echo -e "${CYAN}${BOLD}"
  echo "  ╔═══════════════════════════════════════╗"
  echo "  ║  Servicios Nutresa — Deploy Script    ║"
  echo "  ╚═══════════════════════════════════════╝"
  echo -e "${NC}"
}

check_deps() {
  log "Verificando dependencias..."
  command -v docker      >/dev/null 2>&1 || err "Docker no está instalado"
  command -v docker      >/dev/null 2>&1 && docker compose version >/dev/null 2>&1 \
    || err "Docker Compose (plugin) no está disponible"
  [[ -f "$COMPOSE_FILE" ]] || err "No se encontró $COMPOSE_FILE"
  [[ -f "$ENV_FILE"     ]] || warn ".env no encontrado — usando valores por defecto"
  ok "Dependencias OK"
}

do_up() {
  log "Construyendo imágenes y levantando servicios..."
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d --build
  echo ""
  log "Esperando que los servicios estén saludables..."
  sleep 8

  echo ""
  echo -e "${BOLD}Estado final:${NC}"
  docker compose -f "$COMPOSE_FILE" ps

  echo ""
  ok "Infraestructura desplegada"
  echo -e "  → Web:       ${CYAN}http://localhost${NC}"
  echo -e "  → Portainer: ${CYAN}http://localhost:9000${NC}"
}

do_down() {
  warn "Deteniendo todos los contenedores..."
  docker compose -f "$COMPOSE_FILE" down
  ok "Servicios detenidos"
}

do_restart() {
  warn "Reiniciando infraestructura..."
  do_down
  sleep 2
  do_up
}

do_status() {
  echo -e "${BOLD}Estado de contenedores:${NC}"
  docker compose -f "$COMPOSE_FILE" ps
  echo ""
  echo -e "${BOLD}Uso de recursos:${NC}"
  docker stats --no-stream --format \
    "  {{.Name}}\tCPU: {{.CPUPerc}}\tMEM: {{.MemUsage}}" 2>/dev/null || true
}

do_logs() {
  SERVICE="${2:-}"
  if [[ -n "$SERVICE" ]]; then
    docker compose -f "$COMPOSE_FILE" logs -f --tail=50 "$SERVICE"
  else
    docker compose -f "$COMPOSE_FILE" logs -f --tail=20
  fi
}

# ─── Main ────────────────────────────────────────────────────
banner
check_deps

case "$ACTION" in
  up)      do_up ;;
  down)    do_down ;;
  restart) do_restart ;;
  status)  do_status ;;
  logs)    do_logs "$@" ;;
  *)
    echo "Uso: $0 [up|down|restart|status|logs [servicio]]"
    exit 1
    ;;
esac
