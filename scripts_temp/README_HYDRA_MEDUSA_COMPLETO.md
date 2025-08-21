# 🔍 Scripts de Hydra y Medusa - Directorio scripts_temp

## 📋 Resumen Ejecutivo

Este documento cataloga todos los scripts en el directorio `scripts_temp` que utilizan las herramientas de fuerza bruta **Hydra** y **Medusa** para auditorías de seguridad y pruebas de penetración.

## 🛠️ Herramientas Utilizadas

### Hydra
- **Versión detectada**: Hydra v9.5
- **Propósito**: Ataques de fuerza bruta contra servicios SSH
- **Comandos principales**: `hydra -l {usuario} -p {contrasena} {ip} ssh -V -t 4`

### Medusa
- **Versión detectada**: Medusa v2.3_rc1
- **Propósito**: Ataques de fuerza bruta alternativos a Hydra
- **Comandos principales**: `medusa -u {usuario} -p {contrasena} -h {ip} -M ssh -t 4`

## 📁 Estructura de Archivos

### 1. Scripts Principales de Ataque

#### `automate/escaneo/hydra_ataque.py`
- **Función**: Script principal de ataque con Hydra
- **Características**:
  - Logging detallado en `logs/ataque_hydra.log`
  - Integración con sistema de transacciones SWIFT
  - Configuración dinámica de IP y puerto SSH
  - Manejo de errores robusto
- **Comando ejecutado**: `hydra -l {usuario} -p {contrasena} {ip} ssh -V -t 4`
- **Ubicación**: `scripts_temp/automate/escaneo/hydra_ataque.py`
- **Dependencias**: 
  - `send.swift` (para transacciones)
  - `config.json` (configuración)
  - `constants.py` (paymentId)

#### `automate/escaneo/medusa_ataque.py`
- **Función**: Script principal de ataque con Medusa
- **Características**:
  - Logging en `logs/ataque_medusa.log`
  - Envío automático de transacciones JSON
  - Reintentos automáticos en caso de fallo
  - Certificados SSL para conexiones seguras
- **Comando ejecutado**: `medusa -u {usuario} -p {contrasena} -h {ip} -M ssh -t 4`
- **Ubicación**: `scripts_temp/automate/escaneo/medusa_ataque.py`
- **Dependencias**:
  - `send.data` (plantilla de datos)
  - `certificate.pem` (certificado SSL)

#### `automate/escaneo/medusa_ingreso.py`
- **Función**: Script de ingreso automatizado con Medusa
- **Características**:
  - Versión simplificada sin envío de transacciones
  - Enfoque en pruebas de conectividad
  - Logging básico
- **Comando ejecutado**: `medusa -u {usuario} -p {contrasena} -h {ip} -M ssh -t 4`
- **Ubicación**: `scripts_temp/automate/escaneo/medusa_ingreso.py`

### 2. Scripts de Escaneo Integrados

#### `automate/escaneo/07escaneo.py`
- **Función**: Escaneo de servicios web con múltiples herramientas
- **Características**:
  - Integración de Hydra y Medusa con otras herramientas
  - Escaneo de rangos de IP y puertos
  - Generación de reportes
- **Comandos Hydra**: `hydra -L "$USERS_FILE" -P "$PASSWORDS_FILE" "$current_ip" ssh -s "$port"`
- **Comandos Medusa**: `medusa -h "$current_ip" -U "$USERS_FILE" -P "$PASSWORDS_FILE" -M ssh -n "$port"`
- **Ubicación**: `scripts_temp/automate/escaneo/07escaneo.py`

#### `automate/escaneo/08escaneo.py`
- **Función**: Escaneo de base de datos con caché
- **Características**:
  - Sistema de caché para optimizar escaneos
  - Timestamps en reportes
  - Integración de Hydra y Medusa
- **Comandos Hydra**: `hydra -L {users_file} -P {passwords_file} {ip} ssh -s {port}`
- **Comandos Medusa**: `medusa -h {ip} -U {users_file} -P {passwords_file} -M ssh -n {port}`
- **Ubicación**: `scripts_temp/automate/escaneo/08escaneo.py`

#### `automate/escaneo/10escaneo.py`
- **Función**: Escaneo completo con procesamiento paralelo
- **Características**:
  - Escaneo concurrente con ThreadPoolExecutor
  - Verificación de conectividad antes del ataque
  - Reportes detallados con timestamps
- **Comandos Hydra**: `hydra -L {users_file} -P {passwords_file} {ip} ssh -s {port}`
- **Comandos Medusa**: `medusa -h {ip} -U {users_file} -P {passwords_file} -M ssh -n {port}`
- **Ubicación**: `scripts_temp/automate/escaneo/10escaneo.py`

