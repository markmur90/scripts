#!/usr/bin/env python3
"""
Script de verificación de certificados TLS para Deutsche Bank
Autor: Sistema de Análisis de Scripts Bancarios
Fecha: 2024
"""

import ssl
import socket
import dns.resolver
import dns.reversename
import subprocess
import sys
from datetime import datetime
from pprint import pprint

def get_dns_info(ip_address):
    """Obtiene información DNS de una IP"""
    print(f"🔍 Analizando DNS para IP: {ip_address}")
    print("=" * 60)
    
    try:
        # Reverse DNS lookup
        reverse_name = dns.reversename.from_address(ip_address)
        print(f"�� Reverse DNS lookup: {reverse_name}")
        
        # Intentar resolver el nombre
        try:
            answers = dns.resolver.resolve(reverse_name, "PTR")
            print(f"✅ Nombre de dominio: {answers[0]}")
        except dns.resolver.NXDOMAIN:
            print("❌ No se encontró nombre de dominio para esta IP")
        except dns.resolver.NoAnswer:
            print("❌ No hay respuesta DNS para esta IP")
            
    except Exception as e:
        print(f"❌ Error en reverse DNS: {e}")
    
    # Información adicional de la IP
    print(f"\n�� Información de red:")
    print(f"   - IP: {ip_address}")
    print(f"   - Puerto objetivo: 443 (HTTPS)")
    print(f"   - Protocolo: TLS/SSL")
    
    # Verificar si la IP está en el rango conocido
    ip_parts = ip_address.split('.')
    if ip_parts[0:3] == ['193', '150', '166']:
        print(f"   - Rango: 193.150.166.0/24 (Deutsche Bank)")
        print(f"   - Banco: Deutsche Bank")
    else:
        print(f"   - Rango: Desconocido")
    
    print("=" * 60)

def check_port_status(hostname, port):
    """Verifica si el puerto está abierto"""
    print(f"�� Verificando puerto {port} en {hostname}...")
    
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((hostname, port))
        sock.close()
        
        if result == 0:
            print(f"✅ Puerto {port} está ABIERTO")
            return True
        else:
            print(f"❌ Puerto {port} está CERRADO")
            return False
    except Exception as e:
        print(f"❌ Error verificando puerto: {e}")
        return False

def get_certificate_details(cert):
    """Extrae detalles específicos del certificado"""
    details = {}
    
    # Subject
    if 'subject' in cert:
        subject = cert['subject']
        for item in subject:
            if item[0][0] == 'commonName':
                details['common_name'] = item[0][1]
            elif item[0][0] == 'organizationName':
                details['organization'] = item[0][1]
            elif item[0][0] == 'countryName':
                details['country'] = item[0][1]
    
    # Issuer
    if 'issuer' in cert:
        issuer = cert['issuer']
        for item in issuer:
            if item[0][0] == 'commonName':
                details['issuer_name'] = item[0][1]
            elif item[0][0] == 'organizationName':
                details['issuer_org'] = item[0][1]
    
    # Fechas
    details['valid_from'] = cert.get('notBefore', 'N/A')
    details['valid_until'] = cert.get('notAfter', 'N/A')
    
    # SAN (Subject Alternative Names)
    if 'subjectAltName' in cert:
        details['san'] = cert['subjectAltName']
    
    return details

def check_certificate_security(cert_details):
    """Evalúa la seguridad del certificado"""
    print(f"\n🛡️ Análisis de seguridad del certificado:")
    print("-" * 40)
    
    # Verificar fechas
    if cert_details['valid_until'] != 'N/A':
        try:
            from datetime import datetime
            valid_until = datetime.strptime(cert_details['valid_until'], '%b %d %H:%M:%S %Y %Z')
            now = datetime.now()
            
            if valid_until > now:
                days_left = (valid_until - now).days
                print(f"✅ Certificado válido por {days_left} días más")
                
                if days_left < 30:
                    print("⚠️  ADVERTENCIA: Certificado expira pronto")
                elif days_left < 7:
                    print("🚨 CRÍTICO: Certificado expira en menos de una semana")
            else:
                print("❌ Certificado EXPIRADO")
        except:
            print("❓ No se pudo verificar la fecha de expiración")
    
    # Verificar issuer
    if cert_details.get('issuer_org'):
        trusted_issuers = ['DigiCert', 'Let\'s Encrypt', 'GlobalSign', 'Comodo', 'Verisign']
        issuer_org = cert_details['issuer_org']
        if any(trusted in issuer_org for trusted in trusted_issuers):
            print(f"✅ Emisor confiable: {issuer_org}")
        else:
            print(f"⚠️  Emisor no reconocido: {issuer_org}")

