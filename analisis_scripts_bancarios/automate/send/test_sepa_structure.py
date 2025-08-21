#!/usr/bin/env python3
"""
Script de prueba para verificar que la estructura de datos SEPA Credit Transfer
cumple con la especificación Swagger dbapi-sepaCreditTransfer2.json
"""

import json
import uuid
from datetime import datetime

def generate_uuid():
    """Genera un UUID único"""
    return str(uuid.uuid4())

def generate_end_to_end_identification(payment_id):
    """Genera un identificador end-to-end"""
    return f"E2E{payment_id[:8]}"

def create_sepa_credit_transfer_request(debtor_name, debtor_iban, creditor_name, creditor_iban, 
                                      creditor_bic, amount, purpose_code="SALA", 
                                      remittance_info="JN2DKYS-LNS-K"):
    """
    Crea la estructura de datos según la especificación Swagger SEPA Credit Transfer
    Basado en el schema SepaCreditTransferRequest
    """
    payment_id = generate_uuid()
    
    return {
        "creditor": {
            "creditorName": creditor_name,
            "creditorPostalAddress": {
                "country": "ES",
                "addressLine": {
                    "streetAndHouseNumber": "CALLE IPARRAGUIRRE 20",
                    "zipCodeAndCity": "48009 BILBAO"
                }
            }
        },
        "creditorAccount": {
            "iban": creditor_iban,
            "currency": "EUR"
        },
        "creditorAgent": {
            "financialInstitutionId": {
                "bic": creditor_bic
            }
        },
        "debtor": {
            "debtorName": debtor_name,
            "debtorPostalAddress": {
                "country": "DE",
                "addressLine": {
                    "streetAndHouseNumber": "TAUNUSANLAGE 1",
                    "zipCodeAndCity": "60325 FRANKFURT"
                }
            }
        },
        "debtorAccount": {
            "iban": debtor_iban,
            "currency": "EUR"
        },
        "instructedAmount": {
            "amount": float(amount),
            "currency": "EUR"
        },
        "purposeCode": purpose_code,
        "requestedExecutionDate": datetime.now().strftime("%Y-%m-%d"),
        "paymentIdentification": {
            "endToEndIdentification": generate_end_to_end_identification(payment_id),
            "instructionId": f"INT{payment_id}"
        },
        "remittanceInformationStructured": remittance_info,
        "remittanceInformationUnstructured": remittance_info
    }

def validate_sepa_structure(data):
    """
    Valida que la estructura de datos cumple con los requisitos de la API SEPA
    """
    required_fields = [
        "creditor",
        "creditorAccount", 
        "creditorAgent",
        "debtor",
        "debtorAccount",
        "instructedAmount"
    ]
    
    print("🔍 Validando estructura SEPA Credit Transfer...")
    
    # Verificar campos requeridos
    for field in required_fields:
        if field not in data:
            print(f"❌ Campo requerido faltante: {field}")
            return False
        else:
            print(f"✅ Campo presente: {field}")
    
    # Verificar estructura del creditor
    if "creditorName" not in data["creditor"]:
        print("❌ creditorName faltante en creditor")
        return False
    
    if "creditorPostalAddress" not in data["creditor"]:
        print("❌ creditorPostalAddress faltante en creditor")
        return False
    
    # Verificar estructura del creditorAccount
    if "iban" not in data["creditorAccount"]:
        print("❌ iban faltante en creditorAccount")
        return False
    
    if "currency" not in data["creditorAccount"]:
        print("❌ currency faltante en creditorAccount")
        return False
    
    # Verificar estructura del creditorAgent
    if "financialInstitutionId" not in data["creditorAgent"]:
        print("❌ financialInstitutionId faltante en creditorAgent")
        return False
    
    # Verificar estructura del debtor
    if "debtorName" not in data["debtor"]:
        print("❌ debtorName faltante en debtor")
        return False
    
    if "debtorPostalAddress" not in data["debtor"]:
        print("❌ debtorPostalAddress faltante en debtor")
        return False
    
    # Verificar estructura del debtorAccount
    if "iban" not in data["debtorAccount"]:
        print("❌ iban faltante en debtorAccount")
        return False
    
    if "currency" not in data["debtorAccount"]:
        print("❌ currency faltante en debtorAccount")
        return False
    
    # Verificar estructura del instructedAmount
    if "amount" not in data["instructedAmount"]:
        print("❌ amount faltante en instructedAmount")
        return False
    
    if "currency" not in data["instructedAmount"]:
        print("❌ currency faltante en instructedAmount")
        return False
    
    print("✅ Estructura válida según especificación Swagger")
    return True

