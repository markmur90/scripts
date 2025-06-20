import os
import socket
import subprocess
import logging
import requests
from requests.auth import HTTPBasicAuth
from dotenv import load_dotenv

# Cargar variables de entorno desde un archivo .env
load_dotenv()

# Configurar proxy
http_proxy = os.getenv('HTTP_PROXY')
https_proxy = os.getenv('HTTPS_PROXY')

proxies = {
    'http': http_proxy,
    'https': https_proxy,
} if http_proxy and https_proxy else None

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("activity.log"),
        logging.StreamHandler()
    ]
)

def obtener_usuario():
    """Obtiene el nombre de usuario actual del sistema."""
    return os.getenv('USER') or os.getenv('username') or 'Usuario desconocido'

def obtener_dns():
    """Obtiene el servidor DNS configurado en el sistema."""
    try:
        # Intentar obtener el DNS a través del sistema operativo
        result = subprocess.run(['cat', '/etc/resolv.conf'], capture_output=True, text=True)
        for line in result.stdout.splitlines():
            if line.startswith('nameserver'):
                return line.split()[-1]
    except Exception as e:
        logging.error(f"Error al obtener el DNS: {e}")
    return 'DNS desconocido'

def obtener_ip_servidor(ip, puerto):
    """Obtiene la dirección IP y puerto del servidor."""
    try:
        # Crear un socket para conectarse al servidor
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)  # Tiempo de espera de 5 segundos
        result = sock.connect_ex((ip, puerto))
        if result == 0:
            return f"Conexión exitosa al servidor {ip}:{puerto}"
        else:
            return f"No se pudieron conectar al servidor {ip}:{puerto}"
    except socket.gaierror as e:
        logging.error(f"Error al resolver la dirección {ip}: {e}")
        return 'Dirección desconocida'
    except socket.timeout as e:
        logging.error(f"Tiempo de espera agotado al conectar a {ip}:{puerto}")
        return 'Tiempo de espera agotado'
    except Exception as e:
        logging.error(f"Error al conectar a {ip}:{puerto}: {e}")
        return 'Error desconocido'

def realizar_solicitud(url, usuario, password):
    """Realiza una solicitud HTTP con autenticación básica."""
    try:
        response = requests.get(url, auth=HTTPBasicAuth(usuario, password), proxies=proxies)
        response.raise_for_status()  # Lanzará una excepción para HTTP errors
        return response.text
    except requests.exceptions.RequestException as e:
        logging.error(f"Error en la solicitud HTTP: {e}")
        return None

def main():
    usuario = obtener_usuario()
    dns = obtener_dns()
    ip_servidor = '80.78.30.242'
    puerto = 9181
    resultado_conexion = obtener_ip_servidor(ip_servidor, puerto)

    logging.info(f"Usuario: {usuario}")
    logging.info(f"DNS: {dns}")
    logging.info(resultado_conexion)

    # URL del servidor con autenticación
    url_servidor = f"http://{ip_servidor}:{puerto}"
    usuario_autenticacion = os.getenv('AUTH_USER')
    password_autenticacion = os.getenv('AUTH_PASS')

    if usuario_autenticacion and password_autenticacion:
        respuesta_servidor = realizar_solicitud(url_servidor, usuario_autenticacion, password_autenticacion)
        if respuesta_servidor:
            logging.info(f"Respuesta del servidor: {respuesta_servidor}")
        else:
            logging.warning("No se pudo obtener una respuesta del servidor.")
    else:
        logging.warning("Credenciales de autenticación no configuradas.")

if __name__ == "__main__":
    main()