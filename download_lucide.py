import os
import urllib.request
import json

icons = [
    "user", "lock", "mail", "eye", "keyboard", "mic", "trash",
    "camera", "map-pin", "clock", "star", "tag", "more-horizontal", "settings",
    "bell", "search", "chevron-right", "play", "plus", "check", "x", "message-circle"
]

assets_dir = r"C:\Users\KENEDI\Downloads\UsaBem-Swift\Assets.xcassets"

for icon in icons:
    # URL for lucide icons
    url = f"https://unpkg.com/lucide-static@0.344.0/icons/{icon}.svg"
    
    icon_dir = os.path.join(assets_dir, f"lucide_{icon}.imageset")
    os.makedirs(icon_dir, exist_ok=True)
    
    svg_path = os.path.join(icon_dir, f"{icon}.svg")
    
    try:
        urllib.request.urlretrieve(url, svg_path)
        
        # Create Contents.json
        contents = {
            "images": [
                {
                    "filename": f"{icon}.svg",
                    "idiom": "universal"
                }
            ],
            "info": {
                "author": "xcode",
                "version": 1
            },
            "properties": {
                "preserves-vector-representation": True
            }
        }
        
        with open(os.path.join(icon_dir, "Contents.json"), "w") as f:
            json.dump(contents, f, indent=2)
            
        print(f"Downloaded {icon}")
    except Exception as e:
        print(f"Failed to download {icon}: {e}")
