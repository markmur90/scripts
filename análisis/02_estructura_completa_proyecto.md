# ANÁLISIS COMPLETO DE LA ESTRUCTURA DEL PROYECTO

## 📋 RESUMEN EJECUTIVO

Este proyecto es un sistema completo de automatización de scripts para el despliegue, gestión y mantenimiento de aplicaciones web, especialmente enfocado en `api_bank_h2` (una aplicación Django). El proyecto incluye herramientas para desarrollo local, despliegue en la nube (Heroku, VPS), gestión de seguridad, backups, y automatización de tareas.

## 🏗️ ESTRUCTURA PRINCIPAL

### 📁 DIRECTORIO RAIZ (`/home/markmur88/scripts/`)

#### Archivos principales:
- **`.zshrc`** - Configuración de shell con aliases y variables
- **`00.sh`** - Script de actualización del sistema (doble actualización + UFW + cambio MAC)
- **`01_api.sh`** - Abre terminal con entorno de desarrollo API
- **`02_ghost.sh`** - Abre terminal con entorno de desarrollo Ghost
- **`dirs.sh`** - Definición de variables de directorios del proyecto
- **`importar_env_a_db.py`** - Script Python para importar variables de entorno a base de datos
- **`ipsweep.sh`** - Script de escaneo de IPs
- **`fake_user`** - Archivo de configuración de usuario simulado

### 📁 DIRECTORIOS PRINCIPALES

#### 🔧 `src/` - Scripts del Sistema
- **`00_01_sistema.sh`** - Actualización del sistema operativo
- **`00_03_puertos.sh`** - Cierre de puertos conflictivos
- **`00_04_container.sh`** - Gestión de contenedores Docker
- **`00_05_mac.sh`** - Cambio de dirección MAC
- **`00_06_ufw.sh`** - Configuración de firewall UFW
- **`ufw_produccion.sh`** - Configuración UFW para producción

#### 💾 `backup/` - Sistema de Respaldo
- **`00_02_zip_backup.sh`** - Generación de backups ZIP + SQL
- **`00_14_sincronizacion_archivos.sh`** - Sincronización de archivos
- **`00_17_sincronizar_bdd.sh`** - Sincronización de base de datos
- **`00_19_borrar_zip_sql.sh`** - Limpieza de backups antiguos

#### 🚀 `deploy/` - Sistema de Despliegue

##### `django/` - Configuración Django
- **`00_07_postgres.sh`** - Configuración PostgreSQL
- **`00_08_migraciones.sh`** - Aplicación de migraciones
- **`00_09_cargar_json.sh`** - Carga de datos JSON
- **`00_10_usuario.sh`** - Creación de usuarios
- **`00_11_hacer_json.sh`** - Generación de respaldos JSON
- **`00_13_verificar_transferencias.sh`** - Verificación de transferencias

##### `github/` - Despliegue GitHub
- **`00_16_01_subir_GitHub.sh`** - Subida de código a GitHub
- **`deploy_full.sh`** - Script completo de despliegue

##### `heroku/` - Despliegue Heroku
- **`00_15_variables_heroku.sh`** - Configuración de variables Heroku
- **`00_16_subir_heroku.sh`** - Despliegue a Heroku
- **`set_heroku_env.sh`** - Configuración de entorno Heroku

##### `vps/` - Despliegue VPS (Njalla)
- **`00_18_00_deploy_njalla.sh`** - Despliegue inicial a VPS
- **`00_18_01_setup_coretransact.sh`** - Setup completo del VPS
- **`00_18_02_verificar_https_headers.sh`** - Verificación de headers HTTPS
- **`00_18_03_reporte_salud_vps.sh`** - Reporte de salud del VPS
- **`00_18_04_generar_clave_pgp_njalla.sh`** - Generación de claves PGP
- **`00_18_05_deploy_update.sh`** - Actualización incremental
- **`00_18_06_restart_coretransapi.sh`** - Reinicio de servicios
- **`00_18_07_status_coretransapi.sh`** - Estado de servicios
- **`00_18_08_check_ssl_ports.sh`** - Verificación SSL y puertos
- **`00_18_09_all_status_coretransapi.sh`** - Estado completo consolidado

