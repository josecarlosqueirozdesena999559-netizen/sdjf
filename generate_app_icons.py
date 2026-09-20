import os
import json
from PIL import Image

def generate_icons():
    source_image = "Assets.xcassets/logo.imageset/logo.png"
    out_dir = "Assets.xcassets/AppIcon.appiconset"
    os.makedirs(out_dir, exist_ok=True)
    
    # Open the source image
    img = Image.open(source_image)
    
    # Ensure it's square and has no transparency for App Store (though transparency is allowed on some, best practice is solid background for iOS App Icon).
    # If the logo has a transparent background, we should composite it onto a white background.
    if img.mode in ('RGBA', 'LA'):
        background = Image.new('RGB', img.size, (255, 255, 255))
        background.paste(img, mask=img.split()[3])
        img = background
    elif img.mode != 'RGB':
        img = img.convert('RGB')
        
    sizes = [
        ("20x20", 1, "ipad", "20x20"),
        ("20x20", 2, "ipad", "40x40"),
        ("20x20", 2, "iphone", "40x40"),
        ("20x20", 3, "iphone", "60x60"),
        ("29x29", 1, "ipad", "29x29"),
        ("29x29", 2, "ipad", "58x58"),
        ("29x29", 2, "iphone", "58x58"),
        ("29x29", 3, "iphone", "87x87"),
        ("40x40", 1, "ipad", "40x40"),
        ("40x40", 2, "ipad", "80x80"),
        ("40x40", 2, "iphone", "80x80"),
        ("40x40", 3, "iphone", "120x120"),
        ("60x60", 2, "iphone", "120x120"),
        ("60x60", 3, "iphone", "180x180"),
        ("76x76", 1, "ipad", "76x76"),
        ("76x76", 2, "ipad", "152x152"),
        ("83.5x83.5", 2, "ipad", "167x167"),
        ("1024x1024", 1, "ios-marketing", "1024x1024")
    ]
    
    images_json = []
    
    for size_str, scale, idiom, real_size_str in sizes:
        w, h = map(float, real_size_str.split('x'))
        resized = img.resize((int(w), int(h)), Image.Resampling.LANCZOS)
        filename = f"Icon-{idiom}-{size_str}@{scale}x.png"
        resized.save(os.path.join(out_dir, filename))
        
        images_json.append({
            "size": size_str,
            "idiom": idiom,
            "filename": filename,
            "scale": f"{scale}x"
        })
        
    contents = {
        "images": images_json,
        "info": {
            "version": 1,
            "author": "xcode"
        }
    }
    
    with open(os.path.join(out_dir, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)

if __name__ == "__main__":
    generate_icons()
