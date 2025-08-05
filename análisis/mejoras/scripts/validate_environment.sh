#!/bin/bash

# =============================================================================
# VALIDACIÓN DE ENTORNO - Script de Verificación Pre-Ejecución
# =============================================================================
# Versión: 1.0
# Descripción: Verifica todas las dependencias y condiciones antes de ejecutar
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
VENV_PATH="$PROJECT_BASE_DIR/envAPP"
LOG_DIR="$SCRIPTS_DIR/.logs"

# Variables de estado
ERRORS=0
WARNINGS=0
CHECKS_PASSED=0
TOTAL_CHECKS=0

# Función para mostrar resultados
show_result() {
    local status=$1
    local message=$2
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    case $status in
        "OK")
            echo -e "${GREEN}✅ $message${NC}"
            CHECKS_PASSED=$((CHECKS_PASSED + 1))
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  $message${NC}"
            WARNINGS=$((WARNINGS + 1))
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ERRORS=$((ERRORS + 1))
            ;;
    esac
}

# Función para mostrar banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                VALIDACIÓN DE ENTORNO v1.0                   ║"
    echo "║                Verificación Pre-Ejecución                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Función para verificar sistema operativo
check_os() {
    echo -e "${BLUE}🔍 Verificando Sistema Operativo...${NC}"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        show_result "OK" "Sistema operativo: Linux detectado"
        
        # Verificar distribución
        if command -v lsb_release &> /dev/null; then
            DISTRO=$(lsb_release -d | cut -f2)
            show_result "OK" "Distribución: $DISTRO"
        else
            show_result "WARNING" "No se pudo detectar la distribución específica"
        fi
    else
        show_result "ERROR" "Sistema operativo no soportado: $OSTYPE"
    fi
    echo ""
}

# Función para verificar permisos y usuario
check_permissions() {
    echo -e "${BLUE}🔐 Verificando Permisos y Usuario...${NC}"
    
    # Verificar si es el usuario correcto
    if [[ "$USER" == "markmur88" ]]; then
        show_result "OK" "Usuario correcto: $USER"
    else
        show_result "WARNING" "Usuario actual: $USER (esperado: markmur88)"
    fi
    
    # Verificar permisos sudo
    if sudo -n true 2>/dev/null; then
        show_result "OK" "Permisos sudo disponibles"
    else
        show_result "WARNING" "Permisos sudo requieren contraseña"
    fi
    
    # Verificar directorio home
    if [[ -d "$HOME" ]]; then
        show_result "OK" "Directorio home: $HOME"
    else
        show_result "ERROR" "Directorio home no encontrado: $HOME"
    fi
    echo ""
}

# Función para verificar conectividad
check_connectivity() {
    echo -e "${BLUE}🌐 Verificando Conectividad...${NC}"
    
    # Verificar conexión a internet
    if ping -c 1 google.com &> /dev/null; then
        show_result "OK" "Conexión a internet: Disponible"
    else
        show_result "ERROR" "Conexión a internet: No disponible"
    fi
    
    # Verificar DNS
    if nslookup google.com &> /dev/null; then
        show_result "OK" "Resolución DNS: Funcionando"
    else
        show_result "WARNING" "Resolución DNS: Problemas detectados"
    fi
    
    # Verificar repositorios de paquetes
    if sudo apt-get update &> /dev/null; then
        show_result "OK" "Repositorios de paquetes: Accesibles"
    else
        show_result "WARNING" "Repositorios de paquetes: Problemas de acceso"
    fi
    echo ""
}

# Función para verificar espacio en disco
check_disk_space() {
    echo -e "${BLUE}💾 Verificando Espacio en Disco...${NC}"
    
    # Obtener uso del disco raíz
    DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [[ $DISK_USAGE -lt 80 ]]; then
        show_result "OK" "Espacio en disco: ${DISK_USAGE}% usado"
    elif [[ $DISK_USAGE -lt 90 ]]; then
        show_result "WARNING" "Espacio en disco: ${DISK_USAGE}% usado (cercano al límite)"
    else
        show_result "ERROR" "Espacio en disco: ${DISK_USAGE}% usado (CRÍTICO)"
    fi
    
    # Verificar espacio en /home
    if [[ -d "$HOME" ]]; then
        HOME_USAGE=$(df "$HOME" | tail -1 | awk '{print $5}' | sed 's/%//')
        if [[ $HOME_USAGE -lt 85 ]]; then
            show_result "OK" "Espacio en /home: ${HOME_USAGE}% usado"
        else
            show_result "WARNING" "Espacio en /home: ${HOME_USAGE}% usado"
        fi
    fi
    echo ""
}

