# 🔍 Sistema de Escaneo Distribido de Puertos

## 📋 Descripción General

Este sistema implementa un **escaneo distribuido de puertos** dividiendo el rango completo de puertos (1-1000) en múltiples scripts independientes. Cada script se encarga de escanear un rango específico de puertos, permitiendo ejecución paralela y distribución de carga.

## 🏗️ Estructura del Proyecto

```
scan/
├── 00escaneo.py              # Escaneo inicial (puertos comunes)
├── 01escaneo_1-50.py         # Puertos 1-50
├── 02escaneo_51-100.py       # Puertos 51-100
├── 03escaneo_101-150.py      # Puertos 101-150
├── 04escaneo_151-200.py      # Puertos 151-200
├── 05escaneo_201-250.py      # Puertos 201-250
├── 06escaneo_251-300.py      # Puertos 251-300
├── 07escaneo_301-350.py      # Puertos 301-350
├── 08escaneo_351-400.py      # Puertos 351-400
├── 09escaneo_401-450.py      # Puertos 401-450
├── 10escaneo_451-500.py      # Puertos 451-500
├── 11escaneo_501-550.py      # Puertos 501-550
├── 12escaneo_551-600.py      # Puertos 551-600
├── 13escaneo_601-650.py      # Puertos 601-650
├── 14escaneo_651-700.py      # Puertos 651-700
├── 15escaneo_701-750.py      # Puertos 701-750
├── 16escaneo_751-800.py      # Puertos 751-800
├── 17escaneo_801-850.py      # Puertos 801-850
├── 18escaneo_851-900.py      # Puertos 851-900
├── 19escaneo_901-950.py      # Puertos 901-950
├── 20escaneo_951-1000.py     # Puertos 951-1000
├── 99escaneo.py              # Escaneo de puertos específicos
└── README.md                 # Este archivo
```

## 🎯 Características del Sistema

### ✅ **Distribución de Carga**
- Cada script maneja **50 puertos** específicos
- Escaneo paralelo con **ThreadPoolExecutor**
- **20 workers** simultáneos por script
- Timeout de **1 segundo** por puerto

### ✅ **Rangos de Puertos**
- **00escaneo.py**: Puertos comunes (22, 80, 443, 21, 25, 110, 143, 3306, 5432, 3389)
- **01-20escaneo.py**: Puertos 1-1000 divididos en rangos de 50
- **99escaneo.py**: Puertos específicos (200, 274, 257, 277, 272, 290, 293, 251, 261, 262, 229, 303, 332, 335, 393, 410, 472, 490, 408, 430)

### ✅ **Rangos de IP**
- **00escaneo.py**: `34.111.230.211` (IP específica)
- **01-20escaneo.py**: `193.150.166.0/24` (Rango de red)
- **99escaneo.py**: `193.150.166.0/24` (Rango de red)

## 🔧 Funcionalidades Técnicas

### **Escaneo de Puertos**
```python
def scan_port(ip, port):
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(1)
            result = s.connect_ex((ip, port))
            if result == 0:
                print(f"Puerto {port} abierto en {ip}")
    except socket.error:
        pass
```

### **Escaneo Paralelo**
```python
def scan_range():
    with concurrent.futures.ThreadPoolExecutor(max_workers=20) as executor:
        executor.map(scan_ip, (str(ip) for ip in ip_range.hosts()))
```

### **Gestión de IPs**
- Uso de `ipaddress.ip_network()` para manejo de rangos
- Escaneo de todas las IPs en el rango especificado
- Soporte para redes /24 (256 IPs)

## 🚀 Uso del Sistema

### **1. Escaneo Individual**
```bash
# Escanear puertos comunes
python 00escaneo.py

# Escanear rango específico (ej: puertos 1-50)
python 01escaneo_1-50.py

# Escanear puertos específicos
python 99escaneo.py
```

### **2. Escaneo Paralelo Completo**
```bash
# Ejecutar todos los escaneos en paralelo
for i in {01..20}; do
    python ${i}escaneo_*.py &
done

# O usando un script bash
#!/bin/bash
for script in 0{1..9}escaneo_*.py 1{0..9}escaneo_*.py 20escaneo_*.py; do
    python "$script" &
done
wait
echo "Todos los escaneos completados"
```

### **3. Escaneo Secuencial**
```bash
# Ejecutar escaneos uno tras otro
for script in 0{1..9}escaneo_*.py 1{0..9}escaneo_*.py 20escaneo_*.py; do
    echo "Ejecutando $script..."
    python "$script"
done
```

## 📊 Configuración de Puertos

