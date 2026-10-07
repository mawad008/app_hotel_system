"""Generates the launcher icons and the Google Play listing graphics from the
vector brand mark.

    python tool/generate_store_assets.py

The mark is read from android/app/src/main/res/drawable/launch_logo.xml, which
mirrors the BrandMark paths in lib/core/widgets/brand_logo.dart — so the icon,
the splash and the in-app logo are always the same artwork. Requires Pillow.

Writes:
  * android/app/src/main/res/mipmap-*/ic_launcher(.png|_round.png)   legacy icons
  * android/app/src/main/res/drawable/ic_launcher_(foreground|monochrome).xml
  * android/app/src/main/res/mipmap-anydpi-v26/ic_launcher(_round).xml  adaptive
  * ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png              (no alpha)
  * web/icons/*.png, web/favicon.png
  * store/google-play/icon-512.png, feature-graphic-1024x500.png
"""

import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"
ANDROID_NS = "{http://schemas.android.com/apk/res/android}"

WHITE = (255, 255, 255)
INK_950 = (17, 15, 12)  # AppPrimitives.stone950
SUPERSAMPLE = 4


def load_mark():
    """[(rgb, pathData, polygon)] in the 120x120 Figma frame."""
    tree = ET.parse(RES / "drawable/launch_logo.xml")
    paths = []
    for node in tree.iter("path"):
        colour = node.get(ANDROID_NS + "fillColor")[-6:]
        rgb = tuple(int(colour[i : i + 2], 16) for i in (0, 2, 4))
        data = node.get(ANDROID_NS + "pathData")
        paths.append((rgb, data, flatten(data)))
    return paths


def flatten(data):
    """Absolute M / L / C / Z path data -> one polygon."""
    tokens = re.findall(r"[MLCZ]|-?\d+\.?\d*", data)
    points, i, cur = [], 0, (0.0, 0.0)

    def take(n):
        nonlocal i
        values = [float(t) for t in tokens[i : i + n]]
        i += n
        return values

    while i < len(tokens):
        cmd = tokens[i]
        i += 1
        if cmd in "ML":
            cur = tuple(take(2))
            points.append(cur)
        elif cmd == "C":
            x1, y1, x2, y2, x3, y3 = take(6)
            x0, y0 = cur
            for step in range(1, 25):
                t = step / 24
                u = 1 - t
                points.append(
                    (
                        u**3 * x0 + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t**3 * x3,
                        u**3 * y0 + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t**3 * y3,
                    )
                )
            cur = (x3, y3)
    return points


MARK = load_mark()
_XS = [x for _, _, poly in MARK for x, _ in poly]
_YS = [y for _, _, poly in MARK for _, y in poly]
MARK_BOX = (min(_XS), min(_YS), max(_XS), max(_YS))
MARK_W = MARK_BOX[2] - MARK_BOX[0]
MARK_H = MARK_BOX[3] - MARK_BOX[1]
MARK_CX = (MARK_BOX[0] + MARK_BOX[2]) / 2
MARK_CY = (MARK_BOX[1] + MARK_BOX[3]) / 2


def draw_mark(image, centre, width, recolour=None):
    """Paints the mark `width` px wide, its bounding box centred on `centre`."""
    scale = width / MARK_W
    draw = ImageDraw.Draw(image)
    for rgb, _, poly in MARK:
        fill = recolour(rgb) if recolour else rgb
        draw.polygon(
            [
                (centre[0] + (x - MARK_CX) * scale, centre[1] + (y - MARK_CY) * scale)
                for x, y in poly
            ],
            fill=fill,
        )


def square_icon(size, mark_ratio=0.56, background=WHITE, shape=None):
    """`shape`: None (full bleed), 'round' or 'squircle' — transparent outside."""
    big = size * SUPERSAMPLE
    image = Image.new("RGBA", (big, big), background + (255,))
    draw_mark(image, (big / 2, big / 2), big * mark_ratio)
    if shape:
        mask = Image.new("L", (big, big), 0)
        pen = ImageDraw.Draw(mask)
        if shape == "round":
            pen.ellipse((0, 0, big - 1, big - 1), fill=255)
        else:
            inset = big * 0.06
            pen.rounded_rectangle(
                (inset, inset, big - 1 - inset, big - 1 - inset),
                radius=big * 0.18,
                fill=255,
            )
        image.putalpha(mask)
    return image.resize((size, size), Image.LANCZOS)


def save(image, path, alpha=True):
    path.parent.mkdir(parents=True, exist_ok=True)
    (image if alpha else image.convert("RGB")).save(path, optimize=True)
    print("wrote", path.relative_to(ROOT).as_posix())


