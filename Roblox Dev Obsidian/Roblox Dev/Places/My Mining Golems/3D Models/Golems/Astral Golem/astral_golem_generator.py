# Astral Golem (Celestial, мапа 6): зоряний титан — графітова порожнеча космосу, індиго, зоряний білий метал, два світла (Neon):
# пурпурова туманність (glow) і блакитне зоряне світло (glow2).
# УНІКАЛЬНЕ для Celestial:
#   * кінцівки НЕ ПРИЛЯГАЮТЬ — плечі, руки, кулаки, стегна, гомілки й стопи висять окремо, скріплені магією: між сегментами
#     щілини, в кожній — світна зоряна сфера-суглоб (пульсує, від колін, ліктів і плечей сиплеться зоряний пил);
#   * навколо голема — нахилене кільце, як у Сатурна, що повільно обертається (8 сегментів і 2 зорі);
#   * на грудях обертається спіральна галактика, справжнє блакитне світло (PointLight) і зоряний пил (ParticleEmitter) — додає
#     крок після збірки (AstralAura.lua).
# Інструменти теж «скріплені магією»:
#   кірка — зоряне кайло: держак із двох частин, голова, лезо-півмісяць і чотирипроменева зоря вгорі висять окремо на сферах;
#   меч — новий тип: «осколковий» клинок — лезо з чотирьох ромбів-осколків, що ширяють один за одним на сферах, у кожному
#         пурпурове ядро; гарда — чотирипроменева зоря.
# Ящик — зоряна скриня з сузір'ям на боці; ручки ЛЕВІТУЮТЬ — жердинки біля стінок тримаються лише на сферах.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(void="#1a1734", cosmos="#33287a", star="#e8ecff", glow="#ff4fd8", glow2="#5cdcff", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4"))
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
OCTA = eul(rx=35.264) @ eul(rz=45)
JOINTS = []
def joint(name, bone, pos, s=0.55):
    a(name, bone, "glow2", pos, (s, s, s), OCTA, mirror=True); JOINTS.extend([name, name[:-2] + "_L"])
# ---------- ноги: сегменти на магічних суглобах ----------
a("Foot_R","Shin_R","void",(2.15,0.45,0.15),(3.0,0.9,3.5),eul(ry=5),mirror=True)
joint("AnkleOrb_R","Shin_R",(2.12,1.15,-0.05))
a("Shin_R","Shin_R","star",(2.1,2.0,-0.2),(2.5,1.2,2.5),eul(ry=4),mirror=True)
joint("KneeOrb_R","Shin_R",(2.1,2.85,-0.2),0.58)
a("Thigh_R","Thigh_R","cosmos",(2.0,3.5,-0.25),(2.6,0.8,2.6),eul(ry=-6),mirror=True)
joint("HipOrb_R","Thigh_R",(2.0,4.15,-0.25))
a("Pelvis","Hips","void",(0,5.0,-0.35),(5.8,1.2,3.4))
a("Belt","Hips","star",(0,5.4,-0.35),(6.0,0.45,3.6))
# ---------- корпус: галактика ----------
a("Torso","Torso","cosmos",(0,7.4,-0.3),(6.8,4.0,4.0))
a("Chest","Torso","void",(0,9.45,-0.4),(7.8,1.8,4.6))
GAL = np.array((0, 7.5, 1.86))
a("GalaxyPlateA","Torso","void",(0,7.5,1.76),(1.9,1.9,0.12))
a("GalaxyPlateB","Torso","void",(0,7.5,1.77),(1.9,1.9,0.2),eul(rz=45))
GD = np.array((np.cos(np.radians(45)), np.sin(np.radians(45)), 0))          # рукави на одній діагоналі, внутрішні кінці заходять у ядро
a("GalArm1","Torso","glow",tuple(np.array((0, 7.5, 1.86)) + GD * 0.55),(0.7,0.22,0.1),eul(rz=45))
a("GalArm2","Torso","glow2",tuple(np.array((0, 7.5, 1.86)) - GD * 0.55),(0.7,0.22,0.14),eul(rz=45))
a("GalaxyCore","Torso","star",(0,7.5,1.93),(0.6,0.6,0.1),eul(rz=45))
GALAXY = ["GalArm1", "GalArm2", "GalaxyCore"]
# спина: зоряний сигіл — чотири вкладені ромби сходинками назовні (зоряний метал → порожнеча → блакитний → пурпуровий),
# два внутрішні повільно обертаються
SIG = np.array((0, 7.4, -2.4))
for i, (col, side, back, th) in enumerate((("star", 1.7, -2.28, 0.16), ("void", 1.1, -2.24, 0.28), ("glow2", 0.7, -2.2, 0.4), ("glow", 0.36, -2.16, 0.52)), 1):
    a(f"BackSigil{i}","Torso",col,(0, 7.4, back - th / 2),(side, side, th),eul(rz=45))
