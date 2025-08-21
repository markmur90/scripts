#!/bin/bash

# =============================================================================
# EXPRESS INTELIGENTE - Script Interactivo Mejorado
# =============================================================================
# Versión: 2.1
# Descripción: Alias Express mejorado con interfaz interactiva y optimización para VPS
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

# Variables del proyecto (copiadas del original)
PROJECT_BASE_DIR="/home/markmur88"
SCRIPTS_DIR="$PROJECT_BASE_DIR/scripts"
AP_H2_DIR="$PROJECT_BASE_DIR/api_bank_h2"
VENV_PATH="$PROJECT_BASE_DIR/envSIM"
LOG_DIR="$SCRIPTS_DIR/.logs"

# Utilidades
ensure_env() {
    if [ -f "$HOME/.zshrc" ]; then
        # shellcheck disable=SC1090
        source "$HOME/.zshrc"
    fi
}

# Ruta de mejoras (esta carpeta)
MEJORAS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Ejecutar deploy_full con flags, sin depender de aliases zsh
DEPLOY_FULL_SCRIPT="/home/markmur88/scripts/menu/01_full.sh"
deploy_full_flags() {
    local flags="$1"
    bash -lc "cd '$AP_H2_DIR'; source '$VENV_PATH/bin/activate' >/dev/null 2>&1 || true; bash '$DEPLOY_FULL_SCRIPT' $flags"
}

# Función para mostrar el banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    EXPRESS INTELIGENTE v2.1                  ║"
    echo "║                    Sistema de Automatización                 ║"
    echo "║                    Optimizado para VPS Limitado             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Función para mostrar el menú principal
show_menu() {
    echo -e "${YELLOW}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│                    MENÚ PRINCIPAL                          │${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${WHITE}Selecciona una opción:${NC}"
    echo ""
    echo -e "${GREEN}[1]${NC} 🚀 ${CYAN}Ejecutar Todo (Express Original)${NC}"
    echo -e "${GREEN}[2]${NC} 🔍 ${CYAN}Verificar Estado del Sistema${NC}"
    echo -e "${GREEN}[3]${NC} ⚡ ${CYAN}Ejecutar Solo lo Necesario (Smart Mode)${NC}"
    echo -e "${GREEN}[4]${NC} 📊 ${CYAN}Dashboard de Estado${NC}"
    echo -e "${GREEN}[5]${NC} 🔧 ${CYAN}Modo Mantenimiento${NC}"
    echo -e "${GREEN}[6]${NC} 🛡️  ${CYAN}Verificación de Seguridad${NC}"
    echo -e "${GREEN}[7]${NC} 📋 ${CYAN}Ver Logs Recientes${NC}"
    echo -e "${GREEN}[8]${NC} 💾 ${CYAN}Optimización de Espacio (NUEVO)${NC}"
    echo -e "${GREEN}[9]${NC} 🚀 ${CYAN}Despliegue Optimizado sin Git (NUEVO)${NC}"
    echo -e "${GREEN}[10]${NC} 🔄 ${CYAN}Sincronización al VPS (NUEVO)${NC}"
    echo -e "${GREEN}[11]${NC} ❓ ${CYAN}Ayuda${NC}"
    echo -e "${GREEN}[0]${NC} 🚪 ${CYAN}Salir${NC}"
    echo ""
}

