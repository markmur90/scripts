## 🔍 Auditoría de Seguridad Wi-Fi Corporativa

### 📋 Introducción
Este documento detalla las fases y acciones clave para realizar una auditoría completa de seguridad en redes Wi-Fi corporativas, análisis operativo de registros de red y buenas prácticas en el desarrollo seguro de aplicaciones Android orientadas a entornos financieros.

---

## Fase 1: Análisis de Red

### 📍 1. Inventario de Puntos de Acceso (APs)

#### Auditoría:
- Usar herramientas como **Acrylic Wi-Fi**, **Kismet** o **Wireshark** para mapear APs activos.
- Identificar **APs rogue** (no autorizados) que puedan comprometer la red.
- Documentar:
  - Ubicación física (incluir mapa de calor si es posible).
  - Marca y modelo (ej. Cisco, Aruba, Ubiquiti).
  - Versión de firmware (verificar si está actualizado).
  - Configuración técnica:
    - Canales utilizados
    - Potencia de señal
    - SSID (visible u oculto)
    - Aislamiento de clientes

#### Recomendaciones:
- Activar detección automática de **APs no autorizados** en el controlador de red.
- Mantener **firmware actualizado**, idealmente mediante actualizaciones automatizadas.
- Desactivar **WPS** (Wi-Fi Protected Setup) por vulnerabilidades conocidas.

---

### 🔐 2. Políticas de Seguridad Wi-Fi

#### Auditoría:
Verificar existencia de un **documento formal de políticas** con los siguientes elementos:
- Uso obligatorio de **WPA3** o **WPA2-Enterprise**.
- Autenticación basada en **802.1X + RADIUS**.
- Contraseñas con rotación periódica y requisitos de complejidad:
  - Mínimo **12 caracteres**
  - Combinación alfanumérica y símbolos
- Red de invitados separada:
  - En **VLAN dedicada**
  - Con acceso restringido a recursos internos

#### Recomendaciones:
- Forzar rotación de contraseñas cada **trimestre**.
- Implementar **MFA** (Autenticación Multifactor) para administradores de red.
- Segmentar redes usando múltiples SSIDs según roles (empleados, invitados, IoT).

---

## Fase 2: Análisis de Seguridad Operativa

### 🧰 3. Análisis de Registros de Firewall (último mes)

#### Auditoría:
Buscar anomalías en logs de firewall, tales como:
- Conexiones frecuentes a **IPs extranjeras no justificadas**.
- Accesos en **horarios atípicos** (ej. entre las 2 AM y 5 AM).
- Uso de **puertos inusuales** (ej. 3389 – RDP, 23 – Telnet, 445 – SMB).

Herramientas recomendadas:
- **Splunk**
- **Graylog**
- **ELK Stack**

1. Splunk
Requisitos

    Ubuntu 20.04 LTS

    Mínimo 4 GB de RAM y 20 GB de espacio en disco libre

    Usuario con permisos sudo

Pasos

    Descargar el paquete .deb de Splunk desde el repositorio oficial.

    Instalar el paquete con dpkg.

    Habilitar e iniciar el servicio Splunk.

    Aceptar la licencia e iniciar sesión en la interfaz web (puerto 8000).

2. Graylog
Requisitos

    Ubuntu 20.04 LTS

    Java OpenJDK 11

    MongoDB como base de datos

    Elasticsearch (compatible, versión 7.x)

Pasos

    Instalar Java 11.

    Instalar y configurar MongoDB.

    Instalar Elasticsearch 7.x.

    Añadir repositorio de Graylog y su clave GPG.

    Instalar Graylog Server.

    Generar contraseña secreta (password_secret) y contraseña de administrador (root_password_sha2) en graylog.conf.

    Iniciar y habilitar los servicios MongoDB, Elasticsearch y Graylog.

    Acceder a la interfaz web de Graylog (puerto 9000).

3. ELK Stack
Requisitos

    Ubuntu 20.04 LTS

    Java OpenJDK 11

