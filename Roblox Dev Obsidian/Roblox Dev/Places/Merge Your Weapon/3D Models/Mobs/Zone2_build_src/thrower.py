import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
SKIN, SKIN2, SCAR = mat('Z2Skin', '#7FA864'), mat('Z2Skin2', '#5F8549'), mat('ATScar', '#B8D79A')
HENLEY, HENLEY2 = mat('ATHenley', '#6E7380'), mat('ATHenley2', '#4C505B')
VEST, VEST2, LEATHER, LEATHER2 = mat('ATVest', '#3E5A2E'), mat('ATVest2', '#2C4220'), mat('ATLeather', '#6B4226'), mat('ATLeather2', '#4A2C18')
BANDANA, BANDANA2, DOT = mat('ATBandana', '#C42B2B'), mat('ATBandana2', '#8E1C1C'), mat('ATDot', '#F4F1E6')
PANTS, PANTS2, PAD, BOOT, SOLE = mat('ATPants', '#7A6A4A'), mat('ATPants2', '#5C4F36'), mat('ATKneePad', '#2B2D33'), mat('ATBoot', '#3A2414'), mat('ATSole', '#1C130B')
BANDAGE = mat('ATBandage', '#E6DFC8')
DARK, EYE, TEETH, MOUTH = mat('Z2Dark', '#141620'), mat('ATEye', '#FF5A2A', 3.0), mat('Z2Teeth', '#E8E6DA'), mat('Z2Mouth', '#2A1510')
WOOD, TAPE, STEEL, EDGE = mat('ATWood', '#3E2A1A'), mat('ATTape', '#1E1E22'), mat('ATSteel', '#7D838E'), mat('ATEdge', '#D6DAE0')
BRASS = mat('ATBrass', '#C9A227')

def hatchet(o, base, dirY=-1, s=1.0, up=(0, 0, 1)):
    """small throwing axe drawn along +Z (handle) from base; blade toward dirY"""
    x, y, z = base
    o.box(WOOD, (x, y, z + 0.75 * s), (0.18 * s, 0.18 * s, 1.5 * s))
    o.box(TAPE, (x, y, z + 0.3 * s), (0.22 * s, 0.22 * s, 0.5 * s))
    o.box(STEEL, (x, y + dirY * 0.2 * s, z + 1.4 * s), (0.2 * s, 0.5 * s, 0.4 * s))
    o.box(EDGE, (x, y + dirY * 0.5 * s, z + 1.38 * s), (0.14 * s, 0.12 * s, 0.56 * s))

# ---------- torso: henley + open leather vest, bandolier with hatchets, harness with 3 axes on the back ----------
t = Obj('Torso')
t.box(HENLEY, (0, 0, 3.05), (2.0, 1.06, 2.1))
t.box(HENLEY2, (0, -0.545, 3.75), (0.3, 0.04, 0.7)).box(BRASS, (0, -0.57, 3.85), (0.08, 0.03, 0.08)).box(BRASS, (0, -0.57, 3.6), (0.08, 0.03, 0.08))
for sx in (-1, 1):
    t.box(VEST, (0.62 * sx, -0.55, 3.0), (0.78, 0.06, 2.0)).box(VEST2, (0.3 * sx, -0.585, 3.0), (0.08, 0.04, 2.0))
    t.box(VEST, (1.01 * sx, 0, 3.0), (0.06, 1.1, 2.0))
    t.box(VEST2, (0.66 * sx, -0.59, 2.55), (0.44, 0.04, 0.32))     # pockets
