import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
SKIN, SKIN2 = mat('Z5Skin', '#7FA55A'), mat('Z5Skin2', '#5C7F3E')
SHIRT, SHIRT2 = mat('MGShirt', '#6E7A48'), mat('MGShirt2', '#56603A')
VEST, VEST2, PLATE = mat('MGVest', '#3E4628'), mat('MGVest2', '#2E341E'), mat('MGPlate', '#5A6438')
BRASS, BRASS2, LINK = mat('MGBrass', '#D8B04A'), mat('MGBrass2', '#A8842E'), mat('MGLink', '#3A3C40')
BAND, BAND2 = mat('MGBandana', '#B8322A'), mat('MGBandana2', '#8A2420')
HELM, HELM2, GOG, LENS = mat('MGHelm', '#4E5A30'), mat('MGHelm2', '#3B4424'), mat('MGGoggle', '#2B2D33'), mat('MGLens', '#E89A3A')
PANTS, PANTS2, BOOT, SOLE, BELT = mat('MGPants', '#4C5630'), mat('MGPants2', '#3A4126'), mat('MGBoot', '#22221E'), mat('MGSole', '#121210'), mat('MGBelt', '#3A3424')
DARK, EYE, TEETH, MOUTH, BLOOD = mat('Z5Dark', '#141620'), mat('MGEye', '#FFD84A', 2.5), mat('Z5Teeth', '#E2DFC8'), mat('Z5Mouth', '#2A1510'), mat('Z5Wound', '#7A2E22')
GUN, GUN2, GUN3 = mat('MGGun', '#2A2C30'), mat('MGGun2', '#3C3F45'), mat('MGGun3', '#5A5E66')
t = Obj('Torso')
t.box(SHIRT, (0, 0, 3.05), (2.08, 1.14, 2.1))
t.box(VEST, (0, 0, 3.1), (2.16, 1.26, 1.7)).box(PLATE, (0, -0.66, 3.25), (1.3, 0.06, 1.0))
for x in (-0.7, 0.7): t.box(VEST2, (x, -0.68, 2.55), (0.5, 0.14, 0.5))
# ammo belt across the chest (bandolier)
for i in range(9):
    f = i / 8
    x, z = -0.95 + 1.9 * f, 3.85 - 1.55 * f
    t.box(LINK, (x, -0.68, z), (0.24, 0.06, 0.2), rot=(0, 39, 0))
    t.box(BRASS if i % 2 == 0 else BRASS2, (x, -0.74, z + 0.02), (0.1, 0.12, 0.3), rot=(0, 39, 0))
t.box(BELT, (0, 0, 2.15), (2.2, 1.28, 0.24)).box(BRASS2, (0, -0.65, 2.15), (0.3, 0.04, 0.18))
t.box(VEST2, (0, 0.72, 3.0), (1.5, 0.26, 1.4)).box(BRASS, (0, 0.86, 2.6), (1.0, 0.06, 0.4))   # ammo can on the back
t.build()
h = Obj('Head')
h.box(SKIN, (0, 0, 4.85), (1.6, 1.48, 1.56))
h.box(SKIN2, (0, -0.8, 4.78), (0.26, 0.14, 0.3))
h.box(DARK, (0.37, -0.755, 4.98), (0.42, 0.04, 0.3)).box(EYE, (0.39, -0.775, 4.98), (0.16, 0.03, 0.14))
h.box(BAND, (0, -0.1, 4.42), (1.66, 1.4, 0.5))           # bandana over the mouth
h.box(BAND2, (0, -0.76, 4.3), (1.0, 0.04, 0.14)).box(BAND2, (0, 0.72, 4.5), (0.4, 0.2, 0.5))
h.box(BLOOD, (-0.55, -0.79, 4.95), (0.18, 0.03, 0.3))
h.build()
c = Obj('Hat')
c.box(HELM, (0, 0.04, 5.72), (1.9, 1.8, 0.6), taper=(0.82, 0.82)).box(HELM2, (0, 0.04, 5.46), (2.02, 1.92, 0.16))
c.box(GOG, (0, 0.04, 5.6), (1.94, 1.84, 0.14))
for x in (-0.4, 0.4): c.box(GOG, (x, -0.92, 5.75), (0.5, 0.14, 0.38)).box(LENS, (x, -0.99, 5.75), (0.36, 0.04, 0.26))
# eye patch side: left eye covered (head's dark patch only on the right eye)
c.box(GOG, (-0.37, -0.79, 4.98), (0.44, 0.06, 0.34))
c.build()
def arm(name, sx):
    a = Obj(name); x = 1.52 * sx
    a.box(SHIRT, (x, 0, 3.45), (1.14, 1.14, 1.2)).box(SHIRT2, (x, 0, 2.8), (1.16, 1.16, 0.16))
    a.box(VEST2, (x, 0, 3.9), (1.2, 1.2, 0.42))           # shoulder pad
    a.box(SKIN, (x, 0, 2.2), (0.96, 0.96, 1.0))
    a.box(VEST2, (x, 0, 1.6), (1.0, 1.0, 0.38))           # fingerless gloves
    for dx in (-0.3, 0, 0.3): a.box(SKIN2, (x + dx, -0.12, 1.32), (0.24, 0.58, 0.3))
    a.build()
