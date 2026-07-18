#!/usr/bin/env python3
# Bhasago launcher/web icons (D-032) — replaces the default Flutter logo.
# Design: brand near-black (#111111) tile, "ば" (ba, for Bhasago) in brand
# yellow (#EFE94B) set in the app's own Zen Kaku Gothic Black, with a small
# green progress dot — matching the in-app v4 design language exactly.
#   python3 tools/make_icons.py
import os
from PIL import Image, ImageDraw, ImageFont

FONT = "assets/fonts/ZenKakuGothicNew-Black.ttf"
BG, YELLOW, GREEN = (17, 17, 17, 255), (239, 233, 75, 255), (53, 224, 101, 255)


def icon(size: int, pad_ratio: float = 0.0) -> Image.Image:
    """One square icon. pad_ratio shrinks content for maskable safe-zone."""
    img = Image.new("RGBA", (size, size), BG)
    d = ImageDraw.Draw(img)
    # glyph occupies ~62% of the tile (less when padded for maskable)
    glyph_px = int(size * (0.62 - pad_ratio))
    font = ImageFont.truetype(FONT, glyph_px)
    # center "ば" optically (CJK glyphs sit low — nudge up slightly)
    bbox = d.textbbox((0, 0), "ば", font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (size - w) / 2 - bbox[0]
    y = (size - h) / 2 - bbox[1] - size * 0.02
    d.text((x, y), "ば", font=font, fill=YELLOW)
    # green progress dot, bottom-right of the glyph — the app's "live" accent
    r = size * 0.055
    cx, cy = size * 0.72, size * 0.74
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GREEN)
    return img


def save(img: Image.Image, path: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "PNG")
    print(f"  {path} ({img.size[0]}px)")


def main():
    # Android launcher (legacy square — Android masks it per launcher)
    for dpi, px in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                    ("xxhdpi", 144), ("xxxhdpi", 192)]:
        save(icon(px), f"android/app/src/main/res/mipmap-{dpi}/ic_launcher.png")
    # Web PWA icons + favicon
    save(icon(192), "web/icons/Icon-192.png")
    save(icon(512), "web/icons/Icon-512.png")
    save(icon(192, pad_ratio=0.12), "web/icons/Icon-maskable-192.png")
    save(icon(512, pad_ratio=0.12), "web/icons/Icon-maskable-512.png")
    save(icon(64), "web/favicon.png")
    print("done — rebuild web / apk to pick up the new icons")


if __name__ == "__main__":
    main()
