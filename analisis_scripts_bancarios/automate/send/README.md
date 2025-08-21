# 📤 Sistema de Envío de Transacciones SWIFT

## 📋 Descripción General

Este sistema maneja el envío automatizado de transacciones SWIFT y transferencias bancarias. Incluye generación de datos, autenticación, envío de transacciones y gestión de respuestas para operaciones bancarias seguras.

## 🏗️ Estructura del Proyecto

```
send/
├── data.py                      # Generación de datos de transacciones
├── swift.py                     # Envío de transacciones SWIFT
├── send.py                      # Script principal de envío
├── send_swift.py                # Envío específico de SWIFT
├── utils.py                     # Utilidades y funciones auxiliares
├── auto_send_swift.sh           # Script bash para envío automático
├── data_sct.txt                 # Datos de transacciones SCT
├── generated_token.py           # Token generado dinámicamente
├── headers.json                 # Headers HTTP para peticiones
└── README.md                    # Este archivo
```

## 🔧 Archivos Principales

### `data.py` - Generación de Datos de Transacciones
- **Función**: Creación y gestión de datos de transacciones bancarias
- **Características**:
  - Generación de datos SEPA (Single Euro Payments Area)
  - Múltiples configuraciones de transacciones (DATA_01, DATA_02, DATA_03, DATA_04)
  - Gestión de cuentas deudoras y acreedoras
  - Configuración de direcciones bancarias
  - Generación de identificadores únicos (endToEndIdentification)
  - Soporte para múltiples monedas (EUR, GBP)

### `swift.py` - Envío de Transacciones SWIFT
- **Función**: Envío automatizado de transacciones SWIFT
- **Características**:
  - Envío de transacciones con reintentos automáticos
  - Gestión de errores SSL y de red
  - Autenticación con certificados
  - Generación de OTP (One-Time Password)
  - Headers personalizados (idempotency-id, Correlation-Id)
  - Logging detallado de operaciones

### `send.py` - Script Principal de Envío
- **Función**: Orquestación del proceso de envío
- **Características**:
  - Coordinación entre diferentes módulos
  - Gestión de flujo de trabajo
  - Validación de datos antes del envío
  - Manejo de respuestas del servidor

### `send_swift.py` - Envío Específico de SWIFT
- **Función**: Envío especializado para transacciones SWIFT
- **Características**:
  - Configuración específica para SWIFT
  - Headers especializados
  - Validación de formato SWIFT

## 🔧 Archivos de Utilidades

### `utils.py` - Funciones Auxiliares
- **Función**: Utilidades compartidas por el sistema
- **Características**:
  - Generación de UUIDs únicos
  - Generación de identificadores end-to-end
  - Validación de headers requeridos
  - Funciones de correlación de transacciones
  - Utilidades de formateo de datos

### `auto_send_swift.sh` - Script Bash Automático
- **Función**: Automatización de envío via bash
- **Características**:
  - Ejecución automática de envíos
  - Configuración de variables de entorno
  - Manejo de errores básico

## 📊 Configuración de Datos

### `data_sct.txt` - Datos de Transacciones SCT
- **Función**: Almacenamiento de datos de transacciones SCT
- **Contenido**:
  - Configuraciones de transferencias
  - Parámetros de cuentas
  - Información de beneficiarios

### `headers.json` - Headers HTTP
- **Función**: Configuración de headers para peticiones HTTP
- **Contenido**:
  - Headers de autenticación
  - Headers de contenido
  - Headers personalizados

### `generated_token.py` - Token Dinámico
- **Función**: Generación de tokens de autenticación
- **Uso**: Autenticación en tiempo real para transacciones

## 🏦 Configuraciones de Transacciones

### **DATA_01 - Santander España**
```python
DATA_01 = create_data(
    "MIRYA TRADING CO LTD", "DE86500700100925993805", "EUR", debtor_address, 460000.00,
    "LEGALNET SYSTEMS SPAIN SL", "ES9400496103962716120773", "EUR", "BANCO SANTANDER",
    {"financialInstitutionId": "BSCHESMMXXX"}, creditor_addresses["DATA_01"], "SCT", paymentId
)
```

### **DATA_02 - BBVA España**
```python
DATA_02 = create_data(
    "MIRYA TRADING CO LTD", "DE86500700100925993805", "EUR", debtor_address, 1000.00,
    "ZAIBATSUS.L.", "ES3901821250410201520178", "EUR", "BANCO BILBAO VIZCAYA ARGENTARIA, S.A.",
    {"financialInstitutionId": "BBVAESMMXXX"}, creditor_addresses["DATA_02"], "SCT", paymentId
)
```

### **DATA_03 - Barclays UK**
```python
DATA_03 = create_data(
    "MIRYA TRADING CO LTD", "DE86500700100925993805", "EUR", debtor_address, 1000.00,
    "REVSTAR GLOBAL INTERNATIONAL LTD", "GB69BUKB20041558708288", "EUR", "BARCLAYS BANK UK PLC",
    {"financialInstitutionId": "BUKBGB22XXX"}, creditor_addresses["DATA_03"], "SCT", paymentId
)
```

