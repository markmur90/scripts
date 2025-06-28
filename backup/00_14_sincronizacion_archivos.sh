#!/usr/bin/env bash
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
SCRIPTS_DIR="/home/markmur88/scripts"
BASE_DIR="$AP_H2_DIR"
HEROKU_ROOT="$AP_HK_DIR"
NJALLA_ROOT="/home/markmur88/heroku"
SCRIPT_NAME="$(basename "$0")"
LOG_FILE="$SCRIPTS_DIR/.logs/01_full_deploy/full_deploy.log"
LOG_DEPLOY="$SCRIPTS_DIR/.logs/despliegue/${SCRIPT_NAME%.sh}_.log"
mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$LOG_DEPLOY")"
{
  echo
  echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
  echo -e "📄 Script: $SCRIPT_NAME"
  echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"
trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR
set -euo pipefail
EXCLUDES=(
  "--exclude=*.zip"
  "--exclude=*.bk"
  "--exclude=*.pyc"
  "--exclude=*.pyo"
  "--exclude=*.pyc"
  "--exclude=migrations/*"
  "--exclude=__pycache__/"
  "--exclude=*.txt"
  "--exclude=*.sand"
  "--exclude=*_old*"
  "--exclude=/media/claves"
  "--exclude=READMEcopy.md"
  "--exclude=*.db"
  "--exclude=*.sqlite3"
  # "--exclude=.env"
  # "--exclude=*.env*.*"
  "--exclude=.vscode/"
  "--exclude=package.json"
  "--exclude=package-lock.json"
  "--exclude=/node_modules/"
  "--exclude=/venv/"
  "--exclude=*old.py"
  "--exclude=* copy*"
  "--exclude=/tmp/"
  "--exclude=/logs/"
  "--exclude=/.github/"
  "--exclude=/.git/"
  "--exclude=prompts.txt"
  "--exclude=templates/api/"
  "--exclude=temp/"
  "--exclude=servers/"
  "--exclude=certs/"
  "--exclude=.devcontainer/"
  "--exclude=.codesandbox/"
  "--exclude=env.txt"
  "--exclude=datos_sensibles.txt"
  "--exclude=chmod_log.txt"
  "--exclude=chatgpt.md"
  "--exclude=01_full0.sh"
  "--exclude=upload_env_to_postgres.sh"
  "--exclude=restore_and_upload.sh"
  "--exclude=Problema.md"
  "--exclude=pendientes.txt"
  "--exclude=z_njalla/"
)
actualizar_django_env() {
  local destino="$1"
  echo "🧾 Ajustando DJANGO_ENV en $destino"
  python3 <<EOF | tee -a "$LOG_DEPLOY"
import os
settings = os.path.join("$destino","config","settings","__init__.py")
if os.path.exists(settings):
    lines = open(settings,encoding="utf-8").read().splitlines()
    out=[];updated=False
    for l in lines:
        if "DJANGO_ENV" in l and "'local'" in l:
            out.append(l.replace("'local'","'production'"));updated=True
        else:
            out.append(l)
    if updated:
        open(settings,"w",encoding="utf-8").write("\n".join(out))
        print("✅ DJANGO_ENV actualizado a 'production'.")
    else:
        print("⚠️ Ningún DJANGO_ENV='local' encontrado.")
else:
    print("⚠️ __init__.py no existe.")
EOF
}
sync_local_project() {
  local name="$1" dest="$2"
  # echo -e "\033[7;30m🔄 [$name] Limpiando $dest\033[0m"
  # sudo rm -rf "$dest"/.[!.]* "$dest"/* 2>/dev/null
  echo -e "\033[7;30m🔄 [$name] Rsync a $dest\033[0m"
  rsync -av "${EXCLUDES[@]}" "$BASE_DIR/" "$dest/" | tee -a "$LOG_FILE"
  cd "$dest"
  actualizar_django_env "$dest"
  cd "$BASE_DIR"
  echo -e "\033[7;94m----------------------------------------\033[0m"
}
PROJECT_NAMES=("HEROKU" "NJALLA")
PROJECT_DESTINATIONS=("$HEROKU_ROOT" "$NJALLA_ROOT")
for i in "${!PROJECT_NAMES[@]}"; do
  sync_local_project "${PROJECT_NAMES[i]}" "${PROJECT_DESTINATIONS[i]}"
done
