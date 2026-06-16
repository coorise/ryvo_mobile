#!/usr/bin/env python3
"""Overlay a deploy-target badge on the Ryvo app icon (local / dev)."""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

BADGES = {
    "local": {"label": "LOCAL", "fill": (37, 99, 235)},  # blue-600
    "dev": {"label": "DEV", "fill": (234, 88, 12)},  # orange-600
}


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    ):
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def add_badge(base: Image.Image, label: str, fill: tuple[int, int, int]) -> Image.Image:
    img = base.convert("RGBA").copy()
    w, h = img.size
    draw = ImageDraw.Draw(img)

    badge_h = max(28, h // 5)
    badge_w = max(int(badge_h * 2.8), int(len(label) * badge_h * 0.55))
    margin = max(4, h // 32)
    x0 = w - badge_w - margin
    y0 = h - badge_h - margin
    x1 = w - margin
    y1 = h - margin
    radius = badge_h // 4

    draw.rounded_rectangle((x0, y0, x1, y1), radius=radius, fill=(*fill, 255))

    font = load_font(max(14, badge_h - 10))
    bbox = draw.textbbox((0, 0), label, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = x0 + (badge_w - tw) // 2
    ty = y0 + (badge_h - th) // 2 - 1
    draw.text((tx, ty), label, fill=(255, 255, 255, 255), font=font)

    return img


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("target", choices=["local", "dev", "prod"])
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    base = Image.open(args.source)
    if args.target == "prod":
        out = base.convert("RGBA")
    else:
        badge = BADGES[args.target]
        out = add_badge(base, badge["label"], badge["fill"])

    args.output.parent.mkdir(parents=True, exist_ok=True)
    out.save(args.output, format="PNG")
    print(args.output)


if __name__ == "__main__":
    main()
