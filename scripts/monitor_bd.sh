#!/bin/bash
# Script de monitoreo de base de datos — DBA Nutresa
# Autora: María Jazmín Valencia Muñoz

echo "=========================================="
echo " MONITOREO BASE DE DATOS NUTRESA"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

echo ""
echo "--- Estado del contenedor MySQL ---"
docker inspect --format='Status: {{.State.Status}} | Iniciado: {{.State.StartedAt}}' srv-db

echo ""
echo "--- Tablas en nutresa_db ---"
docker exec srv-db mysql -u root -pNutresa2026 nutresa_db \
  -e "SHOW TABLE STATUS\G" 2>/dev/null | grep -E "Name:|Rows:|Data_length:"

echo ""
echo "--- Conexiones activas ---"
docker exec srv-db mysql -u root -pNutresa2026 \
  -e "SHOW STATUS LIKE 'Threads_connected';" 2>/dev/null

echo ""
echo "--- Tamaño de la base de datos ---"
docker exec srv-db mysql -u root -pNutresa2026 \
  -e "SELECT table_schema AS 'BD', ROUND(SUM(data_length+index_length)/1024/1024,2) AS 'MB' FROM information_schema.tables GROUP BY table_schema;" 2>/dev/null

echo ""
echo "--- Usuarios MySQL ---"
docker exec srv-db mysql -u root -pNutresa2026 \
  -e "SELECT user, host FROM mysql.user;" 2>/dev/null

echo "=========================================="
