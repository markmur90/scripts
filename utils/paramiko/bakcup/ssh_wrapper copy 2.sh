#!/bin/bash  

CONFIG_FILE="/home/markmur88/scripts/utils/paramiko/config.conf"
SCRIPT_PY="/home/markmur88/scripts/utils/paramiko/ssh_connect.py"

function check_tor () {
if systemctl is-active --quiet tor; then 
echo "[+] Servicio Tor corriendo."
else   
echo "[-] Iniciando servicio Tor..."
sudo service tor start || {
echo "[!] No se pudo iniciar el servicio 'tor'. ¿Tienes permisos root?"
exit 1   
}
fi    
}

function verificar_archivos () {
if [ ! -f "$ CONFIG_FILE "]; then   
echo "[!] Archivo $ CONFIG_FILE no encontrado ."
exit 1   
fi   

if [ ! -f "$ SCRIPT_PY "]; then   
echo "[!] Script $ SCRIPT_PY no encontrado ."
exit 1   
fi   

}

function menu () {
clear  
echo "┌──────────────┐"
echo "│ Wrapper SSH │"
echo "└──────────────┘"

read -p $"¿Quieres usar configuración existente o crear una nueva? [E/C]: " eleccion  

case "$ eleccion $" in    
E | e ) echo "[*] Usando configuración actual." ;;    
C | c ) echo "[*] Creando nueva configuración..."    

cat > "$ CONFIG_FILE " <<EOL     
ip_vps=tu.ip.vpshere.com     
port_vps=tu.puerto.aqui     
dns_vsp=tu.dns.aqui     
user_vs=admin_user_here     
pass_vs=admin_pass_here     
tor_password=aquí_va_clave_de_TOR      
EOL      
;;    

*) echo "[!] Opción inválida"; exit ;;
esac      
}

menu  

check_tor  
verificar_archivos  

# Correr script Python infinitamente con cambio automático de IP por TOR cada X segundos 

while true ; do python3 "$ SCRIPT_PY "; sleep $((INTERVALO_SEGUNDOS + aleatorio )) ; done &