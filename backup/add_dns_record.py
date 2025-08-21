import subprocess

def add_dns_record(zone, record_type, name, data, ttl=3600, key_file=None, key_name=None):
    command = ['nsupdate']
    if key_file and key_name:
        command.extend(['-k', f'{key_file}:{key_name}'])

    update_content = f"""
    server your.dns.server
    zone {zone}
    update delete {name} {record_type}
    update add {name} {ttl} {record_type} {data}
    send
    """
    process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate(input=update_content.encode())

    if process.returncode == 0:
        print(f"Registro DNS agregado exitosamente: {name} {record_type} {data}")
    else:
        print(f"Error al agregar el registro DNS: {stderr.decode()}")

def main():
    zone = 'example.com.'  # Zona DNS
    record_type = 'A'  # Tipo de registro (A, CNAME, MX, etc.)
    name = 'subdomain.example.com.'  # Nombre del registro
    data = '192.168.1.1'  # Datos del registro (IP, dominio, etc.)
    ttl = 3600  # Tiempo de vida del registro en segundos
    key_file = '/etc/bind/rndc.key'  # Ruta al archivo de clave TSIG
    key_name = 'rndc-key'  # Nombre de la clave TSIG

    add_dns_record(zone, record_type, name, data, ttl, key_file, key_name)

if __name__ == "__main__":
    main()
