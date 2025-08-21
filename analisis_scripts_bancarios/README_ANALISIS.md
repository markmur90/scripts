# ANÁLISIS COMPLETO DE SCRIPTS BANCARIOS

## Resumen Ejecutivo

Este análisis incluye una colección de scripts relacionados con operaciones bancarias, conexiones SSH, transferencias SWIFT, y automatización de procesos financieros. Los scripts están organizados en diferentes categorías según su funcionalidad.

## Estructura de Archivos

### 1. WormGPT/
- **brute.py**: Script de fuerza bruta para conexiones SSH

### 2. server/04/
- **tls_check_deutschebank.py**: Verificación de certificados TLS para Deutsche Bank
- **simulador_banco/config.py**: Configuración del simulador bancario

### 3. server/02/03_docker/
- **09_generate_jwt.py**: Generación de tokens JWT
- **02_conection.py**: Conexión con certificados SSL
- **01_conection.py**: Pruebas de conectividad DNS, SSH y HTTPS

### 4. server/01/
- **10_conection.py**: Conexión VPN, SSH y API banking completa
- **09_conection.py**: Conexión simple con verificación SSL deshabilitada
- **04_conection.py**: Conexión VPN y SSH con navegador web
- **02_conection.py**: Conexión con certificado Verisign
- **01_conection.py**: Pruebas de conectividad (similar a 01_conection.py en 03_docker)

### 5. automate/send/
- **data.py**: Datos de transferencias bancarias (DATA_01 a DATA_05)
- **utils.py**: Utilidades para generación de UUIDs y validación de headers
- **send.py**: Envío de transacciones SWIFT
- **send_swift.py**: Envío específico de transferencias SWIFT
- **swift.py**: Funcionalidades SWIFT
- **generated_token.py**: Generación de tokens
- **headers.json**: Headers HTTP predefinidos
- **auto_send_swift.sh**: Script bash para automatización
- **data_sct.txt**: Datos de transferencias SCT
- **README.md**: Documentación del módulo send

### 6. automate/scripts_auto/
- **connect_scan.py**: Escaneo de puertos y conexiones SSH
- **connect_db_ssh.py**: Conexión SSH específica para Deutsche Bank

### 7. automate/escaneo/
- **config.py**: Configuración principal del sistema
- **constants.py**: Constantes del sistema
- **hydra_ataque.py**: Script de ataque con Hydra

## Análisis Detallado por Categoría

### 🔐 Scripts de Seguridad y Autenticación

#### brute.py
- **Propósito**: Ataque de fuerza bruta SSH
- **Funcionalidad**: Intenta múltiples combinaciones de usuario/contraseña
- **Técnicas**: Multithreading para acelerar el proceso
- **IP objetivo**: 193.150.166.1:443

#### 09_generate_jwt.py
- **Propósito**: Generación de tokens JWT
- **Algoritmo**: HS256
- **Payload**: Información de empresa (MIRYA TRADING CO LTD)
- **Vigencia**: 24 horas

### 🌐 Scripts de Conexión y Comunicación

#### tls_check_deutschebank.py
- **Propósito**: Verificación de certificados TLS
- **Servidor**: ebankingdb.db.com1:443
- **Funcionalidad**: Obtiene y muestra certificados del servidor

#### 10_conection.py
- **Propósito**: Conexión completa VPN + SSH + API
- **Componentes**:
  - Conexión VPN con OpenConnect
  - Túnel SSH
  - Autenticación API banking
  - Transferencias automáticas
  - Navegación web automática

### 💰 Scripts de Transferencias Bancarias

#### data.py
- **Propósito**: Definición de datos de transferencias
- **Tipos**: DATA_01 a DATA_05 con diferentes configuraciones
- **Bancos**: Santander, BBVA, Barclays, HSBC
- **Monedas**: EUR principalmente
- **Montos**: Desde 1000€ hasta 460,000€

