#!/bin/bash

# =============================================================================
# OPTIMIZACIÓN DE DESPLIEGUE - Script para VPS con espacio limitado
# =============================================================================
# Versión: 1.0
# Descripción: Optimiza el despliegue eliminando archivos innecesarios
# Autor: Análisis Automático
# Fecha: $(date +"%Y-%m-%d")
# =============================================================================

# Colores para la interfaz
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Variables del proyecto
PROJECT_BASE_DIR="/home/markmur88"
SCRIPTS_DIR="$PROJECT_BASE_DIR/scripts"
AP_H2_DIR="$PROJECT_BASE_DIR/api_bank_h2"
VENV_PATH="$PROJECT_BASE_DIR/envSIM"
BACKUP_DIR="$PROJECT_BASE_DIR/backup/zip"

# Variables de optimización
SPACE_SAVED=0
FILES_REMOVED=0
DIRECTORIES_CLEANED=0

# Función para mostrar banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              OPTIMIZACIÓN DE DESPLIEGUE v1.0                ║"
    echo "║                Optimización para VPS Limitado               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Función para calcular tamaño de archivos/directorios
calculate_size() {
    local path=$1
    if [[ -e "$path" ]]; then
        du -sh "$path" 2>/dev/null | cut -f1
    else
        echo "0B"
    fi
}

# Función para mostrar progreso
show_progress() {
    local message=$1
    echo -e "${BLUE}🔄 $message${NC}"
}

# Función para mostrar resultado
show_result() {
    local status=$1
    local message=$2
    local size_saved=$3
    
    case $status in
        "SUCCESS")
            echo -e "${GREEN}✅ $message${NC}"
            if [[ -n "$size_saved" ]]; then
                echo -e "${CYAN}   💾 Espacio liberado: $size_saved${NC}"
                SPACE_SAVED=$((SPACE_SAVED + $(echo "$size_saved" | sed 's/[^0-9]//g')))
            fi
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ;;
    esac
}

# Función para limpiar archivos de desarrollo
clean_development_files() {
    echo -e "${PURPLE}🧹 LIMPIEZA DE ARCHIVOS DE DESARROLLO${NC}"
    echo ""
    
    # Definir todas las carpetas del proyecto
    PROJECT_FOLDERS=(
        "api_bank_h2"
        "api_bank_heroku"
        "scripts"
        "Simulador"
        "eliza-develop"
    )
    
    # Archivos a eliminar
    local dev_files=(
        ".git"
        ".gitignore"
        ".gitattributes"
        "README.md"
        "*.log"
        "*.tmp"
        "*.cache"
        "*.pyc"
        "__pycache__"
        ".pytest_cache"
        ".coverage"
        "htmlcov"
        ".tox"
        ".mypy_cache"
        ".ruff_cache"
        "node_modules"
        "package-lock.json"
        "yarn.lock"
        ".env.example"
        ".env.local"
        ".env.development"
        "*.sqlite3"
        "*.db"
        "media/uploads"
        "static/admin"
        "static/rest_framework"
    )
    
    # Limpiar cada carpeta del proyecto
    for project_folder in "${PROJECT_FOLDERS[@]}"; do
        local project_path="$PROJECT_BASE_DIR/$project_folder"
        
        if [[ -d "$project_path" ]]; then
            echo -e "${BLUE}🔄 Limpiando $project_folder...${NC}"
            
            for pattern in "${dev_files[@]}"; do
                if [[ "$pattern" == ".git" ]]; then
                    # Eliminar directorio .git específicamente
                    if [[ -d "$project_path/.git" ]]; then
                        local git_size=$(calculate_size "$project_path/.git")
                        show_progress "Eliminando directorio .git de $project_folder..."
                        rm -rf "$project_path/.git"
                        show_result "SUCCESS" "Directorio .git eliminado de $project_folder" "$git_size"
                        FILES_REMOVED=$((FILES_REMOVED + 1))
                    fi
                else
                    # Buscar archivos que coincidan con el patrón
                    find "$project_path" -name "$pattern" -type f -delete 2>/dev/null
                    find "$project_path" -name "$pattern" -type d -exec rm -rf {} + 2>/dev/null
                fi
            done
            
            echo -e "${GREEN}✅ $project_folder limpiada${NC}"
        else
            echo -e "${YELLOW}⚠️  $project_folder no encontrada (saltando)${NC}"
        fi
    done
    echo ""
}

