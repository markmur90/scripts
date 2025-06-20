#!/usr/bin/env bash
# =============================================================================
# MIT License
# 
# © 2025 Tu Empresa
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction...
# =============================================================================
# Nombre:        00_06_ufw.sh
# Descripción:   Aplicar reglas de firewall para DESARROLLO LOCAL
# Checksum SHA-256 (esta versión):  PLACEHOLDER_ACTUALIZAR
# Fecha:         2025-06-20
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Arrays de reglas: formato "puerto/proto:Comentario"
# -----------------------------------------------------------------------------
INBOUND_RULES=(
  "22/tcp:SSH"
  "80/tcp:HTTP"
  "443/tcp:HTTPS"
  "8000/tcp:Django"
  "5432/tcp:PostgreSQL"
  "8443/tcp:SSL certs"
  "9051/tcp:Tor CP"
  "9055/tcp:Tor SP Sim"
  "9056/tcp:Tor CP Sim"
  "9002/tcp:Sup Hd Sim"
  "9100/tcp:Sup Sim"
  "9181/tcp:Sim local"
  # extras
  "8001/tcp:Extra"  "8080/tcp:Extra"  "9001/tcp:Extra"
  "9050/tcp:Extra"  "9052/tcp:Extra"  "9053/tcp:Extra"
  "9054/tcp:Extra"  "9180/tcp:Extra"
)

OUTBOUND_RULES=(
  "53/udp:DNS"
  "123/udp:NTP"
  "443/tcp:HTTPS"
)

IPTABLES_RULES=(
  # anti-escaneo
  "-p tcp --tcp-flags ALL NONE -j DROP"
  "-p tcp ! --syn -m state --state NEW -j DROP"
  "-p tcp --tcp-flags ALL ALL -j DROP"
  "-p tcp --tcp-flags ALL FIN,URG,PSH -j DROP"
  "-p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP"
)

LOG_LEVEL="medium"

function apply_inbound() {
  echo "→ Aplicando reglas INBOUND..."
  for entry in "${INBOUND_RULES[@]}"; do
    rule="${entry%%:*}"      # e.g. "22/tcp"
    comment="${entry#*:}"    # e.g. "SSH"
    port="${rule%%/*}"       # e.g. "22"
    proto="${rule##*/}"      # e.g. "tcp"

    # Intentamos con comentario; si falla, reintentamos sin él
    sudo ufw allow in to any port "$port" proto "$proto" comment "$comment" \
      || sudo ufw allow in to any port "$port" proto "$proto"
  done
}

function apply_outbound() {
  echo "→ Aplicando reglas OUTBOUND..."
  for entry in "${OUTBOUND_RULES[@]}"; do
    rule="${entry%%:*}"      # e.g. "53/udp"
    comment="${entry#*:}"    # e.g. "DNS"
    port="${rule%%/*}"       # e.g. "53"
    proto="${rule##*/}"      # e.g. "udp"

    sudo ufw allow out to any port "$port" proto "$proto" comment "$comment" \
      || sudo ufw allow out to any port "$port" proto "$proto"
  done
}

function apply_iptables() {
  echo "→ Aplicando reglas iptables anti-escaneo..."
  for args in "${IPTABLES_RULES[@]}"; do
    sudo iptables -A INPUT $args || true
  done
}

function setup_ufw_service() {
  echo "→ Configurando ufw.service..."
  if systemctl is-enabled ufw.service &>/dev/null; then
    echo "   ufw.service ya habilitado."
  else
    echo "   Desmascarando y habilitando ufw.service..."
    sudo systemctl unmask ufw.service || true
    sudo systemctl enable ufw.service
  fi
  echo "   Reiniciando ufw.service..."
  sudo systemctl restart ufw.service
}

function main() {
  echo -e "\n🧪 Aplicando reglas de firewall para DESARROLLO LOCAL..."

  sudo ufw --force reset

  apply_inbound
  apply_outbound

  sudo ufw logging on
  sudo ufw logging "$LOG_LEVEL"
  sudo ufw default deny incoming
  sudo ufw default allow outgoing

  apply_iptables

  sudo ufw --force enable

  setup_ufw_service

  echo
  sudo ufw status verbose
  echo
  sudo ss -tulnp | grep ssh || true

  echo -e "\n✅ Reglas de firewall aplicadas para DESARROLLO LOCAL."
}

main "$@"
