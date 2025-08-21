#!/usr/bin/env bash
set -euo pipefail

# === VARIABLES DE PROYECTO ===
AP_HK_DIR="/home/markmur88/api_bank_heroku"
AP_H2_DIR="/home/markmur88/api_bank_h2"
VENV_PATH="/home/markmur88/envSIM"
SCRIPTS_DIR="/home/markmur88/scripts"
LOG_DIR="$SCRIPTS_DIR/.logs/despliegue"
LOG_DEPLOY="$LOG_DIR/00_21_local_ssl.log"

CERT_DIR="/home/markmur88/scripts/schemas/certs"
CERT_CRT="$CERT_DIR/desarrollo.crt"
CERT_KEY="$CERT_DIR/desarrollo.key"

# Variables para gestión de procesos
GUNICORN_PID_FILE="$AP_H2_DIR/gunicorn.pid"
GUNICORN_LOG_FILE="$AP_H2_DIR/logs/gunicorn_access.log"
GUNICORN_ERROR_LOG="$AP_H2_DIR/logs/gunicorn_error.log"

# Crear directorios de logs
mkdir -p "$LOG_DIR"
mkdir -p "$(dirname "$GUNICORN_LOG_FILE")"

# Cabecera de log
printf "\n�� Fecha de ejecución: %s\n📄 Script: %s\n" \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$(basename "$0")" \
    | tee -a "$LOG_DEPLOY"

# Trap de errores (solo en Bash)
if [ -n "${BASH_VERSION-}" ]; then
    trap 'printf "\n❌ Error en línea %s: \"%s\"\nAbortando ejecución.\n" "$LINENO" "$BASH_COMMAND" \
            | tee -a "$LOG_DEPLOY"; cleanup_processes; exit 1' ERR
    trap 'cleanup_processes' EXIT
fi

# === FUNCIONES DE GESTIÓN DE PROCESOS ===

# Función para verificar si Gunicorn está ejecutándose
check_gunicorn_running() {
    local port="$1"
    local pid_file="$2"
    
    # Verificar por PID file
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file" 2>/dev/null)
        if [[ -n "$pid" && -d "/proc/$pid" ]]; then
            printf "✅ Gunicorn ejecutándose con PID: %s\n" "$pid" | tee -a "$LOG_DEPLOY"
            return 0
        else
            printf "⚠️ PID file encontrado pero proceso no activo. Limpiando...\n" | tee -a "$LOG_DEPLOY"
            rm -f "$pid_file"
        fi
    fi
    
    # Verificar por puerto
    if sudo lsof -i ":$port" | grep -q LISTEN; then
        printf "⚠️ Puerto %s en uso. Verificando procesos...\n" "$port" | tee -a "$LOG_DEPLOY"
        return 0
    fi
    
    return 1
}

# Función para terminar procesos Gunicorn
terminate_gunicorn() {
    local port="$1"
    local pid_file="$2"
    
    printf "🛑 Terminando procesos Gunicorn...\n" | tee -a "$LOG_DEPLOY"
    
    # Terminar por PID file
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file" 2>/dev/null)
        if [[ -n "$pid" ]]; then
            printf "�� Terminando proceso PID: %s\n" "$pid" | tee -a "$LOG_DEPLOY"
            kill -TERM "$pid" 2>/dev/null || true
            sleep 2
            if kill -0 "$pid" 2>/dev/null; then
                printf "⚠️ Proceso %s no terminó. Forzando...\n" "$pid" | tee -a "$LOG_DEPLOY"
                kill -KILL "$pid" 2>/dev/null || true
            fi
        fi
        rm -f "$pid_file"
    fi
    
    # Terminar procesos por puerto
    local port_pids=$(sudo lsof -ti ":$port" 2>/dev/null || true)
    if [[ -n "$port_pids" ]]; then
        printf "🔌 Terminando procesos en puerto %s: %s\n" "$port" "$port_pids" | tee -a "$LOG_DEPLOY"
        echo "$port_pids" | xargs -r kill -TERM
        sleep 3
        # Forzar terminación si es necesario
        local remaining_pids=$(sudo lsof -ti ":$port" 2>/dev/null || true)
        if [[ -n "$remaining_pids" ]]; then
            printf "⚠️ Forzando terminación de procesos restantes: %s\n" "$remaining_pids" | tee -a "$LOG_DEPLOY"
            echo "$remaining_pids" | xargs -r kill -KILL
        fi
    fi
    
    # Terminar procesos Gunicorn por nombre
    local gunicorn_pids=$(pgrep -f "gunicorn.*config.wsgi" 2>/dev/null || true)
    if [[ -n "$gunicorn_pids" ]]; then
        printf "🔍 Terminando procesos Gunicorn por nombre: %s\n" "$gunicorn_pids" | tee -a "$LOG_DEPLOY"
        echo "$gunicorn_pids" | xargs -r kill -TERM
        sleep 2
        # Verificar si quedan procesos
        local remaining_gunicorn=$(pgrep -f "gunicorn.*config.wsgi" 2>/dev/null || true)
        if [[ -n "$remaining_gunicorn" ]]; then
            printf "⚠️ Forzando terminación de Gunicorn restantes: %s\n" "$remaining_gunicorn" | tee -a "$LOG_DEPLOY"
            echo "$remaining_gunicorn" | xargs -r kill -KILL
        fi
    fi
    
    # Esperar a que el puerto esté libre
    local attempts=0
    while sudo lsof -i ":$port" | grep -q LISTEN && [[ $attempts -lt 10 ]]; do
        printf "⏳ Esperando liberación del puerto %s... (intento %d/10)\n" "$port" $((attempts + 1)) | tee -a "$LOG_DEPLOY"
        sleep 1
        ((attempts++))
    done
    
    if sudo lsof -i ":$port" | grep -q LISTEN; then
        printf "❌ No se pudo liberar el puerto %s después de 10 intentos\n" "$port" | tee -a "$LOG_DEPLOY"
        return 1
    else
        printf "✅ Puerto %s liberado exitosamente\n" "$port" | tee -a "$LOG_DEPLOY"
    fi
}

