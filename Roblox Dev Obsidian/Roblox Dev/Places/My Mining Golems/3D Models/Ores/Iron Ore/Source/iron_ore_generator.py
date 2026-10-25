"""Залізна руда v2 — генератор блокової моделі за GDD «Блоковий стиль моделей»
з розділом «Повороти для округлення і живості».

Запуск:  python iron_ore_generator.py  ->  IronOre.glb, iron_ore_report.txt, iron_ore_blocks.json
Осі: X — вправо, Y — вгору, Z — вперед (лицьовий бік дивиться в +Z). 1 од. = 0,5 стада.

Кожен блок задається в системі координат батька (parent): центр c, розмір s, поворот.
Поворот: rot=(rx, ry, rz) у радіанах (R = Rz·Ry·Rx) або готова матриця R.
Жили руди кріпляться до грані батьківського блока і повертаються навколо нормалі цієї грані,
тому лишаються «прилиплими» до повернутої маси.
"""
import json, struct, math
import numpy as np

COLORS = {
    "stone":    "#7f8a96",  # основний: камінь
    "stone_dk": "#5f6974",  # темніший акцент: основа, плити
    "ore":      "#d08a55",  # залізна руда
    "ore_dk":   "#9a5a36",  # серцевина руди
    "light":    "#f1f5f8",  # спільний світлий: блиск
}

def Rx(a): c, s = math.cos(a), math.sin(a); return np.array([[1,0,0],[0,c,-s],[0,s,c]])
def Ry(a): c, s = math.cos(a), math.sin(a); return np.array([[c,0,s],[0,1,0],[-s,0,c]])
def Rz(a): c, s = math.cos(a), math.sin(a); return np.array([[c,-s,0],[s,c,0],[0,0,1]])
def E(rx=0.0, ry=0.0, rz=0.0): return Rz(rz) @ Ry(ry) @ Rx(rx)

blocks, by_name = [], {}

def B(name, c, s, col, rot=(0, 0, 0), R=None, parent=None):
    Rl = R if R is not None else E(*rot)
    if parent:
        p = by_name[parent]
        Rw = p["R"] @ Rl; cw = p["cw"] + p["R"] @ np.array(c, float)
    else:
        Rw = Rl; cw = np.array(c, float)
    b = dict(name=name, s=np.array(s, float), col=col, R=Rw, cw=cw, parent=parent)
    blocks.append(b); by_name[name] = b
    return b

# орієнтація «локальна +Z → нормаль грані»
FACE_ORIENT = {"+z": E(), "-z": E(ry=math.pi), "+x": E(ry=math.pi/2), "-x": E(ry=-math.pi/2), "+y": E(rx=-math.pi/2)}
FACE_AXIS = {"+z": (2, 1), "-z": (2, -1), "+x": (0, 1), "-x": (0, -1), "+y": (1, 1)}

def on_face(parent, face, uv, size, col, name, spin=0.0, protrude=0.35):
    """Блок товщиною size[2], що сидить на грані face батька і виступає на protrude."""
    p = by_name[parent]; ax, sg = FACE_AXIS[face]; O = FACE_ORIENT[face]
    t = size[2]
    c = np.zeros(3); c[ax] = sg * (p["s"][ax]/2 + protrude - t/2)
    c = c + O @ np.array([uv[0], uv[1], 0.0])
    return B(name, c, size, col, R=O @ Rz(spin), parent=parent)

def vein(name, parent, face, uv, w, h, spin, t=0.6):
    v = on_face(parent, face, uv, (w, h, t), "ore", name, spin)
    B(name + "Core", (-0.15*w, -0.15*h, 0.2), (0.5*w, 0.5*h, t), "ore_dk", rot=(0, 0, 0.25), parent=name)
    B(name + "Glint", (0.28*w, 0.28*h, t/2 + 0.1), (0.35, 0.35, 0.4), "light", rot=(0, 0, math.pi/4), parent=name)

