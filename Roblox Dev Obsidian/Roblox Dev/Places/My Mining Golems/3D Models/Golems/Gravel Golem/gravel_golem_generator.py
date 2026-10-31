# Gravel Golem: блоки тіла й предметів у форматі GolemData (скелет = Clay Golem, 1 од. = 0,5 стада).
import numpy as np, json, itertools
from shapely.geometry import Polygon

D = np.pi / 180
def Rx(a): c, s = np.cos(a), np.sin(a); return np.array([[1,0,0],[0,c,-s],[0,s,c]])
def Ry(a): c, s = np.cos(a), np.sin(a); return np.array([[c,0,s],[0,1,0],[-s,0,c]])
def Rz(a): c, s = np.cos(a), np.sin(a); return np.array([[c,-s,0],[s,c,0],[0,0,1]])
def eul(rx=0, ry=0, rz=0): return Ry(ry*D) @ Rx(rx*D) @ Rz(rz*D)
M = np.diag([-1., 1, 1])

COLORS = dict(main="#9c9389", gap="#5f5850", pebble="#c8bfb2", light="#f1f5f8",
              dark="#1c2836", pink="#f2a0b4", ochre="#b8834f")

BONES = [
 ("Root",None,(0,0,-0.2986)),("Hips","Root",(0,4.85,-0.2986)),("Torso","Hips",(0,5.6,-0.2986)),
 ("Head","Torso",(0,9.9,0.4514)),("UpperArm_R","Torso",(5.2,9.4,-0.2986)),("Forearm_R","UpperArm_R",(5.5,6.9,0.0014)),
 ("UpperArm_L","Torso",(-5.2,9.4,-0.2986)),("Forearm_L","UpperArm_L",(-5.5,6.9,0.0014)),
 ("Thigh_R","Hips",(2,4.6,-0.2986)),("Shin_R","Thigh_R",(2.1,3.15,-0.2986)),
 ("Thigh_L","Hips",(-2,4.6,-0.2986)),("Shin_L","Thigh_L",(-2.1,3.15,-0.2986)),
 ("Eye_R","Head",(0.85,11.4,2.1764)),("Pupil_R","Eye_R",(0.78,11.29,2.2764)),("Brow_R","Head",(0.9,12.4,2.2014)),
 ("Eye_L","Head",(-0.85,11.4,2.1764)),("Pupil_L","Eye_L",(-0.78,11.29,2.2764)),("Brow_L","Head",(-0.9,12.4,2.2014)),
 ("Mouth","Head",(0,10.46,2.3014)),("MouthCorner_R","Head",(0.6,10.6,2.3014)),("MouthCorner_L","Head",(-0.55,10.5,2.3014)),
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
add("Foot_R","Shin_R","gap",(2.1,0.45,0.25),(2.8,0.9,3.4),eul(ry=5),mirror=True)
add("Toe_R","Shin_R","pebble",(2.25,0.55,1.95),(1.6,0.8,1.0),eul(ry=20),mirror=True)
add("Heel_R","Shin_R","pebble",(1.9,0.75,-1.45),(1.1,0.8,0.8),eul(ry=-15,rz=8),mirror=True)
add("Shin_R","Shin_R","main",(2.1,2.05,-0.2),(2.3,2.4,2.3),eul(ry=4),mirror=True)
add("ShinPebble_R","Shin_R","pebble",(2.35,2.3,1.0),(1.0,0.8,0.5),eul(ry=10,rz=12),mirror=True)
add("ShinStone_R","Shin_R","gap",(1.6,1.55,0.95),(0.6,0.5,0.3),eul(rz=-20),mirror=True)
add("Thigh_R","Thigh_R","main",(2.0,3.95,-0.25),(2.5,1.7,2.5),eul(ry=-6),mirror=True)
add("KneePebble_R","Shin_R","pebble",(2.6,3.4,0.95),(0.8,0.6,0.5),eul(ry=25,rz=-15),mirror=True)
add("Pelvis","Hips","gap",(0,4.85,-0.3),(5.4,1.5,3.2))
# ---------- корпус ----------
add("Torso","Torso","main",(0,7.4,-0.3),(6.6,4.0,3.9))
add("Chest","Torso","main",(0,9.4,-0.35),(7.4,1.8,4.3))
add("HeartStone","Torso","pebble",(0.3,7.9,1.75),(1.7,1.5,0.6),eul(rz=6))
add("FrontPebble1","Torso","pebble",(-1.9,8.95,1.8),(1.2,0.9,0.5),eul(ry=8,rz=-10))
add("FrontPebble2","Torso","gap",(-1.6,6.6,1.75),(1.4,1.1,0.5),eul(ry=-6,rz=12))
add("FrontPebble3","Torso","main",(2.0,6.4,1.8),(1.5,1.2,0.6),eul(ry=10,rz=-8))
add("FrontPebble4","Torso","pebble",(1.9,9.65,1.92),(0.8,0.6,0.5),eul(rz=20))
add("Seam1","Torso","gap",(-0.9,7.5,1.72),(0.22,1.6,0.2),eul(rz=15))
add("Seam2","Torso","gap",(1.1,8.95,1.72),(1.3,0.22,0.2),eul(rz=-10))
add("BackPebble1","Torso","pebble",(1.5,9.0,-2.45),(1.6,1.1,0.6),eul(ry=-8,rz=10))
add("BackPebble2","Torso","gap",(-1.4,7.8,-2.4),(1.8,1.3,0.6),eul(rz=-12))
add("BackPebble3","Torso","main",(0.6,6.3,-2.4),(2.0,1.2,0.6),eul(ry=6,rz=5))
add("BackPebble4","Torso","pebble",(-1.9,9.75,-2.6),(0.9,0.7,0.5),eul(rz=25))
add("BackPebble5","Torso","pebble",(2.2,7.0,-2.35),(0.7,0.6,0.5),eul(rz=-20))
# ---------- голова ----------
add("Head","Head","main",(0,11.15,0.5014),(3.8,2.7,3.4))
add("Jaw","Head","main",(0,10.1,0.8014),(3.3,0.8,3.0))
add("HeadPile1","Head","pebble",(0.4,12.75,0.1),(2.4,0.8,2.2),eul(ry=25,rz=-5))
add("HeadPile2","Head","gap",(-0.6,13.3,-0.2),(1.2,0.7,1.1),eul(ry=-20,rz=10))
add("HeadPile3","Head","main",(0.7,13.5,0.3),(0.8,0.6,0.8),eul(ry=40,rz=15))
add("HeadSide","Head","pebble",(1.95,11.9,-0.3),(0.5,0.7,0.8),eul(rz=10))
# обличчя (як у Clay; брови насуплені всередину, усмішка набік)
add("EyeWhite_R","Eye_R","light",(0.85,11.4,2.1764),(1.2,1.25,0.25),mirror=True)
add("Pupil_R","Pupil_R","dark",(0.78,11.29,2.2764),(0.66,0.83,0.25),mirror=True)
add("EyeShine_R","Pupil_R","light",(0.64,11.5225,2.3764),(0.18,0.165,0.25),mirror=True)
add("Brow_R","Brow_R","gap",(0.9,12.4,2.2014),(1.3,0.32,0.3),eul(rz=10),mirror=True)
add("Cheek_R","Head","pink",(1.5375,10.75,2.2764),(0.525,0.26,0.25),mirror=True)
add("Mouth","Mouth","dark",(0.05,10.46,2.3014),(1.0,0.26,0.3))
add("MouthCorner_R","MouthCorner_R","dark",(0.6,10.6,2.3014),(0.3,0.26,0.5))
add("MouthCorner_L","MouthCorner_L","dark",(-0.55,10.5,2.3014),(0.3,0.26,0.5))
# ---------- руки ----------
add("Shoulder_R","UpperArm_R","main",(5.0,9.9,-0.3),(3.0,1.7,3.3),eul(rz=4),mirror=True)
add("ShoulderPebble_R","UpperArm_R","pebble",(5.3,10.95,-0.1),(1.6,0.8,1.5),eul(ry=20,rz=-8),mirror=True)
add("ShoulderStone_R","UpperArm_R","gap",(4.4,10.85,-1.0),(0.9,0.6,0.9),eul(ry=-15,rz=12),mirror=True)
add("ShoulderTop_R","UpperArm_R","main",(5.9,11.4,0.35),(0.6,0.5,0.6),eul(ry=35,rz=10),mirror=True)
add("UpperArm_R","UpperArm_R","main",(5.25,8.0,-0.3),(2.1,2.5,2.2),eul(ry=4),mirror=True)
add("ElbowPebble_R","Forearm_R","pebble",(6.4,6.9,-0.4),(0.6,0.8,0.9),eul(rz=15),mirror=True)
add("Forearm_R","Forearm_R","main",(5.55,5.75,0.0014),(2.4,2.3,2.6),eul(ry=-6),mirror=True)
add("ForearmStone_R","Forearm_R","gap",(5.6,6.1,1.36),(1.0,0.6,0.3),eul(rz=-12),mirror=True)
fist = add("Fist_R","Forearm_R","main",(5.65,3.45,0.1014),(3.0,2.4,3.0),eul(ry=6.875),mirror=True)
for nm, col, loc, sz, rl in [("Knuckles_R","pebble",(0.15,0.3,1.62),(2.5,0.9,0.4),None),
                             ("Thumb_R","gap",(-1.6,0.1,1.0),(0.5,1.1,0.9),eul(rz=-6)),
                             ("FistPebble_R","pebble",(1.58,-0.3,-0.4),(0.4,0.8,0.9),eul(rx=10))]:
    p, R = compose(fist, loc, rl)
    add(nm, "Forearm_R", col, tuple(p), sz, R, mirror=True)

# ---------- предмети (у кулаці Fist_L, ті самі хвати, що в Clay) ----------
def C(x,y,z,*r): return np.array([x,y,z]), np.array(r).reshape(3,3)
A = C(0,0,0,1,0,0,0,0.1215,-0.99259,0,0.99259,0.1215)[1]
def item(name, grp, col, cfp, R, s): return add(name, "Forearm_L", col, cfp, s, R, group=grp)
H = item("Handle","Pickaxe","gap",(-5.65,3.8388,3.2777),A,(0.65,9.2,0.65))
item("Grip","Pickaxe","main",(-5.65,3.4257,-0.0971),C(0,0,0,0.98007,0,0.19867,0.1972,0.1215,-0.97281,-0.02414,0.99259,0.11907)[1],(0.85,2.45,0.85))
item("Pommel","Pickaxe","ochre",(-5.65,3.2495,-1.5364),C(0,0,0,0.71091,0,0.70328,0.69807,0.1215,-0.70565,-0.08545,0.99259,0.08637)[1],(1.05,0.65,1.05))
item("Band","Pickaxe","ochre",(-5.65,3.8874,3.6747),C(0,0,0,0.85252,0,0.52269,0.51882,0.1215,-0.84621,-0.0635,0.99259,0.10358)[1],(0.8,0.4,0.8))
for i, y in enumerate([0.2, 2.2], 1):
    p, R = compose(H, (0, y, 0), eul(ry=45))
    item(f"HandleRing{i}", "Pickaxe", "pebble", tuple(p), R, (0.85, 0.35, 0.85))
HD = item("Head","Pickaxe","main",(-5.65,4.4098,7.9429),A,(1.6,1.8,2.0))
item("HeadRound","Pickaxe","gap",(-5.65,4.4159,7.9925),C(0,0,0,0.70739,0,0.70683,0.70159,0.1215,-0.70215,-0.08588,0.99259,0.08594)[1],(1.2,2.2,1.2))
item("HeadPebble","Pickaxe","ochre",(-5.0,4.1738,8.0725),C(0,0,0,0.9027,-0.31795,0.28989,0.24357,-0.1778,-0.95345,0.35469,0.93129,-0.08306)[1],(0.5,0.6,0.6))
p, R = compose(HD, (-0.88, 0.35, -0.3), eul(rz=15))
item("HeadPebble2", "Pickaxe", "pebble", tuple(p), R, (0.4, 0.55, 0.6))
for nm, pos, r, s in [
    ("Pick1",(-5.65,2.8156,8.0876),(1,0,0,0,0.02179,-0.99976,0,0.99976,0.02179),(1.05,1.1,1.9)),
    ("Pick2",(-5.65,1.3159,8.1203),(1,0,0,0,-0.19691,-0.98042,0,0.98042,-0.19691),(0.85,0.85,1.6)),
    ("Pick3",(-5.65,0.1394,7.884),(1,0,0,0,-0.41524,-0.90971,0,0.90971,-0.41524),(0.62,0.62,1.3)),
    ("Pick4",(-5.65,-0.6338,7.5311),(1,0,0,0,-0.6274,-0.7787,0,0.7787,-0.6274),(0.42,0.42,0.9)),
    ("Back1",(-5.65,5.7437,7.7292),(1,0,0,0,0.21998,-0.9755,0,0.9755,0.21998),(1.05,1.05,1.4)),
    ("Back2",(-5.65,6.6705,7.5202),(1,0,0,0,0.49844,-0.86693,0,0.86693,0.49844),(0.85,0.75,1))]:
    item(nm, "Pickaxe", "main" if nm.startswith("Back") else "pebble", pos, np.array(r).reshape(3,3), s)
item("PickGlint","Pickaxe","light",(-5.65,2.8247,8.5075),np.array((1,0,0,0,0.02179,-0.99976,0,0.99976,0.02179)).reshape(3,3),(1.1,0.22,0.45))
item("Chip","Pickaxe","gap",(-5.65,1.2273,8.5615),np.array((1,0,0,0,-0.19691,-0.98042,0,0.98042,-0.19691)).reshape(3,3),(0.7,0.2,0.5))
# меч
R45 = C(0,0,0,0.70739,0,0.70683,0.70159,0.1215,-0.70215,-0.08588,0.99259,0.08594)[1]
item("SwordPommel","Sword","ochre",(-5.65,3.1523,-2.3305),R45,(1,0.7,1))
item("SwordPommelTop","Sword","pebble",(-5.65,3.207,-1.8838),C(0,0,0,0.95534,0,0.29552,0.29333,0.1215,-0.94826,-0.0359,0.99259,0.11607)[1],(0.75,0.34,0.75))
item("SwordGrip","Sword","gap",(-5.65,3.4075,-0.246),A,(0.7,3.6,0.7))
item("SwordCoil1","Sword","pebble",(-5.65,3.3164,-0.9905),C(0,0,0,0.93768,-0.05996,0.34228,0.3472,0.12128,-0.92992,0.01425,0.99081,0.13454)[1],(0.88,0.32,0.88))
item("SwordCoil2","Sword","pebble",(-5.65,3.5047,0.548),C(0,0,0,0.95362,0.05996,-0.29499,-0.30029,0.12128,-0.94611,-0.02096,0.99081,0.13366)[1],(0.88,0.32,0.88))
G = item("SwordGuard","Sword","ochre",(-5.65,3.6869,2.0369),C(0,0,0,1,0,0,0,0.06176,-0.99809,0,0.99809,0.06176)[1],(0.9,0.75,3))
item("SwordGuardPebble","Sword","pebble",(-5.25,3.6869,2.0369),C(0,0,0,1,0,0,0,-0.61564,-0.78802,0,0.78802,-0.61564)[1],(0.45,0.55,0.55))
p, R = compose(G, (-0.4, 0, 1.0), eul(rx=30))
item("SwordGuardPebble2","Sword","pebble",tuple(p),R,(0.4,0.5,0.5))
p, R = compose(G, (-0.4, 0, -1.0), eul(rx=-25))
item("SwordGuardPebble3","Sword","ochre",tuple(p),R,(0.4,0.5,0.5))
BL = item("SwordBlade","Sword","main",(-5.65,4.1304,5.6599),A,(0.45,6.6,1.5))
item("SwordEdge","Sword","pebble",(-5.65,4.1486,5.8088),A,(0.3,6.1,1.85))
item("SwordFuller","Sword","gap",(-5.65,4.0818,5.2629),A,(0.65,4.2,0.4))
for i, y in enumerate([-1.6, 1.3], 1):
    p, R = compose(BL, (0, y, 0.15), eul(rx=4 * (-1) ** i))
    item(f"BladeSeam{i}", "Sword", "gap", tuple(p), R, (0.55, 0.18, 1.35))
item("SwordTip","Sword","pebble",(-5.65,4.5738,9.2829),A,(0.36,0.95,0.85))

# ---------- правило 0,1: співпадіння граней ----------
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
    bs = [b for b in blocks if b["group"] == group]
    hits = []
    for b1, b2 in itertools.combinations(bs, 2):
        for n1, c1, q1 in faces(b1):
            for n2, c2, q2 in faces(b2):
                if abs(abs(n1 @ n2) - 1) > 1e-4 or abs(n1 @ (c2 - c1)) > 0.02: continue
                u, v = basis(n1)
                P1 = Polygon([(p @ u, p @ v) for p in q1]); P2 = Polygon([(p @ u, p @ v) for p in q2])
                if P1.intersection(P2).area > 1e-3: hits.append((b1["name"], b2["name"]))
    return hits

if __name__ == "__main__":
    for g in (None, "Pickaxe", "Sword"):
        print(g or "Body", len([b for b in blocks if b["group"] == g]), "blocks; coplanar:", check(g))
    body_cols = sorted({b["col"] for b in blocks if b["group"] is None}); print("body colors", body_cols)
    allb = [b for b in blocks if b["group"] is None]
    lo = np.min([b["pos"] - np.abs(b["R"]) @ b["s"] / 2 for b in allb], 0); hi = np.max([b["pos"] + np.abs(b["R"]) @ b["s"] / 2 for b in allb], 0)
    print("bounds", lo.round(2), hi.round(2), "tris", 12 * len(allb))
    f = lambda x: f"{x:.5g}"
    L = ["-- Gravel Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано gravel_golem_generator.py.",
         "-- Скелет = Clay Golem (21 кістка). Pickaxe / Sword — предмети в кулаці Fist_L (префаби GravelPickaxe / GravelSword).",
         "return {", " colors={" + ",".join(f'{k}="{v}"' for k, v in COLORS.items()) + "},", " bones={"]
    for n, p, pos in BONES:
        L.append(f'  {{name="{n}",parent={"nil" if p is None else chr(34)+p+chr(34)},pos=Vector3.new({",".join(f(x) for x in pos)})}},')
    L += [" },", " blocks={"]
    for b in blocks:
        cf = ",".join(f(x) for x in list(b["pos"]) + list(b["R"].flatten()))
        g = f'group="{b["group"]}",' if b["group"] else ""
        L.append(f'  {{name="{b["name"]}",{g}bone="{b["bone"]}",col="{b["col"]}",cf=CFrame.new({cf}),s=Vector3.new({",".join(f(x) for x in b["s"])})}},')
    L += [" },", "}"]
    open("/home/claude/gravel/GravelGolemData.lua", "w").write("\n".join(L) + "\n")
    print("lua bytes", len("\n".join(L)))