t.box(VEST, (0, 0.55, 3.0), (2.04, 0.06, 2.0))
t.box(LEATHER2, (0, -0.62, 3.05), (2.4, 0.08, 0.26), rot=(0, 42, 0))   # bandolier
for i in (-1, 0, 1): t.box(LEATHER, (i * 0.42, -0.67, 3.05 - i * 0.38), (0.22, 0.06, 0.34), rot=(0, 42, 0))
t.box(LEATHER2, (0, 0, 2.12), (2.08, 1.14, 0.24)).box(BRASS, (0, -0.59, 2.12), (0.3, 0.06, 0.24))
t.box(LEATHER2, (0, 0.62, 3.2), (2.2, 0.08, 0.24), rot=(0, -40, 0)).box(LEATHER2, (0, 0.62, 3.2), (2.2, 0.08, 0.24), rot=(0, 40, 0))
for (x, rz) in ((-0.55, 18), (0, 0), (0.55, -18)):   # 3 axes in the back harness, heads sticking up over the shoulders
    o = Obj('tmp')
t.box(WOOD, (-0.55, 0.72, 3.4), (0.16, 0.16, 1.9), rot=(0, 20, 0)).box(STEEL, (-0.9, 0.72, 4.35), (0.46, 0.18, 0.38), rot=(0, 20, 0)).box(EDGE, (-1.15, 0.72, 4.28), (0.12, 0.14, 0.5), rot=(0, 20, 0))
t.box(WOOD, (0.55, 0.72, 3.4), (0.16, 0.16, 1.9), rot=(0, -20, 0)).box(STEEL, (0.9, 0.72, 4.35), (0.46, 0.18, 0.38), rot=(0, -20, 0)).box(EDGE, (1.15, 0.72, 4.28), (0.12, 0.14, 0.5), rot=(0, -20, 0))
t.box(WOOD, (0, 0.74, 3.5), (0.16, 0.16, 2.0)).box(STEEL, (0, 0.74, 4.6), (0.18, 0.46, 0.38)).box(EDGE, (0, 0.96, 4.58), (0.14, 0.12, 0.5))
t.build()

# ---------- head: red bandana with knot tails, scar, glowing orange eyes, heavy jaw ----------
h = Obj('Head')
h.box(SKIN, (0, 0, 4.82), (1.6, 1.48, 1.56))
h.box(SKIN2, (0, -0.68, 4.25), (1.5, 0.3, 0.36))                       # heavy jaw
h.box(SKIN2, (0, -0.8, 4.78), (0.26, 0.16, 0.3))
for x in (-0.83, 0.83): h.box(SKIN2, (x, 0.05, 4.85), (0.1, 0.3, 0.32))
h.box(DARK, (-0.37, -0.755, 5.0), (0.46, 0.04, 0.3)).box(EYE, (-0.35, -0.775, 5.0), (0.18, 0.03, 0.14))
h.box(DARK, (0.37, -0.755, 5.0), (0.46, 0.04, 0.3)).box(EYE, (0.39, -0.775, 5.0), (0.18, 0.03, 0.14))
h.box(SKIN2, (-0.37, -0.765, 5.2), (0.52, 0.05, 0.12), rot=(0, -10, 0)).box(SKIN2, (0.37, -0.765, 5.2), (0.52, 0.05, 0.12), rot=(0, 10, 0))
h.box(SCAR, (0.42, -0.775, 4.95), (0.06, 0.03, 0.62), rot=(0, 18, 0))
for i, x in enumerate((-0.3, -0.1, 0.1, 0.3)): h.box(SCAR, (0.42 + (x * 0.3), -0.78, 4.95 + x * 0.9), (0.18, 0.03, 0.04), rot=(0, 18, 0))
h.box(MOUTH, (0, -0.835, 4.32), (0.9, 0.04, 0.2))
for x in (-0.33, -0.12, 0.1, 0.32): h.box(TEETH, (x, -0.85, 4.37 if x != 0.1 else 4.3), (0.13, 0.03, 0.12))
h.box(TEETH, (-0.45, -0.85, 4.47), (0.1, 0.03, 0.16))                   # tusk-like tooth
h.build()
c = Obj('Hat')
c.box(BANDANA, (0, 0, 5.52), (1.66, 1.54, 0.34)).box(BANDANA, (0, 0.06, 5.68), (1.56, 1.4, 0.16), taper=(0.9, 0.9))
for (x, y, z) in ((-0.5, -0.78, 5.5), (0.1, -0.78, 5.56), (0.55, -0.78, 5.48), (-0.84, 0.2, 5.52), (0.84, -0.2, 5.55)):
    c.box(DOT, (x, y, z), (0.1 if abs(x) > 0.8 else 0.12, 0.03 if abs(x) < 0.8 else 0.12, 0.1))
