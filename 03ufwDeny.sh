#!/bin/bash
# UFW DENY

sudo ufw default allow incoming
sudo ufw default deny outgoing
sudo ufw logging full
sudo ufw enable



sudo systemctl daemon-reload






