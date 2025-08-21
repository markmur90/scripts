#!/bin/bash

# =============================================================================
# SINCRONIZACIÓN AL VPS - Sin Git, usando rsync
# =============================================================================

# Variables
LOCAL_BASE_DIR="/home/markmur88"
VPS_USER="markmur88"
VPS_HOST="80.78.30.242"
VPS_BASE_DIR="/home/markmur88"
SSH_KEY="/home/markmur88/.ssh/vps_njalla_nueva"

# Carpetas del proyecto que se deben sincronizar
PROJECT_FOLDERS=(
    "api_bank_h2"
    "api_bank_heroku"
    "scripts"
    "Simulador"
    "eliza-develop"
)

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}🔄 Iniciando sincronización completa al VPS...${NC}"
echo ""

# Verificar que las carpetas existen localmente
echo -e "${CYAN}📁 Verificando carpetas del proyecto...${NC}"
for folder in "${PROJECT_FOLDERS[@]}"; do
    if [[ -d "$LOCAL_BASE_DIR/$folder" ]]; then
        echo -e "${GREEN}✅ $folder encontrada${NC}"
    else
        echo -e "${YELLOW}⚠️  $folder no encontrada (se omitirá)${NC}"
    fi
done
echo ""

# Función para sincronizar una carpeta
sync_folder() {
    local folder=$1
    local local_path="$LOCAL_BASE_DIR/$folder"
    local vps_path="$VPS_BASE_DIR/$folder"
    
    if [[ ! -d "$local_path" ]]; then
        echo -e "${YELLOW}⚠️  Saltando $folder (no existe)${NC}"
        return
    fi
    
    echo -e "${BLUE}🔄 Sincronizando $folder...${NC}"
    
    # Crear directorio en VPS si no existe
    ssh -i "$SSH_KEY" "$VPS_USER@$VPS_HOST" "mkdir -p $vps_path"
    
    # Sincronizar con exclusiones
    rsync -avz --delete -e "ssh -i $SSH_KEY" \
        --exclude='.git/' \
        --exclude='__pycache__/' \
        --exclude='*.pyc' \
        --exclude='*.log' \
        --exclude='*.tmp' \
        --exclude='*.cache' \
        --exclude='media/uploads/' \
        --exclude='static/admin/' \
        --exclude='static/rest_framework/' \
        --exclude='node_modules/' \
        --exclude='.env' \
        --exclude='*.sqlite3' \
        --exclude='*.db' \
        --exclude='.coverage' \
        --exclude='htmlcov/' \
        --exclude='.pytest_cache/' \
        --exclude='.tox/' \
        --exclude='.mypy_cache/' \
        --exclude='.ruff_cache/' \
        --exclude='*.zip' \
        --exclude='*.tar.gz' \
        --exclude='*.rar' \
        --exclude='*.7z' \
        --exclude='backup/' \
        --exclude='logs/' \
        --exclude='temp/' \
        --exclude='tmp/' \
        "$local_path/" \
        "$VPS_USER@$VPS_HOST:$vps_path/"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $folder sincronizada exitosamente${NC}"
    else
        echo -e "${RED}❌ Error sincronizando $folder${NC}"
        return 1
    fi
}

# Sincronizar cada carpeta
echo -e "${CYAN}🚀 Iniciando sincronización de todas las carpetas...${NC}"
echo ""

SYNC_ERRORS=0

for folder in "${PROJECT_FOLDERS[@]}"; do
    if ! sync_folder "$folder"; then
        SYNC_ERRORS=$((SYNC_ERRORS + 1))
    fi
    echo ""
done

# Verificar resultado
if [[ $SYNC_ERRORS -eq 0 ]]; then
    echo -e "${GREEN}🎉 Sincronización completada exitosamente${NC}"
    echo ""
    
    # Ejecutar despliegue en el VPS
    echo -e "${YELLOW}🚀 Ejecutando despliegue en VPS...${NC}"
    ssh -i "$SSH_KEY" "$VPS_USER@$VPS_HOST" "bash /home/markmur88/scripts/análisis/mejoras/scripts/deploy_optimized.sh"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Despliegue completado exitosamente${NC}"
    else
        echo -e "${RED}❌ Error en el despliegue${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Sincronización fallida con $SYNC_ERRORS errores${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}📊 Resumen de sincronización:${NC}"
echo -e "   Carpetas sincronizadas: ${#PROJECT_FOLDERS[@]}"
echo -e "   Errores: $SYNC_ERRORS"
echo -e "   VPS: $VPS_HOST"
echo "" 