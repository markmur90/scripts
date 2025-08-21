#!/usr/bin/env python3
import os
import socket
import subprocess
import requests
import ssl
import json
import glob
import shutil
from datetime import datetime
from pathlib import Path

def run_command_safe(command, capture_output=True):
    """Ejecuta un comando de forma segura y maneja errores"""
    try:
        if capture_output:
            result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=30)
            return result.stdout if result.returncode == 0 else f"Error: {result.stderr}"
        else:
            result = subprocess.run(command, shell=True, timeout=30)
            return "Comando ejecutado exitosamente" if result.returncode == 0 else f"Error: código {result.returncode}"
    except subprocess.TimeoutExpired:
        return "Error: Comando expiró por timeout"
    except Exception as e:
        return f"Error: {str(e)}"

def get_system_info():
    """Información del sistema"""
    info = {}
    try:
        info['hostname'] = socket.gethostname()
        info['os_info'] = run_command_safe('cat /etc/os-release')
        info['kernel_version'] = run_command_safe('uname -r')
        info['architecture'] = run_command_safe('uname -m')
        info['cpu_info'] = run_command_safe('lscpu')
        info['memory_info'] = run_command_safe('free -h')
        info['disk_info'] = run_command_safe('df -h')
        info['system_uptime'] = run_command_safe('uptime')
    except Exception as e:
        info['system_error'] = str(e)
    return info

def get_network_info():
    """Información de red"""
    info = {}
    try:
        info['ip_addresses'] = run_command_safe('hostname -I')
        info['network_interfaces'] = run_command_safe('ip a')
        info['routing_table'] = run_command_safe('ip route')
        info['dns_servers'] = run_command_safe('cat /etc/resolv.conf')
        info['hosts_file'] = run_command_safe('cat /etc/hosts')
    except Exception as e:
        info['network_error'] = str(e)
    return info

def get_installed_packages():
    """Paquetes instalados"""
    info = {}
    try:
        # Obtener lista de paquetes instalados
        apt_output = run_command_safe('dpkg -l')
        packages = []
        for line in apt_output.split('\n'):
            if line.startswith('ii '):
                parts = line.split()
                if len(parts) >= 3:
                    packages.append({
                        'name': parts[1],
                        'version': parts[2],
                        'description': ' '.join(parts[3:]) if len(parts) > 3 else ''
                    })
        info['apt_packages'] = packages[:100]  # Limitar a 100 paquetes
        
        # Paquetes Python
        pip_output = run_command_safe('pip list')
        pip_packages = []
        for line in pip_output.split('\n')[2:]:  # Saltar header
            if line.strip():
                parts = line.split()
                if len(parts) >= 2:
                    pip_packages.append({
                        'name': parts[0],
                        'version': parts[1]
                    })
        info['pip_packages'] = pip_packages
        
        # Versiones de software
        info['python_version'] = run_command_safe('python3 --version')
        info['node_version'] = run_command_safe('node --version')
        info['npm_version'] = run_command_safe('npm --version')
    except Exception as e:
        info['packages_error'] = str(e)
    return info

def get_nginx_config():
    """Configuración de Nginx"""
    config = {}
    try:
        config['version'] = run_command_safe('nginx -v')
        config['main_config'] = run_command_safe('cat /etc/nginx/nginx.conf')
        
        # Configuraciones de sitios
        sites_available = glob.glob('/etc/nginx/sites-available/*')
        sites_enabled = glob.glob('/etc/nginx/sites-enabled/*')
        
        config['sites_available'] = {}
        for site in sites_available:
            site_name = os.path.basename(site)
            config['sites_available'][site_name] = run_command_safe(f'cat {site}')
        
        config['sites_enabled'] = [os.path.basename(site) for site in sites_enabled]
        
        # Directorios web
        web_dirs = ['/var/www']
        config['web_directories'] = {}
        for web_dir in web_dirs:
            if os.path.exists(web_dir):
                config['web_directories'][web_dir] = run_command_safe(f'ls -la {web_dir}')
    except Exception as e:
        config['error'] = str(e)
    return config

