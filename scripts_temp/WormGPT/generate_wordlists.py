#!/usr/bin/env python3
"""
Generador de listas de usuarios y contraseñas para ataques de fuerza bruta
"""

import argparse
import random
import string
from faker import Faker
from datetime import datetime

fake = Faker()

def generate_users(num_users=100, include_common=True):
    """Generar lista de usuarios"""
    users = []
    
    # Usuarios comunes
    if include_common:
        common_users = [
            "root", "admin", "administrator", "user", "guest", "test", "demo",
            "ubuntu", "debian", "centos", "fedora", "pi", "raspberry",
            "operator", "service", "web", "www", "ftp", "mail", "dns",
            "backup", "monitor", "support", "helpdesk", "info", "contact"
        ]
        users.extend(common_users)
    
    # Generar usuarios aleatorios
    for i in range(num_users):
        # Usuarios con nombres reales
        users.append(fake.user_name())
        
        # Usuarios con patrones comunes
        users.append(f"user{i+1}")
        users.append(f"admin{i+1}")
        users.append(f"test{i+1}")
        
        # Usuarios con nombres de empresa
        company = fake.company().split()[0].lower()
        users.append(company)
        users.append(f"{company}admin")
        users.append(f"{company}user")
        
        # Usuarios con años
        year = random.randint(2020, 2025)
        users.append(f"admin{year}")
        users.append(f"user{year}")
    
    return list(set(users))  # Eliminar duplicados

def generate_passwords(num_passwords=1000, include_common=True, patterns=True):
    """Generar lista de contraseñas"""
    passwords = []
    
    # Contraseñas comunes
    if include_common:
        common_passwords = [
            "password", "123456", "admin123", "qwerty", "toor", "letmein",
            "admin", "root", "123456789", "password123", "admin1234",
            "12345678", "qwerty123", "123123", "1234567", "1234567890",
            "welcome", "login", "abc123", "111111", "dragon", "master",
            "monkey", "letmein", "shadow", "ashley", "freedom", "whatever",
            "qazwsx", "trustno1", "jordan", "harley", "hunter", "buster",
            "soccer", "tiger", "charlie", "thomas", "ranger", "daniel",
            "andrew", "lakers", "joshua", "maggie", "summer", "heather",
            "hammer", "silver", "anthony", "justin", "tiger", "zapper",
            "cowboy", "charles", "ginger", "hammer", "silver", "anthony"
        ]
        passwords.extend(common_passwords)
    
    # Generar contraseñas aleatorias
    for i in range(num_passwords):
        # Contraseñas aleatorias simples
        passwords.append(fake.password(length=random.randint(6, 12)))
        
        # Contraseñas con patrones
        if patterns:
            # Usuario + números
            passwords.append(f"{fake.user_name()}{random.randint(1, 999)}")
            
            # Empresa + año
            company = fake.company().replace(' ', '').replace(',', '').replace('.', '')
            passwords.append(f"{company}{random.randint(2020, 2025)}")
            
            # Patrones comunes
            passwords.append(f"password{random.randint(1, 999)}")
            passwords.append(f"admin{random.randint(1, 999)}")
            passwords.append(f"user{random.randint(1, 999)}")
            passwords.append(f"test{random.randint(1, 999)}")
            
            # Años
            year = random.randint(2020, 2025)
            passwords.append(f"password{year}")
            passwords.append(f"admin{year}")
            passwords.append(f"user{year}")
            
            # Combinaciones de teclado
            keyboard_patterns = [
                "qwerty", "asdfgh", "zxcvbn", "123456", "654321",
                "qazwsx", "edcrfv", "tgbyhn", "ujmikl", "poiuyt"
            ]
            passwords.append(random.choice(keyboard_patterns))
            
            # Contraseñas con caracteres especiales
            special_chars = "!@#$%^&*()_+-=[]{}|;:,.<>?"
            passwords.append(f"password{random.choice(special_chars)}{random.randint(1, 99)}")
            passwords.append(f"admin{random.choice(special_chars)}{random.randint(1, 99)}")
    
    return list(set(passwords))  # Eliminar duplicados