# ---------- голова: шолом і місячна дуга ----------
a("Head","Head","star",(0,11.15,0.5014),(3.8,2.7,3.4))
a("Jaw","Head","void",(0,10.0,0.7),(3.4,0.8,2.7))
a("Helmet","Head","void",(0,12.55,0.5),(4.0,0.4,3.6))
# гребінь: блакитний півмісяць «ріжками» вгору (товщий знизу), у ньому — пурпурова зоря-іскра, що пульсує
MC = np.array((0, 13.5, 0.5))
arc = [MC + 0.85 * np.array((np.cos(np.radians(t)), np.sin(np.radians(t)), 0)) for t in (180, 230, 310, 360)]
for k, (w, dz) in enumerate(((0.22, 0.3), (0.34, 0.36), (0.22, 0.3))):
    p0, p1 = arc[k], arc[k+1]; d = p1 - p0; yy = d / np.linalg.norm(d); xx = np.cross(yy, np.array((0, 0, 1.0)))
    a(f"CrestMoon{k+1}","Head","glow2",tuple((p0 + p1) / 2),(w, np.linalg.norm(d) + 0.2, dz),np.column_stack([xx, yy, np.array((0, 0, 1.0))]))
a("CrestDiamond","Head","glow",(0,13.5,0.5),(0.76,0.76,0.2),eul(rz=45))          # знак Astral: ромб у півмісяці
a("CrestEye","Head","glow2",(0,13.5,0.5),(0.3,0.3,0.28),eul(rz=45))
a("TiaraGem","Head","glow",(0,12.55,2.32),(0.36,0.36,0.1),eul(rz=45))             # самоцвіт на шоломі над чолом
a("HelmGem_R","Head","glow2",(2.03,12.55,0.5),(0.1,0.42,0.42),eul(rx=45),mirror=True)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","glow2",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.2,2.24),(1.2,0.3,0.3),eul(rz=-6),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.46,2.3014),(1.1,0.28,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.26,0.5),mirror=True)
# ---------- руки: сегменти на магічних суглобах, над плечима — зорі ----------
a("Shoulder_R","UpperArm_R","void",(5.7,10.025,-0.3),(2.2,1.35,3.2),eul(rz=4),mirror=True)
a("Pauldron_R","UpperArm_R","star",(5.7,10.9,-0.3),(2.6,0.4,3.0),eul(rz=4),mirror=True)
joint("ShoulderOrb_R","UpperArm_R",(4.25,9.9,-0.3))
# рунне коло перед плечем: шестикутник ширяє трохи попереду (вільний, магія) і обертається у своїй площині;
# пурпуровий ромб — на самій передній грані плеча
SR = np.array((5.7, 10.0, 1.6)); SHR = []
hv = [SR + 0.8 * np.array((np.cos(np.radians(30 + 60*k)), np.sin(np.radians(30 + 60*k)), 0)) for k in range(7)]
for k in range(6):
    p0, p1 = hv[k], hv[k+1]; d = p1 - p0; yy = d / np.linalg.norm(d); zz = np.array((0, 0, 1.0)); xx = np.cross(yy, zz)
    a(f"Rune{k+1}_R","UpperArm_R","glow2",tuple((p0 + p1) / 2),((0.16, 0.2)[k % 2], np.linalg.norm(d) + 0.14, (0.24, 0.3)[k % 2]),np.column_stack([xx, yy, zz]),mirror=True)
    SHR.append(f"Rune{k+1}")
