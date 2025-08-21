#!/bin/bash

INTERMEDIATE_FILE="intermediate.crt"
SYSTEM_CERT_DIR="/usr/local/share/ca-certificates"
SYSTEM_CERT_FILE="$SYSTEM_CERT_DIR/deutsche_bank_bundle.crt"
CUSTOM_BUNDLE_DIR="/home/markmur88/api_bank_h2/servers/ssl"
CUSTOM_BUNDLE_FILE="$CUSTOM_BUNDLE_DIR/ca-bundle-custom.pem"

echo "🔧 Instalando certificado intermedio/bundle..."

# Verificar que existe el archivo
if [ ! -f "$INTERMEDIATE_FILE" ]; then
    echo "❌ Error: No se encontró $INTERMEDIATE_FILE"
    echo "🔍 Ejecuta primero: ./crt_01_obtener_intermedio_mejorado.sh"
    exit 1
fi

# Crear directorio personalizado si no existe
mkdir -p "$CUSTOM_BUNDLE_DIR"

echo "📋 Método 1: Instalación en el sistema (requiere sudo)"
if [ "$EUID" -eq 0 ] || sudo -n true 2>/dev/null; then
    # Copiar al sistema
    sudo cp "$INTERMEDIATE_FILE" "$SYSTEM_CERT_FILE"
    sudo update-ca-certificates
    echo "✅ Certificado instalado en el sistema"
    
    # Verificar instalación
    if sudo openssl verify -CApath /etc/ssl/certs/ "$SYSTEM_CERT_FILE" 2>/dev/null; then
        echo "✅ Verificación del sistema exitosa"
    else
        echo "⚠️  Verificación del sistema falló (puede ser normal para bundles)"
    fi
else
    echo "⚠️  No hay permisos sudo, usando solo método personalizado"
fi

echo "📋 Método 2: Bundle personalizado para la aplicación"

# Crear bundle personalizado combinando CAs del sistema + nuestro certificado
cat /etc/ssl/certs/ca-certificates.crt > "$CUSTOM_BUNDLE_FILE"
echo "" >> "$CUSTOM_BUNDLE_FILE"
cat "$INTERMEDIATE_FILE" >> "$CUSTOM_BUNDLE_FILE"

echo "✅ Bundle personalizado creado en: $CUSTOM_BUNDLE_FILE"

# Actualizar .env.production
ENV_FILE="/home/markmur88/api_bank_h2/.env.production"
if [ -f "$ENV_FILE" ]; then
    echo "📝 Actualizando $ENV_FILE..."
    
    # Remover líneas existentes de REQUESTS_CA_BUNDLE
    grep -v "REQUESTS_CA_BUNDLE" "$ENV_FILE" > "${ENV_FILE}.tmp"
    
    # Añadir nueva configuración
    echo "REQUESTS_CA_BUNDLE=$CUSTOM_BUNDLE_FILE" >> "${ENV_FILE}.tmp"
    
    # Reemplazar archivo original
    mv "${ENV_FILE}.tmp" "$ENV_FILE"
    
    echo "✅ Configuración actualizada en .env.production"
else
    echo "⚠️  No se encontró .env.production, creando configuración manual..."
    echo "📝 Añade esta línea a tu .env.production:"
    echo "REQUESTS_CA_BUNDLE=$CUSTOM_BUNDLE_FILE"
fi

echo ""
echo "🎉 Instalación completada. Pasos siguientes:"
echo "1. Reinicia tu aplicación Django"
echo "2. Activa el entorno: envSIM"
echo "3. Prueba la conexión SSL"
echo ""
echo "📋 Para probar manualmente:"
echo "export REQUESTS_CA_BUNDLE='$CUSTOM_BUNDLE_FILE'"
echo "python -c \"import requests; print(requests.get('https://193.150.166.1', timeout=10).status_code)\""