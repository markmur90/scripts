#!/bin/bash

read -s -p "Introduce la contraseña para el usuario 'admin' de Graylog: " ROOT_PASSWORD
echo

ROOT_PASSWORD_SHA256=$(echo -n "$ROOT_PASSWORD" | sha256sum | awk '{print $1}')
PASSWORD_SECRET=$(pwgen -s 96 1)

cat <<EOF | sudo tee /etc/graylog/server/server.conf > /dev/null
is_master = true
node_id_file = /etc/graylog/server/node-id
password_secret = $PASSWORD_SECRET
root_password_sha2 = $ROOT_PASSWORD_SHA256

mongodb_uri = mongodb://localhost:27017/graylog
elasticsearch_hosts = http://localhost:9200
elasticsearch_shards = 1
elasticsearch_replicas = 0
elasticsearch_index_prefix = graylog
allow_leading_wildcard_searches = false
allow_highlighting = false
elasticsearch_analyzer = standard

http_bind_address = 0.0.0.0:9000
http_publish_uri = http://127.0.0.1:9000/
http_external_uri = http://127.0.0.1:9000/

transport_email_enabled = false
EOF

echo "📄 Archivo server.conf generado."

# ----------------------------
# PASO 7: Habilitar y arrancar servicio Graylog
# ----------------------------
echo "🔄 Habilitando y arrancando Graylog..."
sudo systemctl daemon-reload
sudo systemctl enable graylog-server --now

# ----------------------------
# PASO 8: Verificar estado final
# ----------------------------
echo "⏳ Esperando a que Graylog inicie (esto puede tardar 30-60 segundos)..."
sleep 30

if systemctl is-active --quiet graylog-server; then
    echo "✅ ¡Graylog ha sido instalado y está corriendo correctamente!"
    echo "🌐 Accede desde tu navegador: http://<tu-ip>:9000/"
    echo "👤 Usuario por defecto: admin"
else
    echo "❗ El servicio de Graylog no parece estar activo. Revisa los logs:"
    echo "📄 Logs: sudo journalctl -u graylog-server -f"
fi