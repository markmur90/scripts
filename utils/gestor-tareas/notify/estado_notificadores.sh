#!/usr/bin/env bash
echo -e "\n📡 Estado de los notificadores:\n"

# Verificar notificador.sh
if pgrep -f "/notificador.sh" > /dev/null; then
    echo "✅ notificador.sh está corriendo."
else
    echo "❌ notificador.sh no está activo."
fi

# Verificar notificador_30.sh
if pgrep -f "/notificador2.sh" > /dev/null; then
    echo "✅ notificador2.sh está corriendo."
else
    echo "❌ notificador2.sh no está activo."
fi

# Verificar notificador_30.sh
if pgrep -f "/notificador3.sh" > /dev/null; then
    echo "✅ notificador3.sh está corriendo."
else
    echo "❌ notificador3.sh no está activo."
fi

# Verificar notificador_30.sh
if pgrep -f "/notificador_30.sh" > /dev/null; then
    echo "✅ notificador_30.sh está corriendo."
else
    echo "❌ notificador_30.sh no está activo."
fi