Pasos

    Instalar Java 11.

    Agregar repositorio oficial de Elastic.

    Instalar Elasticsearch, Logstash y Kibana.

    Configurar Elasticsearch y Kibana (ajustes de red si es necesario).

    Iniciar y habilitar los tres servicios.

    Acceder a Kibana en puerto 5601 para visualizar datos.

Comandos de instalación

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

Con esto tendrás instalados y en ejecución Splunk (puerto 8000), Graylog (puerto 9000) y ELK Stack (puerto 5601). ¡A disfrutar del análisis de logs con tu arsenal completo!

#### Recomendaciones:
- Aplicar **geo-bloqueo** si la empresa no opera internacionalmente.
- Cerrar **puertos innecesarios**.
- Configurar **alertas automáticas** ante picos de tráfico saliente sospechoso.

---

### ⚠️ 4. Alertas del IDS (última semana en red gubernamental)

#### Auditoría:
Clasificación de alertas por nivel de severidad:

| Severidad | Tipos de eventos |
|----------|------------------|
| Alta     | Inyecciones SQL, explotación de CVEs, escaneos activos |
| Media    | Autenticaciones fallidas múltiples, anomalías DNS |
| Baja     | Cambios menores en patrones de tráfico |

#### Respuesta sugerida (alta severidad):
- Aislar el segmento afectado.
- Recolectar evidencia forense (**tcpdump**, **pcap**).
- Actualizar firmas del IDS.
- Notificar al **CISO** y aplicar parches inmediatos si aplica.

---

### 📨 5. Registros de Correo: Análisis de Phishing (empresa minorista)

#### Auditoría:
Revisar correos electrónicos buscando:
- Adjuntos ejecutables (.exe, .scr).
- URLs acortadas o dominios similares al corporativo.
- Patrones comunes de phishing:
  - Urgencia de pago.
  - Dominios falsificados (ej. corp-sec.com vs corpsec.com).
  - Lenguaje amenazante o mal traducido.

#### Recomendaciones:
- Integrar sistemas de sandboxing de links como **Proofpoint** o **Mimecast**.
- Implementar protocolos de autenticación de correo:
  - **SPF**
  - **DKIM**
  - **DMARC**
- Capacitación recurrente con simulaciones de phishing (ej. **KnowBe4**, **PhishMe**).

---

## Fase 3: Desarrollo Seguro – Aplicaciones Android

### ✅ Lista de Verificación de Seguridad para Revisión de Código

Objetivo: Prevenir vulnerabilidades típicas en apps bancarias.

---

### 🔐 Sesiones

- Evitar uso de `SharedPreferences` sin cifrado para almacenar tokens.
- Invalidar sesión tras **logout** o **inactividad prolongada**.
- Usar **SecureStorage** o librerías de cifrado como **AES-256**.
- Renovar tokens con expiración corta (máximo **15 minutos**).

---

### 🧱 Almacenamiento Seguro

- No guardar datos sensibles en almacenamiento externo (`/sdcard/`).
- Usar `EncryptedSharedPreferences` o `SQLCipher` para bases de datos locales.
- Validar que en `AndroidManifest.xml` esté configurado:

### 🕵️ Anti-Reversing y Hardening 

- Aplicar obfuscación con ProGuard  o R8 .
- Usar SafetyNet Attestation  o Play Integrity API  para verificar integridad del dispositivo.
- Detectar entornos modificados:
    - Root/Jailbreak.
    - Hooking tools (ej. Frida , Xposed )

---

### 🔑 Autenticación 

- No almacenar credenciales localmente.
- Implementar autenticación multifactor (MFA)  con soporte de biometría.
- Obligatorio usar TLS 1.2/1.3  para comunicaciones seguras.

---

### 📁 Archivos y Recursos Adicionales (Sugeridos) 

- Para completar esta auditoría, se recomienda incluir: 

- Diagramas de red (topología, VLANs, zonas DMZ).
- Listado de dispositivos y firmware usado.
- Logs de ejemplo de firewall, IDS y correo.
- Plantillas de reporte de incidentes y hallazgos críticos.
- Scripts básicos de detección de APs rogue o revisión de políticas de red.
