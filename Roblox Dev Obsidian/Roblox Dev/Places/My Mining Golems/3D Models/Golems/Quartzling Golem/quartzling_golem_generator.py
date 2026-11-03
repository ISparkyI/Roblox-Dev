# Quartzling Golem (Rare): маленький шустрий голем із сіро-фіолетового каменю, з якого ростуть кристали молочного й рожевого кварцу.
# Унікальні: кристалічна кірка (кварцові леза, друза замість обуха), кристалічний меч (гарда-роги, рожеве ядро), ящик-жеода. Скелет Clay.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(rock="#5e5a6c", quartz="#e9ecf5", rose="#ec94b6", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4"),
          bones={"MouthCorner_R": (0.65,10.58,2.3014), "MouthCorner_L": (-0.65,10.58,2.3014),
                 "Brow_R": (0.9,12.4,2.2014), "Brow_L": (-0.9,12.4,2.2014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
def shard(name, bone, col, base, h, w, rx=0, rz=0, ry=0, mirror=False, group=None):
    R = eul(rx=rx, ry=ry, rz=rz); up = R[:, 1]
    b = a(name, bone, col, tuple(np.array(base) + up * h / 2), (w, h, w), R, group=group, mirror=mirror)
    return b
# ---------- ноги ----------
a("Foot_R","Shin_R","rock",(2.15,0.5,0.15),(3.0,1.0,3.5),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","rock",(2.1,2.2,-0.2),(2.5,2.3,2.5),eul(ry=4),mirror=True)
shard("KneeShard_R","Shin_R","quartz",(2.4,2.9,1.0),1.2,0.55,rx=30,rz=-15,mirror=True)
a("Thigh_R","Thigh_R","rock",(2.0,3.95,-0.25),(2.6,1.7,2.6),eul(ry=-6),mirror=True)
a("Pelvis","Hips","rock",(0,4.85,-0.35),(5.8,1.6,3.4))
a("Belt","Hips","quartz",(0,5.35,-0.35),(6.0,0.4,3.6))
# ---------- корпус: рожеве серце, друза на спині ----------
a("Torso","Torso","rock",(0,7.4,-0.3),(6.8,4.0,4.0))
a("Chest","Torso","rock",(0,9.4,-0.4),(7.6,1.8,4.4))
a("Heart","Torso","rose",(0,7.7,1.75),(1.7,1.7,0.6),eul(rz=45))
a("HeartCore","Torso","quartz",(0,7.7,2.1),(0.75,0.75,0.3),eul(rz=45))
shard("ChestShard_R","Torso","quartz",(1.9,8.9,1.4),1.3,0.55,rx=35,rz=-25,mirror=True)
shard("BackShard1","Torso","quartz",(0,8.6,-2.1),3.6,1.15,rx=-28)
shard("BackShard2_R","Torso","rose",(1.5,8.3,-2.1),2.7,0.9,rx=-22,rz=-28,mirror=True)
shard("BackShard3_R","Torso","quartz",(2.4,6.9,-2.1),1.6,0.65,rx=-35,rz=-45,mirror=True)
shard("BackShard4","Torso","rose",(-0.4,6.5,-2.1),1.5,0.7,rx=-60,rz=15)
# ---------- голова: кристалічна корона ----------
a("Head","Head","rock",(0,11.15,0.5014),(3.8,2.7,3.4))
a("Jaw","Head","rock",(0,10.0,0.7),(3.4,0.8,2.7))
a("HeadTop","Head","rock",(0,12.65,0.35),(3.3,0.5,2.8))
shard("Crown1","Head","quartz",(0,12.7,0.2),2.1,0.85,rx=-8)
shard("Crown2_R","Head","rose",(1.0,12.7,0.0),1.4,0.62,rx=-5,rz=-28,mirror=True)
shard("Crown3_R","Head","quartz",(0.6,12.7,-0.9),1.0,0.5,rx=-30,rz=-18,mirror=True)
shard("TempleShard_R","Head","quartz",(1.85,11.6,-0.2),0.9,0.45,rz=-70,rx=-10,mirror=True)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","light",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.4,2.24),(1.2,0.3,0.3),eul(rz=10),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.46,2.3014),(1.1,0.28,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.58,2.3014),(0.3,0.3,0.5),mirror=True)
# ---------- руки ----------
a("Shoulder_R","UpperArm_R","rock",(5.0,9.85,-0.3),(3.1,1.8,3.2),eul(rz=4),mirror=True)
shard("ShoulderShard_R","UpperArm_R","quartz",(5.3,10.6,-0.6),2.0,0.85,rz=-30,rx=-10,mirror=True)
shard("ShoulderShard2_R","UpperArm_R","rose",(4.5,10.6,0.5),1.3,0.6,rz=-12,rx=20,mirror=True)
a("UpperArm_R","UpperArm_R","rock",(5.25,8.0,-0.3),(2.2,2.6,2.3),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","rock",(5.55,5.75,0.0014),(2.6,2.4,2.7),eul(ry=-6),mirror=True)
a("Bracer_R","Forearm_R","quartz",(5.55,6.45,0.0014),(2.8,0.4,2.9),eul(ry=-6),mirror=True)
shard("ElbowShard_R","Forearm_R","rose",(6.6,6.0,-0.6),1.0,0.45,rz=-55,rx=-20,mirror=True)
fist = a("Fist_R","Forearm_R","rock",(5.65,3.45,0.1014),(3.1,2.4,3.1),eul(ry=6.875))
sub(fist,"Knuckles_R","quartz",(0.15,0.3,1.57),(2.5,0.8,0.4))
sub(fist,"Thumb_R","rock",(-1.65,0.1,0.9),(0.5,1.0,0.9),eul(rz=-6)); mir(3)

# ---------- кристалічна кірка: кварцові леза, друза замість обуха ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
P("Handle","rock"); P("Grip","rose"); P("Band","quartz")
PM = P("Pommel","rose",(0.9,0.7,0.9))
sub(PM,"PommelShard","quartz",(0,-0.7,0),(0.45,0.8,0.45),eul(ry=45))
HD = P("Head","rock",(1.5,1.7,1.9))
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n,"quartz")
P("PickGlint","rose")
sub(HD,"Druse1","quartz",(0,0.25,-1.45),(0.75,0.75,1.5),eul(rx=-22))
sub(HD,"Druse2","rose",(0.42,-0.35,-1.25),(0.55,0.55,1.15),eul(rx=18,ry=18))
sub(HD,"Druse3","rose",(-0.42,-0.3,-1.2),(0.5,0.5,1.0),eul(rx=15,ry=-20))
sub(HD,"HeadBand","quartz",(0,0,0.55),(1.65,1.85,0.3))
# ---------- кристалічний меч: гарда-роги, рожеве ядро, кварцове лезо ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
SP = S("SwordPommel","rose"); S("SwordPommelTop","quartz"); S("SwordGrip","rock")
S("SwordCoil1","quartz"); S("SwordCoil2","quartz")
G = S("SwordGuard","rock",(0.85,0.7,2.4))
sub(G,"GuardCore","rose",(0,0,0),(1.05,0.95,0.95),eul(ry=45))
sub(G,"GuardHornR","quartz",(0,0.75,1.35),(0.5,1.6,0.5),eul(rx=32))
sub(G,"GuardHornL","quartz",(0,0.75,-1.35),(0.5,1.6,0.5),eul(rx=-32))
S("SwordBlade","quartz",(0.45,6.6,1.5)); S("SwordEdge","light",(0.3,6.1,1.85)); S("SwordFuller","rose",(0.6,4.2,0.32))
TP = S("SwordTip","quartz")
sub(TP,"TipGem","rose",(0,0.1,0),(0.42,0.6,0.42),eul(ry=45))

# ---------- ящик-жеода (у стадах, півот = центр дна; -Z — зовнішній бік у руках носія) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
def BS(name, col, base, h, w, rx=0, rz=0, ry=0):
    R = eul(rx=rx, ry=ry, rz=rz); return B(name, col, tuple(np.array(base) + R[:, 1] * h / 2), (w, h, w), R)
B("Bottom","rock",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","rock",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","rock",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","rock",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","rock",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","rock",(-1.85,0.98,0),(0.3,1.7,1.66))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Corner" + t, "rock", (2.0*sx, 0.95, 1.05*sz), (0.72, 1.9, 0.72), eul(ry=12*sx*sz))
BS("Crystal1","quartz",(-1.95,1.8,-1.05),1.5,0.55,rx=-15,rz=20)
BS("Crystal2","quartz",(2.0,1.8,-1.05),1.25,0.5,rx=-18,rz=-22)
BS("Crystal3","rose",(-0.75,1.75,-1.0),1.1,0.5,rx=-22,rz=8)
BS("Crystal4","quartz",(0.55,1.75,-1.0),0.85,0.42,rx=-25,rz=-12)
BS("Crystal5","rose",(2.0,1.8,1.05),0.95,0.45,rx=18,rz=-25)
BS("Crystal6","rose",(-2.0,1.8,1.05),0.8,0.42,rx=20,rz=22)
BS("Crystal7","quartz",(0.1,1.75,1.0),0.7,0.38,rx=25,rz=10)
B("GeodeRim","quartz",(0,1.02,-1.2),(1.5,1.1,0.16),eul(rz=0))
B("GeodeHeart","rose",(0,1.02,-1.27),(0.75,0.75,0.12),eul(rz=45))
BS("FrontShard1","quartz",(0.62,0.85,-1.21),0.75,0.22,rz=-38)
BS("FrontShard2","quartz",(-0.62,0.85,-1.21),0.7,0.22,rz=38)
BS("FrontShard3","rose",(-1.3,0.4,-1.2),0.55,0.2,rz=25)
B("LugR","quartz",(2.47,1.1,0),(0.42,0.5,0.9),eul(rz=-14)); B("LugL","quartz",(-2.47,1.1,0),(0.42,0.5,0.9),eul(rz=14))
B("Vein1","quartz",(-0.9,0.7,1.19),(0.9,0.14,0.14),eul(rz=14))
B("Vein2","rose",(1.0,1.15,1.19),(0.7,0.14,0.14),eul(rz=-10))

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    g.export("/home/claude/quartzling/QuartzlingGolemData.lua", [
        "-- Quartzling Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано quartzling_golem_generator.py.",
        "-- Скелет = Clay … Ironclad (21 кістка). Pickaxe / Sword — у кулаці Fist_L. Box — власний ящик-жеода в стадах (півот = центр дна)."])