# Función para optimizar archivos Python
optimize_python_files() {
    echo -e "${PURPLE}🐍 OPTIMIZACIÓN DE ARCHIVOS PYTHON${NC}"
    echo ""
    
    # Definir todas las carpetas del proyecto
    PROJECT_FOLDERS=(
        "api_bank_h2"
        "api_bank_heroku"
        "scripts"
        "Simulador"
        "eliza-develop"
    )
    
    # Optimizar cada carpeta del proyecto
    for project_folder in "${PROJECT_FOLDERS[@]}"; do
        local project_path="$PROJECT_BASE_DIR/$project_folder"
        
        if [[ -d "$project_path" ]]; then
            echo -e "${BLUE}🔄 Optimizando Python en $project_folder...${NC}"
            
            # Compilar archivos Python
            show_progress "Compilando archivos Python en $project_folder..."
            find "$project_path" -name "*.py" -exec python3 -m py_compile {} \; 2>/dev/null
            
            # Eliminar archivos .pyc antiguos
            show_progress "Limpiando archivos .pyc antiguos en $project_folder..."
            find "$project_path" -name "*.pyc" -delete 2>/dev/null
            
            # Eliminar directorios __pycache__
            show_progress "Eliminando directorios __pycache__ en $project_folder..."
            find "$project_path" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
            
            echo -e "${GREEN}✅ $project_folder optimizada${NC}"
        else
            echo -e "${YELLOW}⚠️  $project_folder no encontrada (saltando)${NC}"
        fi
    done
    
    show_result "SUCCESS" "Archivos Python optimizados en todas las carpetas"
    echo ""
}

# Función para optimizar archivos estáticos
optimize_static_files() {
    echo -e "${PURPLE}📁 OPTIMIZACIÓN DE ARCHIVOS ESTÁTICOS${NC}"
    echo ""
    
    # Definir todas las carpetas del proyecto
    PROJECT_FOLDERS=(
        "api_bank_h2"
        "api_bank_heroku"
        "scripts"
        "Simulador"
        "eliza-develop"
    )
    
    # Optimizar cada carpeta del proyecto
    for project_folder in "${PROJECT_FOLDERS[@]}"; do
        local project_path="$PROJECT_BASE_DIR/$project_folder"
        
        if [[ -d "$project_path" ]]; then
            echo -e "${BLUE}🔄 Optimizando archivos estáticos en $project_folder...${NC}"
            
            # Comprimir archivos CSS y JS
            show_progress "Comprimiendo archivos CSS y JS en $project_folder..."
            find "$project_path/static" -name "*.css" -exec gzip -9 {} \; 2>/dev/null
            find "$project_path/static" -name "*.js" -exec gzip -9 {} \; 2>/dev/null
            
            # Eliminar archivos de desarrollo de static
            local static_dev_files=(
                "*.map"
                "*.min.js"
                "*.min.css"
                "source"
                "src"
                "dev"
            )
            
            for pattern in "${static_dev_files[@]}"; do
                find "$project_path/static" -name "$pattern" -delete 2>/dev/null
            done
            
            echo -e "${GREEN}✅ $project_folder optimizada${NC}"
        else
            echo -e "${YELLOW}⚠️  $project_folder no encontrada (saltando)${NC}"
        fi
    done
    
    show_result "SUCCESS" "Archivos estáticos optimizados en todas las carpetas"
    echo ""
}

