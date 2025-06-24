#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ssh_key_setup_tor.py
Automatiza: generar clave SSH, copiar la clave al VPS a través de Tor (SOCKS5) y verificar la conexión.
Interactividad total, mensajes claros y concisos.
"""

import os
import sys
import time
import socket
import subprocess
import getpass
import logging
from typing import Optional

from stem import Signal
from stem.control import Controller

# Configuración de logging minimalista
tq = logging.getLogger()
tq.setLevel(logging.ERROR)  # silencia logs de librerías externas

# Parámetros de Tor y SSH
default_key = os.path.expanduser('~/.ssh/id_ed25519')
SOCKS_HOST, SOCKS_PORT = '127.0.0.1', 9050
CONTROL_PORT = 9051
SSH_CONNECT_TIMEOUT = 90
SSH_OVERALL_TIMEOUT = 300
PROXY_TEMPLATES = [
    'ncat --proxy {h}:{p} --proxy-type socks5 %h %p',
    'nc.openbsd -X 5 -x {h}:{p} %h %p',
    'nc -X 5 -x {h}:{p} %h %p'
]

# Utilidades de impresión

def info(msg): print(f"[+] {msg}")
def error(msg): print(f"[!] {msg}")

def run_cmd(cmd, **kwargs):
    """Ejecuta comando y devuelve (code, stdout, stderr)."""
    try:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             text=True, **kwargs)
        return res.returncode, res.stdout.strip(), res.stderr.strip()
    except Exception as e:
        return 1, '', str(e)

# Paso 1: Recolectar datos
def gather_inputs():
    info("Por favor, ingresa los datos de conexión:")
    ip = input(' • IP del VPS: ').strip()
    port = input(f' • Puerto SSH [{22}]: ').strip() or '22'
    user = input(' • Usuario SSH: ').strip()
    ssh_pass = getpass.getpass(' • Contraseña SSH: ')
    tor_pass = getpass.getpass(' • Contraseña ControlPort Tor (si no tienes, presiona Enter): ')
    key_path = input(f' • Ruta clave privada [{default_key}]: ').strip() or default_key
    passphrase = getpass.getpass(' • Frase de paso (si quieres, presiona Enter): ')
    print('')
    info(f"Entradas:")
    print(f"    VPS: {ip}:{port}  Usuario: {user}")
    print(f"    Clave: {key_path}  Passphrase: {'<con passphrase>' if passphrase else '<sin passphrase>'}\n")
    return ip, int(port), user, ssh_pass, tor_pass, key_path, passphrase

# Paso 2: Asegurar Tor y renovar IP
def ensure_tor():
    info("Iniciando/reiniciando Tor para nuevo circuito...")
    subprocess.run(['sudo','service','tor','restart'], stdout=subprocess.DEVNULL)
    time.sleep(15)

# Paso 3: Chequear proxy SOCKS5
def check_socks():
    info(f"Verificando proxy SOCKS5 en {SOCKS_HOST}:{SOCKS_PORT}...")
    try:
        socket.create_connection((SOCKS_HOST, SOCKS_PORT), timeout=5)
        info("Proxy SOCKS5 OK")
        return True
    except Exception as e:
        error(f"Proxy SOCKS5 inaccesible: {e}")
        return False

# Paso 4: Seleccionar comando ProxyCommand
def get_proxy_cmd():
    for tpl in PROXY_TEMPLATES:
        cmd = tpl.format(h=SOCKS_HOST, p=SOCKS_PORT)
        prog = cmd.split()[0]
        if run_cmd(['which', prog])[0] == 0:
            info(f"Usando proxy: {prog}")
            return f"sh -c 'exec {cmd}'"
    error("No se encontró comando proxy válido (ncat/nc.openbsd/nc).")
    return None

# Paso 5: Generar clave SSH
def gen_key(path, passphrase):
    info("Generando par de claves SSH... (si existe, se conserva)")
    pub = f"{path}.pub"
    if os.path.exists(path) and os.path.exists(pub):
        info("Clave existente encontrada.")
        return True
    code, _, err = run_cmd(['ssh-keygen','-t','ed25519','-f',path,'-N',passphrase,'-q'], check=True)
    if code == 0:
        info("Clave SSH generada correctamente.")
        return True
    error(f"Error generando clave: {err}")
    return False

# Paso 6: Copiar clave al VPS
def deploy_key(ip, port, user, key_path, ssh_pass, proxy_cmd):
    info("Instalando clave pública en el VPS...")
    pubkey = open(f"{key_path}.pub").read().strip()
    remote_cmd = (
        "mkdir -p ~/.ssh && chmod 700 ~/.ssh && "
        f"echo '{pubkey}' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    )
    cmd = [
        'sshpass', '-p', ssh_pass,
        'ssh', '-4', '-p', str(port),
        '-o', f"ProxyCommand={proxy_cmd}",
        '-o', 'AddressFamily=inet',
        '-o', f"ConnectTimeout={SSH_CONNECT_TIMEOUT}",
        '-o', 'StrictHostKeyChecking=no',
        '-o', 'PubkeyAuthentication=no',
        '-o', 'ServerAliveInterval=10',
        '-o', 'ServerAliveCountMax=3',
        f"{user}@{ip}", remote_cmd
    ]
    code, _, err = run_cmd(cmd, timeout=SSH_OVERALL_TIMEOUT)
    if code == 0:
        info("Clave pública instalada en ~/.ssh/authorized_keys")
        return True
    error(f"Error instalando clave: {err}")
    return False

# Paso 7: Probar conexión con clave
def test_ssh(ip, port, user, key_path, proxy_cmd):
    info("Probando conexión SSH usando la nueva clave...")
    cmd = ['ssh','-i',key_path,'-p',str(port),'-o',f"ProxyCommand={proxy_cmd}",
           '-o','StrictHostKeyChecking=no',f"{user}@{ip}", 'echo Conexión exitosa']
    code, out, err = run_cmd(cmd, timeout=SSH_OVERALL_TIMEOUT)
    if code == 0:
        info(out)
        return True
    error(f"Fallo en prueba de conexión: {err}")
    return False

# Renuevamente: renovar IP de Tor (utilizada en ensure_tor)
def renew_tor_ip(password: Optional[str]) -> bool:
    if password:
        try:
            with Controller.from_port(port=CONTROL_PORT) as ctl: # type: ignore
                ctl.authenticate(password=password)
                ctl.signal(Signal.NEWNYM) # type: ignore
            logging.info("Tor IP renewed via ControlPort")
            return True
        except Exception as e:
            logging.warning(f"ControlPort renewal failed: {e}")
    for path in ['/var/run/tor/control','/run/tor/control','/var/lib/tor/control_auth_cookie']:
        try:
            with Controller.from_socket_file(path) as ctl:
                ctl.authenticate()
                ctl.signal(Signal.NEWNYM) # type: ignore
            logging.info(f"Tor IP renewed via cookie at {path}")
            return True
        except Exception:
            continue
    logging.error("Failed to renew Tor IP by any method")
    return False

# Flujo principal
if __name__=='__main__':
    ip, port, user, ssh_pass, tor_pass, key_path, passphrase = gather_inputs()
    if not ensure_tor(): sys.exit(1)
    if not renew_tor_ip(tor_pass): sys.exit(2)
    if not check_socks(): sys.exit(3)
    proxy_cmd = get_proxy_cmd()
    if not proxy_cmd: sys.exit(4)
    if not gen_key(key_path, passphrase): sys.exit(5)
    if not deploy_key(ip, port, user, key_path, ssh_pass, proxy_cmd): sys.exit(6)
    if not test_ssh(ip, port, user, key_path, proxy_cmd): sys.exit(7)

    print("\n[+] ¡Todo listo! Puedes conectarte con tu clave SSH a través de Tor.")
