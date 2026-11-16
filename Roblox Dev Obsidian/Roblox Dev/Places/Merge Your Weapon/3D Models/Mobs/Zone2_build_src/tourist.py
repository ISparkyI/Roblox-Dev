import sys; sys.path.insert(0, '/home/claude/mobs2/build')
from lib import *
reset()
SKIN, SKIN2 = mat('Z2Skin', '#7FA864'), mat('Z2Skin2', '#5F8549')
SHIRT, SHIRT2 = mat('TRShirt', '#21B5C9'), mat('TRShirt2', '#178A9A')
FL1, FL2, FL3, LEAF = mat('TRFlowerPink', '#FF5DA2'), mat('TRFlowerYellow', '#FFD23F'), mat('TRFlowerWhite', '#F4F1E6'), mat('TRLeaf', '#2E8B57')
TEE, SHORTS, SHORTS2 = mat('TRTee', '#F4F1E6'), mat('TRShorts', '#C8B07A'), mat('TRShorts2', '#A38D5B')
SOCK, SANDAL, SOLE = mat('TRSock', '#F2F2EE'), mat('TRSandal', '#7A4A24'), mat('TRSole', '#3A2412')
HAT, BAND = mat('TRHat', '#E9DDB5'), mat('TRBand', '#2E6FB5')
GLASS, FRAME, SUNSCREEN = mat('TRGlass', '#1C2A3A'), mat('TRFrame', '#E04A3A'), mat('TRSunscreen', '#FAFAFA')
PACK, PACK2, BEDROLL = mat('TRPack', '#F07A1A'), mat('TRPack2', '#B85A12'), mat('TRBedroll', '#4C7A3A')
BUM, BUM2 = mat('TRBumbag', '#8A3FD1'), mat('TRBumbag2', '#5E2A92')
CAM, CAM2, LENSG, FLASH = mat('TRCamera', '#26282E'), mat('TRCamera2', '#55585F'), mat('TRLensGlass', '#5AA9E6'), mat('TRFlash', '#F7F7F2')
DARK, EYE, TEETH, MOUTH = mat('Z2Dark', '#141620'), mat('Z2Eye', '#F2D23A', 2.0), mat('Z2Teeth', '#E8E6DA'), mat('Z2Mouth', '#2A1510')

# ---------- torso: open hawaiian shirt over a tee, camera strap, bum bag, big backpack ----------
t = Obj('Torso')
t.box(SHIRT, (0, 0, 3.05), (1.96, 1.04, 2.1))
t.box(TEE, (0, -0.53, 3.25), (0.6, 0.04, 1.6), taper=(0.4, 1))         # tee showing in the V
t.box(SHIRT2, (-0.34, -0.55, 4.0), (0.44, 0.2, 0.14), rot=(0, 0, 28)).box(SHIRT2, (0.34, -0.55, 4.0), (0.44, 0.2, 0.14), rot=(0, 0, -28))
import random; random.seed(7)
for sy in (-0.535, 0.535):
    for (x, z, col) in [(-0.7, 3.7, FL1), (0.62, 3.45, FL2), (-0.55, 2.55, FL3), (0.7, 2.45, FL1), (-0.1 if sy > 0 else -0.75, 3.05, FL2), (0.35, 2.9 if sy > 0 else 2.2, FL3)]:
        if sy < 0 and abs(x) < 0.35: continue
        t.box(col, (x, sy, z), (0.26, 0.04, 0.26), rot=(0, 30, 0))
        t.box(LEAF, (x + 0.2, sy, z - 0.14), (0.16, 0.035, 0.1), rot=(0, -30, 0))
for sx in (-0.985, 0.985):
    t.box(FL2, (sx, -0.2, 3.5), (0.04, 0.26, 0.26)).box(FL1, (sx, 0.25, 2.6), (0.04, 0.26, 0.26))
for x in (-0.2,): t.box(SHIRT2, (x, -0.55, 2.9), (0.08, 0.03, 0.08))
t.box(CAM, (0, -0.55, 3.1), (1.6, 0.04, 0.1), rot=(0, -38, 0))         # camera strap across the chest
t.box(BUM, (0, -0.62, 2.18), (1.0, 0.3, 0.42)).box(BUM2, (0, -0.78, 2.22), (0.8, 0.05, 0.12)).box(CAM, (0, 0, 2.08), (2.0, 1.1, 0.12))
t.box(PACK, (0, 0.95, 3.0), (1.6, 0.8, 1.9)).box(PACK2, (0, 1.36, 2.7), (1.1, 0.14, 0.8)).box(PACK2, (0, 0.95, 3.98), (1.66, 0.86, 0.16))
for x in (-0.55, 0.55): t.box(PACK2, (x, -0.54, 3.4), (0.2, 0.05, 1.5)).box(PACK2, (x, 0.0, 4.09), (0.2, 1.1, 0.06))
t.cyl(BEDROLL, (0, 1.0, 4.35), 0.32, 1.9, axis='X', seg=10).cyl(PACK2, (-0.6, 1.0, 4.35), 0.34, 0.1, axis='X', seg=10).cyl(PACK2, (0.6, 1.0, 4.35), 0.34, 0.1, axis='X', seg=10)
t.build()