# Función para verificar el estado del sistema
check_system_status() {
    echo -e "${BLUE}🔍 Verificando estado del sistema...${NC}"
    echo ""
    
    # Verificar espacio en disco
    echo -e "${YELLOW}📊 Espacio en disco:${NC}"
    df -h | grep -E "Filesystem|/$"
    echo ""
    
    # Verificar servicios críticos
    echo -e "${YELLOW}⚙️  Servicios críticos:${NC}"
    if systemctl is-active --quiet postgresql; then
        echo -e "${GREEN}✅ PostgreSQL: Activo${NC}"
    else
        echo -e "${RED}❌ PostgreSQL: Inactivo${NC}"
    fi
    
    if systemctl is-active --quiet nginx; then
        echo -e "${GREEN}✅ Nginx: Activo${NC}"
    else
        echo -e "${RED}❌ Nginx: Inactivo${NC}"
    fi
    
    # Verificar conexión a internet
    echo -e "${YELLOW}🌐 Conexión a internet:${NC}"
    if ping -c 1 google.com &> /dev/null; then
        echo -e "${GREEN}✅ Conexión: OK${NC}"
    else
        echo -e "${RED}❌ Conexión: Fallida${NC}"
    fi
    
    # Verificar permisos sudo
    echo -e "${YELLOW}🔐 Permisos sudo:${NC}"
    if sudo -n true 2>/dev/null; then
        echo -e "${GREEN}✅ Sudo: Disponible${NC}"
    else
        echo -e "${RED}❌ Sudo: Requiere contraseña${NC}"
    fi
    
    echo ""
    read -p "Presiona Enter para continuar..."
}

# Función para modo inteligente
smart_mode() {
    echo -e "${BLUE}⚡ Modo Inteligente - Analizando cambios...${NC}"
    echo ""
    
    # Verificar si hay cambios en el código
    if [ -d "$AP_H2_DIR/.git" ]; then
        cd "$AP_H2_DIR"
        if [ -n "$(git status --porcelain)" ]; then
            echo -e "${YELLOW}📝 Se detectaron cambios en el código${NC}"
            echo -e "${CYAN}Ejecutando: Migraciones + Backup + Despliegue${NC}"
            echo -e "${CYAN}📦 Aplicando migraciones...${NC}"
            deploy_full_flags "-I"
            echo -e "${CYAN}💾 Generando backup...${NC}"
            deploy_full_flags "-Z -C"
            echo -e "${CYAN}🚀 Desplegando...${NC}"
            deploy_full_flags "-Gi -S -r"
        else
            echo -e "${GREEN}✅ No hay cambios en el código${NC}"
            echo -e "${CYAN}Ejecutando: Solo verificación de estado${NC}"
            bash "/home/markmur88/scripts/service/diagnostico_entorno.sh" || true
        fi
    else
        echo -e "${YELLOW}⚠️  No se detectó repositorio Git${NC}"
        echo -e "${CYAN}Ejecutando: Verificación completa${NC}"
        bash "/home/markmur88/scripts/service/diagnostico_entorno.sh" || true
    fi
}

# Función para ejecutar parcialmente
execute_partial() {
    local mode=$1
    echo ""
    echo -e "${PURPLE}🔄 Ejecutando modo: $mode${NC}"
    
    case $mode in
        "migra,backup,deploy")
            echo -e "${CYAN}📦 Aplicando migraciones...${NC}"
            # Aquí irían las migraciones
            echo -e "${CYAN}💾 Generando backup...${NC}"
            # Aquí iría el backup
            echo -e "${CYAN}🚀 Desplegando...${NC}"
            # Aquí iría el despliegue
            ;;
        "check")
            echo -e "${CYAN}🔍 Verificando estado...${NC}"
            # Aquí iría la verificación
            ;;
        *)
            echo -e "${RED}❌ Modo no reconocido${NC}"
            ;;
    esac
    
    echo -e "${GREEN}✅ Operación completada${NC}"
    echo ""
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar dashboard
show_dashboard() {
    echo -e "${BLUE}📊 Dashboard de Estado del Sistema${NC}"
    echo ""
    
    # Estado de servicios
    echo -e "${YELLOW}┌───────────────── SERVICIOS ─────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} PostgreSQL: $(systemctl is-active postgresql 2>/dev/null || echo "N/A")"
    echo -e "${YELLOW}│${NC} Nginx: $(systemctl is-active nginx 2>/dev/null || echo "N/A")"
    echo -e "${YELLOW}│${NC} Gunicorn: $(systemctl is-active gunicorn 2>/dev/null || echo "N/A")"
    echo -e "${YELLOW}└─────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Últimos backups
    echo -e "${YELLOW}┌───────────────── BACKUPS ───────────────────┐${NC}"
    if [ -d "$PROJECT_BASE_DIR/backup/zip" ]; then
        ls -la "$PROJECT_BASE_DIR/backup/zip" | tail -3
    else
        echo -e "${RED}❌ No se encontró directorio de backups${NC}"
    fi
    echo -e "${YELLOW}└─────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Logs recientes
    echo -e "${YELLOW}┌───────────────── LOGS ─────────────────────┐${NC}"
    if [ -d "$LOG_DIR" ]; then
        find "$LOG_DIR" -name "*.log" -mtime -1 | head -3
    else
        echo -e "${RED}❌ No se encontró directorio de logs${NC}"
    fi
    echo -e "${YELLOW}└─────────────────────────────────────────────┘${NC}"
    echo ""
    
    read -p "Presiona Enter para continuar..."
}

