"""Generates the launcher icons, the native splash artwork, the in-app logo
paths and the Google Play listing graphics from the brand logo.

    pip install pillow svgelements
    python tool/generate_store_assets.py

The source is Design/brand/stdy-hotels-logo.svg, the designer's export: the
STDY HOTELS wordmark (white letters, gold O) and the app icon (white rounded
tile, gold ring), both drawn for the navy brand ground. On light grounds the
same artwork is used with the colours swapped (navy letters, navy tile), and
the launcher icons are the gold ring on navy. Everything below is derived from
the SVG, so the launcher icon, the splash and the in-app logo are always the
same artwork.

Writes:
  * android/app/src/main/res/mipmap-*/ic_launcher(.png|_round.png)   legacy icons
  * android/app/src/main/res/drawable/ic_launcher_(foreground|monochrome).xml
  * android/app/src/main/res/mipmap-anydpi-v26/ic_launcher(_round).xml  adaptive
  * android/app/src/main/res/drawable/(launch_logo|splash_icon).xml  native splash
  * ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png              (no alpha)
  * ios/Runner/Assets.xcassets/LaunchImage.imageset/*.png            native splash
  * web/icons/*.png, web/favicon.png
  * store/google-play/icon-512.png, feature-graphic-1024x500.png
  * lib/core/widgets/brand_paths.dart                                in-app logo
"""

import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont
from svgelements import (
    SVG,
    Arc,
    Close,
    CubicBezier,
    Line,
    Move,
    QuadraticBezier,
    Rect,
    Shape,
)
from svgelements import Path as SvgPath

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"
SOURCE = ROOT / "Design/brand/stdy-hotels-logo.svg"

WHITE = (255, 255, 255)
NAVY = (0x14, 0x25, 0x44)  # AppPrimitives.brandNavy
GOLD = (0xD3, 0xA5, 0x24)  # AppPrimitives.brandGold
SUPERSAMPLE = 4

# The native splash and the in-app splash share one layout: the 120dp icon
# raised 20.5dp so that, with the wordmark under it (BrandLockup), the whole
# lock-up is centred on screen.
SPLASH_ICON = 120
SPLASH_RAISE = 20.5


# --- Reading the artwork ---------------------------------------------------


def commands(shape):
    """A shape as absolute subpaths: [[('M',x,y) | ('L',x,y) | ('C',...) | ('Z',)]]."""
    path = SvgPath(shape)
    path.approximate_arcs_with_cubics()
    subpaths, current = [], None
    for seg in path:
        if isinstance(seg, Move):
            current = [("M", seg.end.x, seg.end.y)]
            subpaths.append(current)
        elif isinstance(seg, Line):
            current.append(("L", seg.end.x, seg.end.y))
        elif isinstance(seg, CubicBezier):
            current.append(
                ("C", seg.control1.x, seg.control1.y, seg.control2.x, seg.control2.y,
                 seg.end.x, seg.end.y)
            )
        elif isinstance(seg, QuadraticBezier):
            s, c, e = seg.start, seg.control, seg.end
            current.append(
                ("C", s.x + 2 / 3 * (c.x - s.x), s.y + 2 / 3 * (c.y - s.y),
                 e.x + 2 / 3 * (c.x - e.x), e.y + 2 / 3 * (c.y - e.y), e.x, e.y)
            )
        elif isinstance(seg, Close):
            current.append(("Z",))
        elif isinstance(seg, Arc):  # pragma: no cover - removed above
            raise ValueError("unexpected arc")
    return subpaths


def remap(subpaths, ox, oy, scale):
    out = []
    for sp in subpaths:
        out.append(
            [
                (c[0],) + tuple(
                    (v - (ox if i % 2 == 0 else oy)) * scale for i, v in enumerate(c[1:])
                )
                for c in sp
            ]
        )
    return out


