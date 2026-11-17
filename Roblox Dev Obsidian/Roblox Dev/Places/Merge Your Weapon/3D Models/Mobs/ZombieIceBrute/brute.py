import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
SKIN, SKIN2 = mat('Z4Skin', '#8FB0A8'), mat('Z4Skin2', '#6E8F88')
VEST, VEST2, ROPE = mat('IBVest', '#4A5568'), mat('IBVest2', '#36404F'), mat('IBRope', '#C9A86A')
PANTS, PANTS2, BOOT, SOLE = mat('IBPants', '#3A3F4A'), mat('IBPants2', '#2A2E36'), mat('IBBoot', '#2B2D33'), mat('IBSole', '#141518')
ICE, ICE2, ICE3, GLOW = mat('IBIce', '#8ED3EE'), mat('IBIce2', '#C2E9F7'), mat('IBIce3', '#5FB4DC'), mat('IBGlow', '#7FE8FF', 3.0)
DARK, TEETH, MOUTH, FROST = mat('Z4Dark', '#141620'), mat('Z4Teeth', '#E2DFC8'), mat('Z4Mouth', '#2A1510'), mat('IBFrost', '#E6F6FC')
t = Obj('Torso')
t.box(SKIN, (0, 0, 3.05), (2.2, 1.2, 2.16))
t.box(VEST, (-0.62, -0.6, 3.0), (0.86, 0.06, 2.0)).box(VEST, (0.62, -0.6, 3.0), (0.86, 0.06, 2.0)).box(VEST, (0, 0.6, 3.0), (2.24, 0.06, 2.0))
for sx in (-1, 1): t.box(VEST, (sx * 1.1, 0, 3.0), (0.06, 1.24, 2.0)).box(VEST2, (sx * 0.62, -0.64, 2.4), (0.5, 0.04, 0.4))
t.box(ROPE, (0, 0, 2.08), (2.26, 1.28, 0.2))
t.box(SKIN2, (-0.3, -0.62, 3.6), (0.5, 0.03, 0.4)).box(SKIN2, (0.3, -0.62, 3.6), (0.5, 0.03, 0.4))   # pecs
# ice crystals growing from the shoulders and the back
for (x, y, z, s, rx, ry) in ((-0.9, 0.2, 4.4, 0.7, -20, -25), (-0.6, 0.4, 4.5, 0.5, -30, -10), (0.9, 0.2, 4.4, 0.8, -20, 25), (0.55, 0.45, 4.6, 0.55, -35, 15),
                             (0, 0.75, 4.0, 0.9, -40, 0), (-0.45, 0.75, 3.4, 0.6, -50, -20), (0.45, 0.75, 3.2, 0.7, -50, 20), (0, 0.72, 2.7, 0.5, -60, 0)):
    t.box(ICE, (x, y, z), (0.36 * s * 1.4, 0.36 * s * 1.4, 1.3 * s), rot=(rx, ry, 0), taper=(0.3, 0.3))
    t.box(ICE2, (x + 0.05, y - 0.05, z - 0.2 * s), (0.2 * s, 0.2 * s, 0.6 * s), rot=(rx, ry, 0))
t.box(FROST, (0.7, -0.64, 2.6), (0.4, 0.03, 0.5))
t.build()
h = Obj('Head')
h.box(SKIN, (0, -0.05, 4.75), (1.5, 1.4, 1.36))
h.box(SKIN2, (0, -0.68, 4.25), (1.56, 0.34, 0.5))                      # jaw
h.box(SKIN2, (0, -0.74, 5.2), (1.4, 0.12, 0.2))                        # brow
h.box(DARK, (-0.34, -0.755, 4.95), (0.4, 0.04, 0.26)).box(GLOW, (-0.33, -0.775, 4.95), (0.2, 0.03, 0.14))
h.box(DARK, (0.34, -0.755, 4.95), (0.4, 0.04, 0.26)).box(GLOW, (0.35, -0.775, 4.95), (0.2, 0.03, 0.14))
h.box(MOUTH, (0, -0.86, 4.3), (1.0, 0.04, 0.22))
for x in (-0.36, 0.36): h.box(TEETH, (x, -0.87, 4.5), (0.14, 0.03, 0.26))            # tusks up
for x in (-0.12, 0.12): h.box(TEETH, (x, -0.87, 4.33), (0.12, 0.03, 0.1))
h.build()
c = Obj('Hat')  # ice crown on the head
for (x, z, s) in ((-0.45, 5.6, 0.6), (0, 5.75, 0.8), (0.45, 5.6, 0.55), (0.2, 5.5, 0.4)):
    c.box(ICE3, (x, 0.1, z), (0.3 * s * 1.4, 0.3 * s * 1.4, 1.0 * s), rot=(-10, 0, x * 30), taper=(0.3, 0.3))
c.build()
def arm(name, sx):
    a = Obj(name); x = 1.62 * sx
    a.box(SKIN, (x, 0, 3.25), (1.2, 1.2, 1.7))
    a.box(ROPE, (x, 0, 2.6), (1.26, 1.26, 0.16))
    a.box(SKIN2, (x, 0, 2.2), (1.24, 1.24, 0.7))
    # huge ice block fist
    a.box(ICE, (x, -0.05, 1.45), (1.7, 1.7, 1.3)).box(ICE2, (x - 0.3 * sx, -0.5, 1.75), (0.6, 0.5, 0.5), rot=(15, 0, 10))
    a.box(ICE3, (x + 0.4 * sx, 0.3, 1.0), (0.7, 0.6, 0.5), rot=(0, 20, 0))
    for (dx, dz) in ((-0.5, 0.9), (0.5, 1.0), (0, 0.8)): a.box(ICE2, (x + dx, -0.6, dz), (0.3, 0.3, 0.6), rot=(160, 0, dx * 30), taper=(0.3, 0.3))
    a.build()
arm('RightArm', 1); arm('LeftArm', -1)
def leg(name, sx):
    l = Obj(name); x = 0.55 * sx
    l.box(PANTS, (x, 0, 1.3), (1.1, 1.16, 1.4)).box(PANTS2, (x, -0.6, 1.0), (0.7, 0.05, 0.6))
    l.box(FROST, (x, 0, 0.7), (1.16, 1.22, 0.2))
    l.box(BOOT, (x, -0.1, 0.32), (1.18, 1.4, 0.6)).box(SOLE, (x, -0.1, 0.05), (1.22, 1.46, 0.12))
    l.build()
leg('RightLeg', 1); leg('LeftLeg', -1)
scale_all(1.5)
if '--export' in sys.argv: export('/home/claude/mobs4/out_models/myw_zombieicebrute.glb')
print(render_preview('/home/claude/mobs4/out_models/ib.png', center=(0, 0, 5.2), dist=19))
