import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
SKIN, SKIN2 = mat('Z5Skin', '#7FA55A'), mat('Z5Skin2', '#5C7F3E')
COAT, COAT2, COAT3 = mat('CMCoat', '#3F4A2C'), mat('CMCoat2', '#2F3820'), mat('CMCoat3', '#4E5A36')
GOLD, GOLD2, RED, RED2 = mat('CMGold', '#E8C24A'), mat('CMGold2', '#B8902A'), mat('CMRed', '#C8342C'), mat('CMRed2', '#8E2420')
MEDAL1, MEDAL2, MEDAL3 = mat('CMMedal1', '#3A7AD8'), mat('CMMedal2', '#D83A3A'), mat('CMMedal3', '#E8E2D2')
CAP, CAP2, VISOR = mat('CMCap', '#4A5632'), mat('CMCap2', '#3A4426'), mat('CMVisor', '#1E1F22')
PANTS, BOOT, SOLE, BELT = mat('CMPants', '#2F3820'), mat('CMBoot', '#141414'), mat('CMSole', '#0C0C0C'), mat('CMBelt', '#2A2018')
DARK, EYE, TEETH, MOUTH, BLOOD = mat('Z5Dark', '#141620'), mat('CMEye', '#FF4A2A', 3.0), mat('Z5Teeth', '#E2DFC8'), mat('Z5Mouth', '#2A1510'), mat('Z5Wound', '#7A2E22')
CIGAR, ASH, EMBER = mat('CMCigar', '#6A3E1E'), mat('CMAsh', '#9A9A96'), mat('CMEmber', '#FF7A2A', 3.0)
GREN, GREN2, PIN = mat('CMGrenade', '#4C5A2E'), mat('CMGrenade2', '#36401F'), mat('CMPin', '#C9CDD2')
t = Obj('Torso')
t.box(COAT, (0, 0, 3.05), (2.12, 1.18, 2.14))
t.box(COAT2, (0, -0.6, 3.05), (0.1, 0.04, 2.0))
for z in (3.7, 3.3, 2.9, 2.5):
    for x in (-0.3, 0.3): t.box(GOLD, (x, -0.61, z), (0.14, 0.04, 0.14))
t.box(COAT3, (0, -0.2, 4.0), (1.4, 0.9, 0.3))            # collar
for x in (-0.55, 0.55): t.box(RED, (x, -0.62, 4.0), (0.3, 0.04, 0.2))   # collar tabs
# medals on the left chest
for i, m in enumerate((MEDAL1, MEDAL2, MEDAL3)):
    x = 0.45 + i * 0.22
    t.box(m, (x, -0.62, 3.65), (0.18, 0.04, 0.16)).box(GOLD, (x, -0.63, 3.45), (0.14, 0.04, 0.14))
