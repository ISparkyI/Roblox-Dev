# Obsidian Golem (Legendary): вулканічне скло — чорно-фіолетовий обсидіан із сірим склистим відблиском і смарагдовими
# світними тріщинами (Neon). Фірмове: орбіта з трьох світних уламків, що кружляє над головою; серце-кристал у грудях,
# що обертається; гострі уламки на плечах, колінах, ліктях; три уламки-шипи на спині.
# Унікальні анімації (GolemAnimator v3): fx — орбіта уламків, оберт серця, гойдання жаринок на плечах;
# poses — важка хода (присідання на кожному кроці, розгойдування корпусу), «дихання» в спокої, носій трохи відхиляється назад.
# Унікальні предмети: кірка-уламок (склиста голова з тріщинами, скляні леза, світний уламок замість обуха),
# меч-ікло (рогата гарда зі світним серцем, обсидіанове лезо зі світним долом).
# Ящик — обсидіановий реліквіарій: тріщини назовні, кутові уламки, нові ручки — похилі розпірки + світна кристалічна перекладина.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(obs="#17141f", sheen="#3d3b56", glow="#a855f7", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4"))
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
OCTA = eul(rx=35.264) @ eul(rz=45)
# ---------- ноги ----------
a("Foot_R","Shin_R","obs",(2.15,0.55,0.15),(3.0,1.1,3.5),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","sheen",(2.1,2.2,-0.2),(2.5,2.3,2.5),eul(ry=4),mirror=True)
a("ShinCrack_R","Shin_R","glow",(2.05,1.95,1.07),(0.16,1.3,0.12),eul(rz=22),mirror=True)
a("KneeShard_R","Shin_R","obs",(2.15,3.05,1.25),(0.8,1.7,0.8),eul(rx=48) @ eul(ry=45),mirror=True)
a("Thigh_R","Thigh_R","obs",(2.0,3.95,-0.25),(2.6,1.7,2.6),eul(ry=-6),mirror=True)
a("Pelvis","Hips","obs",(0,4.85,-0.35),(5.8,1.6,3.4))
a("Belt","Hips","sheen",(0,5.4,-0.35),(6.0,0.45,3.6))
a("BeltCrack","Hips","glow",(0,5.4,1.47),(1.6,0.2,0.1))
# ---------- корпус: розколота грудна плита із серцем ----------
a("Torso","Torso","obs",(0,7.4,-0.3),(6.8,4.0,4.0))
a("Chest","Torso","sheen",(0,9.45,-0.4),(7.8,1.8,4.6))
a("ChestPlate","Torso","sheen",(0,7.45,1.79),(4.4,2.9,0.3))
a("HeartSocket","Torso","obs",(0,7.6,2.0),(1.7,1.7,0.3),eul(rz=45))
a("Heart","Torso","glow",(0,7.6,2.12),(0.85,0.85,0.85),OCTA)
a("ChestCrackA_R","Torso","glow",(1.25,8.35,1.93),(0.16,1.4,0.1),eul(rz=-40),mirror=True)
a("ChestCrackB_R","Torso","glow",(0.95,6.55,1.93),(0.14,1.05,0.1),eul(rz=30),mirror=True)
# ---------- спина: три уламки-шипи й тріщина ----------
a("Spine","Torso","obs",(0,9.55,-3.0),(1.0,3.2,1.0),eul(rx=-35) @ eul(ry=45))
a("SpineS_R","Torso","obs",(1.65,8.95,-2.8),(0.8,2.6,0.8),eul(rz=-25) @ eul(rx=-30) @ eul(ry=45),mirror=True)
a("BackCrack","Torso","glow",(0,7.4,-2.33),(0.16,2.4,0.1))
# ---------- голова: уламки на маківці й орбіта ----------
a("Head","Head","obs",(0,11.15,0.5014),(3.8,2.7,3.4))
a("Jaw","Head","sheen",(0,10.0,0.7),(3.4,0.8,2.7))
a("HeadShard","Head","obs",(0,13.05,0.25),(0.9,1.7,0.9),eul(rx=-10) @ eul(ry=45))
a("HeadShardS_R","Head","sheen",(1.3,12.75,0.1),(0.6,1.1,0.6),eul(rz=-28) @ eul(ry=45),mirror=True)
ORBIT_C = np.array((0, 13.9, 0.4)); OR = 2.35
for k in range(3):
    ang = np.radians(90 + k * 120)
    c = ORBIT_C + np.array((OR*np.cos(ang), 0.15*(k-1), OR*np.sin(ang)))
    a(f"Orbit{k+1}","Head","glow",tuple(c),(0.42,0.95,0.42),eul(rz=18) @ eul(ry=45 + k*20))
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","glow",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.3,2.24),(1.2,0.3,0.3),eul(rz=-8),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.46,2.3014),(1.1,0.28,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.26,0.5),mirror=True)
# ---------- руки: уламки на плечах, жаринки, шипи на ліктях ----------
a("Shoulder_R","UpperArm_R","obs",(5.0,9.85,-0.3),(3.2,1.8,3.4),eul(rz=4),mirror=True)
a("Pauldron_R","UpperArm_R","sheen",(5.1,10.9,-0.3),(3.0,0.4,3.2),eul(rz=4),mirror=True)
a("ShoulderShardA_R","UpperArm_R","obs",(5.75,12.15,-0.55),(0.9,2.6,0.9),eul(rz=-20) @ eul(ry=45),mirror=True)
a("ShoulderShardB_R","UpperArm_R","sheen",(4.55,11.75,-1.1),(0.65,1.8,0.65),eul(rx=-25) @ eul(rz=10) @ eul(ry=45),mirror=True)
a("Ember_R","UpperArm_R","glow",(4.75,12.95,0.75),(0.36,0.36,0.36),OCTA,mirror=True)
a("PauldronCrack_R","UpperArm_R","glow",(5.1,10.4,1.42),(1.6,0.16,0.1),eul(rz=4),mirror=True)
a("UpperArm_R","UpperArm_R","obs",(5.25,8.0,-0.3),(2.2,2.6,2.3),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","sheen",(5.55,5.75,0.0014),(2.7,2.4,2.8),eul(ry=-6),mirror=True)
a("Cuff_R","Forearm_R","obs",(5.55,6.55,0.0014),(2.9,0.4,3.0),eul(ry=-6),mirror=True)
a("ElbowShard_R","Forearm_R","obs",(7.05,6.35,-0.2),(0.55,1.5,0.55),eul(rz=-50) @ eul(ry=45),mirror=True)
fist = a("Fist_R","Forearm_R","obs",(5.65,3.45,0.1014),(3.2,2.4,3.2),eul(ry=6.875))
sub(fist,"Knuckles_R","sheen",(0.15,0.3,1.62),(2.6,0.8,0.4))
sub(fist,"KnuckleCrack_R","glow",(0.15,0.3,1.87),(1.8,0.14,0.12))
sub(fist,"Thumb_R","obs",(-1.7,0.1,0.95),(0.5,1.0,0.9),eul(rz=-6)); mir(4)

# ---------- кірка-уламок ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","obs"); P("Grip","sheen"); P("Band","glow")
PM = P("Pommel","obs",(0.95,0.7,0.95))
sub(PM,"PommelShard","glow",(0,-0.75,0),(0.45,0.9,0.45),eul(ry=45))
sub(HN,"Ring1","sheen",(0,1.2,0),(0.85,0.3,0.85))
sub(HN,"Ring2","glow",(0,2.4,0),(0.8,0.24,0.8),eul(ry=45))
HD = P("Head","obs",(1.6,1.8,1.9))
sub(HD,"HeadCrackR","glow",(0.82,0.1,0),(0.12,1.3,0.2),eul(rx=30))
sub(HD,"HeadCrackL","glow",(-0.82,0.1,0),(0.12,1.3,0.2),eul(rx=-30))
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n,"sheen")
P("PickGlint","glow")
sub(HD,"PollShard","obs",(0,0.1,-1.75),(0.75,0.75,1.9),eul(rz=45))
sub(HD,"PollTip","glow",(0,0.1,-2.95),(0.42,0.42,0.7),eul(rz=45))
sub(HD,"PollSide","sheen",(0,0.62,-1.45),(0.4,0.4,1.0),eul(rx=-35) @ eul(rz=45))
# ---------- меч-ікло ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordPommel","obs"); S("SwordGrip","obs"); S("SwordCoil1","sheen"); S("SwordCoil2","sheen")
S("SwordPommelTop","glow")
G = S("SwordGuard","sheen",(0.8,0.6,1.7))
HR = sub(G,"HornR","obs",(0,0.8,1.05),(0.5,1.6,0.5),eul(rx=28))    # роги вигнуті до леза
HL = sub(G,"HornL","obs",(0,0.8,-1.05),(0.5,1.6,0.5),eul(rx=-28))
sub(HR,"HornTipR","glow",(0,0.92,0),(0.3,0.5,0.3))                 # світні кінчики — продовження рогів
sub(HL,"HornTipL","glow",(0,0.92,0),(0.3,0.5,0.3))
sub(G,"GuardHeart","glow",(0,0.15,0),(0.75,0.75,0.75),OCTA)
S("SwordBlade","obs",(0.45,6.6,1.5)); S("SwordEdge","sheen",(0.3,6.1,1.85)); S("SwordFuller","glow",(0.6,4.4,0.38))
S("SwordTip","obs")

# ---------- ящик — обсидіановий реліквіарій (у стадах, півот = центр дна; -Z — зовнішній бік) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","obs",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","obs",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","obs",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","obs",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","obs",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","obs",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","sheen",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","sheen",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","sheen",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","sheen",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Corner" + t, "obs", (1.98*sx, 1.55, 1.08*sz), (0.5, 1.9, 0.5), eul(rx=12*sz) @ eul(rz=-14*sx) @ eul(ry=45))
# тріщини назовні (-Z) і уламок-емблема
B("FisA","glow",(-0.95,1.15,-1.17),(0.14,1.0,0.1),eul(rz=30))
B("FisB","glow",(0.0,0.55,-1.17),(0.14,0.7,0.1),eul(rz=-30))
B("FisC","glow",(0.95,1.15,-1.17),(0.14,1.0,0.1),eul(rz=30))
B("Emblem","sheen",(0,1.3,-1.24),(0.75,0.75,0.2),eul(rz=45))
B("EmblemCore","glow",(0,1.3,-1.34),(0.42,0.42,0.12),eul(rz=45))
# ручки: дві похилі розпірки від стінки + світна кристалічна перекладина з обсидіановими ковпачками й обмотками
for sx, nm in ((1, "R"), (-1, "L")):
    for sz, t in ((1, "A"), (-1, "B")):
        B(f"Strut{t}{nm}", "obs", (2.24*sx, 1.38, 0.36*sz), (0.22, 0.78, 0.22), eul(rz=-50*sx))
        B(f"GripCap{t}{nm}", "obs", (2.5*sx, 1.64, 0.53*sz), (0.34, 0.34, 0.2))
        B(f"GripWrap{t}{nm}", "sheen", (2.5*sx, 1.64, 0.2*sz), (0.3, 0.3, 0.12))
    B(f"GripBar{nm}", "glow", (2.5*sx, 1.64, 0), (0.24, 0.24, 1.06))

g.free_parts = ("Orbit1", "Orbit2", "Orbit3", "Ember_R", "Ember_L")  # навмисно вільні: орбіта й жаринки
# ---------- унікальні рухи (GolemAnimator v3) ----------
g.fx.append(dict(kind="spin", parts=["Orbit1", "Orbit2", "Orbit3"], pivot=tuple(ORBIT_C), axis=(0, 1, 0),
                 speed=1.1, states={"Walk": 1.6, "Run": 2.6, "Mine": 2.4, "Carry": 0.7}))   # орбіта уламків над головою
g.fx.append(dict(kind="spin", parts=["Heart"], pivot=(0, 7.6, 2.12), axis=(0, 0, 1), speed=1.4, states={"Mine": 2.5}))  # серце крутиться
g.fx.append(dict(kind="bob", parts=["Ember_R"], axis=(0, 1, 0), amp=0.28, speed=2.2, states={"Run": 1.8}))
g.fx.append(dict(kind="bob", parts=["Ember_L"], axis=(0, 1, 0), amp=0.28, speed=2.2, phase=3.14, states={"Run": 1.8}))
# власні пози кліпів (Lua-функції в GolemData.poses)
POSES_LUA = """ poses={
  -- важка хода: на кожному кроці таз присідає, корпус розгойдується з боку в бік, голова врівноважує
  Walk=function(p, pose, rot)
   local s = math.sin(p)
   local h = pose.Hips or {}
   pose.Hips = { t = (h.t or Vector3.zero) + Vector3.new(0, -0.16 * s * s, 0), r = h.r }
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(0.05, 0, 0.07 * s) }
   pose.Head = { r = (pose.Head and pose.Head.r or CFrame.identity) * rot(0, 0, -0.06 * s) }
   return pose
  end,
  Run=function(p, pose, rot)
   local s = math.sin(p)
   local h = pose.Hips or {}
   pose.Hips = { t = (h.t or Vector3.zero) + Vector3.new(0, -0.2 * s * s, 0), r = h.r }
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(0.06, 0, 0.05 * s) }
   return pose
  end,
  -- спокій: глибоке «дихання» — груди піднімаються, плечі розправляються
  Idle=function(p, pose, rot)
   local c = math.cos(p)
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(-0.05 * (1 - c) / 2, 0, 0) }
   local uR, uL = pose.UpperArm_R or {}, pose.UpperArm_L or {}
   pose.UpperArm_R = { r = (uR.r or CFrame.identity) * rot(0, 0, 0.05 * (1 - c) / 2) }
   pose.UpperArm_L = { r = (uL.r or CFrame.identity) * rot(0, 0, -0.05 * (1 - c) / 2) }
   return pose
  end,
  -- носій: важкий ящик — корпус трохи відхилений назад, таз нижче
  Carry=function(p, pose, rot)
   local h = pose.Hips or {}
   pose.Hips = { t = (h.t or Vector3.zero) + Vector3.new(0, -0.1, 0), r = h.r }
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(-0.08, 0, 0) }
   return pose
  end,
 },
"""

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    out = "/home/claude/obsidian/ObsidianGolemData.lua"
    g.export(out, [
        "-- Obsidian Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано obsidian_golem_generator.py.",
        "-- Скелет = Clay … Sapphire (21 кістка). neon — світні тріщини (Neon). fx / poses — унікальні анімації (GolemAnimator v3). Box — власний ящик у стадах."])
    s = open(out).read().replace(" bones={", " neon={glow=true},\n" + POSES_LUA + " bones={", 1); open(out, "w").write(s)
