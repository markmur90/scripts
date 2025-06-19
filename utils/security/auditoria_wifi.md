# 🔍 Auditoría de Seguridad Wi-Fi Corporativa

**Tabla de contenidos**  
1. [Introducción](#introducción)  
2. [Fase 1: Análisis de Red](#fase-1-análisis-de-red)  
   1. [Inventario de Puntos de Acceso (APs)](#1-inventario-de-puntos-de-acceso-aps)  
   2. [Políticas de Seguridad Wi-Fi](#2-políticas-de-seguridad-wi-fi)  
3. [Fase 2: Análisis de Seguridad Operativa](#fase-2-análisis-de-seguridad-operativa)  
   1. [Análisis de Registros de Firewall](#3-análisis-de-registros-de-firewall-último-mes)  
   2. [Alertas del IDS](#4-alertas-del-ids-última-semana)  
   3. [Registros de Correo: Phishing](#5-registros-de-correo-análisis-de-phishing)  
4. [Fase 3: Desarrollo Seguro – Apps Android](#fase-3-desarrollo-seguro–apps-android)  
   1. [Sesiones y Tokens](#sesiones-y-tokens)  
   2. [Almacenamiento Seguro](#almacenamiento-seguro)  
   3. [Anti-Reversing y Hardening](#anti-reversing-y-hardening)  
   4. [Autenticación](#autenticación)  
5. [Anexos y Recursos](#anexos-y-recursos)

---

## Introducción

Este documento describe las fases y acciones clave para:

- **Auditar** la seguridad de redes Wi-Fi corporativas.  
- **Analizar** registros operativos (firewall, IDS, correo).  
- **Revisar** buenas prácticas de desarrollo seguro en apps Android para entornos financieros.

---

## Fase 1: Análisis de Red

### 1. Inventario de Puntos de Acceso (APs)

#### Auditoría

- Mapear APs activos con **Acrylic Wi-Fi**, **Kismet** o **Wireshark**.  
- Detectar **APs rogue** no autorizados.  
- Documentar para cada AP:
  - **Ubicación física** (ideal: mapa de calor).  
  - **Marca & modelo** (e.g., Cisco, Aruba, Ubiquiti).  
  - **Firmware** (versión y estado de parcheo).  
  - **Configuración**:
    - Canales y potencia de señal  
    - SSID (visible/oculto)  
    - Aislamiento de clientes  

#### Recomendaciones

1. Activar detección automática de APs no autorizados en el controlador.  
2. Automatizar actualizaciones de firmware.  
3. Desactivar **WPS** por vulnerabilidades conocidas.

---

### 2. Políticas de Seguridad Wi-Fi

#### Auditoría

- Verificar existencia de documento formal con:
  - **WPA3** o **WPA2-Enterprise** obligatorio.  
  - **802.1X + RADIUS** para autenticación.  
  - Contraseñas rotativas cada 3 meses, ≥12 caracteres (alfanumérico + símbolos).  
  - Red de invitados en **VLAN separada** y con acceso restringido.

#### Recomendaciones

- Forzar rotación trimestral de credenciales.  
- Añadir **MFA** para administradores.  
- Segmentar SSIDs por rol (empleados, invitados, IoT).

---

## Fase 2: Análisis de Seguridad Operativa

### 3. Análisis de Registros de Firewall (último mes)

#### Auditoría

- Buscar anomalías:
  - Conexiones a IPs extranjeras no justificadas.  
  - Accesos en horarios atípicos (p.ej. 02:00–05:00).  
  - Puertos inusuales (3389 RDP, 23 Telnet, 445 SMB).

#### Herramientas y Pasos

```bash
# SPLUNK
wget -O splunk-8.2.5-a7f645ddaf91-linux-2.6-amd64.deb 'https://download.splunk.com/products/splunk/releases/8.2.5/linux/splunk-8.2.5-a7f645ddaf91-linux-2.6-amd64.deb'
sudo dpkg -i splunk-8.2.5-a7f645ddaf91-linux-2.6-amd64.deb
sudo /opt/splunk/bin/splunk enable boot-start --accept-license --answer-yes
sudo systemctl start splunk

# GRAYLOG
sudo apt update
sudo apt install -y openjdk-11-jre-headless uuid-runtime pwgen
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
sudo apt update
sudo apt install -y mongodb-org
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update
sudo apt install -y elasticsearch
sudo systemctl enable --now mongod
sudo systemctl enable --now elasticsearch
echo "deb https://packages.graylog2.org/repo/debian/ stability 4.3" | sudo tee /etc/apt/sources.list.d/graylog.list
wget https://packages.graylog2.org/repo/packages/graylog-4.3-repository_latest.deb
sudo dpkg -i graylog-4.3-repository_latest.deb
sudo apt update
sudo apt install -y graylog-server
SECRET=$(pwgen -N 1 -s 96)
ADMINPASS=$(echo -n yourpassword | sha256sum | cut -d' ' -f1)
sudo sed -i "s/password_secret =.*/password_secret = $SECRET/" /etc/graylog/server/server.conf
sudo sed -i "s/root_password_sha2 =.*/root_password_sha2 = $ADMINPASS/" /etc/graylog/server/server.conf
sudo systemctl enable --now graylog-server

# ELK STACK
sudo apt update
sudo apt install -y openjdk-11-jre-headless apt-transport-https ca-certificates curl
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update
sudo apt install -y elasticsearch logstash kibana
sudo systemctl enable --now elasticsearch
sudo systemctl enable --now logstash
sudo systemctl enable --now kibana
```

#### Recomendaciones

- Implementar **geo-bloqueo** según zonas de operación.
- Cerrar puertos innecesarios.
- Configurar alertas automáticas por picos sospechosos.

---

### 4. Alertas del IDS (última semana)

#### Auditoría

| Severidad | Eventos típicos                                    |
|:---------:|----------------------------------------------------|
| **Alta**  | Inyecciones SQL, explotación de CVEs, escaneos     |
| **Media** | Autenticaciones fallidas múltiples, anomalías DNS  |
| **Baja**  | Cambios menores en patrones de tráfico             |

#### Respuesta (Alta severidad)

1. Aislar segmento afectado.  
2. Capturar evidencia (`tcpdump`, `pcap`).  
3. Actualizar firmas del IDS.  
4. Notificar al CISO y parchear.

---

### 5. Registros de Correo: Análisis de Phishing

#### Auditoría

- Buscar:
  - Adjuntos ejecutables (`.exe`, `.scr`).  
  - URLs acortadas o dominios sospechosos.  
  - Patrones de urgencia o amenazas mal traducidas.

#### Recomendaciones

- Sandbox de enlaces: **Proofpoint**, **Mimecast**.  
- Autenticación de correo: **SPF**, **DKIM**, **DMARC**.  
- Simulacros de phishing periódicos (KnowBe4, PhishMe).

---

## Fase 3: Desarrollo Seguro – Apps Android

### Sesiones y Tokens

- No usar `SharedPreferences` sin cifrado.  
- Invalidar sesión tras logout o inactividad (>15 min).  
- Tokens con expiración corta (≤15 min) y renovación automática.

---

### Almacenamiento Seguro

- Evitar almacenamiento externo (`/sdcard/`).  
- Usar `EncryptedSharedPreferences` o `SQLCipher`.  
- Revisar `AndroidManifest.xml` para permisos mínimos.

---

### Anti-Reversing y Hardening

- Ofuscar con ProGuard o R8.
- Integrar SafetyNet Attestation o Play Integrity API.
- Detectar root/jailbreak y herramientas de hooking (Frida, Xposed).

---

### Autenticación

- No guardar credenciales localmente.
- Implementar MFA con biometría.
- TLS 1.2+ para todas las comunicaciones.

---

## Anexos y Recursos

- Diagramas de red (topología, VLAN, DMZ).
- Inventario de dispositivos y firmware.
- Ejemplos de logs (firewall, IDS, correo).
- Plantillas de reporte de incidentes.
- Scripts de detección de APs rogue y validación de políticas.

