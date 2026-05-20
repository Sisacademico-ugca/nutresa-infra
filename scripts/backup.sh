#!/bin/bash
# ============================================================
#  backup.sh — Script de respaldo · Servicios Nutresa
#  Uso: ./scripts/backup.sh
#  Cron sugerido: 0 2 * * * /ruta/scripts/backup.sh
# ============================================================

set -euo pipefail

# ─── Configuración ───────────────────────────────────────────
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="./backups/backup_${DATE}.log"
DB_CONTAINER="srv-db"
DB_NAME="nutresa_db"
DB_USER="root"
DB_PASS="${MYSQL_ROOT_PASSWORD:-Nutresa@2026!}"
NFS_VOLUME="nutresa-infra_nfs_data"
RETAIN_DAYS=7

# Colores para la salida
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

log() { echo -e "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

# ─── Crear directorio de backups ─────────────────────────────
mkdir -p "$BACKUP_DIR"
log "${GREEN}=== Inicio de backup — $(date) ===${NC}"

# ─── 1. Backup de MySQL ──────────────────────────────────────
log "${YELLOW}[1/3] Respaldando base de datos MySQL...${NC}"
DUMP_FILE="${BACKUP_DIR}/mysql_${DB_NAME}_${DATE}.sql.gz"

if docker exec "$DB_CONTAINER" \
    mysqldump -u"$DB_USER" -p"$DB_PASS" \
    --single-transaction --routines --triggers \
    "$DB_NAME" | gzip > "$DUMP_FILE"; then
  SIZE=$(du -sh "$DUMP_FILE" | cut -f1)
  log "${GREEN}  ✓ MySQL backup: $DUMP_FILE ($SIZE)${NC}"
else
  log "${RED}  ✗ ERROR: Fallo en backup de MySQL${NC}"
  exit 1
fi

# ─── 2. Backup de volumen NFS ────────────────────────────────
log "${YELLOW}[2/3] Respaldando volumen NFS...${NC}"
NFS_FILE="${BACKUP_DIR}/nfs_data_${DATE}.tar.gz"

if docker run --rm \
    -v "${NFS_VOLUME}:/source:ro" \
    -v "$(pwd)/backups:/backup" \
    alpine tar czf "/backup/nfs_data_${DATE}.tar.gz" -C /source .; then
  SIZE=$(du -sh "$NFS_FILE" | cut -f1)
  log "${GREEN}  ✓ NFS backup: $NFS_FILE ($SIZE)${NC}"
else
  log "${RED}  ✗ ERROR: Fallo en backup de NFS${NC}"
fi

# ─── 3. Backup de logs de Nginx ──────────────────────────────
log "${YELLOW}[3/3] Respaldando logs de Nginx...${NC}"
LOG_ARCHIVE="${BACKUP_DIR}/nginx_logs_${DATE}.tar.gz"

docker exec srv-web tar czf - /var/log/nginx/ > "$LOG_ARCHIVE" 2>/dev/null && \
  log "${GREEN}  ✓ Logs backup: $LOG_ARCHIVE${NC}" || \
  log "${YELLOW}  ⚠ Advertencia: no se pudieron respaldar logs de Nginx${NC}"

# ─── 4. Limpiar backups antiguos ─────────────────────────────
log "${YELLOW}[Limpieza] Eliminando backups de más de ${RETAIN_DAYS} días...${NC}"
COUNT=$(find "$BACKUP_DIR" -name "*.gz" -mtime +${RETAIN_DAYS} | wc -l)
find "$BACKUP_DIR" -name "*.gz" -mtime +${RETAIN_DAYS} -delete
log "  → $COUNT archivos eliminados"

# ─── Resumen ─────────────────────────────────────────────────
log "${GREEN}=== Backup completado exitosamente — $(date) ===${NC}"
echo ""
echo "Archivos generados:"
ls -lh "${BACKUP_DIR}"/*"${DATE}"* 2>/dev/null || true