### 3. Scripts de Automatización

#### `automate/send/auto_send_swift.sh`
- **Función**: Script bash para envío automático de transacciones SWIFT
- **Características**:
  - Ejecución de Hydra para obtener credenciales
  - Verificación automática de credenciales válidas
  - Activación de envío SWIFT tras conexión exitosa
- **Comando Hydra**: `hydra -l usuario -P diccionario.txt servicio://ip -o credenciales_validas.txt`
- **Ubicación**: `scripts_temp/automate/send/auto_send_swift.sh`

### 4. Archivos de Configuración

#### `automate/config/config.json`
- **Función**: Configuración centralizada para todos los scripts
- **Parámetros principales**:
  - `ip_servidor`: "193.150.166.1"
  - `puerto_ssh`: 443
  - `timeout_hydra`: 10
  - `archivo_usuarios`: "diccionarios/users"
  - `archivo_contrasenas`: "diccionarios/passwords"
- **Ubicación**: `scripts_temp/automate/config/config.json`

### 5. Archivos de Logs

#### `automate/logs/ataque_hydra.log`
- **Función**: Logs detallados de ataques con Hydra
- **Ubicación**: `scripts_temp/automate/logs/ataque_hydra.log`

#### `automate/logs/ataque_medusa.log`
- **Función**: Logs detallados de ataques con Medusa
- **Ubicación**: `scripts_temp/automate/logs/ataque_medusa.log`

#### `automate/logs/errors.log`
- **Función**: Logs de errores generales
- **Ubicación**: `scripts_temp/automate/logs/errors.log`

## 🚀 Ejemplos de Uso

### Ataque con Hydra
```bash
cd scripts_temp/automate/escaneo
python hydra_ataque.py
```

### Ataque con Medusa
```bash
cd scripts_temp/automate/escaneo
python medusa_ataque.py
```

### Ingreso automatizado con Medusa
```bash
cd scripts_temp/automate/escaneo
python medusa_ingreso.py
```

### Escaneos automatizados
```bash
cd scripts_temp/automate/escaneo
python 07escaneo.py
python 08escaneo.py
python 10escaneo.py
```

### Envío automático SWIFT
```bash
cd scripts_temp/automate/send
bash auto_send_swift.sh
```

## 📊 Tabla de Archivos

| Archivo | Herramienta | Función | Ubicación |
|---------|-------------|---------|-----------|
| `hydra_ataque.py` | Hydra | Ataque principal SSH | `automate/escaneo/` |
| `medusa_ataque.py` | Medusa | Ataque principal SSH | `automate/escaneo/` |
| `medusa_ingreso.py` | Medusa | Login automatizado | `automate/escaneo/` |
| `07escaneo.py` | Ambos | Escaneo servicios web | `automate/escaneo/` |
| `08escaneo.py` | Ambos | Escaneo con caché | `automate/escaneo/` |
| `10escaneo.py` | Ambos | Escaneo paralelo | `automate/escaneo/` |
| `auto_send_swift.sh` | Hydra | Envío SWIFT | `automate/send/` |
| `config.json` | Ambos | Configuración | `automate/config/` |

## ⚠️ Consideraciones de Seguridad

1. **Uso Ético**: Estos scripts deben usarse únicamente en entornos autorizados
2. **Logs**: Todos los ataques se registran en archivos de log
3. **Configuración**: Revisar `config.json` antes de ejecutar
4. **Certificados**: Verificar la validez de certificados SSL
5. **Rate Limiting**: Los scripts incluyen límites de conexiones

## 🔧 Dependencias

### Python
- `subprocess`
- `logging`
- `json`
- `requests`
- `concurrent.futures`
- `ipaddress`

### Herramientas del Sistema
- `hydra`
- `medusa`
- `nmap`
- `nc` (netcat)
- `ssh`

### Archivos de Configuración
- `diccionarios/users`
- `diccionarios/passwords`
- `keys/certificate.pem`

## 📝 Notas de Desarrollo

- Los scripts están diseñados para ser modulares y reutilizables
- El sistema de logging permite auditoría completa de actividades
- La configuración centralizada facilita el mantenimiento
- Los scripts incluyen manejo de errores robusto
- Se implementa procesamiento paralelo para optimizar rendimiento

## 🔄 Actualizaciones

- **Última actualización**: Generado automáticamente
- **Versión de herramientas**: Hydra v9.5, Medusa v2.3_rc1
- **Estado**: Todos los scripts funcionales y documentados
