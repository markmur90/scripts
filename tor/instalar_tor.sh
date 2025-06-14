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

echo "🔧 Instalando Tor y configurando relay + servicio oculto..."

# Instalación
sudo apt-get update && sudo apt-get install -y tor

# Copiar configuración segura

sudo cp "$TORSY_DIR/torrc" /etc/tor/torrc

# Asegurar permisos
sudo chown -R markmur88 /var/lib/tor/hidden_service
sudo chmod 700 /var/lib/tor/hidden_service
sleep 5

# Reiniciar servicio
sudo systemctl enable tor
sleep 5

sudo systemctl restart tor
sleep 5

# Esperar que genere el hostname
echo "⌛ Esperando generación del servicio oculto..."
sleep 10

if [ -f /var/lib/tor/hidden_service/hostname ]; then
    echo "🧅 Dirección onion generada:"
    sudo cat /var/lib/tor/hidden_service/hostname
else
    echo "⚠️ Aún no se ha generado el hostname. Espera unos segundos y revisa con:"
    echo "   sudo cat /var/lib/tor/hidden_service/hostname"
fi