a("RuneCore_R","UpperArm_R","glow",(5.7,10.0,1.33),(0.5,0.5,0.1),eul(rz=45),mirror=True)
joint("ArmOrb_R","UpperArm_R",(5.4,8.9,-0.3))
a("UpperArm_R","UpperArm_R","cosmos",(5.3,7.775,-0.3),(2.2,1.35,2.3),eul(ry=4),mirror=True)
joint("ElbowOrb_R","Forearm_R",(5.45,6.675,-0.15))
a("Forearm_R","Forearm_R","star",(5.55,5.6,0.0014),(2.7,1.3,2.8),eul(ry=-6),mirror=True)
joint("WristOrb_R","Forearm_R",(5.6,4.65,0.05))
fist = a("Fist_R","Forearm_R","void",(5.65,3.4,0.1014),(3.2,1.9,3.2),eul(ry=6.875))
sub(fist,"Knuckles_R","star",(0.15,0.3,1.62),(2.6,0.8,0.4))
mir(2)

# ---------- допоміжне для предметів ----------
X = np.array([1.0, 0, 0])
def frameY(d):
    d = d / np.linalg.norm(d); z = np.cross(X, d); z /= np.linalg.norm(z)
    return np.column_stack([X, d, z])
def seg(grp, name, col, p0, p1, w, t=None, extra=0.0, off=0.0):
    p0, p1 = np.array(p0, float), np.array(p1, float); R = frameY(p1 - p0)
    L = np.linalg.norm(p1 - p0) + extra; c = (p0 + p1) / 2 + R[:, 2] * off; t = w if t is None else t
    return g.item(name, grp, col, c, R, (w, L, t))
u = np.array([0, 0.1215, 0.99259]); wv = np.array([0, -0.99259, 0.1215])
A = PICK["Handle"][1]
def orb(grp, name, pos, s=0.42, col="glow2"): return g.item(name, grp, col, tuple(pos), A @ OCTA, (s, s, s))

# ---------- кірка — зоряне кайло (частини на сферах) ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
hc = np.array(PICK["Handle"][0])
g.item("Handle","Pickaxe","void",tuple(hc - u * 1.8),A,(0.65,5.6,0.65))                  # нижня частина держака (до 1.0)
orb("Pickaxe","HandleOrb",hc + u * 1.33)
g.item("HandleTop","Pickaxe","cosmos",tuple(hc + u * 2.53),A,(0.6,1.7,0.6))               # верхня частина (1.68…3.38)
orb("Pickaxe","HeadOrb",hc + u * 3.72)
P("Grip","star")
PM = P("Pommel","star",(0.85,0.6,0.85))
sub(PM,"PommelStar","glow2",(0,-0.55,0),(0.5,0.5,0.5),OCTA)
H = np.array(PICK["Head"][0])
HD = g.item("Head","Pickaxe","star",tuple(H),A,(1.0,1.1,1.4))
sub(HD,"HeadBand","glow",(0,0,0),(1.06,0.3,1.0))
p4c, p4R, p4s = PICK["Pick4"]; p4c = np.array(p4c); p4back = p4c - p4R[:, 2] * p4s[2] / 2
orb("Pickaxe","BladeOrb",H + wv * 0.85, 0.38)
S0 = H + wv * 1.15; M1 = np.array((-5.65, 2.3, 8.6)); M2 = np.array((-5.65, 0.8, 8.45))
seg("Pickaxe","Pick1","star",S0,M1,0.34,1.1,extra=0.3)
seg("Pickaxe","Pick2","star",M1,M2,0.26,0.9,extra=0.3)
seg("Pickaxe","Pick3","star",M2,p4back,0.18,0.62,extra=0.3)
g.item("Pick4","Pickaxe","glow",tuple(p4c),p4R,p4s)
seg("Pickaxe","PickEdge1","glow",S0,M1,0.46,0.16,extra=0.05,off=0.52)
seg("Pickaxe","PickEdge2","glow",M1,M2,0.40,0.16,extra=0.05,off=0.42)
sub(HD,"StarOrb","glow2",(0,0,-1.1),(0.5,0.5,0.5),OCTA)
SC = H - wv * 2.25
sp = [SC + u * 0.7 * np.cos(np.radians(t)) + wv * 0.7 * np.sin(np.radians(t)) for t in (0, 50, 130, 180)]
for k, w in enumerate((0.22, 0.32, 0.22)):
    seg("Pickaxe", f"SignMoon{k+1}", "glow2", sp[k], sp[k+1], (0.26, 0.32, 0.26)[k], w, extra=0.2)
