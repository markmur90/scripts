#!/usr/bin/env python3
import json
import os
import shutil
import socket
import subprocess
import threading
import time
import select
import pty
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.abspath(os.path.join(BASE_DIR))
PROJECT_ROOT = os.path.abspath(os.path.join(ROOT_DIR, "..", "..", ".."))


def read_config():
    config_path = os.path.join(PROJECT_ROOT, "análisis", "mejoras", "config", "express_config.json")
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        return data.get("express_intelligent", {})
    except Exception:
        return {}


CONFIG = read_config()
RUNNING_PROCS: dict[str, dict] = {}


def get_log_file_path():
    # Prefer configured log file; fallback to common logs
    configured = (CONFIG.get("logging", {}) or {}).get("file")
    if configured and os.path.isfile(configured):
        return configured
    candidates = [
        os.path.join(PROJECT_ROOT, ".logs", "express_intelligent.log"),
        os.path.join(PROJECT_ROOT, ".logs", "01_full_deploy", "full_deploy.log"),
    ]
    for path in candidates:
        if os.path.isfile(path):
            return path
    return None


def tail_file(path: str, num_lines: int = 50):
    if not path or not os.path.isfile(path):
        return []
    try:
        # Efficient tail implementation
        with open(path, "rb") as f:
            f.seek(0, os.SEEK_END)
            buffer = bytearray()
            pointer = f.tell()
            lines_found = 0
            while pointer >= 0 and lines_found <= num_lines:
                f.seek(pointer)
                byte = f.read(1)
                if byte == b"\n":
                    lines_found += 1
                    if lines_found > num_lines:
                        break
                buffer.extend(byte)
                pointer -= 1
        content = bytes(reversed(buffer)).decode("utf-8", errors="ignore").splitlines()[-num_lines:]
        return content
    except Exception:
        return []


def run_cmd(command: list[str] | str, timeout: int = 5) -> tuple[int, str]:
    try:
        completed = subprocess.run(
            command,
            shell=isinstance(command, str),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=timeout,
            text=True,
        )
        return completed.returncode, completed.stdout.strip()
    except subprocess.TimeoutExpired:
        return 124, "timeout"
    except Exception as exc:
        return 1, str(exc)


def check_service(service_name: str) -> str:
    code, out = run_cmd(["systemctl", "is-active", service_name])
    if code == 0 and out.strip() == "active":
        return "active"
    if out.strip():
        return out.strip()
    # Fallback: process exists?
    code, out = run_cmd(f"ps aux | grep -v grep | grep -i {service_name}")
    return "active" if code == 0 and out else "inactive"


def get_cpu_usage_percent() -> float:
    # Compute from /proc/stat over small interval
    def read_cpu_times():
        with open("/proc/stat", "r") as f:
            line = f.readline()
        parts = [float(x) for x in line.split()[1:8]]  # user,nice,system,idle,iowait,irq,softirq
        idle = parts[3] + parts[4]
        non_idle = parts[0] + parts[1] + parts[2] + parts[5] + parts[6]
        total = idle + non_idle
        return idle, total

    idle1, total1 = read_cpu_times()
    time.sleep(0.2)
    idle2, total2 = read_cpu_times()
    totald = total2 - total1
    idled = idle2 - idle1
    if totald <= 0:
        return 0.0
    usage = (1.0 - idled / totald) * 100.0
    return max(0.0, min(100.0, usage))


def get_memory_usage_percent() -> float:
    meminfo = {}
    with open("/proc/meminfo", "r") as f:
        for line in f:
            key, value = line.split(":")
            meminfo[key] = float(value.strip().split()[0])  # in kB
    total = meminfo.get("MemTotal", 0.0)
    free = meminfo.get("MemFree", 0.0)
    buffers = meminfo.get("Buffers", 0.0)
    cached = meminfo.get("Cached", 0.0)
    # memory used approx = total - (free + buffers + cached)
    used = max(0.0, total - (free + buffers + cached))
    return 0.0 if total == 0 else (used / total) * 100.0


