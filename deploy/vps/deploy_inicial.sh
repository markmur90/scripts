#!/usr/bin/env bash
set -e -x

# === Variables de configuración ===
IP_VPS="80.78.30.242"
PORT_VPS="22"
SSH_KEY="/home/markmur88/.ssh/vps_njalla_nueva"
REMOTE_USER="root"
APP_USER="markmur88"
APP_PASSWD="Ptf8454Jd55"
REPO_DIR="api_bank_h2"
DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
EMAIL_SSL="netghostx90@protonmail.com"

# === Carpetas locales a copiar ===
LOCAL_API_BANK_H2="/home/markmur88/api_bank_h2"
LOCAL_API_BANK_HEROKU="/home/markmur88/api_bank_heroku"
LOCAL_SCRIPTS="/home/markmur88/scripts"
LOCAL_SIMULADOR="/home/markmur88/Simulador"

echo " Conectando a VPS $IP_VPS como root..."

# Limpiar huella SSH si es necesario
ssh-keygen -f "/home/markmur88/.ssh/known_hosts" -R "$IP_VPS" 2>/dev/null || true

# FASE 1: Configuración del sistema como root
echo "📦 Fase 1: Configuración del sistema como root..."
ssh -i "$SSH_KEY" -p "$PORT_VPS" "$REMOTE_USER@$IP_VPS" bash -s <<EOF
set -e

APP_USER="$APP_USER"
APP_PASSWD="$APP_PASSWD"

echo "🧱 Instalando dependencias del sistema..."
apt-get update
apt-get full-upgrade -y
apt-get autoremove -y
apt-get clean

apt-get install -y \\
    zsh git curl build-essential tor ufw fail2ban \\
    python3 python3-pip python3-venv python3-dev libpq-dev \\
    postgresql postgresql-contrib nginx certbot python3-certbot-nginx supervisor \\
    libcairo2 libpango1.0-0 libpangoft2-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 \\
    libffi-dev shared-mime-info libjpeg-dev zlib1g-dev libxml2 libxml2-dev libxslt1-dev \\
    rsync python3-psycopg2 python3-dev python3-psycopg2-binary python3-psycopg2-binary \\
    unzip htop python3-gunicorn tor

echo "👤 Configurando usuario $APP_USER con todos los permisos..."
# Crear usuario si no existe
if ! id "\$APP_USER" &>/dev/null; then
    echo " Creando usuario \$APP_USER..."
    useradd -m -s /bin/bash "\$APP_USER"
    echo "\$APP_USER:\$APP_PASSWD" | chpasswd
    
    # Función para agregar usuario a grupo solo si existe
    add_to_group() {
        if getent group "\$1" >/dev/null 2>&1; then
            usermod -aG "\$1" "\$APP_USER"
            echo "   ✅ Agregado a grupo \$1"
        else
            echo "   ⚠️ Grupo \$1 no existe - omitiendo"
        fi
    }
    
    # Agregar a todos los grupos importantes (solo si existen)
    echo "   🔍 Verificando grupos disponibles..."
    add_to_group sudo
    add_to_group www-data
    add_to_group postgres
    add_to_group adm
    add_to_group dialout
    add_to_group cdrom
    add_to_group floppy
    add_to_group audio
    add_to_group dip
    add_to_group video
    add_to_group plugdev
    add_to_group games
    add_to_group users
    add_to_group input
    add_to_group systemd-journal
    add_to_group systemd-network
    add_to_group systemd-resolve
    add_to_group uucp
    add_to_group tty
    add_to_group disk
    add_to_group lp
    add_to_group kmem
    
    # Configurar sudoers sin contraseña
    echo "\$APP_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/\$APP_USER
    chmod 440 /etc/sudoers.d/\$APP_USER
    
    # Configurar SSH
    mkdir -p /home/\$APP_USER/.ssh
    cp /root/.ssh/authorized_keys /home/\$APP_USER/.ssh/
    chown -R \$APP_USER:\$APP_USER /home/\$APP_USER/.ssh
    chmod 700 /home/\$APP_USER/.ssh
    chmod 600 /home/\$APP_USER/.ssh/authorized_keys
    
    echo "✅ Usuario \$APP_USER creado con todos los permisos y grupos"
