import paramiko
from stem import Signal
from stem.control import Controller

def generate_fake_ip():
    # Genera una dirección IP interna falsa (por ejemplo, en el rango privado)
    return "192.168." + str(random.randint(0, 255)) + "." + str(random.randint(1, 254))

def connect_to_tor():
    with Controller.from_port(port=9051) as controller:
        controller.authenticate(password='Ptf8454Jd55')
        controller.signal(Signal.NEWNYM)

def ssh_connect(ip, port, user, password):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        client.connect(ip, port=port, username=user, password=password)
        print("Conexión exitosa")
        return client
    except paramiko.AuthenticationException:
        print("Error de autenticación")
        return None
    except paramiko.SSHException as sshException:
        print(f"Error al establecer conexión SSH: {sshException}")
        return None

if __name__ == "__main__":
    ip_vps = '80.78.30.242'
    puerto = '9181'
    dns = '504e1ef2.host.njalla.net'
    usuario = '493069k1'
    contraseña = 'bar1588623'

    fake_ip_internal=vps.generate_fake_ip()
    connect_to_tor()

    ssh_client = ssh_connect(ip_vps,puerto ,usuario ,contraseña)

    if ssh_client:
       stdin ,stdout ,stderr=ssh_client.exec_command('hostname -I')
       print(stdout.read().decode())
       ssh_client.close()