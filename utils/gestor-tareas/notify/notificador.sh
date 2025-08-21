#!/usr/bin/env bash
# set +e
# exec 2>/dev/null

#!/usr/bin/env bash
# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_BK_DIR="/home/markmur88/api_bank_h2_BK"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
VENV_PATH="/home/markmur88/envSIM"
SCRIPTS_DIR="/home/markmur88/scripts"
BACKU_DIR="$SCRIPTS_DIR/backup"
CERTS_DIR="$SCRIPTS_DIR/certs"
DP_DJ_DIR="$SCRIPTS_DIR/deploy/django"
DP_GH_DIR="$SCRIPTS_DIR/deploy/github"
DP_HK_DIR="$SCRIPTS_DIR/deploy/heroku"
DP_VP_DIR="$SCRIPTS_DIR/deploy/vps"
SERVI_DIR="$SCRIPTS_DIR/service"
SYSTE_DIR="$SCRIPTS_DIR/src"
TORSY_DIR="$SCRIPTS_DIR/tor"
UTILS_DIR="$SCRIPTS_DIR/utils"
CO_SE_DIR="$UTILS_DIR/conexion_segura_db"
UT_GT_DIR="$UTILS_DIR/gestor-tareas"
SM_BK_DIR="$UTILS_DIR/simulator_bank"
TOKEN_DIR="$UTILS_DIR/token"
GT_GE_DIR="$UT_GT_DIR/gestor"
GT_NT_DIR="$UT_GT_DIR/notify"
GE_LG_DIR="$GT_GE_DIR/logs"
GE_SH_DIR="$GT_GE_DIR/scripts"

BASE_DIR="$AP_H2_DIR"

set -euo pipefail

LOG_DIR="$GT_NT_DIR/logs_notificadores"

NOTIF1="$GT_NT_DIR/notificador.sh"
NOTIF2="$GT_NT_DIR/notificador_30.sh"

# # --- logging ---
LOG_FILE="$AP_H2_DIR/scripts/gestor_tareas/gestor/logs_notificadores/$(basename "$0").log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo -e "\n🔄 Inicio $(date '+%F %T')"

# ------------------------------------------
# Configuración inicial
# ------------------------------------------
export DISPLAY=:0.0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

MENSAJE="${1:-⏰ Recordatorio: tiempo transcurrido}"
INTERVALO_MINUTOS="${2:-15}"
SONIDO="/usr/share/sounds/freedesktop/stereo/message.oga"
TODO_FILE="$LOG_DIR/.notifier_todos"
TIEMPO_INICIO=$(date +%s)

# Asegurarse de que exista el archivo de pendientes
touch "$TODO_FILE"

