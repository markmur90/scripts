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

USER="markmur88"
IP="80.78.30.242"

# 1) Verificar que se ejecute exclusivamente como “markmur88”
if [ "$(whoami)" != "markmur88" ]; then
    echo "❌ Este script debe ser ejecutado por el usuario: markmur88"
    exit 1
fi

# 2) Rutas absolutas
HOME_DIR="/home/markmur88"
KEY="/home/markmur88/.ssh/vps_njalla_nueva"
REMOTE_BASE="/home/markmur88"

LOG_DIR="/home/markmur88/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/upload_$(date '+%Y%m%d_%H%M%S').log"

echo "📁 INICIO: Navegación LOCAL para seleccionar carpeta a subir."

# --- NAVEGACIÓN LOCAL ---
current_dir_local="/home/markmur88"
while true; do
    echo
    echo "🗂 Directorio local actual: $current_dir_local"
    echo "   0) [Seleccionar ESTA carpeta: $(basename "$current_dir_local")]"
    idx=1
    if [ "$current_dir_local" != "/home/markmur88" ]; then
        echo "   $idx) ../"
        ((idx++))
    fi
    mapfile -t local_dirs < <(find "$current_dir_local" -maxdepth 1 -mindepth 1 -type d | sort)
    for d in "${local_dirs[@]}"; do
        echo "   $idx) $(basename "$d")/"
        ((idx++))
    done

    read -rp "➡️ Ingresa el número (ej: 0, 1, 2, ...): " choice_local
    if ! [[ "$choice_local" =~ ^[0-9]+$ ]]; then
        echo "❌ Entrada inválida. Debe ser un número."
        continue
    fi
    max_local=$(( idx - 1 ))
    if (( choice_local < 0 || choice_local > max_local )); then
        echo "❌ Número fuera de rango (0 a $max_local)."
        continue
    fi

    if (( choice_local == 0 )); then
        FOLDER_PATH="$current_dir_local"
        break
    fi

    opt_local=0
    if [ "$current_dir_local" != "/home/markmur88" ]; then
        if (( choice_local == 1 )); then
            current_dir_local="$(dirname "$current_dir_local")"
            continue
        else
            opt_local=1
        fi
    fi

    sub_idx_local=$(( choice_local - 1 - opt_local + 1 ))
    real_idx_local=$(( sub_idx_local - 1 ))
    if (( real_idx_local >= 0 && real_idx_local < ${#local_dirs[@]} )); then
        current_dir_local="${local_dirs[$real_idx_local]}"
    else
        echo "❌ Opción no válida."
    fi
done

echo "✅ Carpeta local seleccionada: $FOLDER_PATH"
echo
echo "📁 AHORA: Navegación REMOTA para seleccionar carpeta destino en VPS."

# --- NAVEGACIÓN REMOTA ---
current_dir_remote="$REMOTE_BASE"
while true; do
    echo
    echo "🖧 Directorio remoto actual: $current_dir_remote"
    echo "   0) [Seleccionar ESTE directorio remoto: $(basename "$current_dir_remote")]"
    idx=1
    if [ "$current_dir_remote" != "$REMOTE_BASE" ]; then
        echo "   $idx) ../"
        ((idx++))
    fi
    # Listar subdirectorios en el VPS bajo current_dir_remote
    mapfile -t remote_dirs < <(
        ssh -i "$KEY" -p 22 "$USER@$IP" \
        "cd \"$current_dir_remote\" && \
         find . -maxdepth 1 -mindepth 1 -type d -printf '%P\n' | sort"
    )
    for dname in "${remote_dirs[@]}"; do
        echo "   $idx) ${dname}/"
        ((idx++))
    done

    read -rp "➡️ Ingresa el número (ej: 0, 1, 2, ...): " choice_remote
    if ! [[ "$choice_remote" =~ ^[0-9]+$ ]]; then
        echo "❌ Entrada inválida. Debe ser un número."
        continue
    fi
    max_remote=$(( idx - 1 ))
    if (( choice_remote < 0 || choice_remote > max_remote )); then
        echo "❌ Número fuera de rango (0 a $max_remote)."
        continue
    fi

    if (( choice_remote == 0 )); then
        REMOTE_DEST="$current_dir_remote"
        break
    fi

    opt_remote=0
    if [ "$current_dir_remote" != "$REMOTE_BASE" ]; then
        if (( choice_remote == 1 )); then
            current_dir_remote="$(dirname "$current_dir_remote")"
            continue
        else
            opt_remote=1
        fi
    fi

    sub_idx_remote=$(( choice_remote - 1 - opt_remote + 1 ))
    real_idx_remote=$(( sub_idx_remote - 1 ))
    if (( real_idx_remote >= 0 && real_idx_remote < ${#remote_dirs[@]} )); then
        # Construir nueva ruta remota
        current_dir_remote="$current_dir_remote/${remote_dirs[$real_idx_remote]}"
    else
        echo "❌ Opción no válida."
    fi
done

echo "✅ Carpeta remota seleccionada: $REMOTE_DEST"
echo

# --- EJECUTAR RSYNC para subir ---
{
    echo "=== UPLOAD - $(date) ==="
    echo "🗂 Carpeta local a subir: $FOLDER_PATH"
    echo "➡️ Carpeta remota destino: $REMOTE_DEST"
    rsync -aHvz \
        -e "ssh -i \"$KEY\" -p 22" \
        "$FOLDER_PATH" "$USER@$IP:$REMOTE_DEST"
    echo "✅ Carpeta subida con éxito."
} | tee "$LOG_FILE"
