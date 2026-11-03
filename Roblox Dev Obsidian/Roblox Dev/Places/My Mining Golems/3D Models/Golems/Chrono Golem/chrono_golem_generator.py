# Chrono Golem (Exclusive #5, рівень Celestial / Divine): володар часу — бронза годинникового механізму, білий фарфор,
# золото й аметистове світло часу (Neon).
# ОСОБЛИВИЙ ТРЮК — «тіні часу» (GolemAnimator v3.7, D.echo): за кожною рукою й ногою тягнеться напівпрозора копія,
# що повторює рух із затримкою (відлуння руху); у спокої копії сховані всередині кінцівок.
# Тіло: пісочний годинник на грудях (пісок падає — drift), циферблат на спині зі стрілками (годинна й хвилинна крутяться
# з різною швидкістю — spin), кільце-німб з поділок навколо голови (spin), шестерні на плечах (spin).
# Пози: спокій — голова «тікає», як секундна стрілка (кроками); хода — велична.
# Інструменти: кірка-шестерня (частини тремтять — Wobble), меч — клинок-стрілка годинника (новий тип), гарда-шестерня,
# навершя-маятник. Ящик — скриня-годинник із циферблатом і маятником, ручки-шестерні. Аура — ChronoAura (світло, пісок часу).
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(bronze="#b5803f", bronzeDark="#5a3c22", porcelain="#f4f0e6", gold="#f2c85a", time="#6656ff",
               glass="#e6dcff", echo="#8a80ff", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4"),
          bones={"Mouth": (0,10.5,2.3014), "MouthCorner_R": (0.65,10.6,2.3014), "MouthCorner_L": (-0.65,10.6,2.3014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
OCTA = eul(rx=35.264) @ eul(rz=45)
# ---------- ноги ----------
a("Foot_R","Shin_R","bronzeDark",(2.2,0.55,0.2),(3.2,1.1,3.7),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","bronze",(2.15,2.2,-0.2),(2.7,2.3,2.7),eul(ry=4),mirror=True)
a("Thigh_R","Thigh_R","bronzeDark",(2.0,4.0,-0.25),(2.8,1.7,2.8),eul(ry=-6),mirror=True)
# ---------- таз ----------
a("Pelvis","Hips","bronzeDark",(0,4.85,-0.3),(6.2,1.6,3.5))
a("Belt","Hips","gold",(0,5.45,-0.3),(6.6,0.5,3.9))
a("Buckle","Hips","porcelain",(0,5.45,1.72),(0.7,0.7,0.24),eul(rz=45))
# ---------- корпус: пісочний годинник ----------
a("Torso","Torso","bronze",(0,7.5,-0.3),(7.4,4.2,4.2))
a("Chest","Torso","bronzeDark",(0,9.6,-0.35),(8.6,1.6,4.7))
a("Collar","Torso","gold",(0,10.3,-0.35),(4.8,0.5,3.8))
a("GlassTopPlate","Torso","gold",(0,9.0,1.95),(1.9,0.3,0.5))
a("GlassBotPlate","Torso","gold",(0,6.25,1.95),(1.9,0.3,0.5))
a("GlassPost_R","Torso","gold",(0.82,7.62,1.95),(0.22,2.5,0.32),mirror=True)
a("BulbTop","Torso","glass",(0,8.32,1.95),(1.2,1.06,0.42))
a("BulbBot","Torso","glass",(0,6.93,1.95),(1.2,1.06,0.42))
a("Neck","Torso","glass",(0,7.62,1.95),(0.4,0.36,0.38))
a("SandTop","Torso","time",(0,8.05,1.95),(0.94,0.4,0.3))
a("SandBot","Torso","time",(0,6.65,1.95),(1.0,0.46,0.3))
a("Grain1","Torso","time",(0,7.4,1.95),(0.16,0.24,0.16))
# ---------- спина: циферблат зі стрілками ----------
a("BackPlate","Torso","bronzeDark",(0,7.2,-2.45),(4.2,3.0,0.3))
DC = np.array((0, 8.2, -2.95))
a("DialBack","Torso","bronzeDark",(0,8.2,-2.75),(3.3,3.3,0.3))
a("DialA","Torso","porcelain",tuple(DC),(2.9,2.9,0.14))
for k in range(6):
    ang = 60*k; R = eul(rz=ang)
    a(f"Tick{k+1}","Torso","gold",tuple(DC + R @ np.array([0, 1.3, -0.08])),(0.16,0.4,0.08),R)
a("HourHand","Torso","gold",tuple(DC + np.array([0, 0.45, -0.12])),(0.26,0.9,0.1))
RM = eul(rz=-120)
a("MinuteHand","Torso","bronzeDark",tuple(DC + RM @ np.array([0, 0.62, -0.17])),(0.18,1.24,0.08),RM)
a("DialHub","Torso","time",tuple(DC + np.array([0, 0, -0.2])),(0.34,0.34,0.2),eul(rz=45))
# ---------- голова: шестірчаста корона, кільце поділок ----------
a("Head","Head","bronze",(0,11.15,0.5014),(4.0,2.7,3.4))
a("HelmTop","Head","bronzeDark",(0,12.8,0.35),(3.9,0.5,3.4))
a("CrownBand","Head","gold",(0,12.42,0.5),(4.2,0.4,3.6))
a("CrownGem","Head","time",(0,12.42,2.33),(0.46,0.46,0.12),eul(rz=45))
a("CrownGear","Head","gold",(0,13.2,0.4),(1.1,0.3,1.1))
HALO_C = np.array((0, 13.75, 0.4)); HALO = []
for k in range(6):
    ang = 60*k + 30; R = eul(ry=ang)
    HALO.append(a(f"HaloTick{k+1}","Head","gold",tuple(HALO_C + R @ np.array([0, 0, 2.6])),(0.24,0.3,0.6),R)["name"])
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","time",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.0,2.25),(1.2,0.26,0.3),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.24,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.5,2.3014),(1.1,0.24,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.22,0.5),mirror=True)
# ---------- руки: шестерні на плечах ----------
a("Shoulder_R","UpperArm_R","bronze",(5.0,9.85,-0.3),(3.4,1.9,3.6),eul(rz=3),mirror=True)
a("Pauldron_R","UpperArm_R","bronzeDark",(5.15,10.95,-0.3),(3.6,0.45,3.8),eul(rz=3),mirror=True)
a("PauldronRim_R","UpperArm_R","gold",(5.1,10.62,-0.3),(3.56,0.22,3.76),eul(rz=3),mirror=True)
a("Gear_R","UpperArm_R","gold",(6.82,9.6,-0.3),(0.24,1.2,1.2),eul(rz=3),mirror=True)
a("GearB_R","UpperArm_R","gold",(6.82,9.6,-0.3),(0.16,1.2,1.2),eul(rz=3) @ eul(rx=45),mirror=True)
a("GearHub_R","UpperArm_R","time",(6.95,9.6,-0.3),(0.24,0.5,0.5),eul(rz=3) @ eul(rx=45),mirror=True)
a("UpperArm_R","UpperArm_R","bronzeDark",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","bronze",(5.55,5.75,0.0014),(2.9,2.4,3.0),eul(ry=-6),mirror=True)
a("Bracer_R","Forearm_R","gold",(5.55,6.55,0.0014),(3.1,0.4,3.2),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","bronze",(5.65,3.45,0.1014),(3.6,2.7,3.6),eul(ry=6.875))
sub(fist,"Knuckles_R","gold",(0.15,0.3,1.85),(3.0,1.0,0.45))
sub(fist,"KnuckleGem_R","time",(0.15,0.3,2.12),(0.4,0.4,0.2),eul(rz=45))
sub(fist,"Thumb_R","bronze",(-1.9,0.1,1.05),(0.5,1.1,0.9),eul(rz=-6)); mir(4)
# ---------- «тіні часу»: копії кінцівок усередині них (видно, лише коли кінцівка рухається) ----------
ECHO = []
byname = {b["name"]: b for b in g.blocks}
for nm in ("UpperArm", "Forearm", "Fist", "Thigh", "Shin", "Foot"):
    for sd in ("_R", "_L"):
        b = byname[nm + sd]
        g.blocks.append(dict(b, name="Echo" + nm + sd, col="echo", s=b["s"] * 0.9))
        ECHO.append("Echo" + nm + sd)
g.free_parts = tuple(HALO + ["Grain1"] + ECHO)

# ---------- допоміжне ----------
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

# ---------- кірка-шестерня ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","bronzeDark"); P("Grip","gold")
for i, k in enumerate((1.6, 2.9), 1): sub(HN, f"Ring{i}", "gold", (0, k, 0), (0.82, 0.24, 0.82))
PM = P("Pommel","gold")
sub(PM,"PommelGem","time",(0,-0.4,0),(0.4,0.3,0.4),eul(ry=45))
H = np.array(PICK["Head"][0])
g.item("Head","Pickaxe","gold",tuple(H),A,(0.5,1.9,1.9))
g.item("GearB","Pickaxe","gold",tuple(H),A @ eul(rx=45),(0.44,1.9,1.9))
g.item("GearHub","Pickaxe","time",tuple(H),A @ eul(rx=45),(0.72,0.7,0.7))
g.item("GearRim","Pickaxe","bronzeDark",tuple(H),A,(0.56,1.3,1.3))
SG = H - wv*1.25
g.item("SmallGear","Pickaxe","bronze",tuple(SG),A,(0.34,0.9,0.9))
g.item("SmallGearB","Pickaxe","bronze",tuple(SG),A @ eul(rx=45),(0.3,0.9,0.9))
p4c, p4R, p4s = PICK["Pick4"]; p4c = np.array(p4c); p4back = p4c - p4R[:, 2] * p4s[2] / 2
S0 = H + wv*0.8; Mid = np.array((-5.65, 1.55, 8.2))
seg("Pickaxe","Pick1","bronze",S0,Mid,0.64,0.7,extra=0.3)
seg("Pickaxe","Pick2","bronze",Mid,p4back,0.5,0.55,extra=0.3)
g.item("Pick4","Pickaxe","gold",tuple(p4c),p4R,p4s)
seg("Pickaxe","PickGlow","time",S0 + (Mid - S0)*0.25,Mid,0.66,0.18)

# ---------- меч — клинок-стрілка годинника ----------
g0 = np.array(SWORD["SwordGrip"][0])
def at(aa, bb=0.0): return g0 + u * aa + wv * bb
g.item("SwordGrip","Sword","bronzeDark",tuple(g0),A,(0.66,3.6,0.66))
for i, k in enumerate((-1.1, 0.0, 1.1), 1):
    g.item(f"Wrap{i}","Sword","gold",tuple(at(k)),A,(0.76,0.26,0.76))
g.item("PendulumRod","Sword","gold",tuple(at(-2.2)),A,(0.2,0.7,0.2))
g.item("SwordPommel","Sword","gold",tuple(at(-2.75)),A @ eul(rx=45),(0.3,0.8,0.8))
g.item("PommelCore","Sword","time",tuple(at(-2.75)),A @ eul(rx=45),(0.36,0.4,0.4))
g.item("SwordGuard","Sword","gold",tuple(at(2.15)),A,(1.5,0.3,1.5))
g.item("GuardGearB","Sword","gold",tuple(at(2.15)),A @ eul(ry=45),(1.5,0.2,1.5))
g.item("GuardHub","Sword","time",tuple(at(2.15)),A @ eul(ry=45),(0.6,0.36,0.6))
g.item("SwordBlade","Sword","bronze",tuple(at(5.1)),A,(0.24,5.4,0.5))
g.item("SwordFuller","Sword","time",tuple(at(5.0)),A,(0.3,4.4,0.14))
g.item("BladeSpade","Sword","gold",tuple(at(8.55)),A @ eul(rx=45),(0.32,1.4,1.4))
g.item("SpadeCore","Sword","time",tuple(at(8.55)),A @ eul(rx=45),(0.38,0.62,0.62))
g.item("SwordTip","Sword","gold",tuple(at(9.95)),A,(0.2,1.2,0.26))
g.item("TipPoint","Sword","gold",tuple(at(10.6)),A @ eul(rx=45),(0.14,0.34,0.34))

# ---------- ящик — скриня-годинник ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","bronzeDark",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","bronzeDark",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","bronze",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","bronze",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","bronze",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","bronze",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","gold",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","gold",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","gold",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","gold",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz_ in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz_ > 0 else 'B'}"
        B("Corner" + t, "bronzeDark", (1.87*sx, 1.035, 1.13*sz_), (0.5, 1.67, 0.5))
B("FaceA","porcelain",(0,1.12,-1.2),(0.82,0.82,0.12)); B("FaceB","porcelain",(0,1.12,-1.2),(0.82,0.82,0.08),eul(rz=45))
B("FaceHandH","gold",(0,1.27,-1.265),(0.1,0.32,0.05)); B("FaceHandM","bronzeDark",(0.15,1.03,-1.31),(0.08,0.42,0.08),eul(rz=-125))
B("PendBob","gold",(0,0.47,-1.27),(0.26,0.26,0.12),eul(rz=45))
for i, x in enumerate((-1.2, 1.2), 1): B(f"SideGem{i}","time",(x,1.12,-1.2),(0.26,0.26,0.12),eul(rz=45))
for sx, nm in ((1, "R"), (-1, "L")):   # однакові ручки-шестерні
    B("GearPost"+nm,"gold",(2.2*sx,1.2,0),(0.4,0.24,0.24))
    B("HGear"+nm,"gold",(2.46*sx,1.2,0),(0.14,0.8,0.8)); B("HGearB"+nm,"gold",(2.46*sx,1.2,0),(0.08,0.8,0.8),eul(rx=45))
    B("HGearHub"+nm,"time",(2.55*sx,1.2,0),(0.08,0.26,0.26),eul(rx=45))

# ---------- рухи ----------
g.fx.append(dict(kind="spin", parts=["HourHand"], pivot=tuple(DC), axis=(0, 0, 1), speed=-0.35))
g.fx.append(dict(kind="spin", parts=["MinuteHand"], pivot=tuple(DC), axis=(0, 0, 1), speed=-1.8, states={"Run": 2.0, "Mine": 1.6}))
g.fx.append(dict(kind="spin", parts=HALO, pivot=tuple(HALO_C), axis=(0, 1, 0), speed=0.6, states={"Walk": 1.5, "Run": 2.5}))
g.fx.append(dict(kind="spin", parts=["Gear_R","GearB_R","GearHub_R"], pivot=(6.82, 9.6, -0.3), axis=(1, 0, 0), speed=1.2))
g.fx.append(dict(kind="spin", parts=["Gear_L","GearB_L","GearHub_L"], pivot=(-6.82, 9.6, -0.3), axis=(1, 0, 0), speed=-1.2))
g.fx.append(dict(kind="drift", parts=["Grain1"], axis=(0, 1, 0), amp=0.36, speed=1.4))
g.fx.append(dict(kind="pulse", parts=["DialHub", "SandBot"], amp=0.1, speed=2.4))
EXTRA_LUA = """ echo={ delay=0.16, parts={%s} },
 poses={
  -- спокій: голова «тікає», як секундна стрілка, — повертається кроками
  Idle=function(p, pose, rot)
   local steps = { -0.12, -0.04, 0.04, 0.12, 0.04, -0.04 }
   local k = math.floor((p %% (2 * math.pi)) / (2 * math.pi) * #steps) + 1
   pose.Head = { r = rot(0, steps[k], 0) }
   return pose
  end,
  -- хода: велична, корпус рівний, руки за ритмом
  Walk=function(p, pose, rot)
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(-0.04, 0, 0) }
   pose.Head = { r = rot(-0.05, 0, 0) }
   return pose
  end,
 },
""" % ",".join(f'"{n}"' for n in ECHO)

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    out = "/home/claude/chrono/ChronoGolemData.lua"
    g.export(out, [
        "-- Chrono Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано chrono_golem_generator.py.",
        "-- Скелет = Clay … (21 кістка). neon — світло часу; alpha — скло й тіні часу. echo — «тіні часу» (GolemAnimator v3.7). Аура — ChronoAura."])
    s = open(out).read().replace(" bones={", " neon={time=true,echo=true},\n alpha={glass=0.6,echo=0.62},\n" + EXTRA_LUA + " bones={", 1); open(out, "w").write(s)
