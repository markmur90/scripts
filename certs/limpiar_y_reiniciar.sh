#!/usr/bin/env bash
set -euo pipefail

AP_H2_DIR="/home/markmur88/api_bank_h2"
VENV_PATH="/home/markmur88/envSIM"

echo "�� Limpiando procesos y archivos antiguos..."

# Terminar procesos Gunicorn
pkill -f gunicorn || true
sleep 2

# Limpiar archivos PID y sockets
rm -f "$AP_H2_DIR/gunicorn.pid"
rm -f "$AP_H2_DIR/servers/gunicorn/api.sock"
rm -f "$AP_H2_DIR/api.sock"

# Limpiar puertos
sudo fuser -k 8443/tcp || true
sudo fuser -k 8000/tcp || true

echo "✅ Limpieza completada"
echo "🚀 Ejecutando script SSL local..."
bash "$(dirname "$0")/00_21_local_ssl.sh"