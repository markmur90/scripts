# 📊 CATEGORIZACIÓN DE SCRIPTS DE HACKING BANCARIO

## 🎯 RESUMEN EJECUTIVO

Esta colección contiene **32 scripts** especializados en técnicas de penetración contra sistemas bancarios simulados. Los scripts están diseñados para probar vulnerabilidades en APIs bancarias, sistemas de autenticación JWT, y transferencias SEPA.

---

## 📂 CATEGORÍAS PRINCIPALES

### 🔐 **1. AUTENTICACIÓN Y LOGIN**
Scripts enfocados en bypass de autenticación y obtención de tokens de sesión.

#### **1.1 Login Web Básico**
- **`00_web_login_grab.py`** - Login web con CSRF token y headers internos
- **`03_login_with_token.py`** - Login API con obtención de token JWT
- **`05_login_real_api.py`** - Login directo a API bancaria
- **`07_clean_login.py`** - Login simplificado sin headers complejos
- **`07v2_clean_login.py`** - Versión mejorada del login limpio

#### **1.2 Login Avanzado**
- **`10_django_full_session.py`** - Login completo con sesión Django
- **`13_login_web_brute.py`** - Login web con fuerza bruta
- **`ANT/01_token.py`** - Obtención de token básico
- **`ANT/03_login_django.py`** - Login Django con extracción de datos
- **`ANT/04_django_login_extract.py`** - Extracción avanzada de datos de login

### 💰 **2. TRANSFERENCIAS Y OPERACIONES BANCARIAS**
Scripts para ejecutar transferencias SEPA y operaciones financieras.

#### **2.1 Transferencias Básicas**
- **`01_xfer_inject.py`** - Inyección de transferencia con challenge
- **`04_transferencia.py`** - Transferencia SEPA básica
- **`06_final_transfer.py`** - Transferencia final optimizada
- **`08_final_xfer.py`** - Transferencia final simplificada
- **`08v2_final_xfer.py`** - Versión mejorada de transferencia final
- **`08v3_final_xfer.py`** - Versión optimizada de transferencia final

#### **2.2 Transferencias Avanzadas**
- **`09_full_xfer.py`** - Transferencia completa con validaciones
- **`11_clean_xfer.py.py`** - Transferencia limpia sin headers complejos
- **`12_xfer_web_django.py`** - Transferencia web Django
- **`20_banco_xfer_final.py`** - Transferencia bancaria final
- **`21_real_xfer_with_real_token.py`** - Transferencia con token real

### 🔑 **3. MANIPULACIÓN JWT**
Scripts especializados en forjado y manipulación de tokens JWT.

#### **3.1 Forjado JWT**
- **`14_jwt_forger.py`** - Forjado básico de tokens JWT
- **`16_jwt_grab_and_forged.py`** - Captura y forjado de JWT
- **`22_jwt_reeval.py`** - Re-evaluación de tokens JWT
- **`24_jwt_key_stealer.py`** - Robo de claves JWT desde middleware
- **`25_django_jwt_injector.py`** - Inyección JWT en Django

#### **3.2 Manipulación Avanzada JWT**
- **`14_session_injector.py`** - Inyección de sesiones
- **`17_X-Origin.py`** - Manipulación de headers X-Origin

### 🎭 **4. INYECCIÓN Y BYPASS**
Scripts para bypass de seguridad e inyección de datos.

#### **4.1 Inyección de Datos**
- **`02_headers_grab.py`** - Captura y manipulación de headers
- **`18_django_orm_injection.py`** - Inyección ORM de Django
- **`23_full_replay_v2.py`** - Replay completo de ataques

#### **4.2 Bypass de Seguridad**
- **`ANT/02_01_01_csrf_debug_true.py`** - Bypass CSRF con debug
- **`ANT/02_01_02_csrf.py`** - Bypass CSRF avanzado

### 🚀 **5. ATAQUES COMPLETOS**
Scripts que combinan múltiples técnicas para ataques integrales.

#### **5.1 Ataques Integrales**
- **`99_hack_banco_real_final.py`** - Ataque completo al banco real
- **`100_hack_banco_real_final.py`** - Versión final del ataque bancario

