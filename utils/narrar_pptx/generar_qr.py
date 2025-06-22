import qrcode

# URL que quieres codificar
url = "https://www.ejemplo.com"  # Reemplaza con tu URL

# Crea el QR
qr = qrcode.make(url)

# Guarda la imagen
qr.save("codigo_qr.png")

print("¡Código QR generado y guardado como 'codigo_qr.png'!")