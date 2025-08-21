#!/bin/bash

# =============================================================================
# VERIFICACIÓN DE SEGURIDAD - Script de Auditoría de Seguridad
# =============================================================================
# Versión: 1.0
# Descripción: Verifica la configuración de seguridad del sistema
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
CERT_DIR="$SCRIPTS_DIR/certs"

# Variables de estado
SECURITY_SCORE=0
TOTAL_CHECKS=0
CRITICAL_ISSUES=0
WARNINGS=0
RECOMMENDATIONS=()

# Función para mostrar resultados
show_security_result() {
    local level=$1
    local message=$2
    local points=$3
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    case $level in
        "CRITICAL")
            echo -e "${RED}🚨 CRÍTICO: $message${NC}"
            CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
            ;;
        "HIGH")
            echo -e "${YELLOW}⚠️  ALTO: $message${NC}"
            WARNINGS=$((WARNINGS + 1))
            SECURITY_SCORE=$((SECURITY_SCORE + points))
            ;;
        "MEDIUM")
            echo -e "${BLUE}ℹ️  MEDIO: $message${NC}"
            SECURITY_SCORE=$((SECURITY_SCORE + points))
            ;;
        "LOW")
            echo -e "${CYAN}💡 BAJO: $message${NC}"
            SECURITY_SCORE=$((SECURITY_SCORE + points))
            ;;
        "PASS")
            echo -e "${GREEN}✅ PASÓ: $message${NC}"
            SECURITY_SCORE=$((SECURITY_SCORE + points))
            ;;
    esac
}

# Función para mostrar banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              VERIFICACIÓN DE SEGURIDAD v1.0                 ║"
    echo "║                Auditoría de Seguridad                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Función para verificar firewall UFW
check_ufw_firewall() {
    echo -e "${BLUE}🛡️  Verificando Firewall UFW...${NC}"
    
    # Verificar si UFW está instalado
    if command -v ufw &> /dev/null; then
        show_security_result "PASS" "UFW está instalado" 10
        
        # Verificar estado de UFW
        if ufw status | grep -q "Status: active"; then
            show_security_result "PASS" "UFW está activo" 15
            
            # Verificar reglas básicas
            if ufw status | grep -q "22/tcp"; then
                show_security_result "PASS" "Puerto SSH (22) configurado" 5
            else
                show_security_result "CRITICAL" "Puerto SSH (22) no configurado - riesgo de bloqueo" 0
            fi
            
            # Verificar puertos abiertos
            OPEN_PORTS=$(ufw status | grep "ALLOW" | wc -l)
            if [[ $OPEN_PORTS -lt 10 ]]; then
                show_security_result "PASS" "Número razonable de puertos abiertos: $OPEN_PORTS" 10
            else
                show_security_result "HIGH" "Muchos puertos abiertos: $OPEN_PORTS" 5
            fi
        else
            show_security_result "CRITICAL" "UFW está inactivo - riesgo de seguridad" 0
        fi
    else
        show_security_result "CRITICAL" "UFW no está instalado" 0
    fi
    echo ""
}

# Función para verificar certificados SSL
check_ssl_certificates() {
    echo -e "${BLUE}🔐 Verificando Certificados SSL...${NC}"
    
    # Verificar directorio de certificados
    if [[ -d "$CERT_DIR" ]]; then
        show_security_result "PASS" "Directorio de certificados encontrado" 5
        
        # Verificar certificados locales
        if [[ -f "$CERT_DIR/00_20_ssl.sh" ]]; then
            show_security_result "PASS" "Script de configuración SSL encontrado" 5
        fi
        
        # Verificar certificados autofirmados
        if [[ -f "$CERT_DIR/00_generar_certificado_local.sh" ]]; then
            show_security_result "PASS" "Script de generación de certificados encontrado" 5
        fi
    else
        show_security_result "HIGH" "Directorio de certificados no encontrado" 0
    fi
    
    # Verificar certificados en uso
    if netstat -tuln | grep ":443 " &> /dev/null; then
        show_security_result "PASS" "Puerto HTTPS (443) en uso" 10
    else
        show_security_result "MEDIUM" "Puerto HTTPS (443) no en uso" 0
    fi
    echo ""
}

# Función para verificar permisos de archivos
check_file_permissions() {
    echo -e "${BLUE}📁 Verificando Permisos de Archivos...${NC}"
    
    # Verificar permisos de archivos críticos
    local critical_files=(
        "$SCRIPTS_DIR/dirs.sh"
        "$SCRIPTS_DIR/menu/aliases_deploy.sh"
        "$HOME/.zshrc"
    )
    
    for file in "${critical_files[@]}"; do
        if [[ -f "$file" ]]; then
            PERMS=$(stat -c "%a" "$file")
            if [[ $PERMS == "644" || $PERMS == "600" ]]; then
                show_security_result "PASS" "Permisos seguros en $(basename "$file"): $PERMS" 5
            else
                show_security_result "HIGH" "Permisos inseguros en $(basename "$file"): $PERMS" 0
            fi
        fi
    done
    
    # Verificar permisos de directorios
    if [[ -d "$SCRIPTS_DIR" ]]; then
        DIR_PERMS=$(stat -c "%a" "$SCRIPTS_DIR")
        if [[ $DIR_PERMS == "755" ]]; then
            show_security_result "PASS" "Permisos de directorio scripts: $DIR_PERMS" 5
        else
            show_security_result "MEDIUM" "Permisos de directorio scripts: $DIR_PERMS" 0
        fi
    fi
    echo ""
}

