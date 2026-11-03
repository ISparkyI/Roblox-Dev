# Frostforged Golem (Mythic, мапа 4): лицар, викуваний у морозі — блідо-синя морозна сталь на темно-синьому, лід і крижане
# світло (Neon). Фірмове: на грудях — світна сніжинка, що обертається; на спині — «морозна кузня» (решітка зі світним ядром, що
# пульсує, і два димарі з крижаним світлом); на плечах крижані кристали, на шоломі гребінь і крижані роги; навколо голови
# падають сніжинки.
# Анімації (GolemAnimator v3.3): fx — сніжинка на грудях крутиться (spin), ядро кузні пульсує (pulse), сніжинки падають (новий
# вид drift); poses — карбований марш (високі коліна, руки рівно), біг ковзанярем (ноги розходяться вбік), у спокої — тремтить
# від холоду, носій тримає ящик рівно й високо.
# Інструменти власної форми (не шаблон і не рапіра):
#   кірка — льодоруб: сталевий Т-подібний обух, вигнутий зубчастий дзьоб зі світною крижаною кромкою донизу (вістря Pick4 на
#           стандартному місці), угорі — крижаний молот у сталевому поясі зі світною гранню, внизу держака — сталевий шип;
#   меч — вигнута крижана шабля: лезо — дуга з чотирьох крижаних сегментів зі сталевим обухом, гарда — сніжинка з трьох сталевих
#         брусків під 60°, у центрі крижаний самоцвіт, навершя — загострений кристал.
# Ящик — крижаний сундук: крижані стінки в сталевій рамі, бурульки під обідком, світна сніжинка, ручки — горизонтальна «D»-петля.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(steel="#a9bccf", navy="#22324a", ice="#d4f3ff", glow="#9fe2ff", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4"))
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
OCTA = eul(rx=35.264) @ eul(rz=45)
# ---------- ноги ----------
a("Foot_R","Shin_R","navy",(2.15,0.55,0.15),(3.0,1.1,3.5),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","steel",(2.1,2.2,-0.2),(2.5,2.3,2.5),eul(ry=4),mirror=True)
a("ShinRune_R","Shin_R","glow",(2.1,1.9,1.08),(0.18,1.1,0.12),mirror=True)
a("KneeIcicle_R","Shin_R","ice",(2.15,3.25,1.2),(0.6,1.5,0.6),eul(rx=40) @ eul(ry=45),mirror=True)
a("Thigh_R","Thigh_R","navy",(2.0,3.95,-0.25),(2.6,1.7,2.6),eul(ry=-6),mirror=True)
a("Pelvis","Hips","navy",(0,4.85,-0.35),(5.8,1.6,3.4))
a("Belt","Hips","steel",(0,5.4,-0.35),(6.0,0.45,3.6))
a("BeltGem","Hips","glow",(0,5.4,1.55),(0.55,0.55,0.55),OCTA)
# ---------- корпус: сніжинка на грудях ----------
a("Torso","Torso","steel",(0,7.4,-0.3),(6.8,4.0,4.0))
a("Chest","Torso","navy",(0,9.45,-0.4),(7.8,1.8,4.6))
a("Collar","Torso","steel",(0,10.25,-0.4),(4.6,0.4,3.6))
SNOW_C = (0, 7.6, 1.8)
for i, (ang, z, d) in enumerate(((0, 1.80, 0.1), (60, 1.83, 0.1), (120, 1.86, 0.1)), 1):
    a(f"Flake{i}","Torso","glow",(0,7.6,z),(0.26,2.5,d),eul(rz=ang))
a("FlakeCore","Torso","ice",(0,7.6,1.98),(0.7,0.7,0.7),OCTA)
# ---------- спина: морозна кузня ----------
a("Forge","Torso","navy",(0,8.0,-2.75),(2.8,2.4,1.0))
a("ForgeCore","Torso","glow",(0,8.0,-3.24),(2.0,1.6,0.1))
for i, y in enumerate((7.45, 8.0, 8.55), 1):
    a(f"Grill{i}","Torso","steel",(0,y,-3.3),(2.3,0.2,0.16))
for sx, nm in ((1, "R"), (-1, "L")):
    a(f"Chimney{nm}","Torso","steel",(0.85*sx,9.75,-2.75),(0.6,1.3,0.6))
    a(f"ChimneyFire{nm}","Torso","glow",(0.85*sx,10.46,-2.75),(0.42,0.16,0.42))
# ---------- голова: шолом із гребенем і крижаними рогами ----------
a("Head","Head","steel",(0,11.15,0.5014),(3.8,2.7,3.4))
a("Jaw","Head","navy",(0,10.0,0.7),(3.4,0.8,2.7))
a("HelmCrest","Head","steel",(0,12.85,0.375),(0.5,0.75,2.95))
a("CrestIce","Head","ice",(0,13.3,0.35),(0.3,0.3,2.6))
a("Visor","Head","navy",(0,12.62,2.1),(3.5,0.28,0.42))
a("Horn_R","Head","ice",(1.85,12.75,0.35),(0.45,1.6,0.45),eul(rz=-38) @ eul(ry=45),mirror=True)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","glow",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.2,2.24),(1.2,0.3,0.3),eul(rz=-6),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.46,2.3014),(1.1,0.28,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.26,0.5),mirror=True)
# сніжинки, що падають навколо голови (вільні)
SNOW = [((2.75, 13.4, 1.4), 0.0), ((-2.7, 13.6, -1.1), 1.6), ((1.3, 13.8, -2.2), 3.1), ((-1.6, 13.5, 2.3), 4.6)]
for i, (p, ph) in enumerate(SNOW, 1):
    a(f"Snow{i}","Torso","glow",p,(0.32,0.32,0.08),eul(rz=45) @ eul(ry=30*i))
# ---------- руки: крижані кристали на плечах ----------
a("Shoulder_R","UpperArm_R","navy",(5.0,9.85,-0.3),(3.2,1.8,3.4),eul(rz=4),mirror=True)
a("Pauldron_R","UpperArm_R","steel",(5.1,10.9,-0.3),(3.0,0.4,3.2),eul(rz=4),mirror=True)
a("IceA_R","UpperArm_R","ice",(5.5,12.1,-0.45),(0.9,2.3,0.9),eul(rz=-22) @ eul(ry=45),mirror=True)
a("IceB_R","UpperArm_R","ice",(4.55,11.7,0.5),(0.65,1.6,0.65),eul(rx=20) @ eul(rz=10) @ eul(ry=45),mirror=True)
a("PauldronRune_R","UpperArm_R","glow",(5.1,10.4,1.42),(1.6,0.16,0.1),eul(rz=4),mirror=True)
a("UpperArm_R","UpperArm_R","navy",(5.25,8.0,-0.3),(2.2,2.6,2.3),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","steel",(5.55,5.75,0.0014),(2.7,2.4,2.8),eul(ry=-6),mirror=True)
a("Cuff_R","Forearm_R","ice",(5.55,6.55,0.0014),(2.9,0.4,3.0),eul(ry=-6),mirror=True)
a("ElbowIcicle_R","Forearm_R","ice",(7.05,6.35,-0.2),(0.5,1.4,0.5),eul(rz=-50) @ eul(ry=45),mirror=True)
fist = a("Fist_R","Forearm_R","navy",(5.65,3.45,0.1014),(3.2,2.4,3.2),eul(ry=6.875))
sub(fist,"Knuckles_R","steel",(0.15,0.3,1.62),(2.6,0.8,0.4))
sub(fist,"KnuckleRune_R","glow",(0.15,0.3,1.87),(1.9,0.14,0.12))
sub(fist,"Thumb_R","navy",(-1.7,0.1,0.95),(0.5,1.0,0.9),eul(rz=-6)); mir(4)

# ---------- допоміжне для предметів (площина x = -5.65 кулака) ----------
X = np.array([1.0, 0, 0])
def frameY(d):
    d = d / np.linalg.norm(d); z = np.cross(X, d); z /= np.linalg.norm(z)
    return np.column_stack([X, d, z])
def seg(grp, name, col, p0, p1, w, t=None, extra=0.0, off=0.0):
    """Брусок від p0 до p1 (вісь Y уздовж), w — товщина (X), t — ширина в площині; off — зсув уздовж нормалі в площині."""
    p0, p1 = np.array(p0, float), np.array(p1, float); R = frameY(p1 - p0)
    L = np.linalg.norm(p1 - p0) + extra; c = (p0 + p1) / 2 + R[:, 2] * off; t = w if t is None else t
    return g.item(name, grp, col, c, R, (w, L, t))
u = np.array([0, 0.1215, 0.99259]); wv = np.array([0, -0.99259, 0.1215])
A = PICK["Handle"][1]

# ---------- кірка — льодоруб ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","steel"); P("Grip","navy")
sub(HN,"Wrap1","navy",(0,1.3,0),(0.8,0.5,0.8))
sub(HN,"Wrap2","navy",(0,2.4,0),(0.8,0.5,0.8))
PM = P("Pommel","steel",(0.85,0.6,0.85))
sub(PM,"Ferrule","steel",(0,-0.55,0),(0.55,0.6,0.55),eul(ry=45))
sub(PM,"FerruleSpike","ice",(0,-1.05,0),(0.3,0.7,0.3),eul(ry=45))
H = np.array(PICK["Head"][0])
HD = g.item("Head","Pickaxe","steel",tuple(H),A,(0.9,1.0,2.2))           # Т-подібний обух (довгий у площині)
sub(HD,"HeadCap","navy",(0,0.2,0),(1.1,0.5,1.1))
sub(HD,"HeadRune","glow",(0,0.2,0),(1.16,0.16,0.6))
p4c, p4R, p4s = PICK["Pick4"]; p4c = np.array(p4c); p4back = p4c - p4R[:, 2] * p4s[2] / 2
S0 = H + wv * 1.0; M1 = np.array((-5.65, 2.3, 8.35)); M2 = np.array((-5.65, 0.75, 8.1))
seg("Pickaxe","Pick1","steel",S0,M1,0.44,0.95,extra=0.3)
seg("Pickaxe","Pick2","steel",M1,M2,0.34,0.8,extra=0.3)
seg("Pickaxe","Pick3","steel",M2,p4back,0.26,0.62,extra=0.3)
g.item("Pick4","Pickaxe","ice",tuple(p4c),p4R,p4s)
seg("Pickaxe","PickIce1","glow",S0,M1,0.24,0.2,extra=0.1,off=0.5)          # світна крижана кромка (зовнішній бік)
seg("Pickaxe","PickIce2","glow",M1,M2,0.2,0.2,extra=0.1,off=0.43)
for i, (p, q) in enumerate(((S0 + (M1 - S0) * 0.55, M1), (M1 + (M2 - M1) * 0.5, M2)), 1):  # зубці з внутрішнього боку
    d = (q - p) / np.linalg.norm(q - p); n = np.cross(X, d)
    g.item(f"Tooth{i}","Pickaxe","steel",tuple(p - n * 0.42),frameY(d) @ eul(rx=45),(0.24,0.32,0.32))
# крижаний молот угорі
sub(HD,"HammerNeck","steel",(0,0,-1.25),(0.7,0.7,0.5))
sub(HD,"HammerIce","ice",(0,0,-1.85),(1.25,1.25,0.9))
sub(HD,"HammerBand","steel",(0,0,-1.85),(1.35,1.35,0.32))
sub(HD,"HammerFace","glow",(0,0,-2.33),(0.95,0.95,0.1),eul(rz=45))

# ---------- меч — вигнута крижана шабля ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordGrip","navy"); S("SwordCoil1","steel"); S("SwordCoil2","steel")
g0 = np.array(SWORD["SwordGrip"][0])
def at(aa, bb=0.0): return g0 + u * aa + wv * bb
g.item("SwordPommel","Sword","steel",tuple(at(-2.15)),A,(0.85,0.55,0.85))
g.item("PommelIce","Sword","ice",tuple(at(-2.75)),A @ eul(ry=45),(0.45,0.9,0.45))
# гарда-сніжинка: три бруски під 60° у площині, перпендикулярній до леза (навколо осі u)
for i, ang in enumerate((0, 60, 120)):
    nm = "SwordGuard" if i == 0 else f"GuardBar{i}"
    g.item(nm,"Sword","steel",tuple(at(2.25)),A @ eul(ry=ang),(0.26,0.34 + 0.08*i,2.6))
g.item("GuardGem","Sword","glow",tuple(at(2.25)),A @ OCTA,(0.62,0.62,0.62))
# лезо-дуга (вигинається «вгору», від -wv)
pts = [at(2.45, 0.0), at(4.6, -0.12), at(6.7, -0.55), at(8.6, -1.25), at(10.15, -2.15)]
widths = (1.05, 0.95, 0.8, 0.6); thick = (0.36, 0.28, 0.2, 0.14)
for i in range(4):
    nm = "SwordBlade" if i == 0 else f"Blade{i+1}"
    seg("Sword", nm, "ice", pts[i], pts[i+1], thick[i], widths[i], extra=0.18)
    seg("Sword", f"Spine{i+1}", "steel", pts[i], pts[i+1], (0.5, 0.44)[i % 2], 0.2, extra=0.12 if i else 0.05, off=-(widths[i]/2 - 0.04))
    if i < 3: seg("Sword", f"Frost{i+1}", "glow", pts[i], pts[i+1], thick[i] + 0.08, 0.12, extra=-0.5, off=0.06)
d = pts[4] - pts[3]
g.item("SwordTip","Sword","ice",tuple(pts[4] + d / np.linalg.norm(d) * 0.18),frameY(d) @ eul(ry=45),(0.32,0.6,0.32))

# ---------- ящик — крижаний сундук (у стадах, півот = центр дна; -Z — зовнішній бік) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","navy",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","navy",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","ice",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","ice",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","ice",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","ice",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","steel",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","steel",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","steel",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","steel",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Post" + t, "steel", (1.87*sx, 1.035, 1.13*sz), (0.5, 1.67, 0.5))
        B("Crystal" + t, "ice", (1.87*sx, 2.25, 1.13*sz), (0.3, 0.7, 0.3), eul(rz=-12*sx) @ eul(ry=45))
# бурульки під обідком на зовнішньому боці (-Z) і світна сніжинка
for i, (x, h) in enumerate(((-1.3, 0.55), (-0.75, 0.35), (0.75, 0.4), (1.3, 0.6)), 1):
    B(f"Icicle{i}","ice",(x,1.78 - h/2,-1.23),(0.2,h,0.2),eul(ry=45))
for i, ang in enumerate((0, 60, 120), 1):
    B(f"BoxFlake{i}","glow",(0,0.95,-1.18 - 0.02*i),(0.16,1.05,0.06),eul(rz=ang))
B("BoxFlakeCore","ice",(0,0.95,-1.28),(0.36,0.36,0.36),OCTA)
# ручки — горизонтальна «D»-петля (у площині XZ на висоті 1.45)
for sx, nm in ((1, "R"), (-1, "L")):
    pts_b = [np.array((1.98*sx, 1.45, z)) for z in (0.5,)] + [np.array((2.42*sx, 1.45, 0.45)), np.array((2.62*sx, 1.45, 0.0)),
             np.array((2.42*sx, 1.45, -0.45)), np.array((1.98*sx, 1.45, -0.5))]
    for k in range(4):
        p0, p1 = pts_b[k], pts_b[k+1]; d = p1 - p0; L = np.linalg.norm(d) + 0.2
        y = np.array((0, 1.0, 0)); xx = d / np.linalg.norm(d); zz = np.cross(xx, y)
        B(f"Loop{k+1}{nm}", "glow" if k in (1, 2) else "steel", tuple((p0 + p1) / 2), (L, (0.28, 0.2, 0.15, 0.28)[k], (0.28, 0.2, 0.15, 0.28)[k]),
          np.column_stack([xx, y, zz]))
    B(f"LoopGem{nm}","ice",(2.64*sx,1.45,0),(0.34,0.34,0.34),OCTA)
    B(f"LoopMountA{nm}","steel",(2.1*sx,1.45,0.5),(0.3,0.44,0.36))
    B(f"LoopMountB{nm}","steel",(2.1*sx,1.45,-0.5),(0.3,0.44,0.36))

# ---------- унікальні рухи (GolemAnimator v3.3) ----------
g.free_parts = tuple(f"Snow{i}" for i in range(1, 5))
g.fx.append(dict(kind="spin", parts=["Flake1", "Flake2", "Flake3", "FlakeCore"], pivot=SNOW_C, axis=(0, 0, 1), speed=0.9,
                 states={"Walk": 1.4, "Run": 2.2, "Mine": 2.0}))
g.fx.append(dict(kind="pulse", parts=["ForgeCore"], amp=0.1, speed=3.0, states={"Mine": 1.6}))
for i, (p, ph) in enumerate(SNOW, 1):
    g.fx.append(dict(kind="drift", parts=[f"Snow{i}"], axis=(0, 1, 0), amp=1.6, speed=0.9 + 0.12*i, phase=ph))
POSES_LUA = """ poses={
  -- карбований марш: коліна вище, руки рівні й майже нерухомі
  Walk=function(p, pose, rot)
   local s = math.sin(p)
   local tR, tL = pose.Thigh_R or {}, pose.Thigh_L or {}
   pose.Thigh_R = { r = (tR.r or CFrame.identity) * rot(-0.18 * math.max(0, s), 0, 0) }
   pose.Thigh_L = { r = (tL.r or CFrame.identity) * rot(-0.18 * math.max(0, -s), 0, 0) }
   local uR, uL = pose.UpperArm_R or {}, pose.UpperArm_L or {}
   pose.UpperArm_R = { r = (uR.r or CFrame.identity) * rot(-0.15 * s, 0, 0) }
   pose.UpperArm_L = { r = (uL.r or CFrame.identity) * rot(0.15 * s, 0, 0) }
   return pose
  end,
  -- біг ковзанярем: ноги розходяться вбік, корпус хилиться за кроком
  Run=function(p, pose, rot)
   local s = math.sin(p)
   local tR, tL = pose.Thigh_R or {}, pose.Thigh_L or {}
   pose.Thigh_R = { r = (tR.r or CFrame.identity) * rot(0, 0, 0.16 * math.max(0, s)) }
   pose.Thigh_L = { r = (tL.r or CFrame.identity) * rot(0, 0, -0.16 * math.max(0, -s)) }
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(0.1, 0, -0.08 * s) }
   return pose
  end,
  -- спокій: тремтить від холоду
  Idle=function(p, pose, rot)
   local q = math.sin(14 * p)
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(0, 0, 0.012 * q) }
   pose.Head = { r = (pose.Head and pose.Head.r or CFrame.identity) * rot(0, 0.02 * q, 0) }
   return pose
  end,
  -- носій: тримає сундук рівно й вище
  Carry=function(p, pose, rot)
   local uR, uL = pose.UpperArm_R or {}, pose.UpperArm_L or {}
   pose.UpperArm_R = { r = (uR.r or CFrame.identity) * rot(-0.1, 0, 0) }
   pose.UpperArm_L = { r = (uL.r or CFrame.identity) * rot(-0.1, 0, 0) }
   return pose
  end,
 },
"""

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    out = "/home/claude/frostforged/FrostforgedGolemData.lua"
    g.export(out, [
        "-- Frostforged Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано frostforged_golem_generator.py.",
        "-- Скелет = Clay … Ruby (21 кістка). neon — крижане світло (Neon). fx / poses — унікальні анімації (GolemAnimator v3.3). Box — власний ящик у стадах. Кірка й меч — власні форми (Grip, Pick4, SwordGrip — на стандартних місцях)."])
    s = open(out).read().replace(" bones={", " neon={glow=true},\n" + POSES_LUA + " bones={", 1); open(out, "w").write(s)