# ------------------------------------------
# Función para gestionar la lista de pendientes
# ------------------------------------------
function manage_todos() {
    while true; do
        mapfile -t tasks < "$TODO_FILE"

        # Mostrar lista de tareas actuales si existen
        if [ ${#tasks[@]} -gt 0 ]; then
            # Preparar texto con viñeta por cada tarea
            task_list=$(printf "• %s\n" "${tasks[@]}")
            # Diálogo scrollable para que el usuario vea todas las tareas
            echo -e "$task_list" | zenity --text-info \
                                          --title="📋 Tareas actuales" \
                                          --width=400 \
                                          --height=600
        fi

        # Si no hay tareas, preguntar directamente si quiere agregar una
        if [ ${#tasks[@]} -eq 0 ]; then
            if zenity --question \
                       --title="📋 Lista de pendientes" \
                       --text="No hay tareas pendientes. ¿Deseas agregar una nueva?"; then
                new_task=$(zenity --entry \
                                  --title="➕ Agregar tarea" \
                                  --text="Ingresa la descripción de la nueva tarea:")
                if [ -n "$new_task" ]; then
                    echo "$new_task" >> "$TODO_FILE"
                    continue   # Volver a reevaluar, ya que ahora existe al menos 1 tarea
                else
                    # Si el usuario dejó vacío o canceló, volvemos a preguntar
                    continue
                fi
            else
                # El usuario elige “No” → salir de gestión de pendientes
                break
            fi
        fi

        # Si hay tareas, primero preguntamos WHAT-TO-DO: Marcar completadas / Agregar nueva / Salir
        action=$(zenity --list --radiolist \
                        --title="📋 Gestión de pendientes" \
                        --text="Tienes ${#tasks[@]} tarea(s) pendiente(s).\n¿Qué deseas hacer?" \
                        --column="" --column="Acción" \
                        TRUE "Salir" FALSE "Marcar completadas" FALSE "Agregar nueva" \
                        --width=600 --height=350)
        exit_code=$?

        if [ $exit_code -ne 0 ] || [ -z "$action" ] || [ "$action" == "Salir" ]; then
            # Si pulsa “Cancelar” / cierra diálogo / elige “Salir”: salimos de manage_todos
            break
        fi

        if [ "$action" == "Agregar nueva" ]; then
            # Mostrar cuadro de entrada para la descripción de la nueva tarea
            new_task=$(zenity --entry \
                              --title="➕ Agregar tarea" \
                              --text="Ingresa la descripción de la nueva tarea:")
            if [ -n "$new_task" ]; then
                echo "$new_task" >> "$TODO_FILE"
            fi
            # Regresar al inicio del bucle para reevaluar el menú (podríamos querer agregar más o marcar)
            continue
        fi

        if [ "$action" == "Marcar completadas" ]; then
            # Construir args para checklist: cada línea = FALSE + "texto de la tarea"
            checklist_args=()
            for task in "${tasks[@]}"; do
                checklist_args+=(FALSE "$task")
            done

            # Mostrar checklist: cada tarea aparece con un checkbox inicial sin marcar
            result=$(zenity --list \
                            --checklist \
                            --title="✔️ Marcar tareas completadas" \
                            --text="Selecciona las tareas que ya hayas completado:" \
                            --column="" --column="Tarea" \
                            "${checklist_args[@]}" \
                            --width=400 \
                            --height=600 \
                            --ok-label="Eliminar seleccionadas" \
                            --cancel-label="Volver")
            code_list=$?

            if [ $code_list -eq 1 ] || [ -z "$result" ]; then
                # Si pulsa “Volver” o cierra sin nada seleccionado, regresa al menú principal
                continue
            fi

            # Zenity devuelve las tareas seleccionadas separadas por '|'
            IFS="|" read -r -a done_tasks <<< "$result"

            # Crear temporal para solo guardar las no seleccionadas
            tmpfile=$(mktemp)
            while IFS= read -r line; do
                skip=false
                for done in "${done_tasks[@]}"; do
                    if [ "$line" == "$done" ]; then
                        skip=true
                        break
                    fi
                done
                if ! $skip; then
                    echo "$line" >> "$tmpfile"
                fi
            done < "$TODO_FILE"

            # Reemplazar archivo original
            mv "$tmpfile" "$TODO_FILE"
            # Tras eliminar, ya volvemos al menú inicial: si quedan tareas, volverá a preguntar
            continue
        fi

    done
}

TIEMPO_INICIO=$(date +%s)

# Mensaje inicial en consola
echo "🟢 Notificaciones activadas cada $INTERVALO_MINUTOS minutos exactos del reloj."

# ------------------------------------------
# Bucle principal de notificaciones
# ------------------------------------------

# Evitar duplicados
if pgrep -f "notificador.sh 5" > /dev/null; then
  echo "⚠ Ya hay un notificador.sh corriendo con intervalo 5 minutos. Abortando."
  exit 1
fi


while true; do
    # 1) Mostrar notificación visual + sonido
    HORA_LOCAL=$(date '+%H:%M:%S')
    HORA_BOGOTA=$(TZ=America/Bogota date '+%H:%M:%S')

    # Enviar notificación visual con zenity y sonido en paralelo
    TIEMPO_ACTUAL=$(date +%s)
    MINUTOS_TRANSCURRIDOS=$(( (TIEMPO_ACTUAL - TIEMPO_INICIO) / 60 ))

    (
    zenity --info \
        --title="🔔 Tiempo transcurrido: $MINUTOS_TRANSCURRIDOS minutos" \
        --text="$MENSAJE\nHora local: $HORA_LOCAL\nHora Bogotá: $HORA_BOGOTA" \
        --timeout=3
    ) &
    paplay "$SONIDO" &

    # 2) Si el usuario cierra o ignora la notificación (exit != 0), terminar
    if [[ $? -ne 0 ]]; then
        echo "⏹ Notificación ignorada, continuo...."
    fi

    # 3) Gestionar la lista de pendientes después de la notificación
    manage_todos

    # 4) Calcular segundos hasta el siguiente múltiplo de INTERVALO_MINUTOS
    MINUTOS_ACTUALES=$(date +%M)
    SEGUNDOS_ACTUALES=$(date +%S)
    RESTO=$((MINUTOS_ACTUALES % INTERVALO_MINUTOS))
    ESPERA=$(( (INTERVALO_MINUTOS - RESTO) * 60 - SEGUNDOS_ACTUALES ))
    if [ "$ESPERA" -le 0 ]; then
        ESPERA=$((INTERVALO_MINUTOS * 60))
    fi

    # 5) Dormir hasta el próximo disparo
    sleep "$ESPERA"
done
