# 🤖 Sistema de Automatización de Scripts

## 📋 Descripción General

Este sistema automatiza tareas de escaneo, conexión SSH, generación de claves y gestión de transacciones bancarias. Incluye scripts para automatización completa de procesos de pentesting y auditorías de seguridad.

## 🏗️ Estructura del Proyecto

```
scripts_auto/
├── config.py                    # Configuración central del sistema
├── automation_script.py         # Script principal de automatización
├── automation_script1.py        # Variante 1 del script de automatización
├── automation_script2.py        # Variante 2 con funcionalidades extendidas
├── automation_script3.py        # Variante 3 con características avanzadas
├── connect_scan.py              # Escaneo y conexión SSH automatizada
├── json_connect_scan.py         # Escaneo con salida JSON
├── connect_db_ssh.py            # Conexión a bases de datos via SSH
├── escaneo.py                   # Script básico de escaneo
├── generar_claves_ssh.py        # Generación automática de claves SSH
├── generate_token.py            # Generación de tokens de autenticación
├── generated_token.py           # Token generado dinámicamente
├── codeS256.py                  # Generación de códigos S256
├── collect_dic.py               # Recolección de diccionarios
├── collect_dic_csv.py           # Exportación de diccionarios a CSV
├── collect_dic_json.py          # Exportación de diccionarios a JSON
├── collect_dic_txt.py           # Exportación de diccionarios a TXT
├── gunicorn_config.py           # Configuración de Gunicorn
├── 0002.json                    # Archivo de configuración JSON
├── keys/                        # Directorio de claves y certificados
│   ├── cert                     # Certificado SSH
│   ├── CbA                      # Clave de autenticación
│   ├── id_rsa.pub               # Clave pública RSA
│   └── localhost.csr            # Certificado de solicitud
├── logs/                        # Archivos de registro
│   ├── automation.log           # Log principal de automatización
│   ├── errors.log               # Log de errores
│   └── generar_claves_ssh.log   # Log de generación de claves
└── README.md                    # Este archivo
```

## 🔧 Archivos de Configuración

### `config.py`
- **Función**: Configuración central del sistema
- **Contenido**:
  - Variables de entorno y credenciales
  - Configuración de APIs bancarias (Deutsche Bank)
  - Tokens de autenticación (Bearer, Client ID, Client Secret)
  - URLs de SWIFT y transferencias
  - Configuración de OAuth2 y códigos de autorización
  - Parámetros de transacciones SEPA

### `0002.json`
- **Función**: Configuración en formato JSON
- **Uso**: Parámetros de automatización y conexión

## 🤖 Scripts de Automatización

### `automation_script.py` - Script Principal
- **Función**: Automatización completa de procesos
- **Características**:
  - Carga de configuración desde JSON
  - Ejecución de comandos con privilegios sudo
  - Verificación de herramientas instaladas
  - Envío de transacciones JSON
  - Logging detallado de operaciones
  - Gestión de errores y timeouts

### `automation_script1.py` - Variante 1
- **Función**: Automatización con funcionalidades específicas
- **Diferencias**: Configuración adaptada para casos específicos

### `automation_script2.py` - Variante 2 Extendida
- **Función**: Automatización con características avanzadas
- **Características**:
  - Funcionalidades extendidas
  - Manejo de casos complejos
  - Integración con más herramientas

### `automation_script3.py` - Variante 3 Avanzada
- **Función**: Automatización de alto nivel
- **Características**:
  - Características avanzadas
  - Optimización de rendimiento
  - Gestión de recursos

## 🔍 Scripts de Escaneo y Conexión

### `connect_scan.py` - Escaneo y Conexión SSH
- **Función**: Escaneo de puertos y conexión SSH automatizada
- **Características**:
  - Escaneo de rango de IPs (193.150.166.0/24)
  - Detección de puertos SSH abiertos
  - Conexión automática via SSH
  - Generación automática de claves RSA
  - Gestión de certificados SSH
  - Manejo de errores de conexión

### `json_connect_scan.py` - Escaneo con Salida JSON
- **Función**: Escaneo que genera salida en formato JSON
- **Características**:
  - Formato estructurado de resultados
  - Integración con APIs
  - Procesamiento de datos automatizado

### `connect_db_ssh.py` - Conexión a Bases de Datos
- **Función**: Conexión a bases de datos via SSH
- **Características**:
  - Túneles SSH para BD
  - Conexión a múltiples tipos de BD
  - Gestión de credenciales

### `escaneo.py` - Escaneo Básico
- **Función**: Script simple de escaneo de puertos
- **Características**:
  - Escaneo rápido de puertos comunes
  - Salida directa a consola

## 🔐 Gestión de Claves y Autenticación

