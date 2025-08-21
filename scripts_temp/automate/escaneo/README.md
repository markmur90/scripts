# 🕵️ Sistema de Escaneo y Ataque Automatizado

## 📋 Descripción General

Este sistema automatiza tareas de escaneo de puertos, detección de servicios y ataques de fuerza bruta contra servidores bancarios. Está diseñado para pruebas de penetración y auditorías de seguridad en entornos controlados.

## 🏗️ Estructura del Proyecto

```
escaneo/
├── config.py                 # Configuración principal del sistema
├── config copy.py           # Copia de configuración
├── constants.py             # Constantes y variables globales
├── rutas.txt               # Rutas de archivos de diccionarios
├── README.md               # Este archivo
├── diccionarios/           # Diccionarios de ataque
│   └── diccionarios/
│       ├── servidores      # Lista de servidores objetivo
│       ├── usuarios.txt    # Lista de usuarios
│       ├── contrasenas.txt # Lista de contraseñas
│       ├── puertos         # Lista de puertos comunes
│       └── wordlist.txt    # Lista de palabras para ataques
├── escaneos/               # Resultados de escaneos
└── logs/                   # Archivos de registro
```

## 🔧 Archivos de Configuración

### `config.py`
- **Función**: Configuración central del sistema
- **Contenido**:
  - Variables de entorno (URL, PORT, USERNAME, PASSWORD)
  - Tokens de autenticación (Bearer, Client ID, Client Secret)
  - URLs de APIs bancarias (Deutsche Bank)
  - Configuración de SWIFT y transferencias
  - Configuración de SSL/TLS

### `constants.py`
- **Función**: Genera IDs únicos para transacciones
- **Contenido**:
  - Generación dinámica de `paymentId` usando UUID
  - Configuración de logging

## 🔍 Scripts de Escaneo

### `01escaneo.py` - Escaneo de Puertos por IP
- **Función**: Escanea múltiples puertos en una IP específica
- **Características**:
  - Escaneo de puertos comunes (22, 80, 443, 3306, etc.)
  - Rango de puertos personalizable
  - Escaneo paralelo con ThreadPoolExecutor
  - Guarda resultados en archivos timestamp
  - Compara puertos encontrados vs esperados

### `02escaneo.py` - Escaneo de IPs por Puerto
- **Función**: Escanea un puerto específico en un rango de IPs
- **Características**:
  - Escaneo de rango de IPs personalizable
  - Un puerto específico por escaneo
  - Validación de rangos de IP
  - Escaneo paralelo optimizado

### `03escaneo.py` - Escaneo Avanzado
- **Función**: Escaneo más sofisticado con detección de servicios
- **Características**:
  - Detección de servicios en puertos
  - Análisis de banners
  - Reportes detallados

### `04escaneo.sh` - Script de Escaneo Bash
- **Función**: Automatización de escaneos usando herramientas externas
- **Herramientas**: nmap, netcat, telnet

### `05escaneo.sh` - Escaneo con Herramientas Especializadas
- **Función**: Escaneo usando herramientas de pentesting
- **Herramientas**: masscan, unicornscan

### `06escaneo.py` - Escaneo de Vulnerabilidades
- **Función**: Detección de vulnerabilidades comunes
- **Características**:
  - Análisis de servicios vulnerables
  - Detección de configuraciones inseguras

### `07escaneo.py` - Escaneo de Servicios Web
- **Función**: Análisis específico de servicios web
- **Características**:
  - Detección de tecnologías web
  - Análisis de headers HTTP
  - Enumeración de directorios

### `08escaneo.py` - Escaneo de Base de Datos
- **Función**: Detección y análisis de bases de datos
- **Características**:
  - Escaneo de puertos de BD (MySQL, PostgreSQL, etc.)
  - Detección de instancias de BD

### `09escaneo.py` - Escaneo de Servicios de Red
- **Función**: Análisis de servicios de red
- **Características**:
  - Detección de servicios de red
  - Análisis de protocolos

