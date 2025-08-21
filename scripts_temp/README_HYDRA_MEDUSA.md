# 📋 Scripts que usan Hydra y Medusa

Este documento cataloga todos los scripts en el directorio `scripts_temp` que utilizan las herramientas de fuerza bruta **Hydra** y **Medusa**.

## 🎯 Herramientas Documentadas

### Hydra
- **Descripción**: Herramienta de fuerza bruta para múltiples protocolos
- **Versión detectada**: Hydra v9.5
- **Uso principal**: Ataques SSH, FTP, HTTP, etc.

### Medusa
- **Descripción**: Herramienta alternativa de fuerza bruta
- **Versión detectada**: Medusa v2.3_rc1
- **Uso principal**: Ataques SSH y otros protocolos

---

## 📁 Scripts de Ataque Principal

### 1. `automate/escaneo/hydra_ataque.py`
- **Función**: Script principal de ataque con Hydra
- **Características**:
  - Ataques SSH automatizados
  - Configuración desde archivos JSON
  - Logging detallado en `logs/ataque_hydra.log`
  - Envío de resultados a API
  - Gestión de errores y reintentos
  - Soporte para múltiples usuarios y contraseñas
- **Comando ejecutado**: `hydra -l {usuario} -p {contrasena} {ip} ssh -V -t 4`
- **Ubicación**: `scripts_temp/automate/escaneo/hydra_ataque.py`

### 2. `automate/escaneo/medusa_ataque.py`
- **Función**: Script principal de ataque con Medusa
- **Características**:
  - Ataques SSH automatizados
  - Integración con sistema de transacciones
  - Certificados SSL/TLS
  - Logging en `logs/ataque_medusa.log`
  - Envío de datos a API REST
- **Comando ejecutado**: `medusa -u {usuario} -p {contrasena} -h {ip} -M ssh -t 4`
- **Ubicación**: `scripts_temp/automate/escaneo/medusa_ataque.py`

### 3. `automate/escaneo/medusa_ingreso.py`
- **Función**: Automatización de ingreso después de ataques exitosos
- **Características**:
  - Login automático post-ataque
  - Gestión de sesiones
  - Extracción de datos
  - Envío de transacciones deshabilitado
- **Comando ejecutado**: `medusa -u {usuario} -p {contrasena} -h {ip} -M ssh -t 4`
- **Ubicación**: `scripts_temp/automate/escaneo/medusa_ingreso.py`

---

## 🔧 Scripts de Escaneo Integrados

### 4. `automate/escaneo/04escaneo.sh`
- **Función**: Script bash para escaneo de rangos de IPs
- **Características**:
  - Escaneo de rangos de IPs y puertos
  - Integración de múltiples herramientas
  - Generación de reportes
- **Comandos Hydra**: `hydra -L "$USERS_FILE" -P "$PASSWORDS_FILE" "$current_ip" ssh -s "$port"`
- **Comandos Medusa**: `medusa -h "$current_ip" -U "$USERS_FILE" -P "$PASSWORDS_FILE" -M ssh -n "$port"`
- **Ubicación**: `scripts_temp/automate/escaneo/04escaneo.sh`

### 5. Scripts Python de Escaneo (07escaneo.py, 08escaneo.py, 09escaneo.py, 10escaneo.py)
- **Función**: Escaneos automatizados con integración de herramientas
- **Características**:
  - Escaneo de puertos y servicios
  - Integración de Hydra y Medusa
  - Generación de reportes automáticos
- **Comandos Hydra**: `hydra -L {users_file} -P {passwords_file} {ip} ssh -s {port}`
- **Comandos Medusa**: `medusa -h {ip} -U {users_file} -P {passwords_file} -M ssh -n {port}`
- **Ubicaciones**:
  - `scripts_temp/automate/escaneo/07escaneo.py`
  - `scripts_temp/automate/escaneo/08escaneo.py`
  - `scripts_temp/automate/escaneo/09escaneo.py`
  - `scripts_temp/automate/escaneo/10escaneo.py`

---

## 📤 Scripts de Envío Automatizado

### 6. `automate/send/auto_send_swift.sh`
- **Función**: Automatización de envío SWIFT post-ataque
- **Características**:
  - Ejecución de Hydra para obtener credenciales
  - Verificación de credenciales válidas
  - Envío automático de transferencias SWIFT
