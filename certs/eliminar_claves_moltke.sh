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
LOG_FILE="$SCRIPTS_DIR/.logs/01_full_deploy/full_deploy.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

#!/bin/bash

set -e

EMAIL="j.moltke@db.com"
CLAVE_SALIDA="bar1588623"

echo "🔍 Buscando huellas digitales asociadas a: $EMAIL"

# Buscar huellas de claves privadas
FPRIVS=$(gpg --list-secret-keys --with-colons "$EMAIL" | awk -F: '/^fpr:/ {print $10}')

# Eliminar claves privadas (por fingerprint)
for fpr in $FPRIVS; do
    echo "🔒 Eliminando clave secreta $fpr"
    gpg --batch --yes --delete-secret-key "$fpr"
done

# Buscar huellas de claves públicas
FPUBS=$(gpg --list-keys --with-colons "$EMAIL" | awk -F: '/^fpr:/ {print $10}')

# Eliminar claves públicas (por fingerprint)
for fpr in $FPUBS; do
    echo "📬 Eliminando clave pública $fpr"
    gpg --batch --yes --delete-key "$fpr"
done

# Borrar archivos exportados
echo "🧹 Eliminando archivos exportados..."
rm -f "$CLAVE_SALIDA"_public.asc
rm -f "$CLAVE_SALIDA"_private.asc
rm -f "$CLAVE_SALIDA"_private.asc.gpg

echo "✅ Todas las claves y archivos relacionados con '$EMAIL' han sido eliminados por completo."
