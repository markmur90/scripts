#!/usr/bin/env python3
"""
Script de restauración del servidor
Generado automáticamente el 20250813_035612
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

def install_packages(packages):
    """Instalar paquetes APT"""
    print("\n📦 Instalando paquetes del sistema...")
    for package in packages:
        if isinstance(package, dict):
            package_name = package['name']
        else:
            package_name = package
        print(f"Instalando: {package_name}")
        run_command(f"apt-get install -y {package_name}")

def install_pip_packages(packages):
    """Instalar paquetes Python"""
    print("\n🐍 Instalando paquetes Python...")
    for package in packages:
        if isinstance(package, dict):
            package_name = package['name']
            version = package['version']
            run_command(f"pip3 install {package_name}=={version}")
        else:
            run_command(f"pip3 install {package}")

def setup_nginx(config):
    """Configurar Nginx"""
    print("\n�� Configurando Nginx...")
    
    # Instalar Nginx
    run_command("apt-get install -y nginx")
    
    # Restaurar configuración principal
    if 'main_config' in config:
        with open('/etc/nginx/nginx.conf', 'w') as f:
            f.write(config['main_config'])
    
    # Restaurar sitios
    if 'sites_available' in config:
        for site_name, site_config in config['sites_available'].items():
            site_path = f"/etc/nginx/sites-available/{site_name}"
            with open(site_path, 'w') as f:
                f.write(site_config)
    
    # Habilitar sitios
    if 'sites_enabled' in config:
        for site in config['sites_enabled']:
            run_command(f"ln -sf /etc/nginx/sites-available/{site} /etc/nginx/sites-enabled/")
    
    # Crear directorios web
    if 'web_directories' in config:
        for web_dir in config['web_directories'].keys():
            os.makedirs(web_dir, exist_ok=True)
    
    run_command("nginx -t")
    run_command("systemctl enable nginx")
    run_command("systemctl restart nginx")

def setup_supervisor(config):
    """Configurar Supervisor"""
    print("\n👨‍💼 Configurando Supervisor...")
    
    # Instalar Supervisor
    run_command("apt-get install -y supervisor")
    
    # Restaurar configuración principal
    if 'main_config' in config:
        with open('/etc/supervisor/supervisord.conf', 'w') as f:
            f.write(config['main_config'])
    
    # Restaurar programas
    if 'programs' in config:
        for prog_name, prog_config in config['programs'].items():
            prog_path = f"/etc/supervisor/conf.d/{prog_name}"
            with open(prog_path, 'w') as f:
                f.write(prog_config)
    
    run_command("supervisorctl reread")
    run_command("supervisorctl update")
    run_command("systemctl enable supervisor")

def setup_tor(config):
    """Configurar Tor"""
    print("\n🔒 Configurando Tor...")
    
    # Instalar Tor
    run_command("apt-get install -y tor")
    
    # Restaurar configuración
    if 'torrc' in config:
        with open('/etc/tor/torrc', 'w') as f:
            f.write(config['torrc'])
    
    # Restaurar servicios ocultos
    if 'hidden_services' in config:
        for service in config['hidden_services']:
            service_dir = f"/var/lib/tor/{service['service_name']}"
            os.makedirs(service_dir, exist_ok=True)
            with open(f"{service_dir}/hostname", 'w') as f:
                f.write(service['hostname'])
    
    run_command("systemctl enable tor")
    run_command("systemctl restart tor")

def setup_ssl_certificates(config):
    """Configurar certificados SSL"""
    print("\n🔐 Configurando certificados SSL...")
    
    # Instalar certbot
    run_command("apt-get install -y certbot python3-certbot-nginx")
    
    # Restaurar certificados Let's Encrypt
    if 'letsencrypt' in config and 'domains' in config['letsencrypt']:
        for domain in config['letsencrypt']['domains']:
            print(f"Restaurando certificado para: {domain}")
            # Nota: Los certificados reales deben restaurarse desde backup

def setup_cron_jobs(config):
    """Configurar trabajos cron"""
    print("\n⏰ Configurando trabajos cron...")
    
    if 'root_crontab' in config:
        with open('/tmp/root_crontab', 'w') as f:
            f.write(config['root_crontab'])
        run_command("crontab /tmp/root_crontab")

def main():
    """Función principal de restauración"""
    print("�� Iniciando restauración del servidor...")
    
    # Cargar configuración
    with open('server_config.json', 'r') as f:
        config = json.load(f)
    
    print(f"Restaurando servidor: {config['hostname']}")
    print(f"Configuración del: {config['timestamp']}")
    
    # Actualizar sistema
    run_command("apt-get update")
    
    # Instalar paquetes
    if 'packages' in config and 'apt_packages' in config['packages']:
        packages = [pkg['name'] for pkg in config['packages']['apt_packages'][:50]]  # Limitar a 50
        install_packages(packages)
    
    # Instalar paquetes Python
    if 'packages' in config and 'pip_packages' in config['packages']:
        install_pip_packages(config['packages']['pip_packages'])
    
    # Configurar servicios
    if 'nginx' in config:
        setup_nginx(config['nginx'])
    
    if 'supervisor' in config:
        setup_supervisor(config['supervisor'])
    
    if 'tor' in config:
        setup_tor(config['tor'])
    
    if 'ssl' in config:
        setup_ssl_certificates(config['ssl'])
    
    if 'cron' in config:
        setup_cron_jobs(config['cron'])
    
    print("\n✅ Restauración completada!")
    print("\n�� Próximos pasos:")
    print("1. Restaurar archivos de aplicaciones web desde backup")
    print("2. Restaurar bases de datos desde backup")
    print("3. Restaurar certificados SSL desde backup")
    print("4. Verificar que todos los servicios estén funcionando")

if __name__ == "__main__":
    main()
