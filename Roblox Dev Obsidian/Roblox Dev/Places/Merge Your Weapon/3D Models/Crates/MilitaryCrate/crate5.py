import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
OD, OD2, OD3 = mat('C5Olive', '#5F6B3A'), mat('C5Olive2', '#4A5430'), mat('C5Olive3', '#738050')
STEEL, RIVET, STENCIL, STAR = mat('C5Steel', '#3A3C40'), mat('C5Rivet', '#9A9C9E'), mat('C5Stencil', '#E8DFA8'), mat('C5Star', '#E8C24A')
INSIDE, BRASS, BRASS2, TIP = mat('C5Inside', '#1E2026'), mat('C5Brass', '#D8B04A'), mat('C5Brass2', '#A8842E'), mat('C5Tip', '#B87333')
STRAP, GLOW = mat('C5Strap', '#3A3424'), mat('C5Glow', '#FFB43A', 1.5)
W, D, H = 2.0, 1.5, 1.12
b = Obj('Body')
b.box(OD, (0, 0, H / 2), (W, D, H))
# ribs / steel corners / handles
for sx in (-1, 1):
    for sy in (-1, 1):
        b.box(STEEL, (sx * (W / 2 - 0.02), sy * (D / 2 - 0.02), H / 2), (0.16, 0.16, H + 0.06))
    b.box(STEEL, (sx * (W / 2 + 0.06), 0, 0.72), (0.08, 0.6, 0.12)).box(STEEL, (sx * (W / 2 + 0.06), -0.26, 0.6), (0.08, 0.08, 0.3)).box(STEEL, (sx * (W / 2 + 0.06), 0.26, 0.6), (0.08, 0.08, 0.3))
b.box(OD2, (0, 0, 0.12), (W + 0.04, D + 0.04, 0.2)).box(OD2, (0, 0, H - 0.12), (W + 0.04, D + 0.04, 0.12))
# stencil on the front: star + "bars"
b.box(STAR, (0, -D / 2 - 0.02, 0.62), (0.34, 0.04, 0.34), rot=(0, 45, 0))
for x in (-0.62, -0.5, 0.5, 0.62): b.box(STENCIL, (x, -D / 2 - 0.02, 0.62), (0.07, 0.03, 0.4))
b.box(STENCIL, (0, -D / 2 - 0.02, 0.3), (1.2, 0.03, 0.08))
# straps across
for x in (-0.55, 0.55): b.box(STRAP, (x, 0, H / 2), (0.16, D + 0.06, H + 0.04))
for x in (-0.55, 0.55): b.box(RIVET, (x, -D / 2 - 0.05, 0.9), (0.1, 0.04, 0.1))
b.box(INSIDE, (0, 0, H - 0.01), (W - 0.24, D - 0.24, 0.04))
b.build()
L = Obj('Lid')
L.box(OD3, (0, 0, H + 0.13), (W + 0.06, D + 0.06, 0.26)).box(OD2, (0, 0, H + 0.03), (W + 0.1, D + 0.1, 0.08))
for x in (-0.55, 0.55): L.box(STRAP, (x, 0, H + 0.15), (0.16, D + 0.1, 0.3))
L.box(STEEL, (0, -D / 2 - 0.05, H + 0.08), (0.34, 0.06, 0.2)).box(RIVET, (0, -D / 2 - 0.09, H + 0.08), (0.12, 0.04, 0.1))
L.box(STENCIL, (0, 0, H + 0.27), (0.9, 0.5, 0.02))
L.box(STAR, (0, 0, H + 0.29), (0.32, 0.32, 0.03), rot=(0, 0, 45))
# ammo on the lid: a few big shells + a glowing tracer belt
for i, x in enumerate((-0.75, -0.45)):
    L.cyl(BRASS, (x, 0.35, H + 0.42), 0.12, 0.5, axis='Y', seg=8).cyl(TIP, (x, 0.05, H + 0.42), 0.1, 0.16, axis='Y', seg=8)
for k in range(6):
    L.box(BRASS2 if k % 2 else BRASS, (0.25 + k * 0.12, -0.1 + k * 0.03, H + 0.34), (0.08, 0.3, 0.1), rot=(0, 0, 15))
L.box(GLOW, (0.85, 0.15, H + 0.36), (0.14, 0.14, 0.14))
L.build()
if '--export' in sys.argv: export('/home/claude/mobs5/out_models/myw_crate_zone5.glb')
print(render_preview('/home/claude/mobs5/out_models/c5.png', center=(0, 0, 0.9), dist=5.5))
