# Tinker Golem (Rare): заводна іграшка-механік — бірюзова емаль, латунні шестерні, темне залізо; ключ завода на спині, окуляри-гогли на лобі.
# Унікальні: кірка-ключ (гайковий ключ замість обуха, шестерня на голові), меч-шестерня (гарда — шестерня, зубці на обусі),
# ящик-скринька механіка (шестерні на фасаді, ключ завода збоку, залізні кутики). Скелет Clay.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(teal="#2f8f8a", brass="#d1a24a", iron="#3e3f46", light="#f1f5f8", dark="#1c2836", pink="#f2a0b4"))
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
def gear(name, bone, col, pos, s, t, axis="z", hub="iron", mirror=False, group=None, add=None):
    add = add or a
    if axis == "z": R0, R1, S0, S1, SH = eul(), eul(rz=45), (s, s, t), (s, s, t*0.8), (s*0.42, s*0.42, t*1.35)
    else:           R0, R1, S0, S1, SH = eul(), eul(rx=45), (t, s, s), (t*0.8, s, s), (t*1.35, s*0.42, s*0.42)
    nm = (lambda sfx: name[:-2] + sfx + "_R") if name.endswith("_R") else (lambda sfx: name + sfx)
    kw = {"group": group, "mirror": mirror} if add is a else {}
    add(nm("A"), bone, col, pos, S0, R0, **kw)
    add(nm("B"), bone, col, pos, S1, R1, **kw)
    add(nm("Hub"), bone, hub, pos, SH, R0, **kw)
