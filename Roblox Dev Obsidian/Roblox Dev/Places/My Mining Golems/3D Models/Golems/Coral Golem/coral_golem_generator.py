# Coral Golem (Exclusive #1, рівень Rare): рифовий страж — піщаний камінь, рожевий корал, бірюзова вода.
# Коралові гілки на плечах, мушля-віяло на грудях, морські зірки на колінах, водорості на спині.
# Інструменти — шаблон, перефарбований у корал і пісок; мушлі на голові кірки; ящик — скриня з затонулого піратського корабля
# з однаковими ручками-канатами. Скелет Clay.
import sys; sys.path.insert(0, "/home/claude/tools")
from golemgen import *

g = Golem(dict(sand="#e3c48e", sandDark="#b08a58", coral="#ff7b86", coralDeep="#d9466a", sea="#36c2bb",
               light="#fff4e6", dark="#1c2836", wood="#7a5233", woodDark="#4b3220", iron="#3e4650"),
          bones={"Mouth": (0,10.5,2.3014), "MouthCorner_R": (0.65,10.6,2.3014), "MouthCorner_L": (-0.65,10.6,2.3014)})
a, sub = g.add, g.sub
def mir(n):
    for b in list(g.blocks[-n:]):
        g.blocks.append(dict(b, name=b["name"][:-2] + "_L", bone=b["bone"][:-2] + "_L" if b["bone"].endswith("_R") else b["bone"],
                             pos=np.array([-b["pos"][0], b["pos"][1], b["pos"][2]]), R=M @ b["R"] @ M))
def star(prefix, bone, col, c, r=0.42, arm=(0.3, 0.7, 0.22), mirror=False):
    # морська зірка: серцевина + 5 променів у площині XY (дивиться вперед, +Z)
    a(prefix + "Core" + ("_R" if mirror else ""), bone, col, c, (0.46, 0.46, arm[2] + 0.34), eul(rz=18), mirror=mirror)
    for k in range(5):
        R = eul(rz=72 * k)
        a(f"{prefix}Arm{k+1}" + ("_R" if mirror else ""), bone, col, tuple(np.array(c) + R @ np.array([0, r, 0.03 * k])), arm, R, mirror=mirror)

# ---------- ноги ----------
a("Foot_R","Shin_R","sandDark",(2.2,0.55,0.2),(3.2,1.1,3.7),eul(ry=5),mirror=True)
a("Shin_R","Shin_R","sand",(2.15,2.2,-0.2),(2.7,2.3,2.7),eul(ry=4),mirror=True)
star("Star", "Shin_R", "coral", (2.2,2.75,1.2), mirror=True)
a("Thigh_R","Thigh_R","sand",(2.0,4.0,-0.25),(2.8,1.7,2.8),eul(ry=-6),mirror=True)
a("Pelvis","Hips","sandDark",(0,4.85,-0.3),(6.2,1.6,3.5))
a("Belt","Hips","sea",(0,5.45,-0.3),(6.6,0.5,3.9))
a("Buckle","Hips","light",(0,5.45,1.7),(0.9,0.7,0.3),eul(rz=45))
# ---------- корпус: мушля-віяло на грудях, водорості на спині ----------
a("Torso","Torso","sand",(0,7.5,-0.3),(7.4,4.2,4.2))
a("Chest","Torso","sand",(0,9.6,-0.35),(8.6,1.6,4.7))
a("ChestBand","Torso","sandDark",(0,8.65,-0.3),(7.6,0.4,4.4))
SH = np.array([0, 6.7, 1.9])
a("ShellHinge","Torso","coralDeep",tuple(SH + [0,0.05,0.04]),(0.9,0.5,0.56))
for i, ang in enumerate((-56, -28, 0, 28, 56), 1):
    R = eul(rz=ang); L = 2.0 if ang == 0 else (1.85 if abs(ang) == 28 else 1.55)
    a(f"ShellRib{i}","Torso","light" if i % 2 else "coral",tuple(SH + R @ np.array([0, L/2, 0.03 * i])),(0.62, L, 0.3),R)
a("Pearl","Torso","light",tuple(SH + [0,0.65,0.22]),(0.4,0.4,0.3),eul(rz=45))
a("BackPlate","Torso","sandDark",(0,7.2,-2.45),(4.2,3.0,0.3))
for i, (x, ang, L) in enumerate([(-1.2, 8, 2.6), (0.0, -6, 3.0), (1.25, 10, 2.3)], 1):
    a(f"Weed{i}","Torso","sea",(x, 8.4 - L/2 + 0.6, -2.65),(0.42, L, 0.2),eul(rz=ang))
