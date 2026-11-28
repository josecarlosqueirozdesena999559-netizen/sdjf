"""
Utilitário de recorte automático de spritesheet de ícones.
Uso:
  1. Salve sua imagem de grade em: assets/raw/icons_sheet.png
  2. Execute: python scripts/crop_icons.py
Os ícones recortados são salvos em assets/icons/ e Resources/Assets.xcassets/.
"""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SHEET_PATH = ROOT / "assets" / "raw" / "icons_sheet.png"
ICONS_DIR = ROOT / "assets" / "icons"
XCASSETS_DIR = ROOT / "Resources" / "Assets.xcassets"

ICON_NAMES = [
    "obj_chest_common", "obj_chest_premium", "obj_key_3d", "obj_territory_shield",
    "icon_walk", "icon_run", "icon_bike", "icon_timer",
    "icon_calories", "icon_ranking", "icon_backpack", "icon_qrcode",
    "icon_store", "icon_location", "icon_key_flat", "icon_settings",
]


def trim_transparent(img: Image.Image) -> Image.Image:
    bbox = img.getbbox()
    return img.crop(bbox) if bbox else img


def crop_grid(cols=4, rows=4):
    if not SHEET_PATH.exists():
        raise FileNotFoundError(f"Coloque a imagem de origem em {SHEET_PATH}")

    sheet = Image.open(SHEET_PATH).convert("RGBA")
    cw = sheet.width // cols
    ch = sheet.height // rows

    ICONS_DIR.mkdir(parents=True, exist_ok=True)
    for idx, name in enumerate(ICON_NAMES):
        r, c = divmod(idx, cols)
        cell = sheet.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch))
        trimmed = trim_transparent(cell).resize((256, 256), Image.Resampling.LANCZOS)
        trimmed.save(ICONS_DIR / f"{name}.png", "PNG")

        imageset = XCASSETS_DIR / f"{name}.imageset"
        imageset.mkdir(parents=True, exist_ok=True)
        trimmed.save(imageset / f"{name}.png", "PNG")
        (imageset / "Contents.json").write_text(json.dumps({
            "images": [{"filename": f"{name}.png", "idiom": "universal"}],
            "info": {"author": "xcode", "version": 1},
        }, indent=2), encoding="utf-8")

    print(f"Recortados {len(ICON_NAMES)} ícones para {ICONS_DIR} e {XCASSETS_DIR}")


if __name__ == "__main__":
    crop_grid()