def get_supervisor_config():
    """Configuración de Supervisor"""
    config = {}
    try:
        config['main_config'] = run_command_safe('cat /etc/supervisor/supervisord.conf')
        
        # Configuraciones de programas
        program_configs = glob.glob('/etc/supervisor/conf.d/*.conf')
        config['programs'] = {}
        for prog_config in program_configs:
            prog_name = os.path.basename(prog_config)
            config['programs'][prog_name] = run_command_safe(f'cat {prog_config}')
    except Exception as e:
        config['error'] = str(e)
    return config

def get_tor_config():
    """Configuración de Tor"""
    config = {}
    try:
        config['torrc'] = run_command_safe('cat /etc/tor/torrc')
        config['hidden_services'] = []
        
        # Buscar servicios ocultos
        tor_data_dir = '/var/lib/tor'
        if os.path.exists(tor_data_dir):
            for service_dir in os.listdir(tor_data_dir):
                hostname_file = os.path.join(tor_data_dir, service_dir, 'hostname')
                if os.path.exists(hostname_file):
                    with open(hostname_file, 'r') as f:
                        hostname = f.read().strip()
                        config['hidden_services'].append({
                            'service_name': service_dir,
                            'hostname': hostname
                        })
    except Exception as e:
        config['error'] = str(e)
    return config

def get_ssl_certificates():
    """Certificados SSL"""
    certs = {}
    try:
        # Let's Encrypt
        if os.path.exists('/etc/letsencrypt/live'):
            domains = os.listdir('/etc/letsencrypt/live')
            certs['letsencrypt'] = {
                'domains': domains,
                'renewal_config': run_command_safe('cat /etc/letsencrypt/renewal/*.conf')
            }
        
        # Certificados del sistema
        if os.path.exists('/etc/ssl/certs'):
            certs['system_certs'] = run_command_safe('ls -la /etc/ssl/certs | head -20')
    except Exception as e:
        certs['error'] = str(e)
    return certs

def get_database_config():
    """Configuración de bases de datos"""
    db_config = {}
    try:
        # MySQL/MariaDB
        if os.path.exists('/etc/mysql/mysql.conf.d/mysqld.cnf'):
            db_config['mysql'] = run_command_safe('cat /etc/mysql/mysql.conf.d/mysqld.cnf')
        
        # PostgreSQL
        if os.path.exists('/etc/postgresql'):
            db_config['postgresql'] = run_command_safe('ls -la /etc/postgresql')
    except Exception as e:
        db_config['error'] = str(e)
    return db_config

def get_cron_jobs():
    """Trabajos cron"""
    cron = {}
    try:
        cron['root_crontab'] = run_command_safe('crontab -l')
        cron['system_cron'] = run_command_safe('ls -la /etc/cron.*')
        cron['anacron'] = run_command_safe('cat /etc/anacrontab')
    except Exception as e:
        cron['error'] = str(e)
    return cron

def get_application_configs():
    """Configuraciones de aplicaciones"""
    apps = {}
    try:
        # Buscar archivos de configuración comunes
        config_patterns = [
            '/var/www/*/wp-config.php',
            '/var/www/*/.env',
            '/var/www/*/config.php',
            '/var/www/*/settings.py',
            '/opt/*/.env',
            '/home/*/public_html/.env'
        ]
        
        for pattern in config_patterns:
            files = glob.glob(pattern)
            for config_file in files:
                app_name = os.path.basename(os.path.dirname(config_file))
                config_name = os.path.basename(config_file)
                apps[f'{app_name}_{config_name}'] = {
                    'path': config_file,
                    'content': run_command_safe(f'head -50 {config_file}')
                }
    except Exception as e:
        apps['error'] = str(e)
    return apps

