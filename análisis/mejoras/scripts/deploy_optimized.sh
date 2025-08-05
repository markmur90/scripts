#!/bin/bash

# =============================================================================
# DESPLIEGUE OPTIMIZADO - Sin Git, directo al VPS
# =============================================================================

# Variables
PROJECT_BASE_DIR="/home/markmur88"
VENV_PATH="/home/markmur88/envAPP"
BACKUP_DIR="/home/markmur88/backup/zip"

# Carpetas del proyecto
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

echo -e "${GREEN}🚀 Iniciando despliegue optimizado completo...${NC}"
echo ""

# Función para crear backup de una carpeta
create_backup() {
    local folder=$1
    local folder_path="$PROJECT_BASE_DIR/$folder"
    
    if [[ ! -d "$folder_path" ]]; then
        echo -e "${YELLOW}⚠️  Saltando backup de $folder (no existe)${NC}"
        return
    fi
    
    echo -e "${BLUE}📦 Creando backup de $folder...${NC}"
    DATE=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/backup_${folder}_$DATE.zip"
    
    cd "$PROJECT_BASE_DIR"
    zip -r "$BACKUP_FILE" "$folder" -x "$folder/.git/*" "$folder/__pycache__/*" "$folder/*.log" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Backup de $folder creado: $BACKUP_FILE${NC}"
    else
        echo -e "${RED}❌ Error creando backup de $folder${NC}"
    fi
}

# Función para desplegar una carpeta Django
deploy_django_app() {
    local folder=$1
    local folder_path="$PROJECT_BASE_DIR/$folder"
    
    if [[ ! -d "$folder_path" ]]; then
        echo -e "${YELLOW}⚠️  Saltando despliegue de $folder (no existe)${NC}"
        return
    fi
    
    # Verificar si es una aplicación Django
    if [[ -f "$folder_path/manage.py" ]]; then
        echo -e "${CYAN}🐍 Desplegando aplicación Django: $folder${NC}"
        
        cd "$folder_path"
        
        # Instalar dependencias si existe requirements.txt
        if [[ -f "requirements.txt" ]]; then
            echo -e "${BLUE}📦 Instalando dependencias de $folder...${NC}"
            pip install -r requirements.txt --no-cache-dir
        fi
        
        # Aplicar migraciones
        echo -e "${BLUE}🔄 Aplicando migraciones de $folder...${NC}"
        python manage.py migrate --noinput
        
        # Recolectar archivos estáticos
        echo -e "${BLUE}📁 Recolectando archivos estáticos de $folder...${NC}"
        python manage.py collectstatic --noinput --clear
        
        echo -e "${GREEN}✅ $folder desplegada exitosamente${NC}"
    else
        echo -e "${YELLOW}ℹ️  $folder no es una aplicación Django (saltando)${NC}"
    fi
}

# Función para desplegar una carpeta Node.js
deploy_node_app() {
    local folder=$1
    local folder_path="$PROJECT_BASE_DIR/$folder"
    
    if [[ ! -d "$folder_path" ]]; then
        echo -e "${YELLOW}⚠️  Saltando despliegue de $folder (no existe)${NC}"
        return
    fi
    
    # Verificar si es una aplicación Node.js
    if [[ -f "$folder_path/package.json" ]]; then
        echo -e "${CYAN}📦 Desplegando aplicación Node.js: $folder${NC}"
        
        cd "$folder_path"
        
        # Instalar dependencias
        echo -e "${BLUE}📦 Instalando dependencias de $folder...${NC}"
        npm install --production
        
        # Construir si es necesario
        if [[ -f "package.json" ]] && grep -q "\"build\"" package.json; then
            echo -e "${BLUE}🔨 Construyendo $folder...${NC}"
            npm run build
        fi
        
        echo -e "${GREEN}✅ $folder desplegada exitosamente${NC}"
    else
        echo -e "${YELLOW}ℹ️  $folder no es una aplicación Node.js (saltando)${NC}"
    fi
}

# Función para desplegar scripts
deploy_scripts() {
    local folder=$1
    local folder_path="$PROJECT_BASE_DIR/$folder"
    
    if [[ ! -d "$folder_path" ]]; then
        echo -e "${YELLOW}⚠️  Saltando despliegue de $folder (no existe)${NC}"
        return
    fi
    
    if [[ "$folder" == "scripts" ]]; then
        echo -e "${CYAN}🔧 Configurando scripts: $folder${NC}"
        
        cd "$folder_path"
        
        # Dar permisos de ejecución a scripts
        echo -e "${BLUE}🔐 Configurando permisos de scripts...${NC}"
        find . -name "*.sh" -exec chmod +x {} \;
        
        # Configurar alias si es necesario
        if [[ -f "setup_aliases.sh" ]]; then
            echo -e "${BLUE}⚙️  Configurando alias...${NC}"
            bash setup_aliases.sh
        fi
        
        echo -e "${GREEN}✅ Scripts configurados exitosamente${NC}"
    fi
}

