import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
SKIN, SKIN2 = mat('Z10Skin', '#8AA0A8'), mat('Z10Skin2', '#6A8088')
COAT, COAT2, SHIRT, TIE = mat('LACoat', '#E8ECF0'), mat('LACoat2', '#C8CED6'), mat('LAShirt', '#6A9AD8'), mat('LATie', '#2A3A6A')
PANTS, SHOE, BADGE, STAIN = mat('LAPants', '#3A3E48'), mat('LAShoe', '#1E1E22'), mat('LABadge', '#3AE8FF', 2.0), mat('LAStain', '#6CF04A', 1.5)
GOG, LENS, DARK, EYE, TEETH, MOUTH, BLOOD = mat('LAGoggle', '#2A2E34'), mat('LALens', '#9AF4FF', 2.0), mat('Z10Dark', '#141620'), mat('LAEye', '#6CF04A', 2.5), mat('Z10Teeth', '#E2DFC8'), mat('Z10Mouth', '#2A1510'), mat('Z10Blood', '#7A2E22')
BOARD, PAPER, CLIP, GLASS, FLUID, STEEL = mat('LABoard', '#8A6A42'), mat('LAPaper', '#F2EEDC'), mat('LAClip', '#9AA0A8'), mat('LASyringeGlass', '#D8F0FF'), mat('LAFluid', '#6CF04A', 2.0), mat('LASteel', '#C9CED6')
t = Obj('Torso')
t.box(SHIRT, (0, 0, 3.05), (2.0, 1.08, 2.1))
t.box(TIE, (0, -0.56, 3.35), (0.22, 0.04, 1.1))
t.box(COAT, (-0.66, 0, 3.0), (0.72, 1.16, 2.18)).box(COAT, (0.66, 0, 3.0), (0.72, 1.16, 2.18))      # open lab coat
t.box(COAT, (0, 0.06, 3.0), (2.08, 1.06, 2.18))
t.box(COAT2, (-0.66, -0.6, 2.4), (0.5, 0.04, 0.4)).box(COAT2, (0.66, -0.6, 2.4), (0.5, 0.04, 0.4))   # pockets
t.box(BADGE, (0.6, -0.6, 3.6), (0.34, 0.04, 0.24))
t.box(STAIN, (-0.6, -0.6, 2.9), (0.4, 0.03, 0.3)).box(BLOOD, (0.45, -0.6, 2.75), (0.3, 0.03, 0.4))
t.box(COAT, (0, 0, 1.75), (2.12, 1.2, 0.5))                                                           # coat tails
t.build()
h = Obj('Head')
h.box(SKIN, (0, 0, 4.85), (1.58, 1.46, 1.56))
h.box(SKIN2, (0, -0.79, 4.75), (0.24, 0.14, 0.3))
for x in (-0.36, 0.36): h.box(DARK, (x, -0.74, 4.98), (0.42, 0.04, 0.3)).box(EYE, (x, -0.765, 4.98), (0.16, 0.03, 0.12))
h.box(MOUTH, (0, -0.74, 4.42), (0.8, 0.04, 0.2))
for x in (-0.25, 0.25): h.box(TEETH, (x, -0.755, 4.46), (0.12, 0.03, 0.1))
h.box(BLOOD, (-0.55, -0.75, 4.55), (0.2, 0.03, 0.3))
h.build()
c = Obj('Hat')   # goggles pushed up on the forehead + messy hair
c.box(SKIN2, (0, 0.05, 5.7), (1.62, 1.5, 0.2))
c.box(GOG, (0, 0, 5.42), (1.66, 1.54, 0.22))
for x in (-0.36, 0.36): c.box(GOG, (x, -0.8, 5.45), (0.52, 0.12, 0.42)).box(LENS, (x, -0.87, 5.45), (0.4, 0.04, 0.3))
c.build()
def arm(name, sx):
    a = Obj(name); x = 1.47 * sx
    a.box(COAT, (x, 0, 3.0), (1.06, 1.06, 2.2)).box(COAT2, (x, 0, 2.0), (1.1, 1.1, 0.2))
    a.box(SKIN, (x, 0, 1.6), (0.9, 0.9, 0.6))
    for dx in (-0.28, 0, 0.28): a.box(SKIN2, (x + dx, -0.12, 1.25), (0.22, 0.55, 0.3))
    a.build()
arm('RightArm', 1); arm('LeftArm', -1)
def leg(name, sx):
    l = Obj(name); x = 0.52 * sx
    l.box(PANTS, (x, 0, 1.15), (1.04, 1.1, 1.7))
    l.box(SHOE, (x, -0.08, 0.2), (1.08, 1.3, 0.4))
    l.build()
leg('RightLeg', 1); leg('LeftLeg', -1)
s = Obj('Syringe', bevel=0.02)
X, Z = 1.47, 1.3
s.box(GLASS, (X, -0.7, Z), (0.34, 1.2, 0.34)).box(FLUID, (X, -0.8, Z), (0.26, 0.8, 0.26))
s.box(STEEL, (X, 0.0, Z), (0.5, 0.12, 0.5)).box(STEEL, (X, -1.6, Z), (0.06, 0.7, 0.06))
s.build()
b = Obj('Clipboard', bevel=0.02)
X = -1.47
b.box(BOARD, (X, -0.55, Z + 0.1), (0.1, 1.0, 1.3)).box(PAPER, (X - 0.06, -0.55, Z + 0.05), (0.04, 0.84, 1.1)).box(CLIP, (X - 0.08, -0.55, Z + 0.68), (0.06, 0.4, 0.12))
b.build()
if '--export' in sys.argv: export('/home/claude/mobs10/out_models/myw_zombielabassistant.glb')
print(render_preview('/home/claude/mobs10/out_models/la.png', center=(0, 0, 3.2), dist=12))