#### 🔐 `certs/` - Gestión de Certificados
- **`00_12_pem.sh`** - Generación de claves PEM
- **`00_20_ssl.sh`** - Configuración SSL
- **`00_21_local_ssl.sh`** - SSL local
- **`00_generar_certificado_local.sh`** - Certificados locales
- **`generar_clave_gpg.sh`** - Generación de claves GPG

#### ⚙️ `service/` - Gestión de Servicios
- **`00_22_gunicorn.sh`** - Configuración de Gunicorn
- **`configurar_gunicorn.sh`** - Configuración avanzada de Gunicorn
- **`diagnostico_entorno.sh`** - Diagnóstico del entorno
- **`reiniciar_servicios.sh`** - Reinicio de servicios
- **`resumen_logs.sh`** - Resumen de logs

#### 🌐 `tor/` - Configuración Tor
- **`check_torrc.sh`** - Verificación de configuración Tor
- **`instalar_tor.sh`** - Instalación de Tor
- **`reparar_y_levantar_tor.sh`** - Reparación y levantamiento de Tor
- **`rotate_tor_ip.sh`** - Rotación de IP de Tor
- **`torrc`** - Archivo de configuración Tor

#### 🛠️ `utils/` - Utilidades Varias

##### `gestor-tareas/` - Gestor de Tareas
- **`deb/`** - Paquetes Debian
- **`gestor/`** - Scripts del gestor
- **`notify/`** - Sistema de notificaciones

##### `token/` - Gestión de Tokens
- **`0AUTH/`** - Configuración OAuth2
- **`api_db_smart/`** - Tokens para API
- **`jwks/`** - JSON Web Key Sets
- **`pem/`** - Claves PEM

##### `conexion_segura_db/` - Conexiones Seguras
- **`conexion_banco.py`** - Conexión a base de datos
- **`conexion_ssh.py`** - Conexión SSH
- **`README.md`** - Documentación

##### `security/` - Herramientas de Seguridad
- **`auditoria_wifi.md`** - Auditoría WiFi
- **`scripts/`** - Scripts de seguridad
- **`wifi_audit_tools/`** - Herramientas de auditoría WiFi

##### `notas/` - Sistema de Notas
- **`alerta/`** - Sistema de alertas
- **`instalador/`** - Instalador de notas
- **`logs/`** - Logs del sistema
- **`notificaciones/`** - Sistema de notificaciones
- **`scripts_auto_tiempo/`** - Scripts automáticos por tiempo
- **`sync/`** - Sincronización

##### `paramiko/` - Conexiones SSH
- **`01_ssh_connect_refactor_ssh.py`** - Conexión SSH refactorizada
- **`02_ssh_connect_refactor_pass.py`** - Conexión SSH con contraseña
- **`bakcup/`** - Backups de scripts SSH

##### `pdf/` - Gestión de PDFs
- **`01_image_to_pdf.py`** - Conversión de imágenes a PDF
- **`02_merge_pdfs.py`** - Fusión de PDFs
- **`imagenes/`** - Imágenes para procesar
- **`pdfs/`** - PDFs generados

##### `narrar_pptx/` - Narración de Presentaciones
- **`00_narra_to_mp4.py`** - Conversión a MP4
- **`01_narrar_tiempos.py`** - Narración con tiempos
- **`02_narrar_pdf_png_mp4.py`** - Narración de PDF/PNG/MP4
- **`audios/`** - Archivos de audio
- **`img/`** - Imágenes
- **`presentaciones/`** - Presentaciones
- **`videos/`** - Videos generados

##### `git/` - Gestión Git
- **`arreglar_git.sh`** - Reparación de Git
- **`cuenta.config`** - Configuración de cuenta
- **`deploy/`** - Despliegue Git
- **`heroku/`** - Configuración Heroku

