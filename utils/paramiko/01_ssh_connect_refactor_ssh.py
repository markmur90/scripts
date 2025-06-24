#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
01_ssh_connect_refactor_paramiko.py
Conecta a un VPS vía SSH canalizado por Tor (SOCKS5 en localhost:9050), sin pedir contraseña interactiva.
Mejoras:
- Usa paramiko para autenticación con clave o password desde config.
- No solicita password en tiempo de ejecución (se lee pass_vps de config).
- Detección automática de ProxyCommand (ncat, nc.openbsd, nc).
- Verificación previa del proxy SOCKS5.
- Gestión configurable de ControlPort y autenticación de Tor.
- Captura y logging de ProxyCommand usado.
- Informes claros antes de iniciar sesión interactiva.
- Modo interactivo y modo check-only.
"""
import sys
import time
import random
import logging
import socket
import subprocess
import argparse
from typing import Optional

import paramiko
from paramiko import ProxyCommand
from stem import Signal
from stem.control import Controller

# Configuración de logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Constantes
PROXY_COMMANDS = [
    'ncat --proxy {host}:{port} --proxy-type socks5 %h %p',
    'nc.openbsd -X 5 -x {host}:{port} %h %p',
    'nc -X 5 -x {host}:{port} %h %p'
]
SOCKS_HOST = '127.0.0.1'
SOCKS_PORT = 9050
CONTROL_PORT = 9051
TOR_WAIT = 15  # segundos de espera al (re)iniciar Tor
RENEW_RETRIES = 3


def generate_fake_ip() -> str:
    """Genera una IP interna ficticia."""
    return f"192.168.{random.randint(0, 255)}.{random.randint(1, 254)}"


def check_socks5(host: str = SOCKS_HOST, port: int = SOCKS_PORT, timeout: float = 5.0) -> bool:
    """Verifica la disponibilidad del proxy SOCKS5."""
    try:
        with socket.create_connection((host, port), timeout=timeout):
            logging.info(f"SOCKS5 proxy reachable at {host}:{port}")
            return True
    except Exception as e:
        logging.error(f"Cannot reach SOCKS5 proxy {host}:{port}: {e}")
        return False


def pick_proxy_command(host: str = SOCKS_HOST, port: int = SOCKS_PORT) -> Optional[str]:
    """Selecciona el comando ProxyCommand disponible."""
    for tmpl in PROXY_COMMANDS:
        cmd = tmpl.format(host=host, port=port)
        prog = cmd.split()[0]
        if subprocess.run(['which', prog], capture_output=True).returncode == 0:
            logging.info(f"Selected ProxyCommand: {cmd}")
            return cmd
    logging.error("No valid proxy command found (ncat, nc.openbsd, nc)")
    return None


def renew_tor_ip(password: Optional[str]) -> bool:
    """Renueva la IP de Tor usando ControlPort o cookie."""
    # Intento con ControlPort (puerto como str) # type: ignore
    if password:
        try:
            with Controller.from_port(port=str(CONTROL_PORT)) as ctl:  # type: ignore
                ctl.authenticate(password=password)
                ctl.signal(Signal.NEWNYM)  # type: ignore
            logging.info("Tor IP renewed via ControlPort")
            return True
        except Exception as e:
            logging.warning(f"ControlPort renewal failed: {e}")
    # Intentar cookie
    for path in ['/var/run/tor/control', '/run/tor/control', '/var/lib/tor/control_auth_cookie']:
        try:
            with Controller.from_socket_file(path) as ctl:  # type: ignore
                ctl.authenticate()
                ctl.signal(Signal.NEWNYM)  # type: ignore
            logging.info(f"Tor IP renewed via cookie at {path}")
            return True
        except Exception:
            continue
    logging.error("Failed to renew Tor IP by any method")
    return False


def read_config(path: str) -> dict:
    """Lee y valida la configuración del archivo .conf."""
    required = ('ip_vps', 'port_vps', 'user_vps', 'key_path', 'pass_vps')
    cfg = {}
    try:
        with open(path, encoding='utf-8') as f:
            for ln in f:
                ln = ln.strip()
                if not ln or ln.startswith('#') or '=' not in ln:
                    continue
                k, v = [x.strip() for x in ln.split('=', 1)]
                cfg[k] = v
        for k in required:
            if k not in cfg or not cfg[k]:
                logging.error(f"Missing config key: {k}")
                sys.exit(3)
        return cfg
    except FileNotFoundError:
        logging.error(f"Config file not found: {path}")
        sys.exit(1)
    except Exception as e:
        logging.error(f"Error reading config: {e}")
        sys.exit(2)


def run_remote_checks(client: paramiko.SSHClient) -> dict:
    """Ejecuta diagnósticos remotos y devuelve resultados en dict."""
    results = {}
    fake_ip = generate_fake_ip()
    results['fake_internal_ip'] = fake_ip
    logging.info(f"Fake internal IP antes de conexión: {fake_ip}")

    stdin, stdout, stderr = client.exec_command('hostname -I')
    real_ips = stdout.read().decode().strip()
    results['real_internal_ips'] = real_ips
    logging.info(f"Remote VPS internal IP(s): {real_ips}")

    for cmd, label in [('whoami', 'Remote User'), ('uname -a', 'Kernel/OS'), ('uptime', 'Uptime')]:
        stdin, stdout, stderr = client.exec_command(cmd)
        output = stdout.read().decode().strip()
        results[label] = output
        logging.info(f"[{label}] → {output}")

    return results


def interactive_shell(client: paramiko.SSHClient) -> None:
    """Abre un shell interactivo a través del canal Paramiko."""
    chan = client.invoke_shell()
    import threading, termios, tty, sys

    def _writer(chan):
        try:
            while True:
                data = chan.recv(1024)
                if not data:
                    break
                sys.stdout.write(data.decode())
                sys.stdout.flush()
        except Exception:
            pass

    def _reader(chan):
        oldtty = termios.tcgetattr(sys.stdin)
        try:
            tty.setraw(sys.stdin.fileno())
            tty.setcbreak(sys.stdin.fileno())
            while True:
                d = sys.stdin.read(1)
                if not d:
                    break
                chan.send(d)
        finally:
            termios.tcsetattr(sys.stdin, termios.TCSADRAIN, oldtty)

    t1 = threading.Thread(target=_writer, args=(chan,))
    t2 = threading.Thread(target=_reader, args=(chan,))
    t1.start(); t2.start()
    t1.join(); t2.join()


def main():
    parser = argparse.ArgumentParser(description="SSH vía Tor con Paramiko, sin prompt de password")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--interactive', action='store_true', help='Shell interactiva en VPS')
    group.add_argument('--check-only', action='store_true', help='Sólo diagnósticos sin shell')
    parser.add_argument('config', help='Ruta al archivo config.conf')
    args = parser.parse_args()

    cfg = read_config(args.config)
    ip = cfg['ip_vps']; port = int(cfg['port_vps'])
    user = cfg['user_vps']; key = cfg['key_path']; pwd = cfg['pass_vps']

    if subprocess.run(['systemctl', 'is-active', '--quiet', 'tor']).returncode != 0:
        logging.info("Iniciando servicio Tor...")
        subprocess.run(['sudo', 'service', 'tor', 'start'])
    else:
        logging.info("Reiniciando Tor para circuito fresco...")
        subprocess.run(['sudo', 'service', 'tor', 'restart'])
    time.sleep(TOR_WAIT)

    for i in range(RENEW_RETRIES):
        if renew_tor_ip(cfg.get('tor_password')):
            break
        logging.info(f"Reintentando renovación Tor en 10s (intento {i+1}/{RENEW_RETRIES})")
        time.sleep(10)
    else:
        logging.critical("Renovación de IP Tor fallida.")
        sys.exit(4)

    if not check_socks5():
        sys.exit(5)

    proxy_str = pick_proxy_command()
    if not proxy_str:
        sys.exit(6)

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    proxy = ProxyCommand(proxy_str)

    logging.info("Conectando a través de Tor... ")
    try:
        client.connect(
            hostname=ip, port=port, username=user,
            key_filename=key, password=pwd,
            sock=proxy, allow_agent=False, look_for_keys=False, timeout=30
        )
    except Exception as e:
        logging.error(f"Fallo al conectar por Tor: {e}")
        sys.exit(7)

    results = run_remote_checks(client)
    if args.check_only:
        logging.info("Modo check-only completado. Resultados:")
        for k, v in results.items():
            print(f"{k}: {v}")
        sys.exit(0)

    logging.info("Datos previos al login:")
    for k, v in results.items():
        print(f"- {k}: {v}")
    print("--- Abriendo sesión interactiva ---")
    interactive_shell(client)
    logging.info("Sesión interactiva finalizada.")
    client.close()

if __name__ == '__main__':
    main()
