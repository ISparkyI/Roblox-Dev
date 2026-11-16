import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
SKIN, SKIN2 = mat('Z2Skin', '#7FA864'), mat('Z2Skin2', '#5F8549')
RED, RED2, PLAID = mat('LJFlannel', '#B3261E'), mat('LJFlannel2', '#7E1A15'), mat('LJPlaid', '#261313')
BELT, BRASS, STRAP = mat('LJBelt', '#4A2A12'), mat('LJBrass', '#C9A227'), mat('LJStrap', '#3B2210')
JEANS, JEANS2, BOOT, SOLE, LACE = mat('LJJeans', '#2F4A78'), mat('LJJeans2', '#4C6AA0'), mat('LJBoot', '#5A3A1E'), mat('LJSole', '#24170C'), mat('LJLace', '#C9A86A')
BEANIE, BEANIE2, POM = mat('LJBeanie', '#D2491F'), mat('LJBeanie2', '#A8331A'), mat('LJPom', '#EDE3C8')
BEARD, DARK, EYE, TEETH, MOUTH = mat('LJBeard', '#C0602A'), mat('Z2Dark', '#141620'), mat('Z2Eye', '#F2D23A', 2.0), mat('Z2Teeth', '#E8E6DA'), mat('Z2Mouth', '#2A1510')
WOOD, STEEL, EDGE, IRON = mat('LJWood', '#8A5A2E'), mat('LJAxeRed', '#B02A20'), mat('LJEdge', '#C9CED6'), mat('LJIron', '#4A4E57')

# ---------- torso ----------
t = Obj('Torso')
t.box(RED, (0, 0, 3.05), (2.04, 1.1, 2.1))
for sy in (-0.565, 0.565):
    for x in (-0.5, 0.5): t.box(PLAID, (x, sy, 3.05), (0.22, 0.04, 2.08))
    for z in (2.55, 3.55): t.box(PLAID, (0, sy, z), (2.06, 0.04, 0.2))
for sx in (-1.03, 1.03):
    t.box(PLAID, (sx, 0, 3.05), (0.04, 0.22, 2.08))
    for z in (2.55, 3.55): t.box(PLAID, (sx, 0, z), (0.04, 1.12, 0.2))
t.box(RED2, (0.5, -0.585, 3.62), (0.44, 0.04, 0.4)).box(RED2, (0.5, -0.6, 3.82), (0.48, 0.05, 0.12))   # pocket + flap
t.box(SKIN, (-0.66, -0.57, 2.5), (0.32, 0.03, 0.26))                                                   # torn hole
t.box(RED2, (-0.3, -0.5, 4.08), (0.42, 0.24, 0.12), rot=(0, 0, 22)).box(RED2, (0.3, -0.5, 4.08), (0.42, 0.24, 0.12), rot=(0, 0, -22))
t.box(BELT, (0, 0, 2.12), (2.1, 1.16, 0.22)).box(BRASS, (0, -0.6, 2.12), (0.34, 0.06, 0.24))
for x in (-0.58, 0.58):
    t.box(STRAP, (x, -0.59, 3.12), (0.2, 0.05, 1.88)).box(STRAP, (x, 0.59, 3.12), (0.2, 0.05, 1.88)).box(STRAP, (x, 0, 4.11), (0.2, 1.2, 0.05))
    t.box(BRASS, (x, -0.62, 3.95), (0.14, 0.04, 0.14))
t.build()

