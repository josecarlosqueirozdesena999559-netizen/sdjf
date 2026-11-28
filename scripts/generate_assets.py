import json
import math
import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
ICONS_DIR = ROOT / "assets" / "icons"
XCASSETS_DIR = ROOT / "Resources" / "Assets.xcassets"

EMERALD = (16, 185, 129, 255)      # #10B981
EMERALD_DARK = (5, 150, 105, 255)  # #059669
EMERALD_LIGHT = (167, 243, 208, 255)
GOLD = (255, 183, 3, 255)          # #FFB703
GOLD_DARK = (217, 119, 6, 255)
GOLD_LIGHT = (254, 240, 138, 255)
DARK = (15, 23, 42, 255)           # #0F172A
SLATE = (71, 85, 105, 255)
WHITE = (255, 255, 255, 255)
GRAY_BG = (248, 250, 252, 255)


def new_canvas(size=256):
    return Image.new("RGBA", (size, size), (0, 0, 0, 0))


def add_soft_shadow(img, offset=(0, 8), radius=10, alpha=60):
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    a = img.split()[3]
    shadow.paste((15, 23, 42, alpha), (offset[0], offset[1]), a)
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius))
    out = Image.alpha_composite(shadow, img)
    return out


def draw_app_icon(size=1024):
    img = Image.new("RGBA", (size, size), WHITE)
    d = ImageDraw.Draw(img)
    # Emerald gradient background
    for y in range(size):
        t = y / (size - 1)
        r = int(16 * (1 - t) + 5 * t)
        g = int(185 * (1 - t) + 150 * t)
        b = int(129 * (1 - t) + 105 * t)
        d.line([(0, y), (size, y)], fill=(r, g, b, 255))
    # Subtle hex grid lines
    cx, cy = size // 2, size // 2
    rad = int(size * 0.34)
    pts = [
        (cx + rad * math.cos(math.radians(60 * i - 30)),
         cy + rad * math.sin(math.radians(60 * i - 30)))
        for i in range(6)
    ]
    d.polygon(pts, fill=(255, 255, 255, 36), outline=(255, 255, 255, 220), width=max(4, size // 48))
    # Gold chest/pin emblem inside
    pin_r = int(size * 0.14)
    d.ellipse([cx - pin_r, cy - pin_r - int(size * 0.04), cx + pin_r, cy + pin_r - int(size * 0.04)], fill=GOLD, outline=WHITE, width=max(4, size // 64))
    d.polygon([
        (cx - pin_r * 0.72, cy + int(size * 0.02)),
        (cx + pin_r * 0.72, cy + int(size * 0.02)),
        (cx, cy + int(size * 0.24)),
    ], fill=GOLD)
    inner_r = int(pin_r * 0.42)
    d.ellipse([cx - inner_r, cy - inner_r - int(size * 0.04), cx + inner_r, cy + inner_r - int(size * 0.04)], fill=WHITE)
    return img


def draw_chest(size=256, premium=False):
    img = new_canvas(size)
    d = ImageDraw.Draw(img)
    main = GOLD if premium else EMERALD
    dark = GOLD_DARK if premium else EMERALD_DARK
    trim = GOLD_LIGHT if premium else (255, 255, 255, 240)
    s = size
    # Base box
    d.rounded_rectangle([s*0.16, s*0.42, s*0.84, s*0.84], radius=int(s*0.08), fill=dark, outline=DARK, width=max(3, s//48))
    d.rounded_rectangle([s*0.18, s*0.44, s*0.82, s*0.78], radius=int(s*0.06), fill=main)
    # Lid
    d.rounded_rectangle([s*0.14, s*0.24, s*0.86, s*0.48], radius=int(s*0.1), fill=main, outline=DARK, width=max(3, s//48))
    d.rounded_rectangle([s*0.20, s*0.27, s*0.80, s*0.36], radius=int(s*0.05), fill=trim)
    # Center lock
    d.rounded_rectangle([s*0.42, s*0.41, s*0.58, s*0.60], radius=int(s*0.04), fill=GOLD if not premium else WHITE, outline=DARK, width=max(2, s//64))
    d.ellipse([s*0.47, s*0.47, s*0.53, s*0.53], fill=DARK)
    if premium:
        # Sparkle stars
        for sx, sy, sr in [(0.18, 0.18, 0.06), (0.84, 0.16, 0.05), (0.86, 0.56, 0.04)]:
            cx, cy, r = s*sx, s*sy, s*sr
            d.polygon([(cx, cy-r), (cx+r*0.3, cy-r*0.3), (cx+r, cy), (cx+r*0.3, cy+r*0.3), (cx, cy+r), (cx-r*0.3, cy+r*0.3), (cx-r, cy), (cx-r*0.3, cy-r*0.3)], fill=GOLD_LIGHT)
    return add_soft_shadow(img)


def draw_key(size=256, flat=False):
    img = new_canvas(size)
    d = ImageDraw.Draw(img)
    s = size
    fill = EMERALD if flat else GOLD
    edge = EMERALD_DARK if flat else GOLD_DARK
    # Bow (ring)
    d.ellipse([s*0.16, s*0.28, s*0.52, s*0.64], fill=fill, outline=edge if not flat else DARK, width=max(3, s//42))
    d.ellipse([s*0.27, s*0.39, s*0.41, s*0.53], fill=(0, 0, 0, 0))
    # Clear inner hole properly
    mask = Image.new("L", (s, s), 255)
    md = ImageDraw.Draw(mask)
    md.ellipse([s*0.27, s*0.39, s*0.41, s*0.53], fill=0)
    # Shaft & teeth
    d.rounded_rectangle([s*0.46, s*0.42, s*0.86, s*0.52], radius=int(s*0.04), fill=fill, outline=edge if not flat else DARK, width=max(2, s//64))
    d.rounded_rectangle([s*0.68, s*0.50, s*0.75, s*0.65], radius=int(s*0.02), fill=fill)
    d.rounded_rectangle([s*0.78, s*0.50, s*0.85, s*0.62], radius=int(s*0.02), fill=fill)
    r, g, b, a = img.split()
    from PIL import ImageChops
    a = ImageChops.multiply(a, mask)
    img = Image.merge("RGBA", (r, g, b, a))
    return img if flat else add_soft_shadow(img)


def draw_shield(size=256):
    img = new_canvas(size)
    d = ImageDraw.Draw(img)
    s = size
    pts = [(s*0.50, s*0.12), (s*0.84, s*0.24), (s*0.78, s*0.62), (s*0.50, s*0.88), (s*0.22, s*0.62), (s*0.16, s*0.24)]
    d.polygon(pts, fill=EMERALD, outline=DARK, width=max(4, s//42))
    inner = [(s*0.50, s*0.21), (s*0.75, s*0.30), (s*0.70, s*0.58), (s*0.50, s*0.78), (s*0.30, s*0.58), (s*0.25, s*0.30)]
    d.polygon(inner, fill=EMERALD_DARK)
    d.line([(s*0.36, s*0.50), (s*0.46, s*0.60), (s*0.65, s*0.40)], fill=WHITE, width=max(6, s//20))
    return add_soft_shadow(img)


def draw_flat_circle_icon(size=256, bg=EMERALD, kind="walk"):
    img = new_canvas(size)
    d = ImageDraw.Draw(img)
    s = size
    # Clean crisp icon with white glyph inside emerald badge or clean flat vector
    pad = s * 0.08
    d.ellipse([pad, pad, s - pad, s - pad], fill=bg)
    w = max(5, s // 22)
    fg = WHITE

    if kind == "walk":
        d.ellipse([s*0.45, s*0.20, s*0.57, s*0.32], fill=fg)
        d.line([(s*0.50, s*0.33), (s*0.46, s*0.54), (s*0.36, s*0.76)], fill=fg, width=w)
        d.line([(s*0.46, s*0.54), (s*0.60, s*0.75)], fill=fg, width=w)
        d.line([(s*0.36, s*0.45), (s*0.50, s*0.38), (s*0.64, s*0.47)], fill=fg, width=w)
    elif kind == "run":
        d.ellipse([s*0.54, s*0.19, s*0.66, s*0.31], fill=fg)
        d.line([(s*0.56, s*0.32), (s*0.46, s*0.52), (s*0.28, s*0.66)], fill=fg, width=w)
        d.line([(s*0.46, s*0.52), (s*0.66, s*0.66), (s*0.58, s*0.80)], fill=fg, width=w)
        d.line([(s*0.35, s*0.40), (s*0.53, s*0.36), (s*0.71, s*0.44)], fill=fg, width=w)
    elif kind == "bike":
        d.ellipse([s*0.20, s*0.52, s*0.42, s*0.74], outline=fg, width=w)
        d.ellipse([s*0.58, s*0.52, s*0.80, s*0.74], outline=fg, width=w)
        d.line([(s*0.31, s*0.63), (s*0.48, s*0.42), (s*0.65, s*0.42), (s*0.69, s*0.63)], fill=fg, width=w)
        d.line([(s*0.48, s*0.42), (s*0.48, s*0.63), (s*0.31, s*0.63)], fill=fg, width=w)
    elif kind == "timer":
        d.rounded_rectangle([s*0.42, s*0.18, s*0.58, s*0.25], radius=4, fill=fg)
        d.ellipse([s*0.26, s*0.28, s*0.74, s*0.76], outline=fg, width=w)
        d.line([(s*0.50, s*0.52), (s*0.50, s*0.36)], fill=fg, width=w)
        d.line([(s*0.50, s*0.52), (s*0.63, s*0.58)], fill=fg, width=w)
    elif kind == "calories":
        d.polygon([(s*0.52, s*0.18), (s*0.70, s*0.48), (s*0.64, s*0.76), (s*0.36, s*0.76), (s*0.30, s*0.50), (s*0.44, s*0.34)], fill=fg)
        d.ellipse([s*0.42, s*0.54, s*0.58, s*0.72], fill=bg)
    elif kind == "ranking":
        d.rounded_rectangle([s*0.22, s*0.52, s*0.38, s*0.76], radius=4, fill=fg)
        d.rounded_rectangle([s*0.42, s*0.30, s*0.58, s*0.76], radius=4, fill=GOLD)
        d.rounded_rectangle([s*0.62, s*0.44, s*0.78, s*0.76], radius=4, fill=fg)
    elif kind == "backpack":
        d.rounded_rectangle([s*0.36, s*0.22, s*0.64, s*0.38], radius=12, outline=fg, width=w)
        d.rounded_rectangle([s*0.27, s*0.32, s*0.73, s*0.76], radius=18, fill=fg)
        d.rounded_rectangle([s*0.34, s*0.50, s*0.66, s*0.68], radius=8, fill=bg)
    elif kind == "qrcode":
        for rx, ry in [(0.26, 0.26), (0.56, 0.26), (0.26, 0.56)]:
            d.rectangle([s*rx, s*ry, s*(rx+0.18), s*(ry+0.18)], outline=fg, width=w)
            d.rectangle([s*(rx+0.06), s*(ry+0.06), s*(rx+0.12), s*(ry+0.12)], fill=fg)
        d.rectangle([s*0.56, s*0.56, s*0.64, s*0.64], fill=fg)
        d.rectangle([s*0.66, s*0.66, s*0.74, s*0.74], fill=fg)
    elif kind == "store":
        d.polygon([(s*0.22, s*0.38), (s*0.30, s*0.24), (s*0.70, s*0.24), (s*0.78, s*0.38)], fill=fg)
        d.rounded_rectangle([s*0.26, s*0.40, s*0.74, s*0.74], radius=6, outline=fg, width=w)
        d.rectangle([s*0.43, s*0.54, s*0.57, s*0.74], fill=fg)
    elif kind == "location":
        d.ellipse([s*0.32, s*0.22, s*0.68, s*0.58], fill=fg)
        d.polygon([(s*0.34, s*0.46), (s*0.66, s*0.46), (s*0.50, s*0.78)], fill=fg)
        d.ellipse([s*0.43, s*0.33, s*0.57, s*0.47], fill=bg)
    elif kind == "settings":
        d.ellipse([s*0.30, s*0.30, s*0.70, s*0.70], outline=fg, width=w*2)
        d.ellipse([s*0.42, s*0.42, s*0.58, s*0.58], fill=bg)
        for i in range(8):
            ang = math.radians(i * 45)
            x1 = s*0.50 + s*0.20*math.cos(ang)
            y1 = s*0.50 + s*0.20*math.sin(ang)
            x2 = s*0.50 + s*0.27*math.cos(ang)
            y2 = s*0.50 + s*0.27*math.sin(ang)
            d.line([(x1, y1), (x2, y2)], fill=fg, width=w+2)
    return img


def draw_avatar(idx, size=256):
    img = new_canvas(size)
    d = ImageDraw.Draw(img)
    s = size
    bg_colors = [
        (209, 250, 229, 255), (219, 234, 254, 255), (254, 243, 199, 255),
        (237, 233, 254, 255), (252, 231, 243, 255), (224, 242, 254, 255),
        (220, 252, 231, 255), (254, 226, 226, 255), (241, 245, 249, 255),
    ]
    skin_colors = [
        (214, 155, 114, 255), (244, 198, 168, 255), (248, 212, 186, 255),
        (141, 85, 52, 255), (198, 134, 92, 255), (95, 58, 38, 255),
        (235, 188, 154, 255), (250, 218, 196, 255), (224, 168, 128, 255),
    ]
    hair_colors = [
        (168, 92, 34, 255), (244, 164, 184, 255), (156, 76, 32, 255),
        (28, 28, 34, 255), (92, 54, 34, 255), (138, 108, 76, 255),
        (148, 163, 184, 255), (234, 206, 120, 255), (124, 58, 24, 255),
    ]
    d.ellipse([4, 4, s-4, s-4], fill=bg_colors[idx % len(bg_colors)], outline=WHITE, width=6)
    # Shoulders / Jacket (matches white/emerald explorer style from screenshot)
    d.pieslice([s*0.18, s*0.64, s*0.82, s*1.12], 180, 360, fill=WHITE, outline=EMERALD, width=4)
    # Neck & Head
    d.rectangle([s*0.43, s*0.56, s*0.57, s*0.70], fill=skin_colors[idx % len(skin_colors)])
    d.ellipse([s*0.31, s*0.24, s*0.69, s*0.62], fill=skin_colors[idx % len(skin_colors)])
    # Hair cap
    d.pieslice([s*0.28, s*0.17, s*0.72, s*0.48], 175, 365, fill=hair_colors[idx % len(hair_colors)])
    # Eyes & Smile
    d.ellipse([s*0.40, s*0.41, s*0.45, s*0.46], fill=DARK)
    d.ellipse([s*0.55, s*0.41, s*0.60, s*0.46], fill=DARK)
    d.arc([s*0.44, s*0.47, s*0.56, s*0.55], 15, 165, fill=(140, 65, 55, 255), width=3)
    return img


def write_imageset(name, img):
    folder = XCASSETS_DIR / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    fname = f"{name}.png"
    img.save(folder / fname, "PNG")
    contents = {
        "images": [{"filename": fname, "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1}
    }
    (folder / "Contents.json").write_text(json.dumps(contents, indent=2), encoding="utf-8")


def main():
    ICONS_DIR.mkdir(parents=True, exist_ok=True)

    app_icon = draw_app_icon(1024).convert("RGB")
    app_icon.save(ICONS_DIR / "app_icon.png", "PNG")
    appicon_dir = XCASSETS_DIR / "AppIcon.appiconset"
    appicon_dir.mkdir(parents=True, exist_ok=True)
    app_icon.save(appicon_dir / "AppIcon.png", "PNG")
    (appicon_dir / "Contents.json").write_text(json.dumps({
        "images": [{"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
        "info": {"author": "xcode", "version": 1}
    }, indent=2), encoding="utf-8")

    assets = {
        "obj_chest_common": draw_chest(256, premium=False),
        "obj_chest_premium": draw_chest(256, premium=True),
        "obj_key_3d": draw_key(256, flat=False),
        "obj_territory_shield": draw_shield(256),
        "icon_walk": draw_flat_circle_icon(256, EMERALD, "walk"),
        "icon_run": draw_flat_circle_icon(256, EMERALD, "run"),
        "icon_bike": draw_flat_circle_icon(256, EMERALD, "bike"),
        "icon_timer": draw_flat_circle_icon(256, DARK, "timer"),
        "icon_calories": draw_flat_circle_icon(256, EMERALD_DARK, "calories"),
        "icon_ranking": draw_flat_circle_icon(256, EMERALD, "ranking"),
        "icon_backpack": draw_flat_circle_icon(256, EMERALD, "backpack"),
        "icon_qrcode": draw_flat_circle_icon(256, DARK, "qrcode"),
        "icon_store": draw_flat_circle_icon(256, EMERALD, "store"),
        "icon_location": draw_flat_circle_icon(256, EMERALD, "location"),
        "icon_key_flat": draw_key(256, flat=True),
        "icon_settings": draw_flat_circle_icon(256, SLATE, "settings"),
    }

    for name, img in assets.items():
        img.save(ICONS_DIR / f"{name}.png", "PNG")
        write_imageset(name, img)

    for i in range(1, 10):
        av = draw_avatar(i - 1, 256)
        write_imageset(f"avatar_{i}", av)

    print(f"Generated {len(assets) + 1} icons in {ICONS_DIR} and 9 avatars in {XCASSETS_DIR}")


if __name__ == "__main__":
    main()