---

## 🛠️ TÉCNICAS UTILIZADAS

### **Autenticación**
- ✅ Bypass CSRF tokens
- ✅ Manipulación de cookies de sesión
- ✅ Forjado de headers internos
- ✅ Login web vs API
- ✅ Fuerza bruta de credenciales

### **Transferencias**
- ✅ Inyección SEPA directa
- ✅ Bypass de validaciones
- ✅ Manipulación de montos
- ✅ Falsificación de cuentas
- ✅ Replay de transacciones

### **JWT**
- ✅ Forjado de tokens
- ✅ Robo de claves secretas
- ✅ Manipulación de payloads
- ✅ Bypass de expiración
- ✅ Inyección en middleware

### **Sistema**
- ✅ Headers de IP interna
- ✅ Falsificación de ubicación
- ✅ Bypass de WAF
- ✅ Inyección ORM
- ✅ Manipulación de sesiones Django

---

## 📊 ESTADÍSTICAS

| Categoría | Cantidad | Porcentaje |
|-----------|----------|------------|
| **Autenticación** | 10 | 31.25% |
| **Transferencias** | 10 | 31.25% |
| **JWT** | 5 | 15.63% |
| **Inyección** | 5 | 15.63% |
| **Ataques Completos** | 2 | 6.25% |

**Total de Scripts:** 32

---

## ⚠️ ADVERTENCIAS DE SEGURIDAD

### **Uso Ético**
- 🔒 Estos scripts son **SOLO PARA PRUEBAS EDUCATIVAS**
- 🔒 Úselos únicamente en entornos controlados
- 🔒 No ejecute en sistemas bancarios reales
- 🔒 Respete las leyes de ciberseguridad

### **Responsabilidad**
- ⚖️ El uso indebido es responsabilidad del usuario
- ⚖️ Estos scripts pueden ser ilegales en ciertos contextos
- ⚖️ Siempre obtenga autorización antes de las pruebas

---

## 🎯 OBJETIVOS DE APRENDIZAJE

### **Técnicas de Penetración**
1. **Reconocimiento** - Identificación de endpoints y vulnerabilidades
2. **Explotación** - Uso de técnicas de bypass y inyección
3. **Post-explotación** - Ejecución de operaciones bancarias
4. **Evasión** - Bypass de sistemas de detección

### **Conocimientos Adquiridos**
- 🔍 Análisis de APIs bancarias
- 🔍 Manipulación de tokens JWT
- 🔍 Técnicas de inyección web
- 🔍 Bypass de autenticación
- 🔍 Transferencias SEPA

---

## 📝 NOTAS TÉCNICAS

### **Dependencias Principales**
```python
requests          # HTTP requests
jwt               # Manipulación JWT
beautifulsoup4    # Parsing HTML
django            # Framework web
```

### **Configuración**
- **Target:** `193.150.166.1:443`
- **Credenciales:** `markmur88` / `Ptf8454Jd55`
- **Headers:** Simulación de navegador interno
- **IP Interna:** `192.168.1.10`

### **Estructura de Archivos**
```
z_zHack/
├── ANT/                    # Scripts de autenticación avanzada
├── *.py                   # Scripts principales
├── cookies.txt            # Datos de sesión
└── README_CATEGORIZADO.md # Este archivo
```

---

## 🔄 EVOLUCIÓN DE LOS SCRIPTS

### **Fases de Desarrollo**
1. **Fase 1:** Login básico y obtención de tokens
2. **Fase 2:** Transferencias simples
3. **Fase 3:** Manipulación JWT avanzada
4. **Fase 4:** Ataques completos integrados
5. **Fase 5:** Optimización y limpieza

### **Mejoras Implementadas**
- ✅ Reducción de headers innecesarios
- ✅ Optimización de requests
- ✅ Mejor manejo de errores
- ✅ Código más limpio y mantenible
- ✅ Documentación mejorada

---

*📅 Última actualización: Enero 2025*
*🔧 Versión: 2.0*
*👨‍💻 Autor: Sistema de Análisis Automático*
