# image_to_pdf.py
import os
from PIL import Image

# Directorio con las imágenes
image_dir = "imagenes"
# Directorio de salida para los PDFs
output_dir = "pdfs"

os.makedirs(output_dir, exist_ok=True)

# Procesar cada imagen en el directorio
for filename in os.listdir(image_dir):
    if filename.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.gif')):
        try:
            img_path = os.path.join(image_dir, filename)
            pdf_path = os.path.join(output_dir, os.path.splitext(filename)[0] + ".pdf")
            img = Image.open(img_path)
            if img.mode != "RGB":
                img = img.convert("RGB")
            img.save(pdf_path, "PDF", resolution=100.0)
            print(f"✅ {filename} → {pdf_path}")
        except Exception as e:
            print(f"❌ Error con {filename}: {e}")

print("Todas las imágenes convertidas a PDF.")