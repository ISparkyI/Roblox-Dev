import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
BODY, BODY2, EDGE = mat('C6Body', '#626A72'), mat('C6Body2', '#4E555C'), mat('C6Edge', '#33363B')
YEL, BLK, SYM = mat('C6Yellow', '#E8C22A'), mat('C6Black', '#1E1E1E'), mat('C6Sym', '#E8C22A')
GLOW, GLASS, OOZE, RIVET = mat('C6Glow', '#8CFF3A', 2.0), mat('C6Glass', '#CFEFE8'), mat('C6Ooze', '#5CD82A'), mat('C6Rivet', '#9A9EA4')
W, D, H = 2.0, 1.5, 1.12
b = Obj('Body')
b.box(BODY, (0, 0, H / 2), (W, D, H))
for sx in (-1, 1):
    for sy in (-1, 1): b.box(EDGE, (sx * (W / 2 - 0.02), sy * (D / 2 - 0.02), H / 2), (0.16, 0.16, H + 0.06))
b.box(BODY2, (0, 0, 0.1), (W + 0.04, D + 0.04, 0.16))
# hazard stripe band around the middle
b.box(BLK, (0, 0, 0.62), (W + 0.05, D + 0.05, 0.3))
for i in range(0, 9, 2):
    x = -0.88 + i * 0.22
    b.box(YEL, (x, -D / 2 - 0.045, 0.62), (0.22, 0.04, 0.3))
    b.box(YEL, (x, D / 2 + 0.045, 0.62), (0.22, 0.04, 0.3))
# toxic symbol on the front (yellow diamond, black drop)
b.box(SYM, (0, -D / 2 - 0.03, 0.27), (0.3, 0.04, 0.3), rot=(0, 45, 0)).box(BLK, (0, -D / 2 - 0.06, 0.26), (0.1, 0.03, 0.14))
# glowing vents on the sides
for sx in (-1, 1):
    for z in (0.32, 0.92): b.box(GLOW, (sx * (W / 2 + 0.03), 0, z), (0.04, 0.8, 0.07))
# ooze dripping down from the lid line
for x, l in ((-0.6, 0.35), (0.35, 0.22), (0.7, 0.45)): b.box(OOZE, (x, -D / 2 - 0.035, H - 0.05 - l / 2), (0.12, 0.03, l))
b.box(BODY2, (0, 0, H - 0.01), (W - 0.24, D - 0.24, 0.04))
b.build()
L = Obj('Lid')
L.box(BODY2, (0, 0, H + 0.13), (W + 0.06, D + 0.06, 0.26)).box(EDGE, (0, 0, H + 0.03), (W + 0.1, D + 0.1, 0.08))
L.box(EDGE, (0, -D / 2 - 0.05, H + 0.08), (0.34, 0.06, 0.2)).box(RIVET, (0, -D / 2 - 0.09, H + 0.08), (0.12, 0.04, 0.1))
# glowing canister in a cage on top
L.cyl(GLASS, (0, 0, H + 0.62), 0.3, 0.7, axis='Z', seg=10).cyl(GLOW, (0, 0, H + 0.58), 0.24, 0.52, axis='Z', seg=10)
L.cyl(EDGE, (0, 0, H + 0.32), 0.36, 0.1, axis='Z', seg=10).cyl(EDGE, (0, 0, H + 1.0), 0.36, 0.1, axis='Z', seg=10)
for a in range(4):
    import math
    x, y = math.cos(a * math.pi / 2 + 0.78) * 0.36, math.sin(a * math.pi / 2 + 0.78) * 0.36
    L.box(EDGE, (x, y, H + 0.66), (0.06, 0.06, 0.62))
L.box(YEL, (0.62, 0.3, H + 0.29), (0.4, 0.4, 0.04), rot=(0, 0, 45))
L.build()
if '--export' in sys.argv: export('/home/claude/mobs6/out_models/myw_crate_zone6.glb')
print(render_preview('/home/claude/mobs6/out_models/c6.png', center=(0, 0, 0.9), dist=5.5))
