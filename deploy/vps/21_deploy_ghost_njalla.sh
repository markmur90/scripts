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

# === Configuración local ===
DIR_LOCAL="/home/markmur88/api_bank_h2"
BACKUP_DIR="/home/markmur88/backup"
source "$DIR_LOCAL/.env.production"

LOG_FILE="$DIR_LOCAL/logs/master_run.log"
PASSPHRASE="${PASSPHRASE:-"##_//Ptf8454Jd55\\_##"}"
DATE="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="$BACKUP_DIR/api_bank_h2_backup_$DATE.tar.gz"
ENC_BACKUP_FILE="$BACKUP_FILE.enc"

echo -e "\033[1;36m🚀 Subiendo api_bank_h2 al VPS...\033[0m"

# === Empaquetar y cifrar backup ===
tar czf "$BACKUP_FILE" -C "$DIR_LOCAL" .
echo -e "\033[1;33m🔐 Cifrando backup antes de subir...\033[0m"
openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$PASSPHRASE" -in "$BACKUP_FILE" -out "$ENC_BACKUP_FILE"

# === Transferencia segura ===
echo -e "\033[1;34m📤 Transferencia cifrada vía rsync+ssh...\033[0m"
rsync -avz -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=yes" "$ENC_BACKUP_FILE" "root@$VPS_IP:$VPS_API_DIR/"
ENC_REMOTE_FILE="$VPS_API_DIR/$(basename "$ENC_BACKUP_FILE")"
echo -e "\033[1;32m📦 Backup cifrado transferido\033[0m"

# === Preparar usuario remoto ===
echo -e "\033[1;36m👤 Preparando usuario y entorno remoto...\033[0m"
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=yes root@$VPS_IP bash <<EOF
set -e
if ! id "markmur88" &>/dev/null; then
    echo "➕ Creando usuario 'markmur88' con sudo..."
    adduser --disabled-password --gecos "" markmur88
    usermod -aG sudo markmur88
    mkdir -p /home/markmur88/api_bank_h2
    chown -R markmur88:www-data /home/markmur88/api_bank_h2
    echo "✅ Usuario y directorio creados."
else
    echo "✅ Usuario 'markmur88' ya existe."
fi
EOF

# === Despliegue final ===
echo -e "\033[1;36m⚙️ Desencriptando y desplegando como markmur88...\033[0m"
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=yes markmur88@$VPS_IP bash <<EOF
set -e
export PASSPHRASE="${PASSPHRASE}"
cd "$VPS_API_DIR"

# Desencriptar y extraer
openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"\$PASSPHRASE" -in "$ENC_REMOTE_FILE" -out api_bank_h2_backup.tar.gz
tar xzf api_bank_h2_backup.tar.gz
rm -f api_bank_h2_backup.tar.gz "$ENC_REMOTE_FILE"

# Entorno virtual
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
if [[ ! -f "requirements.txt" ]]; then
    echo "❌ requirements.txt no encontrado"
    exit 1
fi
pip install -r requirements.txt

# Configuración Gunicorn
mkdir -p "$VPS_API_DIR/servers/gunicorn"

cat > "$VPS_API_DIR/servers/gunicorn/gunicorn.socket" <<EOL
[Unit]
Description=Gunicorn Socket for api_bank_h2
PartOf=gunicorn.service

[Socket]
ListenStream=$VPS_API_DIR/servers/gunicorn/api.sock
SocketMode=0660
SocketUser=www-data
SocketGroup=www-data

[Install]
WantedBy=sockets.target
EOL

cat > "$VPS_API_DIR/servers/gunicorn/gunicorn.service" <<EOL
[Unit]
Description=Gunicorn Daemon for api_bank_h2
Requires=gunicorn.socket
After=network.target

[Service]
User=markmur88
Group=www-data
WorkingDirectory=$VPS_API_DIR
Environment="PATH=$VPS_API_DIR/venv/bin"
ExecStart=$VPS_API_DIR/venv/bin/gunicorn \\
          --access-logfile - \\
          --workers 3 \\
          --bind unix:$VPS_API_DIR/servers/gunicorn/api.sock \\
          config.wsgi:application

[Install]
WantedBy=multi-user.target
EOL

sudo cp "$VPS_API_DIR/servers/gunicorn/gunicorn."* /etc/systemd/system/
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now gunicorn.socket
sudo systemctl start gunicorn.service

# Configuración HTTPS con redirección desde HTTP
sudo rm -f /etc/nginx/sites-enabled/api_bank_h2
sudo tee /etc/nginx/sites-available/api.coretransapi.com > /dev/null <<EOL
server {
    listen 80;
    server_name api.coretransapi.com;

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name api.coretransapi.com;

    ssl_certificate /etc/letsencrypt/live/api.coretransapi.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.coretransapi.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://unix:$VPS_API_DIR/servers/gunicorn/api.sock;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
    }
}
EOL

sudo ln -sf /etc/nginx/sites-available/api.coretransapi.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Permisos reforzados post-deploy
chmod 600 .env || true
chmod 700 venv || true
chmod 660 servers/gunicorn/api.sock || true
EOF

echo -e "\033[1;32m✅ Deploy api_bank_h2 en VPS completado.\033[0m"