def get_disk_usage_percent(path: str = "/") -> float:
    usage = shutil.disk_usage(path)
    if usage.total == 0:
        return 0.0
    return (usage.used / usage.total) * 100.0


def ssh_run(command: str, timeout: int = 8) -> tuple[int, str]:
    vps = CONFIG.get("vps", {}) or {}
    host = vps.get("host")
    user = vps.get("user")
    port = str(vps.get("port", 22))
    key = vps.get("ssh_key_path")
    if not host or not user or not key:
        return 1, "vps no configurado"
    ssh_cmd = [
        "ssh", "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=no",
        "-i", key, "-p", port, f"{user}@{host}", command,
    ]
    return run_cmd(ssh_cmd, timeout=timeout)


def build_ssh_cmd(command: str) -> list[str]:
    vps = CONFIG.get("vps", {}) or {}
    host = vps.get("host")
    user = vps.get("user")
    port = str(vps.get("port", 22))
    key = vps.get("ssh_key_path")
    if not host or not user or not key:
        return []
    return [
        "ssh", "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=no",
        "-i", key, "-p", port, f"{user}@{host}", command,
    ]


def build_rsync_commands() -> str:
    vps = CONFIG.get("vps", {}) or {}
    host = vps.get("host"); user = vps.get("user"); port = str(vps.get("port", 22)); key = vps.get("ssh_key_path")
    if not host or not user or not key:
        return "echo 'VPS no configurado' && exit 1"
    ssh_part = f"ssh -i '{key}' -p {port} -o StrictHostKeyChecking=no"
    folders = [
        (os.path.expanduser("/home/markmur88/api_bank_h2"), "/home/markmur88/api_bank_h2/"),
        (os.path.expanduser("/home/markmur88/api_bank_heroku"), "/home/markmur88/api_bank_heroku/"),
        (os.path.expanduser("/home/markmur88/scripts"), "/home/markmur88/scripts/"),
    ]
    excludes = [
        "--exclude=.git/", "--exclude=__pycache__/", "--exclude=*.pyc",
        "--exclude=node_modules/", "--exclude=.venv/", "--exclude=*.log",
    ]
    cmds = []
    for src, dst in folders:
        cmds.append(
            f"rsync -az --delete {' '.join(excludes)} -e \"{ssh_part}\" '{src}/' '{user}@{host}:{dst}'"
        )
    return " && ".join(cmds)


def check_port_open(host: str, port: int, timeout: float = 1.0) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(timeout)
        try:
            s.connect((host, port))
            return True
        except Exception:
            return False


def get_backup_age_human() -> str:
    backup_dir = (CONFIG.get("system", {}) or {}).get("backup_dir") or os.path.join(PROJECT_ROOT, "backup", "zip")
    if not os.path.isdir(backup_dir):
        return "desconocido"
    try:
        latest = None
        latest_mtime = 0
        for root, _, files in os.walk(backup_dir):
            for name in files:
                path = os.path.join(root, name)
                mtime = os.path.getmtime(path)
                if mtime > latest_mtime:
                    latest_mtime = mtime
                    latest = path
        if not latest:
            return "no encontrado"
        seconds = time.time() - latest_mtime
        if seconds < 60:
            return f"hace {int(seconds)}s"
        if seconds < 3600:
            return f"hace {int(seconds/60)}m"
        if seconds < 86400:
            return f"hace {int(seconds/3600)}h"
        return f"hace {int(seconds/86400)}d"
    except Exception:
        return "desconocido"


def json_response(handler: BaseHTTPRequestHandler, obj: dict, status: int = 200):
    data = json.dumps(obj).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(data)))
    handler.send_header("Cache-Control", "no-store")
    handler.end_headers()
    handler.wfile.write(data)