### **DATA_04 - HSBC UK**
```python
DATA_04 = create_data(
    "MIRYA TRADING CO LTD", "DE86500700100925993805", "EUR", debtor_address, 1000.00,
    "ECLIPS CORPORATION LTD", "GB43HBUK40127669998520", "EUR", "HSBC UK BANK PLC",
    {"financialInstitutionId": "HBUKGB4BXXX"}, creditor_addresses["DATA_04"], "SCT", paymentId
)
```

## 🚀 Uso del Sistema

### **1. Configuración Inicial**
```bash
# Activar entorno virtual
source ~/envSIM/bin/activate

# Verificar configuración
python -c "from data import DATA_01; print('Configuración cargada')"
```

### **2. Envío Manual de Transacciones**
```bash
# Envío básico
python send.py

# Envío específico de SWIFT
python send_swift.py

# Envío con configuración personalizada
python swift.py
```

### **3. Envío Automático**
```bash
# Usar script bash
./auto_send_swift.sh

# O ejecutar directamente
bash auto_send_swift.sh
```

### **4. Generación de Datos**
```python
# Importar y usar datos
from data import DATA_01, DATA_02, DATA_03, DATA_04

# Usar configuración específica
transaction_data = DATA_01
```

## 🔐 Autenticación y Seguridad

### **Certificados SSL/TLS**
- Uso de certificados para conexiones seguras
- Validación de certificados del servidor
- Manejo de errores SSL

### **Tokens de Autenticación**
- Generación dinámica de tokens
- Tokens OAuth2 para APIs bancarias
- Gestión de expiración de tokens

### **Headers de Seguridad**
- Headers de idempotencia
- Headers de correlación
- Headers de autenticación

## 📊 Formato de Transacciones

### **Estructura de Datos**
```json
{
    "debtorAccount": {
        "currencyCode": "EUR",
        "iban": "DE86500700100925993805"
    },
    "instructedAmount": {
        "amount": 460000.00,
        "currencyCode": "EUR"
    },
    "creditorName": "LEGALNET SYSTEMS SPAIN SL",
    "creditorAccount": {
        "currencyCode": "EUR",
        "iban": "ES9400496103962716120773"
    },
    "creditorBank": "BANCO SANTANDER",
    "creditorAgent": {
        "financialInstitutionId": "BSCHESMMXXX"
    },
    "debtorName": "MIRYA TRADING CO LTD",
    "debtorBank": "DEUTSCHE BANK",
    "debtorAgent": "DEUTDEFFXXX",
    "remittanceInformationUnstructured": "JN2DKYS-LNS-K",
    "date": "2024-01-15",
    "paymentType": "SCT",
    "endToEndIdentification": "unique_id_here"
}
```

## 🔧 Dependencias

### **Python**
- `requests` (peticiones HTTP)
- `json` (procesamiento JSON)
- `uuid` (generación de IDs únicos)
- `datetime` (manejo de fechas)
- `ssl` (conexiones seguras)
- `logging` (registro de eventos)

### **Configuración Externa**
- Certificados SSL/TLS
- Variables de entorno
- Archivos de configuración

## ⚠️ Consideraciones de Seguridad

### **Uso Responsable**
- ⚠️ Solo usar en **entornos autorizados**
- ⚠️ Proteger **certificados y claves**
- ⚠️ Validar **datos de transacciones**
- ⚠️ Mantener **logs de auditoría**

### **Validaciones**
- Verificación de IBANs
- Validación de montos
- Comprobación de monedas
- Verificación de códigos BIC/SWIFT

## 📝 Logging y Monitoreo

### **Logs del Sistema**
```python
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Ejemplo de uso
logger.info("Enviando transacción SWIFT")
logger.error("Error en el envío")
```

### **Monitoreo de Transacciones**
- Seguimiento de estado de envíos
- Registro de respuestas del servidor
- Monitoreo de errores y reintentos
- Auditoría de transacciones

## 🛠️ Personalización

### **Modificar Configuraciones**
```python
# Crear nueva configuración
DATA_CUSTOM = create_data(
    "NOMBRE_DEUDOR", "IBAN_DEUDOR", "EUR", debtor_address, 1000.00,
    "NOMBRE_ACREEDOR", "IBAN_ACREEDOR", "EUR", "BANCO", 
    {"financialInstitutionId": "BIC_CODE"}, creditor_address, "SCT", paymentId
)
```

### **Ajustar Headers**
```json
{
    "Content-Type": "application/json",
    "Authorization": "Bearer YOUR_TOKEN",
    "idempotency-id": "UNIQUE_ID",
    "Correlation-Id": "CORRELATION_ID"
}
```

---

**Sistema de Envío SWIFT - Optimizado para Transacciones Bancarias Seguras** 🏦
