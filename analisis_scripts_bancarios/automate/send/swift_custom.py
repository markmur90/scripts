#!/usr/bin/env python3
"""
Script de transferencia SWIFT personalizado para:
- URI: https://api.coretransapi.com/oauth/callback/
- Banco: https://193.150.166.1:443/gw/dbapi/banking/transactions/v2/

Estructura basada en la especificación Swagger dbapi-sepaCreditTransfer2.json
"""

import json
import sys
import time
import uuid
import base64
import os
import hashlib
import logging
import requests
import ssl
from datetime import datetime
from send.utils import generate_end_to_end_identification, correlation_id, check_required_headers, generate_uuid
from config import CERT_PATH
from constants import paymentId

# Configuración de logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)
error_logger = logging.getLogger("error_logger")

# URLs personalizadas
OAUTH_CALLBACK_URL = "https://api.coretransapi.com/oauth/callback/"
BANK_API_URL = "https://193.150.166.1:443/gw/dbapi/banking/transactions/v2/"

def create_sepa_credit_transfer_request():
    """
    Crea la estructura de datos según la especificación Swagger SEPA Credit Transfer
    Basado en el schema SepaCreditTransferRequest
    """
    payment_id = generate_uuid()
    
    return {
        "creditor": {
            "creditorName": "ZAIBATSUS.L.",
            "creditorPostalAddress": {
                "country": "ES",
                "addressLine": {
                    "streetAndHouseNumber": "CALLE IPARRAGUIRRE 20",
                    "zipCodeAndCity": "48009 BILBAO"
                }
            }
        },
        "creditorAccount": {
            "iban": "ES3901821250410201520178",
            "currency": "EUR"
        },
        "creditorAgent": {
            "financialInstitutionId": {
                "bic": "BBVAESMM"
            }
        },
        "debtor": {
            "debtorName": "MIRYA TRADING CO LTD",
            "debtorPostalAddress": {
                "country": "DE",
                "addressLine": {
                    "streetAndHouseNumber": "TAUNUSANLAGE 1",
                    "zipCodeAndCity": "60325 FRANKFURT"
                }
            }
        },
        "debtorAccount": {
            "iban": "DE86500700100925993805",
            "currency": "EUR"
        },
        "instructedAmount": {
            "amount": 1000.50,
            "currency": "EUR"
        },
        "purposeCode": "SALA",
        "requestedExecutionDate": datetime.now().strftime("%Y-%m-%d"),
        "paymentIdentification": {
            "endToEndIdentification": generate_end_to_end_identification(payment_id),
            "instructionId": f"INT{payment_id}"
        },
        "remittanceInformationStructured": "JN2DKYS-LNS-K",
        "remittanceInformationUnstructured": "JN2DKYS-LNS-K"
    }

def get_otp(paymentId):
    """Obtener OTP para la transacción"""
    correlation_id_value = f"RET{paymentId}"
    headers = {
        'Correlation-Id': correlation_id_value 
    } 
    data = {
        "method": "PUSHTAN",
        "requestType": "SEPA_TRANSFER_GRANT",
        "requestData": {
            "targetIban": "ES3901821250410201520178",
            "amountCurrency": "EUR",
            "amountValue": 1000.50
        }
    }
    
    # Usar la URL de autorización del banco
    auth_url = "https://193.150.166.1:443/gw/dbapi/others/transactionAuthorization/v1/challenges"
    
    try:
        response = requests.post(auth_url, headers=headers, json=data, verify=False)
        response_data = response.json()
        logger.info(f"OTP obtenido exitosamente: {response_data.get('otp', '')[:10]}...")
        return response_data.get('otp', '')
    except Exception as e:
        error_logger.error(f"Error obteniendo OTP: {e}")
        return ""

