# Geode Golem (Epic): розколота жеода, що ходить — шорстка буро-сіра кам'яна шкаралупа, кремові смуги агату
# й світні бірюзові кристали (Neon) у розколах: груди, маківка, спина, плечі, кулаки. Скелет Clay.
# Унікальні: кірка-жеода (голова — половинка жеоди, кристалічні леза, великий восьмигранний кристал замість обуха),
# меч-агат (шаруване лезо зі світною кромкою, гарда — розколота жеода з кристалами), ящик — розколота жеода.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(shell="#6b6158", agate="#e8d9c4", crystal="#3fd6e0", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4"),
          bones={"MouthCorner_R": (0.65,10.6,2.3014), "MouthCorner_L": (-0.65,10.6,2.3014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
def xtal(name, bone, base, h, w, rx=0, rz=0, ry=0, col="crystal", mirror=False, group=None, single=False):
    """кристал: восьмигранна призма з двох квадратних, повернутих на 45° навколо осі (різна ширина — грані не збігаються)"""
    R = eul(rx=rx, ry=ry, rz=rz); up = R[:, 1]; c = tuple(np.array(base) + up * h / 2)
    a(name + "A" + ("_R" if mirror else ""), bone, col, c, (w, h, w), R, group=group, mirror=mirror)
    if not single: a(name + "B" + ("_R" if mirror else ""), bone, col, c, (w * 0.86, h * 0.9, w * 0.86), R @ eul(ry=45), group=group, mirror=mirror)
# ---------- ноги ----------
a("Foot_R","Shin_R","shell",(2.2,0.55,0.2),(3.2,1.1,3.7),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","shell",(2.15,2.3,-0.2),(2.7,2.3,2.7),eul(ry=4),mirror=True)
a("ShinBand_R","Shin_R","agate",(2.15,2.9,-0.2),(2.86,0.36,2.86),eul(ry=4),mirror=True)
a("Thigh_R","Thigh_R","shell",(2.0,4.0,-0.25),(2.8,1.7,2.8),eul(ry=-6),mirror=True)
xtal("KneeXtal","Shin_R",(2.5,2.9,1.2),1.0,0.45,rx=40,rz=-20,mirror=True,single=True)
a("Pelvis","Hips","shell",(0,4.85,-0.3),(6.2,1.6,3.5))
a("Belt","Hips","agate",(0,5.45,-0.3),(6.6,0.45,3.9))
# ---------- корпус: шкаралупа, розколота спереду ----------
a("Torso","Torso","shell",(0,7.4,-0.6),(7.0,4.0,3.4))
a("Chest","Torso","shell",(0,9.6,-0.35),(8.6,1.6,4.7))
a("ShellHalf_R","Torso","shell",(2.35,7.3,1.4),(2.5,4.1,0.9),eul(ry=-8),mirror=True)
a("Lining","Torso","agate",(0,7.4,1.22),(2.6,3.6,0.4))
a("LiningEdge_R","Torso","agate",(1.12,7.3,1.75),(0.3,3.9,0.5),eul(ry=-8),mirror=True)
for i, (x, y, h, w, rx, rz) in enumerate([(0,7.4,1.9,0.95,62,0),(-0.6,8.4,1.45,0.7,55,18),(0.62,8.3,1.35,0.66,58,-20),
                                           (-0.55,6.25,1.3,0.62,70,25),(0.6,6.35,1.5,0.7,68,-15)], 1):
    xtal(f"Core{i}","Torso",(x,y,1.35),h,w,rx=rx,rz=rz,single=i > 1)
# спина: розлам із кристалами
a("BackCrack","Torso","agate",(0,7.7,-2.35),(1.8,3.0,0.3))
xtal("BackXtal1","Torso",(0,8.4,-2.3),2.4,0.9,rx=-50)
xtal("BackXtal2","Torso",(0.55,7.3,-2.3),1.7,0.7,rx=-45,rz=-30,single=True)
xtal("BackXtal3","Torso",(-0.55,7.0,-2.3),1.5,0.6,rx=-55,rz=28,single=True)
# ---------- голова: розколота маківка з кристалами ----------
a("Head","Head","shell",(0,11.15,0.5014),(4.0,2.7,3.4))
a("Jaw","Head","shell",(0,9.95,0.7),(3.4,0.8,2.7))
a("RimF","Head","shell",(0,12.78,1.75),(4.2,0.7,0.6))
a("RimB","Head","shell",(0,12.85,-0.85),(4.2,0.8,0.6))
a("Rim_R","Head","shell",(1.85,12.8,0.45),(0.55,0.75,1.9),mirror=True)
a("HeadLining","Head","agate",(0,12.65,0.45),(3.2,0.35,1.8))
xtal("Crown1","Head",(0,12.7,0.45),1.9,0.8,rx=-6)
xtal("Crown2","Head",(0.75,12.7,0.2),1.3,0.55,rz=-25,rx=-10,single=True)
xtal("Crown3","Head",(-0.8,12.7,0.65),1.1,0.5,rz=22,rx=8,single=True)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","crystal",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.3,2.25),(1.2,0.3,0.3),eul(rz=8),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.46,2.3014),(1.1,0.28,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.26,0.5),mirror=True)
# ---------- руки: плечі — половинки жеоди зрізом назовні; кристалічні кастети ----------
a("Shoulder_R","UpperArm_R","shell",(5.0,9.85,-0.3),(3.4,1.9,3.6),eul(rz=3),mirror=True)
a("ShoulderCap_R","UpperArm_R","shell",(4.9,10.95,-0.3),(3.0,0.5,3.2),eul(rz=3),mirror=True)
a("ShoulderCut_R","UpperArm_R","agate",(6.72,9.9,-0.3),(0.3,1.6,3.0),eul(rz=3),mirror=True)
xtal("ShoulderXtal1","UpperArm_R",(6.75,10.1,-0.6),1.2,0.6,rz=-75,mirror=True,single=True)
xtal("ShoulderXtal2","UpperArm_R",(6.75,9.6,0.4),0.9,0.45,rz=-100,rx=15,mirror=True,single=True)
a("UpperArm_R","UpperArm_R","shell",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","shell",(5.55,5.75,0.0014),(2.9,2.4,3.0),eul(ry=-6),mirror=True)
a("Bracer_R","Forearm_R","agate",(5.55,6.55,0.0014),(3.1,0.4,3.2),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","shell",(5.65,3.45,0.1014),(3.4,2.6,3.4),eul(ry=6.875))
sub(fist,"Knuckles_R","agate",(0.15,0.3,1.75),(2.8,0.9,0.4))
for i, x in enumerate((-0.8, 0.15, 1.1), 1):
    sub(fist, f"KnuckleXtal{i}_R", "crystal", (x, 0.35, 2.1), (0.42, 0.42, 0.6), eul(rz=45))
sub(fist,"Thumb_R","shell",(-1.8,0.1,1.0),(0.5,1.1,0.9),eul(rz=-6)); mir(6)

# ---------- кірка-жеода ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
P("Handle","shell"); P("Grip","agate"); P("Band","agate")
PM = P("Pommel","shell",(0.95,0.7,0.95))
sub(PM,"PommelCore","crystal",(0,-0.38,0),(0.5,0.2,0.5),eul(ry=45))
HD = P("Head","shell",(1.5,1.7,1.9))
sub(HD,"HeadCutR","agate",(0.8,0,0),(0.16,1.4,1.6))
sub(HD,"HeadCutL","agate",(-0.8,0,0),(0.16,1.4,1.6))
sub(HD,"HeadCoreR","crystal",(0.9,0,0),(0.12,0.9,1.0),eul(rx=45))
sub(HD,"HeadCoreL","crystal",(-0.9,0,0),(0.12,0.9,1.0),eul(rx=45))
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n,"crystal")
P("PickGlint","light")
sub(HD,"SpireCollar","agate",(0,0,-1.12),(1.1,1.1,0.4))
sub(HD,"SpireA","crystal",(0,0,-2.0),(0.82,0.82,1.6))
sub(HD,"SpireB","crystal",(0,0,-1.98),(0.72,0.72,1.5),eul(rz=45))
sub(HD,"SpireTip","crystal",(0,0,-2.9),(0.42,0.42,0.42),eul(rx=45,ry=45))
# ---------- меч-агат ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
SP = S("SwordPommel","shell"); S("SwordPommelTop","crystal"); S("SwordGrip","shell")
S("SwordCoil1","agate"); S("SwordCoil2","agate")
G = S("SwordGuard","shell",(1.0,0.8,2.4))
sub(G,"GuardLining","agate",(0,0.36,0),(0.7,0.2,1.9))
for i, z in enumerate((0.92, -0.92), 1):
    sub(G, f"GuardXtal{i}", "crystal", (0, 0.62, z), (0.42, 0.95, 0.42), eul(ry=45))
S("SwordBlade","shell",(0.45,6.6,1.5)); S("SwordEdge","crystal",(0.3,6.1,1.85)); S("SwordFuller","agate",(0.6,4.4,0.34))
TP = S("SwordTip","crystal")

# ---------- ящик — розколота жеода (у стадах, півот = центр дна; -Z — зовнішній бік) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
def BX(name, base, h, w, rx=0, rz=0):
    R = eul(rx=rx, rz=rz); c = tuple(np.array(base) + R[:, 1] * h / 2)
    B(name + "A", "crystal", c, (w, h, w), R); B(name + "B", "crystal", c, (w*0.86, h*0.9, w*0.86), R @ eul(ry=45))
B("Bottom","shell",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","shell",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","shell",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","shell",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","shell",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","shell",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","agate",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","agate",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","agate",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","agate",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Chunk" + t, "shell", (1.9*sx, 0.95, 1.08*sz), (0.62, 1.7, 0.62), eul(ry=20*sx*sz))
BX("RimXtal1",(-1.1,2.0,-1.05),0.8,0.36,rx=-15,rz=10)
BX("RimXtal2",(0.3,2.0,-1.05),0.65,0.32,rx=-18,rz=-8)
BX("RimXtal3",(1.3,2.0,-1.05),0.5,0.28,rx=-12,rz=-14)
BX("RimXtal4",(-0.4,2.0,1.05),0.5,0.28,rx=15,rz=8)
B("CrackA","crystal",(-0.7,1.25,-1.18),(1.0,0.16,0.14),eul(rz=-25))
B("CrackB","crystal",(0.15,0.98,-1.18),(0.9,0.16,0.14),eul(rz=20))
B("CrackC","crystal",(0.9,1.2,-1.18),(0.8,0.16,0.14),eul(rz=-30))
B("AgateBand","agate",(0,0.5,-1.2),(3.0,0.22,0.2))
for sx, nm in ((1, "R"), (-1, "L")):
    B("HandlePostA"+nm,"shell",(2.18*sx,1.2,0.35),(0.44,0.2,0.2)); B("HandlePostB"+nm,"shell",(2.18*sx,1.2,-0.35),(0.44,0.2,0.2))
    B("HandleBar"+nm,"agate",(2.45*sx,1.2,0),(0.22,0.28,1.0))

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    out = "/home/claude/geode/GeodeGolemData.lua"
    g.export(out, [
        "-- Geode Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано geode_golem_generator.py.",
        "-- Скелет = Clay … Silverjaw (21 кістка). neon — кольори з Material = Neon (кристали). Pickaxe / Sword — у кулаці Fist_L. Box — власний ящик у стадах."])
    s = open(out).read().replace(" bones={", " neon={crystal=true},\n bones={", 1); open(out, "w").write(s)
