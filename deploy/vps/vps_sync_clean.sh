#!/usr/bin/env bash

# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
BACKUPDIR="/home/markmur88/backup"
BANK_GHOST="/home/markmur88/bank_ghost"
VENV_PATH="/home/markmur88/envSIM"
SCRIPTS_DIR="/home/markmur88/scripts"
DP_VP_DIR="$SCRIPTS_DIR/deploy/vps"
BASE_DIR="$AP_H2_DIR"
VPS_BASE_DIR="/home/markmur88/api_bank_h2"
VPS_VENV_PATH="/home/markmur88/envSIM"
VPS_CORETRANS_ROOT="/home/markmur88/coretransapi"

EXCLUDES="/home/markmur88/scripts/deploy/vps/excludes.txt"
LOG_DIR="$SCRIPTS_DIR/.logs/sync"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y%m%d_%H%M%S)_sync_clean.log"

# === SELECCIÓN INTERACTIVA DE SINCRONIZACIÓN ===
declare -A OPCIONES=(
  [1]="$AP_H2_DIR"
  [2]="$AP_HK_DIR"
  [3]="$BACKUPDIR"
)

if [[ "$#" -gt 0 && "$1" =~ ^-[0-5]$ ]]; then
  SELECCION="${1:1}"
else
  echo "¿Qué querés sincronizar?"
  echo "1) API Bank H2"
  echo "2) API Bank Heroku"
  echo "3) Backups"
  echo "5) TODAS"
  echo "0) Cancelar"
  read -p "Ingresá los números separados por coma (ej: 1,3): " SELECCION
fi

if [[ "$SELECCION" == "0" ]]; then
  echo "🚫 Cancelado."
  exit 0
fi

SINCRONIZAR=()

if [[ "$SELECCION" == *5* ]]; then
  SINCRONIZAR=("${OPCIONES[@]}")
else
  IFS=',' read -ra INDICES <<< "$SELECCION"
  for i in "${INDICES[@]}"; do
    if [[ -n "${OPCIONES[$i]}" ]]; then
      SINCRONIZAR+=("${OPCIONES[$i]}")
    fi
  done
fi

set -euo pipefail

# Validación de usuario
if [[ "$EUID" -eq 0 && "$SUDO_USER" != "markmur88" ]]; then
  echo "⚠️ No ejecutar como root. Cambiando a usuario markmur88..."
  exec sudo -u markmur88 "$0" "$@"
  exit 0
fi

# Crear carpetas remotas si no existen
for DIR in "$AP_H2_DIR" "$AP_HK_DIR" "$BACKUPDIR" "$BANK_GHOST"; do
  ssh -i "$SSH_KEY" -p "$VPS_PORT" "markmur88@$VPS_IP" "mkdir -p $DIR"
done

