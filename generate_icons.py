import json
import os
from PIL import Image

with open('Assets.xcassets/AppIcon.appiconset/Contents.json', 'r') as f:
    data = json.load(f)

img = Image.open('app_icon_1024.png').convert('RGBA')
bg = Image.new('RGB', img.size, (255, 255, 255))
bg.paste(img, (0, 0), img)

for item in data['images']:
    if 'filename' in item:
        size_str = item['size']
        w, h = map(float, size_str.split('x'))
        scale = int(item['scale'].replace('x', ''))
        target_w = int(w * scale)
        target_h = int(h * scale)
        
        resized = bg.resize((target_w, target_h), Image.Resampling.LANCZOS)
        resized.save(os.path.join('Assets.xcassets/AppIcon.appiconset', item['filename']))
        print(f"Generated {item['filename']} ({target_w}x{target_h})")