# ---------- head ----------
h = Obj('Head')
h.box(SKIN, (0, 0, 4.85), (1.62, 1.5, 1.6))
h.box(SKIN2, (0, -0.8, 4.8), (0.24, 0.14, 0.32))                       # nose
for x in (-0.84, 0.84): h.box(SKIN2, (x, 0.05, 4.9), (0.1, 0.32, 0.36))   # ears
h.box(DARK, (-0.38, -0.765, 5.05), (0.44, 0.04, 0.38)).box(EYE, (-0.36, -0.785, 5.03), (0.16, 0.03, 0.16))
h.box(DARK, (0.38, -0.765, 5.0), (0.44, 0.04, 0.13)).box(EYE, (0.4, -0.785, 5.0), (0.12, 0.03, 0.07))
h.box(BEARD, (-0.38, -0.775, 5.3), (0.48, 0.05, 0.1), rot=(0, 12, 0)).box(BEARD, (0.38, -0.775, 5.19), (0.5, 0.05, 0.13), rot=(0, -14, 0))
h.box(BEARD, (0, -0.79, 4.33), (1.56, 0.16, 0.6), taper=(0.95, 1)).box(BEARD, (0, -0.84, 4.02), (1.0, 0.22, 0.42))
h.box(BEARD, (0.15, -0.86, 3.86), (0.4, 0.18, 0.3))
for x in (-0.79, 0.79): h.box(BEARD, (x, -0.45, 4.55), (0.08, 0.42, 0.55))
h.box(MOUTH, (0, -0.875, 4.5), (0.62, 0.04, 0.15)).box(TEETH, (-0.14, -0.89, 4.53), (0.13, 0.03, 0.1)).box(TEETH, (0.17, -0.89, 4.51), (0.13, 0.03, 0.08))
h.build()
c = Obj('Hat')  # beanie
c.box(BEANIE, (0, 0.02, 5.56), (1.72, 1.6, 0.52), taper=(0.9, 0.9)).box(BEANIE2, (0, 0.02, 5.33), (1.76, 1.64, 0.22))
for x in (-0.55, -0.18, 0.18, 0.55): c.box(BEANIE2, (x, -0.81, 5.6), (0.12, 0.04, 0.4))   # knit ribs
c.box(POM, (0, 0.06, 5.96), (0.44, 0.44, 0.38))
c.build()

# ---------- arms ----------
def arm(name, sx, torn):
    a = Obj(name); x = 1.45 * sx
    a.box(RED, (x, 0, 3.45), (1.04, 1.04, 1.1))
    a.box(PLAID, (x, -0.525, 3.45), (0.22, 0.04, 1.08)).box(PLAID, (x, 0.525, 3.45), (0.22, 0.04, 1.08)).box(PLAID, (x, 0, 3.3), (1.06, 1.06, 0.18))
    if torn:
        for i, dz in enumerate((0.0, 0.1, -0.05, 0.08)):
            a.box(RED, (x - 0.36 + i * 0.24, -0.53, 2.82 + dz), (0.18, 0.04, 0.22))
    else:
        a.box(RED2, (x, 0, 2.86), (1.1, 1.1, 0.24))
    a.box(SKIN, (x, 0, 2.2), (0.88, 0.88, 1.12))
    a.box(SKIN2, (x, 0, 1.56), (0.92, 0.92, 0.34))
    for dx in (-0.28, 0, 0.28): a.box(SKIN2, (x + dx, -0.12, 1.3), (0.22, 0.55, 0.3))
    a.build()
arm('RightArm', 1, False); arm('LeftArm', -1, True)

# ---------- legs ----------
def leg(name, sx, patch):
    l = Obj(name); x = 0.52 * sx
    l.box(JEANS, (x, 0, 1.32), (1.02, 1.08, 1.36))
    l.box(JEANS2, (x, -0.545, 1.4), (0.05, 0.03, 1.2))
    if patch: l.box(JEANS2, (x, -0.56, 1.12), (0.42, 0.03, 0.38))
    l.box(JEANS2, (x, 0, 0.64), (1.08, 1.14, 0.16))
    l.box(BOOT, (x, -0.08, 0.3), (1.06, 1.28, 0.54)).box(SOLE, (x, -0.08, 0.05), (1.1, 1.34, 0.1))
    for z in (0.34, 0.48): l.box(LACE, (x, -0.735, z), (0.42, 0.03, 0.06))
    l.build()
leg('RightLeg', 1, False); leg('LeftLeg', -1, True)

# ---------- axe (right hand, handle points forward like a Roblox tool, blade faces down = hits in the chop) ----------
ax = Obj('Axe', bevel=0.02)
ax.box(WOOD, (1.45, -0.95, 1.46), (0.2, 2.5, 0.2))
ax.box(BELT, (1.45, -0.05, 1.46), (0.24, 0.5, 0.24))          # grip wrap
ax.box(IRON, (1.45, -2.0, 1.5), (0.28, 0.42, 0.42))
ax.box(STEEL, (1.45, -2.0, 1.08), (0.22, 0.5, 0.5), taper=(1, 1))
ax.box(EDGE, (1.45, -2.0, 0.78), (0.16, 0.72, 0.16))
ax.box(IRON, (1.45, -2.0, 1.78), (0.24, 0.28, 0.18))
ax.build()

import sys
if '--export' in sys.argv:
    export('/home/claude/mobs2/out_models/myw_zombielumberjack.glb')
    bpy.ops.wm.save_as_mainfile(filepath='/home/claude/mobs2/out_models/myw_zombielumberjack.blend')
print(render_preview('/home/claude/mobs2/out_models/lj.png'))