### **Puertos Comunes (00escaneo.py)**
```python
common_ports = [
    22,    # SSH
    80,    # HTTP
    443,   # HTTPS
    21,    # FTP
    25,    # SMTP
    110,   # POP3
    143,   # IMAP
    3306,  # MySQL
    5432,  # PostgreSQL
    3389,  # RDP
]
```

### **Rangos Distribuidos**
- **01escaneo_1-50.py**: Puertos 1, 2, 3, ..., 50
- **02escaneo_51-100.py**: Puertos 51, 52, 53, ..., 100
- **...**
- **20escaneo_951-1000.py**: Puertos 951, 952, 953, ..., 1000

### **Puertos Específicos (99escaneo.py)**
```python
common_ports = [
    200, 274, 257, 277, 272, 290, 293, 251, 261, 262,
    229, 303, 332, 335, 393, 410, 472, 490, 408, 430
]
```

## ⚙️ Configuración de Red

### **IPs Objetivo**
- **IP Específica**: `34.111.230.211` (00escaneo.py)
- **Rango de Red**: `193.150.166.0/24` (01-20escaneo.py, 99escaneo.py)

### **Parámetros de Escaneo**
- **Timeout**: 1 segundo por puerto
- **Workers**: 20 threads simultáneos
- **Protocolo**: TCP (socket.SOCK_STREAM)
- **Familia**: IPv4 (socket.AF_INET)

## 📈 Ventajas del Sistema Distribuido

### ✅ **Rendimiento**
- **Escaneo paralelo** de múltiples rangos
- **Distribución de carga** entre scripts
- **Reducción de tiempo** total de escaneo
- **Optimización de recursos** del sistema

### ✅ **Flexibilidad**
- **Ejecución independiente** de cada rango
- **Personalización** de puertos por script
- **Escalabilidad** fácil (agregar más rangos)
- **Mantenimiento** simplificado

### ✅ **Robustez**
- **Fallos aislados** (un script no afecta otros)
- **Reintentos** independientes por rango
- **Logging** separado por script
- **Recuperación** fácil de errores

## 🔧 Dependencias

### **Python Standard Library**
```python
import socket              # Conexiones de red
import concurrent.futures  # Ejecución paralela
from ipaddress import ip_network  # Manejo de IPs
```

### **Requisitos del Sistema**
- Python 3.6+
- Acceso de red
- Permisos para crear sockets
- Memoria suficiente para múltiples threads

## 📝 Ejemplos de Uso

### **Escaneo Rápido de Puertos Comunes**
```bash
python 00escaneo.py
```

### **Escaneo Completo de Red**
```bash
# Ejecutar todos los scripts en paralelo
for i in {01..20}; do
    python ${i}escaneo_*.py > scan_${i}.log 2>&1 &
done
```

### **Monitoreo de Progreso**
```bash
# Verificar qué scripts están ejecutándose
ps aux | grep escaneo

# Ver logs en tiempo real
tail -f scan_*.log
```

## ⚠️ Consideraciones de Seguridad

### **Uso Responsable**
- ⚠️ Solo usar en **sistemas autorizados**
- ⚠️ Respetar **políticas de red**
- ⚠️ No sobrecargar **servidores objetivo**
- ⚠️ Mantener **logs de auditoría**

### **Limitaciones**
- **Rate limiting** puede afectar resultados
- **Firewalls** pueden bloquear escaneos
- **IDS/IPS** pueden detectar actividad
- **Timeout** puede causar falsos negativos

## 🛠️ Personalización

### **Modificar Rangos de IP**
```python
# Cambiar IP objetivo
ip_range = ip_network("TU_IP_AQUI")
```

### **Ajustar Puertos**
```python
# Modificar lista de puertos
common_ports = [
    # Agregar o quitar puertos según necesidad
]
```

### **Configurar Workers**
```python
# Ajustar número de threads
with concurrent.futures.ThreadPoolExecutor(max_workers=50) as executor:
```

## 📊 Análisis de Resultados

### **Formato de Salida**
```
Puerto 22 abierto en 193.150.166.1
Puerto 80 abierto en 193.150.166.5
Puerto 443 abierto en 193.150.166.10
```

### **Procesamiento de Resultados**
```bash
# Filtrar puertos abiertos
grep "abierto" scan_*.log > puertos_abiertos.txt

# Contar puertos por IP
grep "abierto" scan_*.log | awk '{print $5}' | sort | uniq -c
```

---

**Sistema de Escaneo Distribido - Optimizado para Auditorías de Seguridad** 🔒
