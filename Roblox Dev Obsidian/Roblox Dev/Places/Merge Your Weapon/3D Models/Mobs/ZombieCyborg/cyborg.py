import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
SKIN, SKIN2 = mat('Z10Skin', '#8AA0A8'), mat('Z10Skin2', '#6A8088')
METAL, METAL2, METAL3, DARK = mat('CBMetal', '#9AA0AA'), mat('CBMetal2', '#5A6068'), mat('CBMetal3', '#C9CED6'), mat('CBDark', '#1E2226')
RED, CYAN, WIRE, CLOTH = mat('CBLaser', '#FF3A5A', 3.0), mat('CBGlow', '#3AE8FF', 2.5), mat('CBWire', '#C83A2A'), mat('CBCloth', '#3A4048')
TEETH, MOUTH, BLOOD = mat('Z10Teeth', '#E2DFC8'), mat('Z10Mouth', '#2A1510'), mat('Z10Blood', '#7A2E22')
t = Obj('Torso')
t.box(CLOTH, (0, 0, 3.05), (2.04, 1.1, 2.1))
t.box(METAL, (0.45, 0, 3.2), (1.2, 1.18, 1.8))                         # right half armoured
t.box(METAL2, (0.45, -0.6, 3.6), (1.0, 0.04, 0.5)).box(METAL2, (0.45, -0.6, 2.8), (1.0, 0.04, 0.5))
t.box(CYAN, (0.45, -0.63, 3.2), (0.4, 0.04, 0.4), rot=(0, 45, 0))       # power core
t.box(SKIN, (-0.6, -0.56, 3.3), (0.7, 0.04, 1.0))                       # exposed flesh on the left
for z in (3.0, 3.5): t.box(WIRE, (-0.15, -0.58, z), (0.5, 0.05, 0.08), rot=(0, 15, 0))
t.box(METAL2, (0, 0, 2.08), (2.12, 1.18, 0.22))
t.box(METAL2, (0, 0.62, 3.2), (1.4, 0.16, 1.6)).box(CYAN, (0, 0.71, 3.4), (0.8, 0.04, 0.2))     # back module
t.build()
h = Obj('Head')
h.box(SKIN, (0, 0, 4.85), (1.58, 1.46, 1.56))
h.box(METAL, (0.42, -0.02, 4.95), (0.8, 1.52, 1.4))                     # metal half-face (right side)
h.box(DARK, (0.4, -0.77, 4.98), (0.5, 0.04, 0.36)).box(RED, (0.4, -0.795, 4.98), (0.3, 0.03, 0.2))    # laser eye
h.box(DARK, (-0.38, -0.74, 4.98), (0.36, 0.04, 0.26)).box(RED, (-0.38, -0.765, 4.98), (0.12, 0.03, 0.1))
h.box(MOUTH, (-0.1, -0.74, 4.42), (0.8, 0.04, 0.2))
for x in (-0.35, -0.05): h.box(TEETH, (x, -0.755, 4.46), (0.12, 0.03, 0.1))
h.box(BLOOD, (-0.55, -0.75, 4.6), (0.2, 0.03, 0.3))
h.build()
c = Obj('Hat')   # antenna + head bolts
c.box(METAL2, (0.42, 0.1, 5.72), (0.7, 0.9, 0.2)).box(METAL3, (0.6, 0.3, 6.2), (0.1, 0.1, 0.8)).box(RED, (0.6, 0.3, 6.66), (0.18, 0.18, 0.14))
c.build()
# right arm = arm cannon (the Cannon object is the barrel, welded to the arm)
a = Obj('RightArm'); x = 1.52
a.box(METAL, (x, 0, 3.4), (1.2, 1.2, 1.2)).box(METAL2, (x, 0, 2.5), (1.0, 1.0, 1.0))
a.box(CYAN, (x + 0.61, 0, 3.4), (0.04, 0.5, 0.5))
a.box(METAL, (x, -0.1, 1.7), (1.16, 1.3, 1.0))
a.build()
g = Obj('Cannon', bevel=0.02)
g.cyl(METAL2, (x, -0.95, 1.6), 0.42, 0.8, axis='Y', seg=10).cyl(DARK, (x, -1.45, 1.6), 0.3, 0.3, axis='Y', seg=10).cyl(RED, (x, -1.62, 1.6), 0.22, 0.06, axis='Y', seg=10)
g.box(CYAN, (x + 0.43, -0.9, 1.6), (0.04, 0.5, 0.14)).box(CYAN, (x - 0.43, -0.9, 1.6), (0.04, 0.5, 0.14))
g.build()
a = Obj('LeftArm'); x = -1.47
a.box(CLOTH, (x, 0, 3.3), (1.04, 1.04, 1.4)).box(SKIN, (x, 0, 2.2), (0.9, 0.9, 0.9))
a.box(METAL2, (x, 0, 2.5), (0.96, 0.96, 0.2))
for dx in (-0.28, 0, 0.28): a.box(SKIN2, (x + dx, -0.12, 1.55), (0.22, 0.55, 0.3))
a.build()
def leg(name, sx, metal):
    l = Obj(name); x = 0.52 * sx
    if metal:
        l.box(METAL, (x, 0, 1.4), (1.04, 1.1, 1.2)).box(METAL2, (x, 0, 0.8), (0.9, 0.9, 0.3)).box(METAL, (x, -0.08, 0.3), (1.08, 1.34, 0.6))
        l.box(CYAN, (x + 0.53 * sx, 0, 1.4), (0.04, 0.12, 0.6))
    else:
        l.box(CLOTH, (x, 0, 1.25), (1.04, 1.1, 1.5)).box(DARK, (x, -0.08, 0.25), (1.08, 1.3, 0.5))
    l.build()
leg('RightLeg', 1, True); leg('LeftLeg', -1, False)
if '--export' in sys.argv: export('/home/claude/mobs10/out_models/myw_zombiecyborg.glb')
print(render_preview('/home/claude/mobs10/out_models/cb.png', center=(0, 0, 3.3), dist=12))