def generate_company_specific(company_name, num_variations=50):
    """Generar usuarios y contraseñas específicos de una empresa"""
    users = []
    passwords = []
    
    company_clean = company_name.lower().replace(' ', '').replace(',', '').replace('.', '')
    
    # Usuarios específicos de la empresa
    for i in range(num_variations):
        users.extend([
            company_clean,
            f"{company_clean}admin",
            f"{company_clean}user",
            f"{company_clean}{i+1}",
            f"admin@{company_clean}.com",
            f"user@{company_clean}.com",
            f"admin{company_clean}",
            f"user{company_clean}"
        ])
        
        passwords.extend([
            company_clean,
            f"{company_clean}123",
            f"{company_clean}2024",
            f"{company_clean}2025",
            f"password{company_clean}",
            f"admin{company_clean}",
            f"{company_clean}admin",
            f"{company_clean}user"
        ])
    
    return list(set(users)), list(set(passwords))

def save_wordlist(data, filename):
    """Guardar lista en archivo"""
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            for item in data:
                f.write(f"{item}\n")
        print(f"✓ Lista guardada en: {filename} ({len(data)} elementos)")
        return True
    except Exception as e:
        print(f"✗ Error guardando {filename}: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(
        description="Generador de listas de usuarios y contraseñas",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos de uso:
  %(prog)s --users 100 --passwords 1000
  %(prog)s --company "Mi Empresa" --output-prefix empresa
  %(prog)s --users 50 --passwords 500 --no-common
  %(prog)s --generate-all --output-dir wordlists/
        """
    )
    
    parser.add_argument("--users", type=int, default=100, 
                       help="Número de usuarios a generar (default: 100)")
    parser.add_argument("--passwords", type=int, default=1000, 
                       help="Número de contraseñas a generar (default: 1000)")
    parser.add_argument("--company", type=str, 
                       help="Nombre de empresa para generar listas específicas")
    parser.add_argument("--output-prefix", type=str, default="wordlist",
                       help="Prefijo para archivos de salida (default: wordlist)")
    parser.add_argument("--output-dir", type=str, default=".",
                       help="Directorio de salida (default: actual)")
    parser.add_argument("--no-common", action="store_true",
                       help="No incluir usuarios/contraseñas comunes")
    parser.add_argument("--no-patterns", action="store_true",
                       help="No incluir patrones de contraseñas")
    parser.add_argument("--generate-all", action="store_true",
                       help="Generar todas las listas con diferentes configuraciones")
    
    args = parser.parse_args()
    
    print("🔧 Generador de listas de usuarios y contraseñas")
    print("=" * 50)
    
    if args.generate_all:
        # Generar múltiples listas con diferentes configuraciones
        configs = [
            ("pequeña", 50, 500),
            ("media", 100, 1000),
            ("grande", 200, 2000),
            ("enorme", 500, 5000)
        ]
        
        for name, users, passwords in configs:
            print(f"\n📝 Generando lista {name}...")
            
            user_list = generate_users(users, not args.no_common)
            pass_list = generate_passwords(passwords, not args.no_common, not args.no_patterns)
            
            save_wordlist(user_list, f"{args.output_dir}/{args.output_prefix}_users_{name}.txt")
            save_wordlist(pass_list, f"{args.output_dir}/{args.output_prefix}_passwords_{name}.txt")
    
    elif args.company:
        # Generar listas específicas de empresa
        print(f"🏢 Generando listas específicas para: {args.company}")
        
        user_list, pass_list = generate_company_specific(args.company)
        
        save_wordlist(user_list, f"{args.output_dir}/{args.output_prefix}_users_company.txt")
        save_wordlist(pass_list, f"{args.output_dir}/{args.output_prefix}_passwords_company.txt")
    
    else:
        # Generar listas estándar
        print(f"📝 Generando {args.users} usuarios y {args.passwords} contraseñas...")
        
        user_list = generate_users(args.users, not args.no_common)
        pass_list = generate_passwords(args.passwords, not args.no_common, not args.no_patterns)
        
        save_wordlist(user_list, f"{args.output_dir}/{args.output_prefix}_users.txt")
        save_wordlist(pass_list, f"{args.output_dir}/{args.output_prefix}_passwords.txt")
    
    print(f"\n✅ Generación completada!")
    print(f"📁 Archivos guardados en: {args.output_dir}")

if __name__ == "__main__":
    main()