# ---------- ноги ----------
a("Foot_R","Shin_R","iron",(2.15,0.5,0.15),(3.0,1.0,3.5),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","teal",(2.1,2.2,-0.2),(2.5,2.3,2.5),eul(ry=4),mirror=True)
a("Thigh_R","Thigh_R","teal",(2.0,3.95,-0.25),(2.6,1.7,2.6),eul(ry=-6),mirror=True)
gear("KneeGear_R","Shin_R","brass",(3.42,2.4,-0.2),1.3,0.3,axis="x",mirror=True)
a("Pelvis","Hips","iron",(0,4.85,-0.35),(5.8,1.6,3.4))
a("Belt","Hips","brass",(0,5.35,-0.35),(6.0,0.4,3.6))
a("Pouch_R","Hips","teal",(2.2,4.62,1.55),(1.3,1.0,0.6),mirror=True)
a("PouchFlap_R","Hips","brass",(2.2,5.05,1.88),(1.36,0.3,0.12),mirror=True)
# ---------- корпус: віконце з шестернями, ключ завода на спині ----------
a("Torso","Torso","teal",(0,7.4,-0.3),(7.0,4.0,4.0))
a("Chest","Torso","teal",(0,9.45,-0.4),(7.8,1.8,4.6))
a("Panel","Torso","iron",(0,7.4,1.85),(4.2,3.0,0.4))
gear("BigGear","Torso","brass",(-0.6,7.6,2.22),1.9,0.3)
gear("SmallGear","Torso","brass",(1.0,6.85,2.22),1.1,0.3)
for i, (x, y) in enumerate([(-1.75,8.6),(1.75,8.6),(-1.75,6.2),(1.75,6.2)], 1):
    a(f"Rivet{i}","Torso","brass",(x,y,2.12),(0.3,0.3,0.2))
a("KeyShaft","Torso","iron",(0,7.6,-2.9),(0.5,0.5,1.4))
a("KeyBar","Torso","brass",(0,7.6,-3.65),(0.6,0.6,0.4))
a("KeyBow_R","Torso","brass",(0.78,7.6,-3.65),(1.1,1.5,0.3),mirror=True)
# ---------- голова: окуляри-гогли й антена ----------
a("Head","Head","teal",(0,11.15,0.5014),(3.8,2.7,3.4))
a("Jaw","Head","iron",(0,10.0,0.7),(3.4,0.8,2.7))
a("Strap","Head","iron",(0,12.6,0.45),(4.0,0.5,3.6))
a("GoggleRim_R","Head","brass",(0.85,12.85,2.1),(1.3,1.1,0.5),mirror=True)
a("GoggleLens_R","Head","light",(0.85,12.85,2.42),(0.8,0.66,0.2),mirror=True)
a("GoggleBridge","Head","iron",(0,12.85,2.18),(0.5,0.3,0.3))
a("Antenna","Head","iron",(-0.9,13.4,-0.3),(0.25,1.2,0.25))
a("AntennaBall","Head","brass",(-0.9,14.2,-0.3),(0.55,0.55,0.55))
a("HeadBolt_R","Head","brass",(2.0,11.2,0.4),(0.4,0.7,0.7),mirror=True)
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","light",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.25,2.24),(1.2,0.3,0.3),eul(rz=-6),mirror=True)
a("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.46,2.3014),(1.1,0.28,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.26,0.5),mirror=True)
# ---------- руки ----------
a("Shoulder_R","UpperArm_R","teal",(5.0,9.85,-0.3),(3.2,1.8,3.4),eul(rz=4),mirror=True)
a("ShoulderPlate_R","UpperArm_R","brass",(5.1,10.88,-0.3),(3.3,0.4,3.5),eul(rz=4),mirror=True)
a("UpperArm_R","UpperArm_R","iron",(5.25,8.0,-0.3),(2.0,2.6,2.1),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","teal",(5.55,5.75,0.0014),(2.7,2.4,2.8),eul(ry=-6),mirror=True)
gear("ElbowGear_R","Forearm_R","brass",(6.98,6.2,0.0),1.25,0.3,axis="x",mirror=True)
a("Cuff_R","Forearm_R","brass",(5.55,4.75,0.0014),(2.9,0.36,3.0),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","iron",(5.65,3.45,0.1014),(3.2,2.4,3.2),eul(ry=6.875))
sub(fist,"Knuckles_R","brass",(0.15,0.3,1.62),(2.6,0.8,0.4))
sub(fist,"Thumb_R","iron",(-1.7,0.1,0.95),(0.5,1.0,0.9),eul(rz=-6)); mir(3)

# ---------- кірка-ключ: гайковий ключ замість обуха, шестерня на голові ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
HN = P("Handle","teal"); P("Grip","iron"); P("Pommel","brass"); P("Band","brass")
sub(HN,"Band2","brass",(0,1.6,0),(0.8,0.3,0.8))
HD = P("Head","iron",(1.5,1.7,1.9))
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n,"iron")
P("PickGlint","light")
def subg(name, col, local, s, t, Rl=np.eye(3)):
    sub(HD, name+"A", col, local, (t, s, s), Rl)
    sub(HD, name+"B", col, local, (t*0.8, s, s), Rl @ eul(rx=45))
    sub(HD, name+"Hub", "iron", local, (t*1.35, s*0.42, s*0.42), Rl)
subg("HeadGear", "brass", (1.0, 0, 0), 1.35, 0.3)
sub(HD,"DrillCollar","brass",(0,0,-1.2),(0.95,0.95,0.6))
sub(HD,"DrillBase","iron",(0,0,-1.6),(0.8,0.8,0.5),eul(rz=22.5))
for i, (w, z) in enumerate([(0.68,-1.98),(0.52,-2.36),(0.38,-2.72),(0.24,-3.04)], 1):
    sub(HD, f"Drill{i}", "iron" if i % 2 else "brass", (0, 0, z), (w, w, 0.46), eul(rz=45 * (i % 2) + 22.5 * i))
# ---------- меч-шестерня: гарда — шестерня, зубці на обусі ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordPommelTop","iron"); S("SwordGrip","teal")
SP = S("SwordPommel","brass")
S("SwordCoil1","brass"); S("SwordCoil2","brass")
G = S("SwordGuard","iron",(0.6,0.5,1.6))
sub(G,"GuardGearA","brass",(0,0,0),(0.5,2.3,2.3))
sub(G,"GuardGearB","brass",(0,0,0),(0.4,2.3,2.3),eul(rx=45))
BL = S("SwordBlade","iron",(0.45,6.6,1.5)); S("SwordEdge","light",(0.3,6.1,1.85)); S("SwordFuller","teal",(0.6,4.2,0.32))
for i, y in enumerate((-1.8, -0.6, 0.6, 1.8), 1):
    sub(BL, f"Cog{i}", "brass", (0, y, -0.85), (0.4, 0.45, 0.42))
S("SwordTip","iron")

# ---------- ящик-скринька механіка (у стадах, півот = центр дна; -Z — зовнішній бік у руках носія) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","iron",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","iron",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","teal",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","teal",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","teal",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","teal",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","brass",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","brass",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","brass",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","brass",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Bracket" + t, "iron", (1.87*sx, 1.035, 1.13*sz), (0.5, 1.67, 0.5))
gear("FrontGear","Box","brass",(-0.45,1.0,-1.22),1.0,0.3,add=lambda n,b,c,p,s,R: B(n,c,p,s,R))
gear("FrontGear2","Box","brass",(0.55,0.72,-1.22),0.62,0.3,add=lambda n,b,c,p,s,R: B(n,c,p,s,R))
for sx, nm in ((1, "R"), (-1, "L")):   # однакові латунні ручки з обох боків
    B("HandlePostA"+nm,"brass",(2.18*sx,1.2,0.35),(0.44,0.18,0.18)); B("HandlePostB"+nm,"brass",(2.18*sx,1.2,-0.35),(0.44,0.18,0.18))
    B("HandleBar"+nm,"brass",(2.45*sx,1.2,0),(0.2,0.26,1.0))
B("PlateBack","brass",(0,1.0,1.19),(1.4,0.6,0.14))

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    g.export("/home/claude/tinker/TinkerGolemData.lua", [
        "-- Tinker Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано tinker_golem_generator.py.",
        "-- Скелет = Clay … Quartzling (21 кістка). Pickaxe / Sword — у кулаці Fist_L. Box — власний ящик-скринька в стадах (півот = центр дна)."])
