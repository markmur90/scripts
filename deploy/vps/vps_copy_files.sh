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

set -euo pipefail

USER="markmur88"
IP="80.78.30.242"
HOME_DIR="/home/$USER"
KEY="$HOME_DIR/.ssh/vps_njalla_nueva"
REMOTE_BASE="$HOME_DIR/"
LOG_DIR="$HOME_DIR/transfer_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/download_$(date '+%Y%m%d_%H%M%S').log"

# 1) Verificar usuario
if [ "$(whoami)" != "$USER" ]; then
    echo "❌ Este script debe ejecutarse como $USER"
    exit 1
fi

echo "📁 INICIO: Selecciona ORIGEN en VPS ($IP)."

# --- NAVEGACIÓN REMOTA ---
current_dir_remote="$REMOTE_BASE"
while true; do
    echo
    echo "🖧 Remoto: $current_dir_remote"
    echo "   0) [Elegir ESTE: $(basename "${current_dir_remote%/}")]"
    idx=1
    if [ "$current_dir_remote" != "$REMOTE_BASE" ]; then
        echo "   $idx) ../"
        ((idx++))
    fi

    # Listar archivos y directorios remotos
    mapfile -t remote_entries < <(
        ssh -i "$KEY" -p 22 "$USER@$IP" \
            "cd \"${current_dir_remote%/}\" && \
             find . -maxdepth 1 -mindepth 1 -printf '%P|%y\n' | sort"
    )
    remote_items=()
    remote_types=()
    for entry in "${remote_entries[@]}"; do
        IFS='|' read -r name type <<< "$entry"
        remote_items+=("$name")
        remote_types+=("$type")
        if [ "$type" = "d" ]; then
            echo "   $idx) ${name}/"
        else
            echo "   $idx) ${name}"
        fi
        ((idx++))
    done

    read -rp "➡ Número: " choice
    [[ "$choice" =~ ^[0-9]+$ ]] || { echo "   ❌ Debe ser número"; continue; }
    (( choice > idx-1 )) && { echo "   ❌ Fuera de rango"; continue; }

    if (( choice == 0 )); then
        REMOTE_SOURCE="${current_dir_remote%/}"
        break
    fi

    # Si elige "../"
    if [ "$current_dir_remote" != "$REMOTE_BASE" ] && (( choice == 1 )); then
        current_dir_remote="$(dirname "${current_dir_remote%/}")/"
        continue
    fi

    # Calcular selección (ajustando offset sin aritmética de cadenas)
    if [ "$current_dir_remote" != "$REMOTE_BASE" ]; then
        offset=2
    else
        offset=1
    fi
    sel=$(( choice - offset ))
    sel_name="${remote_items[$sel]}"
    sel_type="${remote_types[$sel]}"

    if [ "$sel_type" = "d" ]; then
        # Navegar dentro
        current_dir_remote="${current_dir_remote%/}/$sel_name/"
    else
        # Archivo: lo elegimos y salimos
        REMOTE_SOURCE="${current_dir_remote%/}/$sel_name"
        break
    fi
done

echo "✅ Origen remoto: $REMOTE_SOURCE"
echo
echo "📁 Selecciona DESTINO local."

# --- NAVEGACIÓN LOCAL (solo directorios) ---
current_dir_local="$HOME_DIR"
while true; do
    echo
    echo "🗂 Local: $current_dir_local"
    echo "   0) [Elegir ESTE: $(basename "$current_dir_local")]"
    idx=1
    if [ "$current_dir_local" != "$HOME_DIR" ]; then
        echo "   $idx) ../"
        ((idx++))
    fi

    mapfile -t local_dirs < <(find "$current_dir_local" -maxdepth 1 -mindepth 1 -type d | sort)
    for d in "${local_dirs[@]}"; do
        echo "   $idx) $(basename "$d")/"
        ((idx++))
    done

    read -rp "➡ Número: " choice
    [[ "$choice" =~ ^[0-9]+$ ]] || { echo "   ❌ Debe ser número"; continue; }
    (( choice > idx-1 )) && { echo "   ❌ Fuera de rango"; continue; }

    if (( choice == 0 )); then
        LOCAL_DEST="$current_dir_local"
        break
    fi

    if [ "$current_dir_local" != "$HOME_DIR" ] && (( choice == 1 )); then
        current_dir_local="$(dirname "$current_dir_local")"
        continue
    fi

    # Offset para selección local
    if [ "$current_dir_local" != "$HOME_DIR" ]; then
        offset=2
    else
        offset=1
    fi
    sel=$(( choice - offset ))
    current_dir_local="${local_dirs[$sel]}"
done

echo "✅ Destino local: $LOCAL_DEST"
echo
echo "🚀 Iniciando transferencia..."

{
    echo "=== DOWNLOAD $(date '+%Y-%m-%d %H:%M:%S') ==="
    echo " Origen remoto: $REMOTE_SOURCE"
    echo " Destino local: $LOCAL_DEST"
    rsync -aHvz \
        -e "ssh -i \"$KEY\" -p 22" \
        "$USER@$IP:$REMOTE_SOURCE" "$LOCAL_DEST"
    echo "✅ Transferencia completada."
} | tee "$LOG_FILE"