def connect_with_ssl_verification(hostname, port, verify_ssl=True):
    """Conecta con diferentes niveles de verificación SSL"""
    print(f"\n🔍 Intentando conexión SSL/TLS a: {hostname}:{port}")
    print(f"🔒 Verificación SSL: {'HABILITADA' if verify_ssl else 'DESHABILITADA'}")
    print("-" * 50)
    
    try:
        # Crear contexto SSL
        if verify_ssl:
            context = ssl.create_default_context()
        else:
            context = ssl.create_default_context()
            context.check_hostname = False
            context.verify_mode = ssl.CERT_NONE
            print("⚠️  ADVERTENCIA: Verificación SSL deshabilitada")
        
        with socket.create_connection((hostname, port), timeout=15) as sock:
            with context.wrap_socket(sock, server_hostname=hostname) as ssock:
                print(f"✅ Conexión SSL/TLS exitosa")
                print(f"🔒 Versión TLS: {ssock.version()}")
                print(f"🔐 Cipher suite: {ssock.cipher()}")
                print(f"�� Longitud de clave: {ssock.cipher()[2]} bits")
                
                # Obtener certificado
                cert = ssock.getpeercert()
                
                # Mostrar certificado completo
                print(f"\n📜 Certificado del servidor:")
                print("-" * 30)
                pprint(cert)
                
                # Extraer detalles específicos
                cert_details = get_certificate_details(cert)
                
                # Mostrar información resumida
                print(f"\n📋 Información resumida del certificado:")
                print("-" * 40)
                print(f"   - Nombre común: {cert_details.get('common_name', 'N/A')}")
                print(f"   - Organización: {cert_details.get('organization', 'N/A')}")
                print(f"   - País: {cert_details.get('country', 'N/A')}")
                print(f"   - Emisor: {cert_details.get('issuer_name', 'N/A')}")
                print(f"   - Organización emisora: {cert_details.get('issuer_org', 'N/A')}")
                print(f"   - Válido desde: {cert_details.get('valid_from', 'N/A')}")
                print(f"   - Válido hasta: {cert_details.get('valid_until', 'N/A')}")
                
                # Verificar SAN si existe
                if cert_details.get('san'):
                    print(f"   - Nombres alternativos: {cert_details['san']}")
                
                # Análisis de seguridad
                check_certificate_security(cert_details)
                
                # Información de la conexión
                print(f"\n🌐 Información de la conexión:")
                print("-" * 30)
                print(f"   - IP remota: {ssock.getpeername()}")
                print(f"   - Puerto local: {ssock.getsockname()}")
                print(f"   - Protocolo: {ssock.version()}")
                
                return True
                
    except ssl.SSLError as e:
        print(f"🔒 Error SSL/TLS: {e}")
        if verify_ssl:
            print("�� Intentando con verificación SSL deshabilitada...")
            return connect_with_ssl_verification(hostname, port, verify_ssl=False)
        else:
            print("💡 No se pudo establecer conexión SSL incluso sin verificación")
            return False
    except Exception as e:
        print(f"❌ Error inesperado: {e}")
        return False

def main():
    """Función principal"""
    print("🏦 VERIFICADOR DE CERTIFICADOS TLS - DEUTSCHE BANK")
    print("=" * 60)
    print(f"📅 Fecha y hora: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Configuración del servidor Deutsche Bank
    hostname = "193.150.166.1"  # IP real del Deutsche Bank
    port = 443
    
    # 1. Obtener información DNS
    get_dns_info(hostname)
    
    # 2. Verificar si el puerto está abierto
    if not check_port_status(hostname, port):
        print(f"\n❌ No se puede continuar. El puerto {port} está cerrado.")
        return
    
    # 3. Intentar conexión SSL/TLS con verificación
    success = connect_with_ssl_verification(hostname, port, verify_ssl=True)
    
    if not success:
        print(f"\n❌ No se pudo establecer conexión SSL/TLS con {hostname}:{port}")
        print("💡 Posibles causas:")
        print("   - El servidor no soporta SSL/TLS")
        print("   - El certificado es inválido o autofirmado")
        print("   - Problemas de configuración de red")
        print("   - Firewall bloqueando la conexión")
    
    print(f"\n🏁 Análisis completado: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    # Verificar si dnspython está instalado
    try:
        import dns.resolver
    except ImportError:
        print("❌ Error: La librería 'dnspython' no está instalada")
        print("�� Instálala con: pip install dnspython")
        sys.exit(1)
    
    main()