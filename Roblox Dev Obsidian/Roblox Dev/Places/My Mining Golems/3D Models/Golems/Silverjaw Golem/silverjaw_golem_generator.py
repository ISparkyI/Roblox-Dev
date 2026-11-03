# Silverjaw Golem (Rare): сланцевий громило з величезною сріблястою щелепою-капканом та іклами, срібні жили й пластини.
# Унікальні: кірка-ікло (зубчасте лезо, велике ікло замість обуха), меч-щелепа (гарда — розкрита паща з іклами, зубчаста кромка),
# ящик-паща (ряди іклів по краях, однакові срібні ручки). Скелет Clay.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(slate="#3d4456", silver="#b4bdca", steel="#7c8696", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4"),
          bones={"Mouth": (0,10.62,2.3014), "MouthCorner_R": (0.65,10.58,2.3014), "MouthCorner_L": (-0.65,10.58,2.3014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
# ---------- ноги ----------
a("Foot_R","Shin_R","slate",(2.2,0.55,0.2),(3.2,1.1,3.7),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","slate",(2.15,2.3,-0.2),(2.7,2.3,2.7),eul(ry=4),mirror=True)
a("ShinPlate_R","Shin_R","silver",(2.2,2.35,1.2),(1.9,1.7,0.4),eul(ry=4),mirror=True)
a("Thigh_R","Thigh_R","slate",(2.0,4.0,-0.25),(2.8,1.7,2.8),eul(ry=-6),mirror=True)
a("Pelvis","Hips","steel",(0,4.85,-0.3),(6.2,1.6,3.5))
a("Belt","Hips","silver",(0,5.45,-0.3),(6.6,0.5,3.9))
# ---------- корпус: срібні жили й самородки, «грива» з пластин на спині ----------
a("Torso","Torso","slate",(0,7.5,-0.3),(7.4,4.2,4.2))
a("Chest","Torso","slate",(0,9.6,-0.35),(8.6,1.6,4.7))
a("Vein1","Torso","silver",(-1.2,7.6,1.85),(3.6,0.45,0.3),eul(rz=32))
a("Vein2","Torso","silver",(1.5,6.6,1.85),(2.2,0.4,0.3),eul(rz=-24))
a("Nugget1","Torso","silver",(1.6,8.4,1.95),(1.0,0.9,0.55),eul(rz=12))
a("Nugget2","Torso","steel",(-2.4,6.3,2.0),(0.8,0.7,0.5),eul(rz=-18))
for i, (y, z, w) in enumerate([(10.2,-2.4,1.6),(9.0,-2.75,1.4),(7.6,-2.85,1.2)], 1):
    a(f"Mane{i}","Torso","silver",(0,y,z),(w,1.1,0.9),eul(rx=-30 - 6*i))
a("BackPlate","Torso","steel",(0,7.2,-2.45),(4.2,3.0,0.3))
# ---------- голова: величезна срібна щелепа з іклами ----------
a("Head","Head","slate",(0,11.15,0.5014),(4.0,2.7,3.4))
a("Crown","Head","silver",(0,12.72,0.38),(4.3,0.5,3.6))
a("CrownRidge","Head","steel",(0,13.1,0.2),(0.8,0.4,3.0))
a("Jaw","Head","silver",(0,9.85,0.95),(4.6,1.0,3.4))
a("JawChin","Head","steel",(0,9.5,2.4),(3.2,0.5,0.6))
a("Fang_R","Head","light",(1.05,10.52,2.5),(0.36,0.42,0.36),mirror=True)
a("FangOuter_R","Head","light",(2.0,10.55,2.25),(0.32,0.5,0.32),mirror=True)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","light",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.25,2.25),(1.3,0.32,0.3),eul(rz=-10),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.85,2.2764),(0.525,0.24,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.62,2.3014),(1.1,0.24,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.58,2.3014),(0.3,0.26,0.5),mirror=True)
# ---------- руки: срібні наплічники з шипами, срібні кастети ----------
a("Shoulder_R","UpperArm_R","slate",(5.0,9.85,-0.3),(3.4,1.9,3.6),eul(rz=3),mirror=True)
a("Pauldron_R","UpperArm_R","silver",(5.15,10.95,-0.3),(3.6,0.45,3.8),eul(rz=3),mirror=True)
a("Spike1_R","UpperArm_R","steel",(5.6,11.45,0.5),(0.55,0.8,0.55),eul(rz=-20,ry=45),mirror=True)
a("Spike2_R","UpperArm_R","steel",(5.4,11.45,-1.1),(0.5,0.7,0.5),eul(rz=-25,ry=45),mirror=True)
a("UpperArm_R","UpperArm_R","steel",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","slate",(5.55,5.75,0.0014),(2.9,2.4,3.0),eul(ry=-6),mirror=True)
a("Bracer_R","Forearm_R","silver",(5.55,6.55,0.0014),(3.1,0.4,3.2),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","slate",(5.65,3.45,0.1014),(3.6,2.7,3.6),eul(ry=6.875))
sub(fist,"Knuckles_R","silver",(0.15,0.3,1.85),(3.0,1.0,0.45))
sub(fist,"KnuckleSpike_R","light",(0.15,0.3,2.2),(0.4,0.4,0.4),eul(rz=45))
sub(fist,"Thumb_R","slate",(-1.9,0.1,1.05),(0.5,1.1,0.9),eul(rz=-6)); mir(4)

# ---------- кірка (v2): зубчасте лезо, срібні «брови», шипастий молот замість обуха ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","slate"); P("Grip","steel"); P("Band","silver")
PM = P("Pommel","silver")
sub(PM,"PommelSpike","light",(0,-0.55,0),(0.42,0.6,0.42),eul(ry=45))
sub(HN,"Collar","silver",(0,3.35,0),(0.95,0.35,0.95))
sub(HN,"CollarSpikeA","light",(0.55,3.35,0),(0.36,0.3,0.36),eul(ry=45))
sub(HN,"CollarSpikeB","light",(-0.55,3.35,0),(0.36,0.3,0.36),eul(ry=45))
HD = P("Head","steel",(1.5,1.7,1.9))
sub(HD,"BrowR","silver",(0.84,0.15,-0.1),(0.24,1.2,1.5))
sub(HD,"BrowL","silver",(-0.84,0.15,-0.1),(0.24,1.2,1.5))
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n,"silver")
P("PickGlint","light")
for n in ("Pick1","Pick2","Pick3"):   # зубці по внутрішньому (увігнутому) краю леза, врізані в лезо
    pos, R, sz = PICK[n]
    g.item(n + "Tooth", "Pickaxe", "light", tuple(np.array(pos) + R @ np.array([0, -sz[1]/2, 0])), R @ eul(rx=45), (sz[0]*0.55, 0.34, 0.34))
sub(HD,"HammerCore","silver",(0,0,-1.35),(1.36,1.36,1.1))
sub(HD,"HammerCap","steel",(0,0,-2.0),(1.6,1.6,0.3))
sub(HD,"SpikeTop","light",(0,0,-2.42),(0.5,0.5,0.75),eul(rz=45))
sub(HD,"SpikeFwd","light",(0,1.02,-1.35),(0.42,0.62,0.42),eul(ry=45))
sub(HD,"SpikeBack","light",(0,-1.02,-1.35),(0.42,0.62,0.42),eul(ry=45))
sub(HD,"SpikeSideR","light",(1.02,0,-1.35),(0.62,0.42,0.42),eul(rx=45))
sub(HD,"SpikeSideL","light",(-1.02,0,-1.35),(0.62,0.42,0.42),eul(rx=45))
# ---------- меч-щелепа (v2): суцільна гарда з іклами, зубчаста кромка врізана в лезо ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordPommel","steel"); S("SwordPommelTop","silver"); S("SwordGrip","slate")
S("SwordCoil1","silver"); S("SwordCoil2","silver")
G = S("SwordGuard","steel",(0.8,0.6,2.6))
sub(G,"GuardJaw","silver",(0,0.42,0),(0.9,0.36,2.2))
for i, z in enumerate((-1.0, 1.0), 1):
    sub(G, f"GuardFang{i}", "light", (0, 0.72, z), (0.4, 0.46, 0.3))
sub(G,"QuillonR","silver",(0,0.25,1.45),(0.6,0.9,0.5),eul(rx=25))
sub(G,"QuillonL","silver",(0,0.25,-1.45),(0.6,0.9,0.5),eul(rx=-25))
BL = S("SwordBlade","silver",(0.45,6.6,1.5)); S("SwordEdge","light",(0.3,6.1,1.85)); S("SwordFuller","steel",(0.6,4.2,0.32))
for i, y in enumerate((-2.2, -1.1, 0.0, 1.1, 2.2), 1):
    sub(BL, f"Serr{i}", "light", (0, y, 0.93), (0.26, 0.4, 0.4), eul(rx=45))
S("SwordTip","silver")

# ---------- ящик-паща (у стадах, півот = центр дна; -Z — зовнішній бік у руках носія) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","steel",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","steel",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","slate",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","slate",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","slate",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","slate",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","silver",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","silver",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","silver",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","silver",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Corner" + t, "steel", (1.87*sx, 1.035, 1.13*sz), (0.5, 1.67, 0.5))
for i, x in enumerate((-1.2, -0.4, 0.4, 1.2), 1):   # ікла на краях
    B(f"FangB{i}", "light", (x, 2.18, -1.08), (0.3, 0.4, 0.3), eul(ry=45))
    B(f"FangF{i}", "light", (x + 0.4 if i < 4 else x - 0.4 + 0.0, 2.15, 1.08), (0.26, 0.34, 0.26), eul(ry=45)) if i < 4 else None
B("JawPlate","silver",(0,0.75,-1.2),(2.6,0.5,0.2))
B("VeinOut","silver",(-0.9,1.35,-1.2),(1.2,0.18,0.18),eul(rz=18))
B("Nug","steel",(1.1,1.3,-1.26),(0.4,0.35,0.26),eul(rz=20))
for sx, nm in ((1, "R"), (-1, "L")):   # однакові срібні ручки
    B("HandlePostA"+nm,"silver",(2.18*sx,1.2,0.35),(0.44,0.18,0.18)); B("HandlePostB"+nm,"silver",(2.18*sx,1.2,-0.35),(0.44,0.18,0.18))
    B("HandleBar"+nm,"silver",(2.45*sx,1.2,0),(0.2,0.26,1.0))

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    g.export("/home/claude/silverjaw/SilverjawGolemData.lua", [
        "-- Silverjaw Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано silverjaw_golem_generator.py.",
        "-- Скелет = Clay … Tinker (21 кістка). Pickaxe / Sword — у кулаці Fist_L. Box — власний ящик-паща в стадах (півот = центр дна)."])