# Función para verificar configuración de red
check_network_security() {
    echo -e "${BLUE}🌐 Verificando Seguridad de Red...${NC}"
    
    # Verificar puertos abiertos
    OPEN_PORTS=$(netstat -tuln | grep LISTEN | wc -l)
    if [[ $OPEN_PORTS -lt 20 ]]; then
        show_security_result "PASS" "Número razonable de puertos abiertos: $OPEN_PORTS" 10
    else
        show_security_result "HIGH" "Muchos puertos abiertos: $OPEN_PORTS" 5
    fi
    
    # Verificar servicios en puertos críticos
    local critical_ports=(22 80 443 5432 8000)
    for port in "${critical_ports[@]}"; do
        if netstat -tuln | grep ":$port " &> /dev/null; then
            show_security_result "MEDIUM" "Puerto crítico $port está abierto" 0
        else
            show_security_result "PASS" "Puerto crítico $port está cerrado" 5
        fi
    done
    
    # Verificar configuración de red
    if ip route | grep -q "default"; then
        show_security_result "PASS" "Configuración de red básica presente" 5
    else
        show_security_result "HIGH" "Problemas en configuración de red" 0
    fi
    echo ""
}

# Función para verificar configuración de SSH
check_ssh_security() {
    echo -e "${BLUE}🔑 Verificando Seguridad SSH...${NC}"
    
    SSH_CONFIG="/etc/ssh/sshd_config"
    
    if [[ -f "$SSH_CONFIG" ]]; then
        show_security_result "PASS" "Archivo de configuración SSH encontrado" 5
        
        # Verificar configuración de autenticación por contraseña
        if grep -q "^PasswordAuthentication yes" "$SSH_CONFIG"; then
            show_security_result "HIGH" "Autenticación por contraseña habilitada" 0
        else
            show_security_result "PASS" "Autenticación por contraseña deshabilitada" 10
        fi
        
        # Verificar configuración de root login
        if grep -q "^PermitRootLogin yes" "$SSH_CONFIG"; then
            show_security_result "CRITICAL" "Login de root habilitado" 0
        else
            show_security_result "PASS" "Login de root deshabilitado" 10
        fi
        
        # Verificar puerto SSH
        if grep -q "^Port 22" "$SSH_CONFIG"; then
            show_security_result "MEDIUM" "SSH en puerto por defecto (22)" 0
        else
            show_security_result "PASS" "SSH en puerto no estándar" 10
        fi
    else
        show_security_result "HIGH" "Archivo de configuración SSH no encontrado" 0
    fi
    echo ""
}

# Función para verificar actualizaciones de seguridad
check_security_updates() {
    echo -e "${BLUE}🔄 Verificando Actualizaciones de Seguridad...${NC}"
    
    # Verificar si hay actualizaciones pendientes
    if command -v apt-get &> /dev/null; then
        UPDATE_COUNT=$(apt list --upgradable 2>/dev/null | wc -l)
        if [[ $UPDATE_COUNT -lt 10 ]]; then
            show_security_result "PASS" "Pocas actualizaciones pendientes: $UPDATE_COUNT" 10
        else
            show_security_result "HIGH" "Muchas actualizaciones pendientes: $UPDATE_COUNT" 0
        fi
        
        # Verificar actualizaciones de seguridad
        SECURITY_UPDATES=$(apt list --upgradable 2>/dev/null | grep -i security | wc -l)
        if [[ $SECURITY_UPDATES -eq 0 ]]; then
            show_security_result "PASS" "No hay actualizaciones de seguridad pendientes" 10
        else
            show_security_result "HIGH" "Actualizaciones de seguridad pendientes: $SECURITY_UPDATES" 0
        fi
    else
        show_security_result "MEDIUM" "No se pudo verificar actualizaciones" 0
    fi
    echo ""
}

# Función para verificar configuración de Tor
check_tor_configuration() {
    echo -e "${BLUE}🌐 Verificando Configuración Tor...${NC}"
    
    TOR_DIR="$SCRIPTS_DIR/tor"
    
    if [[ -d "$TOR_DIR" ]]; then
        show_security_result "PASS" "Directorio de configuración Tor encontrado" 5
        
        # Verificar archivos de configuración Tor
        if [[ -f "$TOR_DIR/torrc" ]]; then
            show_security_result "PASS" "Archivo de configuración Tor encontrado" 5
        fi
        
        if [[ -f "$TOR_DIR/instalar_tor.sh" ]]; then
            show_security_result "PASS" "Script de instalación Tor encontrado" 5
        fi
        
        # Verificar si Tor está ejecutándose
        if pgrep -x "tor" > /dev/null; then
            show_security_result "PASS" "Servicio Tor está ejecutándose" 10
        else
            show_security_result "MEDIUM" "Servicio Tor no está ejecutándose" 0
        fi
    else
        show_security_result "LOW" "Configuración Tor no encontrada" 0
    fi
    echo ""
}

