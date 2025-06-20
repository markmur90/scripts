#!/usr/bin/env bash
# === FIREWALL PARA DESARROLLO LOCAL ===

set -euo pipefail

echo -e "\n🧪 Aplicando reglas de firewall para DESARROLLO LOCAL..."

# Reset UFW
sudo ufw --force reset

# Reglas mínimas necesarias para desarrollo
sudo ufw allow 22/tcp   comment "SSH"
sudo ufw allow 80/tcp   comment "HTTP"
sudo ufw allow 443/tcp  comment "HTTPS"
sudo ufw allow 8000/tcp comment "Django"
sudo ufw allow 5432/tcp comment "PostgreSQL"           # PostgreSQL local
sudo ufw allow 8443/tcp comment "SSL certs"           # PostgreSQL local

sudo ufw allow 9051/tcp comment "Tor CP"
sudo ufw allow 9181/tcp comment "Sim local"
sudo ufw allow 9055/tcp comment "Tor SP Sim"
sudo ufw allow 9056/tcp comment "Tor CP Sim"
sudo ufw allow 9002/tcp comment "Sup Hd Sim"
sudo ufw allow 9100/tcp comment "Sup Sim"

sudo ufw allow 8001/tcp comment "Extra"
sudo ufw allow 8080/tcp comment "Extra"
sudo ufw allow 8443/tcp comment "Extra"
sudo ufw allow 9001/tcp comment "Extra"
sudo ufw allow 9002/tcp comment "Extra"
sudo ufw allow 8001/tcp comment "Extra"
sudo ufw allow 9050/tcp comment "Extra"
sudo ufw allow 9052/tcp comment "Extra"
sudo ufw allow 9053/tcp comment "Extra"
sudo ufw allow 9054/tcp comment "Extra"
sudo ufw allow 9055/tcp comment "Extra"
sudo ufw allow 9056/tcp comment "Extra"
sudo ufw allow 9180/tcp comment "Extra"

# sudo ufw allow 9200/tcp comment "Graylog"
# sudo ufw allow 9200/tcp comment "Graylog"
# sudo ufw allow 9200/tcp comment "Graylog"
# sudo ufw allow 9200/tcp comment "Graylog"
# sudo ufw allow 9200/tcp comment "Graylog"
# sudo ufw allow 27017/tcp comment "Graylog"

# Salidas necesarias
sudo ufw allow out 53              # DNS
sudo ufw allow out 123/udp         # NTP
sudo ufw allow out to any port 443 proto tcp

# Logging
sudo ufw logging on
sudo ufw logging medium

# Reglas iptables anti-escaneo
sudo iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
sudo iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

# Políticas por defecto
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Activar UFW
sudo ufw --force enable
sudo systemctl enable ufw
sudo systemctl start ufw

sudo ufw status verbose
sudo ss -tulnp | grep ssh

echo -e "\n✅ Reglas de firewall aplicadas para DESARROLLO LOCAL."
