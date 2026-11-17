import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
WOOD, WOOD2, PLANK = mat('C3Wood', '#9A5A34'), mat('C3Wood2', '#B06C40'), mat('C3Plank', '#6E3E22')
IRON, IRON2, RIVET = mat('C3Iron', '#4A4F58'), mat('C3Iron2', '#6A707C'), mat('C3Rivet', '#9AA0AA')
GOLD, INSIDE = mat('C3Gold', '#D6A63A'), mat('C3Inside', '#1E140C')
COAL, COPPER, IRONORE, GEM = mat('C3Coal', '#2A2A30'), mat('C3Copper', '#E8783A'), mat('C3IronOre', '#E3C6A6'), mat('C3Gem', '#4FC2E8', 1.5)
TNT, WICK, SAND = mat('C3TNT', '#D8352A'), mat('C3Wick', '#E8D8A8'), mat('C3Sand', '#D9AE78')
W, D, H = 2.0, 1.7, 1.12
b = Obj('Body')
b.box(WOOD, (0, 0, H / 2), (W, D, H))
for z in (0.3, 0.62, 0.92): b.box(PLANK, (0, -D / 2 - 0.01, z), (W - 0.1, 0.03, 0.05)).box(PLANK, (0, D / 2 + 0.01, z), (W - 0.1, 0.03, 0.05))
# two thick steel bands all around + rivets
for x in (-0.6, 0.6):
    b.box(IRON, (x, 0, H / 2), (0.26, D + 0.08, H + 0.06))
    for z in (0.22, 0.56, 0.9): b.box(RIVET, (x, -D / 2 - 0.05, z), (0.09, 0.03, 0.09)).box(RIVET, (x, D / 2 + 0.05, z), (0.09, 0.03, 0.09))
b.box(IRON2, (0, 0, 0.06), (W + 0.06, D + 0.06, 0.12)).box(IRON2, (0, 0, H - 0.05), (W + 0.06, D + 0.06, 0.1))
for sx in (-1, 1):
    for sy in (-1, 1): b.box(IRON, (sx * (W / 2 - 0.02), sy * (D / 2 - 0.02), H / 2), (0.16, 0.16, H + 0.08))
# lock + "danger" stencil stick + sand dust
b.box(GOLD, (0, -D / 2 - 0.07, 0.86), (0.36, 0.08, 0.42)).box(INSIDE, (0, -D / 2 - 0.115, 0.82), (0.08, 0.02, 0.14))
b.cyl(TNT, (0.92, -0.35, 0.3), 0.11, 0.55, axis='Z', seg=8).box(WICK, (0.92, -0.35, 0.65), (0.05, 0.05, 0.16))
b.cyl(TNT, (1.06, -0.15, 0.25), 0.11, 0.45, axis='Z', seg=8)
b.box(SAND, (-0.7, -D / 2 - 0.02, 0.12), (0.5, 0.05, 0.2)).box(SAND, (0.3, D / 2 + 0.02, 0.1), (0.7, 0.05, 0.18))
b.box(INSIDE, (0, 0, H - 0.01), (W - 0.24, D - 0.24, 0.04))
b.build()
L = Obj('Lid')
L.box(WOOD2, (0, 0, H + 0.14), (W + 0.06, D + 0.06, 0.28)).box(WOOD2, (0, 0, H + 0.34), (W + 0.02, D - 0.3, 0.16), taper=(1, 0.72))
for x in (-0.6, 0.6): L.box(IRON, (x, 0, H + 0.2), (0.26, D + 0.1, 0.4))
L.box(IRON2, (0, 0, H + 0.03), (W + 0.1, D + 0.1, 0.08))
L.box(GOLD, (0, -D / 2 - 0.06, H + 0.1), (0.3, 0.06, 0.16))
# ore chunks piled on the lid: coal, copper, iron + a glowing gem
L.box(COAL, (-0.35, 0.05, H + 0.52), (0.42, 0.36, 0.3), rot=(10, 0, 25)).box(COAL, (-0.62, -0.18, H + 0.48), (0.26, 0.24, 0.2), rot=(0, 15, 40))
L.box(COPPER, (0.15, 0.12, H + 0.54), (0.34, 0.3, 0.28), rot=(0, -12, 15)).box(COPPER, (0.42, -0.1, H + 0.47), (0.22, 0.2, 0.16), rot=(20, 0, -30))
L.box(IRONORE, (-0.05, -0.2, H + 0.5), (0.26, 0.22, 0.2), rot=(15, 10, 0))
L.box(GEM, (0.3, 0.28, H + 0.62), (0.2, 0.2, 0.3), rot=(0, 0, 45))
L.build()
if '--export' in sys.argv:
    export('/home/claude/mobs3/out_models/myw_crate_zone3.glb')
print(render_preview('/home/claude/mobs3/out_models/c3.png', center=(0, 0, 0.9), dist=5.5))
