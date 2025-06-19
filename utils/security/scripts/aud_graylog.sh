#!/bin/bash

set -e  # Salir si hay algún error

echo "🚀 Iniciando instalación completa de Graylog..."

# ----------------------------
# PASO 1: Actualizar sistema e instalar dependencias básicas
# ----------------------------
echo "🔁 Actualizando sistema..."
sudo apt update && sudo apt upgrade -y

echo "📦 Instalando dependencias esenciales..."
sudo apt install -y curl gnupg wget software-properties-common uuid-runtime pwgen openjdk-11-jre-headless

# ----------------------------
# PASO 2: Añadir repositorio de MongoDB
# ----------------------------
echo "💾 Añadiendo repositorio de MongoDB..."
MONGO_KEY="/usr/share/keyrings/mongodb-archive-keyring.gpg"
curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc  | sudo gpg --dearmor -o "$MONGO_KEY"
echo "deb [ arch=amd64 signed-by=$MONGO_KEY ] http://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org.list > /dev/null

sudo apt update && sudo apt install -y mongodb-org || { echo "⚠️ No se pudo instalar MongoDB"; exit 1; }

echo "🔄 Iniciando y habilitando MongoDB..."
sudo systemctl enable mongod --now

# ----------------------------
# PASO 3: Añadir repositorio de Elasticsearch
# ----------------------------
echo "🔍 Añadiendo repositorio de Elasticsearch..."
ELASTIC_KEY="/usr/share/keyrings/elastic-co-archive-keyring.gpg"
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch  | sudo gpg --dearmor -o "$ELASTIC_KEY"
echo "deb [signed-by=$ELASTIC_KEY] https://artifacts.elastic.co/packages/7.x/apt  stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list > /dev/null

sudo apt update && sudo apt install -y elasticsearch || { echo "⚠️ No se pudo instalar Elasticsearch"; exit 1; }

echo "🔄 Iniciando y habilitando Elasticsearch..."
sudo systemctl enable elasticsearch --now

# ----------------------------
# PASO 4: Añadir repositorio de Graylog
# ----------------------------
echo "🔵 Añadiendo repositorio de Graylog..."
GRAYLOG_REPO_DEB="graylog-4.3-repository_latest.deb"
wget -O "$GRAYLOG_REPO_DEB" "https://packages.graylog2.org/repo/packages/$GRAYLOG_REPO_DEB"  || {
  echo "❌ Error al descargar el repositorio de Graylog."
  exit 1
}
sudo dpkg -i "$GRAYLOG_REPO_DEB" && rm "$GRAYLOG_REPO_DEB"

sudo apt update

# ----------------------------
# PASO 5: Instalar Graylog Server
# ----------------------------
echo "🟣 Instalando Graylog Server..."
sudo apt install -y graylog-server || { echo "❌ No se pudo instalar Graylog Server"; exit 1; }

# ----------------------------
# PASO 6: Generar server.conf automáticamente
# ----------------------------
echo "🔧 Generando archivo de configuración server.conf..."

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