def load_artwork():
    svg = SVG.parse(str(SOURCE), reify=True)
    shapes = [e for e in svg.elements() if isinstance(e, Shape)]
    tile = next(e for e in shapes if isinstance(e, Rect) and e.bbox()[1] > 300)
    tx, ty, tx2, _ = tile.bbox()
    tile_size = tx2 - tx
    word = [e for e in shapes if e.bbox()[1] < 300]
    wx = min(e.bbox()[0] for e in word)
    wy = min(e.bbox()[1] for e in word)
    wx2 = max(e.bbox()[2] for e in word)
    wy2 = max(e.bbox()[3] for e in word)
    word_h = wy2 - wy

    def is_gold(e):
        return e.fill is not None and e.fill.hex.lower().startswith("#d3a524")

    ring = next(e for e in shapes if is_gold(e) and e.bbox()[1] > 300)
    return {
        # Icon artwork in a 1x1 tile.
        "tile_radius": float(tile.rx) / tile_size,
        "ring": remap(commands(ring), tx, ty, 1 / tile_size),
        # Wordmark artwork, 1 unit tall.
        "word_width": (wx2 - wx) / word_h,
        "letters": [sp for e in word if not is_gold(e)
                    for sp in remap(commands(e), wx, wy, 1 / word_h)],
        "accent": [sp for e in word if is_gold(e)
                   for sp in remap(commands(e), wx, wy, 1 / word_h)],
    }


ART = load_artwork()


# --- Raster rendering ------------------------------------------------------


def flatten(subpath, ox, oy, scale):
    points, cur = [], (0.0, 0.0)
    for c in subpath:
        if c[0] in "ML":
            cur = (c[1], c[2])
            points.append(cur)
        elif c[0] == "C":
            x0, y0 = cur
            x1, y1, x2, y2, x3, y3 = c[1:]
            for step in range(1, 21):
                t = step / 20
                u = 1 - t
                points.append(
                    (u**3 * x0 + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t**3 * x3,
                     u**3 * y0 + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t**3 * y3)
                )
            cur = (x3, y3)
    return [(ox + x * scale, oy + y * scale) for x, y in points]


def fill(image, subpaths, colour, ox, oy, scale):
    """Even-odd fill (letters and the ring have holes)."""
    mask = Image.new("1", image.size, 0)
    for sp in subpaths:
        poly = flatten(sp, ox, oy, scale)
        if len(poly) < 3:
            continue
        layer = Image.new("1", image.size, 0)
        ImageDraw.Draw(layer).polygon(poly, fill=1)
        mask = ImageChops.logical_xor(mask, layer)
    image.paste(colour + (255,) if image.mode == "RGBA" else colour, mask=mask)


def draw_icon(image, left, top, size, tile=WHITE, ring=GOLD):
    """The app icon (tile + ring) in a `size` box; `tile=None` draws the ring only."""
    if tile is not None:
        ImageDraw.Draw(image).rounded_rectangle(
            (left, top, left + size, top + size),
            radius=size * ART["tile_radius"],
            fill=tile,
        )
    fill(image, ART["ring"], ring, left, top, size)


def draw_wordmark(image, left, top, width, letters=WHITE, accent=GOLD):
    scale = width / ART["word_width"]
    fill(image, ART["letters"], letters, left, top, scale)
    fill(image, ART["accent"], accent, left, top, scale)


def square_icon(size, tile_fraction=1.0, shape=None):
    """A launcher icon: the navy tile with the gold ring, the ring sized as on
    a tile spanning `tile_fraction` of the icon. `shape`: None (full bleed),
    'round' or 'squircle', transparent outside."""
    big = size * SUPERSAMPLE
    image = Image.new("RGBA", (big, big), NAVY + (255,))
    tile = big * tile_fraction
    draw_icon(image, (big - tile) / 2, (big - tile) / 2, tile, tile=None)
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


# --- Vector output ---------------------------------------------------------


def num(v):
    s = f"{v:.3f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def path_data(subpaths, scale):
    out = []
    for sp in subpaths:
        for c in sp:
            out.append(c[0] + (" " + " ".join(num(v * scale) for v in c[1:]) if len(c) > 1 else ""))
    return " ".join(out)


def tile_path_data(size):
    r = num(size * ART["tile_radius"])
    s, e = num(size), num(size - size * ART["tile_radius"])
    return (f"M {r} 0 H {e} A {r} {r} 0 0 1 {s} {r} V {e} A {r} {r} 0 0 1 {e} {s} "
            f"H {r} A {r} {r} 0 0 1 0 {e} V {r} A {r} {r} 0 0 1 {r} 0 Z")


