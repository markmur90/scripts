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

CACHE_DIR="$SCRIPTS_DIR/cache"
mkdir -p "$CACHE_DIR"
OS="$(uname -s)"

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="$SCRIPTS_DIR/.logs/01_full_deploy/full_deploy.log"
mkdir -p "$(dirname "$LOG_FILE")"

LOG_SISTEMA="$SCRIPTS_DIR/.logs/sistema/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_SISTEMA)"


{
echo ""
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -euo pipefail




cd "$BASE_DIR" || exit 1

if [[ -f "$BASE_DIR/.env" ]]; then
  source "$BASE_DIR/.env"
else
  echo "❌ No se encontró el archivo .env"
  exit 1
fi



if ! command -v macchanger &>/dev/null; then
  echo "Instalando macchanger..." | tee -a "$LOG_SISTEMA"
  sudo apt-get install -y macchanger
fi


# Detectar si estamos en un entorno VPS o local
if ip link show wlan0 &>/dev/null; then
  INTERFAZ="wlan0"
else
  # Detectar primera interfaz válida (excluyendo loopback, docker, bridges)
  INTERFAZ=$(ip link show | awk -F: '$0 !~ "lo|vir|docker|br|^[^0-9]"{print $2}' | head -n1 | xargs)
fi

if ! ip link show "$INTERFAZ" &>/dev/null; then
  echo "❌ No se detectó una interfaz válida para usar." | tee -a "$LOG_SISTEMA"
  exit 1
fi

get_ip_tor() {
  curl -s --socks5 127.0.0.1:9050 https://api.ipify.org || echo "Desconocida"
}

echo "🌐 Obteniendo IP de salida actual por Tor..."
IP_TOR_ANTES=$(get_ip_tor)
echo "$IP_TOR_ANTES" > "$CACHE_DIR/ip_tor_antes.txt"

echo "🛡️  Iniciando configuración avanzada de Tor..."
if ! command -v tor >/dev/null 2>&1; then
  echo "Tor no está instalado. Instalando..."
  sudo apt-get update && sudo apt-get install -y tor || {
    echo "Falló la instalación de Tor"
    exit 1
  }
fi

TOR_PASS="${TOR_PASS:-Ptf8454Jd55}"
HASHED_PASS=$(tor --hash-password "$TOR_PASS" | tail -n 1)

# Asegurar que Tor esté activo ahora y siempre (arranque automático y autoreinicio)
ensure_tor_always_on() {
  local unit=""
  # Preferir explícitamente la unidad con instancia por defecto
  if systemctl list-unit-files | awk '{print $1}' | grep -qx "tor@default.service"; then
    unit="tor@default.service"
  elif systemctl list-unit-files | awk '{print $1}' | grep -qx "tor.service"; then
    unit="tor.service"
  else
    # Último recurso: intentar tor@default aunque no aparezca listado
    unit="tor@default.service"
  fi

  # Solo aplicar drop-in de autoreinicio a unidades nativas (evitar SysV wrapper en tor.service)
  if [ "$unit" = "tor@default.service" ]; then
    sudo mkdir -p "/etc/systemd/system/${unit}.d"
    sudo tee "/etc/systemd/system/${unit}.d/override.conf" >/dev/null <<'EOF'
[Service]
Restart=always
RestartSec=5
EOF
  fi

  sudo systemctl daemon-reload || true

  # Intentar habilitar/arrancar la unidad seleccionada, con fallback
  if ! sudo systemctl enable --now "$unit"; then
    if [ "$unit" = "tor.service" ]; then
      unit="tor@default.service"
    else
      unit="tor.service"
    fi
    # No crear drop-in si caemos a tor.service (posible SysV)
    sudo systemctl daemon-reload || true
    sudo systemctl enable --now "$unit"
  fi

  sleep 2

  if ! systemctl is-active --quiet "$unit"; then
    echo "❌ Tor no arrancó correctamente. Estado:"
    systemctl status "$unit" --no-pager
    exit 1
  fi

  echo "✔️ Tor activo y habilitado en arranque: $unit"
}

ensure_tor_always_on

# Obtener la unidad de Tor a usar (eco de nombre de unidad completa)
get_tor_unit() {
  if systemctl list-unit-files | awk '{print $1}' | grep -qx "tor@default.service"; then
    echo "tor@default.service"
  elif systemctl list-unit-files | awk '{print $1}' | grep -qx "tor.service"; then
    echo "tor.service"
  else
    # Fallback
    echo "tor@default.service"
  fi
}

ensure_torrc_file() {
  local default_torrc="/etc/tor/torrc"
  if [ ! -f "$default_torrc" ]; then
    sudo mkdir -p "/etc/tor"
    sudo tee "$default_torrc" >/dev/null <<EOF
SOCKSPort 9050
ControlPort 9051
CookieAuthentication 0
HashedControlPassword $HASHED_PASS
EOF
  fi
  echo "$default_torrc"
}

TORRC_PATH=""
TOR_PROC=$(pgrep -af -x tor | head -n1 || true)
if [[ -z "$TOR_PROC" ]]; then
  TOR_PROC=$(pgrep -af -x tor.real | head -n1 || true)
fi

if [[ -z "$TOR_PROC" ]]; then
  # Crear torrc por defecto si no existe y arrancar servicio
  TORRC_PATH=$(ensure_torrc_file)
  unit_to_restart=$(get_tor_unit)
  sudo systemctl try-reload-or-restart "$unit_to_restart" || sudo systemctl restart "$unit_to_restart" || true
  sleep 2
  TOR_PROC=$(pgrep -af -x tor | head -n1 || true)
fi

TOR_PID=$(echo "$TOR_PROC" | awk '{print $1}')
if [[ "$TOR_PID" =~ ^[0-9]+$ ]] && [ -r "/proc/$TOR_PID/cmdline" ]; then
  CMDLINE=$(tr '\0' ' ' < "/proc/$TOR_PID/cmdline")
else
  CMDLINE="$TOR_PROC"
fi

GET_NEXT=0
for token in $CMDLINE; do
  case "$token" in
    --torrc-file=*)
      TORRC_PATH="${token#*=}"; break ;;
    -f)
      GET_NEXT=1 ;;
    -f*)
      TORRC_PATH="${token#-f}"; break ;;
    *)
      if [ "$GET_NEXT" -eq 1 ]; then TORRC_PATH="$token"; break; fi ;;
  esac