# ---------- head: bucket hat, red sunglasses pushed up (one lens missing), sunscreen on the nose ----------
h = Obj('Head')
h.box(SKIN, (0, 0, 4.82), (1.56, 1.46, 1.56))
h.box(SKIN2, (0, -0.78, 4.78), (0.22, 0.14, 0.32)).box(SUNSCREEN, (0, -0.855, 4.86), (0.2, 0.03, 0.14))
for x in (-0.81, 0.81): h.box(SKIN2, (x, 0.05, 4.85), (0.1, 0.32, 0.36))
h.box(DARK, (-0.36, -0.745, 4.98), (0.4, 0.04, 0.36)).box(EYE, (-0.34, -0.765, 4.98), (0.15, 0.03, 0.15))
h.box(DARK, (0.36, -0.745, 4.98), (0.4, 0.04, 0.36)).box(EYE, (0.4, -0.765, 4.92), (0.15, 0.03, 0.15))
h.box(MOUTH, (0.05, -0.745, 4.35), (0.76, 0.04, 0.26), rot=(0, 6, 0))
for x in (-0.2, 0.06, 0.3): h.box(TEETH, (x, -0.76, 4.43), (0.12, 0.03, 0.1))
h.box(FRAME, (0, -0.76, 5.32), (1.4, 0.06, 0.08))                      # glasses pushed up on the forehead
h.box(FRAME, (-0.36, -0.77, 5.3), (0.46, 0.06, 0.3)).box(GLASS, (-0.36, -0.79, 5.3), (0.36, 0.03, 0.2))
h.box(FRAME, (0.36, -0.77, 5.3), (0.46, 0.06, 0.3))
for x in (-0.76, 0.76): h.box(FRAME, (x, -0.35, 5.3), (0.05, 0.8, 0.06))
h.build()
c = Obj('Hat')
c.box(HAT, (0, 0.02, 5.82), (1.5, 1.42, 0.46), taper=(0.92, 0.92)).box(BAND, (0, 0.02, 5.66), (1.54, 1.46, 0.14))
c.box(HAT, (0, 0.02, 5.6), (2.3, 2.2, 0.08), taper=(0.97, 0.97))
c.box(HAT, (0.75, -0.78, 5.56), (0.4, 0.3, 0.06), rot=(14, 0, 20))   # bent brim corner
c.box(FL1, (0.5, -0.72, 5.68), (0.18, 0.06, 0.18))
c.build()

# ---------- arms: short sleeves, bare arms, a wristwatch; camera in the right hand ----------
def arm(name, sx):
    a = Obj(name); x = 1.42 * sx
    a.box(SHIRT, (x, 0, 3.6), (1.04, 1.04, 0.8)).box(SHIRT2, (x, 0, 3.17), (1.08, 1.08, 0.12))
    a.box(FL1 if sx > 0 else FL2, (x, -0.525, 3.65), (0.24, 0.04, 0.24), rot=(0, 25, 0))
    a.box(SKIN, (x, 0, 2.35), (0.86, 0.86, 1.6))
    if sx < 0: a.box(CAM, (x, 0, 1.92), (0.9, 0.9, 0.16)).box(FLASH, (x, -0.46, 1.92), (0.24, 0.04, 0.18))
    a.box(SKIN2, (x, 0, 1.5), (0.9, 0.9, 0.3))
    for dx in (-0.27, 0, 0.27): a.box(SKIN2, (x + dx, -0.12, 1.26), (0.2, 0.52, 0.28))
    a.build()
arm('RightArm', 1); arm('LeftArm', -1)

# ---------- legs: cargo shorts, socks pulled up (one fell down), sandals ----------
def leg(name, sx, sockDown):
    l = Obj(name); x = 0.5 * sx
    l.box(SHORTS, (x, 0, 1.55), (1.0, 1.04, 0.9)).box(SHORTS2, (x + 0.5 * sx, -0.1, 1.45), (0.06, 0.5, 0.44))   # side pocket
    l.box(SHORTS2, (x, 0, 1.12), (1.04, 1.08, 0.08))
    l.box(SKIN, (x, 0, 0.72), (0.84, 0.84, 0.8))
    if sockDown: l.box(SOCK, (x, 0, 0.36), (0.9, 0.9, 0.2))
    else: l.box(SOCK, (x, 0, 0.55), (0.88, 0.88, 0.62)).box(BAND, (x, 0, 0.8), (0.9, 0.9, 0.08))
    l.box(SANDAL, (x, -0.08, 0.12), (0.98, 1.24, 0.12)).box(SOLE, (x, -0.08, 0.03), (1.0, 1.26, 0.06))
    l.box(SANDAL, (x, -0.35, 0.26), (0.92, 0.1, 0.12))
    l.build()
leg('RightLeg', 1, False); leg('LeftLeg', -1, True)

# ---------- camera in the right hand (lens points forward) ----------
cm = Obj('Camera', bevel=0.02)
cm.box(CAM, (1.42, -0.55, 1.5), (0.9, 0.5, 0.62)).box(CAM2, (1.42, -0.55, 1.86), (0.4, 0.4, 0.14)).box(FLASH, (1.62, -0.55, 1.88), (0.3, 0.3, 0.1))
cm.cyl(CAM2, (1.42, -0.95, 1.48), 0.26, 0.4, axis='Y', seg=12)
cm.build()
ln = Obj('CameraLens', bevel=0.0)
ln.cyl(LENSG, (1.42, -1.16, 1.48), 0.19, 0.04, axis='Y', seg=12)
ln.build()

if '--export' in sys.argv:
    export('/home/claude/mobs2/out_models/myw_zombietourist.glb')
    bpy.ops.wm.save_as_mainfile(filepath='/home/claude/mobs2/out_models/myw_zombietourist.blend')
print(render_preview('/home/claude/mobs2/out_models/tr.png'))
