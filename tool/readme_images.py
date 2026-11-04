#!/usr/bin/env python3
"""Turn the raw README renders in app/build/readme/ into the images under docs/.

Run after the two screenshot suites (README, "Regenerating screenshots"):

    python3 tool/readme_images.py

Screens go to docs/screenshots/ and banners and showcases to docs/assets/, all
as WebP at quality 90: visually lossless for UI, at a fraction of PNG's size,
so the README loads fast. It also writes docs/assets/social-preview.jpg at
1280x640 for GitHub's social preview setting. Requires Pillow.
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "app" / "build" / "readme"
SHOTS = ROOT / "docs" / "screenshots"
ASSETS = ROOT / "docs" / "assets"
ART_PREFIXES = ("banner-", "themes")


def main() -> None:
    pngs = sorted(SRC.glob("*.png"))
    if not pngs:
        raise SystemExit(f"No renders in {SRC}; run the screenshot tests first.")
    SHOTS.mkdir(parents=True, exist_ok=True)
    ASSETS.mkdir(parents=True, exist_ok=True)
    before = after = 0
    for png in pngs:
        out = (ASSETS if png.stem.startswith(ART_PREFIXES) else SHOTS) / f"{png.stem}.webp"
        with Image.open(png) as image:
            image.save(out, "WEBP", quality=90, method=6)
        before += png.stat().st_size
        after += out.stat().st_size
        print(f"{out.relative_to(ROOT)}: {png.stat().st_size // 1024} KB -> {out.stat().st_size // 1024} KB")
    banner = SRC / "banner-dark-en.png"
    if banner.exists():
        with Image.open(banner) as image:
            preview = image.convert("RGB").resize((1280, 640), Image.LANCZOS)
            preview.save(ASSETS / "social-preview.jpg", "JPEG", quality=90, optimize=True, progressive=True)
    print(f"total: {before / 1e6:.1f} MB of PNG -> {after / 1e6:.1f} MB of WebP")


if __name__ == "__main__":
    main()
