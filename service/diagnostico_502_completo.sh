#!/bin/bash
# Script corregido de diagnóstico y solución para error 502

echo "🔍 DIAGNÓSTICO COMPLETO - Error 502 Bad Gateway (CORREGIDO)"
echo "============================================================"

# Variables
PROJECT_DIR="/home/markmur88/api_bank_h2"
VENV_PATH="/home/markmur88/envSIM"
SOCKET_PATH="$PROJECT_DIR/servers/gunicorn/api.sock"

# 1. Verificar entorno básico
echo "📋 1. VERIFICANDO ENTORNO BÁSICO"
echo "--------------------------------"
echo "Directorio del proyecto: $PROJECT_DIR"
if [ -d "$PROJECT_DIR" ]; then
    echo "✅ Directorio del proyecto existe"
else
    echo "❌ Directorio del proyecto NO existe"
    exit 1
fi

echo "Entorno virtual: $VENV_PATH"
if [ -f "$VENV_PATH/bin/gunicorn" ]; then
    echo "✅ Gunicorn encontrado en entorno virtual"
else
    echo "❌ Gunicorn NO encontrado en entorno virtual"
    exit 1
fi

# 2. Detener servicios existentes
echo ""
echo "�� 2. DETENIENDO SERVICIOS EXISTENTES"
echo "------------------------------------"
echo "🛑 Deteniendo supervisor..."
sudo supervisorctl stop coretransapi 2>/dev/null || true
sudo systemctl stop gunicorn 2>/dev/null || true

# 3. Limpiar configuración anterior
echo ""
echo "📋 3. LIMPIANDO CONFIGURACIÓN ANTERIOR"
echo "--------------------------------------"
echo "🧹 Limpiando sockets..."
sudo rm -f "$SOCKET_PATH"
sudo rm -f "$PROJECT_DIR/api.sock"  # Socket alternativo que se estaba usando

echo "🧹 Limpiando configuración de supervisor..."
sudo rm -f /etc/supervisor/conf.d/coretransapi.conf

# 4. Crear directorio de logs
echo ""
echo "📋 4. CONFIGURANDO LOGS"
echo "----------------------"
echo "📝 Configurando logs..."
sudo mkdir -p /var/log/supervisor
sudo chown root:adm /var/log/supervisor
sudo chmod 750 /var/log/supervisor

# 5. Configurar supervisor CORREGIDO
echo ""
echo "📋 5. CONFIGURANDO SUPERVISOR (CORREGIDO)"
echo "----------------------------------------"
echo "⚙️ Configurando supervisor..."
sudo tee /etc/supervisor/conf.d/coretransapi.conf > /dev/null <<EOF
[program:coretransapi]
directory=$PROJECT_DIR
command=$VENV_PATH/bin/gunicorn config.wsgi:application --bind unix:$SOCKET_PATH --workers 4 --timeout 120 --keep-alive 2 --max-requests 1000 --max-requests-jitter 100 --access-logfile /var/log/supervisor/coretransapi.access.log --error-logfile /var/log/supervisor/coretransapi.error.log
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
environment=PATH="$VENV_PATH/bin",DJANGO_SETTINGS_MODULE="config.settings",DJANGO_ENV="production",PYTHONPATH="$PROJECT_DIR",LANG="es_ES.UTF-8",LC_ALL="es_ES.UTF-8"
EOF

# 6. Recargar supervisor
echo ""
echo "📋 6. RECARGANDO SUPERVISOR"
echo "---------------------------"
echo "🔄 Recargando supervisor..."
sudo supervisorctl reread
sudo supervisorctl update

# 7. Iniciar el servicio
echo ""
echo "📋 7. INICIANDO SERVICIO"
echo "-----------------------"
echo "🚀 Iniciando coretransapi..."
sudo supervisorctl start coretransapi

# 8. Esperar y verificar socket
echo ""
echo "📋 8. VERIFICANDO SOCKET"
echo "-----------------------"
echo "⏳ Esperando que se cree el socket..."
for i in {1..30}; do
    if [ -S "$SOCKET_PATH" ]; then
        echo "✅ Socket creado exitosamente en intento $i"
        break
    fi
    echo "⏳ Intento $i/30 - Esperando socket..."
    sleep 2
done

# 9. Verificar estado
echo ""
echo "�� 9. ESTADO DEL SERVICIO"
echo "------------------------"
echo "📊 Estado de supervisor:"
sudo supervisorctl status coretransapi

if [ ! -S "$SOCKET_PATH" ]; then
    echo "❌ Error: Socket no creado después de 30 intentos"
    echo "📋 Logs de error:"
    sudo tail -20 /var/log/supervisor/coretransapi.err.log 2>/dev/null || echo "No hay logs de error"
    echo "📋 Logs de salida:"
    sudo tail -20 /var/log/supervisor/coretransapi.out.log 2>/dev/null || echo "No hay logs de salida"
    
    # Intentar ejecutar manualmente para diagnóstico
    echo "🔍 Probando gunicorn manualmente..."
    cd "$PROJECT_DIR"
    source "$VENV_PATH/bin/activate"
    timeout 10s gunicorn config.wsgi:application --bind unix:"$SOCKET_PATH" --workers 1 --timeout 30 || echo "Gunicorn falló al ejecutarse manualmente"
    
    exit 1
fi

# 10. Configurar permisos
echo ""
echo "📋 10. CONFIGURANDO PERMISOS"
echo "---------------------------"
echo "🔐 Configurando permisos..."
sudo chmod 660 "$SOCKET_PATH"
sudo chown markmur88:www-data "$SOCKET_PATH"

# 11. Configurar nginx
echo ""
echo "📋 11. CONFIGURANDO NGINX"
echo "------------------------"
echo "⚙️ Configurando nginx..."
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

# 12. Verificar y reiniciar nginx
echo ""
echo "�� 12. REINICIANDO NGINX"
echo "-----------------------"
echo "🔍 Verificando nginx..."
sudo nginx -t
echo "🚀 Reiniciando nginx..."
sudo systemctl restart nginx

# 13. Estado final
echo ""
echo "�� 13. ESTADO FINAL"
echo "------------------"
echo "Supervisor:"
sudo supervisorctl status coretransapi
echo ""
echo "Nginx:"
sudo systemctl status nginx --no-pager -l | head -5
echo ""
echo "Socket:"
ls -la "$SOCKET_PATH" 2>/dev/null || echo "Socket no encontrado"
echo ""
echo "Procesos gunicorn:"
ps aux | grep gunicorn | grep -v grep || echo "No hay procesos gunicorn"

echo ""
echo "✅ Diagnóstico y solución completados."
echo "🌐 Prueba acceder a: https://api.coretransapi.com"
echo ""
echo "Si sigue fallando, revisa los logs con:"
echo "   sudo tail -f /var/log/supervisor/coretransapi.err.log"
echo "   sudo tail -f /var/log/nginx/error.log"