g.item("SignDiamond","Pickaxe","star",tuple(SC),A @ eul(rx=45),(0.24,0.8,0.8))
g.item("SignCore","Pickaxe","glow",tuple(SC),A @ eul(rx=45),(0.3,0.34,0.34))

# ---------- меч — осколковий клинок ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordGrip","void"); S("SwordCoil1","star"); S("SwordCoil2","star")
g0 = np.array(SWORD["SwordGrip"][0])
def at(aa, bb=0.0): return g0 + u * aa + wv * bb
g.item("SwordPommel","Sword","star",tuple(at(-2.15)),A,(0.85,0.55,0.85))
g.item("PommelStar","Sword","glow2",tuple(at(-2.6)),A @ OCTA,(0.45,0.45,0.45))
g.item("SwordGuard","Sword","star",tuple(at(2.25)),A,(0.32,0.4,2.3))
g.item("GuardBar2","Sword","star",tuple(at(2.25)),A,(1.7,0.34,0.36))
g.item("GuardGem","Sword","glow",tuple(at(2.25)),A @ OCTA,(0.56,0.56,0.56))
seg("Sword","SwordBlade","cosmos",at(2.4),at(3.3),0.24,0.6,extra=0.1)
for i, (oa, ca, side) in enumerate(((3.6, 4.55, 0.95), (5.45, 6.3, 0.85), (7.1, 7.85, 0.72), (8.6, 9.25, 0.55)), 1):
    orb("Sword", f"ShardOrb{i}", at(oa), 0.4)
    nm = "SwordTip" if i == 4 else f"Shard{i}"
    g.item(nm,"Sword","star",tuple(at(ca)),A @ eul(rx=45),((0.28, 0.24)[i % 2], side, side))
    g.item(f"ShardCore{i}","Sword","glow",tuple(at(ca)),A @ eul(rx=45),((0.34, 0.3)[i % 2], side * 0.45, side * 0.45))

# ---------- ящик — зоряна скриня з левітуючими ручками ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","void",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","cosmos",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","void",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","void",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","void",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","void",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","star",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","star",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","star",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","star",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Post" + t, "star", (1.87*sx, 1.035, 1.13*sz), (0.5, 1.67, 0.5))
        B("PostStar" + t, "glow2", (1.87*sx, 2.15, 1.13*sz), (0.36, 0.36, 0.36), OCTA)
# сузір'я на зовнішньому боці (-Z)
for i, (x, y, s) in enumerate(((-1.1, 1.35, 0.24), (-0.4, 0.8, 0.2), (0.35, 1.25, 0.28), (1.1, 0.7, 0.2)), 1):
    B(f"Const{i}","glow2",(x,y,-1.19),(s,s,0.1),eul(rz=45))
B("ConstStar","glow",(0.35,1.25,-1.26),(0.16,0.16,0.08),eul(rz=45))
# ручки — жердинки, що левітують біля стінок на двох сферах кожна
for sx, nm in ((1, "R"), (-1, "L")):
    B(f"HandleBar{nm}","star",(2.55*sx,1.3,0),(0.26,0.26,1.5))
    for sz, zn in ((1, "F"), (-1, "B")):
        B(f"HandleOrb{nm}{zn}","glow2",(2.21*sx,1.3,0.45*sz),(0.5,0.5,0.5),OCTA)
        B(f"HandleCap{nm}{zn}","glow",(2.55*sx,1.3,0.85*sz),(0.3,0.3,0.3),OCTA)

