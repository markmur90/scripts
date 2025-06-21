import os
import subprocess
import tempfile
import shutil
from glob import glob

base = os.path.expanduser("/home/markmur88/scripts/utils/narrar_pptx")
presentaciones_dir = os.path.join(base, "presentaciones")
audios_dir         = os.path.join(base, "audios")
img_dir            = os.path.join(base, "img")
videos_dir         = os.path.join(base, "videos")

os.makedirs(img_dir,    exist_ok=True)
os.makedirs(videos_dir, exist_ok=True)

ppt_filename = "presentacion_narrada_con_tiempos.pptx"
ppt_path     = os.path.join(presentaciones_dir, ppt_filename)
if not os.path.isfile(ppt_path):
    raise FileNotFoundError(f"No se encuentra PPTX en: {ppt_path}")

subprocess.run([
    "lowriter", "--headless",
    "--convert-to", "pdf:writer_pdf_Export",
    "--outdir", presentaciones_dir, ppt_path
], check=True)

pdf_path = os.path.join(presentaciones_dir, os.path.splitext(ppt_filename)[0] + ".pdf")
if not os.path.isfile(pdf_path):
    raise RuntimeError(f"No se generó PDF en: {pdf_path}")

subprocess.run([
    "convert", "-density", "150",
    pdf_path,
    os.path.join(img_dir, "slide_%03d.png")
], check=True)

slide_images = sorted(glob(os.path.join(img_dir, "slide_*.png")))
audio_files  = sorted(glob(os.path.join(audios_dir, "*.mp3")))

count = min(len(slide_images), len(audio_files))
if count == 0:
    raise RuntimeError("No hay imágenes o no hay audios. Revisa ./img y ./audios")

segments_dir = tempfile.mkdtemp()
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

output_video = os.path.join(videos_dir, "presentacion_final.mp4")
subprocess.run([
    "ffmpeg", "-y", "-f", "concat", "-safe", "0",
    "-i", concat_txt, "-c", "copy", output_video
], check=True)

shutil.rmtree(segments_dir)
print(f"Vídeo generado en:\n  {output_video}")