def save_configuration():
    """Guardar toda la configuración en archivos JSON"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Crear directorio de configuración
    config_dir = f"server_config_{timestamp}"
    os.makedirs(config_dir, exist_ok=True)
    
    # Recopilar toda la información
    config_data = {
        'timestamp': timestamp,
        'hostname': socket.gethostname(),
        'system': get_system_info(),
        'network': get_network_info(),
        'packages': get_installed_packages(),
        'nginx': get_nginx_config(),
        'supervisor': get_supervisor_config(),
        'tor': get_tor_config(),
        'ssl': get_ssl_certificates(),
        'database': get_database_config(),
        'cron': get_cron_jobs(),
        'applications': get_application_configs()
    }
    
    # Guardar configuración principal
    with open(f"{config_dir}/server_config.json", 'w', encoding='utf-8') as f:
        json.dump(config_data, f, indent=2, ensure_ascii=False)
    
    # Crear script de restauración
    create_restore_script(config_dir, config_data)
    
    # Crear script de instalación de dependencias
    create_install_script(config_dir, config_data)
    
    print(f"✅ Configuración guardada en: {config_dir}/")
    print(f"�� Archivos generados:")
    print(f"   - {config_dir}/server_config.json")
    print(f"   - {config_dir}/restore_server.py")
    print(f"   - {config_dir}/install_dependencies.sh")
    
    return config_dir

def create_restore_script(config_dir, config_data):
    """Crear script de restauración"""
    restore_script = f'''#!/usr/bin/env python3
"""
Script de restauración del servidor
Generado automáticamente el {config_data['timestamp']}
"""

import os
import subprocess
import json
import shutil
from pathlib import Path

def run_command(command, check=True):
    """Ejecutar comando"""
    print(f"Ejecutando: {{command}}")
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f"Error: {{result.stderr}}")
        return False
    return True

def install_packages(packages):
    """Instalar paquetes APT"""
    print("\\n📦 Instalando paquetes del sistema...")
    for package in packages:
        if isinstance(package, dict):
            package_name = package['name']
        else:
            package_name = package
        print(f"Instalando: {{package_name}}")
        run_command(f"apt-get install -y {{package_name}}")

def install_pip_packages(packages):
    """Instalar paquetes Python"""
    print("\\n🐍 Instalando paquetes Python...")
    for package in packages:
        if isinstance(package, dict):
            package_name = package['name']
            version = package['version']
            run_command(f"pip3 install {{package_name}}=={{version}}")
        else:
            run_command(f"pip3 install {{package}}")

def setup_nginx(config):
    """Configurar Nginx"""
    print("\\n�� Configurando Nginx...")
    
    # Instalar Nginx
    run_command("apt-get install -y nginx")
    
    # Restaurar configuración principal
    if 'main_config' in config:
        with open('/etc/nginx/nginx.conf', 'w') as f:
            f.write(config['main_config'])
    
    # Restaurar sitios
    if 'sites_available' in config:
        for site_name, site_config in config['sites_available'].items():
            site_path = f"/etc/nginx/sites-available/{{site_name}}"
            with open(site_path, 'w') as f:
                f.write(site_config)
    
    # Habilitar sitios
    if 'sites_enabled' in config:
        for site in config['sites_enabled']:
            run_command(f"ln -sf /etc/nginx/sites-available/{{site}} /etc/nginx/sites-enabled/")
    
    # Crear directorios web
    if 'web_directories' in config:
        for web_dir in config['web_directories'].keys():
            os.makedirs(web_dir, exist_ok=True)
    
    run_command("nginx -t")
    run_command("systemctl enable nginx")
    run_command("systemctl restart nginx")

def setup_supervisor(config):
    """Configurar Supervisor"""
    print("\\n👨‍💼 Configurando Supervisor...")
    
    # Instalar Supervisor
    run_command("apt-get install -y supervisor")
    
    # Restaurar configuración principal
    if 'main_config' in config:
        with open('/etc/supervisor/supervisord.conf', 'w') as f:
            f.write(config['main_config'])
    
    # Restaurar programas
    if 'programs' in config:
        for prog_name, prog_config in config['programs'].items():
            prog_path = f"/etc/supervisor/conf.d/{{prog_name}}"
            with open(prog_path, 'w') as f:
                f.write(prog_config)
    
    run_command("supervisorctl reread")
    run_command("supervisorctl update")
    run_command("systemctl enable supervisor")

def setup_tor(config):
    """Configurar Tor"""
    print("\\n🔒 Configurando Tor...")
    
    # Instalar Tor
    run_command("apt-get install -y tor")
    
    # Restaurar configuración
    if 'torrc' in config:
        with open('/etc/tor/torrc', 'w') as f:
            f.write(config['torrc'])
    
    # Restaurar servicios ocultos
    if 'hidden_services' in config:
        for service in config['hidden_services']:
            service_dir = f"/var/lib/tor/{{service['service_name']}}"
            os.makedirs(service_dir, exist_ok=True)
            with open(f"{{service_dir}}/hostname", 'w') as f:
                f.write(service['hostname'])
    
    run_command("systemctl enable tor")
    run_command("systemctl restart tor")

def setup_ssl_certificates(config):
    """Configurar certificados SSL"""
    print("\\n🔐 Configurando certificados SSL...")
    
    # Instalar certbot
    run_command("apt-get install -y certbot python3-certbot-nginx")
    
    # Restaurar certificados Let's Encrypt
    if 'letsencrypt' in config and 'domains' in config['letsencrypt']:
        for domain in config['letsencrypt']['domains']:
            print(f"Restaurando certificado para: {{domain}}")
            # Nota: Los certificados reales deben restaurarse desde backup

def setup_cron_jobs(config):
    """Configurar trabajos cron"""
    print("\\n⏰ Configurando trabajos cron...")
    
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
    
    print(f"Restaurando servidor: {{config['hostname']}}")
    print(f"Configuración del: {{config['timestamp']}}")
    
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
    
    print("\\n✅ Restauración completada!")
    print("\\n�� Próximos pasos:")
    print("1. Restaurar archivos de aplicaciones web desde backup")
    print("2. Restaurar bases de datos desde backup")
    print("3. Restaurar certificados SSL desde backup")
    print("4. Verificar que todos los servicios estén funcionando")

if __name__ == "__main__":
    main()
'''
    
    with open(f"{config_dir}/restore_server.py", 'w', encoding='utf-8') as f:
        f.write(restore_script)
    
    # Hacer ejecutable
    os.chmod(f"{config_dir}/restore_server.py", 0o755)

def create_install_script(config_dir, config_data):
    """Crear script de instalación de dependencias"""
    install_script = f'''#!/bin/bash
# Script de instalación de dependencias
# Generado el {config_data['timestamp']}

echo "🔧 Instalando dependencias del sistema..."

# Actualizar sistema
apt-get update

# Instalar paquetes básicos
apt-get install -y \\
    python3 \\
    python3-pip \\
    nginx \\
    supervisor \\
    tor \\
    certbot \\
    python3-certbot-nginx \\
    curl \\
    wget \\
    git \\
    unzip \\
    htop \\
    vim \\
    ufw

# Instalar paquetes Python
pip3 install requests

echo "✅ Dependencias instaladas!"
echo "📋 Para restaurar la configuración ejecuta: python3 restore_server.py"
'''
    
    with open(f"{config_dir}/install_dependencies.sh", 'w') as f:
        f.write(install_script)
    
    # Hacer ejecutable
    os.chmod(f"{config_dir}/install_dependencies.sh", 0o755)

def main():
    """Función principal"""
    print("🔍 Recopilando configuración del servidor...")
    
    config_dir = save_configuration()
    
    print(f"\n📁 Directorio de configuración: {config_dir}")
    print("\n📋 Para restaurar el servidor:")
    print(f"1. Copia la carpeta '{config_dir}' al nuevo servidor")
    print(f"2. Ejecuta: cd {config_dir}")
    print(f"3. Ejecuta: chmod +x install_dependencies.sh")
    print(f"4. Ejecuta: ./install_dependencies.sh")
    print(f"5. Ejecuta: python3 restore_server.py")
    print("\n⚠️  Recuerda restaurar también:")
    print("   - Archivos de aplicaciones web")
    print("   - Bases de datos")
    print("   - Certificados SSL")
    print("   - Logs y datos de usuario")

if __name__ == "__main__":
    main()