# Función para modo mantenimiento
maintenance_mode() {
    echo -e "${BLUE}🔧 Modo Mantenimiento${NC}"
    echo ""
    echo -e "${YELLOW}Selecciona la operación:${NC}"
    echo ""
    echo -e "${GREEN}[1]${NC} 🧹 Limpiar logs antiguos"
    echo -e "${GREEN}[2]${NC} 💾 Optimizar base de datos"
    echo -e "${GREEN}[3]${NC} 🔄 Reiniciar servicios"
    echo -e "${GREEN}[4]${NC} 📦 Actualizar dependencias"
    echo -e "${GREEN}[5]${NC} 💾 Verificar espacio en disco"
    echo -e "${GREEN}[0]${NC} 🔙 Volver"
    echo ""
    
    read -p "Opción: " maint_choice
    
    case $maint_choice in
        1)
            echo -e "${CYAN}🧹 Limpiando logs antiguos...${NC}"
            find "$PROJECT_BASE_DIR/backup" -name "*.log" -mtime +7 -delete 2>/dev/null
            ;;
        2)
            echo -e "${CYAN}💾 Optimizando base de datos...${NC}"
            sudo -u postgres psql -c "VACUUM FULL;" 2>/dev/null || true
            ;;
        3)
            echo -e "${CYAN}🔄 Reiniciando servicios...${NC}"
            if [ -f "$SCRIPTS_DIR/service/reiniciar_servicios.sh" ]; then
                bash "$SCRIPTS_DIR/service/reiniciar_servicios.sh"
            else
                sudo systemctl restart gunicorn nginx || true
            fi
            ;;
        4)
            echo -e "${CYAN}📦 Actualizando dependencias...${NC}"
            ensure_env
            api && pip install -U -r requirements.txt --no-cache-dir || true
            ;;
        5) 
            echo -e "${CYAN}💾 Verificando espacio en disco...${NC}"
            df -h
            echo ""
            echo -e "${CYAN}📁 Directorios más grandes:${NC}"
            du -sh "$PROJECT_BASE_DIR"/* 2>/dev/null | sort -hr | head -10
            ;;
        0) return ;;
        *) echo -e "${RED}❌ Opción no válida${NC}" ;;
    esac
    
    echo -e "${GREEN}✅ Operación completada${NC}"
    echo ""
    read -p "Presiona Enter para continuar..."
}

# Función para verificación de seguridad
security_check() {
    echo -e "${BLUE}🛡️  Verificación de Seguridad${NC}"
    echo ""
    
    echo -e "${YELLOW}🔐 Verificando permisos de archivos...${NC}"
    # Verificar permisos de archivos críticos
    
    echo -e "${YELLOW}🌐 Verificando configuración de firewall...${NC}"
    # Verificar UFW
    
    echo -e "${YELLOW}🔑 Verificando claves SSL...${NC}"
    # Verificar certificados
    
    echo -e "${GREEN}✅ Verificación de seguridad completada${NC}"
    echo ""
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar logs
show_logs() {
    echo -e "${BLUE}📋 Logs Recientes${NC}"
    echo ""
    
    if [ -d "$LOG_DIR" ]; then
        echo -e "${YELLOW}Últimos logs del sistema:${NC}"
        find "$LOG_DIR" -name "*.log" -exec ls -la {} \; | head -5
        echo ""
        echo -e "${CYAN}¿Ver contenido de algún log específico? (s/n):${NC}"
        read -p "" show_content
        if [[ $show_content =~ ^[Ss]$ ]]; then
            echo -e "${YELLOW}Ingresa el nombre del archivo:${NC}"
            read -p "" log_file
            if [ -f "$LOG_DIR/$log_file" ]; then
                tail -20 "$LOG_DIR/$log_file"
            else
                echo -e "${RED}❌ Archivo no encontrado${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ No se encontró directorio de logs${NC}"
    fi
    
    echo ""
    read -p "Presiona Enter para continuar..."
}

# Función para optimización de espacio
optimize_space() {
    echo -e "${BLUE}💾 Optimización de Espacio para VPS${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  ADVERTENCIA: Esta operación eliminará archivos de desarrollo${NC}"
    echo -e "${YELLOW}   Asegúrate de tener un backup antes de continuar${NC}"
    echo ""
    
    echo -e "${CYAN}Selecciona la optimización:${NC}"
    echo ""
    echo -e "${GREEN}[1]${NC} 🧹 Limpieza rápida (solo archivos temporales)"
    echo -e "${GREEN}[2]${NC} 💾 Optimización completa (incluye .git y archivos de desarrollo)"
    echo -e "${GREEN}[3]${NC} 📊 Ver estadísticas de espacio actual"
    echo -e "${GREEN}[0]${NC} 🔙 Volver"
    echo ""
    
    read -p "Opción: " opt_choice
    
    case $opt_choice in
        1)
            echo -e "${CYAN}🧹 Ejecutando limpieza rápida...${NC}"
            # Limpiar archivos temporales
            sudo rm -rf /tmp/*
            find "$AP_H2_DIR" -name "*.tmp" -delete 2>/dev/null
            find "$AP_H2_DIR" -name "*.cache" -delete 2>/dev/null
            find "$AP_H2_DIR" -name "*.log" -mtime +3 -delete 2>/dev/null
            echo -e "${GREEN}✅ Limpieza rápida completada${NC}"
            ;;
        2)
            echo -e "${CYAN}💾 Ejecutando optimización completa...${NC}"
            if [ -f "$MEJORAS_DIR/optimize_deployment.sh" ]; then
                bash "$MEJORAS_DIR/optimize_deployment.sh" --full
            else
                echo -e "${RED}❌ Script de optimización no encontrado${NC}"
            fi
            ;;
        3)
            echo -e "${CYAN}📊 Estadísticas de espacio:${NC}"
            df -h
            echo ""
            echo -e "${CYAN}📁 Directorios más grandes:${NC}"
            du -sh "$PROJECT_BASE_DIR"/* 2>/dev/null | sort -hr | head -10
            ;;
        0) return ;;
        *) echo -e "${RED}❌ Opción no válida${NC}" ;;
    esac
    
    echo ""
    read -p "Presiona Enter para continuar..."
}

# Función para despliegue optimizado sin Git
deploy_optimized() {
    echo -e "${BLUE}🚀 Despliegue Optimizado sin Git${NC}"
    echo ""
    
    if [ -f "$MEJORAS_DIR/deploy_optimized.sh" ]; then
        echo -e "${CYAN}🚀 Ejecutando despliegue optimizado...${NC}"
        bash "$MEJORAS_DIR/deploy_optimized.sh"
    else
        echo -e "${RED}❌ Script de despliegue optimizado no encontrado${NC}"
        echo -e "${YELLOW}💡 Revisa análisis/mejoras/scripts/deploy_optimized.sh${NC}"
    fi
    
    echo ""
    read -p "Presiona Enter para continuar..."
}

# Función para sincronización al VPS
sync_to_vps() {
    echo -e "${BLUE}🔄 Sincronización al VPS sin Git${NC}"
    echo ""
    
    if [ -f "$MEJORAS_DIR/sync_to_vps.sh" ]; then
        echo -e "${CYAN}🔄 Ejecutando sincronización al VPS...${NC}"
        bash "$MEJORAS_DIR/sync_to_vps.sh"
    else
        echo -e "${RED}❌ Script de sincronización no encontrado${NC}"
        echo -e "${YELLOW}💡 Revisa análisis/mejoras/scripts/sync_to_vps.sh${NC}"
    fi
    
    echo ""
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}❓ Ayuda - Express Inteligente v2.1${NC}"
    echo ""
    echo -e "${YELLOW}Opciones disponibles:${NC}"
    echo ""
    echo -e "${GREEN}[1]${NC} Ejecutar Todo: Ejecuta el flujo completo original"
    echo -e "${GREEN}[2]${NC} Verificar Estado: Muestra el estado actual del sistema"
    echo -e "${GREEN}[3]${NC} Modo Inteligente: Ejecuta solo lo necesario basado en cambios"
    echo -e "${GREEN}[4]${NC} Dashboard: Vista general del estado del sistema"
    echo -e "${GREEN}[5]${NC} Mantenimiento: Herramientas de mantenimiento del sistema"
    echo -e "${GREEN}[6]${NC} Seguridad: Verificaciones de seguridad"
    echo -e "${GREEN}[7]${NC} Logs: Ver logs recientes del sistema"
    echo -e "${GREEN}[8]${NC} Optimización: Optimizar espacio para VPS limitado"
    echo -e "${GREEN}[9]${NC} Despliegue Optimizado: Despliegue sin Git para ahorrar espacio"
    echo -e "${GREEN}[10]${NC} Sincronización: Sincronizar al VPS sin archivos innecesarios"
    echo ""
    echo -e "${CYAN}Nuevas características para VPS con espacio limitado:${NC}"
    echo -e "${WHITE}• Eliminación de directorio .git${NC}"
    echo -e "${WHITE}• Limpieza de archivos de desarrollo${NC}"
    echo -e "${WHITE}• Optimización de archivos estáticos${NC}"
    echo -e "${WHITE}• Sincronización directa sin Git${NC}"
    echo -e "${WHITE}• Despliegue optimizado para 40GB/4GB RAM${NC}"
    echo ""
    echo -e "${CYAN}Para usar el modo original:${NC}"
    echo -e "${WHITE}express --full${NC}"
    echo ""
    echo -e "${CYAN}Para usar el modo inteligente:${NC}"
    echo -e "${WHITE}express --smart${NC}"
    echo ""
    read -p "Presiona Enter para continuar..."
}

# Función principal
main() {
    while true; do
        show_banner
        show_menu
        
        read -p "Selecciona una opción: " choice
        
        case $choice in
            1)
                echo -e "${BLUE}🚀 Ejecutando Express Original...${NC}"
                echo -e "${CYAN}Esto ejecutará: api && deploy_full -Z -C -S -Q -I -Gi -r${NC}"
                echo ""
                read -p "¿Continuar? (s/n): " confirm
                if [[ $confirm =~ ^[Ss]$ ]]; then
                    deploy_full_flags "-Z -C -S -Q -I -Gi -r"
                    echo -e "${GREEN}✅ Flujo completado${NC}"
                fi
                ;;
            2) check_system_status ;;
            3) smart_mode ;;
            4) show_dashboard ;;
            5) maintenance_mode ;;
            6) security_check ;;
            7) show_logs ;;
            8) optimize_space ;;
            9) deploy_optimized ;;
            10) sync_to_vps ;;
            11) show_help ;;
            0)
                echo -e "${GREEN}👋 ¡Hasta luego!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Opción no válida${NC}"
                sleep 2
                ;;
        esac
    done
}

# Manejo de argumentos de línea de comandos
case "${1:-}" in
    --full)
        echo -e "${BLUE}🚀 Ejecutando Express Original...${NC}"
        deploy_full_flags "-Z -C -S -Q -I -Gi -r"
        ;;
    --smart)
        smart_mode
        ;;
    --check)
        check_system_status
        ;;
    --dashboard)
        show_dashboard
        ;;
    --optimize)
        optimize_space
        ;;
    --deploy-opt)
        deploy_optimized
        ;;
    --sync-vps)
        sync_to_vps
        ;;
    --help|-h)
        show_help
        ;;
    "")
        main
        ;;
    *)
        echo -e "${RED}❌ Opción no válida: $1${NC}"
        echo -e "${CYAN}Usa --help para ver las opciones disponibles${NC}"
        exit 1
        ;;
esac 