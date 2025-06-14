#!/usr/bin/env bash
# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_BK_DIR="/home/markmur88/api_bank_h2_BK"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
VENV_PATH="/home/markmur88/envAPP"
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

# Variables
VPS_USER="markmur88"
VPS_IP="80.78.30.242"
VPS_PORT="22"
SSH_KEY="/home/markmur88/.ssh/vps_njalla_nueva"
DEST_DIR="$AP_H2_DIR/scripts/vps_backup"

mkdir -p "$DEST_DIR"

# Archivos a copiar
declare -A FILES_VPS=(
  [nginx_coretransapi.conf]="/etc/nginx/sites-available/coretransapi.conf"
  [supervisor_coretransapi.conf]="/etc/supervisor/conf.d/coretransapi.conf"
  [torrc]="/etc/tor/torrc"
)

echo "📥 Copiando archivos desde VPS..."

for fname in "${!FILES_VPS[@]}"; do
  scp -i "$SSH_KEY" -P "$VPS_PORT" "$VPS_USER@$VPS_IP:${FILES_VPS[$fname]}" "$DEST_DIR/$fname"
  echo "✅ $fname copiado a $DEST_DIR"
done

echo -e "\n🎉 Todos los archivos fueron sincronizados correctamente."
