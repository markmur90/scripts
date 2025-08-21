#!/bin/bash

SERVER="193.150.166.1"
PORT=443

echo "🔍 Analizando certificados del servidor $SERVER:$PORT..."

# Limpiar archivos anteriores
rm -f server_cert.pem intermediate.crt fullchain.pem

# Obtener información del certificado del servidor
cert_info=$(openssl s_client -showcerts -connect $SERVER:$PORT </dev/null 2>/dev/null)

if [ -z "$cert_info" ]; then
    echo "❌ Error: No se pudo conectar al servidor $SERVER:$PORT"
    exit 1
fi

# Guardar toda la información de certificados
echo "$cert_info" | awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' > fullchain.pem

# Contar cuántos certificados hay
cert_count=$(grep -c "BEGIN CERTIFICATE" fullchain.pem)
echo "📊 Certificados encontrados: $cert_count"

if [ "$cert_count" -eq 0 ]; then
    echo "❌ No se encontraron certificados"
    exit 1
elif [ "$cert_count" -eq 1 ]; then
    echo "⚠️  Solo hay un certificado (del servidor), creando bundle completo..."
    
    # Extraer el certificado del servidor
    cp fullchain.pem server_cert.pem
    
    # Crear un bundle que incluya los CAs del sistema + el certificado del servidor
    cat /etc/ssl/certs/ca-certificates.crt > intermediate.crt
    echo "" >> intermediate.crt
    echo "# Certificado del servidor Deutsche Bank" >> intermediate.crt
    cat server_cert.pem >> intermediate.crt
    
    echo "✅ Bundle creado con CAs del sistema + certificado del servidor"
    
else
    echo "✅ Múltiples certificados encontrados, extrayendo intermedios..."
    
    # Dividir certificados en archivos separados
    awk '
    /-----BEGIN CERTIFICATE-----/ { cert++; filename="cert" cert ".pem" }
    { print > filename }
    /-----END CERTIFICATE-----/ { close(filename) }
    ' fullchain.pem
    
    # El primer certificado es del servidor, los siguientes son intermedios
    if [ -f cert2.pem ]; then
        # Combinar todos los certificados intermedios
        cat cert2.pem > intermediate.crt
        
        # Si hay más certificados intermedios, agregarlos
        for i in {3..10}; do
            if [ -f "cert$i.pem" ]; then
                echo "" >> intermediate.crt
                cat "cert$i.pem" >> intermediate.crt
            fi
        done
        
        echo "✅ Certificados intermedios extraídos"
    else
        echo "❌ Error: No se pudieron extraer certificados intermedios"
        exit 1
    fi
    
    # Limpiar archivos temporales de certificados
    rm -f cert*.pem
fi

# Verificar que se creó el archivo
if [ -f intermediate.crt ] && [ -s intermediate.crt ]; then
    echo "📋 Archivo creado: $(pwd)/intermediate.crt ($(wc -l < intermediate.crt) líneas)"
    
    # Mostrar información del primer certificado en el bundle
    echo "📋 Información del bundle/certificado:"
    openssl x509 -in intermediate.crt -noout -subject -issuer 2>/dev/null | head -2 || echo "Bundle de múltiples certificados"
    
    echo "✅ Proceso completado exitosamente"
else
    echo "❌ Error: No se pudo crear intermediate.crt"
    exit 1
fi

# Limpiar archivos temporales
rm -f server_cert.pem fullchain.pem

echo ""
echo "📋 Siguiente paso: ejecutar ./crt_02_instalar_intermedio_mejorado.sh"