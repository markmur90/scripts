import socket
import subprocess
import dns.resolver
import requests
import os
import re

def extract_ips_from_file(filename):
    """Extrae todas las IPs del archivo de servidores"""
    ips = []
    filepath = os.path.join(os.path.dirname(__file__), filename)
    
    try:
        with open(filepath, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    # Buscar IPs en la línea usando regex
                    ip_pattern = r'\b(?:\d{1,3}\.){3}\d{1,3}\b'
                    found_ips = re.findall(ip_pattern, line)
                    ips.extend(found_ips)
    except FileNotFoundError:
        print(f"Error: No se encontró el archivo {filepath}")
        return []
    
    # Eliminar duplicados manteniendo el orden
    unique_ips = []
    for ip in ips:
        if ip not in unique_ips:
            unique_ips.append(ip)
    
    return unique_ips

def get_ip_info(ip_address):
    info = {}

    # Obtener el nombre de dominio asociado a la IP
    try:
        info['domain_name'] = socket.gethostbyaddr(ip_address)[0]
    except socket.herror:
        info['domain_name'] = "No domain name found"

    # Obtener registros DNS
    try:
        answers = dns.resolver.resolve(ip_address, 'PTR')
        info['ptr_records'] = [answer.to_text() for answer in answers]
    except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN, dns.resolver.Timeout):
        info['ptr_records'] = "No PTR records found"

    # Verificar si la IP responde a pings
    info['ping_response'] = subprocess.run(['ping', '-c', '4', ip_address], stdout=subprocess.PIPE).stdout.decode()

    # Leer puertos del archivo
    ports_to_scan = []
    ports_file = os.path.join(os.path.dirname(__file__), 'puertos')
    
    try:
        with open(ports_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):  # Ignorar líneas vacías y comentarios
                    try:
                        port = int(line)
                        ports_to_scan.append(port)
                    except ValueError:
                        print(f"Advertencia: '{line}' no es un puerto válido")
    except FileNotFoundError:
        print(f"Error: No se encontró el archivo {ports_file}")
        return info

    # Verificar servicios abiertos en los puertos especificados
    info['open_ports'] = {}
    print(f"Escaneando {len(ports_to_scan)} puertos...")
    
    for port in ports_to_scan:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1)  # Timeout de 1 segundo para cada puerto
        result = sock.connect_ex((ip_address, port))
        if result == 0:
            info['open_ports'][port] = "Open"
        sock.close()

    # Obtener información de geolocalización (usando una API externa)
    try:
        response = requests.get(f'http://ip-api.com/json/{ip_address}')
        info['geo_info'] = response.json()
    except requests.RequestException:
        info['geo_info'] = "Unable to retrieve geolocation information"

    return info

def main():
    # Extraer IPs del archivo servidores
    ips = extract_ips_from_file('servidores')
    
    if not ips:
        print("No se encontraron IPs para escanear.")
        return
    
    print(f"Se encontraron {len(ips)} servidores disponibles:")
    print("-" * 50)
    
    # Mostrar lista de servidores con números
    for i, ip in enumerate(ips, 1):
        print(f"{i:2d}. {ip}")
    
    print("-" * 50)
    print("0. Salir")
    print()
    
    # Pedir al usuario que elija
    while True:
        try:
            choice = input("Elige el número del servidor a escanear (0 para salir): ")
            choice_num = int(choice)
            
            if choice_num == 0:
                print("Saliendo...")
                return
            elif 1 <= choice_num <= len(ips):
                selected_ip = ips[choice_num - 1]
                break
            else:
                print(f"Por favor, elige un número entre 0 y {len(ips)}")
        except ValueError:
            print("Por favor, ingresa un número válido")
    
    print(f"\n🔍 Escaneando servidor seleccionado: {selected_ip}")
    print("=" * 60)
    
    try:
        info = get_ip_info(selected_ip)
        
        print(f"Nombre de Dominio: {info['domain_name']}")
        print(f"Registros PTR: {info['ptr_records']}")
        print(f"Puertos Abiertos: {info['open_ports']}")
        
        if isinstance(info['geo_info'], dict):
            geo = info['geo_info']
            print(f"País: {geo.get('country', 'N/A')}")
            print(f"Ciudad: {geo.get('city', 'N/A')}")
            print(f"ISP: {geo.get('isp', 'N/A')}")
            print(f"Región: {geo.get('regionName', 'N/A')}")
            print(f"Zona horaria: {geo.get('timezone', 'N/A')}")
        else:
            print(f"Información de Geolocalización: {info['geo_info']}")
            
    except Exception as e:
        print(f"Error escaneando {selected_ip}: {e}")

if __name__ == "__main__":
    main()