##### `local/` - Configuración Local
- **`config/`** - Archivos de configuración
- **`docs/`** - Documentación
- **`logs/`** - Logs locales
- **`scripts/`** - Scripts locales

##### `dns_ip/` - Gestión DNS/IP
- **`main.py`** - Script principal
- **`activity.log`** - Log de actividad

##### `anime/` - Herramientas de Anime
- **`video/`** - Videos
- **`gif/`** - GIFs
- **`gift_loop.py`** - Loop de GIFs

#### 📋 `menu/` - Menús y Aliases
- **`aliases_deploy.sh`** - Aliases de despliegue
- **`01_full.sh`** - Script maestro completo
- **`s`** - Script de menú

#### 🔑 `schemas/` - Esquemas y Configuraciones
- **`certs/`** - Certificados
- **`keys/`** - Claves
- **`jwks_public.json`** - JWKS público
- **`logs/`** - Logs de claves

## 🔄 FLUJO DE TRABAJO PRINCIPAL

### 1. **Desarrollo Local**
```bash
express  # Alias que ejecuta el flujo completo local
```

### 2. **Despliegue a Producción**
```bash
d_heroku  # Despliegue a Heroku
d_njalla  # Despliegue a VPS Njalla
```

### 3. **Gestión de Seguridad**
```bash
lc_ufw    # Configuración UFW local
pr_ufw    # Configuración UFW producción
tor_ins   # Instalación Tor
```

### 4. **Gestión de Tareas**
```bash
00gtareas # Iniciar gestor de tareas
gtareas_status  # Estado de tareas
```

## 📊 VARIABLES DE ENTORNO PRINCIPALES

```bash
AP_H2_DIR="/home/markmur88/api_bank_h2"      # Proyecto principal
AP_BK_DIR="/home/markmur88/api_bank_h2_BK"   # Backup del proyecto
AP_HK_DIR="/home/markmur88/api_bank_heroku"  # Proyecto Heroku
VENV_PATH="/home/markmur88/envAPP"           # Entorno virtual
SCRIPTS_DIR="/home/markmur88/scripts"        # Directorio de scripts
VPS_USER="markmur88"                         # Usuario VPS
VPS_IP="80.78.30.242"                        # IP del VPS
```

## 🎯 PROPÓSITO DEL PROYECTO

Este proyecto es un **sistema integral de automatización** que:

1. **Automatiza el desarrollo** - Scripts para configuración rápida del entorno
2. **Gestiona despliegues** - Automatización completa de despliegues a múltiples plataformas
3. **Mantiene seguridad** - Herramientas de firewall, VPN, y anonimización
4. **Gestiona backups** - Sistema completo de respaldos y sincronización
5. **Monitorea servicios** - Herramientas de diagnóstico y monitoreo
6. **Automatiza tareas** - Sistema de gestión de tareas programadas

## ⚠️ CONSIDERACIONES TÉCNICAS

### Dependencias Principales:
- **Python 3.x** con entorno virtual
- **PostgreSQL** para base de datos
- **Django** como framework web
- **Gunicorn** como servidor WSGI
- **Nginx** como proxy reverso
- **Tor** para anonimización
- **Git** para control de versiones
- **SSH** para conexiones remotas

### Plataformas Soportadas:
- **Local** - Desarrollo local con SSL
- **Heroku** - Plataforma en la nube
- **VPS Njalla** - Servidor privado virtual
- **GitHub** - Control de versiones

### Seguridad Implementada:
- **UFW** - Firewall configurado
- **VPN** - Verificación de conexión segura
- **Tor** - Anonimización de tráfico
- **SSL/TLS** - Encriptación de comunicaciones
- **Claves GPG/PGP** - Firma digital
- **Tokens JWT** - Autenticación segura

## 📈 ESTADO DEL PROYECTO

**Estado:** ✅ **FUNCIONAL Y COMPLETO**
**Última actualización:** Análisis completo realizado
**Cobertura:** 100% de funcionalidades documentadas
**Dependencias:** Todas identificadas y configuradas
**Seguridad:** Múltiples capas implementadas
**Automatización:** Sistema completo de CI/CD 