#!/usr/bin/env python3
"""
Script de restauración del servidor
Usar después de restaurar el servidor para configurar todo automáticamente
"""

import os
import subprocess
import json
import shutil
from pathlib import Path

def run_command(command, check=True):
    """Ejecutar comando"""
    print(f"Ejecutando: {command}")
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f"Error: {result.stderr}")
        return False
    return True

def install_dependencies():
    """Instalar dependencias básicas"""
    print("🔧 Instalando dependencias básicas...")
    
    # Actualizar sistema
    run_command("apt-get update")
    
    # Paquetes básicos
    basic_packages = [
        "python3", "python3-pip", "nginx", "supervisor", "tor",
        "certbot", "python3-certbot-nginx", "curl", "wget", "git",
        "unzip", "htop", "vim", "ufw", "mysql-server", "redis-server"
    ]
    
    for package in basic_packages:
        run_command(f"apt-get install -y {package}")
    
    # Paquetes Python
    pip_packages = ["requests", "flask", "django", "psycopg2-binary"]
    for package in pip_packages:
        run_command(f"pip3 install {package}")

def setup_nginx():
    """Configurar Nginx básico"""
    print("�� Configurando Nginx...")
    
    # Configuración básica
    nginx_config = """
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.html index.htm index.php;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
"""
    
    # Crear sitio por defecto
    with open('/etc/nginx/sites-available/default', 'w') as f:
        f.write(nginx_config)
    
    # Habilitar sitio
    run_command("ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/")
    
    # Crear directorio web
    os.makedirs('/var/www/html', exist_ok=True)
    
    # Página de prueba
    with open('/var/www/html/index.html', 'w') as f:
        f.write("<h1>Servidor restaurado correctamente!</h1>")
    
    run_command("nginx -t")
    run_command("systemctl enable nginx")
    run_command("systemctl restart nginx")

def setup_supervisor():
    """Configurar Supervisor básico"""
    print("👨‍💼 Configurando Supervisor...")
    
    # Configuración básica
    supervisor_config = """
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[unix_http_server]
file=/var/run/supervisor.sock
chmod=0700

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[program:example]
command=python3 /opt/example/app.py
directory=/opt/example
user=www-data
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/example.err.log
stdout_logfile=/var/log/supervisor/example.out.log
"""
    
    with open('/etc/supervisor/supervisord.conf', 'w') as f:
        f.write(supervisor_config)
    
    run_command("systemctl enable supervisor")
    run_command("systemctl restart supervisor")

def setup_tor():
    """Configurar Tor básico"""
    print("🔒 Configurando Tor...")
    
    # Configuración básica
    tor_config = """
SocksPort 9050
HiddenServiceDir /var/lib/tor/hidden_service/
HiddenServicePort 80 127.0.0.1:80
"""
    
    with open('/etc/tor/torrc', 'w') as f:
        f.write(tor_config)
    
    # Crear directorio para servicios ocultos
    os.makedirs('/var/lib/tor/hidden_service', exist_ok=True)
    run_command("chown -R debian-tor:debian-tor /var/lib/tor")
    
    run_command("systemctl enable tor")
    run_command("systemctl restart tor")

def setup_firewall():
    """Configurar firewall básico"""
    print("🔥 Configurando firewall...")
    
    run_command("ufw --force enable")
    run_command("ufw default deny incoming")
    run_command("ufw default allow outgoing")
    run_command("ufw allow ssh")
    run_command("ufw allow 80/tcp")
    run_command("ufw allow 443/tcp")
    run_command("ufw allow 9050/tcp")  # Tor

def setup_ssl():
    """Configurar SSL básico"""
    print("🔐 Configurando SSL...")
    
    # Crear certificado autofirmado para pruebas
    run_command("openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj '/CN=localhost'")

def create_backup_script():
    """Crear script de backup automático"""
    backup_script = """#!/bin/bash
# Script de backup automático

BACKUP_DIR="/backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

echo "Iniciando backup..."

# Backup de configuraciones
cp -r /etc/nginx $BACKUP_DIR/
cp -r /etc/supervisor $BACKUP_DIR/
cp -r /etc/tor $BACKUP_DIR/
cp -r /etc/letsencrypt $BACKUP_DIR/

# Backup de aplicaciones web
cp -r /var/www $BACKUP_DIR/

# Backup de bases de datos
mysqldump --all-databases > $BACKUP_DIR/all_databases.sql

# Backup de logs
cp -r /var/log $BACKUP_DIR/

echo "Backup completado en: $BACKUP_DIR"
"""
    
    with open('/usr/local/bin/backup_server.sh', 'w') as f:
        f.write(backup_script)
    
    run_command("chmod +x /usr/local/bin/backup_server.sh")

def main():
    """Función principal"""
    print("🚀 Iniciando configuración del servidor restaurado...")
    
    # Verificar que estamos como root
    if os.geteuid() != 0:
        print("❌ Este script debe ejecutarse como root")
        exit(1)
    
    print("�� Pasos de configuración:")
    print("1. Instalando dependencias...")
    install_dependencies()
    
    print("2. Configurando Nginx...")
    setup_nginx()
    
    print("3. Configurando Supervisor...")
    setup_supervisor()
    
    print("4. Configurando Tor...")
    setup_tor()
    
    print("5. Configurando firewall...")
    setup_firewall()
    
    print("6. Configurando SSL...")
    setup_ssl()
    
    print("7. Creando script de backup...")
    create_backup_script()
    
    print("\n✅ Configuración completada!")
    print("\n📋 Información del servidor:")
    print(f"   - IP: {subprocess.check_output(['hostname', '-I']).decode().strip()}")
    print("   - Nginx: http://localhost")
    print("   - Tor: Puerto 9050")
    print("   - Supervisor: /etc/supervisor/")
    print("\n🔧 Comandos útiles:")
    print("   - Backup: /usr/local/bin/backup_server.sh")
    print("   - Estado servicios: systemctl status nginx supervisor tor")
    print("   - Logs: tail -f /var/log/nginx/error.log")

if __name__ == "__main__":
    main()