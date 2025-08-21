#!/usr/bin/env bash
# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_BK_DIR="/home/markmur88/api_bank_h2_BK"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
VENV_PATH="/home/markmur88/envSIM"
SCRIPTS_DIR="/home/markmur88/scripts"
BACKU_DIR="$SCRIPTS_DIR/backup"
CERTS_DIR="$SCRIPTS_DIR/certs"
DP_DJ_DIR="$SCRIPTS_DIR/deploy/django"
DP_GH_DIR="$SCRIPTS_DIR/deploy/github"
DP_HK_DIR="$SCRIPTS_DIR/deploy/heroku"
DP_VP_DIR="$SCRIPTS_DIR/deploy/vps"
SERVI_DIR="$SCRIPTS_DIR/service"
SYSTE_DIR="$SCRIPTS_DIR/src"
TORSY_DIR="$SCRIPTS_DIR/tor"
UTILS_DIR="$SCRIPTS_DIR/utils"
CO_SE_DIR="$UTILS_DIR/conexion_segura_db"
UT_GT_DIR="$UTILS_DIR/gestor-tareas"
SM_BK_DIR="$UTILS_DIR/simulator_bank"
TOKEN_DIR="$UTILS_DIR/token"
GT_GE_DIR="$UT_GT_DIR/gestor"
GT_NT_DIR="$UT_GT_DIR/notify"
GE_LG_DIR="$GT_GE_DIR/logs"
GE_SH_DIR="$GT_GE_DIR/scripts"

BASE_DIR="$AP_H2_DIR"

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

PROJECT_DIR="$BASE_DIR"
BACKUP_DIR="$PROJECT_DIR/backup/sql"
LOG_FILE="$SCRIPTS_DIR/.logs/restaurar_local_descifrado.log"

DB_NAME="mydatabase"
DB_USER="markmur88"
KEY_EMAIL="jmoltke@protonmail.com"
GPG_PRIVATE_KEY="$PROJECT_DIR/gpg_keys/jmoltke_private.asc"

CIFRADO="$BACKUP_DIR/backup_local.sql.gpg"
PLANO="$BACKUP_DIR/backup_descifrado.sql"

mkdir -p "$(dirname "$LOG_FILE")"

# 🎯 Validación GPG
if ! gpg --list-secret-keys "$KEY_EMAIL" &>/dev/null; then
  echo "ℹ️ Importando clave privada $KEY_EMAIL..."
  gpg --import "$GPG_PRIVATE_KEY"
fi

{
echo "📅 Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo "📄 Script: $SCRIPT_NAME"
echo "📂 Restaurando desde → $CIFRADO"
echo "════════════════════════════════════════"

# === CONFIGURACIÓN DE BASE DE DATOS LOCAL ===
DB_NAME="mydatabase"
DB_USER="markmur88"
DB_HOST="localhost"
PGPASSFILE="/home/markmur88/.pgpass"
export PGPASSFILE

echo "🔐 ¿Deseás cargar un backup cifrado (.gpg) o sin cifrar (.sql)?"
select opcion in "Cifrado (.gpg)" "Plano (.sql)"; do
    case $REPLY in
        1)
            FILE=$(find ./backup/sql -type f -name "*.sql.gpg" | sort | tail -n 1)
            echo "🔓 Descifrando $FILE..."
            gpg --output /tmp/tmp_decoded.sql --decrypt "$FILE"
            BACKUP_FILE="/tmp/tmp_decoded.sql"
            break
            ;;
        2)
            FILE=$(find ./backup/sql -type f -name "*.sql" | sort | tail -n 1)
            BACKUP_FILE="$FILE"
            break
            ;;
        *)
            echo "❌ Opción inválida. Abortando."
            exit 1
            ;;
    esac
done

echo "📂 Archivo a cargar: $BACKUP_FILE"
echo "🚀 Cargando en PostgreSQL..."
psql -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" < "$BACKUP_FILE"

echo "✅ Carga completada con éxito."

echo -e "\033[1;36m✅ Restauración completada.\033[0m"
} | tee -a "$LOG_FILE"