else
    echo "ℹ Usuario \$APP_USER ya existe - actualizando grupos..."
    
    # Función para agregar usuario a grupo solo si existe
    add_to_group() {
        if getent group "\$1" >/dev/null 2>&1; then
            usermod -aG "\$1" "\$APP_USER" 2>/dev/null || true
            echo "   ✅ Agregado a grupo \$1"
        else
            echo "   ⚠️ Grupo \$1 no existe - omitiendo"
        fi
    }
    
    # Agregar a todos los grupos importantes (solo si existen)
    echo "   🔍 Verificando grupos disponibles..."
    add_to_group sudo
    add_to_group www-data
    add_to_group postgres
    add_to_group adm
    add_to_group dialout
    add_to_group cdrom
    add_to_group floppy
    add_to_group audio
    add_to_group dip
    add_to_group video
    add_to_group plugdev
    add_to_group games
    add_to_group users
    add_to_group input
    add_to_group systemd-journal
    add_to_group systemd-network
    add_to_group systemd-resolve
    add_to_group uucp
    add_to_group tty
    add_to_group disk
    add_to_group lp
    add_to_group kmem
    
    echo "\$APP_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/\$APP_USER
    chmod 440 /etc/sudoers.d/\$APP_USER
    
    # Configurar SSH para usuario existente también
    mkdir -p /home/\$APP_USER/.ssh
    cp /root/.ssh/authorized_keys /home/\$APP_USER/.ssh/
    chown -R \$APP_USER:\$APP_USER /home/\$APP_USER/.ssh
    chmod 700 /home/\$APP_USER/.ssh
    chmod 600 /home/\$APP_USER/.ssh/authorized_keys
    echo "✅ SSH configurado para usuario \$APP_USER"
fi

echo "🎯 Configurando hostname y zona horaria..."
hostnamectl set-hostname coretransapi
timedatectl set-timezone Europe/Berlin

echo "🧭 Configurando Supervisor..."
mkdir -p /var/log/supervisor
chown root:adm /var/log/supervisor
chmod 750 /var/log/supervisor

cat > /etc/supervisor/conf.d/coretransapi.conf <<SUPERVISOR
[program:coretransapi]
directory=/home/\$APP_USER/\$REPO_DIR
command=/home/\$APP_USER/envSIM/bin/gunicorn config.wsgi:application \\
  --bind unix:/home/\$APP_USER/\$REPO_DIR/api.sock \\
  --workers 4
autostart=false
autorestart=true
umask=007
stderr_logfile=/var/log/supervisor/coretransapi.err.log
stdout_logfile=/var/log/supervisor/coretransapi.out.log
user=\$APP_USER
group=www-data
environment=\\
  PATH="/home/\$APP_USER/envSIM/bin",\\
  DJANGO_SETTINGS_MODULE="config.settings",\\
  DJANGO_ENV="production"
SUPERVISOR

