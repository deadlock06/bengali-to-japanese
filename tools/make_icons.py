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


SUN = (216, 64, 64)  # brand red sun (Home backdrop motif)


def icon(size: int, pad_ratio: float = 0.0, rounded: bool = False) -> Image.Image:
    """One icon tile (v2, D-039). Design: subtle vertical gradient on brand
    near-black, faint red-sun disc upper-right (ties to the Home backdrop),
    ば with a soft drop shadow, green live-dot. rounded=True clips corners
    (web-displayed icons); Android legacy mipmaps stay square (launcher masks).
    pad_ratio shrinks content for the maskable safe-zone."""
    img = Image.new("RGBA", (size, size), BG)
    d = ImageDraw.Draw(img)
    # 1. vertical gradient #161616 → #0D0D0D — quiet depth, not flat
    for yy in range(size):
        t = yy / size
        g = int(22 - 9 * t)
        d.line([(0, yy), (size, yy)], fill=(g, g, g, 255))
    # 2. faint red sun, upper-right (≈14% alpha) — the brand motif
    sun = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sun)
    r_sun = size * 0.46
    cx_s, cy_s = size * 0.82, size * 0.16
    sd.ellipse([cx_s - r_sun, cy_s - r_sun, cx_s + r_sun, cy_s + r_sun],
               fill=(*SUN, 26))
    img = Image.alpha_composite(img, sun)
    d = ImageDraw.Draw(img)
    # 3. ば — soft shadow then brand yellow
    glyph_px = int(size * (0.62 - pad_ratio))
    font = ImageFont.truetype(FONT, glyph_px)
    bbox = d.textbbox((0, 0), "ば", font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (size - w) / 2 - bbox[0]
    y = (size - h) / 2 - bbox[1] - size * 0.02
    off = max(1, size // 96)
    d.text((x + off, y + off), "ば", font=font, fill=(0, 0, 0, 140))
    d.text((x, y), "ば", font=font, fill=YELLOW)
    # 4. green live-dot with a thin bg ring so it reads at 48px
    r = size * 0.055
    cx, cy = size * 0.72, size * 0.74
    d.ellipse([cx - r * 1.35, cy - r * 1.35, cx + r * 1.35, cy + r * 1.35],
              fill=BG)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GREEN)
    # 5. rounded corners for web-displayed variants
    if rounded:
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, size - 1, size - 1], radius=int(size * 0.22), fill=255)
        out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        out.paste(img, (0, 0), mask)
        return out
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
    save(icon(192, rounded=True), "web/icons/Icon-192.png")
    save(icon(512, rounded=True), "web/icons/Icon-512.png")
    save(icon(192, pad_ratio=0.12), "web/icons/Icon-maskable-192.png")
    save(icon(512, pad_ratio=0.12), "web/icons/Icon-maskable-512.png")
    save(icon(64, rounded=True), "web/favicon.png")
    print("done — rebuild web / apk to pick up the new icons")


if __name__ == "__main__":
    main()
