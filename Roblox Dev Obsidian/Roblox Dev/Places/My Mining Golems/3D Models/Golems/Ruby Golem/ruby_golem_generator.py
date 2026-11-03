# Ruby Golem (Legendary, мапа 3): ювелірний лицар — граньований рубін у рожево-золотих (rose gold) оправах на темному гранаті,
# із рубіновим вогнем (Neon). Фірмове: великий огранений рубін у грудях (обертається), три рубінові шпилі на спині й кристали на
# плечах, що «резонують» (погойдуються від основи), над чолом ширяє вогняний самоцвіт, корона з рубінових зубців.
# Анімації (GolemAnimator v3.2): fx — оберт рубіна в грудях, гойдання шпилів і плечових кристалів (sway від основи), самоцвіт над
# чолом пливе (bob); poses — велична хода (груди вперед, підборіддя вгору, руки майже не махають), біг, спокій — голова
# повільно оглядається, носій дивиться на ящик.
# Інструменти — НОВІ ФОРМИ (не шаблон PICK / SWORD):
#   кірка — «самоцвітна мотика»: голова — огранений рубін у рожево-золотому поясі, донизу — гранчастий кристалічний шип
#           (вістря Pick4 там само, де в усіх — удар по руді не змінюється), угору замість обуха — широке рожево-золоте тесло;
#   меч — рапіра: тонке рубінове лезо, що звужується трьома ступенями, світний дол, рожево-золота гарда-мушля (ромб),
#         кінцеві самоцвіти й дужка, що огинає кулак від гарди до навершя.
# Ящик — ювелірна скринька з рубіновим кабошоном і ручками-«Т» (вертикальна рукоять із самоцвітами на кінцях).
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(ruby="#b3122f", garnet="#4e0d20", rose="#e8a48c", glow="#ff2d55", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4"))
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
OCTA = eul(rx=35.264) @ eul(rz=45)
# ---------- ноги ----------
a("Foot_R","Shin_R","garnet",(2.15,0.55,0.15),(3.0,1.1,3.5),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","ruby",(2.1,2.2,-0.2),(2.5,2.3,2.5),eul(ry=4),mirror=True)
a("Greave_R","Shin_R","rose",(2.1,2.95,-0.2),(2.7,0.36,2.7),eul(ry=4),mirror=True)
a("KneeGem_R","Shin_R","glow",(2.2,2.95,1.35),(0.5,0.5,0.5),OCTA,mirror=True)
a("Thigh_R","Thigh_R","garnet",(2.0,3.95,-0.25),(2.6,1.7,2.6),eul(ry=-6),mirror=True)
a("Pelvis","Hips","garnet",(0,4.85,-0.35),(5.8,1.6,3.4))
a("Belt","Hips","rose",(0,5.4,-0.35),(6.0,0.45,3.6))
a("BeltGem","Hips","ruby",(0,5.4,1.55),(0.6,0.6,0.6),OCTA)
# ---------- корпус: огранений рубін у грудях ----------
a("Torso","Torso","ruby",(0,7.4,-0.3),(6.8,4.0,4.0))
a("Chest","Torso","garnet",(0,9.45,-0.4),(7.8,1.8,4.6))
a("Collar","Torso","rose",(0,10.25,-0.4),(4.6,0.4,3.6))
a("ChestSetting","Torso","rose",(0,7.6,1.82),(2.4,2.4,0.3),eul(rz=45))
a("ChestFire","Torso","glow",(0,7.6,1.99),(1.9,1.9,0.12),eul(rz=45))
a("ChestRuby","Torso","ruby",(0,7.6,2.2),(1.45,1.45,1.45),OCTA)
a("Filigree_R","Torso","rose",(2.35,7.35,1.75),(0.3,3.2,0.2),eul(rz=-15),mirror=True)
# ---------- спина: рубінові шпилі ----------
a("SpireBase","Torso","rose",(0,8.2,-2.45),(3.2,1.0,0.4))
a("SpireC","Torso","ruby",(0,9.85,-2.9),(1.0,3.4,1.0),eul(rx=-25) @ eul(ry=45))
a("SpireS_R","Torso","ruby",(1.35,9.2,-2.75),(0.8,2.6,0.8),eul(rz=-18) @ eul(rx=-22) @ eul(ry=45),mirror=True)
# ---------- голова: обруч, рубінова корона, вогняний самоцвіт над чолом ----------
a("Head","Head","ruby",(0,11.15,0.5014),(3.8,2.7,3.4))
a("Jaw","Head","garnet",(0,10.0,0.7),(3.4,0.8,2.7))
a("Circlet","Head","rose",(0,12.45,0.5),(4.0,0.5,3.6))
a("CircletGem","Head","glow",(0,12.45,2.33),(0.5,0.5,0.5),OCTA)
a("CrownC","Head","ruby",(0,13.25,0.1),(0.55,1.3,0.55),eul(ry=45))
a("CrownS_R","Head","ruby",(1.15,13.05,0.3),(0.5,1.0,0.5),eul(rz=-15) @ eul(ry=45),mirror=True)
a("Crest","Head","glow",(0,13.75,1.55),(0.55,0.55,0.55),OCTA)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","glow",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.0,2.24),(1.2,0.3,0.3),eul(rz=-6),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.46,2.3014),(1.1,0.28,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.26,0.5),mirror=True)
# ---------- руки ----------
a("Shoulder_R","UpperArm_R","garnet",(5.0,9.85,-0.3),(3.2,1.8,3.4),eul(rz=4),mirror=True)
a("Pauldron_R","UpperArm_R","rose",(5.1,10.9,-0.3),(3.0,0.4,3.2),eul(rz=4),mirror=True)
a("ShoulderGemA_R","UpperArm_R","ruby",(5.45,12.0,-0.45),(0.8,2.0,0.8),eul(rz=-18) @ eul(ry=45),mirror=True)
a("ShoulderGemB_R","UpperArm_R","ruby",(4.6,11.6,0.45),(0.6,1.4,0.6),eul(rx=18) @ eul(rz=8) @ eul(ry=45),mirror=True)
a("UpperArm_R","UpperArm_R","garnet",(5.25,8.0,-0.3),(2.2,2.6,2.3),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","ruby",(5.55,5.75,0.0014),(2.7,2.4,2.8),eul(ry=-6),mirror=True)
a("Cuff_R","Forearm_R","rose",(5.55,6.55,0.0014),(2.9,0.4,3.0),eul(ry=-6),mirror=True)
a("CuffGem_R","Forearm_R","glow",(6.95,6.0,0.0),(0.24,0.6,0.6),eul(rx=45),mirror=True)
fist = a("Fist_R","Forearm_R","garnet",(5.65,3.45,0.1014),(3.2,2.4,3.2),eul(ry=6.875))
sub(fist,"Knuckles_R","rose",(0.15,0.3,1.62),(2.6,0.8,0.4))
sub(fist,"KnuckleGem_R","ruby",(0.15,0.3,1.9),(0.5,0.5,0.24),eul(rz=45))
sub(fist,"Thumb_R","garnet",(-1.7,0.1,0.95),(0.5,1.0,0.9),eul(rz=-6)); mir(4)

# ---------- допоміжне: деталь уздовж відрізка (у площині x = -5.65 кулака) ----------
X = np.array([1.0, 0, 0])
def frameY(d):
    d = d / np.linalg.norm(d); z = np.cross(X, d); z /= np.linalg.norm(z)
    return np.column_stack([X, d, z])
def seg(grp, name, col, p0, p1, w, t=None, extra=0.0, octa=False, R2=None):
    """Брусок від p0 до p1 (вісь Y уздовж), переріз w × t; octa — другий такий самий брусок, повернутий на 45° (восьмигранник)."""
    p0, p1 = np.array(p0, float), np.array(p1, float); R = frameY(p1 - p0)
    if R2 is not None: R = R @ R2
    L = np.linalg.norm(p1 - p0) + extra; c = (p0 + p1) / 2; t = w if t is None else t
    b = g.item(name, grp, col, c, R, (w, L, t))
    if octa: g.item(name + "X", grp, col, c, R @ eul(ry=45), (w * 0.9, L * 0.92, t * 0.9))
    return b
u = np.array([0, 0.1215, 0.99259]); wv = np.array([0, -0.99259, 0.1215])   # вісь держака і «вниз» від неї
A = PICK["Handle"][1]

# ---------- кірка — самоцвітна мотика ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","garnet"); P("Grip","rose")
for i, (k, rot) in enumerate(((1.0, 0), (2.0, 45), (3.0, 0)), 1):      # рожево-золоті обмотки «спіраллю»
    sub(HN, f"Wrap{i}", "rose", (0, k, 0), (0.82, 0.24, 0.82), eul(ry=rot))
PM = P("Pommel","rose",(0.9,0.6,0.9))
sub(PM,"PommelGem","ruby",(0,-0.6,0),(0.55,0.55,0.55),OCTA)
H = np.array(PICK["Head"][0])                                         # центр голови
HD = g.item("Head","Pickaxe","rose",tuple(H),A,(1.05,1.0,1.05))       # рожево-золота втулка
sub(HD,"HeadGem","ruby",(0,0.45,0),(1.65,1.65,1.65),OCTA)              # голова — огранений рубін
sub(HD,"HeadBand","rose",(0,0.45,0),(1.95,0.34,1.95),eul(ry=45))
sub(HD,"HeadFire","glow",(0,0.45,0),(2.05,0.16,0.5))
# шип: від низу голови до вістря Pick4 (Pick4 — як у всіх: удар по руді той самий)
p4c, p4R, p4s = PICK["Pick4"]; p4c = np.array(p4c); p4back = p4c - p4R[:, 2] * p4s[2] / 2
S0 = H + wv * 0.55 + u * 0.45; Mid = np.array((-5.65, 1.55, 8.2))
seg("Pickaxe","Spike1","ruby",S0,Mid,0.95,extra=0.3,octa=True)
seg("Pickaxe","Spike2","ruby",Mid,p4back,0.66,extra=0.3,octa=True)
g.item("Pick4","Pickaxe","glow",tuple(p4c),p4R,p4s)
seg("Pickaxe","SpikeFire","glow",S0 + (Mid - S0) * 0.15,Mid,0.2,1.08)  # світна жилка вздовж шипа
# тесло замість обуха
sub(HD,"AdzeNeck","rose",(0,0.45,-1.15),(0.7,0.62,0.7))
sub(HD,"Adze","rose",(0,0.45,-1.95),(2.5,0.28,1.35))
sub(HD,"AdzeEdge","glow",(0,0.45,-2.66),(2.3,0.4,0.14))
sub(HD,"AdzeGemR","ruby",(1.25,0.45,-1.75),(0.46,0.46,0.46),OCTA)
sub(HD,"AdzeGemL","ruby",(-1.25,0.45,-1.75),(0.46,0.46,0.46),OCTA)

# ---------- меч — рапіра ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
GR = S("SwordGrip","garnet"); S("SwordCoil1","rose"); S("SwordCoil2","rose")
g0 = np.array(SWORD["SwordGrip"][0])
def at(aa, bb=0.0): return g0 + u * aa + wv * bb
g.item("SwordPommel","Sword","ruby",tuple(at(-2.15)),A @ OCTA,(0.85,0.85,0.85))
g.item("PommelCap","Sword","rose",tuple(at(-1.82)),A,(0.8,0.3,0.8))
GD = g.item("SwordGuard","Sword","rose",tuple(at(2.25)),A,(0.5,0.42,2.9))          # хрестовина
g.item("GuardShell","Sword","rose",tuple(at(2.62)),A @ eul(ry=45),(1.3,0.16,1.3))    # мушля-ромб
g.item("GuardGemA","Sword","ruby",tuple(at(2.25, 1.55)),A @ OCTA,(0.46,0.46,0.46))
g.item("GuardGemB","Sword","ruby",tuple(at(2.25, -1.55)),A @ OCTA,(0.46,0.46,0.46))
# дужка, що огинає кулак знизу: від кінця гарди до навершя
B0, B1, B2, B3 = at(2.2, 1.35), at(1.35, 2.05), at(-1.3, 2.05), at(-2.0, 0.5)
seg("Sword","BowA","rose",B0,B1,0.24,extra=0.22)
seg("Sword","BowB","rose",B1,B2,0.3,extra=0.22)
seg("Sword","BowC","rose",B2,B3,0.24,extra=0.22)
# лезо: три ступені, що звужуються
g.item("Ricasso","Sword","rose",tuple(at(2.95)),A,(0.4,0.6,0.95))
g.item("SwordBlade","Sword","ruby",tuple(at(4.55)),A,(0.3,3.5,0.8))
g.item("Blade2","Sword","ruby",tuple(at(7.45)),A,(0.24,2.5,0.6))
g.item("Blade3","Sword","ruby",tuple(at(9.6)),A,(0.18,2.0,0.42))
g.item("SwordFuller","Sword","glow",tuple(at(4.75)),A,(0.38,2.9,0.2))
g.item("Fuller2","Sword","glow",tuple(at(7.4)),A,(0.32,2.1,0.16))
g.item("SwordTip","Sword","ruby",tuple(at(10.75)),A @ eul(ry=45) @ eul(rx=0),(0.3,0.5,0.3))

# ---------- ящик — ювелірна скринька (у стадах, півот = центр дна; -Z — зовнішній бік) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","garnet",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","garnet",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","garnet",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","garnet",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","garnet",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","garnet",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","rose",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","rose",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","rose",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","rose",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Post" + t, "rose", (1.87*sx, 1.035, 1.13*sz), (0.5, 1.67, 0.5))
        B("Spire" + t, "ruby", (1.87*sx, 2.2, 1.13*sz), (0.3, 0.62, 0.3), eul(ry=45))
# зовнішній бік (-Z): рубіновий кабошон в оправі, рожево-золота філігрань і бічні самоцвіти
B("Setting","rose",(0,1.0,-1.21),(1.0,1.0,0.2),eul(rz=45))
B("Cabochon","ruby",(0,1.0,-1.36),(0.62,0.62,0.62),OCTA)
for i, (x, rz) in enumerate(((-0.95, 30), (0.95, -30)), 1):
    B(f"Filigree{i}","rose",(x,1.0,-1.18),(0.12,1.1,0.1),eul(rz=rz))
    B(f"SideGem{i}","glow",(x*1.5,1.0,-1.2),(0.32,0.32,0.16),eul(rz=45))
# ручки-«Т»: консоль від стінки + вертикальна рукоять із самоцвітами на кінцях і світним кільцем
for sx, nm in ((1, "R"), (-1, "L")):
    B(f"HandleArm{nm}","rose",(2.22*sx,1.3,0),(0.5,0.34,0.34))
    B(f"HandleT{nm}","rose",(2.52*sx,1.3,0),(0.26,1.1,0.26))
    B(f"HandleRing{nm}","glow",(2.52*sx,1.62,0),(0.34,0.16,0.34))
    B(f"HandleGemTop{nm}","ruby",(2.52*sx,1.98,0),(0.36,0.36,0.36),OCTA)
    B(f"HandleGemBot{nm}","ruby",(2.52*sx,0.62,0),(0.36,0.36,0.36),OCTA)

# ---------- унікальні рухи (GolemAnimator v3.2) ----------
g.free_parts = ("Crest",)   # вогняний самоцвіт ширяє над чолом
g.fx.append(dict(kind="spin", parts=["ChestRuby"], pivot=(0, 7.6, 2.2), axis=(0, 0, 1), speed=0.8, states={"Mine": 2.0, "Run": 1.6}))
g.fx.append(dict(kind="sway", parts=["SpireC", "SpireS_R", "SpireS_L"], pivot=(0, 8.4, -2.6), axis=(1, 0, 0), amp=0.09, speed=1.7,
                 states={"Walk": 1.5, "Run": 2.2, "Mine": 1.8}))
g.fx.append(dict(kind="sway", parts=["ShoulderGemA_R", "ShoulderGemB_R"], pivot=(5.1, 11.1, -0.3), axis=(0, 0, 1), amp=0.1, speed=2.1))
g.fx.append(dict(kind="sway", parts=["ShoulderGemA_L", "ShoulderGemB_L"], pivot=(-5.1, 11.1, -0.3), axis=(0, 0, 1), amp=0.1, speed=2.1, phase=3.14))
g.fx.append(dict(kind="bob", parts=["Crest"], axis=(0, 1, 0), amp=0.22, speed=2.0))
POSES_LUA = """ poses={
  -- велична хода: груди вперед, підборіддя вгору, руки майже не махають
  Walk=function(p, pose, rot)
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(-0.06, 0, 0) }
   pose.Head = { r = (pose.Head and pose.Head.r or CFrame.identity) * rot(-0.08, 0, 0) }
   local uR, uL = pose.UpperArm_R or {}, pose.UpperArm_L or {}
   local s = math.sin(p)
   pose.UpperArm_R = { r = (uR.r or CFrame.identity) * rot(-0.18 * s, 0, 0) }
   pose.UpperArm_L = { r = (uL.r or CFrame.identity) * rot(0.18 * s, 0, 0) }
   return pose
  end,
  -- біг: корпус рівно, лише легкий нахил
  Run=function(p, pose, rot)
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(-0.05, 0, 0) }
   return pose
  end,
  -- спокій: голова повільно оглядається з боку в бік
  Idle=function(p, pose, rot)
   pose.Head = { r = (pose.Head and pose.Head.r or CFrame.identity) * rot(0, 0.22 * math.sin(p), 0) }
   return pose
  end,
  -- носій: обережно, голова дивиться на скриньку
  Carry=function(p, pose, rot)
   pose.Head = { r = (pose.Head and pose.Head.r or CFrame.identity) * rot(0.16, 0, 0) }
   return pose
  end,
 },
"""

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    out = "/home/claude/ruby/RubyGolemData.lua"
    g.export(out, [
        "-- Ruby Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано ruby_golem_generator.py.",
        "-- Скелет = Clay … Magmaheart (21 кістка). neon — рубіновий вогонь (Neon). fx / poses — унікальні анімації (GolemAnimator v3.2). Box — власний ящик у стадах. Кірка й меч — власні форми (Grip, Pick4, SwordGrip — на стандартних місцях)."])
    s = open(out).read().replace(" bones={", " neon={glow=true},\n" + POSES_LUA + " bones={", 1); open(out, "w").write(s)
