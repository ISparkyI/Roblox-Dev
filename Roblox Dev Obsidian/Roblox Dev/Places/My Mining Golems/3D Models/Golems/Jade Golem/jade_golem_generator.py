# Jade Golem (Exclusive #2, рівень Epic): нефритовий вартовий — зелений нефрит, золото, світний смарагд (Neon).
# Фірмове: нефритовий диск «бі» на спині повільно обертається (fx spin), хмарні візерунки на наплічниках,
# маска дракона на поясі, золоті ґудзики-вузлики на грудях, драконячі ріжки на обручі. Скелет Clay.
# Інструменти — шаблон із золотими накладками й нефритовими вставками. Ящик — лакована скриня з драконячими ручками-кільцями.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(jade="#3b9a52", jadeDark="#1d5a36", jadeLight="#aee3a6", gold="#e8b84a", glow="#4dff6a",
               light="#f1f5f8", dark="#1c2836", pink="#f2a0b4", lacquer="#8e1f2a", lacquerDark="#3a1418"),
          bones={"Mouth": (0,10.5,2.3014), "MouthCorner_R": (0.65,10.6,2.3014), "MouthCorner_L": (-0.65,10.6,2.3014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
# ---------- ноги ----------
a("Foot_R","Shin_R","jadeDark",(2.2,0.55,0.2),(3.2,1.1,3.7),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","jade",(2.15,2.2,-0.2),(2.7,2.3,2.7),eul(ry=4),mirror=True)
a("ShinBand_R","Shin_R","gold",(2.15,2.85,-0.2),(2.86,0.3,2.86),eul(ry=4),mirror=True)
a("KneeCloud_R","Shin_R","gold",(2.25,2.3,1.22),(0.8,0.45,0.24),mirror=True)
a("Thigh_R","Thigh_R","jadeDark",(2.0,4.0,-0.25),(2.8,1.7,2.8),eul(ry=-6),mirror=True)
# ---------- таз: маска дракона ----------
a("Pelvis","Hips","jadeDark",(0,4.85,-0.3),(6.2,1.6,3.5))
a("Belt","Hips","gold",(0,5.45,-0.3),(6.6,0.5,3.9))
a("Mask","Hips","jade",(0,5.15,1.7),(1.6,1.2,0.4))
a("MaskBrow","Hips","gold",(0,5.66,1.78),(1.8,0.26,0.36))
a("MaskEye_R","Hips","glow",(0.42,5.28,1.92),(0.3,0.22,0.16),mirror=True)
a("MaskHorn_R","Hips","gold",(0.95,5.95,1.72),(0.3,0.6,0.3),eul(rz=-30),mirror=True)
a("MaskSnout","Hips","jadeLight",(0,4.85,1.96),(0.8,0.4,0.24))
# ---------- корпус: комір-стійка, ґудзики-вузлики, смарагд ----------
a("Torso","Torso","jade",(0,7.5,-0.3),(7.4,4.2,4.2))
a("Chest","Torso","jade",(0,9.6,-0.35),(8.6,1.6,4.7))
a("Collar","Torso","gold",(0,10.3,-0.35),(4.8,0.5,3.8))
a("CollarGem","Torso","glow",(0,9.95,2.0),(0.55,0.55,0.2),eul(rz=45))
a("Placket","Torso","jadeDark",(0,7.6,1.84),(1.0,3.6,0.2))
for i, y in enumerate((8.6, 7.6, 6.6), 1):
    a(f"Knot{i}","Torso","gold",(0,y,1.97),(1.5,0.24,0.22))
# ---------- спина: диск «бі» (обертається) ----------
HC = np.array((0, 8.4, -3.1))
a("BiArm","Torso","gold",(0, 8.4, -2.75),(0.6,0.6,0.72))
a("BiA","Torso","jadeLight",tuple(HC),(2.6,2.6,0.34))
a("BiB","Torso","jadeLight",tuple(HC),(2.6,2.6,0.24),eul(rz=45))
a("BiHole","Torso","jadeDark",tuple(HC + [0,0,-0.02]),(0.8,0.8,0.42),eul(rz=45))
a("BiGem","Torso","glow",tuple(HC + [0,0,-0.2]),(0.4,0.4,0.16),eul(rz=45))
BI = ["BiA","BiB","BiHole","BiGem"]
for k in range(4):
    ang = 45 + 90*k; c = HC + np.array((1.42*np.cos(np.radians(ang)), 1.42*np.sin(np.radians(ang)), 0))
    a(f"BiTab{k+1}","Torso","gold",tuple(c),(0.42,0.42,0.4),eul(rz=ang)); BI.append(f"BiTab{k+1}")
# ---------- голова: золотий обруч з драконячими ріжками ----------
a("Head","Head","jade",(0,11.15,0.5014),(4.0,2.7,3.4))
a("Crown","Head","jadeDark",(0,12.72,0.38),(4.3,0.5,3.6))
a("Circlet","Head","gold",(0,12.38,0.5),(4.2,0.4,3.6))
a("CircletGem","Head","glow",(0,12.38,2.33),(0.5,0.5,0.14),eul(rz=45))
a("Horn_R","Head","gold",(1.5,13.35,0.0),(0.34,1.1,0.34),eul(rz=-28,rx=-12),mirror=True)
a("Ruyi","Head","gold",(0,13.12,0.9),(0.9,0.3,0.6))
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","glow",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.06,2.25),(1.2,0.26,0.3),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.24,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.5,2.3014),(1.1,0.24,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.22,0.5),mirror=True)
# ---------- руки: наплічники з хмарами, золоті наручі ----------
a("Shoulder_R","UpperArm_R","jade",(5.0,9.85,-0.3),(3.4,1.9,3.6),eul(rz=3),mirror=True)
a("Pauldron_R","UpperArm_R","jadeDark",(5.15,10.95,-0.3),(3.6,0.45,3.8),eul(rz=3),mirror=True)
a("PauldronRim_R","UpperArm_R","gold",(5.1,10.62,-0.3),(3.56,0.24,3.76),eul(rz=3),mirror=True)
a("CloudA_R","UpperArm_R","gold",(6.72,9.8,0.1),(0.24,0.6,1.2),eul(rz=3),mirror=True)
a("CloudB_R","UpperArm_R","gold",(6.76,10.1,-0.55),(0.24,0.7,0.7),eul(rz=3),mirror=True)
a("UpperArm_R","UpperArm_R","jadeDark",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","jade",(5.55,5.75,0.0014),(2.9,2.4,3.0),eul(ry=-6),mirror=True)
a("Bracer_R","Forearm_R","gold",(5.55,6.55,0.0014),(3.1,0.4,3.2),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","jade",(5.65,3.45,0.1014),(3.6,2.7,3.6),eul(ry=6.875))
sub(fist,"Knuckles_R","gold",(0.15,0.3,1.85),(3.0,1.0,0.45))
sub(fist,"KnuckleGem_R","glow",(0.15,0.3,2.12),(0.42,0.42,0.2),eul(rz=45))
sub(fist,"Thumb_R","jade",(-1.9,0.1,1.05),(0.5,1.1,0.9),eul(rz=-6)); mir(4)

# ---------- кірка: золоті накладки, нефритові леза, смарагди з боків голови ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
P("Handle","jadeDark"); P("Grip","gold"); P("Band","gold"); P("Pommel","jade")
HD = P("Head","gold"); P("HeadRound","jade")
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n,"jade")
P("Back1","jadeLight"); P("Back2","jadeLight"); P("PickGlint","jadeLight")
for side, nm in ((1, "R"), (-1, "L")):
    sub(HD, f"HeadGemMount{nm}", "jadeDark", (0.86*side, 0, 0), (0.2, 0.9, 0.9), eul(rx=45))
    sub(HD, f"HeadGem{nm}", "glow", (0.96*side, 0, 0), (0.16, 0.5, 0.5), eul(rx=45))
pos, R, sz = PICK["Pick1"]
g.item("PickCollar", "Pickaxe", "gold", tuple(np.array(pos) + R @ np.array([0, 0, -0.55])), R, (sz[0] + 0.14, sz[1] + 0.14, 0.3))
sub(P("Pommel","jade") if False else g.blocks[[b["name"] for b in g.blocks].index("Pommel")], "PommelGem", "glow", (0, -0.36, 0), (0.4, 0.2, 0.4), eul(ry=45))
# ---------- меч: золота гарда-хмара, нефритове лезо зі золотим долом ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordPommel","gold"); S("SwordPommelTop","glow"); S("SwordGrip","jadeDark")
S("SwordCoil1","gold"); S("SwordCoil2","gold")
G = S("SwordGuard","gold")
sub(G,"GuardCloudR","gold",(0,0.32,1.55),(0.7,0.9,0.7),eul(rx=45))
sub(G,"GuardCloudL","gold",(0,0.32,-1.55),(0.7,0.9,0.7),eul(rx=45))
sub(G,"GuardGem","glow",(0,0.25,0),(1.0,0.36,0.46))
S("SwordBlade","jade"); S("SwordEdge","jadeLight"); S("SwordFuller","gold"); S("SwordTip","jade")

# ---------- ящик: лакована скриня, золото, нефритовий медальйон, драконячі ручки-кільця ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","lacquerDark",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","lacquerDark",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","lacquer",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","lacquer",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","lacquer",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","lacquer",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","gold",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","gold",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","gold",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","gold",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz_ in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz_ > 0 else 'B'}"
        B("Corner" + t, "lacquerDark", (1.87*sx, 1.035, 1.13*sz_), (0.5, 1.67, 0.5))
        B("CornerCap" + t, "gold", (1.87*sx, 0.45, 1.13*sz_), (0.62, 0.4, 0.62))
B("Medal","jade",(0,1.0,-1.2),(0.95,0.95,0.12))
B("MedalB","jade",(0,1.0,-1.2),(0.95,0.95,0.06),eul(rz=45))
B("MedalRing","gold",(0,1.0,-1.26),(0.5,0.5,0.14),eul(rz=45))
B("MedalGem","glow",(0,1.0,-1.33),(0.24,0.24,0.08),eul(rz=45))
for i, x in enumerate((-1.1, 1.1), 1):
    B(f"Cloud{i}","gold",(x,1.15,-1.18),(0.7,0.3,0.08)); B(f"CloudTop{i}","gold",(x,1.36,-1.18),(0.38,0.24,0.12))
for sx, nm in ((1, "R"), (-1, "L")):   # однакові драконячі ручки-кільця
    B("DragonPlate"+nm,"gold",(2.06*sx,1.3,0),(0.12,0.5,0.5))
    B("RingPost"+nm,"gold",(2.24*sx,1.3,0),(0.36,0.2,0.2))
    for j, (yy, zz, ang) in enumerate(((1.125,0.175,-45),(1.125,-0.175,45),(0.775,0.175,45),(0.775,-0.175,-45)), 1):
        B(f"Ring{j}{nm}","gold",(2.45*sx,yy,zz),(0.16 if j in (1,4) else 0.21,0.56,0.16),eul(rx=ang))

# ---------- рух: диск «бі» обертається ----------
g.fx.append(dict(kind="spin", parts=BI, pivot=tuple(HC), axis=(0, 0, 1), speed=0.7, states={"Walk": 1.4, "Run": 2.2, "Mine": 1.8}))

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    out = "/home/claude/jade/JadeGolemData.lua"
    g.export(out, [
        "-- Jade Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано jade_golem_generator.py.",
        "-- Скелет = Clay … (21 кістка). neon — світний смарагд. Pickaxe / Sword — у кулаці Fist_L. Box — лакована скриня (у стадах)."])
    s = open(out).read().replace(" bones={", " neon={glow=true},\n bones={", 1); open(out, "w").write(s)
