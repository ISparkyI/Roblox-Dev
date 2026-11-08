# Topaz Golem (Epic, рол 1 до 6000, між Silverjaw і Geode): ювелірний голем зі сланцю й срібла.
# На грудях великий топаз «смарагдової» огранки (ступінчасті шари) у срібній оправі з лапками, на плечах — огранені
# топази-наплічники, на голові срібний обруч із трьома призмами топазу, на спині друза топазових призм.
# Невеликі блакитні топази (наручі, кірка, меч). Анімації стандартні (Epic без fx). Скелет Clay.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(slate="#5d5866", slateDark="#3f3b47", silver="#cfd5dd", topaz="#e8a93a", topazLight="#f7cf6e",
               topazDark="#b97a24", blue="#6fb3dc", glow="#ffd877", light="#fff4e6", dark="#1c2836", pink="#f2a0b4"),
          bones={"Mouth": (0,10.5,2.3014), "MouthCorner_R": (0.65,10.6,2.3014), "MouthCorner_L": (-0.65,10.6,2.3014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
def prism(name, bone, base, h, w, rx=0, rz=0, ry=45, col="topaz", tip="topazLight", mirror=False, group=None):
    """призма топазу з «пірамідкою» на кінці: стовпчик + менший блок-вершечок"""
    R = eul(rx=rx, rz=rz) @ eul(ry=ry); up = R[:, 1]; base = np.array(base)
    a(name + ("_R" if mirror else ""), bone, col, tuple(base + up * h / 2), (w, h, w), R, group=group, mirror=mirror)
    a(name + "Tip" + ("_R" if mirror else ""), bone, tip, tuple(base + up * (h + 0.12)), (w * 0.6, 0.5, w * 0.6), R, group=group, mirror=mirror)

# ---------- ноги ----------
a("Foot_R","Shin_R","slateDark",(2.2,0.55,0.2),(3.2,1.1,3.7),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","slate",(2.15,2.2,-0.2),(2.7,2.3,2.7),eul(ry=4),mirror=True)
a("ShinBand_R","Shin_R","silver",(2.15,2.95,-0.2),(2.86,0.36,2.86),eul(ry=4),mirror=True)
a("KneeGem_R","Shin_R","topaz",(2.25,2.35,1.2),(0.9,0.9,0.3),eul(ry=4)@eul(rz=45),mirror=True)
a("Thigh_R","Thigh_R","slateDark",(2.0,4.0,-0.25),(2.8,1.7,2.8),eul(ry=-6),mirror=True)
a("Pelvis","Hips","slateDark",(0,4.85,-0.3),(6.2,1.6,3.5))
a("Belt","Hips","silver",(0,5.45,-0.3),(6.6,0.5,3.9))
a("Buckle","Hips","topaz",(0,5.45,1.68),(1.0,0.7,0.3))
# ---------- корпус: великий огранений топаз у срібній оправі ----------
a("Torso","Torso","slate",(0,7.5,-0.3),(7.4,4.2,4.2))
a("Chest","Torso","slate",(0,9.6,-0.35),(8.6,1.6,4.7))
a("ChestBand","Torso","slateDark",(0,8.95,-0.3),(7.6,0.4,4.4))
a("Bezel","Torso","silver",(0,7.3,1.95),(3.4,2.9,0.3))
a("Gem1","Torso","topazDark",(0,7.3,2.2),(2.8,2.3,0.2))
a("Gem2","Torso","topaz",(0,7.3,2.3),(2.1,1.65,0.2))
a("Gem3","Torso","topazLight",(0,7.3,2.4),(1.4,1.0,0.2))
a("GemTable","Torso","glow",(0,7.3,2.5),(0.7,0.42,0.2))
for sx in (1, -1):
    for sy in (1, -1):
        a(f"Prong{'R' if sx > 0 else 'L'}{'T' if sy > 0 else 'B'}","Torso","silver",(1.42*sx,7.3+1.17*sy,2.27),(0.42,0.42,0.42),eul(rz=45))
# спина: друза топазових призм
a("BackPlate","Torso","slateDark",(0,7.7,-2.45),(3.8,3.0,0.3))
prism("BackXtal1","Torso",(0,7.9,-2.45),2.2,0.9,rx=-55)
prism("BackXtal2","Torso",(0.95,7.2,-2.45),1.6,0.7,rx=-50,rz=-28)
prism("BackXtal3","Torso",(-0.95,7.3,-2.45),1.4,0.62,rx=-58,rz=26,col="topazDark",tip="topaz")
# ---------- голова: срібний обруч з трьома призмами топазу ----------
a("Head","Head","slate",(0,11.15,0.5014),(4.0,2.7,3.4))
a("Circlet","Head","silver",(0,12.55,0.45),(4.2,0.45,3.6))
a("CircletGem","Head","blue",(0,12.55,2.3),(0.6,0.6,0.25),eul(rz=45))
prism("Crown1","Head",(0,12.6,0.35),1.5,0.8,col="topaz",tip="glow")
prism("Crown2","Head",(0.95,12.6,0.35),1.0,0.6,rz=-20)
prism("Crown3","Head",(-0.95,12.6,0.35),1.0,0.6,rz=20)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","light",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.02,2.25),(1.2,0.26,0.3),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.24,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.5,2.3014),(1.1,0.24,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.22,0.5),mirror=True)
# ---------- руки: огранені топази-наплічники, срібні наручі з блакитним топазом ----------
r3 = eul(rz=3)
a("Shoulder_R","UpperArm_R","slate",(5.0,9.85,-0.3),(3.4,1.9,3.6),r3,mirror=True)
a("Pauldron_R","UpperArm_R","silver",(5.05,10.9,-0.3),(3.1,0.3,3.3),r3,mirror=True)
a("PauldronGem1_R","UpperArm_R","topazDark",(5.06,11.17,-0.3),(2.5,0.3,2.7),r3,mirror=True)
a("PauldronGem2_R","UpperArm_R","topaz",(5.07,11.45,-0.3),(1.8,0.3,2.0),r3,mirror=True)
a("PauldronGem3_R","UpperArm_R","topazLight",(5.08,11.72,-0.3),(1.0,0.26,1.2),r3,mirror=True)
a("UpperArm_R","UpperArm_R","slateDark",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","slate",(5.55,5.75,0.0014),(2.9,2.4,3.0),eul(ry=-6),mirror=True)
a("Bracer_R","Forearm_R","silver",(5.55,6.4,0.0014),(3.1,0.7,3.2),eul(ry=-6),mirror=True)
a("BracerGem_R","Forearm_R","blue",(5.39,6.4,1.6),(0.6,0.5,0.25),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","slate",(5.65,3.45,0.1014),(3.6,2.7,3.6),eul(ry=6.875))
sub(fist,"Knuckles_R","silver",(0.15,0.3,1.85),(3.0,1.0,0.45))
sub(fist,"FistGem_R","topaz",(1.88,0.3,0.3),(0.4,0.8,0.8),eul(rx=45))
sub(fist,"Thumb_R","slate",(-1.9,0.1,1.05),(0.5,1.1,0.9),eul(rz=-6)); mir(4)

# ---------- кірка v2 (ювелірна): обух — огранений топаз у срібних лапках, лезо в срібній оправі ----------
OCTA = eul(rx=35.264) @ eul(rz=45)
names = lambda: [b["name"] for b in g.blocks]
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","slateDark"); P("Grip","slate"); P("Band","silver")
PM = P("Pommel","silver")
sub(PM,"PommelGem","topaz",(0,-0.6,0),(0.55,0.55,0.55),OCTA)
sub(HN,"Ring1","silver",(0,1.5,0),(0.82,0.28,0.82))
sub(HN,"RingGem","topaz",(0,2.05,0),(0.76,0.5,0.76),eul(ry=45))
sub(HN,"Ring2","silver",(0,2.6,0),(0.82,0.28,0.82))
HD = P("Head","silver"); P("HeadRound","topazDark")
P1 = P("Pick1","topazDark"); P("Pick2","topaz"); P("Pick3","topaz"); P("Pick4","topazLight"); P("PickGlint","light")
for side, nm in ((1, "R"), (-1, "L")):
    sub(HD, f"HeadGem{nm}", "topaz", (0.88*side, 0, 0), (0.2, 1.0, 1.2))
    sub(HD, f"HeadGemTop{nm}", "topazLight", (0.97*side, 0, 0), (0.15, 0.5, 0.6))
    sub(P1, f"Setting{nm}", "silver", (0.56*side, 0.3, 0), (0.12, 0.55, 1.5))
sub(HD,"Collar","silver",(0,0,-1.25),(1.1,1.1,0.5),eul(rz=45))
sub(HD,"Orb","topaz",(0,0,-2.1),(1.25,1.25,1.25),OCTA)
sub(HD,"OrbCore","topazLight",(0,0,-2.1),(0.92,0.92,0.92),eul(rz=45))
for i, (x, y) in enumerate(((0.62,0),(-0.62,0),(0,0.62),(0,-0.62))):
    sub(HD,f"Claw{i}","silver",(x,y,-1.75),(0.2,0.2,0.75))
sub(HD,"OrbCap","blue",(0,0,-3.0),(0.32,0.32,0.32),OCTA)
# ---------- меч v2: срібна гарда з великим топазом і крилами-призмами, клинок у ромбах-гранях ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
SP = S("SwordPommel","silver"); S("SwordPommelTop","topazLight"); S("SwordGrip","slateDark")
sub(SP,"PommelGem","topaz",(0,-0.55,0),(0.6,0.6,0.6),OCTA)
S("SwordCoil1","silver"); S("SwordCoil2","silver")
G = S("SwordGuard","silver",(0.8,0.6,2.4))
sub(G,"GuardGemC","topaz",(0,0.1,0),(0.85,0.85,0.85),OCTA)
sub(G,"GuardBlue","blue",(0,-0.36,0),(0.5,0.3,0.5),eul(ry=45))
for sz, nm in ((1,"R"),(-1,"L")):
    R = eul(rx=35*sz); up = R[:,1]; c = np.array((0,0.35,1.3*sz))
    sub(G,f"Wing{nm}","topaz",tuple(c),(0.45,1.0,0.45),R)
    sub(G,f"WingTip{nm}","topazLight",tuple(c+up*0.62),(0.28,0.35,0.28),R)
BL = S("SwordBlade","topaz"); S("SwordEdge","topazLight"); S("SwordFuller","topazDark"); S("SwordTip","topazLight")
sub(BL,"Ricasso","silver",(0,-2.95,0),(0.6,0.5,1.7))
for i, y in enumerate((-1.5, 0.0, 1.5, 2.6)):
    for sz in (1, -1):
        sub(BL,f"Facet{i}{'R' if sz>0 else 'L'}","topazLight",(0,y,0.55*sz),(0.55,0.34,0.34),eul(rx=45))

# ---------- ящик: сланцева скриня з огранованим топазом (у стадах, півот = центр дна; -Z — зовнішній бік) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","slateDark",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","slateDark",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","slate",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","slate",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","slate",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","slate",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","silver",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","silver",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","silver",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","silver",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Corner" + t, "slateDark", (1.87*sx, 1.035, 1.13*sz), (0.5, 1.67, 0.5))
B("BoxBezel","silver",(0,0.98,-1.2),(1.5,1.06,0.14))          # огранений топаз на зовнішньому боці
B("BoxGem1","topaz",(0,0.98,-1.3),(1.1,0.74,0.12))
B("BoxGem2","topazLight",(0,0.98,-1.38),(0.56,0.36,0.1))
B("BoxGemIn","blue",(0,0.98,1.2),(0.5,0.5,0.12),eul(rz=45))   # маленький блакитний топаз усередині
for sx, nm in ((1, "R"), (-1, "L")):   # однакові ручки: дві срібні стійки + топазова перекладина
    B("HandlePostA"+nm,"silver",(2.2*sx,1.25,0.4),(0.5,0.22,0.22)); B("HandlePostB"+nm,"silver",(2.2*sx,1.25,-0.4),(0.5,0.22,0.22))
    B("HandleBar"+nm,"topaz",(2.5*sx,1.25,0),(0.24,0.3,1.06))

if __name__ == "__main__":
    out = "/home/claude/topaz/TopazGolemData.lua"
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    g.export(out, [
        "-- Topaz Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано topaz_golem_generator.py.",
        "-- Скелет = Clay (21 кістка). Анімації стандартні. neon — лише маленька «площадка» топазу на грудях і верх корони. Pickaxe / Sword — у кулаці Fist_L. Box — сланцева скриня в стадах."])
    s = open(out).read().replace(" bones={", " neon={glow=true},\n bones={", 1); open(out, "w").write(s)
