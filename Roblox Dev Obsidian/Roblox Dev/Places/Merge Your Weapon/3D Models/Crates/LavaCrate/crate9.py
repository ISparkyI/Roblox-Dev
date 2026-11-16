import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
BODY, BODY2, EDGE = mat('C9Body', '#4A4244'), mat('C9Body2', '#352E30'), mat('C9Iron', '#2A2628')
RIVET, LAVA, LAVA2, OBS = mat('C9Rivet', '#8A8086'), mat('C9Lava', '#FF6A1A', 2.0), mat('C9Lava2', '#FFB43A', 2.0), mat('C9Obsidian', '#1A1420')
W, D, H = 2.0, 1.5, 1.12
b = Obj('Body')
b.box(BODY, (0, 0, H / 2), (W, D, H))
for sx in (-1, 1):
    for sy in (-1, 1): b.box(EDGE, (sx * (W / 2 - 0.02), sy * (D / 2 - 0.02), H / 2), (0.18, 0.18, H + 0.06))
b.box(EDGE, (0, 0, 0.1), (W + 0.04, D + 0.04, 0.16))
for x in (-0.75, 0.75):
    for z in (0.35, 0.85): b.box(RIVET, (x, -D / 2 - 0.05, z), (0.08, 0.04, 0.08))
# glowing lava cracks on the front / sides
b.box(LAVA, (-0.35, -D / 2 - 0.015, 0.65), (0.08, 0.03, 0.6), rot=(0, 30, 0)).box(LAVA, (-0.1, -D / 2 - 0.015, 0.4), (0.5, 0.03, 0.08), rot=(0, -10, 0))
b.box(LAVA, (0.45, -D / 2 - 0.015, 0.75), (0.08, 0.03, 0.5), rot=(0, -25, 0))
for sx in (-1, 1): b.box(LAVA, (sx * (W / 2 + 0.015), 0.1, 0.6), (0.03, 0.08, 0.7), rot=(25 * sx, 0, 0))
# flame emblem (obsidian plate with a lava flame)
b.box(OBS, (0, -D / 2 - 0.04, 0.6), (0.6, 0.06, 0.6), rot=(0, 45, 0))
b.box(LAVA2, (0, -D / 2 - 0.08, 0.56), (0.2, 0.04, 0.3)).box(LAVA, (0, -D / 2 - 0.08, 0.72), (0.12, 0.04, 0.16))
b.box(BODY2, (0, 0, H - 0.01), (W - 0.24, D - 0.24, 0.04))
b.build()
L = Obj('Lid')
L.box(BODY2, (0, 0, H + 0.13), (W + 0.06, D + 0.06, 0.26)).box(EDGE, (0, 0, H + 0.03), (W + 0.1, D + 0.1, 0.08))
L.box(EDGE, (0, -D / 2 - 0.05, H + 0.08), (0.34, 0.06, 0.2)).box(RIVET, (0, -D / 2 - 0.09, H + 0.08), (0.12, 0.04, 0.1))
# lava seam across the lid + obsidian shards
L.box(LAVA, (0, 0, H + 0.27), (W - 0.3, 0.12, 0.03)).box(LAVA2, (0, 0, H + 0.28), (0.5, 0.2, 0.03))
for x, a in ((-0.6, 20), (0.6, -25)): L.box(OBS, (x, 0.35, H + 0.42), (0.22, 0.22, 0.4), rot=(15, a, 0), taper=(0.3, 0.3))
L.build()
if '--export' in sys.argv: export('/home/claude/mobs9/out_models/myw_crate_zone9.glb')
print(render_preview('/home/claude/mobs9/out_models/c9.png', center=(0, 0, 0.9), dist=5.5))
