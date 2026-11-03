# Platinum Golem (Mythic, мапа 4): платиновий суверен-механізм — дзеркальна платина на графітовому металі, сатинові вставки й
# фіолетове світло (Neon). Фірмове: на грудях левітує ГІРОСКОП — світне ядро в двох рамках, що обертаються навхрест (Y і X);
# на спині — реактивний ранець із трьома платиновими стабілізаторами і двома соплами, що пульсують; над плечима ширяють
# платинові пластини (гойдаються); на голові — платиновий обруч з діадемою і крильця-стабілізатори.
# Анімації (GolemAnimator v3.3): fx — рамки гіроскопа обертаються навхрест, ядро крутиться, сопла пульсують, пластини над плечима
# пливуть; poses — хода з поворотом корпусу за кроком (руки майже нерухомі), біг спринтера (нахил і сильна робота рук), у спокої
# схиляє голову, розглядаючи гіроскоп, носій трохи відхиляється назад.
# Інструменти власної форми (не шаблон, не рапіра, не шабля):
#   кірка — бур-кайло: платинова голова, донизу — скручений бур із трьох квадратних сегментів (повернуті через 45°) і світних
#           кілець між ними, кінчик Pick4 на стандартному місці; угору — шестигранний молот зі світним бойком;
#   меч — фламберг: хвиляста лінія леза (зигзаг з шести сегментів) зі світним долом, сатинове рікассо з вусами-упорами, широка
#         гарда з квілонами, нахиленими до леза, і світними кулями, шестигранне навершя.
# Ящик — сейф-сховище: графітові стінки в платиновій рамі, болти на стійках, на зовнішньому боці — кодове колесо сейфа;
# ручки — кільця-«калатала» на кронштейнах.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(plat="#ecebe6", gun="#2c2b2f", satin="#b9b2a2", glow="#5a3cff", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4"))
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
OCTA = eul(rx=35.264) @ eul(rz=45)
# ---------- ноги ----------
a("Foot_R","Shin_R","gun",(2.15,0.55,0.15),(3.0,1.1,3.5),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","plat",(2.1,2.2,-0.2),(2.5,2.3,2.5),eul(ry=4),mirror=True)
a("Greave_R","Shin_R","satin",(2.1,2.15,1.12),(1.4,1.6,0.3),mirror=True)
a("KneeBolt_R","Shin_R","glow",(2.1,3.3,1.0),(0.55,0.55,0.55),OCTA,mirror=True)
a("Thigh_R","Thigh_R","gun",(2.0,3.95,-0.25),(2.6,1.7,2.6),eul(ry=-6),mirror=True)
a("Pelvis","Hips","gun",(0,4.85,-0.35),(5.8,1.6,3.4))
a("Belt","Hips","plat",(0,5.4,-0.35),(6.0,0.45,3.6))
a("BeltGem","Hips","glow",(0,5.4,1.55),(0.55,0.55,0.55),OCTA)
# ---------- корпус: гіроскоп на грудях ----------
a("Torso","Torso","plat",(0,7.4,-0.3),(6.8,4.0,4.0))
a("Chest","Torso","gun",(0,9.45,-0.4),(7.8,1.8,4.6))
a("Collar","Torso","plat",(0,10.25,-0.4),(4.6,0.4,3.6))
GY = np.array((0, 7.5, 3.0))
a("SocketRim","Torso","satin",(0,7.5,1.76),(1.7,1.7,0.12))
a("SocketGlow","Torso","glow",(0,7.5,1.83),(1.2,1.2,0.1))
a("GyroCore","Torso","glow",tuple(GY),(0.36,0.36,0.36),OCTA)
RA, RB = [], []
for nm, pos, s in (("RingA1",(0,0.9,0),(1.58,0.16,0.16)),("RingA2",(0,-0.9,0),(1.58,0.16,0.16)),
                   ("RingA3",(0.9,0,0),(0.22,1.98,0.22)),("RingA4",(-0.9,0,0),(0.22,1.98,0.22))):
    a(nm,"Torso","gun",tuple(GY + pos),s); RA.append(nm)
for nm, pos, s in (("RingB1",(0,0.42,0),(0.72,0.09,0.09)),("RingB2",(0,-0.42,0),(0.72,0.09,0.09)),
                   ("RingB3",(0.42,0,0),(0.12,0.96,0.12)),("RingB4",(-0.42,0,0),(0.12,0.96,0.12))):
    a(nm,"Torso","satin",tuple(GY + pos),s); RB.append(nm)
# ---------- спина: реактивний ранець ----------
a("Pack","Torso","gun",(0,8.0,-2.7),(2.4,2.8,0.8))
for sx, nm in ((1, "R"), (-1, "L")):
    a(f"Nozzle{nm}","Torso","glow",(0.6*sx,6.45,-2.75),(0.6,0.3,0.5))
for nm, sx, L in (("FinC", 0, 2.6), ("FinR", 1, 2.0), ("FinL", -1, 2.0)):
    R = eul(rz=-25*sx) @ eul(rx=-20); base = np.array((0.75*sx, 9.3, -2.8))
    a(nm,"Torso","plat",tuple(base + R[:, 1] * (L/2 - 0.2)),(0.3 if sx == 0 else 0.26, L, 1.1 if sx == 0 else 0.9),R)
# ---------- голова: обруч із діадемою, крильця ----------
a("Head","Head","plat",(0,11.15,0.5014),(3.8,2.7,3.4))
a("Jaw","Head","gun",(0,10.0,0.7),(3.4,0.8,2.7))
a("Circlet","Head","satin",(0,12.55,0.5),(4.0,0.4,3.6))
a("Diadem","Head","glow",(0,12.6,2.35),(0.55,0.55,0.55),OCTA)
a("EarFin_R","Head","plat",(2.05,11.7,0.2),(0.3,1.8,1.0),eul(rz=-15) @ eul(rx=-30),mirror=True)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","glow",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.2,2.24),(1.2,0.3,0.3),eul(rz=-6),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.46,2.3014),(1.1,0.28,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.26,0.5),mirror=True)
# ---------- руки: пластини, що ширяють над плечима ----------
a("Shoulder_R","UpperArm_R","gun",(5.0,9.85,-0.3),(3.2,1.8,3.4),eul(rz=4),mirror=True)
a("Pauldron_R","UpperArm_R","plat",(5.1,10.9,-0.3),(3.0,0.4,3.2),eul(rz=4),mirror=True)
a("Pauldron2_R","UpperArm_R","satin",(5.12,11.24,-0.3),(2.6,0.36,2.8),eul(rz=4),mirror=True)
a("SkyPlate_R","UpperArm_R","plat",(5.2,12.3,-0.3),(2.4,0.25,2.6),eul(rz=-10),mirror=True)
a("SkyGem_R","UpperArm_R","glow",(5.2,12.5,-0.3),(0.4,0.4,0.4),eul(rz=-10) @ OCTA,mirror=True)
a("UpperArm_R","UpperArm_R","gun",(5.25,8.0,-0.3),(2.2,2.6,2.3),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","plat",(5.55,5.75,0.0014),(2.7,2.4,2.8),eul(ry=-6),mirror=True)
a("Cuff_R","Forearm_R","satin",(5.55,6.55,0.0014),(2.9,0.4,3.0),eul(ry=-6),mirror=True)
a("ElbowBolt_R","Forearm_R","glow",(6.95,6.2,-0.1),(0.5,0.5,0.5),OCTA,mirror=True)
fist = a("Fist_R","Forearm_R","gun",(5.65,3.45,0.1014),(3.2,2.4,3.2),eul(ry=6.875))
sub(fist,"Knuckles_R","plat",(0.15,0.3,1.62),(2.6,0.8,0.4))
sub(fist,"KnuckleRune_R","glow",(0.15,0.3,1.87),(1.9,0.14,0.12))
sub(fist,"Thumb_R","gun",(-1.7,0.1,0.95),(0.5,1.0,0.9),eul(rz=-6)); mir(4)

# ---------- допоміжне для предметів ----------
X = np.array([1.0, 0, 0])
def frameY(d):
    d = d / np.linalg.norm(d); z = np.cross(X, d); z /= np.linalg.norm(z)
    return np.column_stack([X, d, z])
def seg(grp, name, col, p0, p1, w, t=None, extra=0.0, off=0.0, twist=0):
    p0, p1 = np.array(p0, float), np.array(p1, float); R = frameY(p1 - p0) @ eul(ry=twist)
    L = np.linalg.norm(p1 - p0) + extra; c = (p0 + p1) / 2 + frameY(p1 - p0)[:, 2] * off; t = w if t is None else t
    return g.item(name, grp, col, c, R, (w, L, t))
u = np.array([0, 0.1215, 0.99259]); wv = np.array([0, -0.99259, 0.1215])
A = PICK["Handle"][1]

# ---------- кірка — бур-кайло ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","satin"); P("Grip","gun")
sub(HN,"Wrap1","plat",(0,1.3,0),(0.8,0.5,0.8))
sub(HN,"Wrap2","plat",(0,2.4,0),(0.8,0.5,0.8))
PM = P("Pommel","plat",(0.85,0.6,0.85))
sub(PM,"PommelGem","glow",(0,-0.55,0),(0.5,0.5,0.5),OCTA)
H = np.array(PICK["Head"][0])
HD = g.item("Head","Pickaxe","plat",tuple(H),A,(1.0,1.1,1.6))
sub(HD,"HeadRune","glow",(0,0,0),(1.06,0.16,1.0))
p4c, p4R, p4s = PICK["Pick4"]; p4c = np.array(p4c); p4back = p4c - p4R[:, 2] * p4s[2] / 2
S0 = H + wv * 0.6
pts = [S0 + (p4back - S0) * f for f in (0, 0.36, 0.69, 1.0)]
for i, (w, tw) in enumerate(((0.66, 0), (0.56, 45), (0.48, 0)), 1):
    seg("Pickaxe", f"Pick{i}", "plat" if i != 2 else "satin", pts[i-1], pts[i], w, w, extra=0.3, twist=tw)
for i in (1, 2):
    d = pts[i] - pts[i-1]
    g.item(f"DrillRing{i}","Pickaxe","glow",tuple(pts[i]),frameY(d) @ eul(ry=22.5),((0.76, 0.64)[i-1], 0.14, (0.76, 0.64)[i-1]))
g.item("Pick4","Pickaxe","glow",tuple(p4c),p4R,p4s)
sub(HD,"HammerNeck","satin",(0,0,-0.95),(0.7,0.7,0.6))
for i, ang in enumerate((0, 60, 120)):
    sub(HD,f"Hex{i+1}","plat",(0,0,-1.6),(1.3,0.75,1.0 - 0.06*i),eul(rz=ang))
sub(HD,"HammerFace","glow",(0,0,-2.13),(0.7,0.7,0.1),eul(rz=30))

# ---------- меч — фламберг ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordGrip","gun"); S("SwordCoil1","plat"); S("SwordCoil2","plat")
g0 = np.array(SWORD["SwordGrip"][0])
def at(aa, bb=0.0): return g0 + u * aa + wv * bb
for i, ang in enumerate((0, 60, 120)):
    g.item("SwordPommel" if i == 0 else f"PommelHex{i}","Sword","plat",tuple(at(-2.15)),A @ eul(ry=ang),(0.9,0.6 - 0.05*i,0.52))
g.item("PommelGem","Sword","glow",tuple(at(-2.6)),A @ OCTA,(0.42,0.42,0.42))
g.item("SwordGuard","Sword","plat",tuple(at(2.25)),A,(0.3,0.42,2.9))
for sb, nm in ((1, "R"), (-1, "L")):
    q0, q1 = at(2.25, 1.3*sb), at(2.95, 1.85*sb)
    seg("Sword", f"Quillon{nm}", "plat", q0, q1, 0.26, 0.3, extra=0.2)
    d = (q1 - q0) / np.linalg.norm(q1 - q0)
    g.item(f"QuillonOrb{nm}","Sword","glow",tuple(q1 + d * 0.22),A @ OCTA,(0.42,0.42,0.42))
    seg("Sword", f"Lug{nm}", "satin", at(3.55, 0.3*sb), at(3.3, 0.78*sb), 0.22, 0.22, extra=0.1)
seg("Sword", "SwordBlade", "satin", at(2.4), at(3.75), 0.4, 0.78, extra=0.1)
wave = [at(3.7, 0), at(4.7, 0.2), at(5.7, -0.2), at(6.7, 0.2), at(7.7, -0.2), at(8.6, 0.12), at(9.4, 0)]
widths = (1.15, 1.1, 1.05, 0.95, 0.8, 0.62); thick = (0.3, 0.22, 0.3, 0.22, 0.28, 0.2)
for i in range(6):
    seg("Sword", f"Blade{i+2}", "plat", wave[i], wave[i+1], thick[i], widths[i], extra=0.2)
seg("Sword", "Fuller", "glow", at(3.9), at(8.4), 0.36, 0.14)
d = wave[6] - wave[5]
g.item("SwordTip","Sword","plat",tuple(wave[6] + d / np.linalg.norm(d) * 0.2),frameY(d) @ eul(ry=45),(0.36,0.7,0.36))

# ---------- ящик — сейф-сховище ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","gun",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","satin",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","gun",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","gun",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","gun",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","gun",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","plat",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","plat",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","plat",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","plat",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Post" + t, "plat", (1.87*sx, 1.035, 1.13*sz), (0.5, 1.67, 0.5))
        B("Bolt" + t, "satin", (1.87*sx, 2.12, 1.13*sz), (0.42, 0.42, 0.42), OCTA)
# кодове колесо сейфа на зовнішньому боці (-Z)
B("Dial1","plat",(0,0.98,-1.2),(1.0,1.0,0.12)); B("Dial2","plat",(0,0.98,-1.2),(1.0,1.0,0.22),eul(rz=45))
B("Spoke1","satin",(0,0.98,-1.35),(0.14,1.3,0.12),eul(rz=22.5)); B("Spoke2","satin",(0,0.98,-1.35),(0.14,1.3,0.16),eul(rz=112.5))
B("DialCore","glow",(0,0.98,-1.42),(0.36,0.36,0.1),eul(rz=22.5))
# ручки — кільця-«калатала» на кронштейнах
for sx, nm in ((1, "R"), (-1, "L")):
    B(f"Arm{nm}","plat",(2.33*sx,1.67,0),(0.7,0.24,0.26))
    B(f"ArmBolt{nm}","glow",(2.05*sx,1.67,0),(0.32,0.32,0.32),OCTA)
    c = np.array((2.62*sx, 1.2, 0.0)); r = 0.4
    vs = [c + r * np.array((np.cos(np.radians(22.5 + 45*k)), np.sin(np.radians(22.5 + 45*k)), 0)) for k in range(9)]
    for k in range(8):
        p0, p1 = vs[k], vs[k+1]; dd = p1 - p0; L = np.linalg.norm(dd) + 0.12
        xx = dd / np.linalg.norm(dd); zz = np.array((0, 0, 1.0)); yy = np.cross(zz, xx)
        th = (0.16, 0.12)[k % 2]
        B(f"Ring{k+1}{nm}", "glow" if k in (5, 6) else "plat", tuple((p0 + p1) / 2), (L, th, th), np.column_stack([xx, yy, zz]))

# ---------- унікальні рухи (GolemAnimator v3.3) ----------
g.free_parts = tuple(["GyroCore"] + RA + RB + ["SkyPlate_R", "SkyPlate_L", "SkyGem_R", "SkyGem_L"])
g.fx.append(dict(kind="spin", parts=RA, pivot=tuple(GY), axis=(0, 1, 0), speed=1.2, states={"Walk": 1.3, "Run": 2.0, "Mine": 2.0}))
g.fx.append(dict(kind="spin", parts=RB, pivot=tuple(GY), axis=(1, 0, 0), speed=1.7, states={"Walk": 1.3, "Run": 2.0, "Mine": 2.0}))
g.fx.append(dict(kind="spin", parts=["GyroCore"], pivot=tuple(GY), axis=(0, 0, 1), speed=2.6))
g.fx.append(dict(kind="pulse", parts=["NozzleR", "NozzleL"], amp=0.14, speed=4.0, states={"Run": 1.8, "Mine": 1.4}))
g.fx.append(dict(kind="bob", parts=["SkyPlate_R", "SkyGem_R"], axis=(0, 1, 0), amp=0.2, speed=2.0, phase=0))
g.fx.append(dict(kind="bob", parts=["SkyPlate_L", "SkyGem_L"], axis=(0, 1, 0), amp=0.2, speed=2.0, phase=3.14))
POSES_LUA = """ poses={
  -- хода суверена: корпус повертається за кроком, руки майже не махають
  Walk=function(p, pose, rot)
   local s = math.sin(p)
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(0, 0.07 * s, 0) }
   local uR, uL = pose.UpperArm_R or {}, pose.UpperArm_L or {}
   pose.UpperArm_R = { r = (uR.r or CFrame.identity) * rot(0.12 * s, 0, 0) }
   pose.UpperArm_L = { r = (uL.r or CFrame.identity) * rot(-0.12 * s, 0, 0) }
   return pose
  end,
  -- біг спринтера: нахил уперед і сильна робота рук
  Run=function(p, pose, rot)
   local s = math.sin(p)
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(0.15, 0, 0) }
   local uR, uL = pose.UpperArm_R or {}, pose.UpperArm_L or {}
   pose.UpperArm_R = { r = (uR.r or CFrame.identity) * rot(-0.3 * s, 0, 0) }
   pose.UpperArm_L = { r = (uL.r or CFrame.identity) * rot(0.3 * s, 0, 0) }
   return pose
  end,
  -- спокій: схиляє голову й розглядає гіроскоп
  Idle=function(p, pose, rot)
   local q = 0.5 + 0.5 * math.sin(0.6 * p)
   pose.Head = { r = (pose.Head and pose.Head.r or CFrame.identity) * rot(0.14 * q, 0.05 * math.sin(0.3 * p), 0) }
   return pose
  end,
  -- носій: трохи відхиляється назад під вагою сейфа
  Carry=function(p, pose, rot)
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(-0.06, 0, 0) }
   return pose
  end,
 },
"""

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    out = "/home/claude/platinum/PlatinumGolemData.lua"
    g.export(out, [
        "-- Platinum Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано platinum_golem_generator.py.",
        "-- Скелет = Clay … Frostforged (21 кістка). neon — фіолетове світло (Neon). fx / poses — унікальні анімації (GolemAnimator v3.3). Box — власний ящик у стадах. Кірка й меч — власні форми (Grip, Pick4, SwordGrip — на стандартних місцях)."])
    s = open(out).read().replace(" bones={", " neon={glow=true},\n" + POSES_LUA + " bones={", 1); open(out, "w").write(s)
