#!/bin/bash

echo "🔧 Solucionando problema SSL de Deutsche Bank..."

SERVER="193.150.166.1"
PORT=443
BUNDLE_FILE="/home/markmur88/api_bank_h2/servers/ssl/ca-bundle-custom.pem"
ENV_FILE="/home/markmur88/api_bank_h2/.env.production"

# Crear directorio si no existe
mkdir -p "$(dirname "$BUNDLE_FILE")"

echo "📥 Obteniendo certificado del servidor..."
# Obtener certificado del servidor
openssl s_client -showcerts -connect $SERVER:$PORT </dev/null 2>/dev/null | \
awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' > server_cert.pem

if [ ! -s server_cert.pem ]; then
    echo "❌ Error: No se pudo obtener certificado del servidor"
    exit 1
fi

echo "🔧 Creando bundle personalizado..."
# Crear bundle: CAs del sistema + certificado del servidor
cat /etc/ssl/certs/ca-certificates.crt > "$BUNDLE_FILE"
echo "" >> "$BUNDLE_FILE"
echo "# Deutsche Bank Server Certificate" >> "$BUNDLE_FILE"
cat server_cert.pem >> "$BUNDLE_FILE"

echo "📝 Configurando variables de entorno..."
# Configurar .env.production
if [ -f "$ENV_FILE" ]; then
    # Crear backup
    cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Remover configuraciones SSL existentes y añadir nuevas
    grep -v -E "(REQUESTS_CA_BUNDLE|FORCE_INSECURE_SSL)" "$ENV_FILE" > "${ENV_FILE}.tmp"
    
    echo "" >> "${ENV_FILE}.tmp"
    echo "# SSL Configuration for Deutsche Bank" >> "${ENV_FILE}.tmp"
    echo "REQUESTS_CA_BUNDLE=$BUNDLE_FILE" >> "${ENV_FILE}.tmp"
    
    mv "${ENV_FILE}.tmp" "$ENV_FILE"
    echo "✅ .env.production actualizado"
else
    echo "⚠️  .env.production no encontrado, creando configuración manual..."
    echo "REQUESTS_CA_BUNDLE=$BUNDLE_FILE" > "$ENV_FILE"
fi

# Limpiar archivos temporales
rm -f server_cert.pem

echo ""
echo "🎉 Configuración SSL completada!"
echo ""
echo "📋 Bundle creado en: $BUNDLE_FILE"
echo "📋 Tamaño del bundle: $(wc -l < "$BUNDLE_FILE") líneas"
echo ""
echo "🔄 Para aplicar los cambios:"
echo "1. Activa envSIM: envSIM"
echo "2. Reinicia Django: sudo systemctl restart gunicorn"
echo "3. Prueba la conexión:"
echo "   export REQUESTS_CA_BUNDLE='$BUNDLE_FILE'"
echo "   python -c \"import requests; print('SSL Status:', requests.get('https://193.150.166.1', timeout=10).status_code)\""
echo ""
echo "✅ El error SSL debería estar resuelto"