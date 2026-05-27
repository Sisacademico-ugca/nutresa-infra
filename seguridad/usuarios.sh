#!/bin/bash

echo "Creando grupos..."

groupadd administradores
groupadd soporte

echo "Creando usuarios..."

useradd -m -G administradores admininfra
useradd -m -G soporte soporte1

echo "Asignando contraseñas..."

echo "Admininfra:Admin123*" | chpasswd
echo "soporte1:Soporte123*" | chpasswd

echo "Usuarios creados correctamente"
