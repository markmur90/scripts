#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
03_ssh_key_setup_tor.py (refactor)
Automatiza: generar clave SSH, copiar la clave al VPS a través de Tor (SOCKS5) y verificar la conexión.
- Listado de todas las claves SSH existentes y opción de selección o creación con sufijo.
- Corregido ProxyCommand para que %h y %p se expandan correctamente usando sh -c 'exec'.
- Deploy inteligente: intenta primero detectar si la clave ya funciona, si no, copia usando contraseña; si falla, sugiere Habilitar PasswordAuthentication.
- Modo interactivo por defecto, CLI opcional con argparse.
- Opciones de retry para renovación de IP.
- Logs detallados y silenciamiento de DEBUG de Stem.
"""

import os
import sys
import time
import socket
import subprocess
import getpass
import logging
import argparse
from typing import Optional, Tuple, List

from stem import Signal
from stem.control import Controller

# ------------------------- Configuración -------------------------
logging.basicConfig(format="[%(levelname)s] %(message)s", level=logging.INFO)
logging.getLogger('stem').setLevel(logging.ERROR)

SOCKS_HOST = '127.0.0.1'
SOCKS_PORT = 9050
CONTROL_PORT = 9051
SSH_CONNECT_TIMEOUT = 90      # Timeout para -o ConnectTimeout
SSH_CMD_TIMEOUT = 300         # Timeout global para subprocess
PROXY_TEMPLATES = [
    'ncat --proxy {h}:{p} --proxy-type socks5 %h %p',
    'nc.openbsd -X 5 -x {h}:{p} %h %p',
    'nc -X 5 -x {h}:{p} %h %p'
]
SSH_DIR = os.path.expanduser('~/.ssh')
DEFAULT_KEY_BASE = os.path.join(SSH_DIR, 'id_ed25519')
RENEW_RETRIES = 3

# ------------------------- Utilidades -------------------------

def info(msg: str) -> None:
    logging.info(msg)

def error(msg: str) -> None:
    logging.error(msg)


def run_cmd(cmd: list, timeout: Optional[int] = None) -> Tuple[int, str, str]:
    try:
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              text=True, timeout=timeout)
        return proc.returncode, proc.stdout.strip(), proc.stderr.strip()
    except Exception as e:
        return 1, '', str(e)

# ------------------------- Gestión de Claves -------------------------

def list_ssh_keys() -> List[str]:
    """Lista en ~/.ssh los pares privada/.pub"""
    keys = []
    if os.path.isdir(SSH_DIR):
        for name in os.listdir(SSH_DIR):
            priv = os.path.join(SSH_DIR, name)
            pub = priv + '.pub'
            if os.path.isfile(priv) and not name.endswith('.pub') and os.path.exists(pub):
                keys.append(priv)
    return sorted(keys)


def select_or_new_key() -> str:
    existing = list_ssh_keys()
    if existing:
        info("Claves SSH existentes:")
        for i, k in enumerate(existing, 1):
            print(f"  {i}) {k}")
        print(f"  {len(existing)+1}) Crear nueva clave")
        choice = input(f"Selecciona [1-{len(existing)+1}]: ").strip()
        try:
            idx = int(choice)
            if 1 <= idx <= len(existing):
                return existing[idx-1]
        except ValueError:
            pass
    suffix = input(f"  • Sufijo para la nueva clave [{DEFAULT_KEY_BASE}]: ").strip()
    return f"{DEFAULT_KEY_BASE}{suffix}" if suffix else DEFAULT_KEY_BASE

# ------------------------- Entrada / CLI -------------------------

def gather_args() -> Tuple[str, int, str, str, str, str, str]:
    parser = argparse.ArgumentParser(description="Setup SSH key over Tor SOCKS5")
    parser.add_argument('--ip',   help='IP o hostname del VPS')
    parser.add_argument('--port', type=int, default=22, help='Puerto SSH (defecto: 22)')
    parser.add_argument('--user', help='Usuario SSH')
    parser.add_argument('--key', help='Ruta a clave SSH existente')
    parser.add_argument('--suffix', default='', help='Sufijo para nueva clave')
    parser.add_argument('--batch', action='store_true', help='Modo sin interactividad')
    args = parser.parse_args()

    if not args.ip or not args.user:
        # interactivo completo
        return gather_inputs_interactive()

    ssh_pass = getpass.getpass('Contraseña SSH: ') if not args.batch else ''
    tor_pass = getpass.getpass('ControlPort Tor (vacío si no): ') if not args.batch else ''
    if args.key:
        key_path = args.key
    elif args.suffix:
        key_path = f"{DEFAULT_KEY_BASE}{args.suffix}"
    else:
        key_path = select_or_new_key()
    passphrase = getpass.getpass('Frase de paso (vacío si no): ') if not args.batch else ''
    info(f"VPS {args.ip}:{args.port} | Usuario: {args.user} | Clave: {key_path} | Passphrase: {'sí' if passphrase else 'no'}")
    return args.ip, args.port, args.user, ssh_pass, tor_pass, key_path, passphrase


def gather_inputs_interactive() -> Tuple[str, int, str, str, str, str, str]:
    info("Introduce los datos de conexión:")
    ip = input('  • IP del VPS: ').strip()
    port_str = input('  • Puerto SSH [22]: ').strip() or '22'
    user = input('  • Usuario SSH: ').strip()
    ssh_pass = getpass.getpass('  • Contraseña SSH: ')
    tor_pass = getpass.getpass('  • ControlPort Tor (vacío si no): ')
    key_path = select_or_new_key()
    passphrase = getpass.getpass('  • Frase de paso (vacío si no): ')
    info(f"VPS {ip}:{port_str} | Usuario: {user} | Clave: {key_path} | Passphrase: {'sí' if passphrase else 'no'}")
    return ip, int(port_str), user, ssh_pass, tor_pass, key_path, passphrase

# ------------------------- Funciones SSH -------------------------

def ensure_tor() -> None:
    info("Reiniciando servicio Tor para circuito fresco...")
    subprocess.run(['sudo', 'service', 'tor', 'restart'], stdout=subprocess.DEVNULL)
    time.sleep(15)


def renew_tor_ip(control_pass: str) -> bool:
    for attempt in range(1, RENEW_RETRIES + 1):
        info(f"Intento {attempt} de renovación de IP Tor...")
        try:
            with Controller.from_port(port=CONTROL_PORT) as ctl:  # type: ignore
                ctl.authenticate(password=control_pass) if control_pass else ctl.authenticate()
                ctl.signal(Signal.NEWNYM)  # type: ignore
            info("IP de Tor renovada correctamente")
            return True
        except Exception as exc:
            error(f"Error renovación Tor: {exc}")
            time.sleep(5)
    return False


def check_socks() -> bool:
    info(f"Verificando proxy SOCKS5 en {SOCKS_HOST}:{SOCKS_PORT}...")
    try:
        socket.create_connection((SOCKS_HOST, SOCKS_PORT), timeout=5)
        info("Proxy SOCKS5 disponible")
        return True
    except Exception as exc:
        error(f"Proxy SOCKS5 inaccesible: {exc}")
        return False


def select_proxy_cmd() -> Optional[str]:
    for tpl in PROXY_TEMPLATES:
        cmd_line = tpl.format(h=SOCKS_HOST, p=SOCKS_PORT)
        prog = cmd_line.split()[0]
        if run_cmd(['which', prog])[0] == 0:
            wrapped = f"sh -c 'exec {cmd_line}'"
            info(f"Usando ProxyCommand: {wrapped}")
            return wrapped
    error("No se encontró comando proxy válido en el sistema")
    return None


def gen_ssh_key(path: str, passphrase: str) -> bool:
    pub = f"{path}.pub"
    if os.path.exists(path) and os.path.exists(pub):
        info("Clave SSH ya existe, se conserva")
        return True
    code, _, err = run_cmd(['ssh-keygen', '-t', 'ed25519', '-f', path, '-N', passphrase, '-q'])
    if code == 0:
        info("Par de claves SSH generado con éxito")
        return True
    error(f"Fallo al generar clave SSH: {err}")
    return False


def test_connection(ip: str, port: int, user: str, key: str, proxy_cmd: str) -> bool:
    """Intenta conectar con la clave. Devuelve True si funciona."""
    ssh_cmd = [
        'ssh', '-i', key, '-p', str(port),
        '-o', f"ProxyCommand={proxy_cmd}",
        '-o', 'StrictHostKeyChecking=no',
        f"{user}@{ip}", 'echo OK'
    ]
    code, out, _ = run_cmd(ssh_cmd, timeout=SSH_CMD_TIMEOUT)
    return code == 0 and out.strip() == 'OK'


def deploy_key(ip: str, port: int, user: str, key: str, passwd: str, proxy_cmd: str) -> bool:
    """Copia la clave al servidor via contraseña (sshpass)."""
    # Si no se proporcionó contraseña en gather, solicitar de nuevo aquí
    if not passwd:
        passwd = getpass.getpass('Contraseña SSH para despliegue: ')
    info("Instalando clave en el VPS usando contraseña...")
    pub = open(f"{key}.pub").read().strip()
    remote_cmd = (
        "mkdir -p ~/.ssh && chmod 700 ~/.ssh && "
        f"echo '{pub}' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    )
    # Forzar autenticación por contraseña si el servidor no acepta clave
    ssh_cmd = [
        'sshpass', '-p', passwd,
        'ssh', '-4', '-p', str(port),
        '-o', f"ProxyCommand={proxy_cmd}",
        '-o', 'StrictHostKeyChecking=no',
        '-o', 'PubkeyAuthentication=no',         # Deshabilita clave pública
        '-o', 'PreferredAuthentications=password',  # Solo password
        '-o', 'PasswordAuthentication=yes',         # Habilita PasswordAuthentication
        f"{user}@{ip}", remote_cmd
    ]
    code, out, err = run_cmd(ssh_cmd, timeout=SSH_CMD_TIMEOUT)
    if code == 0:
        info(out or "Clave instalada correctamente en el VPS")
        return True
    error(f"Error instalando clave: {err if err else out}")
    return False

# ------------------------- Flujo Principal -------------------------
if __name__ == '__main__':
    ip, port, user, ssh_pass, tor_pass, key_path, passphrase = gather_args()
    ensure_tor()
    if not renew_tor_ip(tor_pass): sys.exit(1)
    if not check_socks(): sys.exit(2)
    proxy_cmd = select_proxy_cmd()
    if not proxy_cmd: sys.exit(3)
    # Primero, si la clave ya funciona, no necesitamos deploy
    if test_connection(ip, port, user, key_path, proxy_cmd):
        print("[+] La clave ya está autorizada y funciona. Saltando instalación.")
    else:
        # Intentar copiar clave via contraseña
        if not deploy_key(ip, port, user, key_path, ssh_pass, proxy_cmd):
            error("No fue posible desplegar la clave. Asegúrate de que PasswordAuthentication esté habilitado en el servidor SSH del VPS.")
            sys.exit(5)
        # Verificar después del deploy
        if not test_connection(ip, port, user, key_path, proxy_cmd):
            error("La clave se copió pero aún no funciona. Comprueba permisos y configuración de SSH en el servidor.")
            sys.exit(6)
    print("\n[+] ¡Todo listo! Conexión SSH via Tor configurada correctamente.")
