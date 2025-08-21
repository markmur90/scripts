#!/usr/bin/env bash

set -euo pipefail

# Cargar aliases del usuario (incluye envSIM)
if [ -f "$HOME/.zshrc" ]; then
    # shellcheck disable=SC1090
    source "$HOME/.zshrc"
fi

# Activar entorno Python si existe alias envSIM
if alias envSIM &>/dev/null; then
    envSIM || true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Iniciando servidor del dashboard..."
python3 "$SCRIPT_DIR/server.py"


