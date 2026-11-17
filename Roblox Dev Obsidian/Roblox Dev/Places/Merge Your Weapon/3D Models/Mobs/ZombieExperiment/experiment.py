import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
SKIN, SKIN2, SKIN3 = mat('EXSkin', '#9AB8C8'), mat('EXSkin2', '#7A98A8'), mat('EXSkin3', '#B8D8E8')
SUIT, SUIT2, TAG = mat('EXSuit', '#E87A2A'), mat('EXSuit2', '#B85A1A'), mat('EXTag', '#F2EEDC')
METAL, METAL2, DARK = mat('EXMetal', '#9AA0AA'), mat('EXMetal2', '#5A6068'), mat('EXDark', '#141620')
CORE, VEIN, EYE = mat('EXCore', '#3AE8FF', 3.0), mat('EXVein', '#3AE8FF', 2.0), mat('EXEye', '#9AF4FF', 3.5)
GLASS, TEETH, MOUTH = mat('EXHelmetGlass', '#C8F0FF'), mat('EXTeeth', '#E2DFC8'), mat('EXMouth', '#1A2A3A')
t = Obj('Torso')
t.box(SKIN, (0, 0, 3.1), (2.4, 1.3, 2.3))
t.box(SUIT, (0, 0, 2.35), (2.46, 1.36, 0.9))                    # torn prisoner/test-subject suit (lower)
t.box(SUIT2, (-0.7, -0.69, 2.7), (0.6, 0.04, 0.3), rot=(0, 20, 0)).box(TAG, (0.6, -0.69, 2.5), (0.5, 0.04, 0.3))
t.box(METAL2, (0, -0.685, 3.4), (1.3, 0.06, 1.3), rot=(0, 45, 0))  # chest port frame
t.box(CORE, (0, -0.738, 3.4), (0.75, 0.07, 0.75), rot=(0, 45, 0))  # the beam core
for (x, z, a) in ((-0.8, 3.0, 40), (0.85, 3.1, -40), (-0.5, 3.9, -20), (0.55, 3.9, 25)): t.box(VEIN, (x, -0.672, z), (0.1, 0.06, 0.7), rot=(0, a, 0))
# tubes from the back into the shoulders
t.box(METAL, (0, 0.75, 3.3), (1.6, 0.3, 1.8)).box(CORE, (-0.4, 0.92, 3.3), (0.24, 0.06, 1.4)).box(CORE, (0.4, 0.92, 3.3), (0.24, 0.06, 1.4))
t.build()
h = Obj('Head')
h.box(SKIN, (0, -0.1, 4.75), (1.4, 1.3, 1.3))
h.box(SKIN3, (0.25, 0.1, 5.4), (1.0, 1.0, 0.4))                  # swollen brain bulge
h.box(VEIN, (0.25, -0.41, 5.45), (0.6, 0.04, 0.08)).box(VEIN, (-0.1, 0.62, 5.4), (0.08, 0.04, 0.3))
for x in (-0.32, 0.32): h.box(DARK, (x, -0.76, 4.92), (0.4, 0.04, 0.3)).box(EYE, (x, -0.785, 4.92), (0.2, 0.03, 0.14))
h.box(MOUTH, (0, -0.76, 4.4), (0.8, 0.04, 0.26))
for x in (-0.25, 0.0, 0.25): h.box(TEETH, (x, -0.775, 4.48), (0.12, 0.03, 0.12), taper=(0.3, 1))
h.build()
c = Obj('Hat')   # cracked containment helmet ring + glass shard + antennas
c.box(METAL2, (0, -0.1, 4.12), (1.7, 1.6, 0.3))
c.box(GLASS, (-0.45, -0.3, 4.75), (0.12, 1.2, 1.0), rot=(0, 0, 10))
for x in (-0.7, 0.7): c.box(METAL, (x, 0.2, 5.6), (0.12, 0.12, 0.7), rot=(0, 15 if x > 0 else -15, 0)).box(CORE, (x * 1.07, 0.2, 5.98), (0.16, 0.16, 0.12))
c.build()
def arm(name, sx, big):
    a = Obj(name); x = (1.8 if big else 1.6) * sx; k = 1.35 if big else 1.0
    a.box(SKIN, (x, 0, 3.0), (1.2 * k, 1.2 * k, 2.1))
    a.box(SKIN2, (x, 0, 1.8), (1.3 * k, 1.3 * k, 0.6))
    for dx in (-0.36, 0, 0.36): a.box(SKIN2, (x + dx * k, -0.2, 1.35), (0.3 * k, 0.7 * k, 0.4))
    if big:
        for z in (2.4, 3.3): a.box(METAL, (x, 0, z), (1.66, 1.66, 0.3)).box(CORE, (x, -0.84, z), (0.4, 0.04, 0.14))     # restraint braces
        a.box(METAL2, (x + 0.84 * sx, 0, 2.85), (0.06, 0.4, 0.9))
    else:
        a.box(VEIN, (x + 0.61 * sx, 0, 2.9), (0.04, 0.1, 1.0)).box(SUIT, (x, 0, 3.75), (1.26, 1.26, 0.5))
    a.build()
arm('RightArm', 1, True); arm('LeftArm', -1, False)
def leg(name, sx):
    l = Obj(name); x = 0.6 * sx
    l.box(SUIT, (x, 0, 1.3), (1.14, 1.2, 1.5)).box(SUIT2, (x, -0.61, 1.0), (0.6, 0.04, 0.3))
    l.box(SKIN2, (x, -0.06, 0.3), (1.2, 1.44, 0.6))
    l.box(METAL, (x, 0, 0.75), (1.22, 1.3, 0.25))                 # ankle shackle
    l.build()
leg('RightLeg', 1); leg('LeftLeg', -1)
if '--export' in sys.argv: export('/home/claude/mobs10/out_models/myw_zombieexperiment.glb')
print(render_preview('/home/claude/mobs10/out_models/ex.png', center=(0, 0, 3.4), dist=13))
