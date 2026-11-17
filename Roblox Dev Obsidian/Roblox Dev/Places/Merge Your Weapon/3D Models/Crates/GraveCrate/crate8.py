import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
BODY, BODY2, EDGE = mat('C8Body', '#4A3450'), mat('C8Body2', '#36243C'), mat('C8Iron', '#2A2A32')
RIVET, BONE, BONE2, DARK = mat('C8Rivet', '#8A8A96'), mat('C8Bone', '#E8E0C8'), mat('C8Bone2', '#C8BCA0'), mat('C8Dark', '#140C1A')
GLOW, GLOW2, MOSS = mat('C8Glow', '#B05AFF', 2.0), mat('C8Glow2', '#D08AFF', 2.0), mat('C8Moss', '#4A6A42')
W, D, H = 2.0, 1.5, 1.12
b = Obj('Body')
b.box(BODY, (0, 0, H / 2), (W, D, H))
for z in (0.32, 0.62, 0.92): b.box(BODY2, (0, -D / 2 - 0.015, z), (W - 0.1, 0.03, 0.05))   # plank gaps
for sx in (-1, 1):
    for sy in (-1, 1): b.box(EDGE, (sx * (W / 2 - 0.02), sy * (D / 2 - 0.02), H / 2), (0.18, 0.18, H + 0.06))
b.box(EDGE, (0, 0, 0.1), (W + 0.04, D + 0.04, 0.16))
for x in (-0.75, 0.75):
    for z in (0.3, 0.85): b.box(RIVET, (x, -D / 2 - 0.05, z), (0.08, 0.04, 0.08))
# skull emblem on the front with glowing eyes
b.box(BONE, (0, -D / 2 - 0.06, 0.62), (0.5, 0.06, 0.44)).box(BONE2, (0, -D / 2 - 0.06, 0.34), (0.32, 0.06, 0.14))
for x in (-0.11, 0.11): b.box(GLOW, (x, -D / 2 - 0.1, 0.65), (0.1, 0.03, 0.1))
b.box(DARK, (0, -D / 2 - 0.1, 0.5), (0.06, 0.03, 0.08))
# crossed bones behind the skull
b.box(BONE2, (0, -D / 2 - 0.035, 0.55), (0.9, 0.03, 0.1), rot=(0, 30, 0)).box(BONE2, (0, -D / 2 - 0.045, 0.55), (0.9, 0.03, 0.1), rot=(0, -30, 0))
# moss on the bottom edge, rune on the sides
b.box(MOSS, (-0.5, -D / 2 - 0.04, 0.2), (0.6, 0.06, 0.12))
for sx in (-1, 1): b.box(GLOW2, (sx * (W / 2 + 0.03), 0, 0.6), (0.03, 0.3, 0.3), rot=(45, 0, 0))
b.box(BODY2, (0, 0, H - 0.01), (W - 0.24, D - 0.24, 0.04))
b.build()
L = Obj('Lid')
L.box(BODY2, (0, 0, H + 0.13), (W + 0.06, D + 0.06, 0.26)).box(EDGE, (0, 0, H + 0.03), (W + 0.1, D + 0.1, 0.08))
L.box(EDGE, (0, -D / 2 - 0.05, H + 0.08), (0.34, 0.06, 0.2)).box(RIVET, (0, -D / 2 - 0.09, H + 0.08), (0.12, 0.04, 0.1))
# stone cross lying on the lid + glowing rune ring
L.box(BONE2, (0, 0, H + 0.31), (0.22, 1.1, 0.1)).box(BONE2, (0, 0.2, H + 0.31), (0.7, 0.2, 0.1))
L.box(GLOW, (0, 0.2, H + 0.37), (0.12, 0.12, 0.03))
for sx in (-1, 1): L.box(GLOW2, (sx * 0.7, 0.35, H + 0.28), (0.16, 0.16, 0.04), rot=(0, 0, 45))
L.build()
if '--export' in sys.argv: export('/home/claude/mobs8/out_models/myw_crate_zone8.glb')
print(render_preview('/home/claude/mobs8/out_models/c8.png', center=(0, 0, 0.9), dist=5.5))