def vector(width, viewport, comment, body, translate=(0, 0), scale=1):
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        f"<!-- {comment}\n"
        "     Generated by tool/generate_store_assets.py from"
        " Design/brand/stdy-hotels-logo.svg — do not edit by hand. -->\n"
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        f'    android:width="{width}dp"\n    android:height="{width}dp"\n'
        f'    android:viewportWidth="{viewport}"\n    android:viewportHeight="{viewport}">\n'
        f'    <group\n        android:scaleX="{num(scale)}"\n        android:scaleY="{num(scale)}"\n'
        f'        android:translateX="{num(translate[0])}"\n'
        f'        android:translateY="{num(translate[1])}">\n'
        f"{body}    </group>\n</vector>\n"
    )


def vpath(colour, data):
    return (
        "        <path\n"
        f'            android:fillColor="#FF{colour[0]:02X}{colour[1]:02X}{colour[2]:02X}"\n'
        '            android:fillType="evenOdd"\n'
        f'            android:pathData="{data}" />\n'
    )


def icon_body(size, tile=True, ring=GOLD):
    body = vpath(WHITE, tile_path_data(size)) if tile else ""
    return body + vpath(ring, path_data(ART["ring"], size))


# --- Targets ---------------------------------------------------------------


def android_icons():
    for density, size in {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }.items():
        folder = RES / f"mipmap-{density}"
        save(square_icon(size, 0.88, shape="squircle"), folder / "ic_launcher.png")
        save(square_icon(size, 0.88, shape="round"), folder / "ic_launcher_round.png")

    # Adaptive icon (API 26+): a 108dp canvas of which launchers show the
    # centre 72dp — the tile maps onto that, so the ring keeps the artwork's
    # proportions and stays inside the 66dp safe zone. The navy tile itself
    # is the adaptive background (@color/brand_navy).
    write_text(
        RES / "drawable/ic_launcher_foreground.xml",
        vector(108, 108, "Adaptive launcher icon foreground: the gold ring.",
               icon_body(72, tile=False), translate=(18, 18)),
    )
    # Android 13+ themed icons tint a single-colour silhouette.
    write_text(
        RES / "drawable/ic_launcher_monochrome.xml",
        vector(108, 108, "Themed (monochrome) launcher icon.",
               icon_body(72, tile=False, ring=(0, 0, 0)), translate=(18, 18)),
    )
    adaptive = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/brand_navy" />\n'
        '    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />\n'
        "</adaptive-icon>\n"
    )
    write_text(RES / "mipmap-anydpi-v26/ic_launcher.xml", adaptive)
    write_text(RES / "mipmap-anydpi-v26/ic_launcher_round.xml", adaptive)


def android_splash():
    write_text(
        RES / "drawable/launch_logo.xml",
        vector(SPLASH_ICON, SPLASH_ICON,
               "The app icon at the splash size (120dp) for the pre-Android-12 launch"
               " window (launch_background.xml).",
               icon_body(SPLASH_ICON)),
    )
    # The SplashScreen API (Android 12+) draws the icon on a 288dp canvas and
    # clips it to a centred 192dp circle; the rounded tile fits inside it.
    write_text(
        RES / "drawable/splash_icon.xml",
        vector(288, 288,
               "Android 12+ system splash icon: the 120dp app icon, raised 20.5dp to"
               " line up with the Flutter splash (BrandLockup).",
               icon_body(SPLASH_ICON),
               translate=((288 - SPLASH_ICON) / 2, (288 - SPLASH_ICON) / 2 - SPLASH_RAISE)),
    )


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
        # iOS applies its own corner mask, and App Store Connect rejects
        # icons with an alpha channel.
        save(square_icon(pixels), folder / name, alpha=False)


def ios_splash():
    # LaunchScreen.storyboard: navy ground, this image centred, raised 20.5pt.
    folder = ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    for suffix, factor in (("", 1), ("@2x", 2), ("@3x", 3)):
        big = SPLASH_ICON * factor * SUPERSAMPLE
        image = Image.new("RGBA", (big, big), (0, 0, 0, 0))
        draw_icon(image, 0, 0, big)
        size = SPLASH_ICON * factor
        save(image.resize((size, size), Image.LANCZOS), folder / f"LaunchImage{suffix}.png")


