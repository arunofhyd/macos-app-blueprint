#!/usr/bin/env python3
# =============================================================================
#  make_app_icon.py — macOS iconutil ICNS Builder
#  Takes AppIcon.png (1024x1024) and generates AppIcon.icns
# =============================================================================
import os, subprocess, shutil
from PIL import Image

SIZES = [
    (16, 1, 'icon_16x16.png'),
    (16, 2, 'icon_16x16@2x.png'),
    (32, 1, 'icon_32x32.png'),
    (32, 2, 'icon_32x32@2x.png'),
    (128, 1, 'icon_128x128.png'),
    (128, 2, 'icon_128x128@2x.png'),
    (256, 1, 'icon_256x256.png'),
    (256, 2, 'icon_256x256@2x.png'),
    (512, 1, 'icon_512x512.png'),
    (512, 2, 'icon_512x512@2x.png'),
]

def generate_icns(source_png="AppIcon.png", output_icns="AppIcon.icns"):
    if not os.path.exists(source_png):
        print(f"Error: {source_png} not found.")
        return False

    iconset_dir = "AppIcon.iconset"
    os.makedirs(iconset_dir, exist_ok=True)
    img = Image.open(source_png)

    for base_size, scale, filename in SIZES:
        dim = base_size * scale
        resized = img.resize((dim, dim), Image.Resampling.LANCZOS)
        resized.save(os.path.join(iconset_dir, filename))

    subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", output_icns], check=True)
    shutil.rmtree(iconset_dir)
    print(f"✅ Successfully created {output_icns}")
    return True

if __name__ == "__main__":
    generate_icns()
