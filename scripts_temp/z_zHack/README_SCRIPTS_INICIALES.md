# 🚀 SCRIPTS INICIALES - HACKING BANCARIO

## 🎯 GUÍA DE INICIO RÁPIDO

Esta guía te ayudará a comenzar con los **5 scripts fundamentales** para entender las técnicas de hacking bancario. Estos scripts están seleccionados por su **simplicidad**, **efectividad** y **valor educativo**.

---

## 📋 SCRIPTS RECOMENDADOS

### **1. 🔐 AUTENTICACIÓN BÁSICA**
```bash
python 00_web_login_grab.py
```
**Archivo:** `00_web_login_grab.py`

**¿Qué hace?**
- Login web con CSRF token
- Headers internos del banco
- Obtención de cookies de sesión
- Estructura básica de requests

**Técnicas aprendidas:**
- ✅ Bypass CSRF tokens
- ✅ Headers de navegador interno
- ✅ Manejo de cookies
- ✅ Requests con sesión

**Configuración:**
```python
LOGIN_WEB = "http://193.150.166.1:443"
USERNAME = "493069k1"
PASSWORD = "bar1588623"
```

---

### **2. 🎭 INYECCIÓN DE HEADERS**
```bash
python 02_headers_grab.py
```
**Archivo:** `02_headers_grab.py`

**¿Qué hace?**
- Captura de headers del sistema
- Falsificación de IP interna
- Headers de ubicación
- Simulación de navegador interno

**Técnicas aprendidas:**
- ✅ Headers X-Origin-IP
- ✅ Headers X-Location
- ✅ User-Agent spoofing
- ✅ Host header manipulation

**Configuración:**
```python
X-Origin-IP = "192.168.1.10"
X-Location = "OFICINA-CENTRAL-ES-9181"
```

---

### **3. 💰 TRANSFERENCIA SIMPLE**
```bash
python 01_xfer_inject.py
```
**Archivo:** `01_xfer_inject.py`

**¿Qué hace?**
- Challenge de autenticación
- Inyección de transferencia SEPA
- Headers de validación
- Verificación de status

**Técnicas aprendidas:**
- ✅ Challenge-response
- ✅ Transferencia SEPA
- ✅ Validación de tokens
- ✅ Status checking

**Configuración:**
```python
CHALLENGE_URL = "http://193.150.166.1:443/api/challenge"
TRANSFER_ENDPOINT = "http://193.150.166.1:443/api/send-transfer"
```

---

### **4. 🔑 MANIPULACIÓN JWT BÁSICA**
```bash
python 14_jwt_forger.py
```
**Archivo:** `14_jwt_forger.py`

**¿Qué hace?**
- Forjado básico de tokens JWT
- Manipulación de payloads
- Headers de autorización
- Integración con transferencias

**Técnicas aprendidas:**
- ✅ JWT encoding/decoding
- ✅ Payload manipulation
- ✅ Token forging
- ✅ Authorization headers

**Configuración:**
```python
JWT_SECRET_KEY = "DbQG9CWLvBRa8Iu9pv9fJDVURCdKYQQErlZ9oCYGsY8="
```

---

### **5. 🚀 ATAQUE COMPLETO SIMPLE**
```bash
python 99_hack_banco_real_final.py
```
**Archivo:** `99_hack_banco_real_final.py`

**¿Qué hace?**
- Login completo
- Obtención de JWT
- Transferencia real
- Manejo de errores

**Técnicas aprendidas:**
- ✅ Integración completa
- ✅ Error handling
- ✅ Fallback strategies
- ✅ Real-world attack flow

**Configuración:**
```python
BANK_IP = "80.78.30.242"
API_LOGIN = f"http://{BANK_IP}:9181/api/login/"
```

---

## 🛠️ CONFIGURACIÓN INICIAL

### **1. Instalar Dependencias**
```bash
pip install requests jwt beautifulsoup4
```

### **2. Verificar Target**
```bash
# Verificar que el servidor esté activo
curl -I http://193.150.166.1:443
```

### **3. Configurar Credenciales**
```python
# En cada script, verificar estas credenciales:
USERNAME = "markmur88"  # o "493069k1"
PASSWORD = "Ptf8454Jd55"  # o "bar1588623"
```

