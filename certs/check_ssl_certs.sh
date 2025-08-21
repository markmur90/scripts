#!/bin/bash

# === CONFIGURACIÓN ===
DOMAIN="api.coretransapi.com"
ROOT_DOMAIN="coretransapi.com"
CERT_DIR="$HOME/.lego/certificates"
ROOT_CERT_DIR="/root/.lego/certificates"

# === COLORES Y FUNCIONES ===
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'

log()   { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warn()  { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠ $1${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}"; }
info()  { echo -e "${BLUE}[$(date +'%H:%M:%S')] ℹ $1${NC}"; }

echo "🔍 Verificando certificados SSL para $DOMAIN"
echo "================================================"

# Verificar certificado en directorio del usuario
USER_CERT="$CERT_DIR/_.$ROOT_DOMAIN.crt"
USER_KEY="$CERT_DIR/_.$ROOT_DOMAIN.key"

# Verificar certificado en directorio root
ROOT_CERT="$ROOT_CERT_DIR/_.$ROOT_DOMAIN.crt"
ROOT_KEY="$ROOT_CERT_DIR/_.$ROOT_DOMAIN.key"

info "Buscando certificados..."

# Verificar certificado del usuario
if [ -f "$USER_CERT" ]; then
    log "✅ Certificado encontrado en: $USER_CERT"
    if [ -f "$USER_KEY" ]; then
        log "✅ Clave privada encontrada en: $USER_KEY"
        
        # Verificar fecha de expiración
        EXPIRY=$(openssl x509 -in "$USER_CERT" -noout -enddate 2>/dev/null | cut -d= -f2)
        if [ -n "$EXPIRY" ]; then
            log "📅 Expira: $EXPIRY"
            
            # Verificar si expira en menos de 30 días
            EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null)
            CURRENT_EPOCH=$(date +%s)
            DAYS_LEFT=$(( (EXPIRY_EPOCH - CURRENT_EPOCH) / 86400 ))
            
            if [ $DAYS_LEFT -lt 30 ]; then
                warn "⚠️  Certificado expira en $DAYS_LEFT días"
            else
                log "✅ Certificado válido por $DAYS_LEFT días"
            fi
        else
            warn "⚠️  No se pudo leer la fecha de expiración"
        fi
    else
        error "❌ Clave privada no encontrada en: $USER_KEY"
    fi
else
    warn "⚠️  Certificado no encontrado en: $USER_CERT"
fi

# Verificar certificado en directorio root
if [ -f "$ROOT_CERT" ]; then
    warn "⚠️  Certificado encontrado en directorio root: $ROOT_CERT"
    if [ -f "$ROOT_KEY" ]; then
        warn "⚠️  Clave privada encontrada en directorio root: $ROOT_KEY"
        
        # Verificar fecha de expiración
        EXPIRY=$(sudo openssl x509 -in "$ROOT_CERT" -noout -enddate 2>/dev/null | cut -d= -f2)
        if [ -n "$EXPIRY" ]; then
            info "📅 Expira: $EXPIRY"
        fi
    fi
else
    info "ℹ  No hay certificado en directorio root"
fi

echo ""
echo "🔧 Opciones de corrección:"
echo "=========================="

# Si hay certificado en root pero no en usuario, ofrecer copiarlo
if [ -f "$ROOT_CERT" ] && [ ! -f "$USER_CERT" ]; then
    echo "1. Copiar certificado de root a usuario"
fi

# Si no hay certificado en ninguno, ofrecer generarlo
if [ ! -f "$USER_CERT" ] && [ ! -f "$ROOT_CERT" ]; then
    echo "1. Generar nuevo certificado"
fi

# Si hay certificado en usuario, ofrecer renovarlo
if [ -f "$USER_CERT" ]; then
    echo "2. Renovar certificado existente"
fi

echo "3. Verificar configuración DNS"
echo "4. Salir"

echo ""
read -p "Selecciona una opción (1-4): " choice

case $choice in
    1)
        if [ -f "$ROOT_CERT" ] && [ ! -f "$USER_CERT" ]; then
            echo "📋 Copiando certificado de root a usuario..."
            sudo cp "$ROOT_CERT" "$USER_CERT"
            sudo cp "$ROOT_KEY" "$USER_KEY"
            sudo chown markmur88:markmur88 "$USER_CERT" "$USER_KEY"
            sudo chmod 600 "$USER_CERT" "$USER_KEY"
            log "✅ Certificado copiado correctamente"
        elif [ ! -f "$USER_CERT" ] && [ ! -f "$ROOT_CERT" ]; then
            echo "🔐 Generando nuevo certificado..."
            ./setup_ssl_fixed.sh
        fi
        ;;
    2)
        if [ -f "$USER_CERT" ]; then
            echo "🔄 Renovando certificado..."
            export NJALLA_TOKEN="384c973798f4c24a69d165cec329382af68123d7"
            lego --email="netghostx90@protonmail.com" \
                 --dns="njalla" \
                 --domains="*.coretransapi.com" \
                 --accept-tos \
                 renew --days 30
            log "✅ Renovación completada"
        fi
        ;;
    3)
        echo "🌐 Verificando DNS..."
        echo "Dominio: $DOMAIN"
        nslookup "$DOMAIN"
        echo ""
        echo "Dominio raíz: $ROOT_DOMAIN"
        nslookup "$ROOT_DOMAIN"
        ;;
    4)
        echo "👋 Saliendo..."
        exit 0
        ;;
    *)
        echo "❌ Opción inválida"
        exit 1
        ;;
esac
