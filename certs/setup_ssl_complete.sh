#!/bin/bash

# === CONFIGURACIÓN ===
DOMAIN="api.coretransapi.com"
EMAIL="netghostx90@protonmail.com"
NJALLA_TOKEN="384c973798f4c24a69d165cec329382af68123d7"
CERT_DIR="$HOME/.lego/certificates"
LOG_FILE="$HOME/lego-setup.log"

# === COLORES Y FUNCIONES ===
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'

log()   { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"; }
warn()  { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠ $1${NC}" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}" | tee -a "$LOG_FILE"; exit 1; }
info()  { echo -e "${BLUE}[$(date +'%H:%M:%S')] ℹ $1${NC}" | tee -a "$LOG_FILE"; }
check() { if [ $? -ne 0 ]; then error "$1"; fi; }

# === FUNCIÓN DE VERIFICACIÓN DNS ROBUSTA ===
check_dns() {
    local domain="$1"
    local dns_resolved=false
    
    log "🌐 Verificando resolución DNS de $domain..."
    
    # Método 1: Usar dig con servidores DNS públicos
    if command -v dig >/dev/null; then
        if dig +short "$domain" @8.8.8.8 | grep -q .; then
            log "✅ DNS resuelve correctamente para $domain (usando Google DNS)"
            dns_resolved=true
        elif dig +short "$domain" @1.1.1.1 | grep -q .; then
            log "✅ DNS resuelve correctamente para $domain (usando Cloudflare DNS)"
            dns_resolved=true
        fi
    fi
    
    # Método 2: Usar nslookup con timeout
    if [ "$dns_resolved" = false ]; then
        if timeout 5 nslookup "$domain" 8.8.8.8 &>/dev/null; then
            log "✅ DNS resuelve correctamente para $domain (nslookup con Google DNS)"
            dns_resolved=true
        fi
    fi
    
    # Método 3: Usar getent
    if [ "$dns_resolved" = false ]; then
        if getent hosts "$domain" &>/dev/null; then
            log "✅ DNS resuelve correctamente para $domain (usando getent)"
            dns_resolved=true
        fi
    fi
    
    # Método 4: Usar host
    if [ "$dns_resolved" = false ]; then
        if command -v host >/dev/null; then
            if host "$domain" 8.8.8.8 &>/dev/null; then
                log "✅ DNS resuelve correctamente para $domain (usando host)"
                dns_resolved=true
            fi
        fi
    fi
    
    if [ "$dns_resolved" = false ]; then
        warn "⚠️  No se puede resolver $domain con métodos estándar"
        warn "⚠️  Esto puede ser normal si el DNS local no permite recursión"
        return 1
    else
        return 0
    fi
}

# === FUNCIÓN DE VERIFICACIÓN DE CERTIFICADOS ===
check_certificates() {
    local root_domain="$1"
    local user_cert="$CERT_DIR/_.$root_domain.crt"
    local root_cert="/root/.lego/certificates/_.$root_domain.crt"
    
    info "🔍 Verificando certificados existentes..."
    
    # Verificar certificado del usuario
    if [ -f "$user_cert" ]; then
        log "✅ Certificado encontrado en: $user_cert"
        local expiry=$(openssl x509 -in "$user_cert" -noout -enddate 2>/dev/null | cut -d= -f2)
        if [ -n "$expiry" ]; then
            log "📅 Expira: $expiry"
            
            # Verificar si expira en menos de 30 días
            local expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null)
            local current_epoch=$(date +%s)
            local days_left=$(( (expiry_epoch - current_epoch) / 86400 ))
            
            if [ $days_left -lt 30 ]; then
                warn "⚠️  Certificado expira en $days_left días - renovación recomendada"
                return 2  # Necesita renovación
            else
                log "✅ Certificado válido por $days_left días"
                return 0  # Válido
            fi
        fi
    fi
    
    # Verificar certificado en directorio root
    if [ -f "$root_cert" ]; then
        warn "⚠️  Certificado encontrado en directorio root: $root_cert"
        warn "⚠️  Se recomienda copiarlo al directorio del usuario"
        return 3  # En directorio root
    fi
    
    return 1  # No encontrado
}

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
log "🎯 Dominio raíz: $ROOT_DOMAIN"

# Verificar certificados existentes
check_certificates "$ROOT_DOMAIN"
CERT_STATUS=$?

case $CERT_STATUS in
    0)
        log "✅ Certificado válido encontrado. Usa renew para actualizar."
        exit 0
        ;;
    2)
        warn "⚠️  Certificado expira pronto. Continuando con renovación..."
        ;;
    3)
        warn "⚠️  Certificado en directorio root. Copiando al usuario..."
        sudo cp "/root/.lego/certificates/_.$ROOT_DOMAIN.crt" "$CERT_DIR/"
        sudo cp "/root/.lego/certificates/_.$ROOT_DOMAIN.key" "$CERT_DIR/"
        sudo chown markmur88:markmur88 "$CERT_DIR/_.$ROOT_DOMAIN."*
        sudo chmod 600 "$CERT_DIR/_.$ROOT_DOMAIN."*
        log "✅ Certificado copiado correctamente"
        exit 0
        ;;
    *)
        info "ℹ  No se encontró certificado válido. Generando nuevo..."
        ;;
esac

# Verificar internet
log "📡 Ping a github.com..."
ping -c1 github.com &>/dev/null || error "Sin conexión a internet"

# Verificar DNS
check_dns "$DOMAIN" || warn "⚠️  Continuando sin verificación DNS (la validación se hará durante la generación del certificado)"

# === 1. Instalar lego si no existe ===
if ! command -v lego >/dev/null; then
    log "📥 Instalando lego..."
    URL=$(curl -s https://api.github.com/repos/go-acme/lego/releases/latest | grep browser_download_url | grep linux_amd64 | cut -d '"' -f 4)
    if [ -z "$URL" ]; then
        error "No se pudo obtener URL de descarga de lego"
    fi
    
    log "📦 Descargando desde: $URL"
    wget -q -O /tmp/lego.tar.gz "$URL" || error "Fallo al descargar"
    
    cd /tmp
    tar -xzf lego.tar.gz || error "Fallo al extraer"
    
    if [ ! -f "/tmp/lego" ]; then
        error "No se encontró el binario lego en el archivo extraído"
    fi
    
    sudo mv /tmp/lego /usr/local/bin/lego
    sudo chmod +x /usr/local/bin/lego
    rm -rf /tmp/lego*
    
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
