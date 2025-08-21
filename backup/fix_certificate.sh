#!/bin/bash

# Obtener el certificado del servidor
openssl s_client -connect 80.78.30.242 -showcerts > certificado.crt

# Copiar el certificado al directorio de CA
sudo cp certificado.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Verificar que el certificado ha sido añadido correctamente
openssl s_client -connect 80.78.30.242

# Instalar o reinstalar ca-certificates
sudo apt-get update
sudo apt-get install --reinstall ca-certificates

# Actualizar las listas de paquetes
sudo apt-get update