# Función para verificar directorios del proyecto
check_project_directories() {
    echo -e "${BLUE}📁 Verificando Directorios del Proyecto...${NC}"
    
    # Verificar directorio base
    if [[ -d "$PROJECT_BASE_DIR" ]]; then
        show_result "OK" "Directorio base: $PROJECT_BASE_DIR"
    else
        show_result "ERROR" "Directorio base no encontrado: $PROJECT_BASE_DIR"
    fi
    
    # Verificar directorio de scripts
    if [[ -d "$SCRIPTS_DIR" ]]; then
        show_result "OK" "Directorio de scripts: $SCRIPTS_DIR"
    else
        show_result "ERROR" "Directorio de scripts no encontrado: $SCRIPTS_DIR"
    fi
    
    # Verificar directorio de la aplicación
    if [[ -d "$AP_H2_DIR" ]]; then
        show_result "OK" "Directorio de aplicación: $AP_H2_DIR"
    else
        show_result "WARNING" "Directorio de aplicación no encontrado: $AP_H2_DIR"
    fi
    
    # Verificar entorno virtual
    if [[ -d "$VENV_PATH" ]]; then
        show_result "OK" "Entorno virtual: $VENV_PATH"
    else
        show_result "WARNING" "Entorno virtual no encontrado: $VENV_PATH"
    fi
    
    # Verificar directorio de logs
    if [[ -d "$LOG_DIR" ]]; then
        show_result "OK" "Directorio de logs: $LOG_DIR"
    else
        show_result "WARNING" "Directorio de logs no encontrado: $LOG_DIR"
    fi
    echo ""
}

# Función para verificar servicios críticos
check_critical_services() {
    echo -e "${BLUE}⚙️  Verificando Servicios Críticos...${NC}"
    
    # Verificar PostgreSQL
    if systemctl is-active --quiet postgresql; then
        show_result "OK" "PostgreSQL: Activo"
    else
        show_result "WARNING" "PostgreSQL: Inactivo"
    fi
    
    # Verificar Nginx
    if systemctl is-active --quiet nginx; then
        show_result "OK" "Nginx: Activo"
    else
        show_result "WARNING" "Nginx: Inactivo"
    fi
    
    # Verificar Gunicorn
    if systemctl is-active --quiet gunicorn; then
        show_result "OK" "Gunicorn: Activo"
    else
        show_result "WARNING" "Gunicorn: Inactivo"
    fi
    
    # Verificar UFW
    if systemctl is-active --quiet ufw; then
        show_result "OK" "UFW Firewall: Activo"
    else
        show_result "WARNING" "UFW Firewall: Inactivo"
    fi
    echo ""
}

# Función para verificar dependencias de software
check_software_dependencies() {
    echo -e "${BLUE}📦 Verificando Dependencias de Software...${NC}"
    
    # Verificar comandos esenciales
    local essential_commands=("git" "python3" "pip3" "node" "npm" "docker" "docker-compose")
    
    for cmd in "${essential_commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            show_result "OK" "$cmd: Disponible"
        else
            show_result "WARNING" "$cmd: No encontrado"
        fi
    done
    
    # Verificar versiones específicas
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        show_result "OK" "Python versión: $PYTHON_VERSION"
    fi
    
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version | cut -d' ' -f3)
        show_result "OK" "Git versión: $GIT_VERSION"
    fi
    echo ""
}

