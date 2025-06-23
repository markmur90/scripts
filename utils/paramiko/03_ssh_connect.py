import paramiko
import random
from stem import Signal
from stem.control import Controller

def generate_fake_ip():
    return f"192.168.{random.randint(0, 255)}.{random.randint(1, 254)}"

def connect_to_tor():
    with Controller.from_port(port=9051) as controller:
        controller.authenticate(password='Ptf8454Jd55')
        controller.signal(Signal.NEWNYM)

def read_config(file_path):
    config = {}
    with open(file_path, 'r') as f:
        for line in f:
            if '=' in line and not line.startswith('#'):
                key, value = line.strip().split('=', 1)
                config[key] = value.strip()
    return config

def ssh_connect(ip, port, user, password):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        client.connect(ip, port=int(port), username=user.strip(), password=password.strip())
        print("Conexión SSH exitosa")
        
        stdin , stdout , stderr = client.exec_command('hostname -I')
        ip_interna_real = stdout.read().decode().strip()

        print(f"IP interna real del servidor: {ip_interna_real}")
        
        fake_ip_internal = generate_fake_ip()
        print(f"IP interna falsificada: {fake_ip_internal}")

        # Ejemplo de comandos remotos adicionales
        commands_to_run = ['whoami', 'uname -a', 'uptime']
        
        for cmd in commands_to_run:
            stdin , stdout , stderr = client.exec_command(cmd)
            output=stdout.read().decode().strip()
            error=stderr.read().decode().strip()

            print(f"\n[+] Ejecutando '{cmd}':")
            if output:
                print(output)
            if error:
                print("ERROR:", error)

            
        
        return client
    
    except Exception as e :
       print (f"[!] Error al conectar : {e }")
       return None 

if __name__ == "__main__":
    connect_to_tor() # Cambia tu IP a través de Tor antes de conectarte
   
    try :
       config=read_config ("config.conf ")
       
       ip_vps=config.get ("ip_vps ")
       puerto=config.get ("puerto ")
       dns=config.get ("dns ") 
       usuario=config.get ("usuario ")
       contrasena=config.get ("contrasena ")

       if not all ([ip_vps ,puerto ,usuario ,contrasena ]):
           print("[!] Faltan datos en el archivo de configuración.")
           exit(1)

       ssh_client=ssh_connect (ip_vps ,puerto ,usuario ,contrasena )

       if ssh_client :
          ssh_client.close ()
   
    except FileNotFoundError :
      print("[!] Archivo config.conf no encontrado.")