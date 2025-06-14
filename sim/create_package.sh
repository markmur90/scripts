#!/bin/bash
set -e
ZIP=bank_sim_package.zip
rm -f $ZIP
zip -r $ZIP api_bank_h2 Simulador docs -x "*/__pycache__/*" "*.pyc"
echo "Paquete creado: $ZIP"