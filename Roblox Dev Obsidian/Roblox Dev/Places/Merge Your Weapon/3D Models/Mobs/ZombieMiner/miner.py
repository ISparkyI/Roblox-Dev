import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
SKIN, SKIN2 = mat('Z3Skin', '#8CA46C'), mat('Z3Skin2', '#68804E')
SHIRT, SHIRT2 = mat('MNShirt', '#7A8494'), mat('MNShirt2', '#5A6272')
DENIM, DENIM2, PATCH = mat('MNDenim', '#36547E'), mat('MNDenim2', '#28405F'), mat('MNPatch', '#8A6A3E')
BRASS, BELT, POUCH = mat('MNBrass', '#C9A227'), mat('MNBelt', '#4A2C16'), mat('MNPouch', '#6B4524')
SOOT = mat('MNSoot', '#2E2C2C')
GLOVE, BOOT, SOLE = mat('MNGlove', '#7A5230'), mat('MNBoot', '#3E2716'), mat('MNSole', '#1C130B')
HAT, HAT2, LAMPBOX, LAMP = mat('MNHat', '#F2B522'), mat('MNHat2', '#C98C12'), mat('MNLampBox', '#2B2D33'), mat('MNLamp', '#FFF2A8', 3.0)
DARK, EYE, TEETH, MOUTH = mat('Z3Dark', '#141620'), mat('MNEye', '#B8F23A', 2.5), mat('Z3Teeth', '#E2DFC8'), mat('Z3Mouth', '#2A1510')
WOOD, WOOD2, IRON, EDGE = mat('MNWood', '#8A5A2E'), mat('MNWood2', '#6A421F'), mat('MNIron', '#555B66'), mat('MNEdge', '#C9CED6')

# ---------- torso: shirt + denim overalls (bib, straps), belt with a pouch, soot smudges ----------
t = Obj('Torso')
t.box(SHIRT, (0, 0, 3.05), (2.04, 1.1, 2.1))
t.box(DENIM, (0, -0.56, 2.75), (1.5, 0.06, 1.5)).box(DENIM, (0, 0.56, 2.6), (1.7, 0.06, 1.2))
t.box(DENIM, (0, 0, 2.3), (2.08, 1.14, 0.8))                       # trousers top
t.box(DENIM2, (0, -0.6, 3.05), (0.6, 0.04, 0.5))                   # bib pocket
for x in (-0.58, 0.58):
    t.box(DENIM, (x, -0.58, 3.6), (0.28, 0.05, 1.0)).box(DENIM, (x, 0.58, 3.6), (0.28, 0.05, 1.0)).box(DENIM, (x, 0, 4.11), (0.28, 1.18, 0.06))
    t.box(BRASS, (x, -0.62, 3.42), (0.18, 0.04, 0.18))
t.box(BELT, (0, 0, 2.08), (2.12, 1.18, 0.2)).box(BRASS, (0, -0.6, 2.08), (0.3, 0.06, 0.22))
t.box(POUCH, (0.92, -0.25, 1.95), (0.36, 0.5, 0.5))
t.box(SOOT, (-0.5, -0.59, 3.75), (0.4, 0.03, 0.22)).box(SOOT, (0.62, -0.6, 2.5), (0.3, 0.03, 0.26)).box(SOOT, (-0.2, -0.6, 2.35), (0.22, 0.03, 0.16))
t.box(SHIRT2, (0, -0.52, 4.0), (0.8, 0.12, 0.14))                 # collar
t.build()

