"""Кам'яний голем: скелет + анімації Idle / Walk / Run.

Запуск:  python golem_rig.py  ->  StoneGolem_Animated.glb
Бере блоки з golem_generator.py (з уже виправленим правилом 0,1) і жорстко
прив'язує кожен блок до однієї кістки (вага 1.0), тому блоки не деформуються.
Анімації зациклені: Idle 2,4 с, Walk 1,2 с, Run 0,7 с.
"""
import json, struct, math
import numpy as np
import golem_generator as G

FPS = 30

# ---- Кістки: (ім'я, батько, точка обертання у координатах моделі ДО зсуву) ----
BONES = [
    ("Root",       None,        (0, 0, 0)),
    ("Hips",       "Root",      (0, 5.2, 0)),
    ("Torso",      "Hips",      (0, 6.0, 0)),
    ("Head",       "Torso",     (0, 10.2, 0.6)),
    ("UpperArm_R", "Torso",     (4.9, 9.5, 0)),
    ("Forearm_R",  "UpperArm_R",(5.2, 7.0, 0.3)),
    ("UpperArm_L", "Torso",     (-4.9, 9.5, 0)),
    ("Forearm_L",  "UpperArm_L",(-5.2, 7.0, 0.3)),
    ("Thigh_R",    "Hips",      (1.8, 5.0, 0)),
    ("Shin_R",     "Thigh_R",   (1.9, 3.4, 0)),
    ("Thigh_L",    "Hips",      (-1.8, 5.0, 0)),
    ("Shin_L",     "Thigh_L",   (-1.9, 3.4, 0)),
]
# Кістки обличчя ставимо в центри блоків (після виправлення правила 0,1)
def _center(name):
    return tuple(next(b for b in G.blocks if b["name"] == name)["c"])
for side in ("R", "L"):
    BONES += [(f"Eye_{side}", "Head", _center(f"EyeWhite_{side}")),
              (f"Pupil_{side}", f"Eye_{side}", _center(f"Pupil_{side}")),
              (f"Brow_{side}", "Head", _center(f"Brow_{side}"))]
FACE_BONES = {n for n, _, _ in BONES if n.split("_")[0] in ("Eye", "Pupil", "Brow")}
BI = {n: i for i, (n, _, _) in enumerate(BONES)}
shift = np.array(G.shift)
WP = {n: np.array(p, float) + shift for n, _, p in BONES}  # світові позиції кісток

def bone_for(name):
    base, _, side = name.partition("_")
    s = side or ""
    if base in ("Foot", "Shin", "KneePlate"): return f"Shin_{s}"
    if base == "Thigh": return f"Thigh_{s}"
    if base == "Pelvis": return "Hips"
    if base in ("UpperArm",): return f"UpperArm_{s}"
    if base in ("Forearm", "ElbowPlate", "Fist", "Knuckles"): return f"Forearm_{s}"
    if base == "EyeWhite": return f"Eye_{s}"
    if base in ("Pupil", "EyeShine"): return f"Pupil_{s}"
    if base == "Brow": return f"Brow_{s}"
    if base in ("Head", "BrowRidge", "Jaw", "Mouth", "Cheek"): return "Head"
    return "Torso"  # Torso, Chest, CorePlate, Crystal, BackPlate*, Shoulder (наплічник лишається на корпусі)

# ---- Анімації (кути в радіанах, X — нахил вперед/назад) ----
def quat(x=0.0, y=0.0, z=0.0):
    def q(ax, a):
        s = math.sin(a/2); v = [0, 0, 0]; v[ax] = s; return np.array(v + [math.cos(a/2)])
    def mul(a, b):
        x1, y1, z1, w1 = a; x2, y2, z2, w2 = b
        return np.array([w1*x2+x1*w2+y1*z2-z1*y2, w1*y2-x1*z2+y1*w2+z1*x2,
                         w1*z2+x1*y2-y1*x2+z1*w2, w1*w2-x1*x2-y1*y2-z1*z2])
    return mul(q(2, z), mul(q(1, y), q(0, x)))

def pose_idle(p):
    s, c = math.sin(p), math.cos(p)
    return {
        "Hips": dict(t=(0, -0.08 + 0.08*c, 0)),
        "Torso": dict(r=(0.03*s, 0, 0)),
        "Head": dict(r=(-0.02*s, 0.05*math.sin(p), 0.04*math.sin(p + 1.2))),
        "UpperArm_R": dict(r=(0.05*math.sin(p + 0.6), 0, 0.04 + 0.02*s)),
        "UpperArm_L": dict(r=(0.05*math.sin(p + 0.6), 0, -0.04 - 0.02*s)),
        "Forearm_R": dict(r=(-0.12 - 0.04*s, 0, 0)),
        "Forearm_L": dict(r=(-0.12 - 0.04*s, 0, 0)),
        "Thigh_R": dict(r=(0, 0, 0)), "Thigh_L": dict(r=(0, 0, 0)),
        "Shin_R": dict(r=(0, 0, 0)), "Shin_L": dict(r=(0, 0, 0)),
    }

