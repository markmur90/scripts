#!/bin/bash
# Script de instalación de dependencias
# Generado el 20250813_035612

echo "🔧 Instalando dependencias del sistema..."

# Actualizar sistema
apt-get update

# Instalar paquetes básicos
sudo apt-get install -y python3 python3-pip nginx supervisor tor certbot python3-certbot-nginx curl wget git unzip htop vim ufw

# Instalar paquetes Python
pip3 install requests

echo "✅ Dependencias instaladas!"
echo "📋 Para restaurar la configuración ejecuta: python3 restore_server.py"
