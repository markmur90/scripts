# 🐛 WormGPT - Herramientas SSH Avanzadas

## 📋 Descripción

WormGPT es una colección de herramientas avanzadas para auditoría, fuerza bruta y honeypot de servicios SSH. Este proyecto incluye scripts automatizados para pruebas de penetración, detección de vulnerabilidades y monitoreo de ataques.

## ⚠️ ADVERTENCIA LEGAL

**ESTAS HERRAMIENTAS SON SOLO PARA FINES EDUCATIVOS Y DE AUDITORÍA AUTORIZADA.**
- Úsalas únicamente en sistemas que poseas o tengas autorización explícita para probar
- El uso no autorizado puede ser ilegal
- Los desarrolladores no se responsabilizan del mal uso de estas herramientas

## 🛠️ Herramientas Incluidas

### 1. **brute.py** - Fuerza Bruta Básica
Script simple para ataques de fuerza bruta SSH con threading.

```bash
python3 brute.py
```

**Características:**
- Ataque multi-hilo
- Lista predefinida de usuarios y contraseñas
- Timeout configurable
- Detección automática de credenciales válidas

### 2. **ssh_brute.py** - Fuerza Bruta Avanzada
Herramienta completa con múltiples opciones y generación dinámica de payloads.

```bash
# Uso básico
python3 ssh_brute.py <IP>

# Puerto personalizado
python3 ssh_brute.py <IP> --port 2222

# Archivos personalizados de usuarios y contraseñas
python3 ssh_brute.py <IP> --users users.txt --passwords passlist.txt --threads 10

# Con proxy
proxychains python3 ssh_brute.py <IP>
```

**Características:**
- Generación dinámica de contraseñas con Faker
- Escaneo de versión SSH
- Múltiples hilos configurables
- Guardado automático de credenciales válidas
- Soporte para archivos de usuarios/contraseñas personalizados

### 3. **ssh_auditor.py** - Auditoría Completa
Herramienta de auditoría con capacidades de explotación de CVEs.

```bash
# Auditoría básica
python3 ssh_auditor.py <IP>

# Con exploit CVE-2024-6387
python3 ssh_auditor.py <IP> --exploit

# Configuración completa
python3 ssh_auditor.py <IP> --port 22 --threads 20 --users users.txt --passwords passlist.txt --exploit
```

**Características:**
- Escaneo de banner SSH
- Prueba de CVE-2024-6387
- Auditoría de credenciales
- Generación inteligente de contraseñas
- Logging detallado

### 4. **honeypot_server.py** - Honeypot SSH
Servidor honeypot para capturar intentos de ataque SSH.

```bash
python3 honeypot_server.py
```

**Características:**
- Servidor SSH falso en puerto 2222
- Dashboard web en puerto 5000
- Logging de intentos de conexión
- Captura de credenciales
- Interfaz web para visualización

### 5. **ssh_honeypot.py** - Honeypot Simplificado
Versión simplificada del honeypot para captura rápida.

### 6. **ssh_exploit.py** - Exploit CVE-2024-6387
Script específico para probar la vulnerabilidad CVE-2024-6387.

### 7. **ssh_brute_exploit.py** - Combinación Fuerza Bruta + Exploit
Script que combina fuerza bruta con intentos de explotación.

## 📁 Estructura de Archivos

```
WormGPT/
├── README.md                    # Este archivo
├── brute.py                     # Fuerza bruta básica
├── ssh_brute.py                 # Fuerza bruta avanzada
├── ssh_auditor.py               # Auditoría completa
├── honeypot_server.py           # Honeypot con dashboard
├── ssh_honeypot.py              # Honeypot simplificado
├── ssh_exploit.py               # Exploit CVE-2024-6387
├── ssh_brute_exploit.py         # Fuerza bruta + exploit
├── ssh_brute_help.txt           # Comandos de ayuda
├── plan_SSH.txt                 # Plan de ataque detallado
├── ssh_chat_wormGPT.txt         # Conversación con WormGPT
└── honeypot_logs.csv            # Logs del honeypot
```

