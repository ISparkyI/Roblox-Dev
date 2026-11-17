import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
BODY, BODY2, EDGE = mat('C7Body', '#3A4A6A'), mat('C7Body2', '#2A3650'), mat('C7Edge', '#1E2434')
TAPE, TAPE2, RIVET, GOLD = mat('C7Tape', '#F2D22A'), mat('C7TapeText', '#1E1E1E'), mat('C7Rivet', '#9AA0AA'), mat('C7Gold', '#E8C24A')
RED, BLUE, DIAL, DIAL2 = mat('C7Red', '#FF3A3A', 2.0), mat('C7Blue', '#3A6AFF', 2.0), mat('C7Dial', '#C9CDD2'), mat('C7Dial2', '#5A6068')
W, D, H = 2.0, 1.5, 1.12
b = Obj('Body')
b.box(BODY, (0, 0, H / 2), (W, D, H))
for sx in (-1, 1):
    for sy in (-1, 1): b.box(EDGE, (sx * (W / 2 - 0.02), sy * (D / 2 - 0.02), H / 2), (0.18, 0.18, H + 0.06))
b.box(BODY2, (0, 0, 0.1), (W + 0.04, D + 0.04, 0.16))
for x in (-0.6, 0, 0.6):
    for z in (0.3, 0.85): b.box(RIVET, (x, -D / 2 - 0.03, z), (0.08, 0.04, 0.08))
# safe dial on the front
b.cyl(DIAL2, (0.45, -D / 2 - 0.04, 0.55), 0.22, 0.06, axis='Y', seg=12).cyl(DIAL, (0.45, -D / 2 - 0.09, 0.55), 0.15, 0.06, axis='Y', seg=12)
b.box(DIAL2, (-0.4, -D / 2 - 0.05, 0.55), (0.5, 0.06, 0.12))
# police tape wrapped across the crate (diagonal on the front, around the sides)
b.box(TAPE, (0, -D / 2 - 0.06, 0.6), (2.3, 0.03, 0.22), rot=(0, -20, 0))
b.box(TAPE, (W / 2 + 0.03, 0, 0.45), (0.03, D + 0.06, 0.22)).box(TAPE, (-W / 2 - 0.03, 0, 0.75), (0.03, D + 0.06, 0.22))
b.box(BODY2, (0, 0, H - 0.01), (W - 0.24, D - 0.24, 0.04))
b.build()
L = Obj('Lid')
L.box(BODY2, (0, 0, H + 0.13), (W + 0.06, D + 0.06, 0.26)).box(EDGE, (0, 0, H + 0.03), (W + 0.1, D + 0.1, 0.08))
L.box(EDGE, (0, -D / 2 - 0.05, H + 0.08), (0.34, 0.06, 0.2)).box(RIVET, (0, -D / 2 - 0.09, H + 0.08), (0.12, 0.04, 0.1))
L.box(GOLD, (0, 0, H + 0.28), (0.5, 0.5, 0.04), rot=(0, 0, 45)).box(BODY, (0, 0, H + 0.31), (0.2, 0.2, 0.04), rot=(0, 0, 45))
# siren light bar on the lid
L.box(EDGE, (0, 0.35, H + 0.33), (1.2, 0.3, 0.1)).box(RED, (-0.3, 0.35, H + 0.47), (0.5, 0.26, 0.2)).box(BLUE, (0.3, 0.35, H + 0.47), (0.5, 0.26, 0.2))
L.build()
if '--export' in sys.argv: export('/home/claude/mobs7/out_models/myw_crate_zone7.glb')
print(render_preview('/home/claude/mobs7/out_models/c7.png', center=(0, 0, 0.9), dist=5.5))
