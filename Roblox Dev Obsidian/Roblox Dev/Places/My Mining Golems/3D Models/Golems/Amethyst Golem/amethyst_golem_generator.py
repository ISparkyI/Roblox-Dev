# Amethyst Golem (Epic): стрімкий кристалічний голем з насиченого фіолетового аметисту на темному базальті.
# Фірмове: кристалічні «крила» на спині (два віяла з довгих кристалів), граньований світний самоцвіт у грудях (Neon),
# тіара з кристалів, кристалічні клинки на передпліччях, гострі поножі. Найшвидший на мапі 1 (x1.4). Скелет Clay.
# Унікальні: кірка-самоцвіт (голова — граньований аметист зі світним ядром, прямий кристалічний шпиль-обух, плавці на держаку),
# меч-крило (аметистове лезо зі світною серцевиною, гарда — віяла кристалів), ящик — аметистова друза (вежі-кристали по кутах).
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(ame="#8e4fd6", basalt="#3b2752", glow="#7a45ff", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4"),
          bones={"Brow_R": (0.9,12.35,2.2014), "Brow_L": (-0.9,12.35,2.2014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
def xtal(name, bone, col, base, h, w, rx=0, rz=0, ry=0, mirror=False, octo=False):
    R = eul(rx=rx, ry=ry, rz=rz); c = tuple(np.array(base) + R[:, 1] * h / 2)
    sfx = "_R" if mirror else ""
    a(name + sfx, bone, col, c, (w, h, w), R, mirror=mirror)
    if octo: a(name + "B" + sfx, bone, col, c, (w*0.84, h*0.92, w*0.84), R @ eul(ry=45), mirror=mirror)
# ---------- ноги: гострі кристалічні поножі ----------
a("Foot_R","Shin_R","basalt",(2.15,0.5,0.15),(3.0,1.0,3.5),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","ame",(2.1,2.2,-0.2),(2.5,2.3,2.5),eul(ry=4),mirror=True)
xtal("Greave","Shin_R","ame",(2.15,1.4,1.0),2.0,0.7,rx=18,mirror=True)
a("Thigh_R","Thigh_R","basalt",(2.0,3.95,-0.25),(2.6,1.7,2.6),eul(ry=-6),mirror=True)
a("Pelvis","Hips","basalt",(0,4.85,-0.35),(5.8,1.6,3.4))
a("Belt","Hips","ame",(0,5.4,-0.35),(6.0,0.45,3.6))
a("BeltGem","Hips","glow",(0,5.4,1.5),(0.6,0.6,0.24),eul(rz=45))
# ---------- корпус: граньований самоцвіт у грудях ----------
a("Torso","Torso","basalt",(0,7.4,-0.3),(6.8,4.0,4.0))
a("Chest","Torso","ame",(0,9.45,-0.4),(7.8,1.8,4.6))
a("ChestPlate_R","Torso","ame",(1.9,7.6,1.75),(2.2,3.2,0.5),eul(rz=-10),mirror=True)
a("GemFrame","Torso","ame",(0,7.5,1.85),(1.9,1.9,0.42),eul(rz=45))
a("Gem","Torso","glow",(0,7.5,2.08),(1.5,1.5,0.3),eul(rz=45))
a("GemB","Torso","glow",(0,7.5,2.02),(1.62,1.62,0.24))
a("GemCore","Torso","light",(0,7.5,2.27),(0.5,0.5,0.14),eul(rz=45))
# ---------- спина: кристалічні крила (віяла) ----------
a("WingRoot","Torso","basalt",(0,8.6,-2.45),(3.2,2.0,0.6))
for i, (h, w, rz) in enumerate([(4.6,0.85,-38),(3.8,0.72,-60),(2.9,0.6,-82)], 1):
    xtal(f"Wing{i}","Torso","ame" if i != 2 else "glow",(0.9,8.6,-2.6),h,w,rz=rz,rx=-14,mirror=True)
# ---------- голова: тіара з кристалів ----------
a("Head","Head","basalt",(0,11.15,0.5014),(3.8,2.7,3.4))
a("Jaw","Head","basalt",(0,10.0,0.7),(3.4,0.8,2.7))
a("Tiara","Head","ame",(0,12.62,0.5),(4.0,0.5,3.6))
xtal("TiaraMid","Head","glow",(0,12.7,1.6),1.8,0.7,rx=8,octo=True)
xtal("TiaraSide","Head","ame",(1.15,12.7,1.2),1.3,0.5,rz=-22,rx=6,mirror=True)
xtal("TiaraBack","Head","ame",(1.3,12.7,-0.6),1.5,0.55,rz=-30,rx=-25,mirror=True)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","glow",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.35,2.24),(1.2,0.3,0.3),eul(rz=-12),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.46,2.3014),(1.1,0.28,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.26,0.5),mirror=True)
# ---------- руки: кристалічні наплічники й клинки на передпліччях ----------
a("Shoulder_R","UpperArm_R","ame",(5.0,9.85,-0.3),(3.2,1.8,3.4),eul(rz=4),mirror=True)
xtal("ShoulderSpike","UpperArm_R","glow",(5.4,10.6,-0.3),1.6,0.6,rz=-28,mirror=True,octo=True)
a("UpperArm_R","UpperArm_R","basalt",(5.25,8.0,-0.3),(2.2,2.6,2.3),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","ame",(5.55,5.75,0.0014),(2.7,2.4,2.8),eul(ry=-6),mirror=True)
xtal("ArmBlade","Forearm_R","ame",(6.85,5.0,0.0),2.4,0.55,rz=-14,rx=-8,mirror=True)
xtal("ArmBlade2","Forearm_R","glow",(6.8,5.6,-0.9),1.4,0.4,rz=-30,rx=-25,mirror=True)
fist = a("Fist_R","Forearm_R","basalt",(5.65,3.45,0.1014),(3.2,2.4,3.2),eul(ry=6.875))
sub(fist,"Knuckles_R","ame",(0.15,0.3,1.62),(2.6,0.8,0.4))
sub(fist,"KnuckleGem_R","glow",(0.15,0.3,1.88),(0.5,0.5,0.2),eul(rz=45))
sub(fist,"Thumb_R","basalt",(-1.7,0.1,0.95),(0.5,1.0,0.9),eul(rz=-6)); mir(4)

# ---------- кірка-самоцвіт ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","basalt"); P("Grip","ame"); P("Band","ame")
PM = P("Pommel","ame",(0.95,0.7,0.95))
sub(PM,"PommelGem","glow",(0,-0.55,0),(0.5,0.5,0.5),eul(rx=45,ry=45))
sub(HN,"FinA","ame",(0.42,2.8,0.05),(0.5,1.3,0.16),eul(rz=-25))
sub(HN,"FinB","ame",(-0.42,2.8,0),(0.5,1.3,0.16),eul(rz=25))
HD = P("Head","ame",(1.6,1.8,1.9))
sub(HD,"HeadFacet","ame",(0,0,0),(1.5,1.6,2.0),eul(ry=45))
sub(HD,"HeadCoreR","glow",(0.93,0,0),(0.14,0.8,0.8),eul(rx=45))
sub(HD,"HeadCoreL","glow",(-0.93,0,0),(0.14,0.8,0.8),eul(rx=45))
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n,"ame")
P("PickGlint","glow")
sub(HD,"SpireA","ame",(0,0,-1.6),(0.9,0.9,1.4))
sub(HD,"SpireB","ame",(0,0,-1.68),(0.78,0.78,1.3),eul(rz=45))
sub(HD,"Spire2","glow",(0,0,-2.55),(0.56,0.56,0.8),eul(rz=22.5))
sub(HD,"Spire3","ame",(0,0,-3.1),(0.3,0.3,0.5),eul(rz=67.5))
# ---------- меч-крило ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordPommel","ame"); S("SwordPommelTop","glow"); S("SwordGrip","basalt")
S("SwordCoil1","ame"); S("SwordCoil2","ame")
G = S("SwordGuard","basalt",(0.8,0.6,2.0))
sub(G,"GuardGem","glow",(0,0.16,0),(0.95,0.8,0.95),eul(ry=45))
for side, nm in ((1,"R"),(-1,"L")):
    sub(G, "WingA"+nm, "ame", (0, 0.55, 1.15*side), (0.5, 1.6, 0.5), eul(rx=38*side))
    sub(G, "WingB"+nm, "glow", (0, 0.2, 1.4*side), (0.4, 1.05, 0.4), eul(rx=62*side))
S("SwordBlade","ame",(0.45,6.6,1.5)); S("SwordEdge","light",(0.3,6.1,1.85)); S("SwordFuller","glow",(0.6,4.6,0.4))
TP = S("SwordTip","ame")
sub(TP,"TipGem","glow",(0,0.25,0),(0.42,0.55,0.42),eul(ry=45))

# ---------- ящик — аметистова друза (у стадах, півот = центр дна; -Z — зовнішній бік) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","basalt",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","basalt",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","basalt",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","basalt",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","basalt",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","basalt",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","ame",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","ame",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","ame",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","ame",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        h = 2.5 if sz < 0 else 2.1
        R = eul(rz=-6*sx, rx=-5*sz)
        base = np.array((1.95*sx, 0.15, 1.12*sz))
        B("Tower" + t, "ame", tuple(base + R[:,1]*h/2), (0.62, h, 0.62), R)
        B("TowerB" + t, "ame", tuple(base + R[:,1]*h/2), (0.52, h*0.94, 0.52), R @ eul(ry=45))
        B("TowerTip" + t, "glow", tuple(base + R[:,1]*(h + 0.12)), (0.36, 0.5, 0.36), R @ eul(ry=22.5))
B("FrontGemFrame","ame",(0,1.0,-1.2),(1.0,1.0,0.2),eul(rz=45))
B("FrontGem","glow",(0,1.0,-1.3),(0.7,0.7,0.14),eul(rz=45))
B("FrontVeinL","glow",(-0.95,0.75,-1.19),(0.9,0.14,0.14),eul(rz=25))
B("FrontVeinR","glow",(0.95,0.75,-1.19),(0.9,0.14,0.14),eul(rz=-25))
for sx, nm in ((1, "R"), (-1, "L")):
    B("HandlePostA"+nm,"basalt",(2.18*sx,1.2,0.4),(0.44,0.2,0.2)); B("HandlePostB"+nm,"basalt",(2.18*sx,1.2,-0.4),(0.44,0.2,0.2))
    B("HandleBar"+nm,"ame",(2.45*sx,1.2,0),(0.22,0.28,1.1))

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    out = "/home/claude/amethyst/AmethystGolemData.lua"
    g.export(out, [
        "-- Amethyst Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано amethyst_golem_generator.py.",
        "-- Скелет = Clay … Geode (21 кістка). neon — кольори з Material = Neon (світний аметист). Pickaxe / Sword — у кулаці Fist_L. Box — власний ящик у стадах."])
    s = open(out).read().replace(" bones={", " neon={glow=true},\n bones={", 1); open(out, "w").write(s)
