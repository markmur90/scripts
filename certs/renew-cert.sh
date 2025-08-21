#!/bin/bash
export NJALLA_TOKEN="384c973798f4c24a69d165cec329382af68123d7"
lego --email="netghostx90@protonmail.com" \
     --dns="njalla" \
     --domains="*.coretransapi.com" \
     --accept-tos \
     renew --days 30
