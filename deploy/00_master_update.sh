#!/usr/bin/env zsh
set -euo pipefail
# Habilitar aliases si se ejecuta con bash (evita 'orden no encontrada')
if [ -n "$BASH_VERSION" ]; then
  shopt -s expand_aliases
fi

AP_H2_DIR="/home/markmur88/api_bank_h2"
SIMU_PATH="/home/markmur88/envSIM"

alias envSIM="source $SIMU_PATH/bin/activate"
alias api="source ~/.zshrc && cd $AP_H2_DIR && envSIM"
alias deploy_full='bash "/home/markmur88/scripts/menu/01_full.sh"'

alias express='api && deploy_full -Z -C -S -Q -I -Gi -r'
alias vps_l_user='api && ssh -t -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" "clear; ls; exec \$SHELL -l"'

# Carpetas objetivo
CARPETAS=("api_bank_h2" "api_bank_heroku" "scripts")

# Rutas base (misma ruta local-remota). Puedes pasar BASE_LOCAL y BASE_REMOTA por variables de entorno si difieren.
BASE_LOCAL="${BASE_LOCAL:-$HOME}"
BASE_REMOTA="${BASE_REMOTA:-$HOME}"

echo "Base local:  $BASE_LOCAL"
echo "Base remota: $BASE_REMOTA"
echo "Carpetas: ${CARPETAS[*]}"
read -r -p "¿Continuar con la actualización? [y/N] " CONFIRM

if [[ "${CONFIRM,,}" != "y" ]]; then
    echo "Cancelado."
    exit 1
fi

# 1) Eliminar carpetas en el VPS
echo "Eliminando carpetas en el VPS..."
ssh -i /home/markmur88/.ssh/vps_njalla_nueva markmur88@80.78.30.242  "rm -rf ${BASE_REMOTA}/api_bank_h2 ${BASE_REMOTA}/api_bank_heroku ${BASE_REMOTA}/scripts || true"

# 2) Eliminar datos locales de api_bank_heroku
echo "Eliminando en local: ${BASE_LOCAL}/api_bank_heroku ..."
rm -rf "${BASE_LOCAL}/api_bank_heroku" || true

# 3) Ejecutar deploy_full -S en local
echo "Ejecutando deploy_full -S en local..."
AP_H2_DIR="/home/markmur88/api_bank_h2"
SIMU_PATH="/home/markmur88/envSIM"
alias envSIM="source $SIMU_PATH/bin/activate"
alias api='cd "$AP_H2_DIR" && source "$SIMU_PATH/bin/activate"'
alias deploy_full='bash "/home/markmur88/scripts/menu/01_full.sh"'

deploy_full -S

# 4) Copiar carpetas de local a servidor (misma ruta) con vps_sync_dir
echo "Sincronizando carpetas al VPS..."
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
AP_SM_DIR="/home/markmur88/Simulador"
AP_SC_DIR="/home/markmur88/scripts"
VENV_PATH="/home/markmur88/envSIM"
SCRIPTS_DIR="/home/markmur88/scripts"
EXCLUDES="$SCRIPTS_DIR/deploy/vps/excludes.txt"
VPS_USER="markmur88"
VPS_IP="80.78.30.242"
VPS_PORT="22"
SSH_KEY="/home/markmur88/.ssh/vps_njalla_nueva"
VPS_BASE_DIR="/home/markmur88/api_bank_h2"
VPS_HK_DIR="/home/markmur88/api_bank_heroku"
VPS_SM_DIR="/home/markmur88/Simulador"
VPS_SC_DIR="/home/markmur88/scripts"
VPS_VENV_PATH="/home/markmur88/envSIM"
LOG_DIR="$SCRIPTS_DIR/.logs/sync"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y%m%d_%H%M%S)_sync.log"
SUDOPWD="Ptf8454Jd55"
set -euo pipefail
SUDOPWD="Ptf8454Jd55"

sync_project() {
  local name="$1" local local_dir="$2" local remote_dir="$3"
  echo "🆕 [$name] Proyecto local: $local_dir" | tee -a "$LOG_FILE"
  echo "🧹 [$name] Eliminando patrones excluidos en VPS..." | tee -a "$LOG_FILE"
  while IFS= read -r pattern; do
    [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
    echo "🗑 [$name] Borrando: $pattern" | tee -a "$LOG_FILE"
    ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" "rm -rf '$remote_dir/$pattern'" >>"$LOG_FILE" 2>&1
  done <"$EXCLUDES"
  echo "🔄 [$name] Iniciando rsync local→VPS..." | tee -a "$LOG_FILE"
  rsync -avz --delete \
    --exclude-from="$EXCLUDES" \
    -e "ssh -i $SSH_KEY -p $VPS_PORT" \
    "$local_dir/" "$VPS_USER@$VPS_IP:$remote_dir" \
    | tee -a "$LOG_FILE"
  echo "✅ [$name] Sincronización completada." | tee -a "$LOG_FILE"
}

sync_project "H2" "$AP_H2_DIR" "$VPS_BASE_DIR"
sync_project "HK" "$AP_HK_DIR" "$VPS_HK_DIR"
sync_project "SC" "$AP_SC_DIR" "$VPS_SC_DIR"

# 5) Ejecutar 'express && express' en el VPS
echo "Reiniciando servicio Express en el VPS..."
AP_H2_DIR="/home/markmur88/api_bank_h2"
SIMU_PATH="/home/markmur88/envSIM"
alias envSIM="source $SIMU_PATH/bin/activate"
alias api='cd "$AP_H2_DIR" && source "$SIMU_PATH/bin/activate"'
alias deploy_full='bash "/home/markmur88/scripts/menu/01_full.sh"'
alias express='api && deploy_full -Z -C -S -Q -I -Gi -r'

express && express


echo "Actualización completada."