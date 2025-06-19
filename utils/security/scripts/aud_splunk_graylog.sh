#!/usr/bin/env bash
set -euo pipefail
MONGO_KEY_URL="https://www.mongodb.org/static/pgp/server-4.4.asc"
ELASTIC_KEY_URL="https://artifacts.elastic.co/GPG-KEY-elasticsearch"
GRAYLOG_DEB_URL="https://packages.graylog2.org/repo/packages/graylog-4.3-repository_latest.deb"
SPLUNK_URL="https://download.splunk.com/products/splunk/releases/8.2.5/linux/splunk-8.2.5-a7a6b77abfc0-Linux-x86_64.tgz"
apt-get update
apt-get install -y curl gnupg apt-transport-https openjdk-11-jre-headless pwgen
curl -L -o splunk.tgz "$SPLUNK_URL"
tar zxvf splunk.tgz -C /opt
ln -s /opt/splunk/bin/splunk /usr/bin/splunk
curl -fsSL "$MONGO_KEY_URL" | gpg --dearmor -o /usr/share/keyrings/mongodb-server-4.4.gpg
echo "deb [signed-by=/usr/share/keyrings/mongodb-server-4.4.gpg] https://repo.mongodb.org/apt/debian bullseye/mongodb-org/4.4 main" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list
curl -fsSL "$ELASTIC_KEY_URL" | gpg --dearmor -o /usr/share/keyrings/elasticsearch.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list
curl -L -o graylog-4.3-repository_latest.deb "$GRAYLOG_DEB_URL"
dpkg -i graylog-4.3-repository_latest.deb
apt-get update
apt-get install -y mongodb-org elasticsearch graylog-server
systemctl enable mongod
systemctl enable elasticsearch
systemctl enable graylog-server
systemctl start mongod
systemctl start elasticsearch
systemctl start graylog-server
