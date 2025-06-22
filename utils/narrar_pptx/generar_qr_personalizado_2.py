import qrcode
from qrcode.constants import ERROR_CORRECT_L
from PIL import Image, ImageDraw

# URL que quieres codificar
url = "https://docs.google.com/forms/d/e/1FAIpQLSe5rPtHfI3TLqdauEBQQ-ddk9K-DYOXjO2qkR_ISxQZ12uUqQ/viewform?usp=header"  # Reemplaza con tu URL

# Configura parámetros personalizados
qr = qrcode.QRCode(
    version=5,  # Aumenta el tamaño del QR para que el logo quede proporcional
    error_correction=ERROR_CORRECT_L,  # Nivel de corrección de errores
    box_size=10,  # Tamaño de cada "caja" en píxeles
    border=4,  # Margen en módulos
)

# Añade la URL
qr.add_data(url)
qr.make(fit=True)

# Genera la imagen del QR
qr_img = qr.make_image(fill_color="black", back_color="white").convert("RGBA")

# Abre el logo que deseas agregar
logo_path = "/home/markmur88/scripts/utils/narrar_pptx/logo_fermar.png"  # Reemplaza con la ruta a tu logo
logo = Image.open(logo_path)

# Redimensiona el logo para que quede bien en el centro
# Ajusta el tamaño del logo según tus necesidades
logo_size = (qr_img.size[0] // 5, qr_img.size[0] // 5)  # Cambia el divisor para ajustar el tamaño
logo = logo.resize(logo_size, Image.LANCZOS)

# Calcula la posición para centrar el logo
position = ((qr_img.size[0] - logo.size[0]) // 2, (qr_img.size[1] - logo.size[1]) // 2)

# Pega el logo en el centro del QR
qr_img.paste(logo, position, logo)

# Guarda la imagen final
qr_img.save("codigo_qr_con_logo.png")

print("¡Código QR con logo generado y guardado como 'codigo_qr_con_logo.png'!")