# Magmaheart Golem (Legendary, мапа 3): вулканічний громило — темна застигла кірка базальту, з тріщин тече лава (Neon),
# у грудях за кам'яними ґратами пульсує жовто-гаряче магмове серце. Фірмове: голова-кратер з озером лави і бризками,
# що злітають угору; на плечах — вулканічні жерла з лавовими краплями.
# Унікальні анімації (GolemAnimator v3.2): fx — серце пульсує розміром (pulse), бризки з кратера й жерл злітають і падають (bob);
# poses — агресивна хода вразвалку (розворот плечей), біг з нахилом уперед, «кипіння» в спокої, носій тримає ящик вище.
# Предмети: кірка-молот (кам'яна голова з лавовими швами, молот із розпеченою лавовою гранню замість обуха),
# меч-тесак (кам'яне лезо з розпеченою лавовою кромкою, гарда з лавовим поясом і шипами).
# Ящик — магмовий тигель: лава замість дна, лавові патьоки з обідка, емблема з лавовим хрестом, ручки-стремена.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(crust="#3a2c27", ash="#6e5c53", lava="#ff6a1a", core="#ffc93c", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4"))
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
OCTA = eul(rx=35.264) @ eul(rz=45)
# ---------- ноги ----------
a("Foot_R","Shin_R","crust",(2.15,0.55,0.15),(3.0,1.1,3.5),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","crust",(2.1,2.2,-0.2),(2.5,2.3,2.5),eul(ry=4),mirror=True)
a("ShinLava_R","Shin_R","lava",(2.0,1.85,1.08),(0.95,0.16,0.12),eul(rz=-12),mirror=True)
a("ShinLava2_R","Shin_R","lava",(2.4,2.5,1.08),(0.16,0.85,0.12),eul(rz=25),mirror=True)
a("KneeCap_R","Shin_R","ash",(2.1,3.25,0.95),(1.7,0.55,0.7),eul(ry=4),mirror=True)
a("Thigh_R","Thigh_R","crust",(2.0,3.95,-0.25),(2.6,1.7,2.6),eul(ry=-6),mirror=True)
a("ThighCrack_R","Thigh_R","lava",(2.05,4.0,1.1),(0.16,1.1,0.12),eul(rz=-20),mirror=True)
a("Pelvis","Hips","crust",(0,4.85,-0.35),(5.8,1.6,3.4))
a("Belt","Hips","ash",(0,5.4,-0.35),(6.0,0.45,3.6))
a("BeltLava","Hips","lava",(0,5.4,1.47),(2.4,0.2,0.1))
# ---------- корпус: магмове серце за ґратами ----------
a("Torso","Torso","crust",(0,7.4,-0.3),(6.8,4.0,4.0))
a("Chest","Torso","crust",(0,9.45,-0.4),(7.8,1.8,4.6))
a("HeartWindow","Torso","lava",(0,7.6,1.76),(2.6,2.6,0.2))
a("Heart","Torso","core",(0,7.6,1.95),(1.0,1.0,1.0),OCTA)
a("CageV_R","Torso","ash",(0.72,7.6,1.95),(0.3,2.9,0.4),mirror=True)
a("CageH1","Torso","ash",(0,8.55,1.97),(2.9,0.3,0.3))
a("CageH2","Torso","ash",(0,6.65,1.97),(2.9,0.3,0.3))
a("VeinA_R","Torso","lava",(2.15,8.1,1.75),(0.18,1.0,0.12),eul(rz=-50),mirror=True)
a("VeinB_R","Torso","lava",(2.0,6.35,1.75),(0.16,1.0,0.12),eul(rz=40),mirror=True)
# ---------- спина: кам'яні пластини над лавовим хребтом ----------
a("BackLava","Torso","lava",(0,8.0,-2.33),(2.0,3.4,0.1))
for i, y in enumerate((9.35, 8.1, 6.85), 1):
    a(f"BackPlate{i}","Torso","crust",(0,y,-2.55),(1.6,0.85,0.6),eul(rx=-20))
# ---------- голова-кратер ----------
a("Head","Head","crust",(0,11.15,0.5014),(3.8,2.7,3.4))
a("Jaw","Head","ash",(0,10.0,0.7),(3.4,0.8,2.7))
a("HeadCrack_R","Head","lava",(1.93,11.4,0.9),(0.1,1.3,0.18),eul(rx=25),mirror=True)
a("CraterF","Head","crust",(0,12.85,1.6),(3.0,0.7,0.5))
a("CraterB","Head","crust",(0,12.85,-0.6),(3.0,0.7,0.5))
a("CraterR","Head","crust",(1.3,12.85,0.5),(0.5,0.7,1.7))
a("CraterL","Head","crust",(-1.3,12.85,0.5),(0.5,0.7,1.7))
a("CraterLava","Head","lava",(0,12.72,0.5),(2.1,0.46,1.7))
a("Plume1","Head","core",(0,13.75,0.5),(0.6,0.6,0.6),OCTA)
a("Plume2","Head","lava",(0.25,14.45,0.35),(0.36,0.36,0.36),OCTA)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","core",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.3,2.24),(1.2,0.3,0.3),eul(rz=12),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.46,2.3014),(1.1,0.28,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.26,0.5),mirror=True)
# ---------- руки: вулканічні жерла на плечах ----------
a("Shoulder_R","UpperArm_R","crust",(5.0,9.85,-0.3),(3.2,1.8,3.4),eul(rz=4),mirror=True)
a("Vent_R","UpperArm_R","crust",(5.2,11.2,-0.3),(1.8,1.0,1.8),eul(ry=12),mirror=True)
a("VentLava_R","UpperArm_R","lava",(5.2,11.62,-0.3),(1.25,0.3,1.25),eul(ry=12),mirror=True)
a("VentBlob_R","UpperArm_R","core",(5.2,12.3,-0.3),(0.4,0.4,0.4),OCTA,mirror=True)
a("VentDrip_R","UpperArm_R","lava",(5.0,11.15,0.66),(0.2,0.75,0.12),eul(ry=12),mirror=True)
a("UpperArm_R","UpperArm_R","crust",(5.25,8.0,-0.3),(2.2,2.6,2.3),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","crust",(5.55,5.75,0.0014),(2.9,2.5,3.0),eul(ry=-6),mirror=True)
a("ForearmLava_R","Forearm_R","lava",(6.99,5.75,0.1),(0.12,1.7,0.2),eul(rx=18),mirror=True)
a("Cuff_R","Forearm_R","ash",(5.55,6.6,0.0014),(3.1,0.4,3.2),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","crust",(5.65,3.45,0.1014),(3.2,2.4,3.2),eul(ry=6.875))
sub(fist,"Knuckles_R","ash",(0.15,0.3,1.62),(2.6,0.8,0.4))
sub(fist,"KnuckleLava_R","lava",(0.15,0.3,1.87),(2.0,0.16,0.12))
sub(fist,"Thumb_R","crust",(-1.7,0.1,0.95),(0.5,1.0,0.9),eul(rz=-6)); mir(4)

# ---------- кірка-молот ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","crust"); P("Grip","ash"); P("Band","lava")
PM = P("Pommel","ash",(0.95,0.7,0.95))
sub(PM,"PommelLava","lava",(0,-0.42,0),(0.6,0.2,0.6))
sub(HN,"Ring1","lava",(0,1.2,0),(0.8,0.24,0.8))
sub(HN,"Ring2","ash",(0,2.4,0),(0.85,0.3,0.85),eul(ry=45))
HD = P("Head","crust",(1.6,1.8,1.9))
sub(HD,"HeadSeamR","lava",(0.82,0,0),(0.12,1.9,0.22))
sub(HD,"HeadSeamL","lava",(-0.82,0,0),(0.12,1.9,0.22))
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n,"ash")
P("PickGlint","lava")
sub(HD,"HammerNeck","crust",(0,0,-1.2),(1.1,1.1,0.6))
sub(HD,"Hammer","crust",(0,0,-1.85),(1.6,1.6,0.8))
sub(HD,"HammerBand","ash",(0,0,-1.85),(1.7,1.7,0.3))
sub(HD,"HammerFace","core",(0,0,-2.3),(1.15,1.15,0.14))
# ---------- меч-тесак ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordPommel","ash"); S("SwordGrip","crust"); S("SwordCoil1","lava"); S("SwordCoil2","lava")
S("SwordPommelTop","crust")
G = S("SwordGuard","crust",(0.9,0.7,2.2))
sub(G,"GuardLava","lava",(0,0,0),(1.0,0.4,1.5))
sub(G,"GuardSpikeR","ash",(0,0.6,1.0),(0.5,0.9,0.5),eul(rx=22))
sub(G,"GuardSpikeL","ash",(0,0.6,-1.0),(0.5,0.9,0.5),eul(rx=-22))
S("SwordBlade","crust",(0.45,6.6,1.5)); S("SwordEdge","lava",(0.3,6.1,1.85)); S("SwordFuller","ash",(0.6,4.4,0.38))
S("SwordTip","crust")

# ---------- ящик — магмовий тигель (у стадах, півот = центр дна; -Z — зовнішній бік) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","crust",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","crust",(0,0.6,0),(3.36,1.05,1.66))  # дно — застиглий базальт (руда не падає в лаву)
B("WallF","crust",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","crust",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","crust",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","crust",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","ash",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","ash",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","ash",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","ash",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Rock" + t, "crust", (2.0*sx, 0.42, 1.12*sz), (0.75, 0.62, 0.75), eul(ry=30*sx*sz))
# лавові патьоки з обідка назовні (-Z) і емблема з лавовим хрестом
for i, (x, h) in enumerate(((-1.35, 0.55), (-0.55, 0.6), (0.6, 0.45), (1.4, 0.5)), 1):
    B(f"Drip{i}", "lava", (x, 1.78 - h/2, -1.205), (0.18, h, 0.11))
    B(f"DripBlob{i}", "core", (x, 1.78 - h, -1.21), (0.28, 0.28, 0.18))
B("EmblemPlate","ash",(0,0.66,-1.21),(1.1,0.6,0.16))
B("EmblemX1","lava",(0,0.66,-1.31),(0.14,0.66,0.08),eul(rz=38))
B("EmblemX2","lava",(0,0.66,-1.33),(0.14,0.66,0.08),eul(rz=-38))
# ручки-стремена: дві кам'яні консолі від стінки, дві стійки вниз і розпечена лавова перекладина внизу (форма «U»)
for sx, nm in ((1, "R"), (-1, "L")):
    for sz, t in ((1, "A"), (-1, "B")):
        B(f"Arm{t}{nm}", "crust", (2.22*sx, 1.5, 0.42*sz), (0.5, 0.26, 0.26))
        B(f"ArmCap{t}{nm}", "ash", (2.47*sx, 1.5, 0.42*sz), (0.36, 0.36, 0.36))
        B(f"Drop{t}{nm}", "crust", (2.47*sx, 1.06, 0.42*sz), (0.24, 0.6, 0.24))
    B(f"Stirrup{nm}", "lava", (2.47*sx, 0.75, 0), (0.3, 0.3, 1.14))

# ---------- унікальні рухи (GolemAnimator v3.2) ----------
g.free_parts = ("Plume1", "Plume2", "VentBlob_R", "VentBlob_L")   # бризки лави — навмисно вільні
g.fx.append(dict(kind="pulse", parts=["Heart"], amp=0.14, speed=4.0, states={"Run": 1.6, "Mine": 1.8}))   # серце б'ється
g.fx.append(dict(kind="bob", parts=["Plume1"], axis=(0, 1, 0), amp=0.4, speed=3.0, states={"Mine": 1.5}))
g.fx.append(dict(kind="bob", parts=["Plume2"], axis=(0, 1, 0), amp=0.6, speed=3.0, phase=1.3, states={"Mine": 1.5}))
g.fx.append(dict(kind="bob", parts=["VentBlob_R"], axis=(0, 1, 0), amp=0.32, speed=3.6, states={"Run": 1.5}))
g.fx.append(dict(kind="bob", parts=["VentBlob_L"], axis=(0, 1, 0), amp=0.32, speed=3.6, phase=3.14, states={"Run": 1.5}))
POSES_LUA = """ poses={
  -- хода вразвалку: плечі розвертаються за кроком, корпус трохи вперед, руки розмахуються ширше
  Walk=function(p, pose, rot)
   local s = math.sin(p)
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(0.06, 0.12 * s, 0) }
   local uR, uL = pose.UpperArm_R or {}, pose.UpperArm_L or {}
   pose.UpperArm_R = { r = (uR.r or CFrame.identity) * rot(0.12 * s, 0, 0.08) }
   pose.UpperArm_L = { r = (uL.r or CFrame.identity) * rot(-0.12 * s, 0, -0.08) }
   return pose
  end,
  -- біг: сильний нахил уперед, голова дивиться вперед
  Run=function(p, pose, rot)
   pose.Torso = { r = (pose.Torso and pose.Torso.r or CFrame.identity) * rot(0.14, 0, 0) }
   pose.Head = { r = (pose.Head and pose.Head.r or CFrame.identity) * rot(-0.12, 0, 0) }
   return pose
  end,
  -- спокій: «кипить» — голова часто здригається, кулаки стискаються
  Idle=function(p, pose, rot)
   local q = math.sin(3 * p)
   pose.Head = { r = (pose.Head and pose.Head.r or CFrame.identity) * rot(0.03 * q, 0, 0) }
   local fR, fL = pose.Forearm_R or {}, pose.Forearm_L or {}
   pose.Forearm_R = { r = (fR.r or CFrame.identity) * rot(-0.06 * (1 + q) / 2, 0, 0) }
   pose.Forearm_L = { r = (fL.r or CFrame.identity) * rot(-0.06 * (1 + q) / 2, 0, 0) }
   return pose
  end,
  -- носій: тримає тигель вище й відхиляє голову від жару
  Carry=function(p, pose, rot)
   local uR, uL = pose.UpperArm_R or {}, pose.UpperArm_L or {}
   pose.UpperArm_R = { r = (uR.r or CFrame.identity) * rot(-0.12, 0, 0) }
   pose.UpperArm_L = { r = (uL.r or CFrame.identity) * rot(-0.12, 0, 0) }
   pose.Head = { r = (pose.Head and pose.Head.r or CFrame.identity) * rot(-0.1, 0, 0) }
   return pose
  end,
 },
"""

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    out = "/home/claude/magmaheart/MagmaheartGolemData.lua"
    g.export(out, [
        "-- Magmaheart Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано magmaheart_golem_generator.py.",
        "-- Скелет = Clay … Obsidian (21 кістка). neon — лава й розпечене ядро (Neon). fx / poses — унікальні анімації (GolemAnimator v3.2). Box — власний ящик у стадах."])
    s = open(out).read().replace(" bones={", " neon={lava=true,core=true},\n" + POSES_LUA + " bones={", 1); open(out, "w").write(s)