# Función para verificar logs de seguridad
check_security_logs() {
    echo -e "${BLUE}📋 Verificando Logs de Seguridad...${NC}"
    
    # Verificar logs del sistema
    if [[ -f "/var/log/auth.log" ]]; then
        show_security_result "PASS" "Log de autenticación disponible" 5
        
        # Verificar intentos de acceso recientes
        RECENT_ATTEMPTS=$(tail -100 /var/log/auth.log | grep "Failed password" | wc -l)
        if [[ $RECENT_ATTEMPTS -lt 10 ]]; then
            show_security_result "PASS" "Pocos intentos de acceso fallidos recientes: $RECENT_ATTEMPTS" 5
        else
            show_security_result "HIGH" "Muchos intentos de acceso fallidos: $RECENT_ATTEMPTS" 0
        fi
    else
        show_security_result "MEDIUM" "Log de autenticación no disponible" 0
    fi
    
    # Verificar logs de firewall
    if [[ -f "/var/log/ufw.log" ]]; then
        show_security_result "PASS" "Log de firewall UFW disponible" 5
    else
        show_security_result "MEDIUM" "Log de firewall UFW no disponible" 0
    fi
    echo ""
}

# Función para calcular puntuación de seguridad
calculate_security_score() {
    local max_score=200  # Puntuación máxima posible
    
    if [[ $TOTAL_CHECKS -gt 0 ]]; then
        local percentage=$((SECURITY_SCORE * 100 / max_score))
        
        echo -e "${CYAN}"
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║                    PUNTUACIÓN DE SEGURIDAD                  ║"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        echo ""
        
        echo -e "${WHITE}📊 Estadísticas:${NC}"
        echo -e "   Total de verificaciones: $TOTAL_CHECKS"
        echo -e "   Puntuación obtenida: $SECURITY_SCORE/$max_score"
        echo -e "   Porcentaje de seguridad: ${percentage}%"
        echo -e "   🚨 Problemas críticos: $CRITICAL_ISSUES"
        echo -e "   ⚠️  Advertencias: $WARNINGS"
        echo ""
        
        # Evaluación de seguridad
        if [[ $percentage -ge 90 ]]; then
            echo -e "${GREEN}🛡️  EXCELENTE: Sistema muy seguro${NC}"
        elif [[ $percentage -ge 75 ]]; then
            echo -e "${GREEN}✅ BUENO: Sistema seguro${NC}"
        elif [[ $percentage -ge 60 ]]; then
            echo -e "${YELLOW}⚠️  REGULAR: Necesita mejoras${NC}"
        else
            echo -e "${RED}🚨 CRÍTICO: Sistema inseguro${NC}"
        fi
        echo ""
    fi
}

# Función para generar recomendaciones
generate_recommendations() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    RECOMENDACIONES                           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    if [[ $CRITICAL_ISSUES -gt 0 ]]; then
        echo -e "${RED}🚨 ACCIONES CRÍTICAS REQUERIDAS:${NC}"
        echo -e "   1. Resolver todos los problemas críticos identificados"
        echo -e "   2. Revisar configuración de firewall"
        echo -e "   3. Verificar permisos de archivos críticos"
        echo ""
    fi
    
    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  MEJORAS RECOMENDADAS:${NC}"
        echo -e "   1. Actualizar sistema regularmente"
        echo -e "   2. Configurar monitoreo de logs"
        echo -e "   3. Implementar autenticación de dos factores"
        echo -e "   4. Revisar configuración de servicios"
        echo ""
    fi
    
    echo -e "${CYAN}💡 RECOMENDACIONES GENERALES:${NC}"
    echo -e "   1. Ejecutar auditorías de seguridad regularmente"
    echo -e "   2. Mantener backups actualizados"
    echo -e "   3. Monitorear logs de seguridad"
    echo -e "   4. Actualizar certificados SSL"
    echo -e "   5. Revisar políticas de acceso"
    echo ""
}

# Función principal
main() {
    show_banner
    
    # Ejecutar todas las verificaciones de seguridad
    check_ufw_firewall
    check_ssl_certificates
    check_file_permissions
    check_network_security
    check_ssh_security
    check_security_updates
    check_tor_configuration
    check_security_logs
    
    # Mostrar resultados
    calculate_security_score
    generate_recommendations
    
    # Retornar código de salida apropiado
    if [[ $CRITICAL_ISSUES -gt 0 ]]; then
        echo -e "${RED}❌ Auditoría de seguridad fallida con $CRITICAL_ISSUES problemas críticos${NC}"
        exit 1
    elif [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Auditoría completada con $WARNINGS advertencias${NC}"
        exit 0
    else
        echo -e "${GREEN}✅ Auditoría de seguridad exitosa${NC}"
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
        echo "  1              Problema crítico detectado"
        ;;
    --quick)
        echo -e "${YELLOW}🔍 Ejecutando verificación rápida de seguridad...${NC}"
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