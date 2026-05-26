#!/bin/bash

# ==============================================================================
# PROYECTO FINAL: INFRAESTRUCTURA TI - SERVICIOS NUTRESA
# ROL: SysAdmin / Almacenamiento
# SCRIPT: Automatización de aprovisionamiento de almacenamiento (RAID 5 + LVM)
# ==============================================================================

# Colores para la salida en terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
ROJO='\033[0;31m'
NC='\033[0m' # Sin Color

echo -e "${AZUL}=================================================================${NC}"
echo -e "${AZUL}   Iniciando Configuración de Almacenamiento - Servicios Nutresa  ${NC}"
echo -e "${AZUL}=================================================================${NC}"

# 1. Validar que el script se ejecute como root
if [ "$EUID" -ne 0 ]; then
  echo -e "${ROJO}[ERROR] Este script debe ejecutarse con privilegios de administrador (sudo).${NC}"
  exit 1
fi

# 2. Actualizar repositorios e instalar herramientas necesarias
echo -e "\n${AZUL}[1/5] Instalando utilidades necesarias (mdadm y lvm2)...${NC}"
apt update -y && apt install mdadm lvm2 -y

# 3. Creación del Arreglo RAID 5
# Se asume la existencia de 3 discos duros virtuales vacíos: /dev/sdb, /dev/sdc y /dev/sdd
echo -e "\n${AZUL}[2/5] Creando arreglo RAID 5 (/dev/md0) con 3 dispositivos...${NC}"
if [ -b /dev/sdb ] && [ -b /dev/sdc ] && [ -b /dev/sdd ]; then
    # Desvincular cualquier rastro previo si existiera
    mdadm --stop /dev/md0 2>/dev/null
    
    # Crear arreglo con confirmación automática (--run)
    mdadm --create --verbose /dev/md0 --level=5 --raid-devices=3 /dev/sdb /dev/sdc /dev/sdd --run
    
    # Guardar configuración de forma persistente en el Host
    mdadm --detail --scan | tee -a /etc/mdadm/mdadm.conf
    update-initramfs -u
    echo -e "${VERDE}[OK] Arreglo RAID 5 configurado exitosamente.${NC}"
else
    echo -e "${ROJO}[ERROR] No se encontraron los tres discos requeridos (/dev/sdb, /dev/sdc, /dev/sdd).${NC}"
    exit 1
fi

# 4. Configuración de Capa LVM sobre el dispositivo RAID
echo -e "\n${AZUL}[3/5] Inicializando Capa LVM (PV, VG y LV)...${NC}"
# Crear el Volumen Físico (Physical Volume)
pvcreate /dev/md0

# Crear el Grupo de Volúmenes (Volume Group) para la empresa
vgcreate vg_nutresa /dev/md0

# Crear el Volumen Lógico (Logical Volume) ocupando el 100% del espacio disponible
lvcreate -l 100%FREE -n lv_compartido vg_nutresa
echo -e "${VERDE}[OK] Estructura LVM creada de forma dinámica.${NC}"

# 5. Formateo y creación del Sistema de Archivos
echo -e "\n${AZUL}[4/5] Creando sistema de archivos ext4 y punto de montaje...${NC}"
mkfs.ext4 /dev/vg_nutresa/lv_compartido
mkdir -p /mnt/nutresa_datos

# 6. Configurar montaje persistente en /etc/fstab de forma segura
echo -e "\n${AZUL}[5/5] Registrando montaje persistente en /etc/fstab...${NC}"
# Validar si ya se encuentra registrado para evitar duplicados
if ! grep -q "/mnt/nutresa_datos" /etc/fstab; then
    echo '/dev/vg_nutresa/lv_compartido /mnt/nutresa_datos ext4 defaults,nofail 0 2' | tee -a /etc/fstab
fi

# Notificar al kernel y a systemd los cambios en fstab
systemctl daemon-reload
mount -a

echo -e "\n${VERDE}=================================================================${NC}"
echo -e "${VERDE} [ÉXITO] El almacenamiento de Nutresa ha sido aprovisionado:     ${NC}"
echo -e "${VERDE} -> RAID 5 Activo                                                ${NC}"
echo -e "${VERDE} -> LVM Extensible Listo (vg_nutresa-lv_compartido)              ${NC}"
echo -e "${VERDE} -> Montado permanentemente en: /mnt/nutresa_datos                ${NC}"
echo -e "${VERDE}=================================================================${NC}\n"

# Mostrar resumen final en pantalla para la bitácora
df -h | grep nutresa
