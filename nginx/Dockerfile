# ============================================================
#  srv-web — Nginx para Servicios Nutresa (DMZ · VLAN 40)
# ============================================================
FROM nginx:1.25-alpine

LABEL maintainer="Grupo Nutresa TI"
LABEL version="1.0"

# Instalar curl para el healthcheck
RUN apk add --no-cache curl

# Copiar configuración y archivos web
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY html/ /usr/share/nginx/html/

# Crear directorio de logs
RUN mkdir -p /var/log/nginx && \
    chown -R nginx:nginx /var/log/nginx

EXPOSE 80 443

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -f http://localhost/health || exit 1