def write_text(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")
    print("wrote", path.relative_to(ROOT).as_posix())


def android_icons():
    for density, size in {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }.items():
        folder = RES / f"mipmap-{density}"
        save(square_icon(size, 0.5, shape="squircle"), folder / "ic_launcher.png")
        save(square_icon(size, 0.5, shape="round"), folder / "ic_launcher_round.png")

    # Adaptive icon (API 26+): a 108dp canvas of which only the centre 66dp is
    # guaranteed visible under every launcher mask — the mark is scaled to sit
    # inside that safe zone.
    scale = 0.55
    tx = 54 - MARK_CX * scale
    ty = 54 - MARK_CY * scale

    def vector(colour_of):
        body = "\n".join(
            f'        <path\n            android:fillColor="{colour_of(rgb)}"\n'
            f'            android:pathData="{data}" />'
            for rgb, data, _ in MARK
        )
        return (
            '<?xml version="1.0" encoding="utf-8"?>\n'
            "<!-- Generated by tool/generate_store_assets.py from launch_logo.xml"
            " — do not edit by hand. -->\n"
            '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
            '    android:width="108dp"\n    android:height="108dp"\n'
            '    android:viewportWidth="108"\n    android:viewportHeight="108">\n'
            f'    <group\n        android:scaleX="{scale}"\n        android:scaleY="{scale}"\n'
            f'        android:translateX="{tx:.2f}"\n        android:translateY="{ty:.2f}">\n'
            f"{body}\n    </group>\n</vector>\n"
        )

    write_text(
        RES / "drawable/ic_launcher_foreground.xml",
        vector(lambda rgb: "#FF%02X%02X%02X" % rgb),
    )
    # Android 13+ themed icons tint a single-colour silhouette.
    write_text(
        RES / "drawable/ic_launcher_monochrome.xml", vector(lambda rgb: "#FF000000")
    )
    adaptive = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@android:color/white" />\n'
        '    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />\n'
        "</adaptive-icon>\n"
    )
    write_text(RES / "mipmap-anydpi-v26/ic_launcher.xml", adaptive)
    write_text(RES / "mipmap-anydpi-v26/ic_launcher_round.xml", adaptive)


def ios_icons():
    folder = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((folder / "Contents.json").read_text(encoding="utf-8"))
    done = set()
    for entry in contents["images"]:
        name = entry.get("filename")
        if not name or name in done:
            continue
        done.add(name)
        points = float(entry["size"].split("x")[0])
        pixels = round(points * int(entry["scale"].rstrip("x")))
        # App Store Connect rejects icons with an alpha channel.
        save(square_icon(pixels), folder / name, alpha=False)


def web_icons():
    icons = ROOT / "web/icons"
    save(square_icon(192), icons / "Icon-192.png", alpha=False)
    save(square_icon(512), icons / "Icon-512.png", alpha=False)
    save(square_icon(192, 0.42), icons / "Icon-maskable-192.png", alpha=False)
    save(square_icon(512, 0.42), icons / "Icon-maskable-512.png", alpha=False)
    save(square_icon(32, 0.72), ROOT / "web/favicon.png")


def play_listing():
    out = ROOT / "store/google-play"
    # Play wants a full-bleed 512x512 32-bit PNG; it applies its own mask.
    save(square_icon(512), out / "icon-512.png")

    width, height = 1024 * 2, 500 * 2
    graphic = Image.new("RGB", (width, height), INK_950)
    # Light mark on the dark ground: towers in white, the gold spire kept.
    towers = MARK[0][0]
    draw_mark(
        graphic,
        (width * 0.24, height * 0.5),
        height * 0.5,
        recolour=lambda rgb: WHITE if rgb == towers else rgb,
    )
    pen = ImageDraw.Draw(graphic)
    fonts = ROOT / "assets/fonts"
    title = ImageFont.truetype(str(fonts / "Tajawal-Bold.ttf"), 148)
    subtitle = ImageFont.truetype(str(fonts / "Tajawal-Regular.ttf"), 60)
    left = width * 0.43
    pen.text((left, height * 0.31), "Hotel System", font=title, fill=WHITE)
    pen.rectangle(
        (left + 4, height * 0.535, left + 124, height * 0.535 + 8), fill=MARK[-1][0]
    )
    pen.text(
        (left, height * 0.59),
        "Book, check in and unlock your room",
        font=subtitle,
        fill=(214, 208, 198),
    )
    save(
        graphic.resize((1024, 500), Image.LANCZOS),
        out / "feature-graphic-1024x500.png",
    )


if __name__ == "__main__":
    android_icons()
    ios_icons()
    web_icons()
    play_listing()
