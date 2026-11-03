# Aurelian Golem (Divine, мапа 5): сонячний бог-хранитель — білий мармур у золоті й бронзі, сонячне світло (Neon).
# Унікальне для Divine — голем, що САМ СВІТИТЬСЯ: справжнє світло (PointLight) з грудей і сонячного диска та золоті іскри
# (ParticleEmitter), що здіймаються від диска; їх додає крок після збірки в Studio (див. AURA_LUA).
# Фірмове: за головою — СОНЯЧНИЙ ДИСК із вісьмома променями, що повільно обертається; навколо голови по орбіті кружляють три
# малі сонця; на плечах — золоті крила з трьох пер, що тріпочуть; на голові — золотий вінець з уреєм і золоті «немес»-лопаті.
# Анімації (GolemAnimator v3.3): fx — диск обертається, три сонця на орбіті, крила тріпочуть, сонце в грудях пульсує;
# poses — хода-процесія (голова піднята, руки трохи вбік), біг-«спалах» (нахил, руки відведені назад), у спокої — здіймає руки
# до сонця, носій — голова схилена.
# Інструменти власної форми (не шаблон, не рапіра, не шабля, не фламберг):
#   кірка — сонцекайло: широке золоте лезо-півмісяць донизу (кінчик Pick4 на стандартному місці) зі світною кромкою, угорі —
#           сонячний диск із променями;
#   меч — хопеш: пряма бронзова шийка і золотий серп, що загинається гаком, світна кромка по опуклому боці.
# Ящик — ковчег: золоті стінки на бронзовій основі, сонце-емблема спереду, крильця на кутах; ручки — дві довгі бронзові
# жердини вздовж боків, протягнуті крізь золоті кільця (несуть, як ковчег).
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(marble="#f4efe4", gold="#f2c14e", bronze="#6b4a1e", glow="#ffb12e", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4"))
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
OCTA = eul(rx=35.264) @ eul(rz=45)
# ---------- ноги ----------
a("Foot_R","Shin_R","bronze",(2.15,0.55,0.15),(3.0,1.1,3.5),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","marble",(2.1,2.2,-0.2),(2.5,2.3,2.5),eul(ry=4),mirror=True)
a("ShinBand_R","Shin_R","gold",(2.1,1.45,-0.2),(2.7,0.4,2.7),eul(ry=4),mirror=True)
a("KneeSun_R","Shin_R","glow",(2.1,3.3,1.0),(0.55,0.55,0.55),OCTA,mirror=True)
a("Thigh_R","Thigh_R","bronze",(2.0,3.95,-0.25),(2.6,1.7,2.6),eul(ry=-6),mirror=True)
a("Pelvis","Hips","bronze",(0,4.85,-0.35),(5.8,1.6,3.4))
a("Belt","Hips","gold",(0,5.4,-0.35),(6.0,0.45,3.6))
a("BeltSun","Hips","glow",(0,5.4,1.55),(0.55,0.55,0.55),OCTA)
# ---------- корпус: сонце в грудях ----------
a("Torso","Torso","marble",(0,7.4,-0.3),(6.8,4.0,4.0))
a("Chest","Torso","gold",(0,9.45,-0.4),(7.8,1.8,4.6))
a("Collar","Torso","marble",(0,10.25,-0.4),(4.6,0.4,3.6))
a("ChestSunA","Torso","gold",(0,7.5,1.75),(1.6,1.6,0.12))
a("ChestSunB","Torso","gold",(0,7.5,1.76),(1.6,1.6,0.18),eul(rz=45))
a("ChestCore","Torso","glow",(0,7.5,1.9),(0.8,0.8,0.12),eul(rz=22.5))
# ---------- сонячний диск за головою ----------
SUN = np.array((0, 12.3, -2.95))
a("SunMount","Torso","bronze",(0,10.5,-2.6),(0.6,3.0,0.5))
a("DiskA","Torso","gold",tuple(SUN),(2.6,2.6,0.25))
a("DiskB","Torso","gold",tuple(SUN),(2.6,2.6,0.33),eul(rz=45))
a("SunFace","Torso","glow",tuple(SUN + (0, 0, 0.22)),(1.2,1.2,0.1),eul(rz=22.5))
RAYS = []
for k in range(8):
    ang = 22.5 + 45 * k; L = (1.4, 0.95)[k % 2]; r0 = 1.45
    d = np.array((np.cos(np.radians(ang)), np.sin(np.radians(ang)), 0))
    a(f"Ray{k+1}","Torso","glow",tuple(SUN + d * (r0 + L / 2)),(0.22, L, (0.18, 0.22)[k % 2]),eul(rz=ang - 90))
    RAYS.append(f"Ray{k+1}")
# три малі сонця на орбіті над головою (вільні)
ORB_C = np.array((0, 14.6, -0.3)); ORBS = []
for k in range(3):
    t = np.radians(90 + 120 * k)
    a(f"Orb{k+1}","Torso","glow",tuple(ORB_C + 4.4 * np.array((np.cos(t), 0, np.sin(t)))),(0.6,0.6,0.6),OCTA)
    ORBS.append(f"Orb{k+1}")
# ---------- голова: вінець з уреєм, лопаті «немес» ----------
a("Head","Head","marble",(0,11.15,0.5014),(3.8,2.7,3.4))
a("Jaw","Head","bronze",(0,10.0,0.7),(3.4,0.8,2.7))
a("Crown","Head","gold",(0,12.55,0.5),(4.0,0.4,3.6))
a("Uraeus","Head","glow",(0,12.75,2.35),(0.5,0.75,0.3))
a("Lappet_R","Head","gold",(2.08,10.55,0.2),(0.36,2.8,1.5),mirror=True)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","glow",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.2,2.24),(1.2,0.3,0.3),eul(rz=-6),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.46,2.3014),(1.1,0.28,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.26,0.5),mirror=True)
# ---------- руки: золоті крила на плечах ----------
WB = np.array((5.9, 11.0, -0.3))
a("Shoulder_R","UpperArm_R","bronze",(5.0,9.85,-0.3),(3.2,1.8,3.4),eul(rz=4),mirror=True)
a("Pauldron_R","UpperArm_R","gold",(5.1,10.9,-0.3),(3.0,0.4,3.2),eul(rz=4),mirror=True)
for k, (tilt, L, z, col, th) in enumerate(((22, 2.3, -0.75, "gold", 0.24), (42, 2.0, -0.3, "glow", 0.2), (62, 1.6, 0.15, "gold", 0.24)), 1):
    R = eul(rz=-tilt); base = WB + np.array((0, 0, z))
    a(f"Feather{k}_R","UpperArm_R",col,tuple(base + R[:, 1] * (L / 2 - 0.25)),(th, L, 0.6),R,mirror=True)
a("UpperArm_R","UpperArm_R","bronze",(5.25,8.0,-0.3),(2.2,2.6,2.3),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","marble",(5.55,5.75,0.0014),(2.7,2.4,2.8),eul(ry=-6),mirror=True)
a("Cuff_R","Forearm_R","gold",(5.55,6.55,0.0014),(2.9,0.4,3.0),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","bronze",(5.65,3.45,0.1014),(3.2,2.4,3.2),eul(ry=6.875))
sub(fist,"Knuckles_R","gold",(0.15,0.3,1.62),(2.6,0.8,0.4))
sub(fist,"KnuckleRune_R","glow",(0.15,0.3,1.87),(1.9,0.14,0.12))
sub(fist,"Thumb_R","bronze",(-1.7,0.1,0.95),(0.5,1.0,0.9),eul(rz=-6)); mir(4)

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

# ---------- кірка — сонцекайло ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","bronze"); P("Grip","marble")
sub(HN,"Wrap1","gold",(0,1.3,0),(0.8,0.5,0.8))
sub(HN,"Wrap2","gold",(0,2.4,0),(0.8,0.5,0.8))
PM = P("Pommel","gold",(0.85,0.6,0.85))
sub(PM,"PommelSun","glow",(0,-0.55,0),(0.5,0.5,0.5),OCTA)
H = np.array(PICK["Head"][0])
HD = g.item("Head","Pickaxe","gold",tuple(H),A,(1.0,1.1,1.6))
sub(HD,"HeadBand","bronze",(0,0,0),(1.06,0.5,1.0))
p4c, p4R, p4s = PICK["Pick4"]; p4c = np.array(p4c); p4back = p4c - p4R[:, 2] * p4s[2] / 2
S0 = H + wv * 0.6; M1 = np.array((-5.65, 2.3, 8.55)); M2 = np.array((-5.65, 0.8, 8.35))
seg("Pickaxe","Pick1","gold",S0,M1,0.34,1.3,extra=0.3)
seg("Pickaxe","Pick2","gold",M1,M2,0.26,1.05,extra=0.3)
seg("Pickaxe","Pick3","gold",M2,p4back,0.18,0.7,extra=0.3)
g.item("Pick4","Pickaxe","glow",tuple(p4c),p4R,p4s)
seg("Pickaxe","PickEdge1","glow",S0,M1,0.46,0.16,extra=0.05,off=0.62)
seg("Pickaxe","PickEdge2","glow",M1,M2,0.40,0.16,extra=0.05,off=0.5)
sub(HD,"SunNeck","bronze",(0,0,-1.0),(0.6,0.6,0.7))
for i, ang in enumerate((0, 45)):
    sub(HD,f"SunDisk{i+1}","gold",(0,0,-1.95),(0.2 + 0.06*i,1.3,1.3),eul(rx=ang))
for i, ang in enumerate((22.5, 112.5)):
    sub(HD,f"SunRay{i+1}","glow",(0,0,-1.95),(0.34 + 0.06*i,2.1,0.2),eul(rx=ang))

# ---------- меч — хопеш ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordGrip","bronze"); S("SwordCoil1","gold"); S("SwordCoil2","gold")
g0 = np.array(SWORD["SwordGrip"][0])
def at(aa, bb=0.0): return g0 + u * aa + wv * bb
g.item("SwordPommel","Sword","gold",tuple(at(-2.15)),A,(0.9,0.55,0.9))
g.item("PommelSun","Sword","glow",tuple(at(-2.6)),A @ OCTA,(0.45,0.45,0.45))
g.item("SwordGuard","Sword","gold",tuple(at(2.25)),A,(0.36,0.42,1.3))
seg("Sword","SwordBlade","bronze",at(2.4),at(4.9),0.26,0.5,extra=0.1)
hook = [at(4.8, 0.05), at(6.3, -0.45), at(7.4, -1.45), at(7.85, -2.75), at(7.4, -3.85)]
thick = (0.34, 0.28, 0.34, 0.28); widths = (1.0, 1.05, 1.0, 0.85)
for i in range(4):
    seg("Sword", f"Sickle{i+1}", "gold", hook[i], hook[i+1], thick[i], widths[i], extra=0.25)
    seg("Sword", f"Edge{i+1}", "glow", hook[i], hook[i+1], thick[i] + 0.06, 0.14, extra=-0.15, off=widths[i]/2 - 0.02)
d = hook[4] - hook[3]
g.item("SwordTip","Sword","gold",tuple(hook[4] + d / np.linalg.norm(d) * 0.15),frameY(d) @ eul(ry=45),(0.34,0.6,0.34))
g.item("BladeSun","Sword","glow",tuple(at(4.1)),A @ OCTA,(0.42,0.42,0.42))

# ---------- ящик — ковчег ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","bronze",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","marble",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","gold",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","gold",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","gold",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","gold",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","bronze",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","bronze",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","bronze",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","bronze",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Post" + t, "bronze", (1.87*sx, 1.035, 1.13*sz), (0.5, 1.67, 0.5))
        B("Wing" + t, "gold", (1.87*sx + 0.32*sx, 2.25, 1.13*sz), (0.5, 0.9, 0.12), eul(rz=-30*sx))
# сонце-емблема на зовнішньому боці (-Z)
B("Emblem1","glow",(0,0.98,-1.2),(0.8,0.8,0.1)); B("Emblem2","glow",(0,0.98,-1.21),(0.8,0.8,0.2),eul(rz=45))
B("EmblemCore","marble",(0,0.98,-1.355),(0.36,0.36,0.1),eul(rz=22.5))
# ручки — жердини крізь кільця
for sx, nm in ((1, "R"), (-1, "L")):
    px = 2.42 * sx
    B(f"Pole{nm}","bronze",(px,1.0,0),(0.26,0.26,3.6))
    for sz, zn in ((1, "F"), (-1, "B")):
        z = 0.6 * sz
        B(f"Sleeve{nm}{zn}","gold",(px,1.0,z),(0.44,0.44,0.22))
        B(f"SleeveMount{nm}{zn}","bronze",(2.1*sx,1.0,z),(0.24,0.24,0.18))
        B(f"PoleCap{nm}{zn}","glow",(px,1.0,1.86*sz),(0.36,0.36,0.36),OCTA)

# ---------- унікальні рухи (GolemAnimator v3.3) ----------
g.free_parts = tuple(ORBS)
DISK = ["DiskA", "DiskB", "SunFace"] + RAYS
g.fx.append(dict(kind="spin", parts=DISK, pivot=tuple(SUN), axis=(0, 0, 1), speed=0.6, states={"Run": 1.8, "Mine": 1.6}))
g.fx.append(dict(kind="spin", parts=ORBS, pivot=tuple(ORB_C), axis=(0, 1, 0), speed=0.8, states={"Walk": 1.3, "Run": 2.0}))
g.fx.append(dict(kind="sway", parts=["Feather1_R", "Feather2_R", "Feather3_R"], pivot=tuple(WB), axis=(0, 0, 1), amp=0.12, speed=2.4,
                 states={"Run": 2.0, "Walk": 1.3}))
g.fx.append(dict(kind="sway", parts=["Feather1_L", "Feather2_L", "Feather3_L"], pivot=(-WB[0], WB[1], WB[2]), axis=(0, 0, -1), amp=0.12,
                 speed=2.4, states={"Run": 2.0, "Walk": 1.3}))
g.fx.append(dict(kind="pulse", parts=["ChestCore"], amp=0.12, speed=2.0, states={"Mine": 1.5}))
POSES_LUA = """ poses={
  -- хода-процесія: голова піднята, руки трохи відведені вбік
  Walk=function(p, pose, rot)
   pose.Head = { r = (pose.Head and pose.Head.r or CFrame.identity) * rot(-0.06, 0, 0) }
   local uR, uL = pose.UpperArm_R or {}, pose.UpperArm_L or {}
   pose.UpperArm_R = { r = (uR.r or CFrame.identity) * rot(0, 0, 0.08) }
   pose.UpperArm_L = { r = (uL.r or CFrame.identity) * rot(0, 0, -0.08) }
   return pose
  end,
  -- біг-«спалах»: нахил уперед, руки відведені назад
  Run=function(p, pose, rot)
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(0.14, 0, 0) }
   local uR, uL = pose.UpperArm_R or {}, pose.UpperArm_L or {}
   pose.UpperArm_R = { r = (uR.r or CFrame.identity) * rot(0.3, 0, 0) }
   pose.UpperArm_L = { r = (uL.r or CFrame.identity) * rot(0.3, 0, 0) }
   return pose
  end,
  -- спокій: повільно здіймає руки до сонця
  Idle=function(p, pose, rot)
   local q = 0.5 + 0.5 * math.sin(0.5 * p)
   local uR, uL = pose.UpperArm_R or {}, pose.UpperArm_L or {}
   pose.UpperArm_R = { r = (uR.r or CFrame.identity) * rot(0, 0, 0.18 * q) }
   pose.UpperArm_L = { r = (uL.r or CFrame.identity) * rot(0, 0, -0.18 * q) }
   pose.Head = { r = (pose.Head and pose.Head.r or CFrame.identity) * rot(-0.08 * q, 0, 0) }
   return pose
  end,
  -- носій: несе ковчег з поклоном, голова схилена
  Carry=function(p, pose, rot)
   pose.Head = { r = (pose.Head and pose.Head.r or CFrame.identity) * rot(0.12, 0, 0) }
   return pose
  end,
 },
"""

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    out = "/home/claude/aurelian/AurelianGolemData.lua"
    g.export(out, [
        "-- Aurelian Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано aurelian_golem_generator.py.",
        "-- Скелет = Clay … Platinum (21 кістка). neon — сонячне світло (Neon). fx / poses — унікальні анімації (GolemAnimator v3.3). Box — власний ящик у стадах. Кірка й меч — власні форми (Grip, Pick4, SwordGrip — на стандартних місцях). Світло й іскри (PointLight, ParticleEmitter) додаються після збірки."])
    s = open(out).read().replace(" bones={", " neon={glow=true},\n" + POSES_LUA + " bones={", 1); open(out, "w").write(s)
