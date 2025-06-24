import hashlib
import base64

def tor_hash(password):
    salt = hashlib.sha1().digest()
    iterations = 16
    hash = hashlib.pbkdf2_hmac('sha1', password.encode(), salt, iterations, dklen=20)
    return "16:" + base64.b16encode(hash).decode()

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) != 2:
        print("Uso: python tor_hash.py <tu_contraseña>")
        sys.exit(1)

    print(tor_hash(sys.argv[1]))