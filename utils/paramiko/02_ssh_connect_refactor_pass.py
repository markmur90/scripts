#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
02_ssh_connect_refactor_pass.py
Conecta a un VPS vía SSH canalizado por Tor (SOCKS5 en localhost:9050).
Soporta autenticación por clave privada o por contraseña.
"""

import sys
import time
import random
import subprocess
import logging
import socket
import argparse
import getpass
from typing import Optional, List

from stem import Signal
from stem.control import Controller

# Logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Tor & Proxy settings
SOCKS_HOST = '127.0.0.1'
SOCKS_PORT = 9050
CONTROL_PORT = 9051
SSH_CONNECT_TIMEOUT = 90
SSH_OVERALL_TIMEOUT = 300
PROXY_COMMANDS = [
    'ncat --proxy {host}:{port} --proxy-type socks5 %h %p',
    'nc.openbsd -X 5 -x {host}:{port} %h %p',
    'nc -X 5 -x {host}:{port} %h %p'
]


def check_socks5(host: str = SOCKS_HOST, port: int = SOCKS_PORT, timeout: float = 5.0) -> bool:
    try:
        socket.create_connection((host, port), timeout=timeout)
        logging.info(f"SOCKS5 proxy reachable at {host}:{port}")
        return True
    except Exception as e:
        logging.error(f"Cannot reach SOCKS5 proxy {host}:{port}: {e}")
        return False


def pick_proxy_command(host: str = SOCKS_HOST, port: int = SOCKS_PORT) -> Optional[str]:
    for template in PROXY_COMMANDS:
        cmd = template.format(host=host, port=port)
        prog = cmd.split()[0]
        if subprocess.run(['which', prog], capture_output=True).returncode == 0:
            wrapped = f"sh -c \"echo ProxyCommand exec: {cmd} >&2; exec {cmd}\""
            logging.info(f"Selected proxy command: {cmd}")
            return wrapped
    logging.error("No valid proxy command (ncat, nc.openbsd, nc)")
    return None


def renew_tor_ip(password: Optional[str]) -> bool:
    # renew via ControlPort
    if password:
        try:
            with Controller.from_port(port=CONTROL_PORT) as ctl: # type: ignore
                ctl.authenticate(password=password)
                ctl.signal(Signal.NEWNYM) # type: ignore
            logging.info("Tor IP renewed via ControlPort")
            return True
        except Exception:
            pass
    # renew via cookie
    for path in ('/var/run/tor/control','/run/tor/control','/var/lib/tor/control_auth_cookie'):
        try:
            with Controller.from_socket_file(path) as ctl:
                ctl.authenticate()
                ctl.signal(Signal.NEWNYM) # type: ignore
            logging.info(f"Tor IP renewed via cookie: {path}")
            return True
        except Exception:
            continue
    logging.error("Failed to renew Tor IP")
    return False


def ssh_connect(
    ip: str,
    port: int,
    user: str,
    key_path: Optional[str],
    password: Optional[str],
    proxy_cmd: str
) -> bool:
    """
    Construye y ejecuta comando SSH con clave o contraseña.
    """
    # base options
    opts: List[str] = ['ssh',
        '-p', str(port),
        '-o', f"ProxyCommand={proxy_cmd}",
        '-o', 'AddressFamily=inet',
        '-o', 'StrictHostKeyChecking=no',
        '-o', f"ConnectTimeout={SSH_CONNECT_TIMEOUT}",
        '-o', 'ServerAliveInterval=10',
        '-o', 'ServerAliveCountMax=3'
    ]
    # auth method
    if key_path:
        opts += ['-i', key_path]
    else:
        # password authentication
        opts += ['-o', 'PubkeyAuthentication=no', '-o', 'PreferredAuthentications=password']
    opts += [f"{user}@{ip}"]

    cmd = []
    if not key_path and password:
        # use sshpass
        if subprocess.run(['which','sshpass'], capture_output=True).returncode == 0:
            cmd = ['sshpass','-p', password] + opts
        else:
            logging.error("sshpass required for password auth")
            return False
    else:
        cmd = opts

    try:
        subprocess.run(cmd, check=True, timeout=SSH_OVERALL_TIMEOUT)
        logging.info("SSH connection established")
        return True
    except Exception as e:
        logging.error(f"SSH connection failed: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description="SSH via Tor (key or password)")
    parser.add_argument('ip', help='VPS IP address')
    parser.add_argument('port', type=int, help='VPS SSH port')
    parser.add_argument('user', help='SSH user')
    parser.add_argument('--key', dest='key_path', help='Path to SSH private key')
    parser.add_argument('--password', dest='ssh_password', nargs='?', const=None,
                        help='Prompt for SSH password')
    parser.add_argument('--tor-pass', dest='tor_password', help='Tor ControlPort password')
    parser.add_argument('config', help='Ruta al archivo config.conf')
    args = parser.parse_args()

    # prompt password if flag given without value
    if args.ssh_password is None and '--password' in ' '.join(sys.argv):
        args.ssh_password = getpass.getpass('SSH Password: ')

    # restart Tor
    if subprocess.run(['systemctl','is-active','--quiet','tor']).returncode:
        subprocess.run(['sudo','service','tor','start'])
        time.sleep(15)
    else:
        subprocess.run(['sudo','service','tor','restart'])
        time.sleep(15)

    # renew Tor IP
    for _ in range(3):
        if renew_tor_ip(args.tor_password): break
        time.sleep(10)

    if not check_socks5(): sys.exit(1)
    proxy_cmd = pick_proxy_command()
    if not proxy_cmd: sys.exit(2)

    # connect
    if not ssh_connect(
        ip=args.ip,
        port=args.port,
        user=args.user,
        key_path=args.key_path,
        password=args.ssh_password,
        proxy_cmd=proxy_cmd
    ):
        sys.exit(3)

if __name__=='__main__':
    main()
