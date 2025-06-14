#!/bin/bash

# === RUTAS ===
LOG_DIR="/home/markmur88/logs"
mkdir -p "$LOG_DIR"

LOG_ALERTAS="$LOG_DIR/alertas_horas.log"
LOG_TOTAL="$LOG_DIR/tiempo_total.log"
LOG_DIA="$LOG_DIR/tiempo_dia.log"
LOG_FECHA="$LOG_DIR/ultima_fecha.log"
LOG_AUDIO="$LOG_DIR/audio_contador.log"

# === TELEGRAM ===
TG_TOKEN="TU_TOKEN"
TG_CHAT_ID="TU_CHAT_ID"

HORA_ACTUAL=$(date +"%Y-%m-%d %H:%M:%S")
DIA_HOY=$(date +"%Y-%m-%d")

# Si es un nuevo día, reinicia log diario
if [ ! -f "$LOG_FECHA" ] || [ "$DIA_HOY" != "$(cat $LOG_FECHA)" ]; then
    echo "0" > "$LOG_DIA"
    echo "$DIA_HOY" > "$LOG_FECHA"
    echo "0" > "$LOG_AUDIO"
fi

# Inicializar logs
[ ! -f "$LOG_TOTAL" ] && echo "0" > "$LOG_TOTAL"
[ ! -f "$LOG_DIA" ] && echo "0" > "$LOG_DIA"
[ ! -f "$LOG_AUDIO" ] && echo "0" > "$LOG_AUDIO"

# Sumar 60 minutos (1 hora)
TOTAL=$(<"$LOG_TOTAL")
DIA=$(<"$LOG_DIA")
AUDIO_CONT=$(<"$LOG_AUDIO")

TOTAL=$((TOTAL + 60))
DIA=$((DIA + 60))
AUDIO_CONT=$((AUDIO_CONT + 1))

echo "$TOTAL" > "$LOG_TOTAL"
echo "$DIA" > "$LOG_DIA"
echo "$AUDIO_CONT" > "$LOG_AUDIO"

format_time() {
    printf "%02d horas y %02d minutos" $(($1 / 60)) $(($1 % 60))
}

MENSAJE="⏰ $HORA_ACTUAL
📊 Hoy: $(format_time $DIA)
📦 Proyecto: $(format_time $TOTAL)"

# === Notificación gráfica ===
notify-send "⏰ Alerta Horaria" "$MENSAJE"
echo -e "$MENSAJE\n" >> "$LOG_ALERTAS"

# === Alerta hablada y Telegram cada 4 horas ===
if (( AUDIO_CONT % 4 == 0 )); then
    TEXTO="Alerta horaria. Tiempo trabajado hoy: $(format_time $DIA). Tiempo total del proyecto: $(format_time $TOTAL)."
    espeak "$TEXTO" --stdout | aplay

    curl -s -X POST https://api.telegram.org/bot$TG_TOKEN/sendMessage \
        -d chat_id="$TG_CHAT_ID" \
        -d text="$MENSAJE"
fi
