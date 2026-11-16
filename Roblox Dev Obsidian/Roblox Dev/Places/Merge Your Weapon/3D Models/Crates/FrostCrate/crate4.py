import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
STEEL, STEEL2, STRIPE = mat('C4Steel', '#8C97A6'), mat('C4Steel2', '#6E7888'), mat('C4Stripe', '#F2F5F8')
RIVET, GOLD, INSIDE = mat('C4Rivet', '#C9CED6'), mat('C4Gold', '#D6A63A'), mat('C4Inside', '#1E2026')
SNOW, ICE, ICE2, GLOW = mat('C4Snow', '#F7FAFD'), mat('C4Ice', '#A8DCF0'), mat('C4Ice2', '#D6F0FA'), mat('C4Glow', '#7FE8FF', 1.5)
W, D, H = 2.0, 1.7, 1.12
b = Obj('Body')
b.box(STEEL, (0, 0, H / 2), (W, D, H))
for x in (-0.75, -0.45, -0.15, 0.15, 0.45, 0.75): b.box(STEEL2, (x, -D / 2 - 0.02, H / 2), (0.1, 0.04, H - 0.2)).box(STEEL2, (x, D / 2 + 0.02, H / 2), (0.1, 0.04, H - 0.2))
b.box(STRIPE, (0, 0, 0.32), (W + 0.04, D + 0.04, 0.16))
for sx in (-1, 1):
    for sy in (-1, 1):
        b.box(STEEL2, (sx * (W / 2 - 0.02), sy * (D / 2 - 0.02), H / 2), (0.18, 0.18, H + 0.08))
        b.box(RIVET, (sx * (W / 2 + 0.07), sy * (D / 2 - 0.25), 0.9), (0.04, 0.1, 0.1))
b.box(STEEL2, (0, 0, 0.05), (W + 0.06, D + 0.06, 0.1))
b.box(GOLD, (0, -D / 2 - 0.07, 0.86), (0.36, 0.08, 0.42)).box(INSIDE, (0, -D / 2 - 0.115, 0.82), (0.08, 0.02, 0.14))
# frost on the corners + icicles along the bottom edge of the lid line
for sx in (-1, 1): b.box(ICE2, (sx * 0.9, -D / 2 - 0.03, 0.2), (0.3, 0.04, 0.4)).box(ICE2, (sx * 0.95, D / 2 + 0.03, 0.9), (0.2, 0.04, 0.3))
for x in (-0.7, -0.3, 0.35, 0.72): b.box(ICE, (x, -D / 2 - 0.05, H - 0.15 - abs(x) * 0.1), (0.1, 0.06, 0.3 + abs(x) * 0.2), taper=None)
b.box(INSIDE, (0, 0, H - 0.01), (W - 0.24, D - 0.24, 0.04))
b.build()
L = Obj('Lid')
L.box(STEEL, (0, 0, H + 0.14), (W + 0.06, D + 0.06, 0.28)).box(STEEL2, (0, 0, H + 0.03), (W + 0.1, D + 0.1, 0.08))
L.box(STRIPE, (0, 0, H + 0.2), (W + 0.08, 0.3, 0.3))
L.box(GOLD, (0, -D / 2 - 0.06, H + 0.1), (0.3, 0.06, 0.16))
# snow cap + glowing ice crystal on top
L.box(SNOW, (0, 0.05, H + 0.34), (W - 0.1, D - 0.2, 0.16)).box(SNOW, (-0.4, 0.1, H + 0.46), (0.9, 0.8, 0.12)).box(SNOW, (0.5, -0.2, H + 0.44), (0.6, 0.5, 0.1))
L.box(GLOW, (0.2, 0.15, H + 0.72), (0.26, 0.26, 0.6), rot=(10, 0, 20), taper=(0.4, 0.4)).box(ICE, (0.45, 0.25, H + 0.6), (0.18, 0.18, 0.36), rot=(0, 25, -25), taper=(0.4, 0.4))
L.box(ICE, (-0.05, 0.3, H + 0.58), (0.16, 0.16, 0.3), rot=(-20, 0, 15), taper=(0.4, 0.4))
L.build()
if '--export' in sys.argv: export('/home/claude/mobs4/out_models/myw_crate_zone4.glb')
print(render_preview('/home/claude/mobs4/out_models/c4.png', center=(0, 0, 0.9), dist=5.5))
