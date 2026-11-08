# Lodestone Golem (Rare, рол 1 до 2000, між Quartzling і Tinker): голем-магніт.
# Темне залізо й сталь, на грудях підкова-магніт (червоний і синій полюси зі сталевими наконечниками), до плечей і кулаків
# «прилипли» шматочки руди. Анімації стандартні (рівень Rare). Кірка й меч — шаблон із магнітними смугами;
# ящик — залізна скринька з підковою-магнітом і однаковими ручками-підковками. Скелет Clay.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(iron="#4a525c", ironDark="#2c3138", steel="#aab3bd", red="#c8443c", blue="#3f6fc4", ore="#8a6a4a",
               oreDark="#5e4630", light="#fff4e6", dark="#1c2836", pink="#f2a0b4"),
          bones={"Mouth": (0,10.5,2.3014), "MouthCorner_R": (0.65,10.6,2.3014), "MouthCorner_L": (-0.65,10.6,2.3014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))

# ---------- ноги ----------
a("Foot_R","Shin_R","ironDark",(2.2,0.55,0.2),(3.2,1.1,3.7),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","iron",(2.15,2.2,-0.2),(2.7,2.3,2.7),eul(ry=4),mirror=True)
a("ShinPlate_R","Shin_R","steel",(2.15,2.35,1.2),(2.0,1.2,0.3),eul(ry=4),mirror=True)
a("Thigh_R","Thigh_R","ironDark",(2.0,4.0,-0.25),(2.8,1.7,2.8),eul(ry=-6),mirror=True)
a("Pelvis","Hips","ironDark",(0,4.85,-0.3),(6.2,1.6,3.5))
a("Belt","Hips","steel",(0,5.45,-0.3),(6.6,0.5,3.9))
# ---------- корпус: підкова-магніт на грудях ----------
a("Torso","Torso","iron",(0,7.5,-0.3),(7.4,4.2,4.2))
a("Chest","Torso","iron",(0,9.6,-0.35),(8.6,1.6,4.7))
a("ChestBand","Torso","ironDark",(0,8.65,-0.3),(7.6,0.4,4.4))
a("MagBase","Torso","steel",(0,6.35,1.9),(2.4,0.75,0.3))       # дуга підкови (знизу)
a("MagLegR","Torso","red",(0.95,7.25,1.95),(0.7,1.6,0.32))           # червоний полюс
a("MagLegL","Torso","blue",(-0.95,7.25,1.95),(0.7,1.6,0.32))         # синій полюс
a("MagTipR","Torso","steel",(0.95,8.27,1.95),(0.74,0.45,0.36))
a("MagTipL","Torso","steel",(-0.95,8.27,1.95),(0.74,0.45,0.36))
a("BackPlate","Torso","ironDark",(0,7.6,-2.45),(4.4,3.2,0.3))
a("BackRivetR","Torso","steel",(1.6,8.8,-2.62),(0.4,0.4,0.2)); a("BackRivetL","Torso","steel",(-1.6,8.8,-2.62),(0.4,0.4,0.2))
# ---------- голова: сталевий шолом-козирок ----------
a("Head","Head","iron",(0,11.15,0.5014),(4.0,2.7,3.4))
a("Crown","Head","ironDark",(0,12.72,0.38),(4.3,0.5,3.6))
a("Visor","Head","steel",(0,12.38,0.5),(4.2,0.4,3.6))
a("CrestR","Head","red",(0.55,13.2,0.3),(0.9,0.45,1.4))       # маківка: червона й синя половинки
a("CrestL","Head","blue",(-0.55,13.2,0.3),(0.9,0.45,1.4))
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","light",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.06,2.25),(1.2,0.26,0.3),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.24,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.5,2.3014),(1.1,0.24,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.22,0.5),mirror=True)
# ---------- руки: наплічники (правий червоний, лівий синій), прилиплі шматочки руди ----------
a("Shoulder_R","UpperArm_R","iron",(5.0,9.85,-0.3),(3.4,1.9,3.6),eul(rz=3),mirror=True)
a("Pauldron_R","UpperArm_R","red",(5.15,10.95,-0.3),(3.6,0.45,3.8),eul(rz=3))
a("Pauldron_L","UpperArm_L","blue",(-5.15,10.95,-0.3),(3.6,0.45,3.8),eul(rz=-3))
a("OreA_R","UpperArm_R","ore",(5.6,11.45,0.4),(0.7,0.6,0.7),eul(ry=20),mirror=True)
a("OreB_R","UpperArm_R","oreDark",(4.7,11.35,-0.9),(0.55,0.4,0.55),eul(ry=-15),mirror=True)
a("UpperArm_R","UpperArm_R","ironDark",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","iron",(5.55,5.75,0.0014),(2.9,2.4,3.0),eul(ry=-6),mirror=True)
a("Bracer_R","Forearm_R","steel",(5.55,6.55,0.0014),(3.1,0.4,3.2),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","iron",(5.65,3.45,0.1014),(3.6,2.7,3.6),eul(ry=6.875))
sub(fist,"Knuckles_R","steel",(0.15,0.3,1.85),(3.0,1.0,0.45))
sub(fist,"KnuckleOre_R","ore",(1.95,-0.4,0.6),(0.4,0.55,0.55))
sub(fist,"Thumb_R","iron",(-1.9,0.1,1.05),(0.5,1.1,0.9),eul(rz=-6)); mir(4)

# ---------- кірка v2: обух — підкова-магніт; голова червоно-синя ----------
OCTA = eul(rx=35.264) @ eul(rz=45)
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","ironDark"); P("Grip","oreDark"); P("Band","steel")
PM = P("Pommel","steel")
sub(PM,"PommelOre","ore",(0,-0.5,0),(0.5,0.5,0.5),OCTA)
sub(HN,"RingRed","red",(0,1.6,0),(0.82,0.28,0.82))
sub(HN,"RingBlue","blue",(0,2.6,0),(0.82,0.28,0.82))
HD = P("Head","iron"); P("HeadRound","steel")
for n in ("Pick1","Pick2","Pick3"): P(n,"steel")
P("Pick4","light"); P("PickGlint","light")
sub(g.blocks[[b["name"] for b in g.blocks].index("Pick1")],"Pick1Band","red",(0,0.2,0),(1.16,0.3,1.96))
sub(HD,"HeadSideR","red",(0.86,0,0.1),(0.16,1.3,1.5)); sub(HD,"HeadSideL","blue",(-0.86,0,0.1),(0.16,1.3,1.5))
for sx, nm in ((1,"R"),(-1,"L")):
    for i, y in enumerate((0.42,-0.42)):
        sub(HD,f"HeadRivet{nm}{i}","steel",(0.97*sx,y,0.55),(0.12,0.28,0.28))
sub(HD,"MagArc","steel",(0,0,-1.2),(1.2,2.0,0.5))
sub(HD,"MagLegR","red",(0,0.66,-1.9),(0.96,0.56,1.0)); sub(HD,"MagLegL","blue",(0,-0.66,-1.9),(0.96,0.56,1.0))
sub(HD,"MagTipR","steel",(0,0.66,-2.52),(1.08,0.66,0.34)); sub(HD,"MagTipL","steel",(0,-0.66,-2.52),(1.08,0.66,0.34))
# ---------- меч v2: гарда — підкова (червоне й синє плече обіймають клинок), дол із двох полюсів ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
SP = S("SwordPommel","steel"); S("SwordPommelTop","red"); S("SwordGrip","ironDark")
sub(SP,"PommelCap","blue",(0,-0.45,0),(0.6,0.3,0.6))
S("SwordCoil1","steel"); S("SwordCoil2","steel")
G = S("SwordGuard","ironDark",(0.9,0.75,2.6))
sub(G,"GuardOre","ore",(0,0,0),(1.0,0.45,0.5))
sub(G,"ArmR","red",(0,0.75,1.05),(0.7,1.3,0.55)); sub(G,"ArmL","blue",(0,0.75,-1.05),(0.7,1.3,0.55))
sub(G,"ArmTipR","steel",(0,1.5,1.05),(0.76,0.34,0.6)); sub(G,"ArmTipL","steel",(0,1.5,-1.05),(0.76,0.34,0.6))
BL = S("SwordBlade","steel"); S("SwordEdge","light"); S("SwordTip","steel")
sub(BL,"FullerRed","red",(0,-0.4,0.11),(0.6,4.2,0.22)); sub(BL,"FullerBlue","blue",(0,-0.4,-0.11),(0.62,4.2,0.22))

# ---------- ящик: залізна скринька з підковою-магнітом (у стадах, півот = центр дна; -Z — зовнішній бік) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","ironDark",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","ironDark",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","iron",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","iron",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","iron",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","iron",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","steel",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","steel",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","steel",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","steel",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Corner" + t, "ironDark", (1.87*sx, 1.035, 1.13*sz), (0.5, 1.67, 0.5))
B("BoxMagBase","ironDark",(0,0.55,-1.21),(1.14,0.3,0.18))     # підкова на зовнішньому боці
B("BoxMagR","red",(0.45,1.0,-1.2),(0.34,0.65,0.12)); B("BoxMagL","blue",(-0.45,1.0,-1.2),(0.34,0.65,0.12))
B("BoxMagTipR","steel",(0.45,1.42,-1.22),(0.4,0.2,0.22)); B("BoxMagTipL","steel",(-0.45,1.42,-1.22),(0.4,0.2,0.22))
B("BoxRivet1","steel",(-1.3,1.3,1.2),(0.24,0.24,0.12)); B("BoxRivet2","steel",(1.3,1.3,1.2),(0.24,0.24,0.12))
for sx, nm in ((1, "R"), (-1, "L")):   # однакові ручки-підковки: дві стійки (червона й синя) + сталева перекладина
    B("HandlePostA"+nm,"red",(2.2*sx,1.25,0.4),(0.5,0.22,0.22)); B("HandlePostB"+nm,"blue",(2.2*sx,1.25,-0.4),(0.5,0.22,0.22))
    B("HandleBar"+nm,"steel",(2.5*sx,1.25,0),(0.24,0.3,1.06))

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    g.export("/home/claude/lodestone/LodestoneGolemData.lua", [
        "-- Lodestone Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано lodestone_golem_generator.py.",
        "-- Скелет = Clay (21 кістка). Анімації стандартні. Pickaxe / Sword — у кулаці Fist_L. Box — залізна скринька в стадах."])