def test_sepa_data_creation():
    """
    Prueba la creación de datos SEPA
    """
    print("\n🧪 Probando creación de datos SEPA...")
    
    # Crear datos de prueba
    test_data = create_sepa_credit_transfer_request(
        debtor_name="TEST DEBTOR",
        debtor_iban="DE89370400440532013001",
        creditor_name="TEST CREDITOR",
        creditor_iban="DE89370400440532013000",
        creditor_bic="DEUTDEFF",
        amount=100.50
    )
    
    print("📋 Datos de prueba creados:")
    print(json.dumps(test_data, indent=2))
    
    # Validar estructura
    is_valid = validate_sepa_structure(test_data)
    
    if is_valid:
        print("✅ Datos de prueba válidos")
    else:
        print("❌ Datos de prueba inválidos")
    
    return is_valid

def test_predefined_data():
    """
    Prueba los datos predefinidos
    """
    print("\n📊 Probando datos predefinidos...")
    
    # Crear datos predefinidos
    sepa_data_01 = create_sepa_credit_transfer_request(
        debtor_name="MIRYA TRADING CO LTD",
        debtor_iban="DE86500700100925993805",
        creditor_name="LEGALNET SYSTEMS SPAIN SL",
        creditor_iban="ES9400496103962716120773",
        creditor_bic="BSCHESMM",
        amount=460000.00
    )
    
    sepa_data_02 = create_sepa_credit_transfer_request(
        debtor_name="MIRYA TRADING CO LTD",
        debtor_iban="DE86500700100925993805",
        creditor_name="ZAIBATSUS.L.",
        creditor_iban="ES3901821250410201520178",
        creditor_bic="BBVAESMM",
        amount=1000.00
    )
    
    datasets = [
        ("SEPA_DATA_01", sepa_data_01),
        ("SEPA_DATA_02", sepa_data_02)
    ]
    
    for name, data in datasets:
        print(f"\n🔍 Validando {name}:")
        is_valid = validate_sepa_structure(data)
        if is_valid:
            print(f"✅ {name} es válido")
        else:
            print(f"❌ {name} es inválido")

def compare_with_swagger_example():
    """
    Compara nuestra estructura con el ejemplo de la especificación Swagger
    """
    print("\n📚 Comparando con ejemplo de Swagger...")
    
    # Ejemplo de la especificación Swagger
    swagger_example = {
        "creditor": {
            "creditorName": "John Doe",
            "creditorPostalAddress": {
                "country": "DE",
                "addressLine": {
                    "streetAndHouseNumber": "Main Street 123",
                    "zipCodeAndCity": "12345 Berlin"
                }
            }
        },
        "creditorAccount": {
            "iban": "DE89370400440532013000",
            "currency": "EUR"
        },
        "creditorAgent": {
            "financialInstitutionId": {
                "bic": "DEUTDEFF"
            }
        },
        "debtor": {
            "debtorName": "Jane Smith",
            "debtorPostalAddress": {
                "country": "DE",
                "addressLine": {
                    "streetAndHouseNumber": "Second Street 456",
                    "zipCodeAndCity": "67890 Munich"
                }
            }
        },
        "debtorAccount": {
            "iban": "DE89370400440532013001",
            "currency": "EUR"
        },
        "instructedAmount": {
            "amount": 100.50,
            "currency": "EUR"
        },
        "purposeCode": "SALA",
        "requestedExecutionDate": "2023-12-01"
    }
    
    print("📋 Ejemplo de Swagger:")
    print(json.dumps(swagger_example, indent=2))
    
    print("\n🔍 Validando ejemplo de Swagger:")
    is_valid = validate_sepa_structure(swagger_example)
    
    if is_valid:
        print("✅ Ejemplo de Swagger es válido")
    else:
        print("❌ Ejemplo de Swagger es inválido")

def main():
    """
    Función principal de pruebas
    """
    print("🚀 Iniciando pruebas de estructura SEPA Credit Transfer")
    print("=" * 60)
    
    # Probar creación de datos
    test_sepa_data_creation()
    
    # Probar datos predefinidos
    test_predefined_data()
    
    # Comparar con ejemplo de Swagger
    compare_with_swagger_example()
    
    print("\n" + "=" * 60)
    print("✅ Pruebas completadas")

if __name__ == "__main__":
    main()
