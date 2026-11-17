import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
SKIN, SKIN2, SCAR = mat('Z3Skin', '#8CA46C'), mat('Z3Skin2', '#68804E'), mat('DYBurn', '#3A2E28')
SHIRT, STRIPE = mat('DYShirt', '#E6DCC6'), mat('DYStripe', '#B83A2C')
APRON, APRON2 = mat('DYApron', '#7A4A26'), mat('DYApron2', '#5A3418')
BELT, BRASS = mat('DYBelt', '#3A2412'), mat('DYBrass', '#C9A227')
TNT, TNT2, WICK, SPARK = mat('DYTNT', '#D8352A'), mat('DYTNT2', '#9E2219'), mat('DYWick', '#E8D8A8'), mat('DYSpark', '#FFB43A', 4.0)
PANTS, PANTS2, PAD, BOOT, SOLE = mat('DYPants', '#4A4236'), mat('DYPants2', '#363026'), mat('DYPad', '#2B2D33'), mat('DYBoot', '#2E1C10'), mat('DYSole', '#140D07')
HELM, HELM2, LAMPBOX, LAMP = mat('DYHelm', '#454B55'), mat('DYHelm2', '#2F343C'), mat('DYLampBox', '#1E2026'), mat('DYLamp', '#FF7A2A', 3.0)
GOGGLE, LENS = mat('DYGoggle', '#5A3A22'), mat('DYLens', '#58B8E8')
DARK, EYE, TEETH, MOUTH = mat('Z3Dark', '#141620'), mat('DYEye', '#FF6A2A', 3.0), mat('Z3Teeth', '#E2DFC8'), mat('Z3Mouth', '#2A1510')
SOOT = mat('DYSoot', '#2E2C2C')

def stick(o, c, axis='Z', L=0.9, r=0.17):
    """red dynamite stick with a cream band and a little wick"""
    o.cyl(TNT, c, r, L, axis=axis, seg=8)
    x, y, z = c
    o.cyl(TNT2, c, r * 1.05, L * 0.16, axis=axis, seg=8)
    if axis == 'Z': o.box(WICK, (x, y, z + L / 2 + 0.12), (0.06, 0.06, 0.24))

# ---------- torso: striped shirt, leather apron, dynamite bandolier ----------
t = Obj('Torso')
t.box(SHIRT, (0, 0, 3.05), (2.04, 1.12, 2.1))
for z in (2.35, 2.75, 3.15, 3.55, 3.95): t.box(STRIPE, (0, 0, z), (2.06, 1.14, 0.14))
t.box(APRON, (0, -0.6, 2.75), (1.6, 0.06, 1.7)).box(APRON2, (0, -0.64, 2.3), (1.0, 0.04, 0.5))
for x in (-0.6, 0.6): t.box(APRON, (x, 0, 3.8), (0.24, 1.2, 0.08), rot=(0, 0, 0))
t.box(BELT, (0, 0, 2.08), (2.14, 1.2, 0.24)).box(BRASS, (0, -0.62, 2.08), (0.34, 0.06, 0.26))
# bandolier across the chest with 5 sticks
t.box(BELT, (0, -0.66, 3.05), (2.5, 0.08, 0.3), rot=(0, -40, 0))
for i in range(-2, 3):
    x = i * 0.36; z = 3.05 + i * 0.3
    stick(t, (x, -0.76, z), axis='Z', L=0.62, r=0.13)
t.box(BELT, (0, 0.62, 3.05), (2.5, 0.08, 0.3), rot=(0, 40, 0))
# satchel on the back with sticks sticking out
t.box(APRON2, (0, 0.78, 2.7), (1.3, 0.5, 1.0)).box(APRON, (0, 0.78, 3.25), (1.34, 0.54, 0.12))
for x in (-0.35, 0, 0.35): stick(t, (x, 0.8, 3.55), L=0.6, r=0.12)
t.build()

