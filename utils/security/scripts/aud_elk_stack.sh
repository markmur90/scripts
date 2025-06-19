#!/bin/bash

# ELK STACK
sudo apt update
sudo apt install -y openjdk-11-jre-headless apt-transport-https ca-certificates curl
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update
sudo apt install -y elasticsearch logstash kibana
sudo systemctl enable --now elasticsearch
sudo systemctl enable --now logstash
sudo systemctl enable --now kibana