# Snow Golem (Exclusive, тижнева нагорода — 21-й день Daily, Carrier 90 % best; рівень Mushroom): веселий сніговик.
# Три «грудки» снігу (округлені ступенями), червоний шарф із кінцем, що хитається (sway), відро на голові, морквяний ніс,
# вугільні ґудзики, червоні рукавиці, гілочки на плечах (Y, без хреста). Кірка з льодяною головою, меч-бурулька;
# ящик — санки-скриня на полозах із ручками-мотузками. Сніг сіро-блакитний, без Neon (не сліпить). Скелет Clay.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(snow="#e4ebf3", snowShade="#bfcbdb", scarf="#c8463f", scarfDark="#8e2f2b", carrot="#e98a2e", coal="#2a2d33",
               bucket="#5a6878", bucketRim="#7d8a9a", twig="#5b3f2a", ice="#a9d8f0", iceDark="#6fa9cc",
               wood="#8a5a32", woodDark="#5a3a20", rope="#d8c39a", light="#fff4e6", dark="#1c2836", pink="#f2a0b4"),
          bones={"Mouth": (0,10.5,2.3014), "MouthCorner_R": (0.65,10.6,2.3014), "MouthCorner_L": (-0.65,10.6,2.3014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))

# ---------- ноги (нижня «грудка» — таз) ----------
a("Foot_R","Shin_R","snowShade",(2.2,0.55,0.2),(3.2,1.1,3.7),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","snow",(2.15,2.2,-0.2),(2.7,2.3,2.7),eul(ry=4),mirror=True)
a("Thigh_R","Thigh_R","snow",(2.0,4.0,-0.25),(2.8,1.7,2.8),eul(ry=-6),mirror=True)
a("Pelvis","Hips","snow",(0,4.85,-0.3),(6.2,1.6,3.5))
a("PelvisRound","Hips","snow",(0,4.85,-0.3),(5.4,1.2,4.1))
# ---------- корпус (середня «грудка»), ґудзики, шарф ----------
a("Torso","Torso","snow",(0,7.5,-0.3),(7.4,4.2,4.2))
a("TorsoRound","Torso","snow",(0,7.5,-0.3),(6.6,3.4,4.9))
for i, y in enumerate((6.6, 7.5, 8.4), 1):
    a(f"Button{i}","Torso","coal",(0,y,2.24),(0.5,0.5,0.24))
a("Chest","Torso","snow",(0,9.6,-0.35),(8.6,1.6,4.7))
a("Scarf","Torso","scarf",(0,9.75,2.12),(4.6,0.7,0.3))              # шарф: спереду на грудях
a("ScarfStripe","Torso","scarfDark",(0,9.75,2.12),(4.66,0.24,0.36))
a("ScarfCollar","Torso","scarf",(0,10.5,0.2),(4.6,0.2,3.4))          # і навколо шиї (зверху на плечах)
a("ScarfTail","Torso","scarf",(-1.3,8.75,2.42),(0.9,1.9,0.3))
a("ScarfTailStripe","Torso","scarfDark",(-1.3,8.3,2.42),(0.96,0.26,0.38))
a("Fringe","Torso","scarfDark",(-1.33,7.75,2.42),(0.8,0.24,0.24))
# ---------- голова (верхня «грудка»): відро, морквяний ніс ----------
a("Head","Head","snow",(0,11.15,0.5014),(4.0,2.7,3.4))
a("HeadRound","Head","snow",(0,11.25,0.45),(3.4,3.1,2.8))
a("BucketRim","Head","bucketRim",(0.15,12.85,0.35),(3.0,0.32,2.8),eul(rz=-7))
a("Bucket","Head","bucket",(0.24,13.6,0.35),(2.5,1.3,2.3),eul(rz=-7))
a("BucketTop","Head","bucketRim",(0.32,14.32,0.35),(2.1,0.22,1.9),eul(rz=-7))
a("Carrot","Head","carrot",(0,11.1,2.37),(0.46,0.46,0.4))
a("CarrotTip","Head","carrot",(0,11.12,2.76),(0.3,0.3,0.42))
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","coal",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","light",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.06,2.25),(1.2,0.26,0.3),mirror=True)   # рівні підняті брови + усмішка
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.24,0.25),mirror=True)
a("Mouth","Mouth","coal",(0,10.5,2.3014),(1.1,0.24,0.3))
a("MouthCorner_R","MouthCorner_R","coal",(0.65,10.6,2.3014),(0.3,0.22,0.5),mirror=True)
# ---------- руки: снігові, червоні рукавиці, гілочки на плечах ----------
a("Shoulder_R","UpperArm_R","snow",(5.0,9.85,-0.3),(3.4,1.9,3.6),eul(rz=3),mirror=True)
a("Pauldron_R","UpperArm_R","snowShade",(5.15,10.95,-0.3),(3.6,0.45,3.8),eul(rz=3),mirror=True)
a("Twig_R","UpperArm_R","twig",(5.55,11.9,-0.7),(0.26,1.6,0.26),eul(rz=-25),mirror=True)
a("TwigFork_R","UpperArm_R","twig",(5.63,12.52,-0.7),(0.2,0.75,0.2),eul(rz=22),mirror=True)
a("UpperArm_R","UpperArm_R","snowShade",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","snow",(5.55,5.75,0.0014),(2.9,2.4,3.0),eul(ry=-6),mirror=True)
a("Cuff_R","Forearm_R","scarfDark",(5.55,4.9,0.0014),(3.1,0.4,3.2),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","scarf",(5.65,3.45,0.1014),(3.6,2.7,3.6),eul(ry=6.875))
sub(fist,"Knuckles_R","scarfDark",(0.15,0.3,1.85),(3.0,1.0,0.45))
sub(fist,"Thumb_R","scarf",(-1.9,0.1,1.05),(0.5,1.1,0.9),eul(rz=-6)); mir(3)
# кінець шарфа хитається (sway) — сильніше в ходьбі й бігу
g.fx.append(dict(kind="sway", parts=["ScarfTail","ScarfTailStripe","Fringe"], pivot=(-1.3, 9.7, 2.42), axis=(0, 0, 1), amp=0.14, speed=1.8,
                 states={"Walk": 1.5, "Run": 2.2, "Carry": 1.4}))

# ---------- кірка: льодяна голова, червона рукоять ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
P("Handle","twig"); P("Grip","scarf"); P("Band","scarfDark"); P("Pommel","snow")
HD = P("Head","iceDark"); P("HeadRound","ice")
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n,"ice")
P("Back1","iceDark"); P("Back2","iceDark"); P("PickGlint","light")
for side, nm in ((1, "R"), (-1, "L")):
    sub(HD, f"SnowBand{nm}", "snow", (0.88*side, 0.55, 0), (0.18, 0.3, 1.9))
    sub(HD, f"SnowBall{nm}", "snow", (0.9*side, -0.2, 0.3), (0.24, 0.5, 0.5))
# ---------- меч-бурулька ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordPommel","snow"); S("SwordPommelTop","scarfDark"); S("SwordGrip","twig")
S("SwordCoil1","scarf"); S("SwordCoil2","scarf")
G = S("SwordGuard","snowShade")
sub(G,"GuardSnowR","snow",(0,0,1.25),(0.6,0.6,0.6))
sub(G,"GuardSnowL","snow",(0,0,-1.25),(0.6,0.6,0.6))
S("SwordBlade","ice"); S("SwordEdge","light"); S("SwordFuller","iceDark"); S("SwordTip","ice")

# ---------- ящик: санки-скриня на полозах (у стадах, півот = центр дна; -Z — зовнішній бік) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","woodDark",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","woodDark",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","wood",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","wood",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","wood",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","wood",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","snow",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","snow",(0,1.9,-1.0),(4.1,0.24,0.44))   # рівний «сніговий» обідок
B("RimR","snow",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","snow",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Corner" + t, "woodDark", (1.87*sx, 1.035, 1.13*sz), (0.5, 1.67, 0.5))
for i, y in enumerate((0.6, 1.3), 1):   # червоні смуги санок
    B(f"StripeB{i}","scarf",(0,y,-1.2),(3.24,0.24,0.12)); B(f"StripeF{i}","scarf",(0,y,1.2),(3.24,0.24,0.12))
for sz, nm in ((1, "F"), (-1, "B")):   # полози: дві стійки + полоз із загнутим носом
    B("StrutA"+nm,"bucketRim",(1.3,-0.3,0.85*sz),(0.2,0.3,0.2)); B("StrutB"+nm,"bucketRim",(-1.3,-0.3,0.85*sz),(0.2,0.3,0.2))
    B("Runner"+nm,"bucketRim",(0,-0.54,0.85*sz),(4.2,0.18,0.22))
    B("RunnerTip"+nm,"bucketRim",(2.2,-0.33,0.85*sz),(0.18,0.55,0.22),eul(rz=20))
for sx, nm in ((1, "R"), (-1, "L")):   # однакові ручки-мотузки
    B("RopePostA"+nm,"woodDark",(2.2*sx,1.25,0.4),(0.5,0.22,0.22)); B("RopePostB"+nm,"woodDark",(2.2*sx,1.25,-0.4),(0.5,0.22,0.22))
    B("RopeBar"+nm,"rope",(2.5*sx,1.25,0),(0.24,0.3,1.06))

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    out = "/home/claude/snow/SnowGolemData.lua"
    g.export(out, [
        "-- Snow Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано snow_golem_generator.py.",
        "-- Скелет = Clay (21 кістка). fx — кінець шарфа хитається (sway). Box — санки-скриня в стадах (полози нижче дна)."])