# Función de limpieza
cleanup_processes() {
    printf "🧹 Ejecutando limpieza de procesos...\n" | tee -a "$LOG_DEPLOY"
    terminate_gunicorn 8000 "$GUNICORN_PID_FILE"
    terminate_gunicorn 8443 "$GUNICORN_PID_FILE"
}

# Función para iniciar Gunicorn con gestión de PID
start_gunicorn() {
    local port="$1"
    local ssl_cert="$2"
    local ssl_key="$3"
    local pid_file="$4"
    
    printf "�� Iniciando Gunicorn en puerto %s...\n" "$port" | tee -a "$LOG_DEPLOY"
    
    # Comando base de Gunicorn
    local gunicorn_cmd="$VENV_PATH/bin/gunicorn"
    local gunicorn_args="config.wsgi:application --bind 0.0.0.0:$port --pid $pid_file"
    
    # Agregar configuración SSL si se proporciona
    if [[ -n "$ssl_cert" && -n "$ssl_key" ]]; then
        gunicorn_args="$gunicorn_args --certfile=$ssl_cert --keyfile=$ssl_key"
        printf "🔐 Configuración SSL activada\n" | tee -a "$LOG_DEPLOY"
    fi
    
    # Agregar configuración de workers optimizada
    gunicorn_args="$gunicorn_args --workers 4 --timeout 30 --max-requests 1000 --max-requests-jitter 50"
    
    # Agregar logging
    gunicorn_args="$gunicorn_args --access-logfile $GUNICORN_LOG_FILE --error-logfile $GUNICORN_ERROR_LOG --log-level info"
    
    # Ejecutar Gunicorn
    printf "📋 Comando: %s %s\n" "$gunicorn_cmd" "$gunicorn_args" | tee -a "$LOG_DEPLOY"
    
    cd "$AP_H2_DIR"
    nohup $gunicorn_cmd $gunicorn_args > "$LOG_DEPLOY" 2>&1 &
    local gunicorn_pid=$!
    
    # Esperar a que el proceso se inicie
    sleep 3
    
    # Verificar que el proceso esté ejecutándose
    if [[ -f "$pid_file" ]]; then
        local actual_pid=$(cat "$pid_file")
        printf "✅ Gunicorn iniciado exitosamente con PID: %s\n" "$actual_pid" | tee -a "$LOG_DEPLOY"
        printf "🌐 Servidor disponible en: %s://0.0.0.0:%s\n" \
            "$([ -n "$ssl_cert" ] && echo "https" || echo "http")" "$port" | tee -a "$LOG_DEPLOY"
        return 0
    else
        printf "❌ Error: Gunicorn no se inició correctamente\n" | tee -a "$LOG_DEPLOY"
        return 1
    fi
}

# === EJECUCIÓN PRINCIPAL ===

# Activar virtualenv
printf "🔐 Activando entorno virtual...\n" | tee -a "$LOG_DEPLOY"
source "$VENV_PATH/bin/activate"

