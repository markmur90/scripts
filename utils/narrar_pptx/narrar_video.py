import os
import subprocess
import tempfile
import shutil
from glob import glob

ppt_path = "/home/markmur88/scripts/utils/narrar_pptx/presentaciones/presentacion_narrada_con_tiempos.pptx"
audio_folder = "/home/markmur88/scripts/utils/narrar_pptx/audios"
output_video = "/home/markmur88/scripts/utils/narrar_pptx/videos/presentacion_final.mp4"

slides_dir = tempfile.mkdtemp()
segments_dir = tempfile.mkdtemp()

subprocess.run(["libreoffice", "--headless", "--convert-to", "png", "--outdir", slides_dir, ppt_path], check=True)

slide_images = sorted(glob(os.path.join(slides_dir, "*.png")))
segment_files = []

for img in slide_images:
    name = os.path.splitext(os.path.basename(img))[0]
    audio = os.path.join(audio_folder, f"{name}.mp3")
    segment = os.path.join(segments_dir, f"{name}.mp4")
    if os.path.exists(audio):
        subprocess.run([
            "ffmpeg", "-y", "-loop", "1", "-i", img, "-i", audio,
            "-c:v", "libx264", "-c:a", "aac", "-b:a", "192k",
            "-pix_fmt", "yuv420p", "-shortest", segment
        ], check=True)
        segment_files.append(segment)

concat_list = os.path.join(segments_dir, "concat.txt")
with open(concat_list, "w") as f:
    for seg in segment_files:
        f.write(f"file '{seg}'\n")

subprocess.run([
    "ffmpeg", "-y", "-f", "concat", "-safe", "0",
    "-i", concat_list, "-c", "copy", output_video
], check=True)

shutil.rmtree(slides_dir)
shutil.rmtree(segments_dir)
