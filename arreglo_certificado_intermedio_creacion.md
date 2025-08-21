# Creación certificado intermedio
_Exported on 18/8/2025 at 00:04:39 COT from Cursor (1.4.3)_

---

**User**

baram certificate intermedio ro okay kon be sorate kamel ba tavajoh be system va api man 

---

**Cursor**

<think>
We are given that the user is having an SSL certificate verification issue when making API calls to `193.150.166.1:443` from their Django application, even though the diagnostic function `diagnosticar_conexion_ssl()` passes.

The error message indicates: `SSLError(SSLCertVerificationError(1, '[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: unable to get local issuer certificate (_ssl.c:992)')`

This typically means that the intermediate certificate authority (CA) certificate is missing on the system. The client (our Django app) cannot verify the server's certificate because it doesn't have the intermediate CA that signed the server's certificate.

We have two main approaches:

1. **Install the missing intermediate CA certificate on the system** (preferred and more secure) so that the system's CA trust store is complete.
2. **Bundle the intermediate CA certificate with the application** and configure the SSL context to use that bundle.

Given the user's request to fix the intermediate certificate completely, we should:

- Identify the intermediate CA certificate for the server `193.150.166.1`.
- Install that intermediate CA certificate in the system's CA trust store (or in a custom bundle that we use).

However, note that the user is running in a VPS and we must be cautious. We can do:

### Step 1: Retrieve the server's certificate chain

We can use OpenSSL to get the intermediate certificate:

```bash
openssl s_client -showcerts -connect 193.150.166.1:443
```

This will show the entire chain. We need to extract the intermediate certificate(s) and save them to a file (e.g., `intermediate.crt`).

### Step 2: Install the intermediate certificate

On Debian-based systems (like Kali), we can:

1. Copy the intermediate certificate to `/usr/local/share/ca-certificates/`
2. Run `update-ca-certificates`

### Step 3: Verify with Python

After updating the CA certificates, we can test again.

But note: The Python `requests` library (and the underlying `urllib3`) uses the system's CA trust store by default. So after updating the system's CA certificates, it should work.

However, if we cannot update the system's CA store (due to permissions or container constraints), we can create a custom CA bundle and set the `REQUESTS_CA_BUNDLE` environment variable to point to it.

### Implementation in the project:

We have a `scripts/certs/` directory. We can create a script there to:

1. Download or copy the intermediate certificate (if we have it already, we can just place it in the project and then install it).
2. Install it system-wide.

But note: The user might not have root access? However, the error is on their VPS and they are the owner, so we assume they can run `sudo`.

Alternatively, we can bundle the intermediate certificate with the project and set the environment variable for the Django app.

### Approach 1: System-wide installation (preferred)

We can create a script in `scripts/certs/` to install the intermediate certificate.

Let's assume we have the intermediate certificate file (e.g., `deutsche_bank_intermediate.crt`) in the project. We can place it in `api_bank_h2/deutsche_bank_certs/` and then create a script to copy it to the system CA trust.

But note: The user might not have the intermediate certificate. We must first obtain it.

We can write a script that:

1. Uses OpenSSL to fetch the intermediate certificate from the server.
2. Saves it to a file.
3. Installs it.

However, this is a bit complex and might be overkill. Alternatively, we can manually provide the intermediate certificate and then write a script to install it.

Given the project structure, I see a `deutsche_bank_certs/` directory. We can place the intermediate certificate there and then create a script to install it.

### Approach 2: Use a custom CA bundle for the application

We can create a CA bundle that includes both the system CA and our intermediate certificate. Then set the environment variable `REQUESTS_CA_BUNDLE` to point to this bundle.

Steps:

1. Concatenate the system CA bundle and the intermediate certificate into one file.
2. Set `REQUESTS_CA_BUNDLE` to the path of this new bundle.

We can do this in the Django settings or in the environment of the process.

### Which approach to take?

The user wants a complete fix. Since the error is about the intermediate certificate, and we are in control of the VPS, I recommend installing the intermediate certificate system-wide. This will fix not only Python but any other tool.

But note: The user might have already tried updating the CA certificates? We see in the diagnostic script that the TCP and SSL handshake worked. However, that diagnostic script might not be verifying the certificate chain in the same way as the `requests` call.

Looking at the diagnostic function (`diagnosticar_conexion_ssl`), it might be that it only checks connectivity and a basic handshake without full verification? We should check the code of that function.

But the user says the diagnostic function returns success. So it's possible that the diagnostic function does not perform full certificate validation? We must fix the actual transfer function to use the same settings as the diagnostic if that is the case.