# ---------- унікальні рухи (GolemAnimator v3.3) ----------
g.free_parts = tuple(f"Rune{k}_{sd}" for k in range(1, 7) for sd in "RL")
g.fx.append(dict(kind="spin", parts=GALAXY, pivot=(0, 7.5, 1.86), axis=(0, 0, 1), speed=2.2, states={"Mine": 1.6, "Run": 1.8}))
g.fx.append(dict(kind="spin", parts=[n + "_R" for n in SHR], pivot=tuple(SR), axis=(0, 0, 1), speed=1.3, states={"Walk": 1.4, "Run": 2.0}))
g.fx.append(dict(kind="spin", parts=[n + "_L" for n in SHR], pivot=(-SR[0], SR[1], SR[2]), axis=(0, 0, -1), speed=1.3, states={"Walk": 1.4, "Run": 2.0}))
g.fx.append(dict(kind="pulse", parts=JOINTS, amp=0.16, speed=3.2, states={"Walk": 1.3, "Run": 1.8, "Mine": 1.5}))
g.fx.append(dict(kind="pulse", parts=["CrestDiamond", "CrestEye"], amp=0.06, speed=2.6))
g.fx.append(dict(kind="spin", parts=["BackSigil3", "BackSigil4"], pivot=tuple(SIG), axis=(0, 0, 1), speed=-0.8, states={"Walk": 1.5, "Run": 2.2}))
POSES_LUA = """ poses={
  -- хода в невагомості: руки пливуть хвилею, корпус легко погойдується
  Walk=function(p, pose, rot)
   local s = math.sin(p)
   local uR, uL = pose.UpperArm_R or {}, pose.UpperArm_L or {}
   pose.UpperArm_R = { r = (uR.r or CFrame.identity) * rot(0, 0, 0.1 + 0.06 * s) }
   pose.UpperArm_L = { r = (uL.r or CFrame.identity) * rot(0, 0, -0.1 + 0.06 * s) }
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(0, 0, 0.03 * s) }
   return pose
  end,
  -- біг-«комета»: сильний нахил, руки тягнуться назад
  Run=function(p, pose, rot)
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(0.2, 0, 0) }
   local uR, uL = pose.UpperArm_R or {}, pose.UpperArm_L or {}
   pose.UpperArm_R = { r = (uR.r or CFrame.identity) * rot(0.45, 0, 0.12) }
   pose.UpperArm_L = { r = (uL.r or CFrame.identity) * rot(0.45, 0, -0.12) }
   return pose
  end,
  -- спокій: медитація — руки повільно розходяться вбік, голова дивиться вгору на кільце
  Idle=function(p, pose, rot)
   local q = 0.5 + 0.5 * math.sin(0.4 * p)
   local uR, uL = pose.UpperArm_R or {}, pose.UpperArm_L or {}
   pose.UpperArm_R = { r = (uR.r or CFrame.identity) * rot(0, 0, 0.25 * q) }
   pose.UpperArm_L = { r = (uL.r or CFrame.identity) * rot(0, 0, -0.25 * q) }
   pose.Head = { r = (pose.Head and pose.Head.r or CFrame.identity) * rot(-0.1 * q, 0.08 * math.sin(0.2 * p), 0) }
   return pose
  end,
  -- носій: корпус трохи вперед, скриня тримається на рівні грудей
  Carry=function(p, pose, rot)
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(0.05, 0, 0) }
   return pose
  end,
 },
"""

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    out = "/home/claude/astral/AstralGolemData.lua"
    g.export(out, [
        "-- Astral Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано astral_golem_generator.py (v2).",
        "-- Скелет = Clay … Aurelian (21 кістка). neon — туманність і зоряне світло (Neon). Кінцівки й частини інструментів не прилягають — їх тримають світні сфери-суглоби. fx / poses — GolemAnimator v3.3. Світло й зоряний пил додаються після збірки (AstralAura.lua)."])
    s = open(out).read().replace(" bones={", " neon={glow=true,glow2=true},\n" + POSES_LUA + " bones={", 1); open(out, "w").write(s)
