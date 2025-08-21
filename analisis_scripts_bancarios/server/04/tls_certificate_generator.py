#!/usr/bin/env python3
"""
Generador de Certificados TLS para Deutsche Bank
Autor: Sistema de Análisis de Scripts Bancarios
Fecha: 2024

Este script genera certificados TLS personalizados compatibles con:
- TLS 1.3
- AES-256-GCM
- Requerimientos de Deutsche Bank
"""

import os
import sys
import subprocess
import hashlib
import ipaddress
from datetime import datetime, timedelta
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives.serialization import load_pem_private_key
from cryptography.hazmat.backends import default_backend

class DeutscheBankCertificateGenerator:
    """Generador de certificados TLS para Deutsche Bank"""
    
    def __init__(self, output_dir="deutsche_bank_certs"):
        self.output_dir = output_dir
        self.cert_info = {
            'country': 'DE',
            'state': 'HESSE',
            'city': 'FRANKFURT',
            'organization': 'DEUTSCHE BANK AG',
            'organizational_unit': 'IT SECURITY',
            'common_name': '193.150.166.1',
            'email': 'security@deutsche-bank.com',
            'validity_days': 365,
            'key_size': 4096
        }
        
        # Crear directorio de salida
        os.makedirs(self.output_dir, exist_ok=True)
        
    def generate_private_key(self):
        """Genera una clave privada RSA de 4096 bits"""
        print("🔑 Generando clave privada RSA de 4096 bits...")
        
        try:
            private_key = rsa.generate_private_key(
                public_exponent=65537,
                key_size=self.cert_info['key_size'],
                backend=default_backend()
            )
            
            # Guardar clave privada
            private_key_path = os.path.join(self.output_dir, "deutsche_bank_private_key.pem")
            with open(private_key_path, "wb") as f:
                f.write(private_key.private_bytes(
                    encoding=serialization.Encoding.PEM,
                    format=serialization.PrivateFormat.PKCS8,
                    encryption_algorithm=serialization.NoEncryption()
                ))
            
            print(f"✅ Clave privada guardada en: {private_key_path}")
            return private_key
            
        except Exception as e:
            print(f"❌ Error generando clave privada: {e}")
            return None
    
    def create_certificate_signing_request(self, private_key):
        """Crea un Certificate Signing Request (CSR)"""
        print("📝 Generando Certificate Signing Request...")
        
        try:
            # Crear subject
            subject = x509.Name([
                x509.NameAttribute(NameOID.COUNTRY_NAME, self.cert_info['country']),
                x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, self.cert_info['state']),
                x509.NameAttribute(NameOID.LOCALITY_NAME, self.cert_info['city']),
                x509.NameAttribute(NameOID.ORGANIZATION_NAME, self.cert_info['organization']),
                x509.NameAttribute(NameOID.ORGANIZATIONAL_UNIT_NAME, self.cert_info['organizational_unit']),
                x509.NameAttribute(NameOID.COMMON_NAME, self.cert_info['common_name']),
                x509.NameAttribute(NameOID.EMAIL_ADDRESS, self.cert_info['email']),
            ])
            
            # Convertir IP a objeto ipaddress
            ip_address = ipaddress.IPv4Address(self.cert_info['common_name'])
            
            # Crear CSR
            csr = x509.CertificateSigningRequestBuilder().subject_name(
                subject
            ).add_extension(
                x509.SubjectAlternativeName([
                    x509.IPAddress(ip_address),
                    x509.DNSName("deutsche-bank.com"),
                    x509.DNSName("db.com"),
                    x509.DNSName("ebanking.db.com"),
                ]),
                critical=False,
            ).add_extension(
                x509.KeyUsage(
                    digital_signature=True,
                    key_encipherment=True,
                    key_agreement=True,
                    key_cert_sign=False,
                    crl_sign=False,
                    content_commitment=False,
                    data_encipherment=False,
                    encipher_only=False,
                    decipher_only=False
                ),
                critical=True,
            ).add_extension(
                x509.ExtendedKeyUsage([
                    x509.oid.ExtendedKeyUsageOID.SERVER_AUTH,
                    x509.oid.ExtendedKeyUsageOID.CLIENT_AUTH,
                ]),
                critical=False,
            ).sign(private_key, hashes.SHA256(), default_backend())
            
            # Guardar CSR
            csr_path = os.path.join(self.output_dir, "deutsche_bank.csr")
            with open(csr_path, "wb") as f:
                f.write(csr.public_bytes(serialization.Encoding.PEM))
            
            print(f"✅ CSR guardado en: {csr_path}")
            return csr
            
        except Exception as e:
            print(f"❌ Error generando CSR: {e}")
            return None
    
    def create_self_signed_certificate(self, private_key):
        """Crea un certificado autofirmado"""
        print("🏛️ Generando certificado autofirmado...")
        
        try:
            # Crear subject (igual al issuer para certificado autofirmado)
            subject = issuer = x509.Name([
                x509.NameAttribute(NameOID.COUNTRY_NAME, self.cert_info['country']),
                x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, self.cert_info['state']),
                x509.NameAttribute(NameOID.LOCALITY_NAME, self.cert_info['city']),
                x509.NameAttribute(NameOID.ORGANIZATION_NAME, self.cert_info['organization']),
                x509.NameAttribute(NameOID.ORGANIZATIONAL_UNIT_NAME, self.cert_info['organizational_unit']),
                x509.NameAttribute(NameOID.COMMON_NAME, self.cert_info['common_name']),
                x509.NameAttribute(NameOID.EMAIL_ADDRESS, self.cert_info['email']),
            ])
            
            # Fechas de validez
            not_valid_before = datetime.utcnow()
            not_valid_after = not_valid_before + timedelta(days=self.cert_info['validity_days'])
            
            # Convertir IP a objeto ipaddress
            ip_address = ipaddress.IPv4Address(self.cert_info['common_name'])
            
            # Crear certificado
            certificate = x509.CertificateBuilder().subject_name(
                subject
            ).issuer_name(
                issuer
            ).public_key(
                private_key.public_key()
            ).serial_number(
                x509.random_serial_number()
            ).not_valid_before(
                not_valid_before
            ).not_valid_after(
                not_valid_after
            ).add_extension(
                x509.SubjectAlternativeName([
                    x509.IPAddress(ip_address),
                    x509.DNSName("deutsche-bank.com"),
                    x509.DNSName("db.com"),
                    x509.DNSName("ebanking.db.com"),
                ]),
                critical=False,
            ).add_extension(
                x509.KeyUsage(
                    digital_signature=True,
                    key_encipherment=True,
                    key_agreement=True,
                    key_cert_sign=True,
                    crl_sign=True,
                    content_commitment=False,
                    data_encipherment=False,
                    encipher_only=False,
                    decipher_only=False
                ),
                critical=True,
            ).add_extension(
                x509.ExtendedKeyUsage([
                    x509.oid.ExtendedKeyUsageOID.SERVER_AUTH,
                    x509.oid.ExtendedKeyUsageOID.CLIENT_AUTH,
                ]),
                critical=False,
            ).add_extension(
                x509.BasicConstraints(ca=True, path_length=None),
                critical=True,
            ).sign(private_key, hashes.SHA256(), default_backend())
            
            # Guardar certificado
            cert_path = os.path.join(self.output_dir, "deutsche_bank_certificate.pem")
            with open(cert_path, "wb") as f:
                f.write(certificate.public_bytes(serialization.Encoding.PEM))
            
            print(f"✅ Certificado autofirmado guardado en: {cert_path}")
            return certificate
            
        except Exception as e:
            print(f"❌ Error generando certificado: {e}")
            return None
    
    def create_pkcs12_bundle(self, private_key, certificate):
        """Crea un bundle PKCS#12 (.p12) para uso en aplicaciones"""
        print("📦 Generando bundle PKCS#12...")
        
        try:
            from cryptography.hazmat.primitives.serialization import pkcs12
            
            # Crear bundle PKCS#12
            p12_data = pkcs12.serialize_key_and_certificates(
                name=b"deutsche_bank",
                key=private_key,
                cert=certificate,
                cas=None,
                encryption_algorithm=serialization.NoEncryption()
            )
            
            # Guardar bundle
            p12_path = os.path.join(self.output_dir, "deutsche_bank.p12")
            with open(p12_path, "wb") as f:
                f.write(p12_data)
            
            print(f"✅ Bundle PKCS#12 guardado en: {p12_path}")
            return p12_path
            
        except Exception as e:
            print(f"❌ Error generando bundle PKCS#12: {e}")
            return None
    
    def create_openssl_config(self):
        """Crea archivo de configuración OpenSSL"""
        print("⚙️ Generando configuración OpenSSL...")
        
        config_content = f"""[req]
default_bits = {self.cert_info['key_size']}
default_keyfile = deutsche_bank_private_key.pem
default_md = sha256
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = {self.cert_info['country']}
ST = {self.cert_info['state']}
L = {self.cert_info['city']}
O = {self.cert_info['organization']}
OU = {self.cert_info['organizational_unit']}
CN = {self.cert_info['common_name']}
emailAddress = {self.cert_info['email']}

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = deutsche-bank.com
DNS.2 = db.com
DNS.3 = ebanking.db.com
IP.1 = {self.cert_info['common_name']}
"""
        
        config_path = os.path.join(self.output_dir, "openssl.conf")
        with open(config_path, "w") as f:
            f.write(config_content)
        
        print(f"✅ Configuración OpenSSL guardada en: {config_path}")
        return config_path
    
    def generate_openssl_commands(self):
        """Genera comandos OpenSSL para referencia"""
        print("�� Generando comandos OpenSSL de referencia...")
        
        commands = f"""# Comandos OpenSSL para generar certificados manualmente

# 1. Generar clave privada
openssl genrsa -out {self.output_dir}/deutsche_bank_private_key.pem {self.cert_info['key_size']}

# 2. Generar CSR
openssl req -new -key {self.output_dir}/deutsche_bank_private_key.pem -out {self.output_dir}/deutsche_bank.csr -config {self.output_dir}/openssl.conf

# 3. Generar certificado autofirmado
openssl x509 -req -in {self.output_dir}/deutsche_bank.csr -signkey {self.output_dir}/deutsche_bank_private_key.pem -out {self.output_dir}/deutsche_bank_certificate.pem -days {self.cert_info['validity_days']} -extensions v3_req -extfile {self.output_dir}/openssl.conf

# 4. Crear bundle PKCS#12
openssl pkcs12 -export -out {self.output_dir}/deutsche_bank.p12 -inkey {self.output_dir}/deutsche_bank_private_key.pem -in {self.output_dir}/deutsche_bank_certificate.pem

# 5. Verificar certificado
openssl x509 -in {self.output_dir}/deutsche_bank_certificate.pem -text -noout

# 6. Verificar CSR
openssl req -in {self.output_dir}/deutsche_bank.csr -text -noout
"""
        
        commands_path = os.path.join(self.output_dir, "openssl_commands.txt")
        with open(commands_path, "w") as f:
            f.write(commands)
        
        print(f"✅ Comandos OpenSSL guardados en: {commands_path}")
        return commands_path
    
    def create_python_client_example(self):
        """Crea ejemplo de cliente Python usando el certificado"""
        print("🐍 Generando ejemplo de cliente Python...")
        
        client_code = f'''#!/usr/bin/env python3
"""
Cliente Python de ejemplo para Deutsche Bank usando certificado TLS personalizado
"""

import ssl
import socket
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.ssl_ import create_urllib3_context

class DeutscheBankClient:
    def __init__(self, cert_path, key_path):
        self.cert_path = cert_path
        self.key_path = key_path
        
    def create_ssl_context(self):
        """Crea contexto SSL con certificado personalizado"""
        context = ssl.create_default_context(ssl.Purpose.SERVER_AUTH)
        context.load_cert_chain(self.cert_path, self.key_path)
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        return context
    
    def connect_with_socket(self, hostname="193.150.166.1", port=443):
        """Conecta usando socket con certificado personalizado"""
        try:
            context = self.create_ssl_context()
            
            with socket.create_connection((hostname, port), timeout=10) as sock:
                with context.wrap_socket(sock, server_hostname=hostname) as ssock:
                    print(f"✅ Conexión exitosa a {{hostname}}:{{port}}")
                    print(f"🔒 Versión TLS: {{ssock.version()}}")
                    print(f"�� Cipher suite: {{ssock.cipher()}}")
                    
                    # Obtener certificado del servidor
                    cert = ssock.getpeercert()
                    print(f"📜 Certificado del servidor:")
                    print(f"   - Subject: {{cert.get('subject', 'N/A')}}")
                    print(f"   - Issuer: {{cert.get('issuer', 'N/A')}}")
                    
                    return True
                    
        except Exception as e:
            print(f"❌ Error de conexión: {{e}}")
            return False
    
    def connect_with_requests(self, url="https://193.150.166.1:443"):
        """Conecta usando requests con certificado personalizado"""
        try:
            session = requests.Session()
            
            # Configurar certificado
            session.cert = (self.cert_path, self.key_path)
            session.verify = False
            
            # Realizar request
            response = session.get(url, timeout=10)
            print(f"✅ Request exitoso: {{response.status_code}}")
            return response
            
        except Exception as e:
            print(f"❌ Error en request: {{e}}")
            return None

# Ejemplo de uso
if __name__ == "__main__":
    client = DeutscheBankClient(
        cert_path="{self.output_dir}/deutsche_bank_certificate.pem",
        key_path="{self.output_dir}/deutsche_bank_private_key.pem"
    )
    
    # Conectar usando socket
    client.connect_with_socket()
    
    # Conectar usando requests
    # client.connect_with_requests()
'''
        
        client_path = os.path.join(self.output_dir, "deutsche_bank_client_example.py")
        with open(client_path, "w") as f:
            f.write(client_code)
        
        print(f"✅ Ejemplo de cliente Python guardado en: {client_path}")
        return client_path
    
    def create_readme(self):
        """Crea archivo README con instrucciones"""
        print("📖 Generando archivo README...")
        
        readme_content = f"""# Certificados TLS para Deutsche Bank

Este directorio contiene certificados TLS personalizados para conectarse al servidor Deutsche Bank.

## �� Archivos generados:

- `deutsche_bank_private_key.pem` - Clave privada RSA de {self.cert_info['key_size']} bits
- `deutsche_bank_certificate.pem` - Certificado autofirmado
- `deutsche_bank.csr` - Certificate Signing Request
- `deutsche_bank.p12` - Bundle PKCS#12 para aplicaciones
- `openssl.conf` - Configuración OpenSSL
- `openssl_commands.txt` - Comandos OpenSSL de referencia
- `deutsche_bank_client_example.py` - Ejemplo de cliente Python

## 🔧 Información del certificado:

- **País**: {self.cert_info['country']}
- **Estado**: {self.cert_info['state']}
- **Ciudad**: {self.cert_info['city']}
- **Organización**: {self.cert_info['organization']}
- **Unidad Organizacional**: {self.cert_info['organizational_unit']}
- **Nombre común**: {self.cert_info['common_name']}
- **Email**: {self.cert_info['email']}
- **Validez**: {self.cert_info['validity_days']} días
- **Tamaño de clave**: {self.cert_info['key_size']} bits

## 🚀 Uso:

### Con Python:
```python
import ssl
import socket

context = ssl.create_default_context()
context.load_cert_chain('deutsche_bank_certificate.pem', 'deutsche_bank_private_key.pem')

with socket.create_connection(('193.150.166.1', 443)) as sock:
    with context.wrap_socket(sock) as ssock:
        # Tu código aquí
        pass
```

### Con OpenSSL:
```bash
openssl s_client -connect 193.150.166.1:443 -cert deutsche_bank_certificate.pem -key deutsche_bank_private_key.pem
```

### Con curl:
```bash
curl --cert deutsche_bank_certificate.pem --key deutsche_bank_private_key.pem https://193.150.166.1:443
```

## ⚠️ Notas importantes:

1. Este es un certificado autofirmado para propósitos de desarrollo/pruebas
2. Para producción, use certificados emitidos por una autoridad certificadora confiable
3. El certificado incluye Subject Alternative Names para compatibilidad
4. Compatible con TLS 1.3 y AES-256-GCM

## 🔒 Seguridad:

- Clave privada de {self.cert_info['key_size']} bits
- Algoritmo de firma: SHA-256
- Extensión Key Usage configurada para autenticación de servidor y cliente
- Subject Alternative Names incluidos para múltiples dominios/IPs

Generado el: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""
        
        readme_path = os.path.join(self.output_dir, "README.md")
        with open(readme_path, "w") as f:
            f.write(readme_content)
        
        print(f"✅ README guardado en: {readme_path}")
        return readme_path
    
    def generate_all(self):
        """Genera todos los archivos necesarios"""
        print("🏦 GENERADOR DE CERTIFICADOS TLS - DEUTSCHE BANK")
        print("=" * 60)
        print(f"📅 Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        # 1. Generar clave privada
        private_key = self.generate_private_key()
        if not private_key:
            return False
        
        # 2. Generar CSR
        csr = self.create_certificate_signing_request(private_key)
        if not csr:
            return False
        
        # 3. Generar certificado autofirmado
        certificate = self.create_self_signed_certificate(private_key)
        if not certificate:
            return False
        
        # 4. Generar bundle PKCS#12
        self.create_pkcs12_bundle(private_key, certificate)
        
        # 5. Generar archivos de configuración
        self.create_openssl_config()
        self.generate_openssl_commands()
        
        # 6. Generar ejemplos
        self.create_python_client_example()
        self.create_readme()
        
        print(f"\n✅ Todos los archivos generados en: {self.output_dir}")
        print(f"📋 Revisa el archivo README.md para instrucciones de uso")
        
        return True

def main():
    """Función principal"""
    # Verificar dependencias
    try:
        from cryptography import x509
    except ImportError:
        print("❌ Error: La librería 'cryptography' no está instalada")
        print("�� Instálala con: pip install cryptography")
        sys.exit(1)
    
    # Crear generador y ejecutar
    generator = DeutscheBankCertificateGenerator()
    success = generator.generate_all()
    
    if success:
        print("\n🎉 Certificados TLS generados exitosamente!")
        print("🔐 Los certificados están listos para usar con Deutsche Bank")
    else:
        print("\n❌ Error generando certificados")

if __name__ == "__main__":
    main()