def text_response(handler: BaseHTTPRequestHandler, data: bytes, content_type: str = "text/html; charset=utf-8", status: int = 200):
    handler.send_response(status)
    handler.send_header("Content-Type", content_type)
    handler.send_header("Content-Length", str(len(data)))
    handler.send_header("Cache-Control", "no-store")
    handler.end_headers()
    handler.wfile.write(data)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, format: str, *args):
        # Silence default logging to stderr
        return

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        query = parse_qs(parsed.query)

        # Serve dashboard HTML from / (same-origin for the browser)
        if path == "/" or path == "/index.html":
            html_path = os.path.join(ROOT_DIR, "dashboard_web.html")
            if not os.path.isfile(html_path):
                text_response(self, b"<h1>Dashboard no encontrado</h1>", status=404)
                return
            with open(html_path, "rb") as f:
                data = f.read()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(data)
            return

        # Remote (VPS) variants using SSH: pass ?target=vps
        target = ("".join((query.get("target") or [""]))).strip().lower()
        if target == "vps" and path in ("/api/status/resources", "/api/status/services", "/api/status/application", "/api/status/security"):
            if path == "/api/status/resources":
                code, out = ssh_run("python3 - <<'PY'\nimport shutil, psutil, json\nimport os\n# fallback sin psutil\ntry:\n    import psutil as P\nexcept Exception:\n    P=None\n# CPU\ntry:\n    cpu = __import__('psutil').cpu_percent(interval=0.2) if P else 0.0\nexcept Exception:\n    cpu = 0.0\n# Memoria\ntry:\n    if P:\n        m = __import__('psutil').virtual_memory()\n        mem = m.percent\n    else:\n        mem = 0.0\nexcept Exception:\n    mem = 0.0\n# Disco\ntry:\n    u = shutil.disk_usage('/')\n    disk = (u.used/u.total)*100.0 if u.total else 0.0\nexcept Exception:\n    disk = 0.0\nprint(json.dumps({'cpu': round(cpu,1), 'memory': round(mem,1), 'disk': round(disk,1)}))\nPY")
                try:
                    payload = json.loads(out)
                except Exception:
                    payload = {"cpu": 0, "memory": 0, "disk": 0}
                self.send_response(200)
                self.send_header("Content-Type", "application/json; charset=utf-8")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(json.dumps(payload).encode("utf-8"))
                return
            if path == "/api/status/services":
                code, out = ssh_run("python3 - <<'PY'\nimport json, subprocess\nsvcs=['postgresql','nginx','gunicorn','tor']\nr={}\nfor s in svcs:\n    try:\n        c=subprocess.run(['systemctl','is-active',s],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)\n        r[s]=c.stdout.strip() if c.returncode==0 else 'inactive'\n    except Exception:\n        r[s]='unknown'\nprint(json.dumps(r))\nPY")
                try:
                    m = json.loads(out)
                except Exception:
                    m = {"postgresql": "unknown", "nginx": "unknown", "gunicorn": "unknown", "tor": "unknown"}
                self.send_response(200)
                self.send_header("Content-Type", "application/json; charset=utf-8")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(json.dumps(m).encode("utf-8"))
                return
            if path == "/api/status/application":
                code, out = ssh_run("python3 - <<'PY'\nimport socket, json\n\n def openp(p):\n    s=socket.socket()\n    s.settimeout(0.5)\n    try:\n        s.connect(('127.0.0.1',p))\n        s.close(); return True\n    except Exception:\n        return False\napi = openp(8000) or openp(8443)\nghost = openp(2368)\nssl = openp(443)\nprint(json.dumps({'api':'online' if api else 'offline','ghost':'online' if ghost else 'offline','ssl':'ok' if ssl else 'unknown','last_backup':'n/a'}))\nPY")
                try:
                    payload = json.loads(out)
                except Exception:
                    payload = {"api": "offline", "ghost": "offline", "ssl": "unknown", "last_backup": "n/a"}
                self.send_response(200)
                self.send_header("Content-Type", "application/json; charset=utf-8")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(json.dumps(payload).encode("utf-8"))
                return
            if path == "/api/status/security":
                code, out = ssh_run("python3 - <<'PY'\nimport json, subprocess, os\n# UFW\nufw='inactive'\nc=subprocess.run(['systemctl','is-active','ufw'],stdout=subprocess.PIPE,text=True)\nif c.returncode==0 and c.stdout.strip()=='active':\n    ufw='active'\n# VPN\nvpn='disconnected'\nfor iface in ('proton0','tun0','wg0'):\n    r=subprocess.run(['bash','-lc',f'ip a show {iface} >/dev/null 2>&1 && echo up || echo down'],stdout=subprocess.PIPE,text=True)\n    if r.stdout.strip()=='up':\n        vpn='connected'; break\n# Open ports\nports=subprocess.run(['bash','-lc',"ss -tuln | awk 'NR>1 && /LISTEN/ {print $0}' | wc -l"],stdout=subprocess.PIPE,text=True).stdout.strip()\ntry:\n    ports=int(ports)\nexcept Exception:\n    ports=0\n# Access attempts\nattempts=0\nr=subprocess.run(['bash','-lc',"journalctl -u ssh -S '1 day ago' 2>/dev/null | grep -i 'failed password' | wc -l"],stdout=subprocess.PIPE,text=True)\nif r.returncode==0:\n    try: attempts=int(r.stdout.strip())\n    except Exception: attempts=0\nprint(json.dumps({'ufw':ufw,'vpn':vpn,'open_ports':ports,'access_attempts':attempts}))\nPY")
                try:
                    payload = json.loads(out)
                except Exception:
                    payload = {"ufw": "unknown", "vpn": "disconnected", "open_ports": 0, "access_attempts": 0}
                self.send_response(200)
                self.send_header("Content-Type", "application/json; charset=utf-8")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(json.dumps(payload).encode("utf-8"))
                return

        # Local variants (only if not target=vps)
        if path == "/api/status/services":
            payload = {
                "postgresql": check_service("postgresql"),
                "nginx": check_service("nginx"),
                "gunicorn": check_service("gunicorn"),
                "tor": check_service("tor"),
            }
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps(payload).encode("utf-8"))
            return

        if path == "/api/status/resources":
            payload = {
                "cpu": round(get_cpu_usage_percent(), 1),
                "memory": round(get_memory_usage_percent(), 1),
                "disk": round(get_disk_usage_percent("/"), 1),
            }
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps(payload).encode("utf-8"))
            return

        if path == "/api/status/application":
            api_ok = check_port_open("127.0.0.1", 8000) or check_port_open("127.0.0.1", 8443)
            ghost_ok = check_port_open("127.0.0.1", 2368)
            ssl_ok = check_port_open("127.0.0.1", 443)
            payload = {
                "api": "online" if api_ok else "offline",
                "ghost": "online" if ghost_ok else "offline",
                "ssl": "ok" if ssl_ok else "unknown",
                "last_backup": get_backup_age_human(),
            }
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps(payload).encode("utf-8"))
            return

        if path == "/api/status/security":
            # UFW status
            ufw_state = "inactive"
            code, out = run_cmd(["systemctl", "is-active", "ufw"])
            if code == 0 and out.strip() == "active":
                ufw_state = "active"
            else:
                code2, out2 = run_cmd("ufw status | head -n1")
                if code2 == 0 and ("active" in out2.lower() or "activo" in out2.lower()):
                    ufw_state = "active"

            # VPN detection
            vpn = "disconnected"
            for iface in ("proton0", "tun0", "wg0"):
                c, _ = run_cmd(["bash", "-lc", f"ip a show {iface} >/dev/null 2>&1 && echo up || echo down"])
                if c == 0:
                    # interpret echo result by separate check
                    c2, out3 = run_cmd(["bash", "-lc", f"ip a show {iface} >/dev/null 2>&1 && echo up || echo down"])
                    if c2 == 0 and out3.strip() == "up":
                        vpn = "connected"
                        break

            # Open ports count
            _, ports_out = run_cmd(["bash", "-lc", "ss -tuln | awk 'NR>1 && /LISTEN/ {print $0}' | wc -l"])
            try:
                open_ports = int(ports_out.strip())
            except Exception:
                open_ports = 0

            # Access attempts (SSH failed) in last day
            attempts = 0
            codej, outj = run_cmd(["bash", "-lc", "journalctl -u ssh -S '1 day ago' 2>/dev/null | grep -i 'failed password' | wc -l"])
            if codej == 0:
                try:
                    attempts = int(outj.strip())
                except Exception:
                    attempts = 0
            else:
                codeg, outg = run_cmd(["bash", "-lc", "grep -i 'Failed password' /var/log/auth.log 2>/dev/null | wc -l"])
                if codeg == 0:
                    try:
                        attempts = int(outg.strip())
                    except Exception:
                        attempts = 0

            payload = {
                "ufw": ufw_state,
                "vpn": vpn,
                "open_ports": open_ports,
                "access_attempts": attempts,
            }
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps(payload).encode("utf-8"))
            return

        if path == "/api/logs":
            try:
                tail = int((query.get("tail") or ["50"])[0])
            except Exception:
                tail = 50
            log_path = get_log_file_path()
            entries = tail_file(log_path, tail)
            payload = {
                "path": log_path,
                "entries": entries,
            }
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps(payload).encode("utf-8"))
            return

        # SSE streaming of a command execution (terminal-like)
        if path == "/api/action/stream":
            action = ("".join((query.get("action") or [""]))).strip().lower()
            target = ("".join((query.get("target") or [""]))).strip().lower()
            # Soporte de re-attach a sesión existente con token
            re_token = ("".join((query.get("token") or [""]))).strip()
            if re_token and re_token in RUNNING_PROCS:
                ent = RUNNING_PROCS[re_token]
                proc = ent["proc"]
                master_fd = ent["fd"]
                self.send_response(200)
                self.send_header("Content-Type", "text/event-stream; charset=utf-8")
                self.send_header("Cache-Control", "no-cache")
                self.send_header("Connection", "keep-alive")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                try:
                    self.wfile.write(f"data: {json.dumps({'pid': proc.pid, 'token': re_token, 'reattach': True})}\n\n".encode("utf-8"))
                    self.wfile.flush()
                except Exception:
                    return
                buffer = b""; last_keepalive = time.time()
                while True:
                    if proc.poll() is not None:
                        break
                    rlist, _, _ = select.select([master_fd], [], [], 1.0)
                    if rlist:
                        try:
                            chunk = os.read(master_fd, 4096)
                        except OSError:
                            chunk = b""
                        if chunk:
                            buffer += chunk
                            while b"\n" in buffer:
                                line, buffer = buffer.split(b"\n", 1)
                                payload = json.dumps({"line": line.decode('utf-8','ignore')})
                                self.wfile.write(f"data: {payload}\n\n".encode("utf-8"))
                                self.wfile.flush()
                    if time.time() - last_keepalive > 10:
                        self.wfile.write(b": keepalive\n\n"); self.wfile.flush(); last_keepalive = time.time()
                # proceso terminó, notificar fin y limpiar
                try:
                    self.wfile.write(f"data: {json.dumps({'ended': True, 'returncode': proc.returncode})}\n\n".encode("utf-8"))
                    self.wfile.flush()
                except Exception:
                    pass
                try:
                    os.close(master_fd)
                except Exception:
                    pass
                RUNNING_PROCS.pop(re_token, None)
                return
            commands = {
                "express": f"bash '{os.path.join(PROJECT_ROOT, 'análisis', 'mejoras', 'scripts', 'express_inteligente.sh')}' --smart",
                "backup": f"bash '{os.path.join(PROJECT_ROOT, 'backup', '00_02_zip_backup.sh')}'",
                "restart": f"bash '{os.path.join(PROJECT_ROOT, 'service', 'reiniciar_servicios.sh')}'" if os.path.isfile(os.path.join(PROJECT_ROOT, 'service', 'reiniciar_servicios.sh')) else "sudo systemctl restart gunicorn nginx || true",
            }
            cmd = commands.get(action)
            if not cmd:
                text_response(self, b"accion no soportada", content_type="text/plain; charset=utf-8", status=400)
                return

            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream; charset=utf-8")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "keep-alive")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()

            # Forzar entorno de usuario y venv, y salida line-buffered
            # Acciones por pasos y control de contexto
            exec_cmd = None
            shell_flag = True
            if action == "step_vps_delete":
                ssh_cmd = build_ssh_cmd("bash -lc 'rm -rf ~/api_bank_h2 ~/api_bank_heroku ~/scripts'")
                if not ssh_cmd:
                    text_response(self, b"vps no configurado", content_type="text/plain; charset=utf-8", status=400)
                    return
                exec_cmd = ssh_cmd
                shell_flag = False
            elif action == "step_local_clean_heroku":
                exec_cmd = "bash -lc \"rm -rf /home/markmur88/api_bank_heroku/*\""
            elif action == "step_deploy_sync":
                exec_cmd = "bash -lc \"source ~/.zshrc; envSIM >/dev/null 2>&1 || true; deploy_full -S\""
            elif action == "step_rsync_to_vps":
                exec_cmd = build_rsync_commands()
            elif action == "step_express_twice":
                exec_cmd = "bash -lc \"source ~/.zshrc; envSIM >/dev/null 2>&1 || true; express && express\""
            elif action == "vps_update":
                # Ejecutar flujo completo (mixto local/remoto)
                vps_del = build_ssh_cmd("bash -lc 'rm -rf ~/api_bank_h2 ~/api_bank_heroku ~/scripts' ")
                local_clean = "bash -lc \"rm -rf /home/markmur88/api_bank_heroku/*\""
                sync_cmds = build_rsync_commands()
                deploy = "bash -lc \"source ~/.zshrc; envSIM >/dev/null 2>&1 || true; deploy_full -S\""
                expr2 = "bash -lc \"source ~/.zshrc; envSIM >/dev/null 2>&1 || true; express && express\""
                chain = []
                if vps_del:
                    chain.append(" ".join(vps_del))
                chain.append(local_clean)
                chain.append(deploy)
                chain.append(sync_cmds)
                chain.append(expr2)
                exec_cmd = " && ".join(chain)
            else:
                # Fallback a comandos estándar
                if target == "vps":
                    ssh_cmd = build_ssh_cmd(cmd)
                    if not ssh_cmd:
                        text_response(self, b"vps no configurado", content_type="text/plain; charset=utf-8", status=400)
                        return
                    exec_cmd = ssh_cmd
                    shell_flag = False
                else:
                    exec_cmd = f"bash -lc \"source ~/.zshrc; envSIM >/dev/null 2>&1 || true; {cmd}\""
                    shell_flag = True

            # Lanzar en PTY para permitir entrada interactiva
            master_fd, slave_fd = pty.openpty()
            try:
                proc = subprocess.Popen(
                    exec_cmd,
                    shell=shell_flag,
                    stdin=slave_fd,
                    stdout=slave_fd,
                    stderr=slave_fd,
                    bufsize=0,
                    close_fds=True,
                    text=False,
                )
            except Exception as exc:
                os.close(master_fd)
                os.close(slave_fd)
                payload = json.dumps({"error": str(exc)})
                self.wfile.write(f"data: {payload}\n\n".encode("utf-8"))
                self.wfile.flush()
                return
            finally:
                try:
                    os.close(slave_fd)
                except Exception:
                    pass

            token = f"{proc.pid}-{int(time.time())}"
            RUNNING_PROCS[token] = {"proc": proc, "fd": master_fd}

            # announce pid y token
            try:
                self.wfile.write(f"data: {json.dumps({'pid': proc.pid, 'token': token, 'started': True})}\n\n".encode("utf-8"))
                self.wfile.flush()
            except Exception:
                pass

            buffer = b""
            last_keepalive = time.time()
            try:
                while True:
                    if proc.poll() is not None:
                        # Leer pendiente
                        while True:
                            rlist, _, _ = select.select([master_fd], [], [], 0)
                            if not rlist:
                                break
                            try:
                                chunk = os.read(master_fd, 4096)
                            except OSError:
                                break
                            if not chunk:
                                break
                            buffer += chunk
                            while b"\n" in buffer:
                                line, buffer = buffer.split(b"\n", 1)
                                payload = json.dumps({"line": line.decode('utf-8', 'ignore')})
                                self.wfile.write(f"data: {payload}\n\n".encode("utf-8"))
                                self.wfile.flush()
                        break

                    rlist, _, _ = select.select([master_fd], [], [], 1.0)
                    if rlist:
                        try:
                            chunk = os.read(master_fd, 4096)
                        except OSError:
                            chunk = b""
                        if chunk:
                            buffer += chunk
                            while b"\n" in buffer:
                                line, buffer = buffer.split(b"\n", 1)
                                payload = json.dumps({"line": line.decode('utf-8', 'ignore')})
                                self.wfile.write(f"data: {payload}\n\n".encode("utf-8"))
                                self.wfile.flush()
                    # keepalive
                    if time.time() - last_keepalive > 10:
                        self.wfile.write(b": keepalive\n\n")
                        self.wfile.flush()
                        last_keepalive = time.time()
                ret = proc.returncode
                self.wfile.write(f"data: {json.dumps({'ended': True, 'returncode': ret})}\n\n".encode("utf-8"))
                self.wfile.flush()
            except Exception:
                # cliente desconectado: NO terminar el proceso; mantener fd/token para re-attach
                return
            finally:
                # Cerrar y limpiar SOLO si el proceso terminó
                if proc.poll() is not None:
                    try:
                        os.close(master_fd)
                    except Exception:
                        pass
                    RUNNING_PROCS.pop(token, None)
            return

        text_response(self, b"Not found", content_type="text/plain; charset=utf-8", status=404)

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path
        length = int(self.headers.get("Content-Length", "0") or 0)
        try:
            body = self.rfile.read(length) if length > 0 else b"{}"
            data = json.loads(body.decode("utf-8")) if body else {}
        except Exception:
            data = {}

        if path == "/api/action/input":
            token = (data.get("token") or "").strip()
            text = data.get("text")
            ent = RUNNING_PROCS.get(token)
            if not ent or not text:
                json_response(self, {"ok": False, "error": "token o texto inválido"}, status=400)
                return
            try:
                os.write(ent["fd"], (text + "\n").encode("utf-8"))
                json_response(self, {"ok": True})
            except Exception as exc:
                json_response(self, {"ok": False, "error": str(exc)}, status=500)
            return

        if path == "/api/action":
            action = (data.get("action") or "").strip().lower()
            target = (data.get("target") or "").strip().lower()
            # Map actions to commands
            commands = {
                "express": f"bash '{os.path.join(PROJECT_ROOT, 'análisis', 'mejoras', 'scripts', 'express_inteligente.sh')}' --smart",
                "backup": f"bash '{os.path.join(PROJECT_ROOT, 'backup', '00_02_zip_backup.sh')}'",
                "restart": f"bash '{os.path.join(PROJECT_ROOT, 'service', 'reiniciar_servicios.sh')}'" if os.path.isfile(os.path.join(PROJECT_ROOT, 'service', 'reiniciar_servicios.sh')) else "sudo systemctl restart gunicorn nginx || true",
                "emergency": "sudo ufw enable && sudo ufw default deny incoming || true",
                "vps_update": "__COMPOSITE__",
            }

            cmd = commands.get(action)
            if not cmd:
                json_response(self, {"ok": False, "error": "acción no soportada"}, status=400)
                return

            def _runner():
                # Run command in background, log output if possible
                log_path = get_log_file_path() or os.path.join(PROJECT_ROOT, ".logs", "express_intelligent.log")
                os.makedirs(os.path.dirname(log_path), exist_ok=True)
                with open(log_path, "a", encoding="utf-8") as lf:
                    lf.write(f"\n[{time.strftime('%Y-%m-%d %H:%M:%S')}] ACTION {action}: {cmd}\n")
                # Ensure stdout/stderr go to the same log file for visibility in dashboard
                if action == "vps_update":
                    # Compose the multi-step process
                    vps_del = build_ssh_cmd("bash -lc 'rm -rf ~/api_bank_h2 ~/api_bank_heroku ~/scripts' ")
                    local_clean = f"bash -lc \"rm -rf /home/markmur88/api_bank_heroku/*\""
                    sync_cmds = build_rsync_commands()
                    deploy = f"bash -lc \"source ~/.zshrc; envSIM >/dev/null 2>&1 || true; deploy_full -S\""
                    expr2 = f"bash -lc \"source ~/.zshrc; envSIM >/dev/null 2>&1 || true; express && express\""
                    chain = []
                    if vps_del:
                        chain.append(" ".join(vps_del))
                    chain.append(local_clean)
                    chain.append(deploy)
                    chain.append(sync_cmds)
                    chain.append(expr2)
                    full = " && ".join(chain)
                    wrapped = f"{full} >> '{log_path}' 2>&1"
                    subprocess.Popen(wrapped, shell=True)
                else:
                    wrapped = f"{cmd} >> '{log_path}' 2>&1"
                    subprocess.Popen(wrapped, shell=True)

            # Start process and try to return a PID by spawning directly once to capture
            log_path = get_log_file_path() or os.path.join(PROJECT_ROOT, ".logs", "express_intelligent.log")
            os.makedirs(os.path.dirname(log_path), exist_ok=True)
            with open(log_path, "a", encoding="utf-8") as lf:
                lf.write(f"\n[{time.strftime('%Y-%m-%d %H:%M:%S')}] ACTION {action}: {cmd}\n")
            if action == "vps_update":
                vps_del = build_ssh_cmd("bash -lc 'rm -rf ~/api_bank_h2 ~/api_bank_heroku ~/scripts' ")
                local_clean = f"bash -lc \"rm -rf /home/markmur88/api_bank_heroku/*\""
                sync_cmds = build_rsync_commands()
                deploy = f"bash -lc \"source ~/.zshrc; envSIM >/dev/null 2>&1 || true; deploy_full -S\""
                expr2 = f"bash -lc \"source ~/.zshrc; envSIM >/dev/null 2>&1 || true; express && express\""
                chain = []
                if vps_del:
                    chain.append(" ".join(vps_del))
                chain.append(local_clean)
                chain.append(deploy)
                chain.append(sync_cmds)
                chain.append(expr2)
                wrapped_for_pid = f"{' && '.join(chain)} >> '{log_path}' 2>&1"
            else:
                wrapped_for_pid = f"{cmd} >> '{log_path}' 2>&1"
            try:
                proc = subprocess.Popen(wrapped_for_pid, shell=True)
                pid = proc.pid
            except Exception:
                pid = None
                # Fallback thread if needed
                threading.Thread(target=_runner, daemon=True).start()
            json_response(self, {"ok": True, "action": action, "pid": pid})
            return

        if path == "/api/action/kill":
            pid = data.get("pid")
            try:
                pid = int(pid)
            except Exception:
                json_response(self, {"ok": False, "error": "pid inválido"}, status=400)
                return
            try:
                os.kill(pid, 15)
            except Exception as exc:
                json_response(self, {"ok": False, "error": str(exc)})
                return
            json_response(self, {"ok": True, "killed": pid})
            return

        json_response(self, {"ok": False, "error": "ruta no encontrada"}, status=404)


def run(host: str = "127.0.0.1", port: int = 8765):
    httpd = HTTPServer((host, port), Handler)
    print(f"Dashboard server corriendo en http://{host}:{port}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        httpd.server_close()


if __name__ == "__main__":
    run()