done

if [ -z "$TORRC_PATH" ] || [[ "$TORRC_PATH" == -* ]]; then
  if [ -f "/etc/tor/torrc" ]; then
    TORRC_PATH="/etc/tor/torrc"
  elif [ -f "/usr/local/etc/tor/torrc" ]; then
    TORRC_PATH="/usr/local/etc/tor/torrc"
  else
    # Crear uno por defecto
    TORRC_PATH=$(ensure_torrc_file)
  fi
  echo "Tor usa archivo de configuración por defecto: $TORRC_PATH"
else
  echo "Tor usa archivo de configuración personalizado: $TORRC_PATH"
fi

[ -f "$TORRC_PATH" ] || { echo "❌ No existe $TORRC_PATH"; exit 1; }
sudo cp "$TORRC_PATH" "${TORRC_PATH}.bak_$(date +%Y%m%d_%H%M%S)"

replace_or_add_line() {
  local file="$1"
  local directive="$2"
  local value="$3"
  if sudo grep -q "^$directive" "$file"; then
    sudo sed -i "s|^$directive.*|$directive $value|" "$file"
  else
    echo "$directive $value" | sudo tee -a "$file" > /dev/null
  fi
}

replace_or_add_line "$TORRC_PATH" "ControlPort" "9051"
replace_or_add_line "$TORRC_PATH" "CookieAuthentication" "0"
replace_or_add_line "$TORRC_PATH" "HashedControlPassword" "$HASHED_PASS"

ensure_tor_always_on

