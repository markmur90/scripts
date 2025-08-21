#!/usr/bin/env bash
# Configura PostgreSQL, usuario y base de datos

set -euo pipefail

# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
VENV_PATH="/home/markmur88/envSIM"
SCRIPTS_DIR="/home/markmur88/scripts"
BASE_DIR="$AP_H2_DIR"
LOG_DEPLOY="$SCRIPTS_DIR/.logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname "$LOG_DEPLOY")"

# Logging inicial
{
echo ""
echo "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo "📄 Script: $(basename "$0")"
echo "═══════════════════════════════════════════"
} | tee -a "$LOG_DEPLOY"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando." | tee -a "$LOG_DEPLOY"; exit 1' ERR

# 🔍 Verificar e instalar PostgreSQL si falta
echo "🔍 Verificando PostgreSQL..." | tee -a "$LOG_DEPLOY"

if ! command -v psql &>/dev/null; then
    echo "⚠️ PostgreSQL no encontrado. Instalando..." | tee -a "$LOG_DEPLOY"
    OS="$(uname -s)"
    if [[ "$OS" == "Linux" ]]; then
        sudo apt update && sudo apt install -y postgresql postgresql-contrib
    elif [[ "$OS" == "Darwin" ]]; then
        brew update && brew install postgresql
    else
        echo "❌ OS no compatible"
        exit 1
    fi
    echo "♻️ PostgreSQL instalado. Reiniciando script..." | tee -a "$LOG_DEPLOY"
    exec "$0" "$@"
fi

sudo systemctl enable postgresql
sudo systemctl start postgresql

# 🧠 Identificar servicio PostgreSQL y asegurarse que esté activo
OS="$(uname -s)"
if [[ "$OS" == "Linux" ]]; then
    PG_SERVICE=$(systemctl list-unit-files --type=service | grep -E '^postgresql.*\.service' | awk '{print $1}' | head -n1)
    if [[ -z "$PG_SERVICE" ]]; then
        echo "❌ No se detectó un servicio PostgreSQL válido" | tee -a "$LOG_DEPLOY"
        exit 1
    fi
    if ! systemctl is-active --quiet "$PG_SERVICE"; then
        echo "🔌 Iniciando PostgreSQL..." | tee -a "$LOG_DEPLOY"
        sudo systemctl enable "$PG_SERVICE"
        sudo systemctl start "$PG_SERVICE"
    fi
elif [[ "$OS" == "Darwin" ]]; then
    brew services start postgresql
fi

# 🐍 Crear entorno virtual y dependencias
# python3 -m venv "$VENV_PATH"
source "$VENV_PATH/bin/activate"
pip install --upgrade pip
echo "📦 Instalando dependencias..." | tee -a "$LOG_DEPLOY"
pip install -r "$BASE_DIR/requirements.txt"

# === CREDENCIALES ===
DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
DB_HOST="localhost"

export DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:5432/${DB_NAME}"

# 🗝️ Crear ~/.pgpass para no pedir contraseña
echo "${DB_HOST}:5432:*:${DB_USER}:${DB_PASS}" > "/home/${DB_USER}/.pgpass"
chmod 600 "/home/${DB_USER}/.pgpass"
chown ${DB_USER}:${DB_USER} "/home/${DB_USER}/.pgpass"

# 🧑‍🔧 Crear usuario si no existe
sudo -u postgres psql <<-EOF
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}') THEN
        CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';
    END IF;
END
\$\$;
ALTER USER ${DB_USER} WITH SUPERUSER;
GRANT ALL PRIVILEGES ON SCHEMA public TO ${DB_USER};
EOF

# 💣 Si existe, eliminar BDD
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" | grep -q 1; then
    echo "⚠️ Borrando base de datos existente: ${DB_NAME}" | tee -a $LOG_DEPLOY
    sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME}';"
    sudo -u postgres psql -c "DROP DATABASE ${DB_NAME};"
fi

# 🆕 Crear nueva BDD
sudo -u postgres psql <<-EOF
CREATE DATABASE ${DB_NAME};
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
EOF

echo -e "\033[7;30m✅ Base de datos y usuario listos.\033[0m" | tee -a $LOG_DEPLOY

# chmodtree
cd $AP_H2_DIR

# Ejecutar solo la restauración de BD (crear script temporal)
echo "🔧 Ejecutando restauración corregida de BD..."

# Crear script temporal que solo restaura BD sin variables
cat > temp_restore_only.sh << 'RESTORE_SCRIPT'
#!/usr/bin/env bash
DB_USER="markmur88"
DB_PASSWORD="Ptf8454Jd55"
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="mydatabase"
BACKUP_FILE="backup_local.sql"

# Exporta la contraseña para que los comandos no la pidan
export PGPASSWORD="$DB_PASSWORD"

echo "--- PASO 1: RESTAURANDO LA BASE DE DATOS DESDE '$BACKUP_FILE' ---"
echo "Cerrando todas las conexiones existentes a la base de datos '$DB_NAME'..."
psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "postgres" -c "
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE datname = '$DB_NAME' AND pid <> pg_backend_pid();"

echo "Eliminando la base de datos antigua '$DB_NAME' (si existe)..."
psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "postgres" -c "DROP DATABASE IF EXISTS $DB_NAME;"

echo "Creando una base de datos limpia '$DB_NAME'..."
psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "postgres" -c "CREATE DATABASE $DB_NAME;"

echo "Restaurando la base de datos..."
psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" < "$BACKUP_FILE"

echo "✅ Restauración completada."
RESTORE_SCRIPT

chmod +x temp_restore_only.sh
bash temp_restore_only.sh
rm temp_restore_only.sh

# Ejecutar migraciones para crear tablas faltantes (como configuraciones_api)
echo "🔄 Ejecutando migraciones Django..."
source $VENV_PATH/bin/activate
python manage.py migrate --skip-checks

# Ejecutar importación de variables .env usando el script Python
echo "📝 Subiendo variables desde archivos .env..."
if [ -f "importar_env_a_db.py" ]; then
    if [ -f ".env.local" ]; then
        echo "Procesando archivo: '.env.local' para el entorno: 'local'"
        python importar_env_a_db.py .env.local local
    fi
    if [ -f ".env.production" ]; then
        echo "Procesando archivo: '.env.production' para el entorno: 'production'"
        python importar_env_a_db.py .env.production production
    fi
    if [ -f ".env.sandbox" ]; then
        echo "Procesando archivo: '.env.sandbox' para el entorno: 'sandbox'"
        python importar_env_a_db.py .env.sandbox sandbox
    fi
else
    echo "⚠️ Archivo importar_env_a_db.py no encontrado, copiando desde scripts..."
    cp /home/markmur88/scripts/importar_env_a_db.py .
    if [ -f ".env.local" ]; then
        python importar_env_a_db.py .env.local local
    fi
fi

echo "✅ Proceso PostgreSQL completado exitosamente!"

cd $AP_HK_DIR