def web_icons():
    icons = ROOT / "web/icons"
    save(square_icon(192), icons / "Icon-192.png", alpha=False)
    save(square_icon(512), icons / "Icon-512.png", alpha=False)
    save(square_icon(192, 0.78), icons / "Icon-maskable-192.png", alpha=False)
    save(square_icon(512, 0.78), icons / "Icon-maskable-512.png", alpha=False)
    save(square_icon(32, 1.3), ROOT / "web/favicon.png")


def play_listing():
    out = ROOT / "store/google-play"
    # Play wants a full-bleed 512x512 32-bit PNG; it applies its own mask.
    save(square_icon(512), out / "icon-512.png")

    s = 2  # draw at 2x, then downsample
    width, height = 1024 * s, 500 * s
    graphic = Image.new("RGB", (width, height), NAVY)
    icon = 128 * s
    word_w = 520 * s
    word_h = word_w / ART["word_width"]
    gap1, gap2 = 40 * s, 30 * s
    subtitle = ImageFont.truetype(str(ROOT / "assets/fonts/Tajawal-Regular.ttf"), 30 * s)
    tagline = "Book, check in and unlock your room"
    tag_box = ImageDraw.Draw(graphic).textbbox((0, 0), tagline, font=subtitle)
    tag_h = tag_box[3] - tag_box[1]
    top = (height - (icon + gap1 + word_h + gap2 + tag_h)) / 2
    draw_icon(graphic, (width - icon) / 2, top, icon)
    draw_wordmark(graphic, (width - word_w) / 2, top + icon + gap1, word_w)
    ImageDraw.Draw(graphic).text(
        ((width - (tag_box[2] - tag_box[0])) / 2, top + icon + gap1 + word_h + gap2 - tag_box[1]),
        tagline,
        font=subtitle,
        fill=(196, 204, 218),
    )
    save(graphic.resize((1024, 500), Image.LANCZOS), out / "feature-graphic-1024x500.png")


def dart_paths():
    def dart_path(subpaths):
        lines = ["Path()", "    ..fillType = PathFillType.evenOdd"]
        for sp in subpaths:
            for c in sp:
                if c[0] == "M":
                    lines.append(f"    ..moveTo({num(c[1])}, {num(c[2])})")
                elif c[0] == "L":
                    lines.append(f"    ..lineTo({num(c[1])}, {num(c[2])})")
                elif c[0] == "C":
                    lines.append("    ..cubicTo(" + ", ".join(num(v) for v in c[1:]) + ")")
                else:
                    lines.append("    ..close()")
        return "\n".join(lines)

    # Unit coordinates need more precision than the 120dp vectors.
    global num
    coarse = num

    def fine(v):
        s = f"{v:.5f}".rstrip("0").rstrip(".")
        return "0" if s in ("-0", "") else s

    num = fine
    try:
        text = f"""// Generated by tool/generate_store_assets.py from
// Design/brand/stdy-hotels-logo.svg — do not edit by hand.

import 'dart:ui';

/// The STDY HOTELS artwork as vector paths, drawn by `brand_logo.dart`.
abstract final class BrandPaths {{
  /// Corner radius of the app-icon tile, as a fraction of its edge.
  static const double tileRadius = {fine(ART["tile_radius"])};

  /// The gold ring on the app-icon tile, in a 1×1 box (the tile).
  static final Path ring = {dart_path(ART["ring"])};

  /// Width of the wordmark when it is 1 unit tall.
  static const double wordmarkWidth = {fine(ART["word_width"])};

  /// The wordmark's letters (white on navy in the artwork), 1 unit tall.
  static final Path wordmarkLetters = {dart_path(ART["letters"])};

  /// The wordmark's gold "O", 1 unit tall.
  static final Path wordmarkAccent = {dart_path(ART["accent"])};
}}
"""
    finally:
        num = coarse
    write_text(ROOT / "lib/core/widgets/brand_paths.dart", text)


if __name__ == "__main__":
    android_icons()
    android_splash()
    ios_icons()
    ios_splash()
    web_icons()
    play_listing()
    dart_paths()
