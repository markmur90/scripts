#!/bin/bash

# === CONFIGURACIÓN ===
DOMAIN="api.coretransapi.com"
EMAIL="netghostx90@protonmail.com"
NJALLA_TOKEN="384c973798f4c24a69d165cec329382af68123d7"
CERT_DIR="$HOME/.lego/certificates"
LOG_FILE="$HOME/lego-setup.log"  # Cambiado a directorio del usuario

# === COLORES Y FUNCIONES ===
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

log()   { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"; }
warn()  { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠ $1${NC}" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}" | tee -a "$LOG_FILE"; exit 1; }
check() { if [ $? -ne 0 ]; then error "$1"; fi; }

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
    log "📄 Ubicación: $CERT_DIR/_.$ROOT_DOMAIN.crt"
    log "📅 Expira: $(openssl x509 -in $CERT_DIR/_.$ROOT_DOMAIN.crt -noout -enddate 2>/dev/null | cut -d= -f2 || echo 'No se puede leer')"
    exit 0
fi
log "🎯 Dominio raíz: $ROOT_DOMAIN"

# Verificar internet
log "📡 Ping a github.com..."
ping -c1 github.com &>/dev/null || error "Sin conexión a internet"

# Verificar resolución DNS del dominio
log "🌐 Verificando resolución DNS de $DOMAIN..."
DNS_RESOLVED=false

# Método 1: Usar dig con servidores DNS públicos
if command -v dig >/dev/null; then
    if dig +short "$DOMAIN" @8.8.8.8 | grep -q .; then
        log "✅ DNS resuelve correctamente para $DOMAIN (usando Google DNS)"
        DNS_RESOLVED=true
    elif dig +short "$DOMAIN" @1.1.1.1 | grep -q .; then
        log "✅ DNS resuelve correctamente para $DOMAIN (usando Cloudflare DNS)"
        DNS_RESOLVED=true
    fi
fi

# Método 2: Usar nslookup con timeout
if [ "$DNS_RESOLVED" = false ]; then
    if timeout 5 nslookup "$DOMAIN" 8.8.8.8 &>/dev/null; then
        log "✅ DNS resuelve correctamente para $DOMAIN (nslookup con Google DNS)"
        DNS_RESOLVED=true
    fi
fi

# Método 3: Usar getent
if [ "$DNS_RESOLVED" = false ]; then
    if getent hosts "$DOMAIN" &>/dev/null; then
        log "✅ DNS resuelve correctamente para $DOMAIN (usando getent)"
        DNS_RESOLVED=true
    fi
fi

# Método 4: Usar host
if [ "$DNS_RESOLVED" = false ]; then
    if command -v host >/dev/null; then
        if host "$DOMAIN" 8.8.8.8 &>/dev/null; then
            log "✅ DNS resuelve correctamente para $DOMAIN (usando host)"
            DNS_RESOLVED=true
        fi
    fi
fi

if [ "$DNS_RESOLVED" = false ]; then
    warn "⚠️  No se puede resolver $DOMAIN con métodos estándar"
    warn "⚠️  Esto puede ser normal si el DNS local no permite recursión"
    log "⚠️  Continuando (la validación se hará durante la generación del certificado)"
else
    log "✅ DNS resuelve correctamente para $DOMAIN"
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
CRON_JOB="0 12 * * * $RENEW_SCRIPT >> $HOME/lego-renew.log 2>&1"
(crontab -l 2>/dev/null | grep -Fq "$RENEW_SCRIPT") || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
log "✅ Renovación automática programada"

# === 5. Mostrar certificados ===
WILDCARD_CERT="$CERT_DIR/_.$ROOT_DOMAIN.crt"
WILDCARD_KEY="$CERT_DIR/_.$ROOT_DOMAIN.key"

log "📄 Certificado wildcard: $WILDCARD_CERT"
log "🔑 Clave privada: $WILDCARD_KEY"

# Verificar que el certificado existe antes de mostrar la fecha
if [ -f "$WILDCARD_CERT" ]; then
    EXPIRY_DATE=$(openssl x509 -in "$WILDCARD_CERT" -noout -enddate 2>/dev/null | cut -d= -f2)
    if [ -n "$EXPIRY_DATE" ]; then
        log "📅 Expira: $EXPIRY_DATE"
    else
        log "⚠️  No se pudo leer la fecha de expiración"
    fi
else
    log "❌ Certificado no encontrado en: $WILDCARD_CERT"
fi

log "🎉 ¡SSL wildcard listo para usar en *.$ROOT_DOMAIN (incluye $DOMAIN)!"
