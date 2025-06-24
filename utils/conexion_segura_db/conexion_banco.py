from django.db import models
from datetime import datetime
import json
import dns.resolver
import requests
import socket
import os

DNS_BANCO = "160.83.58.33"
DOMINIO_BANCO = "internet.dbbank-de"
RED_SEGURA_PREFIX = "193.150.166."
TIMEOUT = 10

# ==== Directorios de schemas y logs ====
BASE_SCHEMA_DIR = os.path.join("schemas", "transferencias")
os.makedirs(BASE_SCHEMA_DIR, exist_ok=True)
TRANSFER_LOG_DIR = BASE_SCHEMA_DIR  # logs por transferencia
GLOBAL_LOG_FILE = os.path.join(TRANSFER_LOG_DIR, 'global_errors.log')

def obtener_ruta_schema_transferencia(payment_id: str) -> str:
    carpeta = os.path.join(BASE_SCHEMA_DIR, str(payment_id))
    os.makedirs(carpeta, exist_ok=True)
    return carpeta


class LogTransferencia(models.Model):
    registro = models.CharField(max_length=64, help_text="Puede ser payment_id o session_id")
    tipo_log = models.CharField(max_length=20, choices=[
        ('AUTH', 'Autenticación'),
        ('TRANSFER', 'Transferencia'),
        ('XML', 'Generación XML'),
        ('AML', 'Generación AML'),
        ('ERROR', 'Error'),
        ('SCA', 'Autenticación fuerte'),
        ('OTP', 'Generación OTP'),
    ])
    contenido = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Log de Transferencia'
        verbose_name_plural = 'Logs de Transferencias'

    def __str__(self):
        return f"{self.tipo_log} - {self.registro} - {self.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
    

def registrar_log(
    registro: str,
    tipo_log: str = 'TRANSFER',
    headers_enviados: dict = None, # type: ignore
    request_body: any = None, # type: ignore
    response_headers: dict = None, # type: ignore
    response_text: str = None, # type: ignore
    error: any = None, # type: ignore
    extra_info: str = None # type: ignore
):

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = "\n" + "=" * 80 + "\n"
    entry += f"Fecha y hora: {timestamp}\n" + "=" * 80 + "\n"

    if extra_info:
        entry += f"=== Info ===\n{extra_info}\n\n"
    if headers_enviados:
        try:
            entry += "=== Headers enviados ===\n" + json.dumps(headers_enviados, indent=4) + "\n\n"
        except Exception:
            entry += "=== Headers enviados (sin formato) ===\n" + str(headers_enviados) + "\n\n"
    if request_body:
        try:
            entry += "=== Body de la petición ===\n" + json.dumps(request_body, indent=4, default=str) + "\n\n"
        except Exception:
            entry += "=== Body de la petición (sin formato) ===\n" + str(request_body) + "\n\n"
    if response_headers:
        try:
            entry += "=== Response Headers ===\n" + json.dumps(response_headers, indent=4) + "\n\n"
        except Exception:
            entry += "=== Response Headers (sin formato) ===\n" + str(response_headers) + "\n\n"
    if response_text:
        entry += "=== Respuesta ===\n" + str(response_text) + "\n\n"
    if error:
        entry += "=== Error ===\n" + str(error) + "\n"

    carpeta = obtener_ruta_schema_transferencia(registro)
    log_path = os.path.join(carpeta, f"transferencia_{registro}.log")
    try:
        with open(log_path, 'a', encoding='utf-8') as f:
            f.write(entry)
    except Exception as e:
        with open(GLOBAL_LOG_FILE, 'a', encoding='utf-8') as gf:
            gf.write(f"[{timestamp}] ERROR AL GUARDAR EN ARCHIVO {registro}.log: {str(e)}\n")

    try:
        LogTransferencia.objects.create(
            registro=registro,
            tipo_log=tipo_log or 'ERROR',
            contenido=entry
        )
    except Exception as e:
        with open(GLOBAL_LOG_FILE, 'a', encoding='utf-8') as gf:
            gf.write(f"[{timestamp}] ERROR AL GUARDAR LOG EN DB para {registro}: {str(e)}\n")

    if error:
        with open(GLOBAL_LOG_FILE, 'a', encoding='utf-8') as gf:
            gf.write(f"[{timestamp}] ERROR [{registro}]: {str(error)}\n")
            
     

def esta_en_red_segura():
    try:
        hostname = socket.gethostname()
        ip_local = socket.gethostbyname(hostname)
        return ip_local.startswith(RED_SEGURA_PREFIX)
    except Exception:
        return False

def resolver_ip_dominio(dominio):
    resolver = dns.resolver.Resolver()
    resolver.nameservers = [DNS_BANCO]
    try:
        respuesta = resolver.resolve(dominio)
        ip = respuesta[0].to_text() # type: ignore
        print(f"🔐 Resuelto {dominio} → {ip}")
        return ip
    except Exception as e:
        registrar_log("conexion", f"❌ Error DNS bancario: {e}")
        return None

def hacer_request_seguro(dominio, path="/api", metodo="GET", datos=None, headers=None):
    headers = headers or {}

    if esta_en_red_segura():
        ip_destino = resolver_ip_dominio(dominio)
        if not ip_destino:
            registrar_log("conexion", f"❌ No se pudo resolver {dominio} vía DNS bancario.")
            return None
    else:
        if os.getenv("ALLOW_FAKE_BANK", "false").lower() == "true":
            ip_destino = "127.0.0.1"
            dominio = "mock.bank.test"
            puerto = 443

            if not puerto_activo(ip_destino, puerto):
                registrar_log("conexion", f"❌ Mock local en {ip_destino}:{puerto} no está activo. Cancelando.")
                return None

            registrar_log("conexion", f"⚠️ Red no segura. Usando servidor local mock en {ip_destino}:{puerto}.")
        else:
            registrar_log("conexion", "🚫 Red no segura y ALLOW_FAKE_BANK desactivado. Cancelando.")
            return None

    url = f"https://{ip_destino}{path}"
    headers["Host"] = dominio

    try:
        if metodo.upper() == "GET":
            r = requests.get(url, headers=headers, timeout=TIMEOUT, verify=False)
        else:
            r = requests.post(url, headers=headers, json=datos, timeout=TIMEOUT, verify=False)
        registrar_log("conexion", f"✅ Petición a {dominio}{path} → {r.status_code}")
        return r
    except requests.RequestException as e:
        registrar_log("conexion", f"❌ Error en petición HTTPS a {dominio}: {str(e)}")
        return None

def puerto_activo(host, puerto, timeout=2):
    try:
        with socket.create_connection((host, puerto), timeout=timeout):
            return True
    except Exception:
        return False


# ============================
# Wrapper inteligente por sesión
# ============================
from django.conf import settings

def hacer_request_banco(request, path="/api", metodo="GET", datos=None, headers=None):
    usar_conexion = request.session.get("usar_conexion_banco", False)
    if usar_conexion:
        return hacer_request_seguro(DOMINIO_BANCO, path, metodo, datos, headers)
    # Modo normal/local
    registrar_log("conexion", "🔁 Usando modo local de conexión bancaria")
    url = f"https://80.78.30.242:9001{path}"
    try:
        respuesta = requests.request(metodo, url, json=datos, headers=headers, timeout=TIMEOUT)
        return respuesta.json()
    except Exception as e:
        registrar_log("conexion", f"❌ Error al conectar al VPS mock: {e}")
        return None