# ---------- head: big helmet with orange lamp, goggles on the forehead, burnt face, wild grin ----------
h = Obj('Head')
h.box(SKIN, (0, 0, 4.85), (1.66, 1.54, 1.6))
h.box(SKIN2, (0, -0.68, 4.28), (1.56, 0.3, 0.4))
h.box(SKIN2, (0, -0.82, 4.8), (0.28, 0.16, 0.3))
for x in (-0.86, 0.86): h.box(SKIN2, (x, 0.05, 4.88), (0.1, 0.3, 0.34))
h.box(DARK, (-0.38, -0.775, 4.98), (0.46, 0.04, 0.36)).box(EYE, (-0.36, -0.795, 4.98), (0.2, 0.03, 0.18))
h.box(DARK, (0.38, -0.775, 4.98), (0.46, 0.04, 0.36)).box(EYE, (0.4, -0.795, 4.98), (0.2, 0.03, 0.18))
h.box(SCAR, (0.55, -0.785, 4.6), (0.42, 0.03, 0.3)).box(SOOT, (-0.5, -0.785, 4.62), (0.36, 0.03, 0.22))
h.box(MOUTH, (0, -0.845, 4.33), (1.0, 0.04, 0.24))
for x in (-0.38, -0.18, 0.02, 0.22, 0.4): h.box(TEETH, (x, -0.86, 4.38 if x != 0.02 else 4.32), (0.13, 0.03, 0.12))
h.build()
c = Obj('Hat')
c.box(HELM, (0, 0.02, 5.75), (1.82, 1.7, 0.62), taper=(0.84, 0.84)).box(HELM2, (0, 0.02, 6.05), (0.28, 1.36, 0.16))
c.box(HELM, (0, -0.08, 5.48), (2.1, 2.06, 0.14))
c.box(LAMPBOX, (0, -0.92, 5.74), (0.56, 0.24, 0.48)).box(LAMP, (0, -1.05, 5.74), (0.4, 0.04, 0.34))
c.box(GOGGLE, (0, 0, 5.35), (1.74, 1.62, 0.14))
for x in (-0.38, 0.38): c.box(GOGGLE, (x, -0.82, 5.35), (0.5, 0.12, 0.4)).box(LENS, (x, -0.89, 5.35), (0.36, 0.04, 0.28))
c.build()

# ---------- arms: big, sleeves rolled, the right hand holds a lit stick ----------
def arm(name, sx):
    a = Obj(name); x = 1.47 * sx
    a.box(SHIRT, (x, 0, 3.55), (1.08, 1.08, 0.95))
    for z in (3.3, 3.7): a.box(STRIPE, (x, 0, z), (1.1, 1.1, 0.14))
    a.box(SKIN, (x, 0, 2.45), (0.94, 0.94, 1.25))
    a.box(BELT, (x, 0, 2.0), (1.0, 1.0, 0.3)).box(BRASS, (x, -0.51, 2.0), (0.14, 0.04, 0.14))
    if sx < 0: a.box(SCAR, (x, -0.48, 2.6), (0.5, 0.03, 0.4))
    a.box(SKIN2, (x, 0, 1.62), (0.98, 0.98, 0.38))
    for dx in (-0.29, 0, 0.29): a.box(SKIN2, (x + dx, -0.12, 1.36), (0.22, 0.56, 0.3))
    a.build()
arm('RightArm', 1); arm('LeftArm', -1)

def leg(name, sx):
    l = Obj(name); x = 0.52 * sx
    l.box(PANTS, (x, 0, 1.3), (1.06, 1.12, 1.4)).box(PANTS2, (x, 0, 1.75), (1.08, 1.14, 0.12))
    l.box(PAD, (x, -0.6, 1.05), (0.72, 0.08, 0.52))
    l.box(BOOT, (x, -0.08, 0.34), (1.14, 1.34, 0.62)).box(SOLE, (x, -0.08, 0.05), (1.18, 1.4, 0.1)).box(BELT, (x, 0, 0.62), (1.18, 1.18, 0.1))
    l.build()
leg('RightLeg', 1); leg('LeftLeg', -1)

# ---------- the stick in the right hand (thrown), wick with a glowing spark ----------
d = Obj('Dynamite', bevel=0.02)
d.cyl(TNT, (1.47, -0.45, 1.36), 0.2, 1.0, axis='Y', seg=8)
d.cyl(TNT2, (1.47, -0.45, 1.36), 0.21, 0.18, axis='Y', seg=8)
d.box(WICK, (1.47, -1.07, 1.4), (0.06, 0.3, 0.06), rot=(-20, 0, 0))
d.build()
sp = Obj('Spark', bevel=0)
sp.box(SPARK, (1.47, -1.24, 1.47), (0.16, 0.16, 0.16), rot=(45, 45, 0))
sp.build()

scale_all(1.35)
if '--export' in sys.argv:
    export('/home/claude/mobs3/out_models/myw_zombiedynamiter.glb')
    bpy.ops.wm.save_as_mainfile(filepath='/home/claude/mobs3/out_models/myw_zombiedynamiter.blend')
print(render_preview('/home/claude/mobs3/out_models/dy.png', center=(0, 0, 4.3), dist=17))
