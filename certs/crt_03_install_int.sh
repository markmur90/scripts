#!/bin/bash

# Instala el certificado intermedio para Deutsche Bank

SERVER="193.150.166.1"
PORT=443
INTERMEDIATE_CERT="/usr/local/share/ca-certificates/deutsche_bank_intermediate.crt"

# Verificar si ya está instalado
if [ -f "$INTERMEDIATE_CERT" ]; then
  echo "El certificado intermedio ya está instalado. Actualizando..."
  rm "$INTERMEDIATE_CERT"
fi

# Obtener la cadena de certificados
certs=$(openssl s_client -showcerts -connect $SERVER:$PORT </dev/null 2>/dev/null | sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p')
if [ -z "$certs" ]; then
  echo "❌ Error: No se pudo obtener la cadena de certificados de $SERVER:$PORT"
  exit 1
fi

# Contar certificados
num_certs=$(grep -c 'BEGIN CERTIFICATE' <<< "$certs")
if [ "$num_certs" -lt 2 ]; then
  echo "❌ Error: Se esperaban al menos 2 certificados en la cadena, se encontraron $num_certs"
  exit 1
fi

# Extraer el segundo certificado (intermedio)
echo "$certs" | awk '/BEGIN CERTIFICATE/{n++; if(n==2) print} /END CERTIFICATE/{if(n==2) print; if(n==2) exit}' > "$INTERMEDIATE_CERT"
if [ ! -s "$INTERMEDIATE_CERT" ]; then
  echo "❌ Error: No se pudo extraer el certificado intermedio"
  exit 1
fi

# Actualizar los certificados CA
update-ca-certificates

echo "✅ Certificado intermedio instalado correctamente en $INTERMEDIATE_CERT"