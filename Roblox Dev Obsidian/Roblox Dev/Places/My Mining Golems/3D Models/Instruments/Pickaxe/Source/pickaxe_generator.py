"""Кірка — генератор блокової моделі за GDD «Блоковий стиль моделей» (з розділом про повороти).

Запуск:  python pickaxe_generator.py  ->  Pickaxe.glb, pickaxe_report.txt, pickaxe_blocks.json
Локальні осі кірки: +Y — уздовж держака (до голови), +Z — робоче лезо (дзьоб), X — товщина.
Точка опори (0,0,0) — місце хвату в кулаці. 1 од. = 0,5 стада.
Блоки задаються ієрархічно (parent), як у iron_ore_generator.py v2.
"""
import json, struct, math
import numpy as np

COLORS = {
    "wood":     "#a8754a",  # держак
    "wood_dk":  "#7a5233",  # обмотка, кільця
    "metal":    "#a3adb8",  # лезо
    "metal_dk": "#6e7884",  # голова, навершя
    "light":    "#f1f5f8",  # спільний світлий: блиск на лезі
}

def Rx(a): c, s = math.cos(a), math.sin(a); return np.array([[1,0,0],[0,c,-s],[0,s,c]])
def Ry(a): c, s = math.cos(a), math.sin(a); return np.array([[c,0,s],[0,1,0],[-s,0,c]])
def Rz(a): c, s = math.cos(a), math.sin(a); return np.array([[c,-s,0],[s,c,0],[0,0,1]])
def E(rx=0.0, ry=0.0, rz=0.0): return Rz(rz) @ Ry(ry) @ Rx(rx)

blocks, by_name = [], {}
def B(name, c, s, col, rot=(0, 0, 0), parent=None):
    Rl = E(*rot)
    if parent:
        p = by_name[parent]; Rw = p["R"] @ Rl; cw = p["cw"] + p["R"] @ np.array(c, float)
    else:
        Rw = Rl; cw = np.array(c, float)
    b = dict(name=name, s=np.array(s, float), col=col, R=Rw, cw=cw)
    blocks.append(b); by_name[name] = b
    return b

# --- Держак ---
B("Handle",      (0, 3.2, 0),   (0.6, 9.2, 0.6),   "wood")                 # від -1.4 до 7.8
B("Grip",        (0, -0.2, 0),  (0.8, 2.4, 0.8),   "wood_dk", rot=(0, 0.20, 0))
B("Pommel",      (0, -1.65, 0), (1.0, 0.6, 1.0),   "metal_dk", rot=(0, 0.78, 0))
B("Band",        (0, 3.6, 0),   (0.75, 0.4, 0.75), "wood_dk", rot=(0, 0.55, 0))
# --- Голова ---
B("Head",        (0, 7.9, 0),   (1.4, 1.6, 1.8),   "metal_dk")
B("HeadRound",   (0, 7.95, 0),  (1.1, 2.0, 1.1),   "metal_dk", rot=(0, 0.785, 0))
B("HeadCap",     (0, 8.85, 0),  (0.9, 0.4, 0.9),   "metal", rot=(0, 0.3, 0))

# --- Леза: сходинки, кожна наступна повернута сильніше вниз (дугою) ---
def blade(prefix, sign, segs):
    """sign=+1 — робоче лезо (+Z), -1 — зворотне (-Z). segs: (довжина, висота, товщина, кут)."""
    parent, prev_len = "Head", 1.8 / 2
    angle_prev = 0.0
    for i, (L, h, t, ang) in enumerate(segs):
        name = f"{prefix}{i+1}"
        # центр сегмента: від кінця попереднього вздовж його осі Z + половина власної довжини
        c = (0, 0, sign * (prev_len - 0.25 + L / 2)) if i else (0, -0.05, sign * (prev_len + L / 2 - 0.3))
        B(name, c, (t, h, L), "metal", rot=(sign * (ang - angle_prev), 0, 0), parent=parent)
        parent, prev_len, angle_prev = name, L / 2, ang
    return parent

