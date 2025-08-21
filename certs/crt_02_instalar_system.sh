#!/bin/bash
# Script corregido para manejar servidores que solo envían un certificado

echo "🔍 Obteniendo certificados de 193.150.166.1:443..."

# Obtener certificado del servidor
openssl s_client -showcerts -connect 193.150.166.1:443 </dev/null 2>/dev/null | \
awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' > server_cert.pem

# Verificar que se obtuvo el certificado
if [ ! -s server_cert.pem ]; then
    echo "❌ Error: No se pudo obtener el certificado del servidor"
    exit 1
fi

echo "✅ Certificado del servidor obtenido"

# Crear bundle completo: CAs del sistema + certificado del servidor
echo "🔧 Creando bundle completo..."
cat /etc/ssl/certs/ca-certificates.crt > intermediate.crt
echo "" >> intermediate.crt
echo "# Deutsche Bank Server Certificate" >> intermediate.crt
cat server_cert.pem >> intermediate.crt

# Limpiar archivos temporales
rm -f server_cert.pem fullchain.pem

echo "✅ Bundle completo creado: $(pwd)/intermediate.crt"
echo "📊 Tamaño: $(wc -l < intermediate.crt) líneas"