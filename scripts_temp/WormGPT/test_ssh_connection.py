#!/usr/bin/env python3
"""
Script de prueba para verificar conectividad SSH
Útil para diagnosticar problemas antes de ejecutar ataques de fuerza bruta
"""

import socket
import paramiko
import argparse
import sys
import time
from datetime import datetime

def test_port_connectivity(ip, port, timeout=5):
    """Probar conectividad básica del puerto"""
    print(f"🔍 Probando conectividad a {ip}:{port}...")
    
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        start_time = time.time()
        result = sock.connect_ex((ip, port))
        connect_time = time.time() - start_time
        sock.close()
        
        if result == 0:
            print(f"✅ Puerto {port} está abierto (tiempo de conexión: {connect_time:.3f}s)")
            return True
        else:
            print(f"❌ Puerto {port} está cerrado o no responde")
            return False
            
    except Exception as e:
        print(f"❌ Error de conectividad: {e}")
        return False

def test_ssh_banner(ip, port, timeout=5):
    """Probar y obtener el banner SSH"""
    print(f"🔍 Obteniendo banner SSH...")
    
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        sock.connect((ip, port))
        
        # Enviar identificación SSH
        sock.send(b"SSH-2.0-Test\n")
        
        # Recibir respuesta
        banner = sock.recv(1024).decode().strip()
        sock.close()
        
        if banner:
            print(f"✅ Banner SSH: {banner}")
            return banner
        else:
            print("⚠️  No se recibió banner SSH")
            return None
            
    except Exception as e:
        print(f"❌ Error obteniendo banner: {e}")
        return None

def test_ssh_connection(ip, port, username, password, timeout=5):
    """Probar conexión SSH con credenciales específicas"""
    print(f"🔍 Probando credenciales: {username}:{password}")
    
    client = None
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        start_time = time.time()
        client.connect(
            ip, 
            port=port, 
            username=username, 
            password=password, 
            timeout=timeout,
            banner_timeout=timeout,
            auth_timeout=timeout
        )
        connect_time = time.time() - start_time
        
        print(f"✅ Conexión SSH exitosa! (tiempo: {connect_time:.3f}s)")
        
        # Probar comando simple
        try:
            stdin, stdout, stderr = client.exec_command('whoami', timeout=5)
            user = stdout.read().decode().strip()
            print(f"✅ Usuario actual: {user}")
        except Exception as e:
            print(f"⚠️  No se pudo ejecutar comando: {e}")
        
        return True
        
    except paramiko.AuthenticationException:
        print("❌ Autenticación fallida")
        return False
    except paramiko.SSHException as e:
        print(f"❌ Error SSH: {e}")
        return False
    except socket.error as e:
        print(f"❌ Error de socket: {e}")
        return False
    except Exception as e:
        print(f"❌ Error inesperado: {e}")
        return False
    finally:
        if client:
            try:
                client.close()
            except:
                pass

def test_ssh_versions(ip, port):
    """Probar diferentes versiones de SSH"""
    print(f"🔍 Probando diferentes versiones SSH...")
    
    versions = [
        "SSH-2.0-OpenSSH_8.9",
        "SSH-2.0-OpenSSH_8.4",
        "SSH-2.0-OpenSSH_7.9",
        "SSH-2.0-OpenSSH_7.4",
        "SSH-2.0-OpenSSH_6.9",
        "SSH-2.0-OpenSSH_5.9",
        "SSH-1.99-OpenSSH_3.9",
        "SSH-2.0-SSHD"
    ]
    
    for version in versions:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(3)
            sock.connect((ip, port))
            sock.send(f"{version}\n".encode())
            
            response = sock.recv(1024).decode().strip()
            sock.close()
            
            if response:
                print(f"✅ {version} -> {response}")
            else:
                print(f"⚠️  {version} -> Sin respuesta")
                
        except Exception as e:
            print(f"❌ {version} -> Error: {e}")

def main():
    parser = argparse.ArgumentParser(
        description="Script de prueba para conectividad SSH",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos de uso:
  %(prog)s 192.168.1.1
  %(prog)s 10.0.0.1 --port 2222
  %(prog)s 172.16.0.1 --test-credentials admin password
  %(prog)s 192.168.1.100 --full-test
        """
    )
    
    parser.add_argument("ip", help="IP del servidor")
    parser.add_argument("--port", type=int, default=22, help="Puerto SSH (default: 22)")
    parser.add_argument("--timeout", type=int, default=5, help="Timeout en segundos (default: 5)")
    parser.add_argument("--test-credentials", nargs=2, metavar=('USER', 'PASS'),
                       help="Probar credenciales específicas")
    parser.add_argument("--full-test", action="store_true",
                       help="Ejecutar todas las pruebas")
    parser.add_argument("--test-versions", action="store_true",
                       help="Probar diferentes versiones SSH")
    
    args = parser.parse_args()
    
    print("🔧 Script de prueba de conectividad SSH")
    print("=" * 50)
    print(f"🎯 Objetivo: {args.ip}:{args.port}")
    print(f"⏱️  Timeout: {args.timeout}s")
    print(f"📅 Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Prueba básica de conectividad
    if not test_port_connectivity(args.ip, args.port, args.timeout):
        print("\n❌ No se puede conectar al puerto. Verifica:")
        print("   - La IP es correcta")
        print("   - El puerto está abierto")
        print("   - No hay firewall bloqueando")
        return 1
    
    print()
    
    # Prueba de banner SSH
    banner = test_ssh_banner(args.ip, args.port, args.timeout)
    
    print()
    
    # Prueba de versiones SSH
    if args.test_versions or args.full_test:
        test_ssh_versions(args.ip, args.port)
        print()
    
    # Prueba de credenciales específicas
    if args.test_credentials:
        username, password = args.test_credentials
        test_ssh_connection(args.ip, args.port, username, password, args.timeout)
        print()
    
    # Prueba completa
    if args.full_test:
        print("🔍 Ejecutando prueba completa...")
        
        # Probar credenciales comunes
        common_creds = [
            ("root", "root"),
            ("admin", "admin"),
            ("admin", "password"),
            ("root", "password"),
            ("test", "test")
        ]
        
        for user, pwd in common_creds:
            if test_ssh_connection(args.ip, args.port, user, pwd, args.timeout):
                print(f"🎉 ¡Credenciales válidas encontradas: {user}:{pwd}")
                break
            time.sleep(1)  # Pausa entre intentos
    
    print("\n✅ Pruebas completadas")
    return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n⚠️  Pruebas interrumpidas por el usuario")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error inesperado: {e}")
        sys.exit(1)
