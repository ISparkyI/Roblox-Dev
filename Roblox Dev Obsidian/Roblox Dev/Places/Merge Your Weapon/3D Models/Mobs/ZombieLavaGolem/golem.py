import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
ROCK, ROCK2, ROCK3 = mat('GLRock', '#5A5052'), mat('GLRock2', '#443C3E'), mat('GLRock3', '#6E6466')
LAVA, LAVA2, CORE = mat('GLLava', '#FF6A1A', 2.5), mat('GLLava2', '#FFB43A', 2.5), mat('GLCore', '#FFD27A', 3.0)
EYE, MOUTH = mat('GLEye', '#FFE08A', 3.5), mat('GLMouth', '#FF4A1A', 2.5)
t = Obj('Torso')
t.box(ROCK, (0, 0, 3.05), (2.3, 1.3, 2.2))
t.box(ROCK3, (-0.55, -0.66, 3.55), (0.95, 0.1, 0.8), rot=(0, 6, 0)).box(ROCK3, (0.55, -0.66, 3.55), (0.95, 0.1, 0.8), rot=(0, -6, 0))   # chest plates
t.box(ROCK2, (0, -0.66, 2.45), (1.6, 0.08, 0.7))
t.box(CORE, (0, -0.69, 3.0), (0.5, 0.06, 0.5), rot=(0, 45, 0)).box(LAVA, (0, -0.68, 3.0), (0.8, 0.05, 0.8), rot=(0, 45, 0))           # molten core
for (x, z, a, l) in ((-0.6, 2.6, 30, 0.7), (0.7, 2.7, -25, 0.8), (-0.9, 3.9, 60, 0.5), (0.8, 4.0, -60, 0.5)):
    t.box(LAVA, (x, -0.665, z), (0.14, 0.04, l), rot=(0, a, 0))
for (x, z, a) in ((0, 3.2, 10), (-0.5, 2.5, -40), (0.6, 3.8, 50)): t.box(LAVA, (x, 0.665, z), (0.14, 0.04, 0.9), rot=(0, a, 0))
# rocks on the shoulders / back
t.box(ROCK2, (0, 0.75, 3.8), (1.4, 0.4, 0.8), rot=(-20, 0, 0)).box(ROCK3, (0.5, 0.7, 2.7), (0.7, 0.3, 0.6))
t.box(LAVA2, (-0.95, -0.665, 3.2), (0.14, 0.04, 0.6), rot=(0, 15, 0)).box(LAVA2, (0.95, -0.665, 3.1), (0.14, 0.04, 0.6), rot=(0, -15, 0))
t.build()
h = Obj('Head')
h.box(ROCK, (0, -0.05, 4.7), (1.4, 1.3, 1.1))
h.box(ROCK2, (0, -0.72, 5.05), (1.5, 0.16, 0.28))            # heavy brow
for x in (-0.34, 0.34): h.box(EYE, (x, -0.71, 4.82), (0.28, 0.04, 0.14))
h.box(MOUTH, (0, -0.71, 4.38), (0.7, 0.04, 0.12))
h.box(LAVA, (0.45, -0.71, 4.55), (0.06, 0.03, 0.3))
h.build()
c = Obj('Hat')   # crown of rock spikes with glowing tips
for (x, y, s) in ((-0.45, 0.1, 0.5), (0.0, 0.25, 0.7), (0.45, 0.05, 0.55), (0.0, -0.3, 0.4)):
    c.box(ROCK3, (x, y, 5.25 + s / 2), (0.4, 0.4, s), taper=(0.35, 0.35))
c.box(LAVA2, (0.0, 0.25, 5.98), (0.12, 0.12, 0.1))
c.build()
def arm(name, sx):
    a = Obj(name); x = 1.75 * sx
    a.box(ROCK3, (x, 0, 3.75), (1.3, 1.3, 0.9))                 # shoulder boulder
    a.box(ROCK, (x, 0, 2.9), (1.0, 1.0, 1.2))
    a.box(LAVA, (x + 0.505 * sx, 0, 2.9), (0.03, 0.14, 0.9))
    a.box(ROCK2, (x, -0.05, 1.75), (1.45, 1.45, 1.2))           # huge fist
    a.box(LAVA, (x, -0.79, 1.75), (1.0, 0.04, 0.12)).box(LAVA2, (x, -0.79, 1.45), (0.6, 0.04, 0.1))
    a.build()
arm('RightArm', 1); arm('LeftArm', -1)
def leg(name, sx):
    l = Obj(name); x = 0.6 * sx
    l.box(ROCK, (x, 0, 1.35), (1.1, 1.1, 1.3))
    l.box(LAVA, (x + 0.555 * sx, 0, 1.3), (0.03, 0.14, 0.7))
    l.box(ROCK2, (x, -0.1, 0.35), (1.3, 1.5, 0.7))
    l.build()
leg('RightLeg', 1); leg('LeftLeg', -1)
if '--export' in sys.argv: export('/home/claude/mobs9/out_models/myw_zombielavagolem.glb')
print(render_preview('/home/claude/mobs9/out_models/gl.png', center=(0, 0, 3.2), dist=13))