arm('RightArm', 1); arm('LeftArm', -1)
def leg(name, sx):
    l = Obj(name); x = 0.54 * sx
    l.box(PANTS, (x, 0, 1.3), (1.08, 1.14, 1.4)).box(PANTS2, (x, -0.58, 1.05), (0.56, 0.06, 0.4))
    l.box(VEST2, (x, -0.6, 1.4), (0.6, 0.1, 0.5))         # knee pad
    l.box(BOOT, (x, -0.08, 0.4), (1.14, 1.36, 0.76)).box(SOLE, (x, -0.08, 0.05), (1.18, 1.42, 0.12))
    l.build()
leg('RightLeg', 1); leg('LeftLeg', -1)
# light machine gun held at the hip in the right hand, barrel forward
g = Obj('MachineGun', bevel=0.02)
X, Z = 1.52, 1.45
g.box(GUN, (X, 0.75, Z - 0.05), (0.32, 1.0, 0.5))       # stock
g.box(GUN, (X, -0.25, Z + 0.05), (0.4, 1.2, 0.56))      # receiver
g.box(GUN2, (X, -0.25, Z + 0.38), (0.36, 0.9, 0.12))    # top cover
g.box(GUN, (X, -0.05, Z - 0.42), (0.22, 0.26, 0.5), rot=(15, 0, 0))  # grip
g.box(GUN3, (X - 0.38, -0.3, Z - 0.1), (0.42, 0.6, 0.56))  # ammo box on the side
g.box(GUN2, (X, -1.4, Z + 0.1), (0.34, 1.2, 0.34))      # barrel shroud
for k in range(4): g.box(GUN, (X, -0.95 - k * 0.3, Z + 0.1), (0.36, 0.08, 0.36))
g.box(GUN, (X, -2.4, Z + 0.1), (0.18, 0.9, 0.18)).box(GUN3, (X, -2.9, Z + 0.1), (0.26, 0.2, 0.26))
g.box(GUN, (X, -1.9, Z - 0.35), (0.06, 0.06, 0.6), rot=(0, 25, 0)).box(GUN, (X, -1.9, Z - 0.35), (0.06, 0.06, 0.6), rot=(0, -25, 0))  # bipod (folded down)
# a short hanging ammo belt
for k in range(4): g.box(BRASS if k % 2 == 0 else BRASS2, (X - 0.3, -0.2 + k * 0.05, Z - 0.5 - k * 0.22), (0.1, 0.32, 0.12))
g.build()
scale_all(1.0)
if '--export' in sys.argv: export('/home/claude/mobs5/out_models/myw_zombiemachinegunner.glb')
print(render_preview('/home/claude/mobs5/out_models/mg.png', center=(0, 0, 3.4), dist=13))
