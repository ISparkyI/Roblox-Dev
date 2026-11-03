# Phantom Golem (Exclusive #4, рівень Mythic): примарний лицар — темний кістяний метал, срібло, блідо-бірюзове примарне світло.
# Новий прийом: НАПІВПРОЗОРІ деталі (D.alpha: колір -> Transparency) і новий вид анімації fade (GolemAnimator v3.6):
# прозорість деталі мерехтить base + amp·(0.5+0.5·sin). Душа-ядро в грудях видно крізь скляне вікно між ребрами (pulse),
# примарні ноги, плюмаж і вогники на наплічниках мерехтять (fade), рваний плащ із пластин гойдається (sway).
# Пози: хода «пливе» (ноги майже не крокують), у спокої корпус ледь колихається.
# Інструменти власної форми: кірка-коса, КЛЕЙМОР (новий тип: широке пряме лезо, гарда з V-подібними квілонами до леза).
# Ящик — склеп-скриня з ліхтарями-душами на кутах і однаковими ручками-ланцюгами. Скелет Clay.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(bone="#3c414d", boneDark="#1f232b", silver="#a7b0bb", ghost="#3fd9c0", ghostSoft="#9fe3d8", glass="#a8efe6", soul="#5effd8",
               light="#f1f5f8", dark="#1c2836", pink="#f2a0b4", crypt="#596070", cryptDark="#2c3038"),
          bones={"Mouth": (0,10.5,2.3014), "MouthCorner_R": (0.65,10.6,2.3014), "MouthCorner_L": (-0.65,10.6,2.3014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
FADE = []
# ---------- ноги: примарні (напівпрозорі, мерехтять) зі срібними наколінниками ----------
a("Foot_R","Shin_R","ghost",(2.2,0.55,0.2),(3.2,1.1,3.7),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","ghost",(2.15,2.2,-0.2),(2.7,2.3,2.7),eul(ry=4),mirror=True)
FADE += ["Foot_R","Foot_L","Shin_R","Shin_L"]
a("KneeGuard_R","Shin_R","silver",(2.15,3.25,-0.2),(2.9,0.45,2.9),eul(ry=4),mirror=True)
a("Thigh_R","Thigh_R","bone",(2.0,4.0,-0.25),(2.8,1.7,2.8),eul(ry=-6),mirror=True)
# ---------- таз ----------
a("Pelvis","Hips","boneDark",(0,4.85,-0.3),(6.2,1.6,3.5))
a("Belt","Hips","silver",(0,5.45,-0.3),(6.6,0.5,3.9))
a("Buckle","Hips","soul",(0,5.45,1.75),(0.5,0.5,0.24),eul(rz=45))
# ---------- корпус: вікно-ґрати, крізь яке видно душу ----------
a("Torso","Torso","bone",(0,7.5,-0.3),(7.4,4.2,4.2))
a("Chest","Torso","boneDark",(0,9.6,-0.35),(8.6,1.6,4.7))
a("Gorget","Torso","silver",(0,10.3,-0.35),(4.8,0.5,3.8))
a("SoulCore","Torso","soul",(0,7.65,1.78),(1.5,1.5,0.4),eul(rz=45))
a("SoulGlass","Torso","glass",(0,7.65,1.95),(2.4,2.4,0.16))
a("WindowRim","Torso","silver",(0,7.65,1.86),(2.9,2.9,0.12))
for i, y in enumerate((8.3, 7.65, 7.0), 1):
    a(f"Rib{i}","Torso","silver",(0,y,2.08),(2.7 - 0.25*abs(i-2),0.2,0.2))
# плащ із пластин (гойдаються)
CAPE = []
for i, (x, L, ang) in enumerate([(-2.1, 4.0, 3), (-0.72, 4.7, -2), (0.72, 4.4, 2), (2.1, 3.7, -3)], 1):
    a(f"Cape{i}","Torso","ghostSoft",(x, 10.3 - L/2, -2.58),(1.2, L, 0.2),eul(rz=ang, rx=-4)); CAPE.append((f"Cape{i}", x))
# ---------- голова: шолом із примарним плюмажем ----------
a("Head","Head","bone",(0,11.15,0.5014),(4.0,2.7,3.4))
a("Helm","Head","boneDark",(0,12.85,0.4),(4.4,0.9,3.8))
a("HelmBrim","Head","silver",(0,12.38,0.5),(4.3,0.34,3.7))
a("CheekGuard_R","Head","silver",(2.08,11.3,1.0),(0.24,1.8,1.6),mirror=True)
PLUME = [a("Plume1","Head","ghost",(0,13.65,0.2),(1.0,0.8,1.6))["name"],
         a("Plume2","Head","ghost",(0,14.25,-0.1),(0.76,0.6,1.2),eul(rx=-12))["name"],
         a("Plume3","Head","ghost",(0,14.72,-0.45),(0.5,0.5,0.8),eul(rx=-24))["name"]]
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","soul",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.0,2.25),(1.2,0.26,0.3),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.24,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.5,2.3014),(1.1,0.24,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.22,0.5),mirror=True)
# ---------- руки: наплічники з вогниками, ланцюги на передпліччях ----------
a("Shoulder_R","UpperArm_R","bone",(5.0,9.85,-0.3),(3.4,1.9,3.6),eul(rz=3),mirror=True)
a("Pauldron_R","UpperArm_R","boneDark",(5.15,10.95,-0.3),(3.6,0.45,3.8),eul(rz=3),mirror=True)
a("PauldronRim_R","UpperArm_R","silver",(5.1,10.62,-0.3),(3.56,0.22,3.76),eul(rz=3),mirror=True)
a("Wisp_R","UpperArm_R","ghost",(5.4,11.5,-0.3),(0.8,0.7,0.8),eul(ry=45),mirror=True)
a("WispTop_R","UpperArm_R","ghost",(5.45,12.0,-0.35),(0.46,0.5,0.46),eul(ry=45, rz=-10),mirror=True)
FADE += ["Wisp_R","Wisp_L","WispTop_R","WispTop_L"] + PLUME
a("UpperArm_R","UpperArm_R","boneDark",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","bone",(5.55,5.75,0.0014),(2.9,2.4,3.0),eul(ry=-6),mirror=True)
a("Bracer_R","Forearm_R","silver",(5.55,6.55,0.0014),(3.1,0.4,3.2),eul(ry=-6),mirror=True)
for i, t in enumerate((0.15, 0.4, 0.65, 0.9), 1):      # ланцюг навскіс по передпліччю (ланки по черзі повернуті)
    x, y = 4.55 + 2.0*t, 6.25 - 1.6*t
    a(f"Chain{i}_R","Forearm_R","silver",(x, y, 1.5),(0.44, 0.24, 0.16) if i % 2 else (0.24, 0.44, 0.2),eul(rz=-38),mirror=True)
fist = a("Fist_R","Forearm_R","boneDark",(5.65,3.45,0.1014),(3.6,2.7,3.6),eul(ry=6.875))
sub(fist,"Knuckles_R","silver",(0.15,0.3,1.85),(3.0,1.0,0.45))
sub(fist,"KnuckleSoul_R","soul",(0.15,0.3,2.12),(0.4,0.4,0.2),eul(rz=45))
sub(fist,"Thumb_R","boneDark",(-1.9,0.1,1.05),(0.5,1.1,0.9),eul(rz=-6)); mir(4)

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
OCTA = eul(rx=35.264) @ eul(rz=45)

# ---------- кірка-коса ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","boneDark"); P("Grip","bone")
for i, k in enumerate((1.6, 2.9), 1): sub(HN, f"Ring{i}", "silver", (0, k, 0), (0.82, 0.24, 0.82))
PM = P("Pommel","silver")
sub(PM,"PommelSoul","soul",(0,-0.4,0),(0.4,0.3,0.4),eul(ry=45))
H = np.array(PICK["Head"][0])
HD = g.item("Head","Pickaxe","silver",tuple(H + u*0.2),A,(1.0,1.3,1.0))
sub(HD,"HeadSoul","soul",(0,0.2,0),(1.1,0.4,0.5))
sub(HD,"Hook","boneDark",(0,0.25,-0.9),(0.6,0.6,1.0))
sub(HD,"HookTip","silver",(0,0.55,-1.45),(0.4,0.8,0.4),eul(rx=-30))
p4c, p4R, p4s = PICK["Pick4"]; p4c = np.array(p4c); p4back = p4c - p4R[:, 2] * p4s[2] / 2
S0 = H + wv*0.5 + u*0.15; C1 = H + wv*1.5 + u*0.85; C2 = H + wv*2.9 + u*0.55
seg("Pickaxe","Blade1","bone",S0,C1,0.24,1.0,extra=0.3)
seg("Pickaxe","Blade2","bone",C1,C2,0.2,0.9,extra=0.3)
seg("Pickaxe","Blade3","bone",C2,p4back,0.24,0.6,extra=0.3)
g.item("Pick4","Pickaxe","silver",tuple(p4c),p4R,p4s)
for i, (p, q, w) in enumerate(((S0, C1, 0.14), (C1, C2, 0.1), (C2, p4back, 0.14)), 1):   # примарна кромка з боку держака
    seg("Pickaxe", f"Edge{i}", "ghost", p - u*0.5, q - u*0.5 + (q - p)*0.02, w, 0.22, extra=0.12)

# ---------- клеймор ----------
g0 = np.array(SWORD["SwordGrip"][0])
def at(aa, bb=0.0): return g0 + u * aa + wv * bb
g.item("SwordGrip","Sword","boneDark",tuple(at(-0.3)),A,(0.64,4.2,0.64))
for i, k in enumerate((-1.6, -0.6, 0.4, 1.4), 1):
    g.item(f"Wrap{i}","Sword","bone",tuple(at(k)),A,(0.74,0.24,0.74))
g.item("SwordPommel","Sword","silver",tuple(at(-2.6)),A @ OCTA,(0.7,0.7,0.7))
g.item("PommelSoul","Sword","soul",tuple(at(-2.6)),A @ eul(ry=45),(0.5,0.84,0.5))
GC = at(2.1)
g.item("SwordGuard","Sword","silver",tuple(GC),A,(0.5,0.5,1.0))
for sgn, nm in ((1, "R"), (-1, "L")):        # квілони V: від центру вбік і до леза
    end = at(2.75, 1.45*sgn)
    seg("Sword", f"Quillon{nm}", "silver", GC + wv*0.3*sgn, end, 0.36, 0.3, extra=0.25)
    g.item(f"QuillonSoul{nm}", "Sword", "soul", tuple(end + u*0.12), A @ OCTA, (0.4, 0.4, 0.4))
g.item("Ricasso","Sword","silver",tuple(at(2.8)),A,(0.44,0.8,1.0))
g.item("SwordBlade","Sword","bone",tuple(at(6.6)),A,(0.28,7.2,1.3))
g.item("SwordEdge","Sword","silver",tuple(at(6.55)),A,(0.2,7.0,1.56))
g.item("SwordFuller","Sword","ghost",tuple(at(5.6)),A,(0.34,4.6,0.26))
g.item("SwordTip","Sword","silver",tuple(at(10.25)),A @ eul(rx=45),(0.22,0.95,0.95))

# ---------- ящик: склеп-скриня з ліхтарями-душами ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","cryptDark",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","cryptDark",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","crypt",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","crypt",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","crypt",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","crypt",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","silver",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","silver",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","silver",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","silver",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz_ in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz_ > 0 else 'B'}"
        B("Corner" + t, "cryptDark", (1.87*sx, 1.035, 1.13*sz_), (0.5, 1.67, 0.5))
        B("Lantern" + t, "ghost", (1.87*sx, 2.2, 1.13*sz_), (0.3, 0.44, 0.3))
        B("LanternCap" + t, "cryptDark", (1.87*sx, 2.46, 1.13*sz_), (0.46, 0.12, 0.46))
B("ArchL","silver",(-0.42,1.15,-1.2),(0.18,1.0,0.12),eul(rz=-32)); B("ArchR","silver",(0.42,1.15,-1.2),(0.18,1.0,0.12),eul(rz=32))
B("ArchSoul","soul",(0,1.6,-1.22),(0.3,0.3,0.12),eul(rz=45))
B("Plinth","cryptDark",(0,0.62,-1.18),(1.6,0.2,0.08))
for i, x in enumerate((-1.3, 1.3), 1): B(f"Rune{i}","ghost",(x,1.0,-1.2),(0.16,0.6,0.1))
for sx, nm in ((1, "R"), (-1, "L")):   # однакові ручки-ланцюги
    B("ChainPostA"+nm,"silver",(2.2*sx,1.3,0.34),(0.4,0.24,0.24)); B("ChainPostB"+nm,"silver",(2.2*sx,1.3,-0.34),(0.4,0.24,0.24))
    B("LinkA"+nm,"silver",(2.43*sx,1.12,0.32),(0.12,0.5,0.18),eul(rx=15)); B("LinkC"+nm,"silver",(2.43*sx,1.12,-0.32),(0.12,0.5,0.18),eul(rx=-15))
    B("LinkB"+nm,"silver",(2.43*sx,0.9,0),(0.26,0.16,0.9))

# ---------- рухи ----------
g.fx.append(dict(kind="pulse", parts=["SoulCore"], amp=0.16, speed=3.0, states={"Mine": 1.8, "Run": 1.5}))
g.fx.append(dict(kind="fade", parts=FADE, amp=0.38, speed=1.3, states={"Idle": 0.6, "Walk": 1.4, "Run": 2.0}))
for i, (nm, x) in enumerate(CAPE):
    g.fx.append(dict(kind="sway", parts=[nm], pivot=(x, 10.2, -2.58), axis=(1, 0, 0), amp=0.09, speed=1.8, phase=1.3*i,
                     states={"Walk": 1.5, "Run": 2.2}))
g.fx.append(dict(kind="sway", parts=PLUME[1:], pivot=(0, 13.9, 0.0), axis=(1, 0, 0), amp=0.12, speed=2.2))
POSES_LUA = """ poses={
  -- хода «пливе»: ноги майже не крокують, корпус рівний, руки опущені
  Walk=function(p, pose, rot)
   local s = math.sin(p)
   pose.Thigh_R = { r = rot(-0.12 * s, 0, 0) }
   pose.Thigh_L = { r = rot(0.12 * s, 0, 0) }
   pose.Shin_R = { r = rot(0.06, 0, 0) }
   pose.Shin_L = { r = rot(0.06, 0, 0) }
   pose.Torso = { r = rot(0.03, 0, 0.03 * s) }
   pose.UpperArm_R = { r = rot(-0.05 * s, 0, 0.08) }
   pose.UpperArm_L = { r = rot(0.05 * s, 0, -0.08) }
   return pose
  end,
  -- спокій: корпус і голова ледь колихаються, як привид
  Idle=function(p, pose, rot)
   local s, c = math.sin(p), math.cos(p)
   pose.Torso = { r = rot(0.03 * s, 0, 0.04 * c) }
   pose.Head = { r = rot(-0.03 * s, 0.08 * math.sin(p * 0.5), -0.03 * c) }
   return pose
  end,
 },
"""

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    out = "/home/claude/phantom/PhantomGolemData.lua"
    g.export(out, [
        "-- Phantom Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано phantom_golem_generator.py.",
        "-- Скелет = Clay … (21 кістка). neon — душа й примарне світло (Neon); alpha — напівпрозорі кольори (GolemBuilder v2). fx fade — GolemAnimator v3.6."])
    s = open(out).read().replace(" bones={", " neon={soul=true,ghost=true},\n alpha={ghost=0.45,ghostSoft=0.45,glass=0.7},\n" + POSES_LUA + " bones={", 1); open(out, "w").write(s)