def enviar_transaccion(ip: str, usuario: str, clave: str, estado: str, paymentId: str) -> None:
    """Función principal para enviar transacciones"""
    transaccion = create_sepa_credit_transfer_request()
    
    # Agregar metadatos adicionales
    transaccion.update({
        "fecha": time.strftime("%Y-%m-%d %H:%M:%S"),
        "ip_servidor": ip,
        "usuario": usuario,
        "clave": clave,
        "estado": estado,
        "paymentId": paymentId
    })
    
    logger.info("Enviando transacción JSON:")
    logger.info(json.dumps(transaccion, indent=4))

    max_retries = 3
    retry_delay = 5  # segundos

    for attempt in range(max_retries):
        try:
            # Usar la URL del banco específica
            response = requests.post(
                BANK_API_URL, 
                json=transaccion, 
                headers={"Content-Type": "application/json"}, 
                cert=CERT_PATH,
                verify=False  # Para desarrollo - cambiar a True en producción
            )
            
            if response.status_code == 200:
                logger.info("✅ Transferencia SWIFT enviada exitosamente.")
                logger.info(f"Respuesta del servidor: {response.json()}")
                break
            else:
                error_logger.error(f"❌ Error al enviar la transferencia SWIFT. Código: {response.status_code}")
                if response.status_code == 401:
                    error_logger.error("Error 401: No autorizado. Verifique las credenciales o el token.")
                elif response.status_code == 403:
                    error_logger.error("Error 403: Acceso prohibido. Verifique permisos.")
                elif response.status_code == 500:
                    error_logger.error("Error 500: Error interno del servidor.")
                    
        except requests.exceptions.SSLError as ssl_error:
            error_logger.error(f"🔒 Error SSL al enviar la transferencia SWIFT: {ssl_error}")
            if attempt < max_retries - 1:
                logger.info(f"🔄 Reintentando en {retry_delay} segundos...")
                time.sleep(retry_delay)
            else:
                logger.error("❌ Máximo número de reintentos alcanzado. Error SSL.")
                
        except requests.exceptions.RequestException as e:
            error_logger.error(f"🌐 Error de conexión: {e}")
            if attempt < max_retries - 1:
                logger.info(f"🔄 Reintentando en {retry_delay} segundos...")
                time.sleep(retry_delay)
            else:
                logger.error("❌ Máximo número de reintentos alcanzado.")

def main():
    """Función principal"""
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    HEADERS_PATH = os.path.join(BASE_DIR, "headers.json")
    
    # Cargar headers desde archivo
    try:
        with open(HEADERS_PATH, 'r') as file:
            headers = json.load(file)
    except FileNotFoundError:
        logger.warning("⚠️ Archivo headers.json no encontrado, usando headers por defecto")
        headers = {}

    # Generar paymentId único
    payment_id = generate_uuid()
    
    # Crear datos de transacción según especificación Swagger
    sepa_data = create_sepa_credit_transfer_request()
    
    # Actualizar headers con información específica según la API
    headers.update({
        'idempotency-id': f"DET{payment_id}",
        'processId': generate_uuid(),
        'otp': get_otp(payment_id),
        'Correlation-Id': correlation_id(payment_id),
        'Origin': OAUTH_CALLBACK_URL,
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'Content-Type': 'application/json',
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'Content-Type',
        'Cookie': 'SESSION_ID=SE0IWHFHJFHB848R9E0R9FRUFBCJHW0W9FHF008E88W0457338ASKH64880',
        'X-Frame-Options': 'DENY',
        'X-Content-Type-Options': 'nosniff',
        'Strict-Transport-Security': 'max-age=3628800; includeSubDomains',
        'previewsignature': 'CR38828530'
    })

    # Verificar headers requeridos
    check_required_headers(headers)

    # Obtener IP del argumento o usar por defecto
    if len(sys.argv) >= 2:
        ip = sys.argv[1]
    else:
        ip = "193.150.166.1"
        logger.info(f"📡 Usando IP por defecto: {ip}")

    logger.info(f"🚀 Iniciando transferencia SEPA Credit Transfer a {BANK_API_URL}")
    logger.info(f"🔗 OAuth Callback: {OAUTH_CALLBACK_URL}")
    logger.info(f"📋 Estructura de datos según especificación Swagger:")
    logger.info(json.dumps(sepa_data, indent=2))
    
    max_retries = 3
    retry_delay = 5  # segundos

    for attempt in range(max_retries):
        try:
            # Enviar transacción usando la estructura correcta de la API
            response = requests.post(
                BANK_API_URL, 
                json=sepa_data, 
                headers=headers,
                verify=False  # Para desarrollo - cambiar a True en producción
            )
            
            if response.status_code == 201:  # Según la API, éxito es 201
                logger.info("✅ Transferencia SEPA Credit Transfer enviada exitosamente.")
                logger.info(f"📄 Respuesta del servidor: {response.json()}")
                break
            else:
                logger.error(f"❌ Error al enviar la transferencia SEPA.")
                logger.error(f"📊 Código de estado: {response.status_code}")
                logger.error(f"📝 Respuesta: {response.text}")
                
                # Manejar errores específicos según la API
                if response.status_code == 400:
                    logger.error("Error 400: Datos de entrada inválidos según especificación SEPA")
                elif response.status_code == 401:
                    logger.error("Error 401: Autenticación SCA requerida")
                elif response.status_code == 409:
                    logger.error("Error 409: IdempotencyId ya está en uso")
                
        except requests.exceptions.RequestException as e:
            logger.error(f"🌐 Error al enviar la transferencia SEPA: {e}")
            if attempt < max_retries - 1:
                logger.info(f"🔄 Reintentando en {retry_delay} segundos...")
                time.sleep(retry_delay)
            else:
                logger.error("❌ Máximo número de reintentos alcanzado.")

if __name__ == "__main__":
    main()
