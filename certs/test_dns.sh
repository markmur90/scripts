#!/bin/bash

# === CONFIGURACIÓN ===
DOMAIN="api.coretransapi.com"

# === COLORES Y FUNCIONES ===
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

log()   { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warn()  { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠ $1${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}"; }

echo "🌐 Probando resolución DNS para $DOMAIN"
echo "========================================"

# Método 1: Usar dig con servidores DNS públicos
echo "1. Probando con dig + Google DNS (8.8.8.8):"
if command -v dig >/dev/null; then
    RESULT=$(dig +short "$DOMAIN" @8.8.8.8)
    if [ -n "$RESULT" ]; then
        log "✅ Resuelto: $RESULT"
    else
        error "❌ No se pudo resolver"
    fi
else
    warn "⚠️  dig no está instalado"
fi

echo ""
echo "2. Probando con dig + Cloudflare DNS (1.1.1.1):"
if command -v dig >/dev/null; then
    RESULT=$(dig +short "$DOMAIN" @1.1.1.1)
    if [ -n "$RESULT" ]; then
        log "✅ Resuelto: $RESULT"
    else
        error "❌ No se pudo resolver"
    fi
else
    warn "⚠️  dig no está instalado"
fi

echo ""
echo "3. Probando con nslookup + Google DNS:"
if timeout 5 nslookup "$DOMAIN" 8.8.8.8 &>/dev/null; then
    log "✅ nslookup exitoso con Google DNS"
else
    error "❌ nslookup falló con Google DNS"
fi

echo ""
echo "4. Probando con getent:"
if getent hosts "$DOMAIN" &>/dev/null; then
    log "✅ getent exitoso"
    getent hosts "$DOMAIN"
else
    error "❌ getent falló"
fi

echo ""
echo "5. Probando con host + Google DNS:"
if command -v host >/dev/null; then
    if host "$DOMAIN" 8.8.8.8 &>/dev/null; then
        log "✅ host exitoso con Google DNS"
    else
        error "❌ host falló con Google DNS"
    fi
else
    warn "⚠️  host no está instalado"
fi

echo ""
echo "6. Probando DNS local (puede fallar):"
if nslookup "$DOMAIN" &>/dev/null; then
    log "✅ DNS local funciona"
else
    warn "⚠️  DNS local no funciona (normal en algunos entornos)"
fi

echo ""
echo "🎯 Resumen:"
echo "El dominio $DOMAIN debería resolverse correctamente con servidores DNS públicos"
echo "Si el DNS local falla, es normal y no afecta la generación del certificado SSL"