# Reiniciar Tor para aplicar cambios de torrc en la unidad correcta
unit_to_restart=$(get_tor_unit)
sudo systemctl try-reload-or-restart "$unit_to_restart" || sudo systemctl restart "$unit_to_restart"
sleep 2

echo "🔑 Autenticando con ControlPort..."
# Asegurar netcat disponible para conectar al ControlPort
if ! command -v nc >/dev/null 2>&1; then
  sudo apt-get update && sudo apt-get install -y netcat-openbsd || true
fi
AUTH_CMD=$(printf 'AUTHENTICATE "%s"\r\nSIGNAL NEWNYM\r\nQUIT\r\n' "$TOR_PASS")
CHECK=$(echo -e "$AUTH_CMD" | nc 127.0.0.1 9051 || true)

if ! echo "$CHECK" | grep -q "250 OK"; then
  echo "❌ Error autenticando con Tor ControlPort:"
  echo "$CHECK" | tee -a "$LOG_SISTEMA"
  exit 1
fi

sleep 5
IP_TOR_DESPUES=$(get_ip_tor)
echo "$IP_TOR_DESPUES" > "$CACHE_DIR/ip_tor_despues.txt"

echo -e "\n\033[7;30m🔁 Cambiando MAC de la interfaz $INTERFAZ\033[0m" | tee -a "$LOG_SISTEMA"

sudo ip link set "$INTERFAZ" up
sleep 2

MAC_ANTERIOR=$(sudo macchanger -s "$INTERFAZ" | awk '/Current MAC:/ {print $3}')
IP_ANTERIOR=$(ip -4 addr show "$INTERFAZ" | awk '/inet / {print $2}' | cut -d/ -f1)
echo "$MAC_ANTERIOR" > "$CACHE_DIR/mac_antes.txt"
echo "$IP_ANTERIOR"  > "$CACHE_DIR/ip_antes.txt"

sudo dhclient -r "$INTERFAZ" >> "$LOG_SISTEMA" 2>&1
sudo ip link set "$INTERFAZ" down

MAC_NUEVA=$(sudo macchanger -r "$INTERFAZ" | awk '/New MAC:/ {print $3}')
sudo ip link set "$INTERFAZ" up
sleep 2

renovar_ip() {
  local intento=$1
  sudo HOSTNAME="ghost-$(tr -dc a-z0-9 </dev/urandom | head -c6)" dhclient -v "$INTERFAZ" >> "$LOG_SISTEMA" 2>&1
  sleep 4
  IP_ACTUAL=$(ip -4 addr show "$INTERFAZ" | awk '/inet / {print $2}' | cut -d/ -f1)
  echo "$IP_ACTUAL" > "$CACHE_DIR/ip_actual.txt"
}

renovar_ip 1

if [ "$IP_ACTUAL" = "$IP_ANTERIOR" ]; then
  echo "⚠ IP no ha cambiado tras el primer intento. Reintentando..." | tee -a "$LOG_SISTEMA"
  sudo ip link set "$INTERFAZ" down
  MAC_NUEVA=$(sudo macchanger -r "$INTERFAZ" | awk '/New MAC:/ {print $3}')
  sudo ip link set "$INTERFAZ" up
  renovar_ip 2
fi

FECHA="$(date '+%Y-%m-%d %H:%M:%S')"
{
  echo ""
  echo "========================================="
  echo "📅 Fecha           : $FECHA"
  echo "🛰️ Interfaz        : $INTERFAZ"
  echo "🧭 MAC anterior    : $MAC_ANTERIOR"
  echo "✨ MAC actual      : $MAC_NUEVA"
  echo "🧭 IP anterior     : $IP_ANTERIOR"
  echo "🛰️ IP actual       : $IP_ACTUAL"
  echo "🧭 IP Tor anterior : $IP_TOR_ANTES"
  echo "🛰️ IP Tor actual   : $IP_TOR_DESPUES"
  echo "========================================="
} | tee -a "$LOG_SISTEMA"

echo "✔️ Cambios de red y anonimato completados con éxito."