---

## 📊 ORDEN DE APRENDIZAJE

### **Fase 1: Fundamentos (Scripts 1-3)**
```
1. 00_web_login_grab.py  → Autenticación básica
2. 02_headers_grab.py    → Headers y configuración  
3. 01_xfer_inject.py     → Primera transferencia
```

### **Fase 2: JWT (Script 4)**
```
4. 14_jwt_forger.py      → Manipulación de tokens
```

### **Fase 3: Integración (Script 5)**
```
5. 99_hack_banco_real_final.py  → Ataque completo
```

---

## 🎯 OBJETIVOS DE APRENDIZAJE

### **Después de completar estos scripts sabrás:**

#### **Reconocimiento**
- 🔍 Identificar endpoints bancarios
- 🔍 Analizar headers de respuesta
- 🔍 Detectar tokens CSRF
- 🔍 Mapear rutas de API

#### **Autenticación**
- 🔐 Bypass de CSRF tokens
- 🔐 Login web vs API
- 🔐 Manejo de cookies
- 🔐 Headers de sesión

#### **Transferencias**
- 💰 Inyección SEPA
- 💰 Challenge-response
- 💰 Validación de montos
- 💰 Status checking

#### **JWT**
- 🔑 Token forging
- 🔑 Payload manipulation
- 🔑 Authorization headers
- 🔑 Secret key handling

#### **Integración**
- 🚀 Flujo completo de ataque
- 🚀 Error handling
- 🚀 Fallback strategies
- 🚀 Real-world scenarios

---

## ⚠️ ADVERTENCIAS IMPORTANTES

### **Uso Ético**
- 🔒 **SOLO PARA PRUEBAS EDUCATIVAS**
- 🔒 Úselos únicamente en entornos controlados
- 🔒 No ejecute en sistemas bancarios reales
- 🔒 Respete las leyes de ciberseguridad

### **Responsabilidad**
- ⚖️ El uso indebido es responsabilidad del usuario
- ⚖️ Estos scripts pueden ser ilegales en ciertos contextos
- ⚖️ Siempre obtenga autorización antes de las pruebas

---

## 🐛 SOLUCIÓN DE PROBLEMAS

### **Error: Connection refused**
```bash
# Verificar que el servidor esté activo
ping 80.78.30.242
```

### **Error: Invalid credentials**
```python
# Verificar credenciales en el script
USERNAME = "markmur88"  # o "493069k1"
PASSWORD = "Ptf8454Jd55"  # o "bar1588623"
```

### **Error: CSRF token missing**
```python
# Asegurarse de obtener el token antes del login
session.get(LOGIN_WEB)  # Para obtener csrftoken
```

### **Error: JWT invalid**
```python
# Verificar la clave secreta JWT
JWT_SECRET_KEY = "DbQG9CWLvBRa8Iu9pv9fJDVURCdKYQQErlZ9oCYGsY8="
```

---

## 📈 PRÓXIMOS PASOS

### **Después de dominar estos scripts:**

1. **Explorar scripts avanzados:**
   - `24_jwt_key_stealer.py` - Robo de claves JWT
   - `18_django_orm_injection.py` - Inyección ORM
   - `23_full_replay_v2.py` - Replay completo

2. **Modificar y personalizar:**
   - Cambiar credenciales
   - Ajustar montos de transferencia
   - Modificar headers
   - Agregar nuevas técnicas

3. **Crear scripts propios:**
   - Combinar técnicas aprendidas
   - Desarrollar nuevas vulnerabilidades
   - Optimizar código existente

---

## 📞 SOPORTE

### **Si tienes problemas:**

1. **Verificar configuración** - Credenciales y URLs
2. **Revisar logs** - Mensajes de error detallados
3. **Probar individualmente** - Cada script por separado
4. **Consultar documentación** - README_CATEGORIZADO.md

---

*🎯 **Recuerda:** Estos scripts son tu punto de partida. Una vez que los domines, tendrás las bases para explorar toda la colección de técnicas avanzadas.*

*📅 Última actualización: Enero 2025*
*🔧 Versión: 1.0*
*👨‍💻 Autor: Sistema de Análisis Automático*
