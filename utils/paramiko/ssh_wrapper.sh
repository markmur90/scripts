# ------ ssh_wrapper.sh (actualizado) ------
#!/bin/bash

CONFIG_FILE="/home/markmur88/scripts/utils/paramiko/config.conf"
SCRIPT_PY="/home/markmur88/scripts/utils/paramiko/ssh_connect.py"

function crear_config() {
    echo "[+] Creando archivo de configuración $CONFIG_FILE..."
    cat > "$CONFIG_FILE" <<EOL
ip_vps=123.45.67.89
port_vps=22
dns_vps=vps.mihost.com.ar
user_vps=admin
pass_vps=mysecretpass
EOL

    echo "[*] Archivo creado con valores por defecto."
    echo "[*] Edítalo ahora con tus credenciales reales antes de ejecutar la conexión."
}

function editar_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "[!] Archivo $CONFIG_FILE no existe. Primero debes crearlo."
        exit 1
    fi
    nano "$CONFIG_FILE"
}

function check_tor() {
    if systemctl is-active --quiet tor; then
        echo "[+] Tor está activo."
        return 0
    else
        echo "[-] Tor no está corriendo. Iniciándolo..."
        sudo service tor start
        sleep 20
        if systemctl is-active --quiet tor; then
            echo "[+] Tor iniciado correctamente."
            return 0
        else
            echo "[!] No se pudo iniciar Tor. Instálalo con 'apt install tor' o revisa permisos."
            exit 1
        fi
    fi
}

function ejecutar_conexion() {
    check_tor

    if [ ! -f "$SCRIPT_PY" ]; then
        echo "[!] Script $SCRIPT_PY no encontrado."
        exit 1
    fi

    if [ ! -f "$CONFIG_FILE" ]; then
        crear_config
        sleep 1
        editar_config
    fi

    # --- Aquí pasamos la ruta del config al script Python ---
    python3 "$SCRIPT_PY" "$CONFIG_FILE"
}

function menu() {
    echo "┌──────────────┐"
    echo "│ Wrapper SSH  │"
    echo "└──────────────┘"
    echo ""
    echo "1) Crear config.conf (sobreescribe cualquier existente)"
    echo "2) Editar config.conf actual"
    echo "3) Conectar al VPS usando SSH y Tor"
    read -p "Elige una opción (1/2/3): " opcion

    case $opcion in
        1) crear_config ;;
        2) editar_config ;;
        3) ejecutar_conexion ;;
        *) echo "[!] Opción inválida" ;;
    esac
}

menu
# ---------------------------------------------
