-- ============================================================
--  Inicialización BD — Servicios Nutresa
--  Archivo: mysql/init/01_init.sql
--  Se ejecuta automáticamente al crear el contenedor srv-db
-- ============================================================

CREATE DATABASE IF NOT EXISTS nutresa_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE nutresa_db;

-- ─── Tabla de empleados ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS empleados (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  nombre      VARCHAR(100) NOT NULL,
  cargo       VARCHAR(100),
  departamento VARCHAR(80),
  email       VARCHAR(120) UNIQUE,
  activo      TINYINT(1) DEFAULT 1,
  creado_en   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ─── Tabla de servidores ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS servidores (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  nombre      VARCHAR(50) NOT NULL,
  ip_vlan     VARCHAR(20),
  vlan        VARCHAR(10),
  servicio    VARCHAR(50),
  estado      ENUM('activo','inactivo','mantenimiento') DEFAULT 'activo',
  creado_en   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ─── Tabla de logs de acceso ─────────────────────────────────
CREATE TABLE IF NOT EXISTS logs_acceso (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  usuario     VARCHAR(80),
  ip_origen   VARCHAR(45),
  accion      VARCHAR(200),
  resultado   ENUM('exito','fallo') DEFAULT 'exito',
  fecha       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ─── Datos iniciales ─────────────────────────────────────────
INSERT INTO servidores (nombre, ip_vlan, vlan, servicio) VALUES
  ('srv-web', '172.20.40.10', 'VLAN40-DMZ',         'Nginx Web Server'),
  ('srv-db',  '172.20.10.10', 'VLAN10-Servidores',  'MySQL 8.0'),
  ('srv-ntp', '172.20.10.11', 'VLAN10-Servidores',  'NTP Chrony'),
  ('srv-nfs', '172.20.10.12', 'VLAN10-Servidores',  'NFS Share');

INSERT INTO empleados (nombre, cargo, departamento, email) VALUES
  ('Anderson Fonseca López',      'Ing. de Infraestructura', 'TI', 'afonseca@nutresa.com'),
  ('John González Cardenas',      'Administrador de Redes',  'TI', 'jgonzalez@nutresa.com'),
  ('Juan Carlos Pinzón',          'Ing. de Seguridad',       'TI', 'jcpinzon@nutresa.com'),
  ('María Jazmín Valencia Muñoz', 'DBA',                     'TI', 'mjvalencia@nutresa.com'),
  ('Jhony Villanueva Ortiz',      'Ing. de Sistemas',        'TI', 'javillanueva@nutresa.com');

-- ─── Usuario de solo lectura para la app web ─────────────────
CREATE USER IF NOT EXISTS 'nutresa_web'@'%' IDENTIFIED BY 'WebRead@2026!';
GRANT SELECT ON nutresa_db.* TO 'nutresa_web'@'%';
FLUSH PRIVILEGES;
