#!/bin/bash
set -euo pipefail

echo -e "\n🚀 Iniciando el proceso completo de obtención y configuración del certificado SSL/TLS para api.coretransapi.com...\n"

# Paso 1: Elegir el Tipo de Certificado SSL/TLS
echo -e "🔍 Paso 1: Elegir el Tipo de Certificado SSL/TLS\n"
echo -e "✅ Seleccionamos un certificado DV (Validación de Dominio) proporcionado por Let's Encrypt, ya que es gratuito, ampliamente reconocido, y adecuado para nuestro dominio.\n"

# Paso 2: Generar una Solicitud de Firma de Certificado (CSR)
echo -e "🔑 Paso 2: Generar una Solicitud de Firma de Certificado (CSR)\n"
echo -e "✅ Certbot generará automáticamente la CSR durante el proceso de obtención del certificado, por lo que no necesitas hacerlo manualmente.\n"

# Paso 3: Elegir una Autoridad de Certificación (CA)
echo -e "🏢 Paso 3: Elegir una Autoridad de Certificación (CA)\n"
echo -e "✅ Seleccionamos Let's Encrypt, una CA gratuita y ampliamente reconocida que cumple con los estándares actuales y futuros.\n"

# Paso 4: Completar el Proceso de Validación (Usando Certbot con Nginx)
echo -e "🔍 Paso 4: Completando el proceso de validación...\n"

# Instalar Certbot si no está instalado
if ! command -v certbot &> /dev/null; then
    echo -e "📦 Instalando Certbot...\n"
    sudo apt-get update
    sudo apt-get install -y certbot python3-certbot-nginx
else
    echo -e "✅ Certbot ya está instalado.\n"
fi

# Obtener y configurar el certificado
echo -e "🔧 Obteniendo y configurando el certificado SSL/TLS...\n"
sudo certbot --nginx -d api.coretransapi.com --non-interactive --agree-tos -m admin@api.coretransapi.com

# Paso 5: Instalar y Configurar el Certificado (Certbot lo hace automáticamente)
echo -e "✅ Paso 5: Certbot ha instalado y configurado el certificado automáticamente.\n"

# Verificar la configuración de Nginx
echo -e "🔍 Verificando la configuración de Nginx...\n"
sudo nginx -t

# Reiniciar Nginx para aplicar los cambios
echo -e "🔄 Reiniciando Nginx...\n"
sudo systemctl reload nginx

# Paso 6: Automatizar la Renovación
echo -e "📅 Paso 6: Automatizando la renovación del certificado...\n"

# Configurar la renovación automática
echo -e "🔧 Configurando la renovación automática...\n"
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# Verificar el estado del temporizador de Certbot
echo -e "🔍 Verificando el estado del temporizador de Certbot...\n"
sudo systemctl status certbot.timer

# Paso 7: Revisar y Ajustar la Configuración de Fail2Ban
echo -e "🔧 Paso 7: Revisando y ajustando la configuración de Fail2Ban...\n"

# Crear o editar el archivo jail.local de Fail2Ban
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
# Excluir IPs legítimas del bloqueo
ignoreip = 127.0.0.1/8 193.150.166.1

# Permitir tráfico IPv6
allowipv6 = true

# Parámetros globales para todos los jails
bantime  = 10m
findtime  = 600
maxretry = 10

[sshd]
# Configuración específica para el jail sshd
enabled = true
port    = ssh
logpath = /var/log/auth.log
backend = %(sshd_backend)s
maxretry = 10
findtime = 600
bantime  = 10m
EOF

# Reiniciar Fail2Ban para aplicar los cambios
echo -e "🔄 Reiniciando Fail2Ban...\n"
sudo systemctl restart fail2ban

# Verificar el estado de Fail2Ban
echo -e "🔍 Verificando el estado de Fail2Ban...\n"
sudo systemctl status fail2ban

echo -e "\n✅ Proceso completo. El certificado SSL/TLS para api.coretransapi.com ha sido obtenido, configurado y la renovación automática ha sido establecida.\n"
echo -e "💡 Recuerda verificar regularmente el estado de tus certificados y del servidor para asegurar que todo funcione correctamente.\n"