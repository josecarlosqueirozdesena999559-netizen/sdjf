import json
import os
from PIL import Image

with open('Assets.xcassets/AppIcon.appiconset/Contents.json', 'r') as f:
    data = json.load(f)

img = Image.open('Assets.xcassets/splash_bg.imageset/splash_bg.png').convert('RGBA')

w, h = img.size
if w != h:
    size = min(w, h)
    left = (w - size)/2
    top = (h - size)/2
    right = (w + size)/2
    bottom = (h + size)/2
    img = img.crop((left, top, right, bottom))

bg = Image.new('RGB', img.size, (255, 255, 255))
bg.paste(img, (0, 0), img)

for item in data['images']:
    if 'filename' in item:
        size_str = item['size']
        w_s, h_s = map(float, size_str.split('x'))
        scale = int(item['scale'].replace('x', ''))
        target_w = int(w_s * scale)
        target_h = int(h_s * scale)
        
        resized = bg.resize((target_w, target_h), Image.Resampling.LANCZOS)
        resized.save(os.path.join('Assets.xcassets/AppIcon.appiconset', item['filename']))
