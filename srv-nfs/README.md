# Servidor de Almacenamiento Compartido (NFS) - Servicios Nutresa

Este módulo contiene la configuración del almacenamiento seguro y redundante para la infraestructura de TI de Servicios Nutresa.

## Componentes Implementados
- **RAID 5:** Configurado con 3 discos para tolerancia a fallos a nivel de hardware.
- **LVM:** Volumen lógico (`lv_compartido`) montado en `/mnt/nutresa_datos` para permitir escalabilidad en caliente.
- **NFS Server:** Dockerizado y exponiendo el almacenamiento a la red interna corporativa (`192.168.0.0/16`).

## Instrucciones de Despliegue
1. Asegúrese de que el volumen LVM esté montado en `/mnt/nutresa_datos`.
2. Nade hasta esta carpeta e inicie el contenedor:
   ```bash
   docker compose up -d
