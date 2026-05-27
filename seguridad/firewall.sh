#!/bin/bash

echo "Configuracion firewall UFW..."

#Resetear reglas anteriores
ufw --force reset

#Politicas por defecto
ufw default deny incoming
ufw default allow outgoing

#Permitir SSH
ufw allow 22/tcp

#Permitir HTTP
ufw allow 80/tcp

#Permitir HTTPS
ufw allow 443/tcp

#Permitir MSYQL solo red interna
ufw allow from 192.168.1.0/24 to any port 3306

#Permitir NFS
ufw allow 2049/tcp

#Activar firewall
ufw --force enable

#Mostrar estado 
ufw status verbose

echo "Firewall configurado correctamente"
