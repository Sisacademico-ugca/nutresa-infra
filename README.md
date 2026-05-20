# 🏭 Infraestructura TI — Servicios Nutresa

**Proyecto Final · Administración de Infraestructura TI**  
Universidad del Quindío — Ingeniería de Sistemas y Computación · 2026-1

## 👥 Equipo
| Nombre | Rol |
|--------|-----|
| Anderson Fonseca López | Ing. de Infraestructura |
| John Alejandro González Cardenas | Administrador de Redes |
| Juan Carlos Pinzón | Ing. de Seguridad |
| María Jazmín Valencia Muñoz | DBA |
| Jhony Alexander Villanueva Ortiz | Ing. de Sistemas |

---

## 🗂️ Estructura del Proyecto

```
nutresa-infra/
├── docker-compose.yml        ← Orquestación completa
├── .env                      ← Variables de entorno (NO subir a Git)
├── .gitignore
│
├── nginx/                    ← srv-web (VLAN 40 - DMZ)
│   ├── Dockerfile
│   ├── conf/nginx.conf
│   └── html/index.html
│
├── mysql/                    ← srv-db (VLAN 10)
│   └── init/01_init.sql
│
├── nfs/                      ← srv-nfs (VLAN 10)
│   └── exports
│
├── scripts/
│   ├── deploy.sh             ← Despliegue de servicios
│   ├── backup.sh             ← Respaldo automático
│   ├── monitor.sh            ← Monitoreo en tiempo real
│   └── firewall.sh           ← Reglas iptables
│
└── monitoring/               ← Portainer (gestión visual)
```

---

## 🌐 Arquitectura de Red

| VLAN | Subred (Packet Tracer) | Subred (Docker) | Servicios |
|------|------------------------|-----------------|-----------|
| VLAN 10 — Servidores | 192.168.10.0/24 | 172.20.10.0/24 | srv-db · srv-ntp · srv-nfs |
| VLAN 20 — Administración | 192.168.20.0/24 | — | SW-Admin |
| VLAN 30 — Usuarios | 192.168.30.0/24 | — | PC-Usuario1/2 |
| VLAN 40 — DMZ | 192.168.40.0/24 | 172.20.40.0/24 | srv-web |

---

## 🚀 Inicio Rápido

### Prerrequisitos
- Docker Desktop instalado y corriendo
- Git

### 1. Clonar el repositorio
```bash
git clone <url-del-repo>
cd nutresa-infra
```

### 2. Crear el archivo .env
```bash
cp .env.example .env
# Editar las contraseñas antes de continuar
```

### 3. Dar permisos a los scripts
```bash
chmod +x scripts/*.sh
```

### 4. Desplegar
```bash
./scripts/deploy.sh up
```

### 5. Verificar
| Servicio | URL |
|----------|-----|
| Sitio Web (Nginx) | http://localhost |
| Portainer (gestión) | http://localhost:9000 |
| NTP | UDP localhost:123 |
| NFS | localhost:2049 |

---

## 📋 Scripts disponibles

```bash
# Despliegue
./scripts/deploy.sh up        # Levantar todo
./scripts/deploy.sh down      # Detener todo
./scripts/deploy.sh restart   # Reiniciar
./scripts/deploy.sh status    # Ver estado
./scripts/deploy.sh logs srv-web  # Ver logs de un servicio

# Backup
./scripts/backup.sh           # Ejecutar backup manual

# Monitoreo
./scripts/monitor.sh          # Reporte único
./scripts/monitor.sh --watch  # Monitoreo continuo (cada 10s)

# Firewall (requiere sudo)
sudo ./scripts/firewall.sh apply   # Aplicar reglas
sudo ./scripts/firewall.sh status  # Ver reglas activas
sudo ./scripts/firewall.sh reset   # Limpiar reglas
```

---

## 🔒 Seguridad implementada

- MySQL no expuesto al exterior (solo acceso interno vía red Docker)
- Usuario de solo lectura `nutresa_web` para la aplicación web
- Headers de seguridad en Nginx (X-Frame-Options, X-XSS-Protection)
- Versión de Nginx ocultada (`server_tokens off`)
- Reglas iptables por VLAN
- Variables sensibles en `.env` (fuera del repositorio Git)

---

## 📦 Servicios y puertos

| Contenedor | IP Docker | Puerto Host | Descripción |
|-----------|-----------|-------------|-------------|
| srv-web | 172.20.40.10 | 80, 443 | Nginx Web Server |
| srv-db | 172.20.10.10 | — (interno) | MySQL 8.0 |
| srv-ntp | 172.20.10.11 | 123/UDP | Servidor NTP |
| srv-nfs | 172.20.10.12 | 2049 | Servidor NFS |
| portainer | 172.20.10.20 | 9000 | Panel de gestión |