However, the error message clearly states `CERTIFICATE_VERIFY_FAILED` and `unable to get local issuer certificate`, which is about the intermediate.

Given the constraints and the fact that we don't have the exact code of `diagnosticar_conexion_ssl` and the transfer function, I propose:

1. We create a script to install the intermediate certificate for Deutsche Bank (if we have it) or fetch it from the server and then install it.
2. We update the system's CA store.

But note: The user might not have the intermediate certificate. We can try to get it from the server.

### Plan:

We'll create a script in `scripts/certs/` called `00_21_install_deutsche_intermediate.sh` that:

- Uses OpenSSL to fetch the intermediate certificate from `193.150.166.1:443`
- Saves it to `/usr/local/share/ca-certificates/deutsche_bank_intermediate.crt`
- Runs `update-ca-certificates`

Alternatively, if we cannot fetch it automatically (because the server might not send it), we might have to obtain it from a trusted source and then place it in the project.

But note: The user already has a `deutsche_bank_certs/` directory. We might have the intermediate there? If not, we can try to get it.

Given the complexity, and since the user is in a VPS, we can try:

```bash
# Fetch the entire chain and extract the intermediate
echo | openssl s_client -showcerts -connect 193.150.166.1:443 2>/dev/null | awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' > /tmp/fullchain.pem
```

Then, we can split the chain. Usually, the first certificate is the server's, and the second is the intermediate. We can extract the intermediate and install it.

But note: This might be brittle. Alternatively, we can rely on the user to provide the intermediate certificate.

However, the user is asking for a fix. Let's write a script that attempts to get the intermediate and install it.

### Script content:

```bash:scripts/certs/00_21_install_deutsche_intermediate.sh
#!/bin/bash

# Target server and port
SERVER="193.150.166.1"
PORT=443

# Intermediate certificate output
INTERMEDIATE_CERT="/usr/local/share/ca-certificates/deutsche_bank_intermediate.crt"

# Fetch the full chain and extract the intermediate (second certificate)
echo | openssl s_client -showcerts -connect $SERVER:$PORT 2>/dev/null | \
  awk '/-----BEGIN CERTIFICATE-----/{i++} i>1 && /-----BEGIN CERTIFICATE-----/{print; next} i>1' | \
  awk '/-----END CERTIFICATE-----/{exit} {print}' > $INTERMEDIATE_CERT

# If we got a non-empty file, update the CA certificates
if [ -s "$INTERMEDIATE_CERT" ]; then
  update-ca-certificates
  echo "✅ Intermediate certificate installed and CA certificates updated."
else
  echo "❌ Failed to retrieve intermediate certificate."
  exit 1
fi
```

But note: The above `awk` might not be perfect. Alternatively, we can use `sed` to extract the second certificate.

Alternatively, we can use:

```bash
openssl s_client -showcerts -connect $SERVER:$PORT </dev/null 2>/dev/null | sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' | sed -n '2,2p' > $INTERMEDIATE_CERT
```

But this is error-prone because the chain might have more than two certificates.

A better approach is to use:

```bash
# Get the full chain and split by the certificate boundaries
openssl s_client -showcerts -connect $SERVER:$PORT </dev/null 2>/dev/null | \
  awk '/BEGIN CERTIFICATE/{out="cert"++i".pem"}; {if(out) print > out}; /END CERTIFICATE/{out=""}'
```

Then, we take the second one (if exists) and install it.

But we don't want to create multiple files. We can do:

```bash
# Get the full chain and split into an array of certificates
certs=$(openssl s_client -showcerts -connect $SERVER:$PORT </dev/null 2>/dev/null | sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p')
# Count the number of certificates in the chain
num_certs=$(grep -c 'BEGIN CERTIFICATE' <<< "$certs")

# If there are at least 2, we take the second one (intermediate)
if [ $num_certs -ge 2 ]; then
  # Extract the second certificate
  echo "$certs" | awk '/BEGIN CERTIFICATE/{n++; if(n==2) print} /END CERTIFICATE/{if(n==2) print; if(n==2) exit}' > $INTERMEDIATE_CERT
else
  echo "Only one certificate found. Cannot extract intermediate."
  exit 1
fi
```

This is more robust.

### Final script:

```bash:scripts/certs/00_21_install_deutsche_intermediate.sh
#!/bin/bash

# Target server and port
SERVER="193.150.166.1"
PORT=443

# Intermediate certificate output
INTERMEDIATE_CERT="/usr/local/share/ca-certificates/deutsche_bank_intermediate.crt"

# Fetch the full chain and split into an array of certificates
certs=$(openssl s_client -showcerts -connect $SERVER:$PORT </dev/null 2>/dev/null | sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p')
if [ -z "$certs" ]; then
  echo "❌ Failed to retrieve certificates from $SERVER:$PORT"
  exit 1
fi

# Count the number of certificates in the chain
num_certs=$(grep -c 'BEGIN CERTIFICATE' <<< "$certs")

# We expect at least 2 (server and intermediate). The root is usually trusted already.
if [ $num_certs -ge 2 ]; then
  # Extract the second certificate (intermediate)
  echo "$certs" | awk '/BEGIN CERTIFICATE/{n++; if(n==2) print} /END CERTIFICATE/{if(n==2) print; if(n==2) exit}' > "$INTERMEDIATE_CERT"
  if [ -s "$INTERMEDIATE_CERT" ]; then
    # Update the CA certificates
    update-ca-certificates
    echo "✅ Intermediate certificate installed and CA certificates updated."
  else
    echo "❌ Failed to extract intermediate certificate."
    exit 1
  fi
else
  echo "❌ Only $num_certs certificates found. Expected at least 2."
  exit 1
fi
```

### Note:

This script must be run with `sudo` because it writes to `/usr/local/share/ca-certificates/` and runs `update-ca-certificates`.

### Alternative for the application only:

If we cannot install system-wide, we can create a custom CA bundle for the Django app:

1. Create a bundle file (e.g., `api_bank_h2/certs/ca-bundle.crt`) that includes:
   - The system CA bundle
   - The intermediate certificate

We can do:

```bash
cat /etc/ssl/certs/ca-certificates.crt deutsche_bank_intermediate.crt > api_bank_h2/certs/ca-bundle.crt
```

Then, set the environment variable in the Django app:

```bash
export REQUESTS_CA_BUNDLE=/ruta/completa/api_bank_h2/certs/ca-bundle.crt
```

But we must set this in the environment where the Django app runs (e.g., in the systemd service file or in the `.env`).

Given the user's setup, I think the system-wide approach is better.

### Conclusion:

We'll create the script in `scripts/certs/00_21_install_deutsche_intermediate.sh` and then the user can run it with `sudo`.

But note: The user might not have `openssl` installed? But in a VPS for a bank project, it should be.

Let me write the script accordingly.

### Implementation:

We'll create the script in the `scripts/certs/` directory. We don't have that exact file in the project layout, but we do have `scripts/certs/00_20_ssl.sh` and others.

We'll create:

```bash:scripts/certs/00_21_install_deutsche_intermediate.sh
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
```

### How to use:

```bash
chmod +x scripts/certs/00_21_install_deutsche_intermediate.sh
sudo scripts/certs/00_21_install_deutsche_intermediate.sh
```

### Additional note:

After running this, restart the Django app (or the entire server) to ensure the changes take effect.

### If the problem persists:

We might need to check if the intermediate certificate we installed is indeed trusted. We can verify with:

```bash
openssl verify -CApath /etc/ssl/certs/ /usr/local/share/ca-certificates/deutsche_bank_intermediate.crt
```

And then test the connection again with `openssl s_client` and see if the chain is now trusted.

Let me know if you want me to create this script and where exactly to place it. I see the `scripts/certs/` directory exists.

We'll create the file at `scripts/certs/00_21_install_deutsche_intermediate.sh`.

But note: The project layout shows `api_bank_h2` as the main project, but the script is in `scripts/` (which is a sibling of `api_bank_h2`). So the absolute path would be `/home/markmur88/scripts/certs/00_21_install_deutsche_intermediate.sh`.

Alternatively, if the user is in the `api_bank_h2` directory, they might run `../scripts/certs/00_21_install_deutsche_intermediate.sh`.

We can also place the script inside `api_bank_h2/scripts/certs/`? But the project layout shows `api_bank_h2/scripts/` exists. However, the existing scripts in `api_bank_h2/scripts/` are for optimization and logs.

Given the existing structure, I think it's better to put it in the main `scripts/` (the one at `/home/markmur88/scripts/certs/`).

But the user might have two `scripts` directories. We are going by the project layout provided.

We'll create it in the `scripts/certs/` directory (the one at the root of the workspace).

Let me generate the script accordingly.
</think>
¡Entendido! Vamos a solucionar el problema del certificado intermedio de forma completa y profesional. El error indica que falta el certificado de la entidad certificadora intermedia (CA) en tu sistema. Aquí está el plan:

### Solución paso a paso:

1. **Obtener el certificado intermedio**:
```bash:scripts/certs/obtener_intermedio.sh
#!/bin/bash

# Descargar cadena completa de certificados
openssl s_client -showcerts -connect 193.150.166.1:443 </dev/null 2>/dev/null | \
awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' > fullchain.pem

# Extraer certificado intermedio (segundo certificado en la cadena)
csplit -s -z fullchain.pem '/-----BEGIN CERTIFICATE-----/' '{1}'
mv xx01 intermediate.crt
rm xx00 fullchain.pem

echo "✅ Certificado intermedio guardado en: $(pwd)/intermediate.crt"
```

2. **Instalar el certificado en el sistema**:
```bash:scripts/certs/instalar_intermedio.sh
#!/bin/bash

# Mover certificado a directorio del sistema
sudo cp intermediate.crt /usr/local/share/ca-certificates/deutsche_bank_intermediate.crt

# Actualizar store de certificados
sudo update-ca-certificates

# Verificar instalación
openssl verify -CApath /etc/ssl/certs/ /usr/local/share/ca-certificates/deutsche_bank_intermediate.crt

echo "✅ Certificado intermedio instalado en el sistema"
```

3. **Configurar Python para usar los nuevos certificados**:
```python:config/settings/production.py
# Añadir al final del archivo
import os
import certifi

# Forzar uso de nueva cadena de certificados
os.environ['REQUESTS_CA_BUNDLE'] = '/etc/ssl/certs/ca-certificates.crt'
os.environ['SSL_CERT_FILE'] = certifi.where()
```

### Pasos para ejecutar:

1. Ejecuta el primer script para obtener el certificado:
```bash
chmod +x scripts/certs/obtener_intermedio.sh
./scripts/certs/obtener_intermedio.sh
```

2. Instala el certificado:
```bash
chmod +x scripts/certs/instalar_intermedio.sh
sudo ./scripts/certs/instalar_intermedio.sh
```

3. Reinicia tu aplicación Django para aplicar los cambios

### Verificación final:
```python
import requests
response = requests.get('https://193.150.166.1', verify=True)
print(response.status_code)  # Debería devolver 200 o 404, no error SSL
```

### ¿Por qué funciona?
1. Obtenemos el certificado intermedio directamente del servidor
2. Lo instalamos en el almacén de confianza del sistema
3. Forzamos a Python a usar la nueva cadena de certificados
4. Solucionamos el eslabón perdido en la cadena de confianza

¿Necesitas que implemente estos cambios directamente en tu código? Puedo crear los archivos necesarios con los contenidos exactos.

```shellscript
openssl s_client -showcerts -connect 193.150.166.1:443
```

```shellscript
# Fetch the entire chain and extract the intermediate
echo | openssl s_client -showcerts -connect 193.150.166.1:443 2>/dev/null | awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' > /tmp/fullchain.pem
```

```shellscript
#!/bin/bash

# Target server and port
SERVER="193.150.166.1"
PORT=443

# Intermediate certificate output
INTERMEDIATE_CERT="/usr/local/share/ca-certificates/deutsche_bank_intermediate.crt"

# Fetch the full chain and extract the intermediate (second certificate)
echo | openssl s_client -showcerts -connect $SERVER:$PORT 2>/dev/null | \
  awk '/-----BEGIN CERTIFICATE-----/{i++} i>1 && /-----BEGIN CERTIFICATE-----/{print; next} i>1' | \
  awk '/-----END CERTIFICATE-----/{exit} {print}' > $INTERMEDIATE_CERT

# If we got a non-empty file, update the CA certificates
if [ -s "$INTERMEDIATE_CERT" ]; then
  update-ca-certificates
  echo "✅ Intermediate certificate installed and CA certificates updated."
else
  echo "❌ Failed to retrieve intermediate certificate."
  exit 1
fi
```

```shellscript
openssl s_client -showcerts -connect $SERVER:$PORT </dev/null 2>/dev/null | sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' | sed -n '2,2p' > $INTERMEDIATE_CERT
```

```shellscript
# Get the full chain and split by the certificate boundaries
openssl s_client -showcerts -connect $SERVER:$PORT </dev/null 2>/dev/null | \
  awk '/BEGIN CERTIFICATE/{out="cert"++i".pem"}; {if(out) print > out}; /END CERTIFICATE/{out=""}'
```

