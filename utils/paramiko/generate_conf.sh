#!/bin/bash 

echo "Ingresando datos para configuración..."

read -p "IP del VPS: " ipvps  
read -p "Puerto SSH: " port  
read -p "DNS asociado (opcional): " dns  
read -p "Usuario SSH: " user  
read -s -p $'\n'"Contraseña SSH: $'\n'" pass  

cat > config.conf <</EOL>