t.box(RED, (0, -0.1, 3.1), (2.2, 1.3, 0.2), rot=(0, 35, 0))   # sash
t.box(BELT, (0, 0, 2.2), (2.2, 1.28, 0.26)).box(GOLD, (0, -0.66, 2.2), (0.36, 0.04, 0.22))
for x in (-0.75, 0.75): t.box(GREN, (x, -0.72, 2.05), (0.3, 0.3, 0.36)).box(GREN2, (x, -0.72, 2.26), (0.16, 0.16, 0.1))  # grenades on the belt
t.box(COAT, (0, 0, 1.75), (2.2, 1.24, 0.7))               # coat skirt
t.box(COAT2, (0, -0.63, 1.75), (0.1, 0.04, 0.66))
t.build()
h = Obj('Head')
h.box(SKIN, (0, 0, 4.85), (1.62, 1.5, 1.58))
h.box(SKIN2, (0, -0.81, 4.78), (0.26, 0.14, 0.3))
h.box(DARK, (-0.37, -0.765, 5.0), (0.44, 0.04, 0.3)).box(EYE, (-0.35, -0.785, 5.0), (0.18, 0.03, 0.14))
h.box(DARK, (0.37, -0.765, 5.0), (0.44, 0.04, 0.3)).box(EYE, (0.39, -0.785, 5.0), (0.16, 0.03, 0.14))
h.box(DARK, (0, -0.765, 5.25), (1.1, 0.04, 0.1), rot=(0, -8, 0))   # angry brows
h.box(MOUTH, (0, -0.775, 4.42), (0.8, 0.04, 0.2))
for x in (-0.25, 0, 0.25): h.box(TEETH, (x, -0.785, 4.47), (0.12, 0.03, 0.1))
h.box(CIGAR, (0.42, -1.05, 4.42), (0.14, 0.6, 0.14)).box(ASH, (0.42, -1.38, 4.42), (0.15, 0.08, 0.15)).box(EMBER, (0.42, -1.43, 4.42), (0.12, 0.04, 0.12))
h.box(SKIN2, (-0.55, -0.77, 4.3), (0.3, 0.03, 0.2)).box(BLOOD, (0.6, -0.78, 5.25), (0.18, 0.03, 0.2))
h.build()
c = Obj('Hat')
c.box(CAP, (0, 0.1, 5.95), (2.1, 2.0, 0.42)).box(CAP2, (0, 0.04, 5.68), (1.7, 1.6, 0.24))
c.box(RED, (0, 0.04, 5.62), (1.72, 1.62, 0.14))
c.box(VISOR, (0, -0.85, 5.55), (1.5, 0.5, 0.08), rot=(-12, 0, 0))
c.box(GOLD, (0, -0.85, 5.95), (0.36, 0.06, 0.3)).box(GOLD2, (0, -0.83, 5.62), (1.3, 0.04, 0.06))
c.build()
def arm(name, sx):
    a = Obj(name); x = 1.53 * sx
    a.box(COAT, (x, 0, 3.3), (1.12, 1.12, 1.5)).box(COAT2, (x, 0, 2.5), (1.14, 1.14, 0.16))
    a.box(GOLD, (x, 0, 4.06), (1.2, 1.2, 0.14)).box(GOLD2, (x, 0, 3.98), (1.16, 1.16, 0.06))   # epaulettes
    for dx in (-0.4, -0.2, 0, 0.2, 0.4): a.box(GOLD, (x + dx, -0.62, 4.0), (0.06, 0.04, 0.12))
    a.box(GOLD, (x, 0, 2.65), (1.16, 1.16, 0.06))
    a.box(SKIN, (x, 0, 2.05), (0.94, 0.94, 0.8))
    a.box(SKIN2, (x, 0, 1.55), (0.96, 0.96, 0.3))
    for dx in (-0.3, 0, 0.3): a.box(SKIN2, (x + dx, -0.12, 1.32), (0.24, 0.56, 0.28))
    a.build()
arm('RightArm', 1); arm('LeftArm', -1)
def leg(name, sx):
    l = Obj(name); x = 0.53 * sx
    l.box(PANTS, (x, 0, 1.2), (1.06, 1.12, 1.2)).box(RED, (x + 0.54 * sx, 0, 1.2), (0.03, 0.3, 1.2))   # red trouser stripe
    l.box(BOOT, (x, -0.06, 0.5), (1.12, 1.3, 1.0)).box(BOOT, (x, -0.06, 0.95), (1.16, 1.34, 0.12)).box(SOLE, (x, -0.06, 0.05), (1.16, 1.38, 0.12))
    l.build()
leg('RightLeg', 1); leg('LeftLeg', -1)
# grenade in the right hand (thrown)
g = Obj('Grenade', bevel=0.02)
X, Z = 1.53, 1.25
g.box(GREN, (X, -0.45, Z), (0.56, 0.56, 0.66)).box(GREN2, (X, -0.45, Z + 0.1), (0.6, 0.6, 0.08)).box(GREN2, (X, -0.45, Z - 0.1), (0.6, 0.6, 0.08))
g.box(GREN2, (X, -0.45, Z + 0.4), (0.26, 0.26, 0.16)).box(PIN, (X + 0.2, -0.45, Z + 0.42), (0.18, 0.04, 0.18)).box(GREN2, (X - 0.2, -0.45, Z + 0.28), (0.08, 0.1, 0.5))
g.build()
if '--export' in sys.argv: export('/home/claude/mobs5/out_models/myw_zombiecommander.glb')
print(render_preview('/home/claude/mobs5/out_models/cm.png', center=(0, 0, 3.4), dist=13))
