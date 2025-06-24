#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ssh_connect.py
Conecta a un VPS vía SSH canalizado por Tor (SOCKS5 en localhost:9050).
"""

import sys, time, random, subprocess
from typing import Optional

import paramiko
from paramiko.proxy import ProxyCommand
from stem import Signal
from stem.control import Controller

def generate_fake_ip() -> str:
    return f"192.168.{random.randint(0,255)}.{random.randint(1,254)}"

def renew_tor_ip(password: Optional[str]) -> bool:
    # 1) ControlPort TCP:9051 + password
    if password:
        try:
            with Controller.from_port(port=9051) as ctl:
                ctl.authenticate(password=password)
                ctl.signal(Signal.NEWNYM)
            print("[+] IP de Tor renovada (ControlPort:9051)")
            return True
        except Exception as e:
            print(f"[-] ControlPort falló: {e}")
    # 2) Socket UNIX + cookie auth
    for path in ("/var/run/tor/control", "/run/tor/control", "/var/lib/tor/control_auth_cookie"):
        try:
            with Controller.from_socket_file(path) as ctl:
                ctl.authenticate()
                ctl.signal(Signal.NEWNYM)
            print(f"[+] IP de Tor renovada (cookie en {path})")
            return True
        except Exception:
            continue
    print("[!] No pude renovar IP de Tor.")
    return False

def read_config(path: str) -> dict:
    cfg = {}
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            k, v = line.split('=',1)
            cfg[k.strip()] = v.strip()
    for key in ('ip_vps','port_vps','user_vps','pass_vps'):
        if key not in cfg or not cfg[key]:
            print(f"[!] Falta valor requerido: {key}")
            sys.exit(3)
    cfg.setdefault('tor_password', None)
    return cfg

def ssh_connect_via_tor(ip: str, port: int, user: str, pwd: str) -> Optional[paramiko.SSHClient]:
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    proxy = ProxyCommand(f"nc -X 5 -x 127.0.0.1:9050 {ip} {port}")
    try:
        client.connect(hostname=ip, port=port,
                       username=user, password=pwd,
                       sock=proxy, timeout=30)
        print("[+] Conexión SSH establecida vía Tor")
        return client
    except Exception as e:
        print(f"[!] Falló al conectar por SSH: {e}")
        return None

def run_remote_checks(client: paramiko.SSHClient):
    fake = generate_fake_ip()
    print(f"\nIP interna falsificada : {fake}\n")
    for cmd,label in [
        ("hostname -I","IP real del servidor"),
        ("whoami","Usuario"),
        ("uname -a","Kernel/SO"),
        ("uptime","Uptime")
    ]:
        stdin,stdout,stderr = client.exec_command(cmd)
        out=stdout.read().decode().strip()
        err=stderr.read().decode().strip()
        print(f"[{label}] → {out or err}")

if __name__=="__main__":
    cfg_path = sys.argv[1] if len(sys.argv)>1 else "config.conf"
    cfg = read_config(cfg_path)

    # 1) Asegurar Tor levantado
    if subprocess.run(["systemctl","is-active","--quiet","tor"]).returncode != 0:
        print("[-] Tor no está activo, arrancándolo...")
        subprocess.run(["sudo","service","tor","start"])
        time.sleep(10)

    # 2) Renovar IP de Tor
    while not renew_tor_ip(cfg['tor_password']):
        print("[*] Reintentando en 10s…")
        time.sleep(10)

    # 3) SSH vía Tor
    client = ssh_connect_via_tor(
        ip=cfg['ip_vps'],
        port=int(cfg['port_vps']),
        user=cfg['user_vps'],
        pwd=cfg['pass_vps']
    )
    if client:
        try:
            run_remote_checks(client)
        finally:
            client.close()
            print("[*] Conexión SSH cerrada")
