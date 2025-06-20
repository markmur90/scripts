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
    raise FileNotFoundError(f"No se encuentra el PPTX en:\n  {ppt_path}")

slides_dir   = tempfile.mkdtemp()
segments_dir = tempfile.mkdtemp()

try:
    subprocess.run(
        ["libreoffice", "--headless", "--convert-to", "png", "--outdir", slides_dir, ppt_path],
        check=True
    )
except subprocess.CalledProcessError:
    shutil.rmtree(slides_dir)
    shutil.rmtree(segments_dir)
    raise RuntimeError(f"LibreOffice no pudo procesar:\n  {ppt_path}")

slide_images = sorted(glob(os.path.join(slides_dir, "*.png")))
audio_files  = sorted(glob(os.path.join(audio_folder, "*.mp3")))

print("Imágenes encontradas:")
for img in slide_images:
    print(" ", os.path.basename(img))
print("Audios encontrados:")
for aud in audio_files:
    print(" ", os.path.basename(aud))

count = min(len(slide_images), len(audio_files))
if count == 0:
    shutil.rmtree(slides_dir)
    shutil.rmtree(segments_dir)
    raise RuntimeError("No hay imágenes o no hay audios. Revisa que:\n"
                       f"  • {ppt_filename} existe y LibreOffice lo convierte.\n"
                       f"  • ./audios/ contiene tus *.mp3.")

segment_files = []
for i in range(count):
    img = slide_images[i]
    aud = audio_files[i]
    seg = os.path.join(segments_dir, f"segment{i+1}.mp4")
    subprocess.run([
        "ffmpeg", "-y",
        "-loop", "1", "-i", img,
        "-i", aud,
        "-c:v", "libx264", "-c:a", "aac", "-b:a", "192k",
        "-pix_fmt", "yuv420p",
        "-shortest", seg
    ], check=True)
    segment_files.append(seg)

concat_txt = os.path.join(segments_dir, "concat.txt")
with open(concat_txt, "w") as f:
    for seg in segment_files:
        f.write(f"file '{seg}'\n")

subprocess.run([
    "ffmpeg", "-y",
    "-f", "concat", "-safe", "0",
    "-i", concat_txt,
    "-c", "copy", output_video
], check=True)

shutil.rmtree(slides_dir)
shutil.rmtree(segments_dir)
print(f"Vídeo generado en:\n  {output_video}")