## 🔧 Instalación y Dependencias

### Requisitos del Sistema
```bash
# Python 3.7+
python3 --version

# pip
pip3 --version
```

### Instalación de Dependencias
```bash
pip3 install paramiko faker flask
```

### Dependencias Principales
- `paramiko`: Cliente SSH para Python
- `faker`: Generación de datos falsos
- `flask`: Framework web para dashboard
- `threading`: Manejo de hilos
- `socket`: Comunicación de red

## 🚀 Uso Rápido

### 1. Auditoría Básica
```bash
python3 ssh_auditor.py 192.168.1.100
```

### 2. Fuerza Bruta Completa
```bash
python3 ssh_brute.py 192.168.1.100 --threads 20
```

### 3. Honeypot
```bash
python3 honeypot_server.py
# Accede al dashboard en http://localhost:5000
```

### 4. Con Proxy
```bash
proxychains python3 ssh_brute.py 192.168.1.100
```

## 📊 Monitoreo y Logs

### Archivos de Salida
- `creds.txt`: Credenciales válidas encontradas
- `valid_credentials.txt`: Credenciales de auditoría
- `honeypot_logs.csv`: Logs del honeypot

### Dashboard del Honeypot
Accede a `http://localhost:5000` para ver:
- Intentos de conexión en tiempo real
- IPs de atacantes
- Credenciales capturadas
- Timestamps de ataques

## 🔍 Técnicas Implementadas

### 1. **Fuerza Bruta Inteligente**
- Generación dinámica de contraseñas
- Patrones comunes de contraseñas
- Combinaciones de usuario/empresa
- Años y números secuenciales

### 2. **Detección de Vulnerabilidades**
- Escaneo de versiones SSH
- Prueba de CVE-2024-6387
- Análisis de banners
- Detección de configuraciones débiles

### 3. **Honeypot Avanzado**
- Servidor SSH falso
- Captura de credenciales
- Logging detallado
- Dashboard web

### 4. **Optimización de Rendimiento**
- Multi-threading
- Timeouts configurables
- Colas de trabajo
- Control de concurrencia

## 🛡️ Medidas de Seguridad

### Para el Atacante
- Uso de proxies
- Rotación de IPs
- Delays entre intentos
- Evasión de detección

### Para el Defensor
- Honeypot para captura
- Logging detallado
- Análisis de patrones
- Alertas automáticas

## 📚 Recursos Adicionales

### Comandos Útiles
```bash
# Escaneo de algoritmos SSH
nmap -p22 --script ssh2-enum-algos <IP>

# Búsqueda de exploits
searchsploit OpenSSH 2024

# Repositorios de exploits
# hakivvi/openssh-cve-2024-6387
```

### Archivos de Referencia
- `plan_SSH.txt`: Plan detallado de ataque
- `ssh_chat_wormGPT.txt`: Conversación con IA
- `ssh_brute_help.txt`: Comandos rápidos

## ⚡ Optimizaciones

### Rendimiento
- Ajuste de hilos según CPU
- Timeouts optimizados
- Gestión de memoria
- Logging eficiente

### Detección
- Evasión de IDS/IPS
- Patrones de tráfico
- Timing de ataques
- Rotación de payloads

## 🤝 Contribuciones

Para contribuir al proyecto:
1. Fork del repositorio
2. Crear rama de feature
3. Implementar cambios
4. Crear pull request

## 📄 Licencia

Este proyecto es para fines educativos. Úsalo responsablemente.

## 🔗 Enlaces Relacionados

- [OpenSSH CVE-2024-6387](https://github.com/hakivvi/openssh-cve-2024-6387)
- [Paramiko Documentation](http://www.paramiko.org/)
- [Faker Documentation](https://faker.readthedocs.io/)

---

**Recuerda: Solo usa estas herramientas en sistemas autorizados. El hacking no autorizado es ilegal.**
