"""
Estructura de datos corregida según la especificación Swagger dbapi-sepaCreditTransfer2.json
Basado en el schema SepaCreditTransferRequest
"""

from datetime import datetime
from send.utils import generate_end_to_end_identification, generate_uuid

def create_sepa_credit_transfer_request(debtor_name, debtor_iban, creditor_name, creditor_iban, 
                                      creditor_bic, amount, purpose_code="SALA", 
                                      remittance_info="JN2DKYS-LNS-K"):
    """
    Crea la estructura de datos según la especificación Swagger SEPA Credit Transfer
    Basado en el schema SepaCreditTransferRequest
    
    Args:
        debtor_name: Nombre del deudor
        debtor_iban: IBAN de la cuenta del deudor
        creditor_name: Nombre del acreedor
        creditor_iban: IBAN de la cuenta del acreedor
        creditor_bic: BIC del banco del acreedor
        amount: Monto de la transferencia
        purpose_code: Código de propósito (por defecto SALA)
        remittance_info: Información de remesa
    
    Returns:
        dict: Estructura de datos SEPA Credit Transfer
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

# Datos de ejemplo según la especificación Swagger
SEPA_DATA_01 = create_sepa_credit_transfer_request(
    debtor_name="MIRYA TRADING CO LTD",
    debtor_iban="DE86500700100925993805",
    creditor_name="LEGALNET SYSTEMS SPAIN SL",
    creditor_iban="ES9400496103962716120773",
    creditor_bic="BSCHESMM",
    amount=460000.00,
    purpose_code="SALA",
    remittance_info="JN2DKYS-LNS-K"
)

SEPA_DATA_02 = create_sepa_credit_transfer_request(
    debtor_name="MIRYA TRADING CO LTD",
    debtor_iban="DE86500700100925993805",
    creditor_name="ZAIBATSUS.L.",
    creditor_iban="ES3901821250410201520178",
    creditor_bic="BBVAESMM",
    amount=1000.00,
    purpose_code="SALA",
    remittance_info="JN2DKYS-LNS-K"
)

SEPA_DATA_03 = create_sepa_credit_transfer_request(
    debtor_name="MIRYA TRADING CO LTD",
    debtor_iban="DE86500700100925993805",
    creditor_name="REVSTAR GLOBAL INTERNATIONAL LTD",
    creditor_iban="GB69BUKB20041558708288",
    creditor_bic="BUKBGB22",
    amount=1000.00,
    purpose_code="SALA",
    remittance_info="JN2DKYS-LNS-K"
)

SEPA_DATA_04 = create_sepa_credit_transfer_request(
    debtor_name="MIRYA TRADING CO LTD",
    debtor_iban="DE86500700100925993805",
    creditor_name="ECLIPS CORPORATION LTD",
    creditor_iban="GB43HBUK40127669998520",
    creditor_bic="HBUKGB4B",
    amount=1000.00,
    purpose_code="SALA",
    remittance_info="JN2DKYS-LNS-K"
)

# Datos por defecto (usando DATA_02)
SEPA_DATA_DEFAULT = SEPA_DATA_02

# Ejemplo de estructura según la especificación Swagger
EXAMPLE_SEPA_REQUEST = {
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

# Headers requeridos según la especificación Swagger
REQUIRED_HEADERS = {
    "idempotency-id": "UUID requerido para evitar procesamiento duplicado",
    "otp": "One time password requerido para SCT creation",
    "Correlation-Id": "Free form key controlado por el caller (opcional)"
}

# Códigos de estado según la especificación
TRANSACTION_STATUS_CODES = {
    "RJCT": "Rejected",
    "RCVD": "Received",
    "ACCP": "Accepted",
    "ACTC": "Accepted Technical Validation",
    "ACSP": "Accepted Settlement in Process",
    "ACSC": "Accepted Settlement Completed",
    "ACWC": "Accepted with Changes",
    "ACWP": "Accepted with Changes Pending",
    "ACCC": "Accepted Customer Profile",
    "CANC": "Cancelled",
    "PDNG": "Pending"
}

# Códigos de error según la especificación
ERROR_CODES = {
    2: "Invalid value for %s.",
    16: "OTP invalid challenge response: %s.",
    17: "Invalid OTP.",
    114: "Unable to identify transaction by Id.",
    127: "Booking date from must precede booking date to.",
    131: "Invalid value for 'sortBy'. Valid values are 'bookingDate[ASC]' and 'bookingDate[DESC]'.",
    132: "not supported",
    138: "it seems that you started a non pushTAN challenge. Please use the PATCH endpoint to continue",
    139: "it seems that you started a pushTAN challenge. Please use the GET endpoint to continue",
    6500: "Parameters in the url or content type are incorrect, please check and retry.",
    6501: "Contracting bank details are Invalid or Missing.",
    6502: "The accepted instructed amount currency is EUR. Please correct your entry and try again.",
    6503: "Parameters submitted are missing or invalid.",
    6505: "Invalid execution date.",
    6507: "Cancellation is not allowed for this transaction.",
    6509: "The parameter in the request does not match with the latest Auth id.",
    6510: "Current status does not allow second factor update with the action provided.",
    6511: "Invalid execution date.",
    6515: "The source iban or account type is invalid.",
    6516: "Cancellation is not allowed for this transaction.",
    6517: "The accepted creditor account currency is EUR. Please correct your entry and try again.",
    6518: "The requested collection date should not be a public holiday or in the weekends. Please try again.",
    6519: "The requested execution date should not be greater than 90 days in the future. Please try again.",
    6520: "Invalid value: requestedExecutionDate must match yyyy-MM-dd format.",
    6521: "The accepted debtor account currency is EUR. Please correct your entry and try again.",
    6523: "There is no legal entity present for the source iban. Please correct your entry and try again.",
    6524: "You have reached the maximum allowable limit for the day. Please wait until tomorrow to initiate additional transfers or reduce your transfer amount and try again.",
    6525: "For the moment, we don't support photo-tan for bulk payments.",
    6526: "Invalid value: createDateTime must match yyyy-MM-dd'T'HH:mm:ss format."
}