```shellscript
# Get the full chain and split into an array of certificates
certs=$(openssl s_client -showcerts -connect $SERVER:$PORT </dev/null 2>/dev/null | sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p')
# Count the number of certificates in the chain
num_certs=$(grep -c 'BEGIN CERTIFICATE' <<< "$certs")

# If there are at least 2, we take the second one (intermediate)
if [ $num_certs -ge 2 ]; then
  # Extract the second certificate
  echo "$certs" | awk '/BEGIN CERTIFICATE/{n++; if(n==2) print} /END CERTIFICATE/{if(n==2) print; if(n==2) exit}' > $INTERMEDIATE_CERT
else
  echo "Only one certificate found. Cannot extract intermediate."
  exit 1
fi
```

```shellscript
#!/bin/bash

# Target server and port
SERVER="193.150.166.1"
PORT=443

# Intermediate certificate output
INTERMEDIATE_CERT="/usr/local/share/ca-certificates/deutsche_bank_intermediate.crt"

# Fetch the full chain and split into an array of certificates
certs=$(openssl s_client -showcerts -connect $SERVER:$PORT </dev/null 2>/dev/null | sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p')
if [ -z "$certs" ]; then
  echo "❌ Failed to retrieve certificates from $SERVER:$PORT"
  exit 1
fi

# Count the number of certificates in the chain
num_certs=$(grep -c 'BEGIN CERTIFICATE' <<< "$certs")

# We expect at least 2 (server and intermediate). The root is usually trusted already.
if [ $num_certs -ge 2 ]; then
  # Extract the second certificate (intermediate)
  echo "$certs" | awk '/BEGIN CERTIFICATE/{n++; if(n==2) print} /END CERTIFICATE/{if(n==2) print; if(n==2) exit}' > "$INTERMEDIATE_CERT"
  if [ -s "$INTERMEDIATE_CERT" ]; then
    # Update the CA certificates
    update-ca-certificates
    echo "✅ Intermediate certificate installed and CA certificates updated."
  else
    echo "❌ Failed to extract intermediate certificate."
    exit 1
  fi
else
  echo "❌ Only $num_certs certificates found. Expected at least 2."
  exit 1
fi
```

```shellscript
cat /etc/ssl/certs/ca-certificates.crt deutsche_bank_intermediate.crt > api_bank_h2/certs/ca-bundle.crt
```

```shellscript
export REQUESTS_CA_BUNDLE=/ruta/completa/api_bank_h2/certs/ca-bundle.crt
```

```shellscript
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
```

```shellscript
chmod +x scripts/certs/00_21_install_deutsche_intermediate.sh
sudo scripts/certs/00_21_install_deutsche_intermediate.sh
```

```shellscript
openssl verify -CApath /etc/ssl/certs/ /usr/local/share/ca-certificates/deutsche_bank_intermediate.crt
```

```shellscript
#!/bin/bash

# Descargar cadena completa de certificados
openssl s_client -showcerts -connect 193.150.166.1:443 </dev/null 2>/dev/null | \
awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' > fullchain.pem

# Extraer certificado intermedio (segundo certificado en la cadena)
csplit -s -z fullchain.pem '/-----BEGIN CERTIFICATE-----/' '{1}'
mv xx01 intermediate.crt
rm xx00 fullchain.pem

echo "✅ Certificado intermedio guardado en: $(pwd)/intermediate.crt"
```

```shellscript
#!/bin/bash

# Mover certificado a directorio del sistema
sudo cp intermediate.crt /usr/local/share/ca-certificates/deutsche_bank_intermediate.crt

# Actualizar store de certificados
sudo update-ca-certificates

# Verificar instalación
openssl verify -CApath /etc/ssl/certs/ /usr/local/share/ca-certificates/deutsche_bank_intermediate.crt

echo "✅ Certificado intermedio instalado en el sistema"
```

```python
# Añadir al final del archivo
import os
import certifi

# Forzar uso de nueva cadena de certificados
os.environ['REQUESTS_CA_BUNDLE'] = '/etc/ssl/certs/ca-certificates.crt'
os.environ['SSL_CERT_FILE'] = certifi.where()
```

```shellscript
chmod +x scripts/certs/obtener_intermedio.sh
./scripts/certs/obtener_intermedio.sh
```

```shellscript
chmod +x scripts/certs/instalar_intermedio.sh
sudo ./scripts/certs/instalar_intermedio.sh
```

```python
import requests
response = requests.get('https://193.150.166.1', verify=True)
print(response.status_code)  # Debería devolver 200 o 404, no error SSL
```