def pose_gait(p, leg, knee, arm, elbow, bob, lean, twist):
    s, c = math.sin(p), math.cos(p)
    return {
        "Hips": dict(t=(0, -bob*0.5 + bob*0.5*math.cos(2*p) - (0.35 if lean > 0.15 else 0), 0), r=(0, -twist*0.5*s, 0)),
        "Torso": dict(r=(lean, twist*s, 0.04*s)),
        "Head": dict(r=(-lean*0.6, -twist*0.8*s, -0.03*s)),
        "Thigh_R": dict(r=(-leg*s - lean*0.3, 0, 0)),
        "Thigh_L": dict(r=(leg*s - lean*0.3, 0, 0)),
        "Shin_R": dict(r=(knee*max(0.0, c) + 0.05, 0, 0)),
        "Shin_L": dict(r=(knee*max(0.0, -c) + 0.05, 0, 0)),
        "UpperArm_R": dict(r=(arm*s, 0, 0.06)),
        "UpperArm_L": dict(r=(-arm*s, 0, -0.06)),
        "Forearm_R": dict(r=(-elbow - 0.15*max(0.0, -s), 0, 0)),
        "Forearm_L": dict(r=(-elbow - 0.15*max(0.0, s), 0, 0)),
    }

# ---- Обличчя: окремий кліп Face, грає поверх Idle/Walk/Run (чіпає лише кістки очей і брів) ----
def _tri(t, at, close=0.07, open_=0.1):
    if at <= t < at + close: return (t - at) / close
    if at + close <= t < at + close + open_: return 1 - (t - at - close) / open_
    return 0.0
def _ease(t, a, b):
    x = min(1.0, max(0.0, (t - a) / (b - a))); return x*x*(3 - 2*x)
def pose_face(p):
    t = p / (2*math.pi) * 4.0
    blink = max(_tri(t, 1.2), _tri(t, 3.0), _tri(t, 3.25))
    look = 0.2*_ease(t, 1.6, 1.8) - 0.35*_ease(t, 2.4, 2.6) + 0.15*_ease(t, 3.4, 3.6)   # погляд вбік
    hmph = _ease(t, 0.3, 0.45) - _ease(t, 0.8, 1.0)                                      # «хмик»: брови сильніше вниз
    raise_ = abs(look)*0.6 - 0.06*blink - 0.08*hmph
    out = {}
    for side, sx in (("R", 1), ("L", -1)):
        out[f"Eye_{side}"] = dict(s=(1, 1 - 0.9*blink, 1))
        out[f"Pupil_{side}"] = dict(t=(look, -0.03*blink, 0))
        out[f"Brow_{side}"] = dict(t=(0, raise_, 0), r=(0, 0, sx*(0.15*hmph - 0.08*abs(look))))
    return out

CLIPS = {
    "Face": (4.0, pose_face),
    "Idle": (2.4, pose_idle),
    "Walk": (1.2, lambda p: pose_gait(p, leg=0.45, knee=0.7, arm=0.35, elbow=0.25, bob=0.18, lean=0.05, twist=0.08)),
    "Run":  (0.7, lambda p: pose_gait(p, leg=0.75, knee=1.2, arm=0.6, elbow=0.6, bob=0.35, lean=0.18, twist=0.12)),
}

# ---- Збирання GLB ----
buf = bytearray(); views, accs = [], []
def add(arr, typ, comp, target=None, mm=False):
    global buf
    while len(buf) % 4: buf += b"\0"
    off = len(buf); buf += arr.tobytes()
    v = dict(buffer=0, byteOffset=off, byteLength=arr.nbytes)
    if target: v["target"] = target
    views.append(v)
    a = dict(bufferView=len(views)-1, componentType=comp, count=len(arr), type=typ)
    if mm: a["min"] = np.atleast_1d(arr.min(0)).tolist(); a["max"] = np.atleast_1d(arr.max(0)).tolist()
    accs.append(a); return len(accs)-1

order = list(G.COLORS)
geo = {k: ([], [], [], []) for k in order}  # P, N, J, I
for b in G.blocks:
    P, N, I = G.block_geo(b)
    for t in range(0, len(I), 3):
        a_, b_, c_ = P[I[t]], P[I[t+1]], P[I[t+2]]
        if np.dot(np.cross(b_-a_, c_-a_), N[I[t]]) < 0: I[t+1], I[t+2] = I[t+2], I[t+1]
    g = geo[b["col"]]; base = sum(len(x) for x in g[0])
    g[0].append(P); g[1].append(N); g[2].append(np.full(len(P), BI[bone_for(b["name"])])); g[3].append(I + base)

