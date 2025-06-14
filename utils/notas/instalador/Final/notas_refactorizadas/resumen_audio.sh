#!/bin/bash
echo "🔊 Generando resumen por voz"
ULTIMO_RESUMEN=$(find "/home/markmur88/notas/texto" -type f -printf "%T@ %p\n" | sort -n | tail -1 | cut -d' ' -f2-)
RESUMEN=$(cat "$ULTIMO_RESUMEN" 2>/dev/null)
[ -z "$RESUMEN" ] && RESUMEN="No hay notas recientes."
espeak "Resumen de tus notas: $RESUMEN"
