# 🏦 Scripts de Análisis de Seguridad Bancaria - z_zHack

## 📋 Descripción General

Esta carpeta contiene una colección de scripts de análisis de seguridad diseñados para probar la robustez de un sistema bancario simulado. **⚠️ IMPORTANTE: Estos scripts son únicamente para propósitos educativos y de testing en entornos controlados.**

## 🎯 Objetivo

Los scripts simulan diferentes vectores de ataque para identificar vulnerabilidades en:
- Autenticación JWT
- Validación de sesiones
- Headers de seguridad
- Middleware de Django
- Endpoints de transferencias SEPA

---

## 📁 Análisis de Scripts

### 🔐 **Scripts de Autenticación y Login**

#### `00_web_login_grab.py`
- **Función**: Obtiene tokens CSRF desde la web interna del banco
- **Método**: Accede a la página de login para extraer `csrftoken` desde cookies o HTML
- **Headers**: Simula navegador interno con IP falsificada (`192.168.1.10`)
- **Objetivo**: Preparar sesión para ataques posteriores

#### `02_headers_grab.py`
- **Función**: Analiza headers permitidos por el sistema
- **Método**: Realiza peticiones OPTIONS para descubrir CORS y headers aceptados
- **Información**: Revela `Access-Control-Allow-Headers` y orígenes permitidos
- **Objetivo**: Reconocimiento de configuración de seguridad

#### `03_login_with_token.py`
- **Función**: Login con obtención de token JWT
- **Método**: POST a `/api/login/` con credenciales y headers internos
- **Resultado**: Extrae `access_token` para autorización Bearer
- **Objetivo**: Obtener token válido para operaciones

#### `07_clean_login.py` / `07v2_clean_login.py`
- **Función**: Login simplificado sin CSRF
- **Método**: POST directo con credenciales y headers mínimos
- **Objetivo**: Login rápido para testing

#### `13_login_web_brute.py`
- **Función**: Login vía formulario web (no API)
- **Método**: Simula navegador real con `csrfmiddlewaretoken`
- **Objetivo**: Bypass de validaciones de API

---

### 💰 **Scripts de Transferencias**

#### `01_xfer_inject.py`
- **Función**: Inyección de transferencia SEPA básica
- **Método**: Challenge + transferencia con token interno
- **Payload**: Datos de transferencia con IBANs y montos
- **Objetivo**: Ejecutar transferencia sin validación completa

#### `04_transferencia.py`
- **Función**: Transferencia con modelo Django completo
- **Método**: Genera datos estructurados según modelo ORM
- **Campos**: `payment_id`, `debtor`, `creditor`, `instructed_amount`
- **Objetivo**: Simular transferencia real del sistema

#### `06_final_transfer.py`
- **Función**: Transferencia con JWT decodificado
- **Método**: Analiza token JWT y ejecuta transferencia
- **Análisis**: Decodifica payload JWT sin verificar firma
- **Objetivo**: Entender estructura de tokens

#### `08_final_xfer.py` / `08v2_final_xfer.py` / `08v3_final_xfer.py`
- **Función**: Transferencias con tokens hardcodeados
- **Método**: Usa tokens pre-capturados en headers
- **Objetivo**: Bypass de autenticación con tokens válidos

#### `09_full_xfer.py`
- **Función**: Transferencia completa con modelo SEPA
- **Método**: Carga token desde archivo y usa estructura completa
- **Campos**: Todos los campos requeridos por el modelo Django
- **Objetivo**: Transferencia realista completa

#### `11_clean_xfer.py.py`
- **Función**: Transferencia limpia con ORM válido
- **Método**: Ajusta campos a modelo Django exacto
- **Validación**: Usa IDs de cuentas y códigos de estado válidos
- **Objetivo**: Transferencia que pase validaciones ORM

#### `12_xfer_web_django.py`
- **Función**: Transferencia vía formulario web Django
- **Método**: POST a formulario con `sessionid` y `csrftoken`
- **Objetivo**: Bypass de API usando interfaz web

---

### 🔑 **Scripts de Manipulación JWT**

#### `14_jwt_forger.py`
- **Función**: Forja tokens JWT con secretos conocidos
- **Método**: Intenta acceder a `JWT_SECRET_KEY` del middleware
- **Objetivo**: Crear tokens válidos sin autenticación

#### `16_jwt_grab_and_forged.py`
- **Función**: Bruteforce de secretos JWT
- **Método**: Prueba patrones comunes de secretos
- **Patrones**: `django-fake-secret`, `default_jwt_key`, etc.
- **Objetivo**: Descubrir clave de firma JWT

#### `22_jwt_reeval.py`
- **Función**: Renovación de tokens JWT
- **Método**: Usa endpoint de challenge para generar nuevos tokens
- **Objetivo**: Mantener sesión activa con tokens frescos

#### `24_jwt_key_stealer.py`
- **Función**: Roba `JWT_SECRET_KEY` desde errores
- **Método**: Provoca errores en middleware para exponer secretos
- **Técnica**: Inyecta tokens inválidos para generar stacktraces
- **Objetivo**: Extraer clave de firma desde errores del servidor

