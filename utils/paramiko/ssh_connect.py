#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ssh_connect.py
Conecta a un VPS vía SSH canalizado por Tor (SOCKS5 en localhost:9050).
Mejoras:
- Detección automática del comando proxy (prioridad: ncat, nc.openbsd, nc).
- Verificación previa del puerto SOCKS5.
- Gestión configurable de ControlPort y autenticación.
- Manejo de timeouts ajustables.
- Opción de usar torsocks como fallback sin ProxyCommand.
- Captura y log del ProxyCommand para diagnosticar errores.
- Informe explícito de la IP interna del VPS.
"""

import sys
import time
import random
import subprocess
import logging
import socket
from typing import Optional

from stem import Signal
from stem.control import Controller

# Configuración de logging
default_level = logging.INFO
logging.basicConfig(level=default_level, format='%(asctime)s - %(levelname)s - %(message)s')

# Proxy commands candidates: priority order
PROXY_COMMANDS = [
    'ncat --proxy {host}:{port} --proxy-type socks5 %h %p',
    'nc.openbsd -X 5 -x {host}:{port} %h %p',
    'nc -X 5 -x {host}:{port} %h %p'
]
SOCKS_HOST = '127.0.0.1'
SOCKS_PORT = 9050
CONTROL_PORT = 9051
SSH_CONNECT_TIMEOUT = 90   # SSH -o ConnectTimeout
SSH_OVERALL_TIMEOUT = 300  # subprocess.run timeout


def generate_fake_ip() -> str:
    return f"192.168.{random.randint(0,255)}.{random.randint(1,254)}"


def check_socks5(host: str = SOCKS_HOST, port: int = SOCKS_PORT, timeout: float = 5.0) -> bool:
    try:
        with socket.create_connection((host, port), timeout=timeout):
            logging.info(f"SOCKS5 proxy reachable at {host}:{port}")
            return True
    except Exception as e:
        logging.error(f"Cannot reach SOCKS5 proxy {host}:{port}: {e}")
        return False


def pick_proxy_command(host: str = SOCKS_HOST, port: int = SOCKS_PORT) -> Optional[str]:
    """Return wrapped proxy command for SSH ProxyCommand with debug echo."""
    for template in PROXY_COMMANDS:
        cmd = template.format(host=host, port=port)
        prog = cmd.split()[0]
        if subprocess.run(['which', prog], capture_output=True).returncode == 0:
            wrapped = f"sh -c \"echo ProxyCommand exec: {cmd} >&2; exec {cmd}\""
            logging.info(f"Selected proxy command: {cmd}")
            return wrapped
    logging.error("No valid proxy command found (ncat, nc.openbsd, nc)")
    return None


def use_torsocks() -> bool:
    return subprocess.run(['which', 'torsocks'], capture_output=True).returncode == 0


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


def read_config(path: str) -> dict:
    required = ('ip_vps','port_vps','user_vps','key_path')
    cfg = {}
    try:
        with open(path, encoding='utf-8') as f:
            for ln in f:
                ln = ln.strip()
                if not ln or ln.startswith('#') or '=' not in ln:
                    continue
                k,v = [x.strip() for x in ln.split('=',1)]
                cfg[k] = v
        for k in required:
            if k not in cfg or not cfg[k]:
                logging.error(f"Missing config key: {k}")
                sys.exit(3)
        cfg.setdefault('tor_password', None)
        return cfg
    except FileNotFoundError:
        logging.error(f"Config file not found: {path}")
        sys.exit(1)
    except Exception as e:
        logging.error(f"Error reading config: {e}")
        sys.exit(2)


def ssh_connect_via_tor(
    ip: str, port: int, user: str, key_path: str,
    connect_timeout: int = SSH_CONNECT_TIMEOUT,
    overall_timeout: int = SSH_OVERALL_TIMEOUT
) -> bool:
    if not check_socks5(): return False
    proxy_cmd = pick_proxy_command()
    if not proxy_cmd: return False

    ssh_base = [
        'ssh', '-i', key_path, '-p', str(port),
        '-o', f"ProxyCommand={proxy_cmd}",
        '-o', 'AddressFamily=inet',
        '-o', 'StrictHostKeyChecking=no',
        '-o', f"ConnectTimeout={connect_timeout}",
        '-o', 'ServerAliveInterval=10',
        '-o', 'ServerAliveCountMax=3',
        f"{user}@{ip}"
    ]
    try:
        subprocess.run(ssh_base, check=True, timeout=overall_timeout)
        logging.info("SSH established via Tor ProxyCommand")
        return True
    except Exception as e:
        logging.error(f"ProxyCommand method failed: {e}")
        if use_torsocks():
            try:
                torsocks_cmd = ['torsocks','ssh','-i',key_path,'-p',str(port),
                                '-o','StrictHostKeyChecking=no',
                                f"{user}@{ip}"]
                subprocess.run(torsocks_cmd, check=True, timeout=overall_timeout)
                logging.info("SSH established via torsocks")
                return True
            except Exception as e2:
                logging.error(f"torsocks method failed: {e2}")
    return False


def run_remote_checks(
    ip: str, port: int, user: str, key_path: str, timeout: int = SSH_OVERALL_TIMEOUT
) -> None:
    fake_ip = generate_fake_ip()
    logging.info(f"Fake internal IP: {fake_ip}")
    # Primera comprobación: obtener IP interna real
    try:
        out = subprocess.run(
            ['ssh','-i', key_path,'-p',str(port),
             '-o', 'StrictHostKeyChecking=no',f"{user}@{ip}", 'hostname -I'],
            check=True, capture_output=True, text=True, timeout=timeout
        )
        ips = out.stdout.strip()
        logging.info(f"Remote VPS internal IP(s): {ips}")
    except Exception as e:
        logging.warning(f"Failed to retrieve internal IP: {e}")
        ips = ''
    # Resto de diagnósticos
    cmds = [('whoami','Remote User'),('uname -a','Kernel/OS'),('uptime','Uptime')]
    for cmd,label in cmds:
        try:
            out = subprocess.run(
                ['ssh','-i', key_path,'-p',str(port),
                 '-o', 'StrictHostKeyChecking=no',f"{user}@{ip}", cmd],
                check=True, capture_output=True, text=True, timeout=timeout
            )
            logging.info(f"[{label}] → {out.stdout.strip()}")
        except Exception as e:
            logging.warning(f"[{label}] → failed: {e}")


def main():
    cfg_path = sys.argv[1] if len(sys.argv)>1 else 'config.conf'
    cfg = read_config(cfg_path)

    # Ensure Tor running
    if subprocess.run(['systemctl','is-active','--quiet','tor']).returncode != 0:
        logging.info("Starting Tor service...")
        subprocess.run(['sudo','service','tor','start'])
        time.sleep(15)
    else:
        logging.info("Restarting Tor for fresh circuit...")
        subprocess.run(['sudo','service','tor','restart'])
        time.sleep(15)

    # Renew Tor IP
    for i in range(3):
        if renew_tor_ip(cfg.get('tor_password')): break
        logging.info(f"Retrying Tor IP renewal in 10s (attempt {i+1}/3)")
        time.sleep(10)
    else:
        logging.critical("Tor IP renewal failed after retries.")
        sys.exit(4)

    # SSH connect and diagnostics
    if ssh_connect_via_tor(
        ip=cfg['ip_vps'], port=int(cfg['port_vps']),
        user=cfg['user_vps'], key_path=cfg['key_path']
    ):
        run_remote_checks(
            ip=cfg['ip_vps'], port=int(cfg['port_vps']),
            user=cfg['user_vps'], key_path=cfg['key_path']
        )

if __name__=='__main__':
    main()