# --- Маси: кожна має «округлювач» — той самий блок, повернутий навколо Y ---
B("Base",       (0.0, 0.75, 0.0),   (8.2, 1.5, 6.4), "stone_dk", rot=(0, 0.08, 0))
B("BaseRound",  (0.0, 0.70, 0.0),   (6.0, 1.0, 6.0), "stone_dk", rot=(0, 0.08 + 0.62, 0))
B("Body",       (-0.2, 2.65, -0.1), (6.8, 2.8, 5.4), "stone",    rot=(0, -0.10, 0))
B("BodyRound",  (-0.2, 2.55, -0.1), (5.2, 2.4, 5.2), "stone",    rot=(0, -0.10 + 0.70, 0))
B("Upper",      (-0.4, 4.55, -0.3), (4.8, 1.8, 4.0), "stone",    rot=(0, 0.22, 0.06))
B("UpperRound", (-0.4, 4.45, -0.3), (3.8, 1.5, 3.8), "stone",    rot=(0, 0.22 + 0.70, 0.06))
B("Cap",        (0.3, 5.85, -0.4),  (2.8, 1.2, 2.6), "stone",    rot=(0.12, 0.60, -0.10))
B("LumpL",      (-3.7, 1.9, 0.5),   (2.6, 2.6, 3.2), "stone",    rot=(0, 0.35, 0.18))
B("LumpR",      (3.8, 1.5, 0.9),    (2.4, 1.8, 2.8), "stone",    rot=(0, -0.40, -0.15))
B("LumpBack",   (0.9, 2.1, -3.0),   (3.6, 2.2, 1.8), "stone",    rot=(-0.12, 0.25, 0))

# --- Накладки темного каменю (трохи повернуті навколо нормалі) ---
on_face("Base",  "+z", (-1.0, 0.1), (3.2, 0.9, 0.5), "stone", "PlateFrontLow", spin=0.06)
on_face("Upper", "+x", (0.6, -0.1), (1.4, 1.1, 0.5), "stone_dk", "PlateSideR", spin=-0.2)
on_face("Upper", "+y", (1.0, -0.8), (1.4, 1.2, 0.4), "stone_dk", "PlateTop", spin=0.4, protrude=0.25)
on_face("LumpBack", "-z", (0.3, 0.2), (1.6, 1.0, 0.5), "stone_dk", "PlateBackL", spin=-0.3)

# --- Жили руди ---
vein("OreFrontA", "Body",  "+z", (0.9, 0.3),  2.4, 1.8, 0.35)
vein("OreFrontB", "Upper", "+z", (-1.2, 0.1), 1.6, 1.3, -0.45)
vein("OreFrontC", "LumpL", "+z", (0.0, 0.2),  1.3, 1.1, 0.6)
vein("OreFrontD", "LumpR", "+z", (0.2, 0.0),  1.1, 0.9, -0.3)
vein("OreSideL",  "LumpL", "-x", (0.3, 0.1),  1.6, 1.2, 0.25)
vein("OreSideR",  "Body",  "+x", (-0.6, 0.5), 1.6, 1.3, -0.5)
vein("OreTop",    "Cap",   "+y", (0.0, 0.0),  1.4, 1.2, 0.5, t=0.4)
vein("OreTopL",   "Upper", "+y", (-1.2, 1.0), 1.2, 1.0, -0.6, t=0.4)
vein("OreBack",   "Body",  "-z", (1.7, 0.4),  1.8, 1.4, 0.4)

# --- Камінці (лише поворот навколо Y, щоб не провалювались у землю) ---
B("Pebble1",   (4.0, 0.4, 3.6),   (1.2, 0.8, 1.0), "stone",    rot=(0, 0.5, 0))
B("Pebble2",   (-4.3, 0.35, -2.9),(0.9, 0.7, 0.9), "stone_dk", rot=(0, -0.6, 0))
B("PebbleOre", (2.7, 0.3, 4.1),   (0.7, 0.6, 0.7), "ore",      rot=(0, 0.9, 0))

# ---------- Правило 0,1 ----------
# Автоматично перевіряємо тільки пари блоків з однаковою орієнтацією (як у GDD:
# повернуті блоки перевіряються оком). Для них рахуємо в спільній локальній системі.
def same_R(a, b): return np.allclose(a["R"], b["R"], atol=1e-6)
def local_bounds(b, Rref):
    c = Rref.T @ b["cw"]; return c - b["s"]/2, c + b["s"]/2
def conflicts():
    out = []
    for i in range(len(blocks)):
        for j in range(i+1, len(blocks)):
            a, b = blocks[i], blocks[j]
            if not same_R(a, b): continue
            alo, ahi = local_bounds(a, a["R"]); blo, bhi = local_bounds(b, a["R"])
            if not all(alo[k] < bhi[k] and blo[k] < ahi[k] for k in range(3)): continue
            for k in range(3):
                if abs(alo[k]-blo[k]) < 0.1 - 1e-9 or abs(ahi[k]-bhi[k]) < 0.1 - 1e-9: out.append((a["name"], b["name"], k))
    return out
conf = conflicts()
rotated = [b["name"] for b in blocks if not np.allclose(b["R"], np.eye(3), atol=1e-6)]

# ---------- Геометрія ----------
UNIT = np.array([[x, y, z] for x in (-.5, .5) for y in (-.5, .5) for z in (-.5, .5)])
def corners(b): return (UNIT * b["s"]) @ b["R"].T + b["cw"]
allp = np.vstack([corners(b) for b in blocks])
mn, mx = allp.min(0), allp.max(0)
shift = np.array([-(mn[0]+mx[0])/2, -mn[1], -(mn[2]+mx[2])/2])

