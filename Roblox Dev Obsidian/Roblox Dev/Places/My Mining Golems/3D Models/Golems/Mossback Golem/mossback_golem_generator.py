# Mossback Golem: блоки тіла й предметів у форматі GolemData (скелет = Clay / Gravel Golem, 1 од. = 0,5 стада).
# Старий валун, зарослий мохом: моховий горб на спині, борода з моху, сонні очі, жовті квіточки (виняток: 7-й колір у тілі).
import numpy as np, itertools
from shapely.geometry import Polygon

D = np.pi / 180
def Rx(a): c, s = np.cos(a), np.sin(a); return np.array([[1,0,0],[0,c,-s],[0,s,c]])
def Ry(a): c, s = np.cos(a), np.sin(a); return np.array([[c,0,s],[0,1,0],[-s,0,c]])
def Rz(a): c, s = np.cos(a), np.sin(a); return np.array([[c,-s,0],[s,c,0],[0,0,1]])
def eul(rx=0, ry=0, rz=0): return Ry(ry*D) @ Rx(rx*D) @ Rz(rz*D)
M = np.diag([-1., 1, 1])

COLORS = dict(stone="#6e7769", moss="#5e8c35", mossL="#8db54a", flower="#f2d24b",
              light="#f1f5f8", dark="#1c2836", pink="#f2a0b4", dstone="#4a5148", pale="#a7ad9f")

BONES = [
 ("Root",None,(0,0,-0.2986)),("Hips","Root",(0,4.85,-0.2986)),("Torso","Hips",(0,5.6,-0.2986)),
 ("Head","Torso",(0,9.9,0.4514)),("UpperArm_R","Torso",(5.2,9.4,-0.2986)),("Forearm_R","UpperArm_R",(5.5,6.9,0.0014)),
 ("UpperArm_L","Torso",(-5.2,9.4,-0.2986)),("Forearm_L","UpperArm_L",(-5.5,6.9,0.0014)),
 ("Thigh_R","Hips",(2,4.6,-0.2986)),("Shin_R","Thigh_R",(2.1,3.15,-0.2986)),
 ("Thigh_L","Hips",(-2,4.6,-0.2986)),("Shin_L","Thigh_L",(-2.1,3.15,-0.2986)),
 ("Eye_R","Head",(0.85,11.4,2.1764)),("Pupil_R","Eye_R",(0.78,11.29,2.2764)),("Brow_R","Head",(0.9,12.25,2.2014)),
 ("Eye_L","Head",(-0.85,11.4,2.1764)),("Pupil_L","Eye_L",(-0.78,11.29,2.2764)),("Brow_L","Head",(-0.9,12.25,2.2014)),
 ("Mouth","Head",(0,10.48,2.3014)),("MouthCorner_R","Head",(0.5,10.58,2.3014)),("MouthCorner_L","Head",(-0.5,10.58,2.3014)),
]

blocks = []
def add(name, bone, col, pos, size, R=None, group=None, mirror=False):
    R = np.eye(3) if R is None else R
    b = dict(name=name, bone=bone, col=col, pos=np.array(pos, float), R=R, s=np.array(size, float), group=group)
    blocks.append(b)
    if mirror:
        blocks.append(dict(name=name[:-2] + "_L", bone=bone[:-2] + "_L" if bone.endswith("_R") else bone, col=col,
                           pos=np.array([-pos[0], pos[1], pos[2]], float), R=M @ R @ M, s=np.array(size, float), group=group))
    return b
def compose(parent, local, Rl=None):
    Rl = np.eye(3) if Rl is None else Rl
    return parent["pos"] + parent["R"] @ np.array(local, float), parent["R"] @ Rl