# ---------- голова: піщаний камінь, бірюзова пов'язка, кораловий чубчик ----------
a("Head","Head","sand",(0,11.15,0.5014),(4.0,2.7,3.4))
a("Crown","Head","sandDark",(0,12.72,0.38),(4.3,0.5,3.6))
a("HeadBand","Head","sea",(0,12.38,0.5),(4.2,0.4,3.6))
a("TuftBase","Head","coralDeep",(0,13.2,0.2),(0.6,0.6,0.6))
a("TuftC","Head","coral",(0,13.75,0.2),(0.4,1.0,0.4))
a("TuftR","Head","coral",(0.45,13.55,0.2),(0.36,0.8,0.36),eul(rz=-35))
a("TuftL","Head","coral",(-0.45,13.55,0.2),(0.36,0.8,0.36),eul(rz=35))
a("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
a("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
a("EyeShine_R","Pupil_R","light",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
a("Brow_R","Brow_R","dark",(0.9,12.06,2.25),(1.2,0.26,0.3),mirror=True)   # рівні підняті брови + усмішка — веселий вираз
a("Cheek_R","Head","coral",(1.5375,10.75,2.2764),(0.525,0.24,0.25),mirror=True)
a("Mouth","Mouth","dark",(0,10.5,2.3014),(1.1,0.24,0.3))
a("MouthCorner_R","MouthCorner_R","dark",(0.65,10.6,2.3014),(0.3,0.22,0.5),mirror=True)   # кутики вгору — усмішка
# ---------- руки: коралові гілки на наплічниках, мушлі-накладки ----------
a("Shoulder_R","UpperArm_R","sand",(5.0,9.85,-0.3),(3.4,1.9,3.6),eul(rz=3),mirror=True)
a("Pauldron_R","UpperArm_R","sandDark",(5.15,10.95,-0.3),(3.6,0.45,3.8),eul(rz=3),mirror=True)
a("CoralTrunk_R","UpperArm_R","coralDeep",(5.3,11.75,-0.7),(0.5,1.3,0.5),eul(rz=-8),mirror=True)
a("CoralBranchA_R","UpperArm_R","coral",(5.75,12.25,-0.7),(0.34,0.9,0.34),eul(rz=-45),mirror=True)
a("CoralBranchB_R","UpperArm_R","coral",(4.95,12.35,-0.7),(0.32,0.8,0.32),eul(rz=30),mirror=True)
a("CoralSprig_R","UpperArm_R","coral",(5.45,11.6,0.6),(0.34,0.9,0.34),eul(rx=25),mirror=True)
a("UpperArm_R","UpperArm_R","sandDark",(5.25,8.0,-0.3),(2.3,2.6,2.4),eul(ry=4),mirror=True)
a("Forearm_R","Forearm_R","sand",(5.55,5.75,0.0014),(2.9,2.4,3.0),eul(ry=-6),mirror=True)
a("Bracer_R","Forearm_R","sea",(5.55,6.55,0.0014),(3.1,0.4,3.2),eul(ry=-6),mirror=True)
a("Barnacle_R","Forearm_R","light",(6.95,5.6,0.6),(0.3,0.42,0.42),eul(ry=-6),mirror=True)
fist = a("Fist_R","Forearm_R","sand",(5.65,3.45,0.1014),(3.6,2.7,3.6),eul(ry=6.875))
sub(fist,"Knuckles_R","sandDark",(0.15,0.3,1.85),(3.0,1.0,0.45))
sub(fist,"KnuckleShell_R","coral",(0.15,0.3,2.15),(0.5,0.5,0.3),eul(rz=45))
sub(fist,"Thumb_R","sand",(-1.9,0.1,1.05),(0.5,1.1,0.9),eul(rz=-6)); mir(4)

# ---------- кірка: шаблон у кораловому й піщаному, мушлі-віяла з обох боків голови ----------
P = lambda n, c, s=None: std_item(g, "Pickaxe", PICK, n, c, s)
P("Handle","wood"); P("Grip","sea"); P("Band","coral"); P("Pommel","sandDark")
HD = P("Head","sandDark"); P("HeadRound","sand")
for n in ("Pick1","Pick2","Pick3","Pick4"): P(n,"coral")
P("Back1","coralDeep"); P("Back2","coralDeep"); P("PickGlint","light")
for side, nm in ((1, "R"), (-1, "L")):   # мушля-віяло на боці голови: шарнір унизу, 5 ребер розходяться догори (−Z голови)
    base = np.array([0.86*side, 0, 0.62])
    sub(HD, f"ShellHinge{nm}", "coralDeep", tuple(base + [0.12*side, 0, 0.05]), (0.5, 0.5, 0.3))
    for i, (ang, L) in enumerate(((-46, 0.95), (-23, 1.12), (0, 1.25), (23, 1.12), (46, 0.95)), 1):
        R = eul(rx=ang)
        sub(HD, f"ShellRib{i}{nm}", "light" if i % 2 else "coral", tuple(base + [0.03*i*side, 0, 0] + R @ np.array([0, 0, -L/2])), (0.2, 0.36, L), R)
# ---------- меч: шаблон, коралові відростки на гарді, бірюзове лезо з піщаною кромкою ----------
S = lambda n, c, s=None: std_item(g, "Sword", SWORD, n, c, s)
S("SwordPommel","coralDeep"); S("SwordPommelTop","light"); S("SwordGrip","wood")
S("SwordCoil1","sea"); S("SwordCoil2","sea")
G = S("SwordGuard","sandDark")
sub(G,"GuardCoralR","coral",(0,0.55,1.3),(0.4,0.9,0.36),eul(rx=-25))
sub(G,"GuardCoralL","coral",(0,0.55,-1.3),(0.4,0.9,0.36),eul(rx=25))
sub(G,"GuardShell","light",(0,0,0),(1.0,0.5,0.5),eul(rx=45))
S("SwordBlade","sea"); S("SwordEdge","light"); S("SwordFuller","coral"); S("SwordTip","sea")

# ---------- ящик: скриня з затонулого піратського корабля (у стадах, півот = центр дна; -Z — зовнішній бік) ----------
def B(name, col, pos, size, R=None): return g.add(name, "Box", col, pos, size, R, group="Box")
B("Bottom","woodDark",(0,0,0),(4.3,0.34,2.4))
B("FloorRaised","wood",(0,0.6,0),(3.36,1.05,1.66))
B("WallF","wood",(0,0.98,1.0),(3.6,1.7,0.3)); B("WallB","wood",(0,0.98,-1.0),(3.6,1.7,0.3))
B("WallR","wood",(1.85,0.98,0),(0.3,1.7,1.66)); B("WallL","wood",(-1.85,0.98,0),(0.3,1.7,1.66))
B("RimF","woodDark",(0,1.9,1.0),(4.1,0.24,0.44)); B("RimB","woodDark",(0,1.9,-1.0),(4.1,0.24,0.44))
B("RimR","woodDark",(1.88,1.9,0),(0.4,0.24,1.5)); B("RimL","woodDark",(-1.88,1.9,0),(0.4,0.24,1.5))
for sx in (1, -1):
    for sz in (1, -1):
        t = f"{'R' if sx > 0 else 'L'}{'F' if sz > 0 else 'B'}"
        B("Corner" + t, "iron", (1.87*sx, 1.035, 1.13*sz), (0.5, 1.67, 0.5))
for i, x in enumerate((-0.95, 0.95), 1):   # залізні смуги-обручі
    B(f"StrapB{i}","iron",(x,0.95,-1.2),(0.34,1.5,0.12)); B(f"StrapF{i}","iron",(x,0.95,1.2),(0.34,1.5,0.12))
B("Lock","iron",(0,1.3,-1.22),(0.6,0.7,0.14)); B("Keyhole","dark",(0,1.25,-1.3),(0.14,0.3,0.06))
B("Plank","woodDark",(0,0.62,-1.18),(1.56,0.12,0.08))
B("Barnacle1","light",(-1.4,0.5,-1.22),(0.3,0.3,0.18)); B("Barnacle2","light",(1.4,1.55,-1.22),(0.26,0.26,0.16))
B("CoralBase","coralDeep",(-1.42,1.25,-1.24),(0.3,0.3,0.2))
B("CoralSprig","coral",(-1.42,1.55,-1.24),(0.2,0.5,0.14),eul(rz=-20))
B("Weed","sea",(1.42,0.75,-1.22),(0.2,0.9,0.12),eul(rz=8))
for sx, nm in ((1, "R"), (-1, "L")):   # однакові ручки-канати
    B("RopePostA"+nm,"sand",(2.18*sx,1.2,0.35),(0.44,0.2,0.2)); B("RopePostB"+nm,"sand",(2.18*sx,1.2,-0.35),(0.44,0.2,0.2))
    B("RopeBar"+nm,"sand",(2.45*sx,1.2,0),(0.22,0.26,0.96))
    B("RopeKnot"+nm,"sandDark",(2.45*sx,1.2,0),(0.3,0.34,0.3))

if __name__ == "__main__":
    g.report(); print("Box", len([b for b in g.blocks if b["group"]=="Box"]), "blocks; coplanar:", g.check("Box"))
    g.export("/home/claude/coral/CoralGolemData.lua", [
        "-- Coral Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано coral_golem_generator.py.",
        "-- Скелет = Clay … Tinker (21 кістка). Pickaxe / Sword — у кулаці Fist_L. Box — власна скриня з затонулого корабля (півот = центр дна)."])