# Función para limpiar logs y archivos temporales
clean_logs_and_temp() {
    echo -e "${PURPLE}📋 LIMPIEZA DE LOGS Y ARCHIVOS TEMPORALES${NC}"
    echo ""
    
    # Limpiar logs antiguos
    show_progress "Limpiando logs antiguos..."
    find "$SCRIPTS_DIR/.logs" -name "*.log" -mtime +7 -delete 2>/dev/null
    find "$AP_H2_DIR" -name "*.log" -mtime +3 -delete 2>/dev/null
    
    # Limpiar archivos temporales
    show_progress "Limpiando archivos temporales..."
    find "$AP_H2_DIR" -name "*.tmp" -delete 2>/dev/null
    find "$AP_H2_DIR" -name "*.cache" -delete 2>/dev/null
    find "$AP_H2_DIR" -name "*.swp" -delete 2>/dev/null
    find "$AP_H2_DIR" -name "*.swo" -delete 2>/dev/null
    
    # Limpiar directorio temp del sistema
    show_progress "Limpiando directorio /tmp..."
    sudo rm -rf /tmp/* 2>/dev/null
    
    show_result "SUCCESS" "Logs y archivos temporales limpiados"
    echo ""
}

# Función para optimizar base de datos
optimize_database() {
    echo -e "${PURPLE}💾 OPTIMIZACIÓN DE BASE DE DATOS${NC}"
    echo ""
    
    # Vacuum y reindex PostgreSQL
    show_progress "Optimizando base de datos PostgreSQL..."
    sudo -u postgres psql -c "VACUUM FULL;" 2>/dev/null
    sudo -u postgres psql -c "REINDEX DATABASE api_bank_h2;" 2>/dev/null
    
    show_result "SUCCESS" "Base de datos optimizada"
    echo ""
}

# Función para crear archivo .gitignore optimizado
create_optimized_gitignore() {
    echo -e "${PURPLE}📝 CREANDO .GITIGNORE OPTIMIZADO${NC}"
    echo ""
    
    cat > "$AP_H2_DIR/.gitignore" << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Django
*.log
local_settings.py
db.sqlite3
db.sqlite3-journal
media/
static/admin/
static/rest_framework/

# Environment
.env
.env.local
.env.development
.env.test
.env.production
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Development
*.tmp
*.cache
.coverage
htmlcov/
.pytest_cache/
.tox/
.mypy_cache/
.ruff_cache/

# Node.js (si se usa)
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Backup files
*.bak
*.backup
*.old

# Large files
*.zip
*.tar.gz
*.rar
*.7z
EOF

    show_result "SUCCESS" "Archivo .gitignore optimizado creado"
    echo ""
}

# Función para crear script de despliegue optimizado
create_optimized_deploy_script() {
    echo -e "${PURPLE}🚀 CREANDO SCRIPT DE DESPLIEGUE OPTIMIZADO${NC}"
    echo ""
    
    cat > "$SCRIPTS_DIR/deploy_optimized.sh" << 'EOF'
#!/bin/bash

# =============================================================================
# DESPLIEGUE OPTIMIZADO - Sin Git, directo al VPS
# =============================================================================

# Variables
PROJECT_DIR="/home/markmur88/api_bank_h2"
VENV_PATH="/home/markmur88/envSIM"
BACKUP_DIR="/home/markmur88/backup/zip"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Iniciando despliegue optimizado...${NC}"

# 1. Crear backup antes del despliegue
echo -e "${YELLOW}📦 Creando backup de seguridad...${NC}"
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/backup_before_deploy_$DATE.zip"
cd "$PROJECT_DIR/.."
zip -r "$BACKUP_FILE" api_bank_h2 -x "api_bank_h2/.git/*" "api_bank_h2/__pycache__/*" "api_bank_h2/*.log"

# 2. Activar entorno virtual
echo -e "${YELLOW}🐍 Activando entorno virtual...${NC}"
source "$VENV_PATH/bin/activate"

# 3. Instalar/actualizar dependencias
echo -e "${YELLOW}📦 Actualizando dependencias...${NC}"
cd "$PROJECT_DIR"
pip install -r requirements.txt --no-cache-dir

# 4. Aplicar migraciones
echo -e "${YELLOW}🔄 Aplicando migraciones...${NC}"
python manage.py migrate --noinput

# 5. Recolectar archivos estáticos
echo -e "${YELLOW}📁 Recolectando archivos estáticos...${NC}"
python manage.py collectstatic --noinput --clear

# 6. Reiniciar servicios
echo -e "${YELLOW}🔄 Reiniciando servicios...${NC}"
sudo systemctl restart gunicorn
sudo systemctl restart nginx

# 7. Verificar estado
echo -e "${YELLOW}🔍 Verificando estado de servicios...${NC}"
sudo systemctl status gunicorn --no-pager
sudo systemctl status nginx --no-pager

echo -e "${GREEN}✅ Despliegue optimizado completado${NC}"
echo -e "${GREEN}💾 Backup creado: $BACKUP_FILE${NC}"
EOF

    chmod +x "$SCRIPTS_DIR/deploy_optimized.sh"
    show_result "SUCCESS" "Script de despliegue optimizado creado"
    echo ""
}

# Función para crear script de sincronización sin Git
create_sync_script() {
    echo -e "${PURPLE}🔄 CREANDO SCRIPT DE SINCRONIZACIÓN SIN GIT${NC}"
    echo ""
    
    cat > "$SCRIPTS_DIR/sync_to_vps.sh" << 'EOF'
#!/bin/bash

# =============================================================================
# SINCRONIZACIÓN AL VPS - Sin Git, usando rsync
# =============================================================================

# Variables
LOCAL_PROJECT="/home/markmur88/api_bank_h2"
VPS_USER="markmur88"
VPS_HOST="80.78.30.242"
VPS_PROJECT="/home/markmur88/api_bank_h2"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔄 Iniciando sincronización al VPS...${NC}"

# Excluir archivos innecesarios
rsync -avz --delete \
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
    "$LOCAL_PROJECT/" \
    "$VPS_USER@$VPS_HOST:$VPS_PROJECT/"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Sincronización completada exitosamente${NC}"
    
    # Ejecutar despliegue en el VPS
    echo -e "${YELLOW}🚀 Ejecutando despliegue en VPS...${NC}"
    ssh "$VPS_USER@$VPS_HOST" "cd $VPS_PROJECT && ./deploy_optimized.sh"
else
    echo -e "${RED}❌ Error en la sincronización${NC}"
    exit 1
fi
EOF

    chmod +x "$SCRIPTS_DIR/sync_to_vps.sh"
    show_result "SUCCESS" "Script de sincronización sin Git creado"
    echo ""
}

# Función para mostrar estadísticas de espacio
show_space_stats() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    ESTADÍSTICAS DE ESPACIO                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    echo -e "${WHITE}📊 Estadísticas de optimización:${NC}"
    echo -e "   Archivos eliminados: $FILES_REMOVED"
    echo -e "   Directorios limpiados: $DIRECTORIES_CLEANED"
    echo -e "   Espacio liberado: ${SPACE_SAVED}MB"
    echo ""
    
    # Mostrar uso actual de disco
    echo -e "${WHITE}💾 Uso actual de disco:${NC}"
    df -h | grep -E "Filesystem|/$"
    echo ""
    
    # Mostrar directorios más grandes
    echo -e "${WHITE}📁 Directorios más grandes:${NC}"
    du -sh "$AP_H2_DIR"/* 2>/dev/null | sort -hr | head -10
    echo ""
}

# Función para crear alias optimizado
create_optimized_alias() {
    echo -e "${PURPLE}🎯 CREANDO ALIAS OPTIMIZADO${NC}"
    echo ""
    
    cat >> "$HOME/.zshrc" << 'EOF'

# =============================================================================
# ALIASES OPTIMIZADOS PARA VPS
# =============================================================================

# Despliegue optimizado (sin Git)
alias deploy_opt='cd /home/markmur88/scripts && ./deploy_optimized.sh'

# Sincronización al VPS (sin Git)
alias sync_vps='cd /home/markmur88/scripts && ./sync_to_vps.sh'

# Optimización de espacio
alias optimize_space='cd /home/markmur88/scripts && ./optimize_deployment.sh'

# Verificar espacio en disco
alias check_space='df -h && echo "--- Directorios más grandes ---" && du -sh /home/markmur88/* 2>/dev/null | sort -hr | head -10'

# Limpieza rápida
alias quick_clean='sudo apt-get autoremove -y && sudo apt-get autoclean && sudo rm -rf /tmp/*'

# Estado de servicios
alias services_status='sudo systemctl status gunicorn nginx postgresql --no-pager'
EOF

    show_result "SUCCESS" "Alias optimizados agregados a .zshrc"
    echo ""
}

# Función principal
main() {
    show_banner
    
    echo -e "${YELLOW}⚠️  ADVERTENCIA: Esta optimización eliminará archivos de desarrollo${NC}"
    echo -e "${YELLOW}   Asegúrate de tener un backup antes de continuar${NC}"
    echo ""
    read -p "¿Continuar con la optimización? (s/n): " confirm
    
    if [[ ! $confirm =~ ^[Ss]$ ]]; then
        echo -e "${RED}❌ Optimización cancelada${NC}"
        exit 0
    fi
    
    # Ejecutar optimizaciones
    clean_development_files
    optimize_python_files
    optimize_static_files
    clean_logs_and_temp
    optimize_database
    create_optimized_gitignore
    create_optimized_deploy_script
    create_sync_script
    create_optimized_alias
    
    # Mostrar estadísticas
    show_space_stats
    
    echo -e "${GREEN}🎉 Optimización completada exitosamente${NC}"
    echo ""
    echo -e "${CYAN}📋 Próximos pasos:${NC}"
    echo -e "   1. Recargar configuración: source ~/.zshrc"
    echo -e "   2. Usar 'deploy_opt' para despliegues optimizados"
    echo -e "   3. Usar 'sync_vps' para sincronización sin Git"
    echo -e "   4. Usar 'check_space' para monitorear espacio"
    echo ""
}

# Manejo de argumentos
case "${1:-}" in
    --help|-h)
        echo -e "${CYAN}Uso: $0 [opciones]${NC}"
        echo ""
        echo "Opciones:"
        echo "  --help, -h     Mostrar esta ayuda"
        echo "  --quick        Optimización rápida (solo archivos críticos)"
        echo "  --full         Optimización completa (por defecto)"
        echo ""
        echo "Este script optimiza el despliegue para VPS con espacio limitado."
        ;;
    --quick)
        echo -e "${YELLOW}🔍 Ejecutando optimización rápida...${NC}"
        # Solo optimizaciones críticas
        clean_development_files
        clean_logs_and_temp
        show_space_stats
        ;;
    --full|"")
        main
        ;;
    *)
        echo -e "${RED}❌ Opción no válida: $1${NC}"
        echo -e "${CYAN}Usa --help para ver las opciones disponibles${NC}"
        exit 1
        ;;
esac 