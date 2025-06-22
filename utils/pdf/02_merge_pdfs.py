# merge_pdfs.py
import os
from PyPDF2 import PdfMerger

# Directorio con los PDFs
pdf_dir = "pdfs"
# Archivo de salida
output_file = "libro.pdf"

# Listar PDFs
pdf_files = [f for f in os.listdir(pdf_dir) if f.endswith(".pdf")]
pdf_files.sort()  # Orden alfabético por defecto

# Mostrar opciones al usuario
print("PDFs disponibles:")
for i, pdf in enumerate(pdf_files):
    print(f"{i}: {pdf}")

# Pedir orden deseado
order_input = input("Ingresa los índices en orden (ej: 0 2 1): ")
order = list(map(int, order_input.split()))

# Validar índices
try:
    ordered_pdfs = [os.path.join(pdf_dir, pdf_files[i]) for i in order]
except IndexError:
    print("⚠️ Índice inválido. Usa solo números mostrados.")
    exit()

# Unir PDFs
merger = PdfMerger()
for pdf in ordered_pdfs:
    merger.append(pdf)

merger.write(output_file)
merger.close()

print(f"PDF final guardado como: {output_file}")