# === FUNCION PARA LIMPIEZA DE EXCLUSIONES ===
limpiar_patrones() {
  REMOTE_DIR=$1
  echo "🧹 Limpiando en VPS ($REMOTE_DIR) archivos excluidos..." | tee -a "$LOG_FILE"
  while IFS= read -r pattern; do
    [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
    echo "🗑 Eliminando: $pattern" | tee -a "$LOG_FILE"

    if [[ "$pattern" == */ ]]; then
      ssh -i "$SSH_KEY" -p "$VPS_PORT" "markmur88@$VPS_IP" \
        "find $REMOTE_DIR -type d -name '${pattern%/}' -exec rm -rf {} +" >> "$LOG_FILE" 2>&1
    elif [[ "$pattern" == *\** ]]; then
      ssh -i "$SSH_KEY" -p "$VPS_PORT" "markmur88@$VPS_IP" \
        "find $REMOTE_DIR -type f -name '$pattern' -exec rm -f {} +" >> "$LOG_FILE" 2>&1
    else
      ssh -i "$SSH_KEY" -p "$VPS_PORT" "markmur88@$VPS_IP" \
        "find $REMOTE_DIR -name '$pattern' -exec rm -f {} +" >> "$LOG_FILE" 2>&1
    fi
  done < "$EXCLUDES"
}


echo "🔥 Eliminando contenido de carpetas remotas..." | tee -a "$LOG_FILE"
for dir in "${SINCRONIZAR[@]}"; do
  echo "🧨 Borrando contenido de $dir en VPS" | tee -a "$LOG_FILE"
  ssh -i "$SSH_KEY" -p "$VPS_PORT" "markmur88@$VPS_IP" "rm -rf $dir/* $dir/.* 2>/dev/null || true"
done

# === LIMPIEZA Y SYNC ===



echo "🔄 Ejecutando sincronización según selección..." | tee -a "$LOG_FILE"
for dir in "${SINCRONIZAR[@]}"; do
  case "$dir" in
    "$AP_H2_DIR")
      echo "🔄 Sincronizando proyecto hacia API Bank H2 (sin exclusiones)..." | tee -a "$LOG_FILE"
      rsync -avz --delete \
        -e "ssh -i $SSH_KEY -p $VPS_PORT" \
        "$BASE_DIR/" "markmur88@$VPS_IP:$AP_H2_DIR/" \
        | tee -a "$LOG_FILE"
      ;;
    "$AP_HK_DIR")
      echo "🔄 Sincronizando proyecto hacia API Bank Heroku (con exclusiones)..." | tee -a "$LOG_FILE"
      rsync -avz --delete \
        --exclude-from="$EXCLUDES" \
        -e "ssh -i $SSH_KEY -p $VPS_PORT" \
        "$BASE_DIR/" "markmur88@$VPS_IP:$AP_HK_DIR/" \
        | tee -a "$LOG_FILE"
      limpiar_patrones "$AP_HK_DIR"
      ;;

    "$BACKUPDIR")
      echo "🔄 Sincronizando solo el último archivo de backup..." | tee -a "$LOG_FILE"
      
      ULTIMO_BACKUP=$(find "$BACKUPDIR" -type f -printf "%T@ %p\n" | sort -n | tail -1 | cut -d' ' -f2-)
      echo "📁 Último archivo de backup: $ULTIMO_BACKUP" | tee -a "$LOG_FILE"

      echo "🧨 Limpiando backups previos en VPS..." | tee -a "$LOG_FILE"
      ssh -i "$SSH_KEY" -p "$VPS_PORT" "markmur88@$VPS_IP" "rm -f $BACKUPDIR/*" >> "$LOG_FILE" 2>&1

      rsync -avz \
        -e "ssh -i $SSH_KEY -p $VPS_PORT" \
        "$ULTIMO_BACKUP" "markmur88@$VPS_IP:$BACKUPDIR/" \
        | tee -a "$LOG_FILE"
      ;;



  esac
done

echo "📡 Ejecutando comandos remotos en el VPS..." | tee -a "$LOG_FILE"
ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" << EOF | tee -a "$LOG_FILE"
  set -euo pipefail

  echo "🌐 Entrando en directorio remoto: /home/markmur88/api_bank_h2"
  cd "/home/markmur88/api_bank_h2"

  echo "🔧 Activando entorno virtual en VPS: /home/markmur88/api_bank_h2"
  source "/home/markmur88/envSIM/bin/activate"

  # echo "🔁 Ejecutando script 01_full.sh en VPS"
  # bash /home/markmur88/scripts/menu/01_full.sh -Q -I -l

  echo "🔁 Reiniciando servicios en VPS..."

  if sudo supervisorctl status | grep -q '^coretransapi'; then
      sudo supervisorctl restart coretransapi
      echo "📋 Estado del servicio coretransapi en VPS:"
      sudo supervisorctl status coretransapi
      echo "📄 Últimos logs de error en VPS:"
      tail -n 10 /var/log/supervisor/coretransapi.err.log
  else
      echo "⚠️ Servicio 'coretransapi' no está registrado en supervisor. Saltando reinicio..."
  fi

  # Instalar nginx
sudo apt update && sudo apt install nginx -y

# Iniciar y habilitar
sudo systemctl start nginx
sudo systemctl enable nginx
  echo "✅ Comandos remotos completados."

EOF




echo "✅ Sincronización completada." | tee -a "$LOG_FILE"
