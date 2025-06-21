import os
import subprocess
import tempfile
import shutil
from glob import glob

script_dir   = os.path.dirname(os.path.abspath(__file__))
ppt_filename = "presentacion_narrada_con_tiempos.pptx"
ppt_path     = os.path.join(script_dir, ppt_filename)
audio_folder = os.path.join(script_dir, "audios")
output_video = os.path.join(script_dir, "presentacion_final.mp4")

if not os.path.isfile(ppt_path):
    raise FileNotFoundError(f"No encuentro el PPTX en:\n  {ppt_path}")

slides_dir   = tempfile.mkdtemp()
segments_dir = tempfile.mkdtemp()

# (A) convertir PPTX → PDF
subprocess.run([
    "libreoffice", "--headless", "--convert-to", "pdf",
    "--outdir", slides_dir, ppt_path
], check=True)

pdf_path = os.path.join(slides_dir, os.path.splitext(ppt_filename)[0] + ".pdf")

# (B) convertir PDF → PNG
subprocess.run([
    "convert", "-density", "150",
    pdf_path,
    os.path.join(slides_dir, "slide_%03d.png")
], check=True)

slide_images = sorted(glob(os.path.join(slides_dir, "slide_*.png")))
audio_files  = sorted(glob(os.path.join(audio_folder, "*.mp3")))

print("Imágenes generadas:")
for img in slide_images:
    print(" ", os.path.basename(img))
print("Audios disponibles:")
for aud in audio_files:
    print(" ", os.path.basename(aud))

count = min(len(slide_images), len(audio_files))
if count == 0:
    shutil.rmtree(slides_dir)
    shutil.rmtree(segments_dir)
    raise RuntimeError("No hay imágenes o no hay audios. Revisa ./audios y que el PPTX exista.")

segment_files = []
for i in range(count):
    img = slide_images[i]
    aud = audio_files[i]
    seg = os.path.join(segments_dir, f"segment{i+1:03d}.mp4")
    subprocess.run([
        "ffmpeg", "-y",
        "-loop", "1", "-i", img, "-i", aud,
        "-c:v", "libx264", "-c:a", "aac", "-b:a", "192k",
        "-pix_fmt", "yuv420p", "-shortest", seg
    ], check=True)
    segment_files.append(seg)

concat_txt = os.path.join(segments_dir, "concat.txt")
with open(concat_txt, "w") as f:
    for seg in segment_files:
        f.write(f"file '{seg}'\n")

subprocess.run([
    "ffmpeg", "-y", "-f", "concat", "-safe", "0",
    "-i", concat_txt, "-c", "copy", output_video
], check=True)

shutil.rmtree(slides_dir)
shutil.rmtree(segments_dir)

print(f"Vídeo final generado en:\n  {output_video}")