#### `25_django_jwt_injector.py`
- **Función**: Inyección directa en middleware Django
- **Método**: Provoca errores para exponer configuración interna
- **Objetivo**: Acceso directo al sistema Django

---

### 🌐 **Scripts de Headers y Middleware**

#### `05_login_real_api.py`
- **Función**: Login con headers precisos del sistema
- **Método**: Usa `Host: api.coretransapi.com` y headers internos
- **Objetivo**: Bypass de validaciones de Host

#### `10_django_full_session.py`
- **Función**: Sesión completa de Django
- **Método**: Combina cookies, sessionid y JWT
- **Objetivo**: Simular sesión web completa

#### `17_X-Origin.py`
- **Función**: Explota headers X-Origin para errores
- **Método**: Provoca errores en validación de headers
- **Objetivo**: Exponer información interna del sistema

#### `18_django_orm_injection.py`
- **Función**: Inyección directa en ORM Django
- **Método**: Crea objetos Transfer directamente en el modelo
- **Objetivo**: Bypass de validaciones de API

---

### 🎯 **Scripts de Ataque Completo**

#### `20_banco_xfer_final.py`
- **Función**: Ataque completo con cookies reales
- **Método**: Usa cookies capturadas previamente
- **Cookies**: `csrftoken` y `sessionid` hardcodeados
- **Objetivo**: Transferencia con sesión válida

#### `21_real_xfer_with_real_token.py`
- **Función**: Transferencia con token JWT real
- **Método**: Usa token capturado previamente
- **Objetivo**: Transferencia autenticada real

#### `23_full_replay_v2.py`
- **Función**: Ataque completo desde cero
- **Pasos**: 
  1. Limpia sesión
  2. Login web
  3. Renueva JWT
  4. Ejecuta transferencia
  5. Inyección web como fallback
- **Objetivo**: Ataque automatizado completo

#### `99_hack_banco_real_final.py`
- **Función**: Ataque final con todas las técnicas
- **Métodos**: Login web + challenge + transferencia + formulario
- **Objetivo**: Máxima probabilidad de éxito

#### `100_hack_banco_real_final.py`
- **Función**: Versión simplificada del ataque completo
- **Método**: Login + transferencia directa
- **Objetivo**: Ataque rápido y efectivo

---

## 🛡️ **Vulnerabilidades Identificadas**

### 1. **Validación de Host**
- Los scripts falsifican `Host: api.coretransapi.com`
- Bypass de validaciones de dominio

### 2. **Headers Internos**
- Uso de `X-Origin-IP: 192.168.1.10`
- `X-Location: OFICINA-CENTRAL-ES`
- Simulación de red interna

### 3. **JWT Vulnerable**
- Tokens pueden ser decodificados sin verificar firma
- Posible exposición de `JWT_SECRET_KEY`
- Renovación de tokens sin validación

### 4. **CSRF Bypass**
- Tokens CSRF pueden ser extraídos de HTML
- Uso de tokens dummy cuando no están disponibles

### 5. **Validación de Sesión**
- `sessionid` puede ser reutilizado
- Cookies pueden ser inyectadas directamente

---

## 🔧 **Configuración de Entorno**

### URLs Base
```python
BASE_URL = "http://193.150.166.1:443"
LOGIN_URL = f"{BASE_URL}/api/login/"
TRANSFER_URL = f"{BASE_URL}/api/send-transfer"
```

### Credenciales de Prueba
```python
USERNAME = "markmur88"
PASSWORD = "Ptf8454Jd55"
```

### Headers Comunes
```python
HEADERS = {
    "Host": "80.78.30.242",
    "X-Origin-IP": "192.168.1.10",
    "X-Location": "OFICINA-CENTRAL-ES",
    "X-Session-Type": "BANCO-INTERNAL"
}
```

---

## ⚠️ **Advertencias de Seguridad**

1. **Solo para testing**: Estos scripts deben usarse únicamente en entornos controlados
2. **No usar en producción**: Nunca ejecutar contra sistemas reales
3. **Responsabilidad**: El usuario es responsable del uso de estos scripts
4. **Legalidad**: Asegúrate de tener autorización antes de usar

---

## 📊 **Orden de Ejecución Recomendado**

Para un análisis completo:

1. `00_web_login_grab.py` - Reconocimiento inicial
2. `02_headers_grab.py` - Análisis de headers
3. `03_login_with_token.py` - Obtener token JWT
4. `06_final_transfer.py` - Analizar estructura JWT
5. `09_full_xfer.py` - Transferencia completa
6. `23_full_replay_v2.py` - Ataque automatizado completo

---

## 🎓 **Propósito Educativo**

Estos scripts demuestran:
- Técnicas de bypass de autenticación
- Manipulación de tokens JWT
- Explotación de middleware Django
- Inyección de sesiones
- Bypass de validaciones de seguridad

**Recuerda**: El conocimiento de seguridad debe usarse para proteger sistemas, no para atacarlos.