# 1. Crear backups de todas las carpetas
echo -e "${CYAN}📦 Creando backups de seguridad...${NC}"
echo ""

for folder in "${PROJECT_FOLDERS[@]}"; do
    create_backup "$folder"
done
echo ""

# 2. Activar entorno virtual
echo -e "${YELLOW}🐍 Activando entorno virtual...${NC}"
if [[ -d "$VENV_PATH" ]]; then
    source "$VENV_PATH/bin/activate"
    echo -e "${GREEN}✅ Entorno virtual activado${NC}"
else
    echo -e "${YELLOW}⚠️  Entorno virtual no encontrado, continuando sin él${NC}"
fi
echo ""

# 3. Desplegar cada carpeta según su tipo
echo -e "${CYAN}🚀 Desplegando aplicaciones...${NC}"
echo ""

for folder in "${PROJECT_FOLDERS[@]}"; do
    echo -e "${BLUE}🔄 Procesando $folder...${NC}"
    
    # Desplegar según el tipo de aplicación
    deploy_django_app "$folder"
    deploy_node_app "$folder"
    deploy_scripts "$folder"
    
    echo ""
done

# 4. Reiniciar servicios
echo -e "${YELLOW}🔄 Reiniciando servicios...${NC}"

# Reiniciar Gunicorn si está configurado
if systemctl list-unit-files | grep -q gunicorn; then
    echo -e "${BLUE}🔄 Reiniciando Gunicorn...${NC}"
    sudo systemctl restart gunicorn
fi

# Reiniciar Nginx
echo -e "${BLUE}🔄 Reiniciando Nginx...${NC}"
sudo systemctl restart nginx

# Reiniciar otros servicios si existen
if systemctl list-unit-files | grep -q "api_bank_h2"; then
    echo -e "${BLUE}🔄 Reiniciando servicio api_bank_h2...${NC}"
    sudo systemctl restart api_bank_h2
fi

echo ""

# 5. Verificar estado de servicios
echo -e "${YELLOW}🔍 Verificando estado de servicios...${NC}"

# Verificar servicios principales
SERVICES=("nginx" "gunicorn" "postgresql")
for service in "${SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "$service"; then
        STATUS=$(systemctl is-active "$service")
        if [[ "$STATUS" == "active" ]]; then
            echo -e "${GREEN}✅ $service: Activo${NC}"
        else
            echo -e "${RED}❌ $service: Inactivo${NC}"
        fi
    fi
done

echo ""

# 6. Verificar aplicaciones desplegadas
echo -e "${YELLOW}🔍 Verificando aplicaciones desplegadas...${NC}"

for folder in "${PROJECT_FOLDERS[@]}"; do
    folder_path="$PROJECT_BASE_DIR/$folder"
    if [[ -d "$folder_path" ]]; then
        if [[ -f "$folder_path/manage.py" ]]; then
            echo -e "${GREEN}✅ $folder: Aplicación Django${NC}"
        elif [[ -f "$folder_path/package.json" ]]; then
            echo -e "${GREEN}✅ $folder: Aplicación Node.js${NC}"
        elif [[ "$folder" == "scripts" ]]; then
            echo -e "${GREEN}✅ $folder: Scripts${NC}"
        else
            echo -e "${CYAN}ℹ️  $folder: Carpeta de datos${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  $folder: No encontrada${NC}"
    fi
done

echo ""
echo -e "${GREEN}🎉 Despliegue optimizado completado exitosamente${NC}"
echo ""
echo -e "${CYAN}📊 Resumen del despliegue:${NC}"
echo -e "   Carpetas procesadas: ${#PROJECT_FOLDERS[@]}"
echo -e "   Backups creados: $(ls -1 $BACKUP_DIR/backup_*_$(date +"%Y%m%d")*.zip 2>/dev/null | wc -l)"
echo -e "   Servicios reiniciados: ${#SERVICES[@]}"
echo ""
echo -e "${YELLOW}💡 Próximos pasos:${NC}"
echo -e "   1. Verificar que todas las aplicaciones funcionan correctamente"
echo -e "   2. Probar las funcionalidades principales"
echo -e "   3. Monitorear los logs de servicios"
echo -e "   4. Verificar el uso de espacio en disco"
echo "" 