c.box(BANDANA2, (0, 0.8, 5.45), (0.36, 0.2, 0.3)).box(BANDANA, (-0.15, 0.95, 5.1), (0.22, 0.08, 0.6), rot=(18, 15, 0)).box(BANDANA, (0.16, 0.92, 5.15), (0.22, 0.08, 0.5), rot=(12, -20, 0))
c.build()

# ---------- arms: bare, leather bracers, right forearm bandaged ----------
def arm(name, sx):
    a = Obj(name); x = 1.48 * sx
    a.box(HENLEY, (x, 0, 3.55), (1.06, 1.06, 0.95)).box(VEST2, (x, 0, 3.98), (1.1, 1.1, 0.12))
    a.box(SKIN, (x, 0, 2.5), (0.94, 0.94, 1.2))
    a.box(LEATHER, (x, 0, 2.05), (1.0, 1.0, 0.5)).box(BRASS, (x, -0.51, 2.1), (0.14, 0.04, 0.14))
    if sx > 0:
        for z in (2.45, 2.7, 2.95): a.box(BANDAGE, (x, 0, z), (0.98, 0.98, 0.12), rot=(0, 8 if z != 2.7 else -8, 0))
    a.box(SKIN2, (x, 0, 1.62), (0.96, 0.96, 0.36))
    for dx in (-0.29, 0, 0.29): a.box(SKIN2, (x + dx, -0.12, 1.36), (0.22, 0.56, 0.3))
    a.build()
arm('RightArm', 1); arm('LeftArm', -1)

def leg(name, sx):
    l = Obj(name); x = 0.52 * sx
    l.box(PANTS, (x, 0, 1.3), (1.04, 1.1, 1.4)).box(PANTS2, (x + 0.52 * sx, 0.0, 1.4), (0.06, 0.5, 0.5))
    l.box(PAD, (x, -0.58, 1.08), (0.7, 0.08, 0.5)).box(PAD, (x, -0.55, 1.08), (1.06, 0.04, 0.12))
    l.box(BOOT, (x, -0.08, 0.34), (1.1, 1.3, 0.62)).box(SOLE, (x, -0.08, 0.05), (1.14, 1.36, 0.1)).box(LEATHER2, (x, 0, 0.62), (1.14, 1.14, 0.1))
    l.build()
leg('RightLeg', 1); leg('LeftLeg', -1)

# ---------- hand axe (the one he throws), handle forward like a tool, blade down ----------
ax = Obj('HandAxe', bevel=0.02)
ax.box(WOOD, (1.48, -0.85, 1.5), (0.2, 2.0, 0.2))
ax.box(TAPE, (1.48, -0.05, 1.5), (0.24, 0.5, 0.24))
ax.box(STEEL, (1.48, -1.65, 1.25), (0.22, 0.44, 0.56))
ax.box(EDGE, (1.48, -1.65, 0.94), (0.16, 0.62, 0.14))
ax.box(STEEL, (1.48, -1.65, 1.64), (0.24, 0.22, 0.2))
ax.build()

scale_all(1.3)
if '--export' in sys.argv:
    export('/home/claude/mobs2/out_models/myw_zombieaxethrower.glb')
    bpy.ops.wm.save_as_mainfile(filepath='/home/claude/mobs2/out_models/myw_zombieaxethrower.blend')
print(render_preview('/home/claude/mobs2/out_models/at.png', center=(0, 0, 4.1), dist=16))
