#!/usr/bin/env bash
set -euo pipefail
SPLUNK_URL="https://download.splunk.com/products/splunk/releases/8.2.5/linux/splunk-8.2.5-a7a6b77abfc0-Linux-x86_64.tgz"
apt-get update
apt-get install -y curl gnupg
curl -L -o splunk.tgz "$SPLUNK_URL"
tar zxvf splunk.tgz -C /opt
ln -s /opt/splunk/bin/splunk /usr/bin/splunk