### `10escaneo.py` - Escaneo Completo
- **Función**: Escaneo integral del objetivo
- **Características**:
  - Combinación de todos los tipos de escaneo
  - Reporte consolidado

## ⚔️ Scripts de Ataque

### `hydra_ataque.py` - Ataque con Hydra
- **Función**: Ataques de fuerza bruta usando Hydra
- **Características**:
  - Ataques SSH, FTP, HTTP, etc.
  - Configuración desde archivos JSON
  - Logging detallado de ataques
  - Envío de resultados a API
  - Gestión de errores y reintentos

### `medusa_ataque.py` - Ataque con Medusa
- **Función**: Ataques de fuerza bruta usando Medusa
- **Características**:
  - Alternativa a Hydra
  - Soporte para múltiples protocolos
  - Integración con sistema de transacciones
  - Certificados SSL/TLS

### `medusa_ingreso.py` - Ingreso Automatizado
- **Función**: Automatización de ingreso a sistemas
- **Características**:
  - Login automático después de ataques exitosos
  - Gestión de sesiones
  - Extracción de datos

## 📚 Diccionarios

### Ubicación: `diccionarios/diccionarios/`

- **servidores**: Lista de servidores objetivo con IPs
- **usuarios.txt**: Lista de nombres de usuario para ataques
- **contrasenas.txt**: Lista de contraseñas para fuerza bruta
- **puertos**: Puertos comunes para escaneo
- **wordlist.txt**: Lista extensa de palabras para ataques
- **info**: Información adicional sobre objetivos

## 🚀 Uso del Sistema

### 1. Configuración Inicial
```bash
# Activar entorno virtual
source ~/envSIM/bin/activate

# Instalar dependencias
pip install -r requirements.txt
```

### 2. Configurar Variables de Entorno
```bash
# Crear archivo .env con las configuraciones necesarias
cp config.py config_local.py
# Editar config_local.py con tus configuraciones
```

### 3. Ejecutar Escaneos
```bash
# Escaneo básico de puertos
python 01escaneo.py

# Escaneo de rango de IPs
python 02escaneo.py

# Escaneo completo
python 10escaneo.py
```

### 4. Ejecutar Ataques
```bash
# Ataque con Hydra
python hydra_ataque.py

# Ataque con Medusa
python medusa_ataque.py
```

## 📊 Resultados

### Ubicación de Resultados
- **Escaneos**: `escaneos/` (archivos timestamp)
- **Logs**: `logs/` (archivos de registro)
- **Reportes**: Generados automáticamente

### Formato de Resultados
- Archivos de texto con timestamp
- Logs estructurados
- Reportes en formato JSON
- Envío automático a APIs

## ⚠️ Advertencias de Seguridad

⚠️ **IMPORTANTE**: Este sistema está diseñado únicamente para:
- Pruebas de penetración autorizadas
- Auditorías de seguridad
- Entornos de laboratorio controlados

**NO usar en:**
- Sistemas sin autorización
- Entornos de producción sin permiso
- Actividades ilegales

## 🔧 Dependencias

### Python
- `requests`
- `python-dotenv`
- `ipaddress`
- `concurrent.futures`
- `socket`
- `subprocess`
- `logging`
- `json`
- `datetime`

### Herramientas Externas
- `hydra`
- `medusa`
- `nmap`
- `masscan`
- `netcat`

## 📝 Notas de Desarrollo

- El sistema está optimizado para entornos Linux
- Requiere permisos de administrador para algunas funciones
- Los archivos de configuración deben ser personalizados según el entorno
- El sistema incluye logging detallado para auditoría
- Los resultados se envían automáticamente a APIs configuradas

## 🤝 Contribución

Para contribuir al proyecto:
1. Revisar el código existente
2. Seguir las convenciones de nomenclatura
3. Agregar logging apropiado
4. Documentar nuevas funciones
5. Probar en entornos controlados

---

**Desarrollado para pruebas de seguridad autorizadas** 🔒
 
