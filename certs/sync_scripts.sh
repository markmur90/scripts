#!/bin/bash

# === CONFIGURACIÓN ===
LOCAL_DIR="/home/markmur88/scripts"
REMOTE_DIR="/home/markmur88"
REMOTE_HOST="coretransapi.com"
REMOTE_USER="markmur88"

# === COLORES Y FUNCIONES ===
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

log()   { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warn()  { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠ $1${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}"; }

# === CREAR ARCHIVO DE EXCLUSIÓN ===
EXCLUDE_FILE="/tmp/rsync_exclude.txt"
cat > "$EXCLUDE_FILE" << 'EOF'
# Excluir certificados SSL sensibles
**/.lego/
**/.lego/**
**/certificates/
**/*.crt
**/*.key
**/*.pem

# Excluir logs y archivos temporales
**/*.log
**/tmp/
**/temp/
**/*.tmp

# Excluir archivos de configuración sensibles
**/.env
**/config.json
**/secrets.json

# Excluir archivos de sistema
**/.DS_Store
**/Thumbs.db
**/*~
EOF

log "🔄 Iniciando sincronización de scripts..."
log "📁 Origen: $LOCAL_DIR"
log "📁 Destino: $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"
log "🚫 Excluyendo certificados SSL y archivos sensibles"

# Ejecutar rsync con exclusiones
rsync -avz --delete \
    --exclude-from="$EXCLUDE_FILE" \
    --progress \
    "$LOCAL_DIR/" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/scripts/"

if [ $? -eq 0 ]; then
    log "✅ Sincronización completada exitosamente"
else
    error "❌ Error durante la sincronización"
    exit 1
fi

# Limpiar archivo temporal
rm -f "$EXCLUDE_FILE"

log "🎉 Scripts sincronizados sin incluir certificados SSL"