# ---------- ноги ----------
add("Foot_R","Shin_R","stone",(2.15,0.5,0.15),(3.1,1.0,3.6),eul(ry=6),mirror=True)
add("FootMoss_R","Shin_R","moss",(2.3,1.05,1.0),(1.7,0.3,1.4),eul(ry=12),mirror=True)
add("Shin_R","Shin_R","stone",(2.1,2.15,-0.2),(2.5,2.4,2.5),eul(ry=4),mirror=True)
add("ShinMoss_R","Shin_R","moss",(2.95,2.55,0.75),(0.5,1.3,0.45),eul(rz=-8),mirror=True)
add("Thigh_R","Thigh_R","stone",(2.0,3.95,-0.25),(2.7,1.7,2.7),eul(ry=-6),mirror=True)
add("KneeMoss_R","Shin_R","mossL",(2.3,3.35,1.1),(1.4,0.5,0.6),eul(ry=8,rz=10),mirror=True)
add("Pelvis","Hips","stone",(0,4.85,-0.4),(5.8,1.6,3.4))
# ---------- корпус ----------
add("Torso","Torso","stone",(0,7.4,-0.3),(7.0,4.0,4.0))
add("Chest","Torso","stone",(0,9.4,-0.45),(7.8,1.8,4.5))
add("ChestMoss1","Torso","moss",(-1.7,8.95,1.93),(1.8,1.1,0.4),eul(rz=8))
add("ChestMoss2","Torso","mossL",(1.9,6.6,1.8),(1.2,0.8,0.4),eul(rz=-10))
# моховий горб
add("HumpBase","Torso","moss",(0,8.0,-2.75),(7.2,4.6,1.4),eul(rx=-8))
add("HumpTop","Torso","moss",(0,10.25,-2.2),(6.6,1.4,3.6),eul(rx=10))
add("HumpLayer2","Torso","mossL",(0.3,9.0,-3.6),(5.2,3.2,0.6),eul(rx=-8,ry=4))
add("HumpLayer3","Torso","moss",(-0.2,9.7,-4.05),(3.4,1.8,0.5),eul(rx=-8,rz=6))
add("HumpLow","Torso","moss",(0,6.05,-2.65),(6.2,1.4,1.0),eul(rx=6))
add("Flower1","Torso","flower",(1.6,11.1,-2.4),(0.4,0.4,0.4),eul(ry=45))
add("Flower2","Torso","flower",(-2.0,8.3,-3.45),(0.4,0.4,0.4),eul(rz=45))
add("Flower3","Torso","flower",(0.9,10.2,-4.35),(0.35,0.35,0.35),eul(rz=30))
# ---------- голова ----------
add("Head","Head","stone",(0,11.15,0.5014),(3.8,2.7,3.4))
add("Jaw","Head","stone",(0,10.1,0.8014),(3.3,0.8,3.0))
add("HeadMoss","Head","mossL",(0,12.65,0.3),(4.0,0.6,3.6))
add("HeadMoss2","Head","moss",(-0.5,13.1,0.0),(2.4,0.5,2.2),eul(ry=15))
add("Flower4","Head","flower",(0.75,13.15,0.55),(0.35,0.35,0.35),eul(ry=30))
add("Beard","Head","moss",(0,9.75,1.85),(2.4,0.9,0.6))
add("Beard2","Head","mossL",(0.2,9.2,1.98),(1.4,0.75,0.5),eul(rz=6))
# обличчя: сонні повіки поверх очей, м'які брови, лагідна усмішка
add("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
add("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
add("EyeShine_R","Pupil_R","light",(0.64,11.42,2.3764),(0.18,0.165,0.25),mirror=True)
add("Lid_R","Head","stone",(0.85,11.82,2.35),(1.32,0.5,0.25),mirror=True)
add("Brow_R","Brow_R","dark",(0.9,12.25,2.27),(1.2,0.28,0.3),eul(rz=-7),mirror=True)
add("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
add("Mouth","Mouth","dark",(0,10.48,2.3014),(0.8,0.24,0.3))
add("MouthCorner_R","MouthCorner_R","dark",(0.5,10.58,2.3014),(0.26,0.24,0.5))
add("MouthCorner_L","MouthCorner_L","dark",(-0.5,10.58,2.3014),(0.26,0.24,0.5))
# ---------- руки ----------
add("Shoulder_R","UpperArm_R","stone",(5.0,9.8,-0.3),(3.2,1.8,3.4),eul(rz=-6),mirror=True)
add("ShoulderMoss_R","UpperArm_R","moss",(5.1,10.85,-0.5),(3.0,0.6,3.2),eul(rz=-6),mirror=True)
add("ShoulderMoss2_R","UpperArm_R","mossL",(5.4,11.25,-0.7),(1.8,0.4,1.8),eul(ry=15,rz=-6),mirror=True)
add("UpperArm_R","UpperArm_R","stone",(5.25,8.0,-0.3),(2.4,2.6,2.5),eul(ry=4),mirror=True)
add("Forearm_R","Forearm_R","stone",(5.55,5.75,0.0014),(2.7,2.4,2.8),eul(ry=-6),mirror=True)
add("ElbowMoss_R","Forearm_R","moss",(6.9,6.55,-0.5),(0.4,1.4,0.9),eul(rz=6),mirror=True)
fist = add("Fist_R","Forearm_R","stone",(5.65,3.45,0.1014),(3.2,2.5,3.2),eul(ry=6.875),mirror=True)
for nm, col, loc, sz, rl in [("FistMoss_R","moss",(0.3,1.35,-0.2),(2.2,0.35,2.0),eul(ry=10)),
                             ("Thumb_R","stone",(-1.7,0.1,1.0),(0.5,1.1,0.9),eul(rz=-6))]:
    p, R = compose(fist, loc, rl)
    add(nm, "Forearm_R", col, tuple(p), sz, R, mirror=True)

# ---------- предмети (у кулаці Fist_L, хвати як у Clay / Gravel) ----------
def R9(*r): return np.array(r).reshape(3,3)
A = R9(1,0,0,0,0.1215,-0.99259,0,0.99259,0.1215)
R45 = R9(0.70739,0,0.70683,0.70159,0.1215,-0.70215,-0.08588,0.99259,0.08594)
def item(name, grp, col, pos, R, s): return add(name, "Forearm_L", col, pos, s, R, group=grp)
H = item("Handle","Pickaxe","dstone",(-5.65,3.8388,3.2777),A,(0.65,9.2,0.65))
item("Grip","Pickaxe","stone",(-5.65,3.4257,-0.0971),R9(0.98007,0,0.19867,0.1972,0.1215,-0.97281,-0.02414,0.99259,0.11907),(0.85,2.45,0.85))
item("Pommel","Pickaxe","stone",(-5.65,3.2495,-1.5364),R9(0.71091,0,0.70328,0.69807,0.1215,-0.70565,-0.08545,0.99259,0.08637),(1.05,0.65,1.05))
item("Band","Pickaxe","moss",(-5.65,3.8874,3.6747),R9(0.85252,0,0.52269,0.51882,0.1215,-0.84621,-0.0635,0.99259,0.10358),(0.8,0.4,0.8))
p, R = compose(H, (0, 2.2, 0), eul(ry=45)); item("HandleMoss","Pickaxe","mossL",tuple(p),R,(0.85,0.5,0.85))
HD = item("Head","Pickaxe","stone",(-5.65,4.4098,7.9429),A,(1.6,1.8,2.0))
item("HeadRound","Pickaxe","dstone",(-5.65,4.4159,7.9925),R45,(1.2,2.2,1.2))
p, R = compose(HD, (0, 0.15, 0)); item("HeadMoss","Pickaxe","moss",tuple(p),R,(1.8,0.55,2.2))
p, R = compose(HD, (-1.02, 0.15, 0.4), eul(rx=45)); item("HeadFlower","Pickaxe","flower",tuple(p),R,(0.3,0.35,0.35))
for nm, pos, r, s in [
    ("Pick1",(-5.65,2.8156,8.0876),(1,0,0,0,0.02179,-0.99976,0,0.99976,0.02179),(1.05,1.1,1.9)),
    ("Pick2",(-5.65,1.3159,8.1203),(1,0,0,0,-0.19691,-0.98042,0,0.98042,-0.19691),(0.85,0.85,1.6)),
    ("Pick3",(-5.65,0.1394,7.884),(1,0,0,0,-0.41524,-0.90971,0,0.90971,-0.41524),(0.62,0.62,1.3)),
    ("Pick4",(-5.65,-0.6338,7.5311),(1,0,0,0,-0.6274,-0.7787,0,0.7787,-0.6274),(0.42,0.42,0.9)),
    ("Back1",(-5.65,5.7437,7.7292),(1,0,0,0,0.21998,-0.9755,0,0.9755,0.21998),(1.05,1.05,1.4)),
    ("Back2",(-5.65,6.6705,7.5202),(1,0,0,0,0.49844,-0.86693,0,0.86693,0.49844),(0.85,0.75,1))]:
    item(nm, "Pickaxe", "stone" if nm.startswith("Back") else "pale", pos, R9(*r), s)
item("PickGlint","Pickaxe","light",(-5.65,2.8247,8.5075),R9(1,0,0,0,0.02179,-0.99976,0,0.99976,0.02179),(1.1,0.22,0.45))
item("Chip","Pickaxe","dstone",(-5.65,1.2273,8.5615),R9(1,0,0,0,-0.19691,-0.98042,0,0.98042,-0.19691),(0.7,0.2,0.5))
# меч
item("SwordPommel","Sword","dstone",(-5.65,3.1523,-2.3305),R45,(1,0.7,1))
item("SwordPommelTop","Sword","moss",(-5.65,3.207,-1.8838),R9(0.95534,0,0.29552,0.29333,0.1215,-0.94826,-0.0359,0.99259,0.11607),(0.75,0.34,0.75))
item("SwordGrip","Sword","dstone",(-5.65,3.4075,-0.246),A,(0.7,3.6,0.7))
item("SwordCoil1","Sword","moss",(-5.65,3.3164,-0.9905),R9(0.93768,-0.05996,0.34228,0.3472,0.12128,-0.92992,0.01425,0.99081,0.13454),(0.88,0.32,0.88))
item("SwordCoil2","Sword","moss",(-5.65,3.5047,0.548),R9(0.95362,0.05996,-0.29499,-0.30029,0.12128,-0.94611,-0.02096,0.99081,0.13366),(0.88,0.32,0.88))
G = item("SwordGuard","Sword","stone",(-5.65,3.6869,2.0369),R9(1,0,0,0,0.06176,-0.99809,0,0.99809,0.06176),(0.9,0.75,3))
p, R = compose(G, (0, 0.47, 0)); item("SwordGuardMoss","Sword","moss",tuple(p),R,(1.0,0.3,2.6))
p, R = compose(G, (-0.5, 0.35, 0.8), eul(rx=45)); item("SwordFlower","Sword","flower",tuple(p),R,(0.3,0.35,0.35))
BL = item("SwordBlade","Sword","stone",(-5.65,4.1304,5.6599),A,(0.45,6.6,1.6))
item("SwordEdge","Sword","pale",(-5.65,4.1486,5.8088),A,(0.3,6.1,1.95))
item("SwordFuller","Sword","dstone",(-5.65,4.0818,5.2629),A,(0.65,4.2,0.4))
p, R = compose(BL, (0, -2.55, 0)); item("BladeMoss","Sword","moss",tuple(p),R,(0.7,1.0,1.75))
p, R = compose(BL, (0, -1.75, 0.25), eul(rx=4)); item("BladeMoss2","Sword","mossL",tuple(p),R,(0.58,0.7,1.1))
item("SwordTip","Sword","pale",(-5.65,4.5738,9.2829),A,(0.36,0.95,0.9))

# ---------- правило 0,1 ----------
def faces(b):
    out = []
    for ax in range(3):
        n = b["R"][:, ax]
        for sg in (-1, 1):
            c = b["pos"] + sg * n * b["s"][ax] / 2
            o = [i for i in range(3) if i != ax]
            u, v = b["R"][:, o[0]] * b["s"][o[0]] / 2, b["R"][:, o[1]] * b["s"][o[1]] / 2
            out.append((sg * n, c, [c + a * u + bb * v for a, bb in ((1,1),(1,-1),(-1,-1),(-1,1))]))
    return out
def basis(n):
    a = np.array([1,0,0]) if abs(n[0]) < 0.9 else np.array([0,1,0])
    u = np.cross(n, a); u /= np.linalg.norm(u); return u, np.cross(n, u)
def check(group):
    bs = [b for b in blocks if b["group"] == group]; hits = []
    for b1, b2 in itertools.combinations(bs, 2):
        for n1, c1, q1 in faces(b1):
            for n2, c2, q2 in faces(b2):
                if abs(abs(n1 @ n2) - 1) > 1e-4 or abs(n1 @ (c2 - c1)) > 0.02: continue
                u, v = basis(n1)
                P1 = Polygon([(p @ u, p @ v) for p in q1]); P2 = Polygon([(p @ u, p @ v) for p in q2])
                if P1.intersection(P2).area > 1e-3: hits.append((b1["name"], b2["name"]))
    return sorted(set(hits))

if __name__ == "__main__":
    for g in (None, "Pickaxe", "Sword"):
        print(g or "Body", len([b for b in blocks if b["group"] == g]), "blocks; coplanar:", check(g))
    print("body colors", sorted({b["col"] for b in blocks if b["group"] is None}))
    allb = [b for b in blocks if b["group"] is None]
    lo = np.min([b["pos"] - np.abs(b["R"]) @ b["s"] / 2 for b in allb], 0); hi = np.max([b["pos"] + np.abs(b["R"]) @ b["s"] / 2 for b in allb], 0)
    print("bounds", lo.round(2), hi.round(2), "size", (hi - lo).round(2), "tris", 12 * len(allb))
    f = lambda x: f"{x:.5g}"
    L = ["-- Mossback Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано mossback_golem_generator.py.",
         "-- Скелет = Clay / Gravel Golem (21 кістка). Pickaxe / Sword — предмети в кулаці Fist_L (префаби MossbackPickaxe / MossbackSword).",
         "return {", " colors={" + ",".join(f'{k}="{v}"' for k, v in COLORS.items()) + "},", " bones={"]
    for n, p, pos in BONES:
        L.append(f'  {{name="{n}",parent={"nil" if p is None else chr(34)+p+chr(34)},pos=Vector3.new({",".join(f(x) for x in pos)})}},')
    L += [" },", " blocks={"]
    for b in blocks:
        cf = ",".join(f(x) for x in list(b["pos"]) + list(b["R"].flatten()))
        g = f'group="{b["group"]}",' if b["group"] else ""
        L.append(f'  {{name="{b["name"]}",{g}bone="{b["bone"]}",col="{b["col"]}",cf=CFrame.new({cf}),s=Vector3.new({",".join(f(x) for x in b["s"])})}},')
    L += [" },", "}"]
    open("/home/claude/mossback/MossbackGolemData.lua", "w").write("\n".join(L) + "\n")
