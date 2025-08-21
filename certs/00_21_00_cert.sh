#!/bin/bash
# Script para completar la validación por correo electrónico y configurar el certificado SSL/TLS en Nginx

# Variables
DOMAIN="api.coretransapi.com"
EMAIL="admin@coretransapi.com"
CSR_FILE="certificate.csr"
KEY_FILE="private.key"
CERT_FILE="certificate.crt"
CA_RESPONSE_EMAIL="ca-response-email.txt"  # Archivo que simula el correo recibido de la CA


# 1. Generar una Solicitud de Firma de Certificado (CSR)
echo "Generando CSR y clave privada..."
openssl genpkey -algorithm RSA -out $KEY_FILE -pkeyopt rsa_keygen_bits:2048
openssl req -new -key $KEY_FILE -out $CSR_FILE -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"


# 2. Simular la recepción del correo de la CA
echo "Simulando la recepción del correo de la CA..."
cat <<EOF > $CA_RESPONSE_EMAIL
Subject: Certificate Validation Request for api.coretransapi.com

Dear Administrator,

We have received a request to issue a certificate for the domain api.coretransapi.com. To complete the validation process, please follow the instructions below:

1. Click on the following link to verify your domain:
   https://ca.example.com/verify?token=abc123xyz

2. Once you have clicked the link, you will be prompted to enter the validation code:
   abc123xyz

3. Enter the code on our website to complete the validation.

If you have any questions, please contact support@ca.example.com.

Best regards,
CA Support Team
EOF


# 3. Completar el Proceso de Validación por Correo Electrónico
echo "Completando el proceso de validación por correo electrónico..."
# En la práctica, abrirías el enlace y pegarías el código de validación en el sitio web de la CA
# Aquí, simplemente mostramos el enlace y el código
echo "Por favor, abra el siguiente enlace y pegue el código de validación:"
grep "https://ca.example.com/verify?token=abc123xyz" $CA_RESPONSE_EMAIL
echo "Código de validación: abc123xyz"


# 4. Instalar y Configurar el Certificado en Nginx
echo "Instalando y configurando el certificado en Nginx..."
# Simular la recepción del certificado de la CA
cat <<EOF > $CERT_FILE
-----BEGIN CERTIFICATE-----
MIIDXTCCAkWgAwIBAgIJAJC123456789MA0GCSqGSIb3DQEBCwUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwHhcNMTcwOTI1MDYyMjQ1WhcNMjcwOTIzMDYyMjQ1WjBF
MQswCQYDVQQGEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTEhMB8GA1UECgwYSW50
ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
CgKCAQEAwJ9K
-----END CERTIFICATE-----
EOF

# Mover el certificado y la clave privada a un directorio seguro
sudo mv $KEY_FILE /etc/ssl/private/
sudo mv $CERT_FILE /etc/ssl/certs/


# 5. Configurar Nginx para usar el certificado
echo "Configurando Nginx para usar el certificado..."
sudo nano /etc/nginx/sites-available/default

# Añadir/editar la configuración de Nginx
cat <<EOF | sudo tee /etc/nginx/sites-available/default
server {
listen 443 ssl;
server_name api.coretransapi.com;
ssl_certificate /etc/ssl/certs/certificate.crt;
ssl_certificate_key /etc/ssl/private/private.key;

location / {
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
}
}
EOF

# Habilitar el sitio y reiniciar Nginx
sudo ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx


# 6. Automatizar la renovación del certificado (opcional, usando Certbot)
echo "Instalando Certbot para automatizar la renovación del certificado..."
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

# Obtener y configurar el certificado con Certbot
sudo certbot --nginx -d api.coretransapi.com

# Configurar la renovación automática

sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer


# 7. Revisar y ajustar la configuración de Fail2Ban (opcional)
echo "Revisando y ajustando la configuración de Fail2Ban..."
sudo nano /etc/fail2ban/jail.local

# Añadir/editar la configuración de Fail2Ban
cat <<EOF | sudo tee /etc/fail2ban/jail.local
[DEFAULT]
ignoreip = 127.0.0.1/8 193.150.166.1

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
EOF

# Reiniciar Fail2Ban
sudo systemctl restart fail2ban

echo "Configuración completada. El certificado SSL/TLS ha sido instalado y configurado en Nginx."

# 8. Verificar el estado de Nginx
sudo systemctl status nginx

# 9. Verificar el estado de Certbot
sudo systemctl status certbot.timer

# 10. Verificar el estado de Fail2Ban
sudo systemctl status fail2ban

echo -e "\n✅ Proceso completo. El certificado SSL/TLS para api.coretransapi.com ha sido obtenido, configurado y la renovación automática ha sido establecida.\n"
echo -e "💡 Recuerda verificar regularmente el estado de tus certificados y del servidor para asegurar que todo funcione correctamente.\n"