# Storm Golem (Exclusive #3, рівень Legendary): громовий самурай — грозова синьо-сіра броня, сталь, жовта блискавка (Neon).
# Фірмове: шолом кабуто з рогами-кувагата й блискавкою між ними, наплічники о-соде, тасети кусадзурі, блискавка на грудях
# (pulse), хмаринки над плечима з блискавками пливуть (bob), прапор-сашімоно на спині майорить (sway).
# Пози: хода самурая (рівний корпус, руки майже не махають), бойова стійка в спокої.
# Інструменти власної форми: громовий молот-кайло; КАТАНА (новий тип): ледь вигнуте вузьке лезо, квадратна цуба, обмотане руків'я.
# Ящик — барабан бога грому (тайко) з натягнутими шкірами на торцях і ручками-шнурами. Скелет Clay.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(storm="#4d5868", stormDark="#262b36", steel="#a3aebf", cloud="#d6dde8", bolt="#ffe23d",
               light="#f1f5f8", dark="#1c2836", pink="#f2a0b4", blade="#e4eaf2", brass="#c9a24a",
               drum="#6e3324", drumDark="#3e2016"),
          bones={"Mouth": (0,10.5,2.3014), "MouthCorner_R": (0.65,10.6,2.3014), "MouthCorner_L": (-0.65,10.6,2.3014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
def zig(name, bone, col, p0, p1, w, z, t, mirror=False):
    """брусок у площині XY від p0 до p1 (на глибині z)"""
    p0, p1 = np.array(p0, float), np.array(p1, float); d = p1 - p0; L = np.linalg.norm(d)
    ang = np.degrees(np.arctan2(-d[0], d[1]))
    return a(name, bone, col, ((p0[0]+p1[0])/2, (p0[1]+p1[1])/2, z), (w, L + w*0.6, t), eul(rz=ang), mirror=mirror)

# ---------- ноги: поножі ----------
a("Foot_R","Shin_R","stormDark",(2.2,0.55,0.2),(3.2,1.1,3.7),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","storm",(2.15,2.2,-0.2),(2.7,2.3,2.7),eul(ry=4),mirror=True)
a("Greave_R","Shin_R","steel",(2.2,2.3,1.2),(1.8,1.9,0.3),eul(ry=4),mirror=True)
a("Thigh_R","Thigh_R","stormDark",(2.0,4.0,-0.25),(2.8,1.7,2.8),eul(ry=-6),mirror=True)
# ---------- таз: пояс-обі й тасети ----------
a("Pelvis","Hips","stormDark",(0,4.85,-0.3),(6.2,1.6,3.5))
a("Obi","Hips","cloud",(0,5.45,-0.3),(6.6,0.5,3.9))
a("Tasset_R","Hips","steel",(1.3,4.6,1.76),(1.9,1.3,0.26),eul(rx=-8),mirror=True)
a("TassetSide_R","Hips","steel",(3.46,4.6,-0.3),(0.26,1.3,2.6),eul(rz=8),mirror=True)
# ---------- корпус: панцир-до, блискавка ----------
a("Torso","Torso","storm",(0,7.5,-0.3),(7.4,4.2,4.2))
a("Chest","Torso","steel",(0,9.6,-0.35),(8.6,1.6,4.7))
a("Lame1","Torso","stormDark",(0,8.5,-0.3),(7.6,0.35,4.4))
a("Lame2","Torso","stormDark",(0,6.5,-0.3),(7.6,0.35,4.4))
BOLT = [zig("ChestBolt1","Torso","bolt",(0.6,8.95),(-0.25,7.7),0.36,1.88,0.2),
        zig("ChestBolt2","Torso","bolt",(-0.25,7.7),(0.5,7.35),0.36,1.91,0.2),
        zig("ChestBolt3","Torso","bolt",(0.5,7.35),(-0.4,6.05),0.36,1.88,0.2)]
# спина: сашімоно (прапор)
a("BackPlate","Torso","stormDark",(0,7.2,-2.45),(4.2,3.0,0.3))
# прапор стоїть у гнізді на верху панцира, збоку (не перетинає світлих смуг)
PX, PZ = 1.7, -2.3
a("PoleSocket","Torso","stormDark",(PX,10.62,PZ),(0.56,0.44,0.56))
a("Pole","Torso","stormDark",(PX,12.75,PZ),(0.24,3.9,0.24))
a("PoleTop","Torso","bolt",(PX,14.85,PZ),(0.4,0.4,0.4),eul(ry=45))
a("Flag","Torso","cloud",(PX+1.11,13.35,PZ),(2.0,2.6,0.12))
FLAG = ["Flag", zig("FlagBolt1","Torso","bolt",(PX+1.45,14.3),(PX+0.8,13.3),0.26,PZ-0.08,0.06)["name"],
        zig("FlagBolt2","Torso","bolt",(PX+0.8,13.3),(PX+1.5,12.3),0.26,PZ-0.1,0.06)["name"]]
# ---------- голова: шолом кабуто ----------
a("Head","Head","storm",(0,11.15,0.5014),(4.0,2.7,3.4))
a("Helm","Head","stormDark",(0,12.85,0.4),(4.5,0.9,3.9))
a("HelmTop","Head","stormDark",(0,13.5,0.3),(3.6,0.5,3.2))
a("Visor","Head","steel",(0,12.42,2.05),(4.4,0.25,0.9),eul(rx=-10))
a("Shikoro","Head","stormDark",(0,12.1,-1.55),(4.8,1.0,0.35),eul(rx=22))
a("ShikoroSide_R","Head","stormDark",(2.42,12.15,0.1),(0.35,1.0,3.0),eul(rz=-18),mirror=True)
a("HornBase","Head","steel",(0,12.95,2.3),(0.9,0.5,0.24))
a("Horn_R","Head","steel",(0.72,13.78,2.33),(0.3,1.95,0.22),eul(rz=-30),mirror=True)
zig("CrestBolt1","Head","bolt",(0.2,13.95),(-0.15,13.15),0.24,2.4,0.18)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","bolt",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.06,2.25),(1.2,0.26,0.3),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.24,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.5,2.3014),(1.1,0.24,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.22,0.5),mirror=True)
# ---------- руки: о-соде, наручі кote ----------
a("Shoulder_R","UpperArm_R","storm",(5.0,9.85,-0.3),(3.4,1.9,3.6),eul(rz=3),mirror=True)
a("Pauldron_R","UpperArm_R","stormDark",(5.15,10.95,-0.3),(3.6,0.45,3.8),eul(rz=3),mirror=True)
a("Sode_R","UpperArm_R","steel",(6.85,9.4,-0.3),(0.3,2.4,3.0),eul(rz=3),mirror=True)
a("SodeLace1_R","UpperArm_R","stormDark",(6.86,9.95,-0.3),(0.44,0.2,3.06),eul(rz=3),mirror=True)
a("UpperArm_R","UpperArm_R","stormDark",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","storm",(5.55,5.75,0.0014),(2.9,2.4,3.0),eul(ry=-6),mirror=True)
a("Bracer_R","Forearm_R","steel",(5.55,6.55,0.0014),(3.1,0.4,3.2),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","storm",(5.65,3.45,0.1014),(3.6,2.7,3.6),eul(ry=6.875))
sub(fist,"Knuckles_R","steel",(0.15,0.3,1.85),(3.0,1.0,0.45))
sub(fist,"Thumb_R","storm",(-1.9,0.1,1.05),(0.5,1.1,0.9),eul(rz=-6)); mir(3)
# ---------- хмаринки над плечима (ширяють, з блискавками) ----------
CLOUD = {}
for sx, nm in ((1, "R"), (-1, "L")):
    ps = [a(f"Cloud{nm}","Torso","cloud",(5.2*sx,12.05,-0.3),(1.7,0.66,1.3)),
          a(f"CloudPuffA{nm}","Torso","cloud",(4.6*sx,12.3,-0.25),(0.9,0.8,0.95)),
          a(f"CloudBolt{nm}","Torso","bolt",(5.3*sx,11.55,-0.3),(0.18,0.5,0.18),eul(rz=-25*sx))]
    CLOUD[nm] = [b["name"] for b in ps]
g.free_parts = tuple(CLOUD["R"] + CLOUD["L"])

# ---------- допоміжне для інструментів ----------
X = np.array([1.0, 0, 0])
def frameY(d):
    d = d / np.linalg.norm(d); z = np.cross(X, d); z /= np.linalg.norm(z)
    return np.column_stack([X, d, z])
def seg(grp, name, col, p0, p1, w, t=None, extra=0.0):
    p0, p1 = np.array(p0, float), np.array(p1, float); R = frameY(p1 - p0)
    L = np.linalg.norm(p1 - p0) + extra; c = (p0 + p1) / 2; t = w if t is None else t
    return g.item(name, grp, col, c, R, (w, L, t))
u = np.array([0, 0.1215, 0.99259]); wv = np.array([0, -0.99259, 0.1215])
A = PICK["Handle"][1]

# ---------- кірка: громовий молот-кайло ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","stormDark"); P("Grip","cloud")
for i, k in enumerate((1.4, 2.4), 1): sub(HN, f"Wrap{i}", "steel", (0, k, 0), (0.82, 0.26, 0.82))
PM = P("Pommel","steel")
sub(PM,"PommelBolt","bolt",(0,-0.42,0),(0.42,0.24,0.42),eul(ry=45))
H = np.array(PICK["Head"][0])
HD = g.item("Head","Pickaxe","steel",tuple(H + u*0.2),A,(1.2,1.5,1.2))
sub(HD,"HammerBody","stormDark",(0,0.2,-1.0),(1.6,1.5,1.4))
sub(HD,"HammerBand","bolt",(0,0.2,-1.0),(1.7,0.3,1.2))
sub(HD,"HammerFace","steel",(0,0.2,-1.86),(1.85,1.75,0.34))
sub(HD,"HammerRing","stormDark",(0,0.2,-2.1),(1.2,1.2,0.16),eul(ry=0))
p4c, p4R, p4s = PICK["Pick4"]; p4c = np.array(p4c); p4back = p4c - p4R[:, 2] * p4s[2] / 2
S0 = H + wv * 0.55 + u * 0.35; Mid = np.array((-5.65, 1.6, 8.25))
seg("Pickaxe","Spike1","steel",S0,Mid,0.95,0.9,extra=0.3)
seg("Pickaxe","Spike2","steel",Mid,p4back,0.66,0.62,extra=0.3)
g.item("Pick4","Pickaxe","steel",tuple(p4c),p4R,p4s)
seg("Pickaxe","SpikeBolt","bolt",S0 + (Mid - S0)*0.2,Mid,1.02,0.22)
seg("Pickaxe","SpikeBolt2","bolt",Mid,Mid + (p4back - Mid)*0.7,0.72,0.18)

# ---------- меч: катана ----------
g0 = np.array(SWORD["SwordGrip"][0])
def at(aa, bb=0.0): return g0 + u * aa + wv * bb
g.item("SwordGrip","Sword","stormDark",tuple(g0),A,(0.66,3.6,0.66))
for i, k in enumerate((-1.3, -0.45, 0.4, 1.25), 1):
    g.item(f"Ito{i}","Sword","cloud",tuple(at(k)),A @ eul(ry=45),(0.74,0.3,0.74))
g.item("SwordPommel","Sword","steel",tuple(at(-2.0)),A,(0.8,0.45,0.8))
g.item("SwordGuard","Sword","steel",tuple(at(2.15)),A,(1.4,0.22,1.4))
g.item("GuardBolt","Sword","bolt",tuple(at(2.15)),A @ eul(ry=45),(0.62,0.3,0.62))
g.item("Habaki","Sword","brass",tuple(at(2.45)),A,(0.34,0.4,0.72))
B0, B1, B2, B3, B4 = at(2.35, 0), at(5.1, -0.07), at(7.8, -0.26), at(10.3, -0.58), at(11.05, -0.78)
seg("Sword","SwordBlade","blade",B0,B1,0.24,0.6,extra=0.12)
seg("Sword","Blade2","blade",B1,B2,0.18,0.57,extra=0.12)
seg("Sword","Blade3","blade",B2,B3,0.24,0.54,extra=0.12)
seg("Sword","SwordTip","blade",B3,B4,0.14,0.36,extra=0.1)
for i, (p, q) in enumerate(((B0, B1), (B1, B2), (B2, B3)), 1):   # хамон — світла кромка по ріжучому боці (+wv)
    seg("Sword", f"Hamon{i}", "light", p + wv*0.25, q + wv*0.25, 0.06 if i == 2 else 0.12, 0.16, extra=0.03)
seg("Sword","SwordFuller","bolt",at(2.7,-0.08),at(7.6,-0.3),0.3,0.1)

# ---------- ящик: барабан бога грому ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","drumDark",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","drumDark",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","drum",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","drum",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","drum",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","drum",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","drumDark",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","drumDark",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","drumDark",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","drumDark",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz_ in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz_ > 0 else 'B'}"
        B("Corner" + t, "drumDark", (1.87*sx, 1.035, 1.13*sz_), (0.5, 1.67, 0.5))
for row, y in (("T", 1.45), ("D", 0.58)):     # ряди цвяхів на зовнішньому боці
    for i, x in enumerate((-1.2, -0.6, 0.0, 0.6, 1.2), 1):
        B(f"Tack{row}{i}", "steel", (x, y, -1.19), (0.2, 0.2, 0.1))
B("FrontBolt1","bolt",(0.25,1.2,-1.2),(0.2,0.55,0.14),eul(rz=-30))
B("FrontBolt2","bolt",(-0.15,0.8,-1.2),(0.2,0.55,0.14),eul(rz=-30))
B("FrontBoltMid","bolt",(0.05,1.0,-1.2),(0.42,0.16,0.08),eul(rz=10))
for sx, nm in ((1, "R"), (-1, "L")):   # шкіри барабана на торцях і однакові ручки-шнури
    B("Skin"+nm,"cloud",(2.12*sx,1.0,0),(0.2,1.2,1.2))
    B("SkinB"+nm,"cloud",(2.12*sx,1.0,0),(0.12,1.2,1.2),eul(rx=45))
    B("SkinMark"+nm,"bolt",(2.25*sx,1.0,0),(0.06,0.5,0.5),eul(rx=45))
    B("CordPostA"+nm,"cloud",(2.4*sx,1.3,0.32),(0.36,0.2,0.2)); B("CordPostB"+nm,"cloud",(2.4*sx,1.3,-0.32),(0.36,0.2,0.2))
    B("CordBar"+nm,"cloud",(2.6*sx,1.3,0),(0.22,0.26,0.9))
    B("Tassel"+nm,"bolt",(2.6*sx,0.98,0),(0.16,0.42,0.16))

# ---------- рухи ----------
g.fx.append(dict(kind="pulse", parts=[b["name"] for b in BOLT], amp=0.12, speed=5.0, states={"Mine": 1.8, "Run": 1.5}))
g.fx.append(dict(kind="bob", parts=CLOUD["R"], axis=(0, 1, 0), amp=0.14, speed=1.6))
g.fx.append(dict(kind="bob", parts=CLOUD["L"], axis=(0, 1, 0), amp=0.14, speed=1.6, phase=2.2))
g.fx.append(dict(kind="sway", parts=FLAG, pivot=(PX, 13.35, PZ), axis=(0, 1, 0), amp=0.28, speed=2.2, states={"Walk": 1.4, "Run": 2.0}))
POSES_LUA = """ poses={
  -- хода самурая: корпус рівний, підборіддя трохи вгору, руки майже не махають
  Walk=function(p, pose, rot)
   pose.Torso = { r = rot(0.02, 0.06 * math.sin(p), 0) }
   pose.Head = { r = rot(-0.04, 0, 0) }
   local s = math.sin(p)
   pose.UpperArm_R = { r = rot(-0.12 * s, 0, 0.06) }
   pose.UpperArm_L = { r = rot(0.12 * s, 0, -0.06) }
   return pose
  end,
  -- біг: нахил уперед, руки назад
  Run=function(p, pose, rot)
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(0.12, 0, 0) }
   return pose
  end,
  -- бойова стійка: корпус трохи повернутий, голова дивиться вперед, кулаки підняті, ноги ширше
  Idle=function(p, pose, rot)
   local s = math.sin(p)
   pose.Torso = { r = rot(0.04, 0.16, 0) }
   pose.Head = { r = rot(0.02 * s, -0.14, 0) }
   pose.UpperArm_R = { r = rot(-0.3, 0, 0.1) }
   pose.Forearm_R = { r = rot(-0.55 - 0.04 * s, 0, 0) }
   pose.UpperArm_L = { r = rot(-0.38, 0, -0.1) }
   pose.Forearm_L = { r = rot(-0.6 - 0.04 * s, 0, 0) }
   pose.Thigh_R = { r = rot(0, 0, 0.07) }
   pose.Thigh_L = { r = rot(0, 0, -0.07) }
   pose.Shin_R = { r = rot(0, 0, -0.07) }
   pose.Shin_L = { r = rot(0, 0, 0.07) }
   return pose
  end,
 },
"""

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    out = "/home/claude/storm/StormGolemData.lua"
    g.export(out, [
        "-- Storm Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано storm_golem_generator.py.",
        "-- Скелет = Clay … (21 кістка). neon — блискавка (Neon). fx / poses — унікальні анімації. Кірка й катана — власні форми (Grip, Pick4, SwordGrip — на стандартних місцях). Box — барабан у стадах."])
    s = open(out).read().replace(" bones={", " neon={bolt=true},\n" + POSES_LUA + " bones={", 1); open(out, "w").write(s)