tip = blade("Pick", +1, [(1.9, 1.05, 1.0, 0.10), (1.6, 0.8, 0.8, 0.32), (1.3, 0.6, 0.6, 0.55), (0.9, 0.4, 0.4, 0.80)])
back = blade("Back", -1, [(1.4, 1.0, 1.0, 0.10), (1.0, 0.7, 0.8, 0.40)])
# блиск на робочому лезі й лопатка на зворотному
B("PickGlint", (0.0, 0.42, 0.0), (1.0, 0.25, 0.5), "light", rot=(0, 0, 0), parent="Pick2")
B("BackFlat",  (0, 0.0, -0.55), (1.15, 1.0, 0.3), "metal_dk", parent="Back2")

# точка удару — кінчик робочого леза (локальні координати кірки)
tipb = by_name[tip]
tip_point = tipb["cw"] + tipb["R"] @ np.array([0, -0.1, tipb["s"][2] / 2])

# ---------- Правило 0,1 (пари з однаковою орієнтацією) ----------
def same_R(a, b): return np.allclose(a["R"], b["R"], atol=1e-6)
def conflicts():
    out = []
    for i in range(len(blocks)):
        for j in range(i+1, len(blocks)):
            a, b = blocks[i], blocks[j]
            if not same_R(a, b): continue
            ca, cb = a["R"].T @ a["cw"], a["R"].T @ b["cw"]
            alo, ahi, blo, bhi = ca - a["s"]/2, ca + a["s"]/2, cb - b["s"]/2, cb + b["s"]/2
            if not all(alo[k] < bhi[k] and blo[k] < ahi[k] for k in range(3)): continue
            for k in range(3):
                if abs(alo[k]-blo[k]) < 0.1 - 1e-9 or abs(ahi[k]-bhi[k]) < 0.1 - 1e-9: out.append((a["name"], b["name"], k))
    return out
conf = conflicts()

# ---------- GLB (точка опори = хват; у GLB кірка лежить держаком уздовж Y) ----------
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
            P.append(b["R"] @ ((np.array(q) - 0.5) * b["s"]) + b["cw"]); N.append(b["R"] @ np.array(n, float))
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
nodes.append(dict(name="Pickaxe", children=list(range(len(blocks)))))
gltf = dict(asset=dict(version="2.0", generator="pickaxe_generator.py"), scene=0, scenes=[dict(nodes=[len(nodes)-1])],
            nodes=nodes, meshes=meshes, materials=materials, accessors=accs, bufferViews=views, buffers=[dict(byteLength=0)])
while len(buf) % 4: buf += b"\0"
gltf["buffers"][0]["byteLength"] = len(buf)
js = json.dumps(gltf, separators=(",", ":")).encode()
while len(js) % 4: js += b" "
glb = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(buf))
glb += struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(buf), 0x004E4942) + bytes(buf)
open("Pickaxe.glb", "wb").write(glb)

UNIT = np.array([[x, y, z] for x in (-.5, .5) for y in (-.5, .5) for z in (-.5, .5)])
allp = np.vstack([(UNIT * b["s"]) @ b["R"].T + b["cw"] for b in blocks]); size = allp.max(0) - allp.min(0)
rep = (f"Блоків: {len(blocks)}\nТрикутників: {len(blocks)*12}\nКольорів: {len(COLORS)}\n"
       f"Правило 0,1 (однакова орієнтація): збігів {len(conf)} {conf}\n"
       f"Розмір (од.): {size[0]:.2f} x {size[1]:.2f} x {size[2]:.2f}  (стади: {size[0]/2:.2f} x {size[1]/2:.2f} x {size[2]/2:.2f})\n"
       f"Кінчик леза (лок.): {np.round(tip_point, 3).tolist()}\n")
open("pickaxe_report.txt", "w", encoding="utf-8").write(rep)
json.dump(dict(colors=COLORS, tip=tip_point.tolist(),
               blocks=[dict(name=b["name"], col=b["col"], s=b["s"].tolist(), c=b["cw"].tolist(), R=b["R"].tolist()) for b in blocks]),
          open("pickaxe_blocks.json", "w"), ensure_ascii=False)
print(rep)
