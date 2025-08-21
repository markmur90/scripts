#!/bin/bash

# === CONFIGURACIÓN ===
DOMAIN="api.coretransapi.com"
EMAIL="netghostx90@protonmail.com"
NJALLA_TOKEN="384c973798f4c24a69d165cec329382af68123d7"
CERT_DIR="$HOME/.lego/certificates"
LOG_FILE="/var/log/lego-setup.log"

# === COLORES Y FUNCIONES ===
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

log()   { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"; }
warn()  { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠ $1${NC}" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}" | tee -a "$LOG_FILE"; exit 1; }
check() { if [ $? -ne 0 ]; then error "$1"; fi; }  # ✅ Ahora sí está definida

# === 0. Validaciones iniciales ===
log "🔧 Iniciando validaciones..."

if [ -z "$NJALLA_TOKEN" ]; then
    error "NJALLA_TOKEN no está definido"
fi

if ! [[ "$EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    error "EMAIL no válido: $EMAIL"
fi

# Extraer dominio raíz
ROOT_DOMAIN=$(echo "$DOMAIN" | sed -E 's/^[^.]+\.(.+)$/\1/' | tr -d '"')
if [ -z "$ROOT_DOMAIN" ] || [ "$ROOT_DOMAIN" = "$DOMAIN" ]; then
    error "No se pudo extraer dominio raíz desde '$DOMAIN'"
fi

if [ -f "$CERT_DIR/_.$ROOT_DOMAIN.crt" ]; then
    log "✅ Certificado wildcard ya existe. Usa renew para actualizar."
    exit 0
fi
log "🎯 Dominio raíz: $ROOT_DOMAIN"

# Verificar internet
log "📡 Ping a github.com..."
ping -c1 github.com &>/dev/null || error "Sin conexión a internet"

# Verificar acceso a Njalla (opcional - puede fallar por CSRF)
log "🔐 Probando API de Njalla (opcional)..."
# Intentar validación simple con referer correcto
response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $NJALLA_TOKEN" \
    -H "Referer: https://njal.la/" \
    -H "Origin: https://njal.la" \
    -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
    -d '{"method": "list-domains", "params": {}}' \
    https://njal.la/api/1/ 2>/dev/null || echo '{"error": {"code": 999, "message": "Connection failed"}}')

# Si hay error de CSRF o conexión, continuar sin validación
if echo "$response" | grep -q "CSRF\|error\|Connection failed"; then
    warn "API Njalla no disponible o con error CSRF: $(echo "$response" | head -1)"
    log "⚠️  Continuando sin validación de dominio (la validación se hará durante la generación del certificado)"
else
    # Verificar si el dominio está en la respuesta
    if echo "$response" | grep -q "\"name\":\"$ROOT_DOMAIN\""; then
        log "✅ Dominio '$ROOT_DOMAIN' confirmado en Njalla"
    else
        warn "Dominio '$ROOT_DOMAIN' no encontrado en la lista de Njalla"
        log "⚠️  Continuando sin validación de dominio (verificar manualmente si es necesario)"
    fi
fi

# === 1. Instalar lego si no existe ===
if ! command -v lego >/dev/null; then
    log "📥 Instalando lego..."
    URL=$(curl -s https://api.github.com/repos/go-acme/lego/releases/latest | grep browser_download_url | grep linux_amd64 | cut -d '"' -f 4)
    if [ -z "$URL" ]; then
        error "No se pudo obtener URL de descarga de lego"
    fi
    
    log "📦 Descargando desde: $URL"
    wget -q -O /tmp/lego.tar.gz "$URL" || error "Fallo al descargar"
    
    # Extraer el archivo (el binario lego está en el root del tar)
    cd /tmp
    tar -xzf lego.tar.gz || error "Fallo al extraer"
    
    # El binario lego está directamente en /tmp después de la extracción
    if [ ! -f "/tmp/lego" ]; then
        error "No se encontró el binario lego en el archivo extraído"
    fi
    
    sudo mv /tmp/lego /usr/local/bin/lego
    sudo chmod +x /usr/local/bin/lego
    rm -rf /tmp/lego*
    
    # Verificar instalación
    if command -v lego >/dev/null; then
        log "✅ lego instalado: $(lego --version)"
    else
        error "lego no se instaló correctamente"
    fi
else
    log "✅ lego ya instalado: $(lego --version)"
fi

# === 2. Generar certificado ===
log "🔐 Generando certificado para *.$ROOT_DOMAIN (incluye $DOMAIN)..."
export NJALLA_TOKEN
lego --email="$EMAIL" \
     --dns="njalla" \
     --domains="*.$ROOT_DOMAIN" \
     --accept-tos \
     run
check "Fallo al generar certificado"

# === 3. Script de renovación ===
RENEW_SCRIPT="$HOME/renew-cert.sh"
cat > "$RENEW_SCRIPT" << 'EOF'
#!/bin/bash
export NJALLA_TOKEN="384c973798f4c24a69d165cec329382af68123d7"
lego --email="netghostx90@protonmail.com" \
     --dns="njalla" \
     --domains="*.coretransapi.com" \
     --accept-tos \
     renew --days 30
EOF

chmod +x "$RENEW_SCRIPT"

# === 4. Añadir al cron ===
CRON_JOB="0 12 * * * $RENEW_SCRIPT >> /var/log/lego-renew.log 2>&1"
(crontab -l 2>/dev/null | grep -Fq "$RENEW_SCRIPT") || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
log "✅ Renovación automática programada"

# === 5. Mostrar certificados ===
WILDCARD_CERT="$CERT_DIR/_.$ROOT_DOMAIN.crt"
WILDCARD_KEY="$CERT_DIR/_.$ROOT_DOMAIN.key"

log "📄 Certificado wildcard: $WILDCARD_CERT"
log "🔑 Clave privada: $WILDCARD_KEY"
log "📅 Expira: $(openssl x509 -in $WILDCARD_CERT -noout -enddate | cut -d= -f2)"

log "🎉 ¡SSL wildcard listo para usar en *.$ROOT_DOMAIN (incluye $DOMAIN)!"