import os
import socket
import subprocess
import logging
import requests
from requests.auth import HTTPBasicAuth
from dotenv import load_dotenv
import socks

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

def intentar_conexion(ip, puerto, intentos=3):
    """Intenta conectar al servidor un número específico de veces."""
    for i in range(intentos):
        try:
            # Crear un socket para conectarse al servidor
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)  # Tiempo de espera de 5 segundos
            result = sock.connect_ex((ip, puerto))
            if result == 0:
                logging.info(f"Conexión exitosa al servidor {ip}:{puerto} en el intento {i+1}")
                return True
            else:
                logging.warning(f"No se pudo conectar al servidor {ip}:{puerto} en el intento {i+1}")
        except socket.gaierror as e:
            logging.error(f"Error al resolver la dirección {ip}: {e}")
        except socket.timeout as e:
            logging.warning(f"Tiempo de espera agotado al conectar a {ip}:{puerto} en el intento {i+1}")
        except Exception as e:
            logging.error(f"Error al conectar a {ip}:{puerto} en el intento {i+1}: {e}")
    return False

def realizar_solicitud(url, usuario, password, proxies):
    """Realiza una solicitud HTTP con autenticación básica."""
    try:
        # Configurar el socket para usar el proxy SOCKS
        socks.set_default_proxy(socks.SOCKS5, "localhost", 9050)
        socket.socket = socks.socksocket

        logging.info(f"Realizando solicitud HTTP a {url} con usuario {usuario}")
        response = requests.get(url, auth=HTTPBasicAuth(usuario, password), proxies=proxies)
        response.raise_for_status()  # Lanzará una excepción para HTTP errors
        return response.status_code, response.text
    except requests.exceptions.HTTPError as http_err:
        logging.error(f"HTTP error occurred: {http_err}")
        return http_err.response.status_code, None
    except requests.exceptions.ConnectionError as conn_err:
        logging.error(f"Connection error occurred: {conn_err}")
        return None, None
    except requests.exceptions.Timeout as timeout_err:
        logging.error(f"Timeout error occurred: {timeout_err}")
        return None, None
    except requests.exceptions.RequestException as req_err:
        logging.error(f"Request error occurred: {req_err}")
        return None, None
    except Exception as e:
        logging.error(f"An unexpected error occurred: {e}")
        return None, None

def main():
    dns = obtener_dns()
    ip_servidor = '80.78.30.242'
    puerto = 9181

    logging.info(f"DNS: {dns}")

    if intentar_conexion(ip_servidor, puerto):
        logging.info(f"Se ha establecido una conexión exitosa con {ip_servidor}:{puerto}")
    else:
        logging.error(f"No se pudo establecer una conexión con {ip_servidor}:{puerto}")
        return

    # URL del servidor con autenticación
    url_servidor = f"http://{ip_servidor}:{puerto}"
    usuario_autenticacion = os.getenv('AUTH_USER')
    password_autenticacion = os.getenv('AUTH_PASS')

    if usuario_autenticacion and password_autenticacion:
        logging.info(f"Intentando autenticar con usuario: {usuario_autenticacion}")
        status_code, respuesta_servidor = realizar_solicitud(url_servidor, usuario_autenticacion, password_autenticacion, proxies)
        if status_code == 200:
            logging.info(f"Autenticación exitosa. Usuario: {usuario_autenticacion} ingresó correctamente.")
            logging.info(f"Respuesta del servidor: {respuesta_servidor}")
        elif status_code:
            logging.warning(f"Autenticación fallida. Código de estado: {status_code}")
        else:
            logging.warning("No se pudo obtener una respuesta del servidor.")
    else:
        logging.warning("Credenciales de autenticación no configuradas.")

if __name__ == "__main__":
    main()