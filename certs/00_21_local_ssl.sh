#!/usr/bin/env bash
set -euo pipefail

# === VARIABLES DE PROYECTO ===
AP_HK_DIR="/home/markmur88/api_bank_heroku"
AP_H2_DIR="/home/markmur88/api_bank_h2"
VENV_PATH="/home/markmur88/envAPP"
SCRIPTS_DIR="/home/markmur88/scripts"
LOG_DIR="$SCRIPTS_DIR/.logs/despliegue"
LOG_DEPLOY="$LOG_DIR/00_21_local_ssl.log"

CERT_DIR="/home/markmur88/scripts/schemas/certs"
CERT_CRT="$CERT_DIR/desarrollo.crt"
CERT_KEY="$CERT_DIR/desarrollo.key"

# Crear directorios de logs
mkdir -p "$LOG_DIR"

# Cabecera de log
printf "\n📅 Fecha de ejecución: %s\n📄 Script: %s\n" \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$(basename "$0")" \
    | tee -a "$LOG_DEPLOY"

# Trap de errores (solo en Bash)
if [ -n "${BASH_VERSION-}" ]; then
    trap 'printf "\n❌ Error en línea %s: \"%s\"\nAbortando ejecución.\n" "$LINENO" "$BASH_COMMAND" \
            | tee -a "$LOG_DEPLOY"; exit 1' ERR
fi

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

# Arrancar Gunicorn (SSL o solo HTTP según disponibilidad de puerto 8443)
if sudo lsof -i :8443 | grep -q LISTEN; then
    printf "🧅 Puerto 8443 en uso. Ejecutando Gunicorn en 0.0.0.0:8000...\n" \
        | tee -a "$LOG_DEPLOY"
    if sudo lsof -i :8000 | grep -q LISTEN; then
        printf "⚠️ Puerto 8000 en uso. Liberando...\n" | tee -a "$LOG_DEPLOY"
        sudo fuser -k 8000/tcp
        sleep 2
    fi
    nohup "$VENV_PATH/bin/gunicorn" \
        config.wsgi:application \
        --bind 0.0.0.0:8000 \
        > "$LOG_DEPLOY" 2>&1 &
    printf "🚀 Gunicorn arrancado en http://0.0.0.0:8000\n" | tee -a "$LOG_DEPLOY"
else
    printf "🌐 Levantando Gunicorn con SSL en https://0.0.0.0:8443\n🔐 Cert: %s\n" \
        "$CERT_CRT" | tee -a "$LOG_DEPLOY"
    nohup "$VENV_PATH/bin/gunicorn" \
        config.wsgi:application \
        --certfile="$CERT_CRT" \
        --keyfile="$CERT_KEY" \
        --bind 0.0.0.0:8443 \
        > "$LOG_DEPLOY" 2>&1 &
    printf "🚀 Gunicorn SSL arrancado.\n" | tee -a "$LOG_DEPLOY"
fi

# Entrega en pantalla la solución
printf "\n✅ Despliegue completado sin errores.\n" | tee -a "$LOG_DEPLOY"
