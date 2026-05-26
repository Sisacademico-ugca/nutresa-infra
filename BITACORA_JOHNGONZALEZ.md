# Bitácora — John Alejandro González Cardenas
## Administrador de Redes
## Proyecto Final: Infraestructura TI Nutresa
## Universidad del Quindío — 2026-1

---

## Entrada 1 — 2026-05-26

### Actividades realizadas
- Cloné el repositorio del grupo
- Instalé y configuré Docker Desktop con integración WSL2
- Levanté todos los servicios con docker compose up -d --build
- Verifiqué funcionamiento de Nginx en http://localhost
- Verifiqué Portainer en http://localhost:9000
- Simulé RAID 1 con loop devices en WSL2
- Configuré LVM sobre el RAID simulado
- Apliqué reglas de firewall con firewall.sh
- Creé usuarios Linux: dba_nutresa, lector_nutresa
- Configuré permisos sticky bit y setgid
- Ejecuté scripts de monitoreo y backup
- Revisé logs con journalctl

### Problemas encontrados
- Scripts con CRLF (Windows): solucionado con dos2unix
- sudo no encontrado en docker-desktop: solucionado usando Ubuntu WSL2
- Permission denied en docker: solucionado agregando usuario al grupo docker

### Evidencias
- Capturas de docker compose ps con todos los servicios Up
- Capturas de RAID: cat /proc/mdstat
- Capturas de LVM: pvs, vgs, lvs
- Capturas de monitor_bd.sh funcionando
