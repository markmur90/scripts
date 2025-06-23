# gif_loop.py
import scenedetect
from scenedetect import VideoManager, SceneManager
from scenedetect.detectors import ContentDetector
from moviepy.editor import VideoFileClip, concatenate_videoclips

gif1_path = "input1.gif"
gif2_path = "input2.gif"
gif2_path = "input2.gif"
gif2_path = "input2.gif"
output_gif_path = "output_loop.gif"

video_manager = VideoManager([gif1_path])
scene_manager = SceneManager()
scene_manager.add_detector(ContentDetector())
video_manager.start()
scene_manager.detect_scenes(frame_source=video_manager)
scene_list1 = scene_manager.get_scene_list()
video_manager.release()

video_manager = VideoManager([gif2_path])
scene_manager = SceneManager()
scene_manager.add_detector(ContentDetector())
video_manager.start()
scene_manager.detect_scenes(frame_source=video_manager)
scene_list2 = scene_manager.get_scene_list()
video_manager.release()

last_end = scene_list1[-1][1].get_seconds()
first_start = scene_list2[0][0].get_seconds()

clip1 = VideoFileClip(gif1_path).subclip(0, last_end)
clip2 = VideoFileClip(gif2_path).subclip(first_start)
final_clip = concatenate_videoclips([clip1, clip2], method="compose")
final_clip.write_gif(output_gif_path, fps=15)