# Migraciones y archivos estáticos
printf "🛠️ Aplicando migraciones y collectstatic...\n" | tee -a "$LOG_DEPLOY"
cd "$AP_H2_DIR"
python3 manage.py makemigrations \
    && python3 manage.py migrate \
    && python3 manage.py collectstatic --noinput \
    | tee -a "$LOG_DEPLOY"

# Generar certificados si faltan
if [[ ! -f "$CERT_CRT" || ! -f "$CERT_KEY" ]]; then
    printf "⚠️ Certificados no encontrados. Generando en %s...\n" "$CERT_DIR" \
        | tee -a "$LOG_DEPLOY"
    mkdir -p "$CERT_DIR"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_KEY" \
        -out "$CERT_CRT" \
        -subj "/C=ES/ST=Madrid/L=Madrid/O=Local Dev/OU=Dev/CN=0.0.0.0"
    printf "✅ Certificados generados.\n" | tee -a "$LOG_DEPLOY"
fi

# Verificar y limpiar procesos existentes
printf "🔍 Verificando procesos existentes...\n" | tee -a "$LOG_DEPLOY"

# Verificar puerto 8443 (SSL)
if check_gunicorn_running 8443 "$GUNICORN_PID_FILE"; then
    printf "�� Puerto 8443 en uso. Terminando procesos existentes...\n" | tee -a "$LOG_DEPLOY"
    terminate_gunicorn 8443 "$GUNICORN_PID_FILE"
fi

# Verificar puerto 8000 (HTTP)
if check_gunicorn_running 8000 "$GUNICORN_PID_FILE"; then
    printf "⚠️ Puerto 8000 en uso. Terminando procesos existentes...\n" | tee -a "$LOG_DEPLOY"
    terminate_gunicorn 8000 "$GUNICORN_PID_FILE"
fi

# Iniciar Gunicorn según disponibilidad de puertos
if ! sudo lsof -i :8443 | grep -q LISTEN; then
    printf "�� Iniciando Gunicorn con SSL en puerto 8443...\n" | tee -a "$LOG_DEPLOY"
    if start_gunicorn 8443 "$CERT_CRT" "$CERT_KEY" "$GUNICORN_PID_FILE"; then
        printf "�� Gunicorn SSL iniciado exitosamente en https://0.0.0.0:8443\n" | tee -a "$LOG_DEPLOY"
    else
        printf "❌ Error al iniciar Gunicorn SSL. Intentando puerto 8000...\n" | tee -a "$LOG_DEPLOY"
        terminate_gunicorn 8443 "$GUNICORN_PID_FILE"
        if start_gunicorn 8000 "" "" "$GUNICORN_PID_FILE"; then
            printf "🚀 Gunicorn HTTP iniciado exitosamente en http://0.0.0.0:8000\n" | tee -a "$LOG_DEPLOY"
        else
            printf "❌ Error crítico: No se pudo iniciar Gunicorn en ningún puerto\n" | tee -a "$LOG_DEPLOY"
            exit 1
        fi
    fi
else
    printf "🌐 Puerto 8443 ocupado. Iniciando Gunicorn HTTP en puerto 8000...\n" | tee -a "$LOG_DEPLOY"
    if start_gunicorn 8000 "" "" "$GUNICORN_PID_FILE"; then
        printf "🚀 Gunicorn HTTP iniciado exitosamente en http://0.0.0.0:8000\n" | tee -a "$LOG_DEPLOY"
    else
        printf "❌ Error crítico: No se pudo iniciar Gunicorn\n" | tee -a "$LOG_DEPLOY"
        exit 1
    fi
fi

# Mostrar estado final
printf "\n📊 Estado final del servidor:\n" | tee -a "$LOG_DEPLOY"
if [[ -f "$GUNICORN_PID_FILE" ]]; then
    final_pid=$(cat "$GUNICORN_PID_FILE")  # Removido 'local'
    printf "✅ Gunicorn ejecutándose con PID: %s\n" "$final_pid" | tee -a "$LOG_DEPLOY"
    printf "�� PID file: %s\n" "$GUNICORN_PID_FILE" | tee -a "$LOG_DEPLOY"
    printf "📋 Logs: %s\n" "$GUNICORN_LOG_FILE" | tee -a "$LOG_DEPLOY"
fi

printf "\n✅ Despliegue completado sin errores.\n" | tee -a "$LOG_DEPLOY"
printf "🎯 Servidor listo para desarrollo local.\n" | tee -a "$LOG_DEPLOY"