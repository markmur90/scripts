#!/bin/bash

SERVER="193.150.166.1"
PORT=443

echo "🔍 Analizando certificados del servidor $SERVER:$PORT..."

# Limpiar archivos anteriores
rm -f server_cert.pem intermediate.crt fullchain.pem

# Obtener certificados del servidor
openssl s_client -showcerts -connect $SERVER:$PORT </dev/null 2>/dev/null | \
awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' > fullchain.pem

# Verificar que se obtuvo algo
if [ ! -s fullchain.pem ]; then
    echo "❌ Error: No se pudo obtener certificados del servidor"
    exit 1
fi

# Contar certificados
cert_count=$(grep -c "BEGIN CERTIFICATE" fullchain.pem)
echo "📊 Certificados encontrados: $cert_count"

if [ "$cert_count" -eq 1 ]; then
    echo "⚠️  Solo un certificado encontrado. Creando bundle completo..."
    
    # Crear bundle con CAs del sistema + certificado del servidor
    cat /etc/ssl/certs/ca-certificates.crt > intermediate.crt
    echo "" >> intermediate.crt
    echo "# Deutsche Bank Server Certificate" >> intermediate.crt
    cat fullchain.pem >> intermediate.crt
    
    echo "✅ Bundle creado con CAs del sistema + certificado del servidor"
    
elif [ "$cert_count" -gt 1 ]; then
    echo "✅ Múltiples certificados, extrayendo intermedios..."
    
    # Usar awk para dividir certificados
    awk '
    BEGIN { cert = 0 }
    /-----BEGIN CERTIFICATE-----/ { 
        cert++; 
        if (cert > 1) { 
            filename = "intermediate.crt"
            if (cert == 2) print > filename
            else print >> filename
        }
    }
    /-----END CERTIFICATE-----/ { 
        if (cert > 1) {
            if (cert == 2) print > filename
            else print >> filename
        }
    }
    cert > 1 && !/-----BEGIN CERTIFICATE-----/ && !/-----END CERTIFICATE-----/ {
        if (cert == 2) print > filename
        else print >> filename
    }
    ' fullchain.pem
    
    if [ -s intermediate.crt ]; then
        echo "✅ Certificados intermedios extraídos"
    else
        echo "⚠️  No se pudieron extraer intermedios, creando bundle completo..."
        cat /etc/ssl/certs/ca-certificates.crt > intermediate.crt
        echo "" >> intermediate.crt
        cat fullchain.pem >> intermediate.crt
    fi
else
    echo "❌ No se encontraron certificados válidos"
    exit 1
fi

# Verificar resultado
if [ -f intermediate.crt ] && [ -s intermediate.crt ]; then
    lines=$(wc -l < intermediate.crt)
    echo "📋 Archivo creado: $(pwd)/intermediate.crt ($lines líneas)"
    echo "✅ Certificado intermedio/bundle guardado exitosamente"
else
    echo "❌ Error: No se pudo crear intermediate.crt"
    exit 1
fi

# Limpiar
rm -f fullchain.pem server_cert.pem

echo ""
echo "📋 Siguiente paso: ejecutar ./crt_02_instalar_system.sh"