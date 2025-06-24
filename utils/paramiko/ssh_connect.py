#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ssh_connect.py
Conecta a un VPS vía SSH canalizado por Tor (SOCKS5 en localhost:9050).
"""

import sys
import time
import random
import subprocess
import logging
from typing import Optional

from stem import Signal
from stem.control import Controller

# Configuración de logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def generate_fake_ip() -> str:
    """Genera una dirección IP falsa."""
    return f"192.168.{random.randint(0,255)}.{random.randint(1,254)}"

def renew_tor_ip(password: Optional[str]) -> bool:
    """
    Renueva la dirección IP de Tor utilizando el ControlPort o autenticación por cookie.
    
    Args:
        password (Optional[str]): Contraseña para el ControlPort de Tor.
        
    Returns:
        bool: True si la IP fue renovada exitosamente, False en caso contrario.
    """
    # 1) ControlPort TCP:9051 + password
    if password:
        try:
            with Controller.from_port(port=9051) as ctl: # type: ignore
                ctl.authenticate(password=password)
                ctl.signal(Signal.NEWNYM) # type: ignore
            logging.info("IP de Tor renovada (ControlPort:9051)")
            return True
        except Exception as e:
            logging.error(f"ControlPort falló: {e}")
    # 2) Socket UNIX + cookie auth
    for path in ("/var/run/tor/control", "/run/tor/control", "/var/lib/tor/control_auth_cookie"):
        try:
            with Controller.from_socket_file(path) as ctl:
                ctl.authenticate()
                ctl.signal(Signal.NEWNYM) # type: ignore
            logging.info(f"IP de Tor renovada (cookie en {path})")
            return True
        except Exception:
            continue
    logging.warning("No pude renovar IP de Tor.")
    return False

def read_config(path: str) -> dict:
    """
    Lee el archivo de configuración y devuelve un diccionario con los valores.
    
    Args:
        path (str): Ruta al archivo de configuración.
        
    Returns:
        dict: Diccionario con los valores de configuración.
    """
    cfg = {}
    try:
        with open(path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#') or '=' not in line:
                    continue
                k, v = line.split('=', 1)
                cfg[k.strip()] = v.strip()
        for key in ('ip_vps', 'port_vps', 'user_vps', 'key_path'):
            if key not in cfg or not cfg[key]:
                logging.error(f"Falta valor requerido: {key}")
                sys.exit(3)
        cfg.setdefault('tor_password', None)
        return cfg
    except FileNotFoundError:
        logging.error(f"Archivo de configuración no encontrado: {path}")
        sys.exit(1)
    except Exception as e:
        logging.error(f"Error al leer el archivo de configuración: {e}")
        sys.exit(1)

def ssh_connect_via_tor(ip: str, port: int, user: str, key_path: str, timeout: int = 180) -> bool:
    """
    Establece una conexión SSH a través de Tor utilizando OpenSSH.
    
    Args:
        ip (str): Dirección IP del VPS.
        port (int): Puerto SSH del VPS.
        user (str): Usuario SSH.
        key_path (str): Ruta a la clave SSH.
        timeout (int): Tiempo de espera para la conexión SSH en segundos.
        
    Returns:
        bool: True si la conexión fue exitosa, False en caso contrario.
    """
    command = [
        "ssh",
        "-i", key_path,
        "-p", str(port),
        "-o", "ProxyCommand=nc -X 5 -x 127.0.0.1:9050 %h %p",
        "-o", "StrictHostKeyChecking=no",
        "-o", "ConnectTimeout=60",  # Tiempo de espera para establecer la conexión
        "-o", "ServerAliveInterval=30",  # Envía keep-alive cada 30 segundos
        "-o", "ServerAliveCountMax=3",  # Máximo de keep-alive sin respuesta antes de cerrar
        f"{user}@{ip}"
    ]
    try:
        result = subprocess.run(command, check=True, capture_output=True, text=True, timeout=timeout)
        logging.info("Conexión SSH establecida vía Tor")
        logging.info(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        logging.error(f"Falló al conectar por SSH: {e.stderr}")
        return False
    except subprocess.TimeoutExpired:
        logging.error(f"Tiempo de espera excedido al conectar por SSH")
        return False

def run_remote_checks(ip: str, port: int, user: str, key_path: str, timeout: int = 180):
    """
    Ejecuta comandos remotos en el VPS utilizando OpenSSH.
    
    Args:
        ip (str): Dirección IP del VPS.
        port (int): Puerto SSH del VPS.
        user (str): Usuario SSH.
        key_path (str): Ruta a la clave SSH.
        timeout (int): Tiempo de espera para la conexión SSH en segundos.
    """
    fake = generate_fake_ip()
    logging.info(f"IP interna falsificada : {fake}\n")
    commands = [
        ("hostname -I", "IP real del servidor"),
        ("whoami", "Usuario"),
        ("uname -a", "Kernel/SO"),
        ("uptime", "Uptime")
    ]
    for cmd, label in commands:
        command = [
            "ssh",
            "-i", key_path,
            "-p", str(port),
            "-o", "ProxyCommand=nc -X 5 -x 127.0.0.1:9050 %h %p",
            "-o", "StrictHostKeyChecking=no",
            "-o", "ConnectTimeout=60",  # Tiempo de espera para establecer la conexión
            "-o", "ServerAliveInterval=30",  # Envía keep-alive cada 30 segundos
            "-o", "ServerAliveCountMax=3",  # Máximo de keep-alive sin respuesta antes de cerrar
            f"{user}@{ip}",
            cmd
        ]
        try:
            result = subprocess.run(command, check=True, capture_output=True, text=True, timeout=timeout)
            logging.info(f"[{label}] → {result.stdout.strip()}")
        except subprocess.CalledProcessError as e:
            logging.error(f"[{label}] → Error: {e.stderr.strip()}")
        except subprocess.TimeoutExpired:
            logging.error(f"[{label}] → Tiempo de espera excedido")

def main():
    cfg_path = sys.argv[1] if len(sys.argv) > 1 else "config.conf"
    cfg = read_config(cfg_path)

    # 1) Asegurar Tor levantado y reiniciarlo si es necesario
    if subprocess.run(["systemctl", "is-active", "--quiet", "tor"]).returncode != 0:
        logging.info("Tor no está activo, arrancándolo...")
        subprocess.run(["sudo", "service", "tor", "start"])
        time.sleep(180)
    else:
        logging.info("[+] Tor está activo. Reiniciando Tor para obtener una nueva IP...")
        subprocess.run(["sudo", "service", "tor", "restart"])
        time.sleep(180)

    # 2) Renovar IP de Tor
    while not renew_tor_ip(cfg['tor_password']):
        logging.info("[*] Reintentando en 10s…")
        time.sleep(180)

    # 3) SSH vía Tor
    if ssh_connect_via_tor(
        ip=cfg['ip_vps'],
        port=int(cfg['port_vps']),
        user=cfg['user_vps'],
        key_path=cfg['key_path']
    ):
        run_remote_checks(
            ip=cfg['ip_vps'],
            port=int(cfg['port_vps']),
            user=cfg['user_vps'],
            key_path=cfg['key_path']
        )

if __name__ == "__main__":
    main()