FACES = [((1,0,0),[(1,0,0),(1,1,0),(1,1,1),(1,0,1)]), ((-1,0,0),[(0,0,1),(0,1,1),(0,1,0),(0,0,0)]),
         ((0,1,0),[(0,1,0),(0,1,1),(1,1,1),(1,1,0)]), ((0,-1,0),[(0,0,1),(0,0,0),(1,0,0),(1,0,1)]),
         ((0,0,1),[(1,0,1),(1,1,1),(0,1,1),(0,0,1)]), ((0,0,-1),[(0,0,0),(0,1,0),(1,1,0),(1,0,0)])]
def hex2lin(h):
    rgb = [int(h[i:i+2], 16)/255 for i in (1, 3, 5)]
    return [c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4 for c in rgb] + [1.0]
def block_geo(b):
    P, N, I = [], [], []
    for n, quad in FACES:
        base = len(P)
        for q in quad:
            P.append(b["R"] @ ((np.array(q) - 0.5) * b["s"]) + b["cw"] + shift); N.append(b["R"] @ np.array(n, float))
        I += [base, base+1, base+2, base, base+2, base+3]
    P, N, I = np.array(P, np.float32), np.array(N, np.float32), np.array(I, np.uint32)
    for t in range(0, len(I), 3):
        a_, b_, c_ = P[I[t]], P[I[t+1]], P[I[t+2]]
        if np.dot(np.cross(b_-a_, c_-a_), N[I[t]]) < 0: I[t+1], I[t+2] = I[t+2], I[t+1]
    return P, N, I

order = list(COLORS)
buf = bytearray(); views, accs, meshes, nodes = [], [], [], []
def add(arr, target, typ, comp):
    global buf
    while len(buf) % 4: buf += b"\0"
    off = len(buf); buf += arr.tobytes()
    views.append(dict(buffer=0, byteOffset=off, byteLength=arr.nbytes, target=target))
    a = dict(bufferView=len(views)-1, componentType=comp, count=len(arr), type=typ)
    if typ == "VEC3": a["min"] = arr.min(0).tolist(); a["max"] = arr.max(0).tolist()
    accs.append(a); return len(accs)-1
for b in blocks:
    P, N, I = block_geo(b)
    pa = add(P, 34962, "VEC3", 5126); na = add(N, 34962, "VEC3", 5126); ia = add(I, 34963, "SCALAR", 5125)
    meshes.append(dict(name=b["name"], primitives=[dict(attributes=dict(POSITION=pa, NORMAL=na), indices=ia, material=order.index(b["col"]))]))
    nodes.append(dict(name=b["name"], mesh=len(meshes)-1))
materials = [dict(name=k, pbrMetallicRoughness=dict(baseColorFactor=hex2lin(v), metallicFactor=0.0, roughnessFactor=0.85)) for k, v in COLORS.items()]
nodes.append(dict(name="IronOre", children=list(range(len(blocks)))))
gltf = dict(asset=dict(version="2.0", generator="iron_ore_generator.py v2"), scene=0, scenes=[dict(nodes=[len(nodes)-1])],
            nodes=nodes, meshes=meshes, materials=materials, accessors=accs, bufferViews=views, buffers=[dict(byteLength=0)])
while len(buf) % 4: buf += b"\0"
gltf["buffers"][0]["byteLength"] = len(buf)
js = json.dumps(gltf, separators=(",", ":")).encode()
while len(js) % 4: js += b" "
glb = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(buf))
glb += struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(buf), 0x004E4942) + bytes(buf)
open("IronOre.glb", "wb").write(glb)

size = mx - mn
rep = (f"Блоків: {len(blocks)} (повернутих: {len(rotated)})\nТрикутників: {len(blocks)*12}\nКольорів: {len(COLORS)}\n"
       f"Правило 0,1 (пари з однаковою орієнтацією): збігів {len(conf)} {conf}\n"
       f"Розмір (од.): {size[0]:.2f} x {size[1]:.2f} x {size[2]:.2f}\n"
       f"Розмір (стади): {size[0]/2:.2f} x {size[1]/2:.2f} x {size[2]/2:.2f}\n")
open("iron_ore_report.txt", "w", encoding="utf-8").write(rep)
json.dump(dict(colors=COLORS, shift=shift.tolist(),
               blocks=[dict(name=b["name"], col=b["col"], s=b["s"].tolist(), c=(b["cw"]+shift).tolist(), R=b["R"].tolist()) for b in blocks]),
          open("iron_ore_blocks.json", "w"), ensure_ascii=False)
print(rep)
