from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

SIZE = 256
OUT = Path("flutter/windows/runner/resources/app_icon.ico")
OUT.parent.mkdir(parents=True, exist_ok=True)

# Transparent canvas with a premium rounded blue tile.
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
base = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
px = base.load()
for y in range(SIZE):
    for x in range(SIZE):
        t = (x + y) / (2 * (SIZE - 1))
        # Cyan-blue -> royal blue -> deep blue.
        if t < 0.5:
            u = t / 0.5
            c0, c1 = (100, 200, 255), (43, 124, 255)
        else:
            u = (t - 0.5) / 0.5
            c0, c1 = (43, 124, 255), (21, 88, 200)
        r = int(c0[0] + (c1[0] - c0[0]) * u)
        g = int(c0[1] + (c1[1] - c0[1]) * u)
        b = int(c0[2] + (c1[2] - c0[2]) * u)
        px[x, y] = (r, g, b, 255)

mask = Image.new("L", (SIZE, SIZE), 0)
md = ImageDraw.Draw(mask)
md.rounded_rectangle((12, 12, 244, 244), radius=62, fill=255)
base.putalpha(mask)

# Soft external glow.
glow = base.filter(ImageFilter.GaussianBlur(14))
glow.putalpha(glow.getchannel("A").point(lambda v: int(v * 0.32)))
img.alpha_composite(glow)
img.alpha_composite(base)

d = ImageDraw.Draw(img)

# Luminous A mark, visually matching the in-app Aproxia identity.
# Glow strokes first.
glow_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow_layer)
left = [(66, 190), (119, 65), (132, 51)]
right = [(132, 51), (193, 190)]
gd.line(left, fill=(96, 180, 255, 120), width=42, joint="curve")
gd.line(right, fill=(96, 180, 255, 120), width=42, joint="curve")
glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(10))
img.alpha_composite(glow_layer)

d = ImageDraw.Draw(img)
d.line(left, fill=(226, 246, 255, 255), width=28, joint="curve")
d.line(right, fill=(203, 235, 255, 255), width=28, joint="curve")
# Slight blue inner accents to avoid a flat white glyph.
d.line([(72, 188), (120, 76)], fill=(128, 211, 255, 255), width=9)
d.line([(140, 76), (188, 188)], fill=(96, 166, 255, 255), width=9)
# Crossbar.
d.line([(101, 145), (162, 145)], fill=(255, 255, 255, 255), width=16)

# Orbital connection sweep.
# Draw a lower arc using sampled Bezier points.
def bezier(p0, p1, p2, steps=48):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        pts.append((
            int(u*u*p0[0] + 2*u*t*p1[0] + t*t*p2[0]),
            int(u*u*p0[1] + 2*u*t*p1[1] + t*t*p2[1]),
        ))
    return pts

orbit = bezier((45, 188), (132, 238), (221, 130))
d.line(orbit, fill=(116, 218, 255, 235), width=9)

# Four-point sparkle.
cx, cy = 201, 50
d.line((cx, cy - 20, cx, cy + 20), fill=(220, 248, 255, 255), width=6)
d.line((cx - 20, cy, cx + 20, cy), fill=(220, 248, 255, 255), width=6)
d.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=(255, 255, 255, 255))

# Save true multi-resolution Windows ICO.
img.save(
    OUT,
    format="ICO",
    sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
)
print(f"Generated Aproxia icon: {OUT}")