#### send.py
- **Propósito**: Envío de transacciones SWIFT
- **Características**:
  - Reintentos automáticos
  - Validación de headers
  - Logging detallado
  - Manejo de errores

### 🔍 Scripts de Escaneo y Reconocimiento

#### connect_scan.py
- **Propósito**: Escaneo de puertos y conexiones
- **Rango IP**: 193.150.166.0/24
- **Técnicas**: Multithreading, generación de claves RSA
- **Funcionalidad**: Detección de puertos abiertos y conexión SSH

#### hydra_ataque.py
- **Propósito**: Ataque automatizado con Hydra
- **Características**:
  - Carga de diccionarios de usuarios/contraseñas
  - Logging detallado
  - Integración con envío de transacciones
  - Configuración dinámica

### ⚙️ Scripts de Configuración

#### config.py (escaneo)
- **Propósito**: Configuración centralizada
- **Componentes**:
  - URLs de bancos
  - Credenciales
  - Tokens de autenticación
  - Configuración SSL/TLS
  - Variables de entorno

## Patrones de Comportamiento Detectados

### 1. Credenciales Reutilizadas
- Usuario: `deutschebank@AS8373`, `493069k1`
- PIN: `02569S`, `54082`
- SSN: `0211676`

### 2. IPs Objetivo
- Principal: `193.150.166.1`
- Rango: `193.150.166.0/24`
- DNS: `160.83.58.33`

### 3. Puertos Utilizados
- SSH: 22, 443
- HTTPS: 443
- API: 5000, 8000

### 4. Certificados y Seguridad
- Certificado Verisign
- Fingerprint específico
- Configuración TLS personalizada

## Dependencias Identificadas

### Librerías Python Principales
- `paramiko`: Conexiones SSH
- `requests`: Peticiones HTTP/HTTPS
- `ssl`: Manejo de certificados SSL/TLS
- `dns.resolver`: Resolución DNS
- `jwt`: Tokens JWT
- `OpenSSL`: Certificados X.509
- `concurrent.futures`: Multithreading
- `subprocess`: Ejecución de comandos

### Archivos de Configuración
- `config.py`: Configuración principal
- `constants.py`: Constantes del sistema
- `headers.json`: Headers HTTP
- `data_sct.txt`: Datos de transferencias

## Riesgos de Seguridad Identificados

### 🔴 Críticos
1. **Credenciales hardcodeadas** en múltiples archivos
2. **Deshabilitación de verificación SSL** en algunos scripts
3. **Auto-aceptación de claves SSH** (AutoAddPolicy)
4. **Tokens JWT con secretos débiles**

### 🟡 Moderados
1. **Logging excesivo** de información sensible
2. **Manejo inadecuado de errores** que puede exponer información
3. **Uso de diccionarios de ataque** predefinidos

### 🟢 Bajos
1. **Timeouts configurados** para evitar bloqueos
2. **Reintentos limitados** en algunas operaciones

## Recomendaciones de Seguridad

### Inmediatas
1. **Eliminar credenciales hardcodeadas**
2. **Implementar gestión segura de secretos**
3. **Habilitar verificación SSL en todos los scripts**
4. **Revisar y rotar tokens JWT**

### A Mediano Plazo
1. **Implementar autenticación multifactor**
2. **Auditar logs de acceso**
3. **Implementar rate limiting**
4. **Revisar permisos de archivos**

### A Largo Plazo
1. **Implementar infraestructura como código segura**
2. **Automatizar rotación de credenciales**
3. **Implementar monitoreo de seguridad**
4. **Realizar auditorías de seguridad regulares**

## Conclusión

Esta colección de scripts representa un sistema complejo de automatización bancaria con múltiples puntos de entrada y funcionalidades. Aunque técnicamente sofisticado, presenta importantes vulnerabilidades de seguridad que deben ser abordadas antes de cualquier uso en producción.

El análisis revela un patrón de desarrollo que prioriza la funcionalidad sobre la seguridad, lo cual es común en entornos de desarrollo pero inaceptable en sistemas financieros reales.
