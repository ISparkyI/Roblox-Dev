import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
SKIN, SKIN2, SKIN3 = mat('MTSkin', '#8A6A9A'), mat('MTSkin2', '#6A4E7A'), mat('MTSkin3', '#B08AC0')
VEIN, BONE, BONE2 = mat('MTVein', '#FF4ADA', 2.0), mat('MTBone', '#E8E0C8'), mat('MTBone2', '#C8BCA0')
JEANS, JEANS2, RAG = mat('MTJeans', '#3A5478'), mat('MTJeans2', '#2A3E5A'), mat('MTRag', '#6A6A62')
DARK, EYE, TEETH, MOUTH = mat('Z7Dark', '#141620'), mat('MTEye', '#FF4ADA', 3.0), mat('Z7Teeth', '#E2DFC8'), mat('Z7Mouth', '#2A1510')
t = Obj('Torso')
t.box(SKIN, (0, 0, 3.05), (2.2, 1.24, 2.2))
t.box(SKIN2, (-0.55, -0.63, 3.4), (0.9, 0.04, 0.7)).box(SKIN2, (0.55, -0.63, 3.4), (0.9, 0.04, 0.7))   # pecs
for z in (2.4, 2.75): t.box(SKIN2, (0, -0.63, z), (1.1, 0.04, 0.24))                                        # abs
t.box(VEIN, (0.85, -0.63, 2.8), (0.08, 0.03, 0.9)).box(VEIN, (-0.3, -0.63, 3.9), (0.6, 0.03, 0.08))
t.box(RAG, (-0.7, 0, 2.05), (0.8, 1.28, 0.3), rot=(0, 10, 0))     # torn shirt remains at the waist
t.box(JEANS2, (0, 0, 2.0), (2.24, 1.28, 0.22))
# bone spikes along the back
for i, z in enumerate((2.6, 3.2, 3.8)):
    t.box(BONE, (0, 0.75, z), (0.3, 0.6, 0.3), rot=(-35, 0, 0), taper=(0.3, 0.3))
t.box(BONE2, (0.8, 0.7, 3.9), (0.24, 0.5, 0.24), rot=(-30, 0, 25), taper=(0.3, 0.3)).box(BONE2, (-0.8, 0.7, 3.9), (0.24, 0.5, 0.24), rot=(-30, 0, -25), taper=(0.3, 0.3))
t.build()
h = Obj('Head')
h.box(SKIN, (0, -0.1, 4.75), (1.5, 1.4, 1.3))
h.box(SKIN3, (0.3, 0.1, 5.35), (0.9, 0.9, 0.3))     # swollen skull bump
h.box(DARK, (-0.33, -0.81, 4.95), (0.4, 0.04, 0.26)).box(EYE, (-0.33, -0.83, 4.95), (0.2, 0.03, 0.14))
h.box(DARK, (0.36, -0.81, 4.9), (0.36, 0.04, 0.22)).box(EYE, (0.36, -0.83, 4.9), (0.12, 0.03, 0.1))
h.box(MOUTH, (0, -0.82, 4.38), (1.0, 0.04, 0.34))
for x in (-0.36, -0.12, 0.12, 0.36): h.box(TEETH, (x, -0.84, 4.44 if x < 0 else 4.32), (0.14, 0.03, 0.16), taper=(0.3, 1))
h.box(VEIN, (0.6, -0.81, 5.1), (0.06, 0.03, 0.4))
h.build()
c = Obj('Hat')
c.box(BONE, (-0.5, 0.1, 5.5), (0.24, 0.24, 0.6), rot=(0, -20, 0), taper=(0.3, 0.3)).box(BONE, (0.55, 0.0, 5.7), (0.2, 0.2, 0.5), rot=(0, 25, 0), taper=(0.3, 0.3))
c.build()
def arm(name, sx, big):
    a = Obj(name); x = (1.75 if big else 1.55) * sx; k = 1.35 if big else 1.0
    a.box(SKIN, (x, 0, 3.0), (1.2 * k, 1.2 * k, 2.1))
    a.box(SKIN2, (x, 0, 3.7), (1.26 * k, 1.26 * k, 0.5))
    a.box(VEIN, (x + 0.5 * k * sx, -0.3, 2.9), (0.04, 0.08, 1.2))
    a.box(SKIN3, (x, 0, 1.75), (1.3 * k, 1.3 * k, 0.7))                       # huge fist
    for dx in (-0.36, 0, 0.36): a.box(SKIN2, (x + dx * k, -0.2, 1.3), (0.3 * k, 0.7 * k, 0.4))
    if big:
        for dz in (2.6, 3.2): a.box(BONE, (x + 0.85 * sx, 0, dz), (0.5, 0.26, 0.26), rot=(0, 0, 0), taper=None)
    a.build()
arm('RightArm', 1, True); arm('LeftArm', -1, False)
def leg(name, sx):
    l = Obj(name); x = 0.56 * sx
    l.box(JEANS, (x, 0, 1.3), (1.12, 1.18, 1.4))
    l.box(SKIN, (x, -0.2, 0.75), (1.0, 0.8, 0.4))          # torn knees -> skin
    l.box(JEANS2, (x + 0.2 * sx, -0.6, 1.5), (0.4, 0.05, 0.3))
    l.box(SKIN2, (x, -0.06, 0.3), (1.16, 1.4, 0.6))          # bare mutated feet
    for dx in (-0.35, 0, 0.35): l.box(BONE2, (x + dx, -0.82, 0.12), (0.2, 0.2, 0.2), taper=(0.4, 0.4))
    l.build()
leg('RightLeg', 1); leg('LeftLeg', -1)
if '--export' in sys.argv: export('/home/claude/mobs7/out_models/myw_zombiemutant.glb')
print(render_preview('/home/claude/mobs7/out_models/mt.png', center=(0, 0, 3.4), dist=13))