prims = []
for k in order:
    P = np.vstack(geo[k][0]).astype(np.float32); N = np.vstack(geo[k][1]).astype(np.float32)
    J = np.zeros((len(P), 4), np.uint8); J[:, 0] = np.concatenate(geo[k][2])
    W = np.zeros((len(P), 4), np.float32); W[:, 0] = 1
    I = np.concatenate(geo[k][3]).astype(np.uint32)
    prims.append(dict(attributes=dict(POSITION=add(P, "VEC3", 5126, 34962, True), NORMAL=add(N, "VEC3", 5126, 34962),
                                      JOINTS_0=add(J, "VEC4", 5121, 34962), WEIGHTS_0=add(W, "VEC4", 5126, 34962)),
                      indices=add(I, "SCALAR", 5125, 34963), material=order.index(k)))

nodes = []
for n, parent, _ in BONES:
    local = WP[n] - (WP[parent] if parent else 0)
    nodes.append(dict(name=n, translation=[float(x) for x in local]))
for n, parent, _ in BONES:
    if parent:
        nodes[BI[parent]].setdefault("children", []).append(BI[n])
ibm = np.array([np.eye(4) for _ in BONES], np.float32)
for i, (n, _, _) in enumerate(BONES):
    m = np.eye(4); m[:3, 3] = -WP[n]; ibm[i] = m.T  # glTF — по стовпцях
ibm_acc = add(ibm.reshape(-1, 16), "MAT4", 5126)
mesh_node = len(nodes)
nodes.append(dict(name="StoneGolemMesh", mesh=0, skin=0))

animations = []
for clip, (T, fn) in CLIPS.items():
    fps = 60 if clip == "Face" else FPS  # кліпання коротке, тому обличчю потрібно більше кадрів
    n_frames = int(round(T * fps))
    times = np.linspace(0, T, n_frames + 1).astype(np.float32)
    t_acc = add(times, "SCALAR", 5126, mm=True)
    chans, samps = [], []
    poses = [fn(2*math.pi*t/T) for t in times]
    targets = sorted(FACE_BONES, key=BI.get) if clip == "Face" else [b for b, _, _ in BONES if b != "Root" and b not in FACE_BONES]
    for bone in targets:
        rots = np.array([quat(*pz.get(bone, {}).get("r", (0, 0, 0))) for pz in poses], np.float32)
        samps.append(dict(input=t_acc, output=add(rots, "VEC4", 5126), interpolation="LINEAR"))
        chans.append(dict(sampler=len(samps)-1, target=dict(node=BI[bone], path="rotation")))
        if any("t" in pz.get(bone, {}) for pz in poses):
            par = dict((n, pr) for n, pr, _ in BONES)[bone]
            base = WP[bone] - WP[par]
            tr = np.array([base + np.array(pz[bone].get("t", (0, 0, 0))) for pz in poses], np.float32)
            samps.append(dict(input=t_acc, output=add(tr, "VEC3", 5126), interpolation="LINEAR"))
            chans.append(dict(sampler=len(samps)-1, target=dict(node=BI[bone], path="translation")))
        if any("s" in pz.get(bone, {}) for pz in poses):
            sc_ = np.array([pz[bone].get("s", (1, 1, 1)) for pz in poses], np.float32)
            samps.append(dict(input=t_acc, output=add(sc_, "VEC3", 5126), interpolation="LINEAR"))
            chans.append(dict(sampler=len(samps)-1, target=dict(node=BI[bone], path="scale")))
    animations.append(dict(name=clip, channels=chans, samplers=samps))

materials = [dict(name=k, pbrMetallicRoughness=dict(baseColorFactor=G.hex2lin(v), metallicFactor=0.0,
                                                    roughnessFactor=0.85)) for k, v in G.COLORS.items()]
gltf = dict(asset=dict(version="2.0", generator="golem_rig.py"), scene=0,
            scenes=[dict(name="StoneGolem", nodes=[BI["Root"], mesh_node])], nodes=nodes,
            meshes=[dict(name="StoneGolem", primitives=prims)],
            skins=[dict(name="GolemRig", joints=list(range(len(BONES))), inverseBindMatrices=ibm_acc, skeleton=BI["Root"])],
            animations=animations, materials=materials, accessors=accs, bufferViews=views,
            buffers=[dict(byteLength=0)])
while len(buf) % 4: buf += b"\0"
gltf["buffers"][0]["byteLength"] = len(buf)
js = json.dumps(gltf, separators=(",", ":")).encode()
while len(js) % 4: js += b" "
glb = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(buf))
glb += struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(buf), 0x004E4942) + bytes(buf)
open("StoneGolem_Animated.glb", "wb").write(glb)
print(f"Кісток: {len(BONES)}, анімацій: {', '.join(CLIPS)}, розмір: {len(glb)//1024} КБ")