echo " Configurando Nginx..."
cat > /etc/nginx/sites-available/coretransapi.conf <<NGINX
server {
    listen 80;
    server_name api.coretransapi.com;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        include proxy_params;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/coretransapi.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

systemctl enable nginx
systemctl start nginx
nginx -t
systemctl reload nginx

echo "🔐 Obteniendo certificado SSL..."
certbot --nginx --non-interactive --agree-tos -m $EMAIL_SSL -d api.coretransapi.com

echo "🧱 Configurando firewall UFW..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow from 127.0.0.1 to any port 5432
ufw allow from 127.0.0.1 to any port 8000
ufw allow out 53
ufw allow out 123/udp
ufw allow out to any port 443 proto tcp
ufw --force enable

echo " Configurando SSH (manteniendo puerto 22)..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
# NO cambiar el puerto SSH - mantener 22
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sshd -t
systemctl restart sshd

echo " Configurando Fail2Ban..."
systemctl enable fail2ban
systemctl start fail2ban

echo "🗄️ Configurando PostgreSQL..."
systemctl enable postgresql
systemctl start postgresql

# Configurar autenticación PostgreSQL
echo "🔧 Configurando autenticación PostgreSQL..."

# Detectar la versión de PostgreSQL instalada
PG_VERSION=\$(ls /etc/postgresql/ | head -n1)
if [ -z "\$PG_VERSION" ]; then
    echo "❌ No se pudo detectar la versión de PostgreSQL"
    exit 1
fi

echo "📋 Versión de PostgreSQL detectada: \$PG_VERSION"
PG_CONF_DIR="/etc/postgresql/\$PG_VERSION/main"

# Crear backup del archivo de configuración
if [ -f "\$PG_CONF_DIR/pg_hba.conf" ]; then
    cp "\$PG_CONF_DIR/pg_hba.conf" "\$PG_CONF_DIR/pg_hba.conf.bak"
    echo "✅ Backup creado: \$PG_CONF_DIR/pg_hba.conf.bak"
else
    echo "⚠️ No se encontró pg_hba.conf en \$PG_CONF_DIR"
fi

# Configurar pg_hba.conf para permitir autenticación local
cat > "\$PG_CONF_DIR/pg_hba.conf" <<PG_HBA
# Database administrative login by Unix domain socket
local   all             postgres                                peer

# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
host    all             all             0.0.0.0/0               md5

# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            md5
host    replication     all             ::1/128                 md5
PG_HBA

# Reiniciar PostgreSQL para aplicar cambios
systemctl restart postgresql

# Crear usuario y base de datos PostgreSQL
echo "🔐 Creando usuario y base de datos PostgreSQL..."

# Definir variables para PostgreSQL
DB_USER="$DB_USER"
DB_PASS="$DB_PASS"
DB_NAME="$DB_NAME"

echo "👤 Variables PostgreSQL:"
echo "   Usuario: $DB_USER"
echo "   Base de datos: $DB_NAME"

# Crear usuario PostgreSQL
echo "👤 Creando usuario PostgreSQL: $DB_USER"
sudo -u postgres psql -c "DO \\\$\\\$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN CREATE USER $DB_USER WITH PASSWORD '$DB_PASS'; END IF; END \\\$\\\$;"

# Configurar permisos del usuario
echo "🔑 Configurando permisos del usuario..."
sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"
sudo -u postgres psql -c "GRANT USAGE, CREATE ON SCHEMA public TO $DB_USER;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON SCHEMA public TO $DB_USER;"
sudo -u postgres psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO $DB_USER;"
sudo -u postgres psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;"
sudo -u postgres psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;"

# Crear base de datos
echo "🗄️ Creando base de datos: $DB_NAME"
# Verificar si la base de datos existe
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    echo "✅ Base de datos $DB_NAME ya existe"
else
    echo "📝 Creando base de datos $DB_NAME..."
    sudo -u postgres createdb "$DB_NAME"
    echo "✅ Base de datos $DB_NAME creada exitosamente"
fi

# Configurar permisos de la base de datos
echo "🔐 Configurando permisos de la base de datos..."
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
sudo -u postgres psql -c "GRANT CONNECT ON DATABASE $DB_NAME TO $DB_USER;"
sudo -u postgres psql -c "GRANT CREATE ON DATABASE $DB_NAME TO $DB_USER;"

# Verificar que el usuario puede conectarse
echo "🔍 Verificando conexión PostgreSQL..."
sudo -u postgres psql -c "SELECT 1;" >/dev/null 2>&1 && echo "✅ PostgreSQL configurado correctamente"

echo "✅ Fase 1 completada - Sistema configurado como root"
echo " Ahora se desconectará y se conectará como \$APP_USER..."
EOF

echo "🔄 Esperando 5 segundos para que SSH se reinicie..."
sleep 5

# Verificar conectividad SSH
echo "�� Verificando conectividad SSH..."
if ssh -i "$SSH_KEY" -p 22 -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@$IP_VPS "echo 'SSH funcionando'" 2>/dev/null; then
    echo "✅ Conexión SSH exitosa en puerto 22"
else
    echo "❌ No se puede conectar por SSH - verifica el estado del VPS"
    exit 1
fi

# Verificar conectividad SSH del usuario markmur88
echo "🔍 Verificando conectividad SSH del usuario $APP_USER..."
if ssh -i "$SSH_KEY" -p 22 -o ConnectTimeout=10 -o StrictHostKeyChecking=no $APP_USER@$IP_VPS "echo 'SSH funcionando como $APP_USER'" 2>/dev/null; then
    echo "✅ Conexión SSH exitosa para usuario $APP_USER"
else
    echo "❌ No se puede conectar como $APP_USER - configurando SSH..."
    # Reconfigurar SSH para el usuario
    ssh -i "$SSH_KEY" -p 22 root@$IP_VPS <<EOF
mkdir -p /home/$APP_USER/.ssh
cp /root/.ssh/authorized_keys /home/$APP_USER/.ssh/
chown -R $APP_USER:$APP_USER /home/$APP_USER/.ssh
chmod 700 /home/$APP_USER/.ssh
chmod 600 /home/$APP_USER/.ssh/authorized_keys
echo "✅ SSH reconfigurado para $APP_USER"
EOF
    sleep 3
fi

# FASE 2: Copiar carpetas locales al VPS
echo "📦 Fase 2: Copiando carpetas locales al VPS..."

echo "📁 Copiando api_bank_h2..."
if [ -d "$LOCAL_API_BANK_H2" ]; then
    rsync -avz -e "ssh -i $SSH_KEY -p 22" --exclude='__pycache__' --exclude='*.pyc' --exclude='.git' "$LOCAL_API_BANK_H2/" $APP_USER@$IP_VPS:/home/$APP_USER/$REPO_DIR/
    echo "✅ api_bank_h2 copiado exitosamente"
else
    echo "❌ No se encontró $LOCAL_API_BANK_H2"
    exit 1
fi

echo "�� Copiando api_bank_heroku..."
if [ -d "$LOCAL_API_BANK_HEROKU" ]; then
    rsync -avz -e "ssh -i $SSH_KEY -p 22" --exclude='__pycache__' --exclude='*.pyc' --exclude='.git' "$LOCAL_API_BANK_HEROKU/" $APP_USER@$IP_VPS:/home/$APP_USER/api_bank_heroku/
    echo "✅ api_bank_heroku copiado exitosamente"
else
    echo "⚠️ No se encontró $LOCAL_API_BANK_HEROKU - continuando..."
fi

echo "📁 Copiando scripts..."
if [ -d "$LOCAL_SCRIPTS" ]; then
    rsync -avz -e "ssh -i $SSH_KEY -p 22" --exclude='__pycache__' --exclude='*.pyc' --exclude='.git' "$LOCAL_SCRIPTS/" $APP_USER@$IP_VPS:/home/$APP_USER/scripts/
    echo "✅ scripts copiado exitosamente"
else
    echo "⚠️ No se encontró $LOCAL_SCRIPTS - continuando..."
fi

echo "�� Copiando Simulador..."
if [ -d "$LOCAL_SIMULADOR" ]; then
    rsync -avz -e "ssh -i $SSH_KEY -p 22" --exclude='__pycache__' --exclude='*.pyc' --exclude='.git' "$LOCAL_SIMULADOR/" $APP_USER@$IP_VPS:/home/$APP_USER/Simulador/
    echo "✅ Simulador copiado exitosamente"
else
    echo "⚠️ No se encontró $LOCAL_SIMULADOR - continuando..."
fi

# FASE 3: Configuración de la aplicación como usuario markmur88
echo "📦 Fase 3: Configuración de la aplicación como $APP_USER..."
ssh -i "$SSH_KEY" -p "$PORT_VPS" "$APP_USER@$IP_VPS" bash -s <<EOF
set -e

REPO_DIR="$REPO_DIR"
DB_NAME="$DB_NAME"
DB_USER="$DB_USER"
DB_PASS="$DB_PASS"

echo "👤 Conectado como: \$(whoami)"
echo " Directorio actual: \$(pwd)"

echo "🐍 Configurando entorno virtual..."
echo "📁 Creando entorno virtual..."
python3 -m venv /home/$APP_USER/envSIM
echo "🔧 Activando entorno virtual..."
source /home/$APP_USER/envSIM/bin/activate
echo "📦 Actualizando pip..."
pip install --upgrade pip
echo "📚 Instalando dependencias del proyecto..."
pip install -r /home/$APP_USER/\$REPO_DIR/requirements.txt
echo "✅ Entorno virtual configurado"

echo "🗄️ Verificando conexión PostgreSQL..."
# Verificar que PostgreSQL está funcionando y accesible
if sudo -u postgres psql -c "SELECT 1;" >/dev/null 2>&1; then
    echo "✅ PostgreSQL está funcionando"
else
    echo "❌ PostgreSQL no está funcionando - reiniciando..."
    sudo systemctl restart postgresql
    sleep 3
fi

# Verificar que el usuario puede conectarse a la base de datos
echo "🔍 Verificando conexión del usuario $DB_USER a la base de datos..."
if PGPASSWORD="$DB_PASS" psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1; then
    echo "✅ Usuario $DB_USER puede conectarse a la base de datos"
else
    echo "❌ Error de conexión - verificando configuración..."
    # Reconfigurar usuario si es necesario
    sudo -u postgres psql <<SQL
ALTER USER $DB_USER WITH PASSWORD '$DB_PASS';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
GRANT CONNECT ON DATABASE $DB_NAME TO $DB_USER;
SQL
    echo "✅ Usuario $DB_USER reconfigurado"
fi

echo "⚙️ Ejecutando migraciones Django..."
cd /home/$APP_USER/\$REPO_DIR
echo "🔧 Activando entorno virtual..."
source /home/$APP_USER/envSIM/bin/activate

echo "🧹 Limpiando cache..."
# Limpiar cache
find . -path "*/__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -delete 2>/dev/null || true
find . -path "*/migrations/*.py" -not -name "__init__.py" -delete 2>/dev/null || true
find . -path "*/migrations/*.pyc" -delete 2>/dev/null || true

echo "📝 Creando migraciones..."
python3 manage.py makemigrations
echo "🔄 Aplicando migraciones..."
python3 manage.py migrate
echo "📁 Recolectando archivos estáticos..."
python3 manage.py collectstatic --noinput

echo "🔧 Configurando permisos..."
sudo chown -R $APP_USER:www-data /home/$APP_USER/\$REPO_DIR
sudo chown -R $APP_USER:$APP_USER /home/$APP_USER/api_bank_heroku 2>/dev/null || true
sudo chown -R $APP_USER:$APP_USER /home/$APP_USER/scripts 2>/dev/null || true
sudo chown -R $APP_USER:$APP_USER /home/$APP_USER/Simulador 2>/dev/null || true
echo "✅ Permisos configurados"

echo "🚀 Activando Supervisor..."
echo "📖 Releyendo configuración..."
sudo supervisorctl reread
echo "🔄 Actualizando supervisor..."
sudo supervisorctl update
echo "▶️ Iniciando aplicación..."
sudo supervisorctl start coretransapi
echo "✅ Supervisor activado"

echo "✅ Fase 3 completada - Aplicación configurada como $APP_USER"

# FASE 4: Ejecutar funcionalidades del alias express
echo "🚀 Fase 4: Ejecutando funcionalidades del alias express..."

echo "📁 Sincronizando archivos locales..."
bash /home/$APP_USER/scripts/backup/00_14_sincronizacion_archivos.sh

echo "🗄️ Configurando PostgreSQL local..."
bash /home/$APP_USER/scripts/deploy/django/00_07_postgres.sh

echo "⚙️ Aplicando migraciones Django..."
cd /home/$APP_USER/$REPO_DIR
source /home/$APP_USER/envSIM/bin/activate
python3 manage.py makemigrations
python3 manage.py migrate
python3 manage.py collectstatic --noinput

echo "📤 Desplegando a GitHub..."
bash /home/$APP_USER/scripts/deploy/github/00_16_01_subir_GitHub.sh

echo "🔐 Ejecutando entorno local con SSL..."
bash /home/$APP_USER/scripts/certs/00_21_local_ssl.sh

echo "✅ Fase 4 completada - Funcionalidades express ejecutadas"
EOF

echo "🎉 ¡Despliegue completado exitosamente!"
echo " Resumen:"
echo "   - VPS: $IP_VPS"
echo "   - SSH: Puerto 22 (mantenido)"
echo "   - Usuario: $APP_USER (creado con todos los permisos)"
echo "   - Aplicación: https://api.coretransapi.com"
echo "   - Base de datos: PostgreSQL configurada"
echo "   - SSL: Certificado Let's Encrypt instalado"
echo "   - Firewall: UFW configurado"
echo "   - Seguridad: Fail2Ban activado"
echo "   - Entorno virtual: Creado en /home/$APP_USER/envSIM"
echo "   - Directorio proyecto: /home/$APP_USER/$REPO_DIR"
echo "   - Funcionalidades express: Sincronización, PostgreSQL, migraciones, GitHub, SSL"
echo ""
echo "�� Carpetas copiadas:"
echo "   - api_bank_h2: $(if [ -d "$LOCAL_API_BANK_H2" ]; then echo "✅"; else echo "❌"; fi)"
echo "   - api_bank_heroku: $(if [ -d "$LOCAL_API_BANK_HEROKU" ]; then echo "✅"; else echo "❌"; fi)"
echo "   - scripts: $(if [ -d "$LOCAL_SCRIPTS" ]; then echo "✅"; else echo "❌"; fi)"
echo "   - Simulador: $(if [ -d "$LOCAL_SIMULADOR" ]; then echo "✅"; else echo "❌"; fi)"
echo ""
echo " Para conectarte al VPS:"
echo "   ssh -i $SSH_KEY -p 22 $APP_USER@$IP_VPS"
echo ""
echo "🔒 El firewall está configurado de forma segura:"
echo "   - Puerto 22 (SSH) está permitido"
echo "   - Puerto 80 (HTTP) está permitido"
echo "   - Puerto 443 (HTTPS) está permitido"
echo "   - Conexiones salientes permitidas"