- **Comando Hydra**: `hydra -l usuario -P diccionario.txt servicio://ip -o credenciales_validas.txt`
- **Ubicación**: `scripts_temp/automate/send/auto_send_swift.sh`

---

## ⚙️ Archivos de Configuración

### 7. `automate/config/config.json` y `automate/config/config_base.json`
- **Función**: Configuración centralizada para herramientas
- **Parámetros**:
  - `timeout_hydra`: 10 (segundos)
  - Configuraciones de IPs y puertos
  - Rutas de diccionarios
- **Ubicaciones**:
  - `scripts_temp/automate/config/config.json`
  - `scripts_temp/automate/config/config_base.json`

### 8. `automate/escaneo/config.py`
- **Función**: Configuración dinámica para scripts de escaneo
- **Características**:
  - Función `get_hydra_config()`
  - Importación de configuraciones de Hydra
  - Gestión de URLs y puertos
- **Ubicación**: `scripts_temp/automate/escaneo/config.py`

---

## 📊 Archivos de Logs y Reportes

### Logs de Ataques
- **Hydra**: `automate/logs/ataque_hydra.log`
- **Medusa**: `automate/logs/ataque_medusa.log`
- **Errores**: `automate/logs/errors.log`

### Reportes de Escaneo
- **Ubicación**: `automate/reports/`
- **Formato**: Archivos con timestamp (ej: `reporte_20250427_201443.txt`)
- **Contenido**: Salida de comandos Hydra y Medusa

---

## 📚 Documentación Adicional

### 9. `automate/escaneo/README.md`
- **Función**: Documentación completa del sistema de escaneo
- **Secciones relevantes**:
  - Scripts de Ataque (Hydra y Medusa)
  - Uso del Sistema
  - Configuración
- **Ubicación**: `scripts_temp/automate/escaneo/README.md`

### 10. `WormGPT/plan_SSH.txt` y `WormGPT/ssh_chat_wormGPT.txt`
- **Función**: Documentación de técnicas de ataque SSH
- **Contenido**:
  - Ejemplos de uso de Hydra
  - Comandos específicos para ataques SSH
  - Estrategias de fuerza bruta
- **Ubicaciones**:
  - `scripts_temp/WormGPT/plan_SSH.txt`
  - `scripts_temp/WormGPT/ssh_chat_wormGPT.txt`

---

## 🚀 Uso de los Scripts

### Ejecución de Ataques Principales
```bash
# Ataque con Hydra
cd scripts_temp/automate/escaneo
python hydra_ataque.py

# Ataque con Medusa
python medusa_ataque.py

# Ingreso automatizado con Medusa
python medusa_ingreso.py
```

### Ejecución de Escaneos
```bash
# Escaneo con script bash
cd scripts_temp/automate/escaneo
bash 04escaneo.sh

# Escaneos Python
python 07escaneo.py
python 08escaneo.py
python 09escaneo.py
python 10escaneo.py
```

### Envío Automatizado
```bash
# Envío SWIFT post-ataque
cd scripts_temp/automate/send
bash auto_send_swift.sh
```

---

## ⚠️ Advertencias de Seguridad

**IMPORTANTE**: Todos estos scripts están diseñados únicamente para:
- Pruebas de penetración autorizadas
- Auditorías de seguridad
- Investigación educativa
- Entornos de laboratorio controlados

**NUNCA** usar en:
- Sistemas de producción sin autorización
- Redes públicas
- Actividades ilegales

---

## 📋 Resumen de Archivos

| Script | Herramienta | Función | Ubicación |
|--------|-------------|---------|-----------|
| `hydra_ataque.py` | Hydra | Ataque principal SSH | `automate/escaneo/` |
| `medusa_ataque.py` | Medusa | Ataque principal SSH | `automate/escaneo/` |
| `medusa_ingreso.py` | Medusa | Login automatizado | `automate/escaneo/` |
| `04escaneo.sh` | Ambos | Escaneo de rangos | `automate/escaneo/` |
| `07-10escaneo.py` | Ambos | Escaneos automatizados | `automate/escaneo/` |
| `auto_send_swift.sh` | Hydra | Envío SWIFT | `automate/send/` |
| `config.json` | Ambos | Configuración | `automate/config/` |
| `config.py` | Ambos | Configuración dinámica | `automate/escaneo/` |

---

*Documento generado automáticamente - Última actualización: $(date)*
