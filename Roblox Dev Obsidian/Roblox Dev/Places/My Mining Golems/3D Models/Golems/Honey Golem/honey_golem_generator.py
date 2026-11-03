# Honey Golem (Exclusive, тижнева нагорода — 14-й день Daily, Miner 65 % best; рівень Mushroom): медовий голем-бджола.
# Бурштинове тіло з темними смугами, соти на грудях, бочонок меду на спині, вусики на голові; над плечем ширяє бджілка
# (вільна деталь: bob + sway, крильця напівпрозорі). Інструменти — шаблон у медових кольорах із краплями меду;
# ящик — вулик-скриня з сотами й однаковими ручками-планками. Скелет Clay.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(honey="#e3a33c", honeyDark="#9c5f20", wax="#f3d27a", stripe="#4a2f1a", wood="#c99a5b", woodDark="#5a3a20",
               wing="#e6f2ff", light="#fff4e6", dark="#1c2836", pink="#f2a0b4"),
          bones={"Mouth": (0,10.5,2.3014), "MouthCorner_R": (0.65,10.6,2.3014), "MouthCorner_L": (-0.65,10.6,2.3014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))

# ---------- ноги ----------
a("Foot_R","Shin_R","honeyDark",(2.2,0.55,0.2),(3.2,1.1,3.7),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","honey",(2.15,2.2,-0.2),(2.7,2.3,2.7),eul(ry=4),mirror=True)
a("ShinStripe_R","Shin_R","stripe",(2.15,2.45,-0.2),(2.8,0.5,2.8),eul(ry=4),mirror=True)
a("Thigh_R","Thigh_R","honeyDark",(2.0,4.0,-0.25),(2.8,1.7,2.8),eul(ry=-6),mirror=True)
a("Pelvis","Hips","stripe",(0,4.85,-0.3),(6.2,1.6,3.5))
a("Belt","Hips","honeyDark",(0,5.45,-0.3),(6.6,0.5,3.9))
# ---------- корпус: смуги, соти на грудях, бочонок меду на спині ----------
a("Torso","Torso","honey",(0,7.5,-0.3),(7.4,4.2,4.2))
a("TorsoStripe1","Torso","stripe",(0,6.55,-0.3),(7.6,0.6,4.4))
a("TorsoStripe2","Torso","stripe",(0,8.35,-0.3),(7.6,0.6,4.4))
a("Chest","Torso","honey",(0,9.6,-0.35),(8.6,1.6,4.7))
a("CombPlate","Torso","wax",(0,7.45,1.9),(2.6,1.15,0.3))
for i, x in enumerate((-0.75, 0, 0.75), 1):          # соти — три ромбики на восковій пластині
    a(f"CombCell{i}","Torso","honeyDark",(x,7.45,2.08),(0.46,0.46,0.2),eul(rz=45))
a("BarrelBody","Torso","wood",(0,7.6,-3.2),(2.6,2.8,1.6))
a("BarrelHoopTop","Torso","woodDark",(0,8.55,-3.2),(2.7,0.3,1.7))
a("BarrelHoopBot","Torso","woodDark",(0,6.65,-3.2),(2.7,0.3,1.7))
a("BarrelLid","Torso","honeyDark",(0,9.1,-3.2),(2.3,0.3,1.3))
a("HoneyDrip","Torso","honey",(0.55,8.65,-4.08),(0.45,0.9,0.16))
# ---------- голова: смугаста шапочка, вусики ----------
a("Head","Head","honey",(0,11.15,0.5014),(4.0,2.7,3.4))
a("Crown","Head","stripe",(0,12.72,0.38),(4.3,0.5,3.6))
a("Antenna_R","Head","stripe",(0.75,13.45,0.4),(0.24,1.2,0.24),eul(rz=-22),mirror=True)
a("AntennaTip_R","Head","honeyDark",(1.0,14.05,0.4),(0.5,0.5,0.5),mirror=True)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","light",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.06,2.25),(1.2,0.26,0.3),mirror=True)   # рівні підняті брови + усмішка
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.24,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.5,2.3014),(1.1,0.24,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.22,0.5),mirror=True)
# ---------- руки ----------
a("Shoulder_R","UpperArm_R","honey",(5.0,9.85,-0.3),(3.4,1.9,3.6),eul(rz=3),mirror=True)
a("Pauldron_R","UpperArm_R","stripe",(5.15,10.95,-0.3),(3.6,0.45,3.8),eul(rz=3),mirror=True)
a("UpperArm_R","UpperArm_R","honeyDark",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","honey",(5.55,5.75,0.0014),(2.9,2.4,3.0),eul(ry=-6),mirror=True)
a("Bracer_R","Forearm_R","wax",(5.55,6.55,0.0014),(3.1,0.4,3.2),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","honey",(5.65,3.45,0.1014),(3.6,2.7,3.6),eul(ry=6.875))
sub(fist,"Knuckles_R","honeyDark",(0.15,0.3,1.85),(3.0,1.0,0.45))
sub(fist,"Thumb_R","honey",(-1.9,0.1,1.05),(0.5,1.1,0.9),eul(rz=-6)); mir(3)
# ---------- бджілка над правим плечем (ширяє: bob + sway) ----------
BC = np.array([6.3, 13.4, 0.9])
BEE = [a("BeeBody","Torso","honey",tuple(BC),(0.7,0.62,0.95)),
       a("BeeStripe","Torso","stripe",tuple(BC + [0,0,-0.1]),(0.76,0.68,0.26)),
       a("BeeHead","Torso","stripe",tuple(BC + [0,0.02,0.62]),(0.5,0.5,0.4)),
       a("BeeWing_R","Torso","wing",tuple(BC + [0.42,0.46,-0.05]),(0.5,0.08,0.42),eul(rz=-25)),
       a("BeeWing_L","Torso","wing",tuple(BC + [-0.42,0.46,-0.05]),(0.5,0.08,0.42),eul(rz=25))]
BEE = [b["name"] for b in BEE]
g.free_parts = tuple(BEE)
g.fx.append(dict(kind="bob", parts=BEE, axis=(0, 1, 0), amp=0.22, speed=2.2))
g.fx.append(dict(kind="sway", parts=BEE, pivot=(5.2, 13.4, -0.3), axis=(0, 1, 0), amp=0.35, speed=1.3, states={"Walk": 1.4, "Run": 1.8}))
g.fx.append(dict(kind="sway", parts=["HoneyDrip"], pivot=(0.55, 9.1, -4.08), axis=(0, 0, 1), amp=0.06, speed=1.2))

# ---------- кірка: шаблон у медових кольорах, краплі меду з боків голови ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
P("Handle","woodDark"); P("Grip","stripe"); P("Band","wax"); P("Pommel","honeyDark")
HD = P("Head","honeyDark"); P("HeadRound","honey")
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n,"wax")
P("Back1","honey"); P("Back2","honey"); P("PickGlint","light")
for side, nm in ((1, "R"), (-1, "L")):
    sub(HD, f"HeadDrop{nm}", "honey", (0.9*side, -0.15, 0.25), (0.22, 0.55, 0.55), eul(rx=45))
    sub(HD, f"HeadStripe{nm}", "stripe", (0.88*side, 0.55, 0), (0.18, 0.3, 1.9))
# ---------- меч: шаблон, жало-лезо кольору воску, гарда з медовими краплями ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordPommel","honey"); S("SwordPommelTop","stripe"); S("SwordGrip","woodDark")
S("SwordCoil1","stripe"); S("SwordCoil2","stripe")
G = S("SwordGuard","honeyDark")
sub(G,"GuardDropR","honey",(0,0,1.25),(0.55,0.55,0.55),eul(rx=45))
sub(G,"GuardDropL","honey",(0,0,-1.25),(0.55,0.55,0.55),eul(rx=45))
S("SwordBlade","wax"); S("SwordEdge","light"); S("SwordFuller","honey"); S("SwordTip","wax")

# ---------- ящик: вулик-скриня (у стадах, півот = центр дна; -Z — зовнішній бік) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","woodDark",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","woodDark",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","wood",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","wood",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","wood",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","wood",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","honeyDark",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","honeyDark",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","honeyDark",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","honeyDark",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Corner" + t, "woodDark", (1.87*sx, 1.035, 1.13*sz), (0.5, 1.67, 0.5))
B("HiveBand","stripe",(0,0.55,-1.2),(3.2,0.3,0.12)); B("HiveBandF","stripe",(0,0.55,1.2),(3.2,0.3,0.12))
for i, (x, y) in enumerate(((-0.45, 1.4), (0.45, 1.4), (0, 1.08)), 1):   # соти — три ромбики назовні
    B(f"Comb{i}","wax",(x,y,-1.22),(0.46,0.46,0.14),eul(rz=45))
B("Entrance","dark",(0,0.98,1.2),(0.7,0.22,0.1))
for sx, nm in ((1, "R"), (-1, "L")):   # однакові ручки-планки
    B("HandlePostA"+nm,"woodDark",(2.2*sx,1.25,0.4),(0.5,0.22,0.22)); B("HandlePostB"+nm,"woodDark",(2.2*sx,1.25,-0.4),(0.5,0.22,0.22))
    B("HandleBar"+nm,"honey",(2.5*sx,1.25,0),(0.24,0.3,1.06))

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    out = "/home/claude/honey/HoneyGolemData.lua"
    g.export(out, [
        "-- Honey Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано honey_golem_generator.py.",
        "-- Скелет = Clay (21 кістка). alpha — крильця бджілки. fx — бджілка ширяє (bob + sway), крапля меду хитається. Box — вулик у стадах."])
    s = open(out).read().replace(" bones={", " alpha={wing=0.4},\n bones={", 1); open(out, "w").write(s)
