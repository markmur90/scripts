#!/bin/bash
# Script mejorado de reparación 502 Bad Gateway

echo "🔧 Reparando error 502 Bad Gateway (versión mejorada)..."

# Variables
PROJECT_DIR="/home/markmur88/api_bank_h2"
VENV_PATH="/home/markmur88/envSIM"
SOCKET_PATH="$PROJECT_DIR/servers/gunicorn/api.sock"

# 1. Verificar entorno
echo "🔍 Verificando entorno..."
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Directorio del proyecto no encontrado: $PROJECT_DIR"
    exit 1
fi

if [ ! -f "$VENV_PATH/bin/gunicorn" ]; then
    echo "❌ Gunicorn no encontrado en: $VENV_PATH/bin/gunicorn"
    exit 1
fi

# 2. Detener servicios
echo "🛑 Deteniendo servicios..."
sudo supervisorctl stop coretransapi 2>/dev/null || true
sudo systemctl stop nginx 2>/dev/null || true

# 3. Limpiar sockets antiguos
echo "🧹 Limpiando sockets..."
sudo rm -f "$SOCKET_PATH"
sudo rm -f "/home/markmur88/api_bank_h2/servers/gunicorn/api.sock"

# 4. Verificar permisos del directorio
echo "�� Verificando permisos..."
sudo chown -R markmur88:www-data "$PROJECT_DIR"
sudo chmod 755 "$PROJECT_DIR"

# 5. Crear directorio de logs si no existe
echo "📝 Configurando logs..."
sudo mkdir -p /var/log/supervisor
sudo chown root:adm /var/log/supervisor
sudo chmod 750 /var/log/supervisor

# 6. Corregir configuración de supervisor con más variables de entorno
echo "⚙️ Corrigiendo configuración de supervisor..."
sudo tee /etc/supervisor/conf.d/coretransapi.conf > /dev/null <<EOF
[program:coretransapi]
directory=$PROJECT_DIR
command=$VENV_PATH/bin/gunicorn config.wsgi:application \\
  --bind unix:$SOCKET_PATH \\
  --workers 4 \\
  --timeout 120 \\
  --keep-alive 2 \\
  --max-requests 1000 \\
  --max-requests-jitter 100
autostart=true
autorestart=true
startsecs=10
startretries=3
stopwaitsecs=10
umask=007
stderr_logfile=/var/log/supervisor/coretransapi.err.log
stdout_logfile=/var/log/supervisor/coretransapi.out.log
user=markmur88
group=www-data
environment=\\
  PATH="$VENV_PATH/bin",\\
  DJANGO_SETTINGS_MODULE="config.settings",\\
  DJANGO_ENV="production",\\
  PYTHONPATH="$PROJECT_DIR",\\
  LANG="es_ES.UTF-8",\\
  LC_ALL="es_ES.UTF-8"
EOF

# 7. Recargar supervisor
echo "🔄 Recargando supervisor..."
sudo supervisorctl reread
sudo supervisorctl update

# 8. Iniciar el servicio y esperar
echo "🚀 Iniciando coretransapi..."
sudo supervisorctl start coretransapi

# 9. Esperar y verificar que se cree el socket
echo "⏳ Esperando que se cree el socket..."
for i in {1..30}; do
    if [ -S "$SOCKET_PATH" ]; then
        echo "✅ Socket creado exitosamente en intento $i"
        break
    fi
    echo "⏳ Intento $i/30 - Esperando socket..."
    sleep 2
done

# 10. Verificar estado del proceso
echo "�� Verificando estado del proceso..."
sudo supervisorctl status coretransapi

# 11. Si el socket no se creó, mostrar logs de error
if [ ! -S "$SOCKET_PATH" ]; then
    echo "❌ Error: Socket no creado después de 30 intentos"
    echo "📋 Logs de error de supervisor:"
    sudo tail -20 /var/log/supervisor/coretransapi.err.log 2>/dev/null || echo "No hay logs de error disponibles"
    echo "📋 Logs de salida de supervisor:"
    sudo tail -20 /var/log/supervisor/coretransapi.out.log 2>/dev/null || echo "No hay logs de salida disponibles"
    
    # Intentar ejecutar gunicorn manualmente para ver el error
    echo "🔍 Probando gunicorn manualmente..."
    cd "$PROJECT_DIR"
    source "$VENV_PATH/bin/activate"
    timeout 10s gunicorn config.wsgi:application --bind unix:"$SOCKET_PATH" --workers 1 --timeout 30 || echo "Gunicorn falló al ejecutarse manualmente"
    
    exit 1
fi

# 12. Configurar permisos del socket
echo "🔐 Configurando permisos del socket..."
sudo chmod 660 "$SOCKET_PATH"
sudo chown markmur88:www-data "$SOCKET_PATH"

# 13. Corregir configuración de nginx
echo "🌐 Corrigiendo configuración de nginx..."
sudo tee /etc/nginx/sites-available/coretransapi.conf > /dev/null <<EOF
server {
    listen 80;
    server_name api.coretransapi.com;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name api.coretransapi.com;

    ssl_certificate /etc/letsencrypt/live/api.coretransapi.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.coretransapi.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    client_max_body_size 20M;
    client_body_timeout 60s;
    client_header_timeout 60s;

    location /static/ {
        alias $PROJECT_DIR/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias $PROJECT_DIR/media/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location / {
        proxy_pass http://unix:$SOCKET_PATH;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        proxy_buffering off;
    }
}
EOF

# 14. Verificar configuración de nginx
echo "🔍 Verificando configuración de nginx..."
sudo nginx -t

# 15. Iniciar nginx
echo "🚀 Iniciando nginx..."
sudo systemctl start nginx

# 16. Verificar estado final
echo "📋 Estado final de servicios:"
echo "--- Supervisor ---"
sudo supervisorctl status coretransapi
echo "--- Nginx ---"
sudo systemctl status nginx --no-pager -l
echo "--- Socket ---"
ls -la "$SOCKET_PATH" 2>/dev/null || echo "Socket no encontrado"

echo "✅ Reparación completada. Prueba acceder a tu sitio web."
echo "�� Si sigue fallando, revisa los logs con:"
echo "   sudo tail -f /var/log/supervisor/coretransapi.err.log"
echo "   sudo tail -f /var/log/nginx/error.log"