# Emerald Golem (Epic, рол 1 до 35000, між Sapphire і Obsidian) — смарагдовий раджа: срібне тіло, смарагдові шовки
# (шаровари, рукави, пояс-кушак з хвостиком, плащ), кремовий тюрбан з брошкою-смарагдом і пером, ромбічний смарагд
# у срібному медальйоні на грудях, грановані кристали на плечах і на тюрбані. Кристали світяться (Neon `xtal`), як
# в інших Epic. Від Jade (матовий нефрит у золоті) — прозорий гранований камінь у сріблі.
# v2: анімації стандартні (без fx, кристаликів над плечима немає), нові кірка / меч-талвар / скриня раджі. Скелет Clay.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(silver="#9aa5b1", silverDark="#5f6b78", emerald="#22b86a", emeraldDark="#137a48", emeraldLight="#86eab4",
               glow="#5df0a6", xtal="#1fb84a", cream="#efe8d8", creamDark="#d6ccb6", light="#fff4e6", dark="#1c2836", pink="#f2a0b4"),
          bones={"Mouth": (0,10.5,2.3014), "MouthCorner_R": (0.65,10.6,2.3014), "MouthCorner_L": (-0.65,10.6,2.3014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
def prism(name, bone, base, h, w, rx=0, rz=0, col="xtal", tip="emeraldLight", mirror=False, R0=None):
    """гранований кристал: стовпчик (повернутий на 45° навколо своєї осі) + менший вершечок"""
    R = (R0 if R0 is not None else np.eye(3)) @ eul(rx=rx, rz=rz) @ eul(ry=45); up = R[:, 1]; base = np.array(base)
    sfx = "_R" if mirror else ""
    a(name + sfx, bone, col, tuple(base + up * h / 2), (w, h, w), R, mirror=mirror)
    a(name + "Tip" + sfx, bone, tip, tuple(base + up * (h + 0.12)), (w * 0.6, 0.5, w * 0.6), R, mirror=mirror)
D45 = eul(rz=45)

# ---------- ноги: срібні гомілки, смарагдові шаровари ----------
a("Foot_R","Shin_R","silverDark",(2.2,0.55,0.2),(3.2,1.1,3.7),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","silver",(2.15,2.2,-0.2),(2.7,2.3,2.7),eul(ry=4),mirror=True)
a("ShinBand_R","Shin_R","emeraldDark",(2.15,3.0,-0.2),(2.86,0.36,2.86),eul(ry=4),mirror=True)
a("KneeGem_R","Shin_R","xtal",(2.25,2.25,1.2),(0.8,0.8,0.3),eul(ry=4)@D45,mirror=True)
a("Thigh_R","Thigh_R","emeraldDark",(2.0,4.0,-0.25),(2.8,1.7,2.8),eul(ry=-6),mirror=True)
a("Pelvis","Hips","silverDark",(0,4.85,-0.3),(6.2,1.6,3.5))
a("Sash","Hips","emerald",(0,5.45,-0.3),(6.6,0.5,3.9))
a("Buckle","Hips","silver",(0,5.45,1.68),(1.1,0.8,0.3))
a("BuckleGem","Hips","emeraldLight",(0,5.45,1.86),(0.45,0.45,0.2),D45)
a("SashTail","Hips","emerald",(2.3,4.65,1.72),(0.6,1.4,0.3),eul(rz=-6))
# ---------- корпус: ромбічний смарагд у срібному медальйоні ----------
a("Torso","Torso","silver",(0,7.5,-0.3),(7.4,4.2,4.2))
a("Chest","Torso","silver",(0,9.6,-0.35),(8.6,1.6,4.7))
a("ChestBand","Torso","emeraldDark",(0,8.95,-0.3),(7.6,0.4,4.4))
MC = 7.25
a("Medal","Torso","silverDark",(0,MC,1.95),(2.6,2.6,0.3),D45)
a("Gem1","Torso","emeraldDark",(0,MC,2.2),(2.1,2.1,0.2),D45)
a("Gem2","Torso","emerald",(0,MC,2.3),(1.5,1.5,0.2),D45)
a("Gem3","Torso","xtal",(0,MC,2.4),(0.95,0.95,0.2),D45)
a("Core","Torso","glow",(0,MC,2.5),(0.5,0.5,0.2),D45)
for nm, (x, y) in {"PearlT": (0, 1.95), "PearlB": (0, -1.95), "PearlR": (1.95, 0), "PearlL": (-1.95, 0)}.items():
    a(nm,"Torso","silver",(x,MC+y,2.05),(0.42,0.42,0.42),D45)
# спина: смарагдовий плащ із срібною облямівкою
a("CapeTop","Torso","emeraldDark",(0,9.55,-2.75),(5.6,0.6,0.4))
a("Cape","Torso","emerald",(0,7.5,-2.6),(5.0,4.4,0.4))
a("CapeTrim","Torso","silver",(0,5.45,-2.6),(5.2,0.35,0.44))
a("CapeGem","Torso","emeraldLight",(0,7.9,-2.86),(0.8,0.8,0.2),D45)
# ---------- голова: тюрбан з брошкою, пером і кристалом ----------
a("Head","Head","silver",(0,11.15,0.5014),(4.0,2.7,3.4))
a("Turban","Head","cream",(0,12.85,0.45),(4.4,1.0,3.8))
a("TurbanWrap","Head","creamDark",(0,13.25,0.45),(4.5,0.32,3.95),eul(rz=8))
a("TurbanTop","Head","cream",(0,13.7,0.4),(3.6,0.8,3.2))
a("Brooch","Head","silver",(0,13.05,2.4),(1.0,1.0,0.25),D45)
a("BroochGem","Head","xtal",(0,13.05,2.55),(0.66,0.66,0.2),D45)
a("Plume1","Head","emeraldLight",(0.3,14.15,2.25),(0.36,1.4,0.24),eul(rz=-15))
a("Plume2","Head","emerald",(0.62,15.0,2.2),(0.28,0.8,0.2),eul(rz=-32))
prism("TurbanXtal","Head",(0,13.95,0.3),0.9,0.6)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","light",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.0,2.25),(1.2,0.26,0.3),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.24,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.5,2.3014),(1.1,0.24,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.22,0.5),mirror=True)
# ---------- руки: срібні плечі з гранованими кристалами, смарагдові рукави ----------
r3 = eul(rz=3)
a("Shoulder_R","UpperArm_R","silver",(5.0,9.85,-0.3),(3.4,1.9,3.6),r3,mirror=True)
a("Pauldron_R","UpperArm_R","silverDark",(5.05,10.9,-0.3),(3.1,0.3,3.3),r3,mirror=True)
prism("ShXtalA","UpperArm_R",(5.1,10.95,-0.3),1.3,0.7,R0=r3,mirror=True)
prism("ShXtalB","UpperArm_R",(5.95,10.95,0.3),0.8,0.5,rz=-25,R0=r3,mirror=True)
prism("ShXtalC","UpperArm_R",(4.35,10.95,-0.95),0.7,0.45,rx=-20,rz=15,R0=r3,mirror=True)
a("UpperArm_R","UpperArm_R","emeraldDark",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","silver",(5.55,5.75,0.0014),(2.9,2.4,3.0),eul(ry=-6),mirror=True)
a("Bracer_R","Forearm_R","silverDark",(5.55,6.4,0.0014),(3.1,0.7,3.2),eul(ry=-6),mirror=True)
a("BracerGem_R","Forearm_R","xtal",(5.39,6.4,1.62),(0.55,0.55,0.25),eul(ry=-6)@D45,mirror=True)
fist = a("Fist_R","Forearm_R","silver",(5.65,3.45,0.1014),(3.6,2.7,3.6),eul(ry=6.875))
sub(fist,"Knuckles_R","silverDark",(0.15,0.3,1.85),(3.0,1.0,0.45))
sub(fist,"FistGem_R","xtal",(1.88,0.3,0.3),(0.4,0.75,0.75),eul(rx=45))
sub(fist,"Thumb_R","silver",(-1.9,0.1,1.05),(0.5,1.1,0.9),eul(rz=-6)); mir(4)
# ---------- кірка v2: подвійна — смарагдове лезо й смарагдовий шип на обусі, срібна оправа ----------
OCTA = eul(rx=35.264) @ eul(rz=45)
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","silverDark"); P("Grip","emeraldDark"); P("Band","silver")
PM = P("Pommel","silver")
sub(PM,"PommelGem","xtal",(0,-0.6,0),(0.5,0.5,0.5),OCTA)
sub(PM,"PommelSpike","silver",(0,-1.05,0),(0.2,0.45,0.2),eul(ry=45))
sub(HN,"Ring1","silver",(0,1.5,0),(0.82,0.28,0.82))
sub(HN,"RingSilk","emeraldDark",(0,2.05,0),(0.76,0.5,0.76),eul(ry=45))
sub(HN,"Ring2","silver",(0,2.6,0),(0.82,0.28,0.82))
HD = P("Head","silver"); P("HeadRound","emeraldDark")
P1 = P("Pick1","emeraldDark"); P("Pick2","xtal"); P("Pick3","xtal"); P("Pick4","emeraldLight"); P("PickGlint","light")
for side, nm in ((1, "R"), (-1, "L")):
    sub(HD, f"HeadGem{nm}", "xtal", (0.88*side, 0, 0), (0.2, 0.9, 0.9), eul(rx=45))
    sub(HD, f"HeadGemTop{nm}", "emeraldLight", (0.97*side, 0, 0), (0.15, 0.45, 0.45), eul(rx=45))
    sub(P1, f"Setting{nm}", "silver", (0.56*side, 0.3, 0), (0.12, 0.55, 1.5))
sub(HD,"Collar","silver",(0,0,-1.2),(1.0,1.0,0.45),eul(rz=45))
sub(HD,"BackXtal","xtal",(0,0,-2.1),(0.7,0.7,1.5),eul(rz=45))
sub(HD,"BackTip","emeraldLight",(0,0,-3.0),(0.42,0.42,0.5),eul(rz=45))
sub(HD,"BackSideR","xtal",(0.5,0,-1.65),(0.32,0.32,0.7),eul(ry=30)@eul(rz=45))
sub(HD,"BackSideL","xtal",(-0.5,0,-1.65),(0.32,0.32,0.7),eul(ry=-30)@eul(rz=45))
# ---------- меч v2: талвар — дисковий навершник, гарда з язиком і смарагдовими кульками, світний дол ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
SP = S("SwordPommel","silver"); S("SwordPommelTop","emeraldDark"); S("SwordGrip","emeraldDark")
sub(SP,"PommelDisc","silver",(0,-0.45,0),(1.3,0.18,1.3))
sub(SP,"PommelGem","xtal",(0,-0.65,0),(0.45,0.45,0.45),OCTA)
sub(SP,"PommelSpike","silver",(0,-1.05,0),(0.2,0.45,0.2),eul(ry=45))
S("SwordCoil1","silver"); S("SwordCoil2","silver")
G = S("SwordGuard","silverDark",(0.8,0.6,2.2))
sub(G,"QBallR","xtal",(0,0,1.3),(0.5,0.5,0.5),OCTA); sub(G,"QBallL","xtal",(0,0,-1.3),(0.5,0.5,0.5),OCTA)
sub(G,"Langet","silver",(0,0.6,0),(0.7,0.7,0.5))
sub(G,"LangetGem","xtal",(0,0.6,0),(0.8,0.38,0.38),eul(rx=45))
BL = S("SwordBlade","silver"); S("SwordEdge","light"); S("SwordFuller","xtal"); S("SwordTip","silver")
for i, y in enumerate((2.3, 2.85)):
    for sz in (1, -1):
        sub(BL,f"Engrave{i}{'R' if sz>0 else 'L'}","emeraldDark",(0,y,0.45*sz),(0.52,0.3,0.3),eul(rx=45))

# ---------- ящик: смарагдова скриня раджі (у стадах, півот = центр дна; -Z — зовнішній бік) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","silverDark",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","silverDark",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","emeraldDark",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","emeraldDark",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","emeraldDark",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","emeraldDark",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","silver",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","silver",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","silver",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","silver",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Corner" + t, "silverDark", (1.87*sx, 1.035, 1.13*sz), (0.5, 1.67, 0.5))
B("BoxMedal","silver",(0,0.98,-1.2),(1.1,1.1,0.14),D45)          # ромб-смарагд на зовнішньому боці
B("BoxGem1","xtal",(0,0.98,-1.3),(0.75,0.75,0.12),D45)
B("BoxGem2","emeraldLight",(0,0.98,-1.38),(0.36,0.36,0.1),D45)
B("BoxStudR","xtal",(1.05,0.98,-1.2),(0.3,0.3,0.12),D45); B("BoxStudL","xtal",(-1.05,0.98,-1.2),(0.3,0.3,0.12),D45)
B("BoxStud1","silver",(-1.0,1.1,1.2),(0.26,0.26,0.12)); B("BoxStud2","silver",(1.0,1.1,1.2),(0.26,0.26,0.12))
B("BoxGemIn","xtal",(0,1.1,1.2),(0.32,0.32,0.12),D45)
OCTA_B = eul(rx=35.264) @ eul(rz=45)
for sx in (1, -1):        # «бані» палацу на кутах: срібна підставка, смарагдова баня, срібний шпиль
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("DomeBase" + t, "silver", (1.87*sx, 2.02, 1.06*sz), (0.46, 0.35, 0.46))
        B("Dome" + t, "xtal", (1.87*sx, 2.45, 1.06*sz), (0.42, 0.42, 0.42), OCTA_B)
        B("Spire" + t, "silver", (1.87*sx, 2.79, 1.06*sz), (0.1, 0.32, 0.1))
for sx, nm in ((1, "R"), (-1, "L")):   # однакові ручки: дві срібні стійки + світна смарагдова перекладина
    B("HandlePostA"+nm,"silver",(2.2*sx,1.25,0.4),(0.5,0.22,0.22)); B("HandlePostB"+nm,"silver",(2.2*sx,1.25,-0.4),(0.5,0.22,0.22))
    B("HandleBar"+nm,"xtal",(2.5*sx,1.25,0),(0.24,0.3,1.06))

if __name__ == "__main__":
    out = "/home/claude/emerald/EmeraldGolemData.lua"
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    g.export(out, [
        "-- Emerald Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано emerald_golem_generator.py.",
        "-- Скелет = Clay (21 кістка). Анімації стандартні (без fx). neon — серцевина й кристали (glow, xtal). Pickaxe / Sword — у кулаці Fist_L. Box — скриня раджі в стадах."])
    s = open(out).read().replace(" bones={", " neon={glow=true,xtal=true},\n bones={", 1); open(out, "w").write(s)