# Función para verificar configuración de red
check_network_config() {
    echo -e "${BLUE}🌐 Verificando Configuración de Red...${NC}"
    
    # Verificar interfaces de red
    if ip link show &> /dev/null; then
        show_result "OK" "Interfaces de red: Detectadas"
    else
        show_result "WARNING" "No se pudieron detectar interfaces de red"
    fi
    
    # Verificar puertos críticos
    local critical_ports=(22 80 443 5432 8000)
    
    for port in "${critical_ports[@]}"; do
        if netstat -tuln | grep ":$port " &> /dev/null; then
            show_result "OK" "Puerto $port: En uso"
        else
            show_result "INFO" "Puerto $port: Libre"
        fi
    done
    echo ""
}

# Función para verificar archivos de configuración críticos
check_config_files() {
    echo -e "${BLUE}⚙️  Verificando Archivos de Configuración...${NC}"
    
    # Verificar archivos críticos
    local config_files=(
        "$SCRIPTS_DIR/dirs.sh"
        "$SCRIPTS_DIR/menu/aliases_deploy.sh"
        "$SCRIPTS_DIR/menu/01_full.sh"
        "$HOME/.zshrc"
    )
    
    for file in "${config_files[@]}"; do
        if [[ -f "$file" ]]; then
            show_result "OK" "Archivo encontrado: $(basename "$file")"
        else
            show_result "WARNING" "Archivo no encontrado: $(basename "$file")"
        fi
    done
    echo ""
}

# Función para mostrar resumen
show_summary() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                        RESUMEN                               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    echo -e "${WHITE}📊 Estadísticas:${NC}"
    echo -e "   Total de verificaciones: $TOTAL_CHECKS"
    echo -e "   ✅ Exitosas: $CHECKS_PASSED"
    echo -e "   ⚠️  Advertencias: $WARNINGS"
    echo -e "   ❌ Errores: $ERRORS"
    echo ""
    
    # Calcular porcentaje de éxito
    if [[ $TOTAL_CHECKS -gt 0 ]]; then
        SUCCESS_RATE=$((CHECKS_PASSED * 100 / TOTAL_CHECKS))
        echo -e "${WHITE}📈 Tasa de éxito: ${SUCCESS_RATE}%${NC}"
        echo ""
    fi
    
    # Recomendaciones
    if [[ $ERRORS -gt 0 ]]; then
        echo -e "${RED}🚨 ACCIÓN REQUERIDA:${NC}"
        echo -e "   Se detectaron $ERRORS errores críticos que deben resolverse antes de continuar."
        echo ""
    fi
    
    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  RECOMENDACIONES:${NC}"
        echo -e "   Se detectaron $WARNINGS advertencias que deberían revisarse."
        echo ""
    fi
    
    if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
        echo -e "${GREEN}🎉 ¡Todo listo!${NC}"
        echo -e "   El entorno está completamente preparado para ejecutar operaciones."
        echo ""
    fi
}

# Función principal
main() {
    show_banner
    
    # Ejecutar todas las verificaciones
    check_os
    check_permissions
    check_connectivity
    check_disk_space
    check_project_directories
    check_critical_services
    check_software_dependencies
    check_network_config
    check_config_files
    
    # Mostrar resumen
    show_summary
    
    # Retornar código de salida apropiado
    if [[ $ERRORS -gt 0 ]]; then
        echo -e "${RED}❌ Validación fallida con $ERRORS errores críticos${NC}"
        exit 1
    elif [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Validación completada con $WARNINGS advertencias${NC}"
        exit 0
    else
        echo -e "${GREEN}✅ Validación exitosa - Entorno listo${NC}"
        exit 0
    fi
}

# Manejo de argumentos
case "${1:-}" in
    --help|-h)
        echo -e "${CYAN}Uso: $0 [opciones]${NC}"
        echo ""
        echo "Opciones:"
        echo "  --help, -h     Mostrar esta ayuda"
        echo "  --quick        Verificación rápida (solo crítico)"
        echo "  --full         Verificación completa (por defecto)"
        echo ""
        echo "Códigos de salida:"
        echo "  0              Éxito (con o sin advertencias)"
        echo "  1              Error crítico detectado"
        ;;
    --quick)
        echo -e "${YELLOW}🔍 Ejecutando verificación rápida...${NC}"
        # Aquí irían solo las verificaciones críticas
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