import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
SUIT, SUIT2, SUIT3, TAPE = mat('HZSuit', '#E8C22A'), mat('HZSuit2', '#C8A01A'), mat('HZSuit3', '#F2D850'), mat('HZTape', '#2A2C30')
VISOR, GLOW, RIM = mat('HZVisor', '#1E2A22'), mat('HZGlow', '#8CFF3A', 2.5), mat('HZRim', '#3A3C40')
TANK, TANK2, VALVE = mat('HZTank', '#5A6A4A'), mat('HZTank2', '#3A4430'), mat('HZValve', '#C83A2A')
BOOT, SOLE, GLOVE = mat('HZBoot', '#2A2C30'), mat('HZSole', '#141516'), mat('HZGlove', '#2A4A2A')
HOSE, NOZ, NOZ2, SYM, SYM2 = mat('HZHose', '#3A3C40'), mat('HZNozzle', '#8A9098'), mat('HZNozzle2', '#5A6068'), mat('HZSym', '#141414'), mat('HZSym2', '#E8C22A')
DARK, EYE, OOZE = mat('Z6Dark', '#141620'), mat('HZEye', '#C8FF4A', 3.0), mat('Z6Ooze', '#4CC81A')
t = Obj('Torso')
t.box(SUIT, (0, 0, 3.05), (2.14, 1.2, 2.14))
t.box(SUIT2, (0, -0.61, 3.05), (0.14, 0.04, 2.0))
t.box(TAPE, (0, 0, 2.15), (2.18, 1.24, 0.22))
# hazard symbol on the chest
t.box(SYM2, (0.55, -0.62, 3.55), (0.6, 0.04, 0.6), rot=(0, 45, 0)).box(SYM, (0.55, -0.65, 3.55), (0.2, 0.03, 0.2))
t.box(OOZE, (-0.6, -0.62, 2.5), (0.4, 0.03, 0.5)).box(OOZE, (-0.4, -0.62, 2.2), (0.2, 0.03, 0.3))
# air tanks on the back
for x in (-0.45, 0.45):
    t.cyl(TANK, (x, 0.95, 3.0), 0.38, 1.8, axis='Z', seg=10).cyl(TANK2, (x, 0.95, 3.95), 0.24, 0.2, axis='Z', seg=8).box(VALVE, (x, 0.95, 4.12), (0.18, 0.18, 0.12))
t.box(TANK2, (0, 0.95, 3.0), (1.2, 0.3, 0.2))
t.build()
h = Obj('Head')
h.box(SUIT, (0, 0, 4.9), (1.8, 1.7, 1.76))           # hood
h.box(SUIT2, (0, 0, 5.85), (1.5, 1.4, 0.2))
h.box(RIM, (0, -0.86, 4.95), (1.4, 0.08, 1.1))
h.box(VISOR, (0, -0.9, 4.95), (1.2, 0.06, 0.9))
h.box(EYE, (-0.3, -0.94, 5.05), (0.18, 0.03, 0.14)).box(EYE, (0.32, -0.94, 5.02), (0.14, 0.03, 0.12))
h.box(GLOW, (0, -0.93, 4.6), (0.9, 0.02, 0.06))
# gas filter under the visor
h.cyl(HOSE, (0, -1.0, 4.3), 0.3, 0.4, axis='Y', seg=10).cyl(TANK2, (0, -1.22, 4.3), 0.34, 0.1, axis='Y', seg=10)
h.build()
c = Obj('Hat')
c.box(SUIT3, (0, 0.1, 6.05), (1.0, 0.9, 0.24)).box(GLOW, (0, 0.1, 6.2), (0.3, 0.3, 0.1))   # top vent with a light
c.build()
def arm(name, sx):
    a = Obj(name); x = 1.6 * sx
    a.box(SUIT, (x, 0, 3.0), (1.16, 1.16, 2.0)).box(TAPE, (x, 0, 2.05), (1.2, 1.2, 0.16))
    a.box(SUIT3, (x, -0.2, 3.5), (1.18, 0.5, 0.5))
    a.box(GLOVE, (x, 0, 1.68), (1.06, 1.06, 0.6))
    for dx in (-0.3, 0, 0.3): a.box(GLOVE, (x + dx, -0.12, 1.32), (0.24, 0.58, 0.32))
    a.build()
arm('RightArm', 1); arm('LeftArm', -1)
def leg(name, sx):
    l = Obj(name); x = 0.55 * sx
    l.box(SUIT, (x, 0, 1.3), (1.1, 1.16, 1.4)).box(TAPE, (x, 0, 0.78), (1.14, 1.2, 0.14))
    l.box(BOOT, (x, -0.06, 0.38), (1.16, 1.34, 0.72)).box(SOLE, (x, -0.06, 0.05), (1.2, 1.4, 0.12))
    l.build()
leg('RightLeg', 1); leg('LeftLeg', -1)
s = Obj('Sprayer', bevel=0.02)
X, Z = 1.6, 1.4
s.box(NOZ2, (X, -0.3, Z), (0.36, 0.7, 0.44)).box(NOZ2, (X, -0.15, Z - 0.42), (0.24, 0.26, 0.5), rot=(15, 0, 0))
s.cyl(NOZ, (X, -1.2, Z + 0.05), 0.14, 1.4, axis='Y', seg=8).cyl(NOZ2, (X, -1.95, Z + 0.05), 0.26, 0.24, axis='Y', seg=8).cyl(GLOW, (X, -2.08, Z + 0.05), 0.18, 0.04, axis='Y', seg=8)
s.cyl(HOSE, (X - 0.2, 0.4, Z + 0.6), 0.1, 1.6, axis='Z', seg=6, rot=(40, 0, 0))
s.build()
if '--export' in sys.argv: export('/home/claude/mobs6/out_models/myw_zombiehazmat.glb')
print(render_preview('/home/claude/mobs6/out_models/hz.png', center=(0, 0, 3.4), dist=13))