### `generar_claves_ssh.py` - Generación de Claves SSH
- **Función**: Generación automática de claves SSH
- **Características**:
  - Generación de pares de claves RSA
  - Configuración automática de permisos
  - Integración con directorio de claves
  - Logging de operaciones

### `generate_token.py` - Generación de Tokens
- **Función**: Generación de tokens de autenticación
- **Características**:
  - Tokens OAuth2
  - Tokens de acceso
  - Gestión de expiración

### `generated_token.py` - Token Dinámico
- **Función**: Token generado dinámicamente
- **Uso**: Autenticación en tiempo real

### `codeS256.py` - Códigos S256
- **Función**: Generación de códigos de verificación S256
- **Uso**: Autenticación PKCE (Proof Key for Code Exchange)

## 📊 Recolección y Exportación de Datos

### `collect_dic.py` - Recolección de Diccionarios
- **Función**: Recolección y procesamiento de diccionarios
- **Características**:
  - Agregación de múltiples fuentes
  - Procesamiento de datos
  - Validación de entradas

### `collect_dic_csv.py` - Exportación a CSV
- **Función**: Exportación de diccionarios a formato CSV
- **Características**:
  - Formato tabular
  - Compatibilidad con Excel
  - Fácil procesamiento

### `collect_dic_json.py` - Exportación a JSON
- **Función**: Exportación de diccionarios a formato JSON
- **Características**:
  - Formato estructurado
  - Compatibilidad con APIs
  - Procesamiento programático

### `collect_dic_txt.py` - Exportación a TXT
- **Función**: Exportación de diccionarios a texto plano
- **Características**:
  - Formato simple
  - Compatibilidad universal
  - Fácil lectura

## 🌐 Configuración de Servidores

### `gunicorn_config.py` - Configuración de Gunicorn
- **Función**: Configuración del servidor WSGI Gunicorn
- **Características**:
  - Configuración de workers
  - Configuración de bind
  - Configuración de timeouts
  - Configuración de logging

## 🔑 Directorio de Claves

### `keys/`
- **cert**: Certificado SSH para conexiones
- **CbA**: Clave de autenticación bancaria
- **id_rsa.pub**: Clave pública RSA
- **localhost.csr**: Certificado de solicitud para localhost

## 📝 Logs del Sistema

### `logs/`
- **automation.log**: Log principal de todas las operaciones
- **errors.log**: Log específico de errores
- **generar_claves_ssh.log**: Log de generación de claves SSH

## 🚀 Uso del Sistema

### **1. Configuración Inicial**
```bash
# Activar entorno virtual
source ~/envSIM/bin/activate

# Verificar configuración
python config.py
```

### **2. Generar Claves SSH**
```bash
python generar_claves_ssh.py
```

### **3. Ejecutar Automatización**
```bash
# Script principal
python automation_script.py

# Variantes específicas
python automation_script1.py
python automation_script2.py
python automation_script3.py
```

### **4. Escaneo y Conexión**
```bash
# Escaneo básico
python escaneo.py

# Escaneo con conexión SSH
python connect_scan.py

# Escaneo con salida JSON
python json_connect_scan.py
```

### **5. Recolección de Datos**
```bash
# Recolectar diccionarios
python collect_dic.py

# Exportar a diferentes formatos
python collect_dic_csv.py
python collect_dic_json.py
python collect_dic_txt.py
```

## 🔧 Dependencias

### **Python**
- `paramiko` (SSH)
- `requests` (HTTP)
- `subprocess` (comandos del sistema)
- `json` (procesamiento JSON)
- `logging` (registro de eventos)
- `concurrent.futures` (ejecución paralela)
- `socket` (conexiones de red)
- `ipaddress` (manejo de IPs)

### **Herramientas Externas**
- `nmap` (escaneo de puertos)
- `hydra` (ataques de fuerza bruta)
- `medusa` (ataques de fuerza bruta)
- `ssh-keygen` (generación de claves SSH)

## ⚠️ Consideraciones de Seguridad

### **Uso Responsable**
- ⚠️ Solo usar en **sistemas autorizados**
- ⚠️ Respetar **políticas de red**
- ⚠️ Mantener **logs de auditoría**
- ⚠️ Proteger **claves y certificados**

### **Gestión de Credenciales**
- Almacenar credenciales de forma segura
- Usar variables de entorno
- Rotar claves regularmente
- Monitorear accesos

## 📊 Monitoreo y Logs

### **Verificar Logs**
```bash
# Ver log principal
tail -f logs/automation.log

# Ver errores
tail -f logs/errors.log

# Ver generación de claves
tail -f logs/generar_claves_ssh.log
```

### **Análisis de Resultados**
```bash
# Filtrar operaciones exitosas
grep "ejecutado correctamente" logs/automation.log

# Filtrar errores
grep "ERROR" logs/errors.log
```

---

**Sistema de Automatización - Optimizado para Auditorías de Seguridad** 🔒