# ---------- head: hard hat with a glowing headlamp, soot, crooked grin ----------
h = Obj('Head')
h.box(SKIN, (0, 0, 4.85), (1.62, 1.5, 1.58))
h.box(SKIN2, (0, -0.8, 4.78), (0.24, 0.14, 0.3))
for x in (-0.84, 0.84): h.box(SKIN2, (x, 0.05, 4.88), (0.1, 0.3, 0.34))
h.box(DARK, (-0.38, -0.765, 5.02), (0.42, 0.04, 0.34)).box(EYE, (-0.37, -0.785, 5.0), (0.16, 0.03, 0.16))
h.box(DARK, (0.38, -0.765, 4.98), (0.42, 0.04, 0.22)).box(EYE, (0.4, -0.785, 4.98), (0.12, 0.03, 0.1))
h.box(SOOT, (0.5, -0.77, 4.6), (0.4, 0.03, 0.2)).box(SOOT, (-0.55, -0.77, 4.52), (0.3, 0.03, 0.16))
h.box(MOUTH, (0.05, -0.775, 4.38), (0.8, 0.04, 0.22), rot=(0, -6, 0))
for x, z in ((-0.25, 4.42), (-0.05, 4.4), (0.18, 4.36), (0.34, 4.38)): h.box(TEETH, (x, -0.79, z), (0.12, 0.03, 0.11))
h.build()
c = Obj('Hat')
c.box(HAT, (0, 0, 5.72), (1.72, 1.62, 0.56), taper=(0.86, 0.86)).box(HAT2, (0, 0, 5.98), (0.24, 1.3, 0.16))
c.box(HAT, (0, -0.12, 5.47), (2.0, 2.0, 0.12))                     # brim
c.box(LAMPBOX, (0, -0.86, 5.7), (0.5, 0.2, 0.42)).box(LAMP, (0, -0.97, 5.7), (0.34, 0.04, 0.3))
c.box(LAMPBOX, (0, 0, 5.5), (1.76, 1.66, 0.08))                    # strap
c.build()

# ---------- arms: rolled shirt sleeves, bare forearms, leather gloves ----------
def arm(name, sx):
    a = Obj(name); x = 1.45 * sx
    a.box(SHIRT, (x, 0, 3.5), (1.04, 1.04, 1.0)).box(SHIRT2, (x, 0, 2.98), (1.1, 1.1, 0.22))
    a.box(SKIN, (x, 0, 2.35), (0.88, 0.88, 1.06))
    if sx < 0: a.box(SOOT, (x, -0.45, 2.4), (0.4, 0.03, 0.3))
    a.box(GLOVE, (x, 0, 1.62), (0.98, 0.98, 0.5)).box(GLOVE, (x, 0, 1.9), (1.04, 1.04, 0.12))
    for dx in (-0.28, 0, 0.28): a.box(GLOVE, (x + dx, -0.12, 1.33), (0.22, 0.55, 0.28))
    a.build()
arm('RightArm', 1); arm('LeftArm', -1)

# ---------- legs: overalls, knee patch, heavy boots ----------
def leg(name, sx, patch):
    l = Obj(name); x = 0.52 * sx
    l.box(DENIM, (x, 0, 1.32), (1.02, 1.08, 1.36))
    if patch: l.box(PATCH, (x, -0.56, 1.15), (0.5, 0.03, 0.44))
    l.box(DENIM2, (x, 0, 0.66), (1.08, 1.14, 0.18))
    l.box(BOOT, (x, -0.1, 0.32), (1.1, 1.34, 0.58)).box(SOLE, (x, -0.1, 0.05), (1.14, 1.4, 0.1))
    l.box(IRON, (x, -0.78, 0.3), (0.7, 0.06, 0.26))              # steel toe cap
    l.build()
leg('RightLeg', 1, True); leg('LeftLeg', -1, False)

# ---------- pickaxe: handle forward like a tool, the head stands up / down (hits in the overhead swing) ----------
pk = Obj('Pickaxe', bevel=0.02)
pk.box(WOOD, (1.45, -1.0, 1.46), (0.2, 2.6, 0.2))
pk.box(WOOD2, (1.45, -0.05, 1.46), (0.24, 0.5, 0.24))
pk.box(IRON, (1.45, -2.2, 1.46), (0.3, 0.36, 0.42))               # eye of the head
pk.box(IRON, (1.45, -2.2, 1.98), (0.24, 0.26, 0.7), taper=(0.35, 0.5))            # upper spike
pk.box(IRON, (1.45, -2.2, 0.94), (0.24, 0.26, 0.7), rot=(180, 0, 0), taper=(0.35, 0.5))  # lower spike
pk.box(EDGE, (1.45, -2.2, 0.56), (0.12, 0.14, 0.12)).box(EDGE, (1.45, -2.2, 2.36), (0.12, 0.14, 0.12))
pk.build()

scale_all(1.1)
if '--export' in sys.argv:
    export('/home/claude/mobs3/out_models/myw_zombieminer.glb')
    bpy.ops.wm.save_as_mainfile(filepath='/home/claude/mobs3/out_models/myw_zombieminer.blend')
print(render_preview('/home/claude/mobs3/out_models/mn.png', center=(0, 0, 3.6), dist=14))
