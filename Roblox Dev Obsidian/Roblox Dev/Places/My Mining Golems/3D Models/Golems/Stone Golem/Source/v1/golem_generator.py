"""Кам'яний голем — генератор блокової моделі за GDD «Блоковий стиль моделей».

Запуск:  python golem_generator.py  ->  StoneGolem_Static.glb, stone_golem_report.txt
Осі: X — вправо, Y — вгору, Z — вперед (обличчя дивиться в +Z).
1 одиниця моделі = 0,5 стада.
"""
import json, struct, math
import numpy as np

COLORS = {
    "main":    "#8b96a3",  # основний: камінь
    "accent":  "#66717e",  # темніший акцент: ступні, наплічники, кулаки, плити
    "light":   "#f1f5f8",  # спільний світлий: білки очей, блиск
    "dark":    "#1c2836",  # спільний темний: зіниці, рот
    "pink":    "#f2a0b4",  # спільний рожевий: щічки
    "crystal": "#6fd3e0",  # акцент характеру голема: кристал-серце
}

blocks = []  # dict(name, c, s, col, rz)

def B(name, c, s, col, rz=0.0, mirror=False):
    if mirror:
        for side, sx in (("R", 1), ("L", -1)):
            blocks.append(dict(name=f"{name}_{side}", c=[c[0]*sx, c[1], c[2]],
                               s=list(s), col=col, rz=rz*sx))
    else:
        blocks.append(dict(name=name, c=list(c), s=list(s), col=col, rz=rz))

# --- Ноги (маса 1) ---
B("Foot",      (1.9, 0.5, 0.4),  (2.8, 1.0, 3.6), "accent", mirror=True)
B("Shin",      (1.9, 2.2, 0.0),  (2.2, 2.6, 2.2), "main",   mirror=True)
B("KneePlate", (1.9, 2.6, 1.15), (1.6, 1.2, 0.5), "accent", mirror=True)
B("Thigh",     (1.8, 4.2, 0.0),  (2.4, 1.8, 2.4), "main",   mirror=True)
# --- Таз (маса 2) ---
B("Pelvis",    (0, 5.2, 0.0),    (5.4, 1.6, 3.2), "main")
# --- Корпус (маса 3) ---
B("Torso",     (0, 7.8, 0.0),    (7.0, 4.0, 4.2), "main")
B("Chest",     (0, 9.6, -0.2),   (8.0, 1.6, 4.6), "main")
B("CorePlate", (0, 7.6, 2.2),    (3.0, 2.4, 0.6), "accent")
B("Crystal",   (0, 7.7, 2.5),    (1.4, 1.4, 0.6), "crystal")
B("CrystalShine", (-0.3, 8.1, 2.85), (0.4, 0.4, 0.2), "light")
B("BackPlateUp",  (0, 8.6, -2.3), (4.4, 2.6, 0.6), "accent")
B("BackPlateLow", (0, 6.4, -2.2), (3.0, 1.4, 0.6), "accent")
# --- Голова (маса 4) ---
B("Head",      (0, 11.5, 0.6),   (3.6, 2.8, 3.2), "main")
B("BrowRidge", (0, 12.75, 1.95), (3.4, 0.6, 0.7), "main")
B("Jaw",       (0, 10.35, 1.0),  (3.2, 0.9, 2.8), "main")
B("Mouth",     (0, 10.8, 2.35),  (2.0, 0.25, 0.3), "dark")
# --- Обличчя: шари по 0,1 ---
B("EyeWhite",  (0.85, 11.75, 2.2), (1.1, 1.1, 0.2),  "light", mirror=True)
B("Pupil",     (0.75, 11.6, 2.3),  (0.6, 0.75, 0.2), "dark",  mirror=True)
B("EyeShine",  (0.6, 11.85, 2.4),  (0.2, 0.2, 0.2),  "light", mirror=True)
B("Brow",      (0.85, 12.42, 2.3), (1.3, 0.3, 0.3),  "accent", rz=0.35, mirror=True)  # сердита брова
B("Cheek",     (1.5, 11.0, 2.25),  (0.55, 0.25, 0.2), "pink", mirror=True)
# --- Руки (кінцівки, сходинками до кулака) ---
B("UpperArm",  (4.9, 8.2, 0.0),  (2.2, 2.6, 2.4), "main",   mirror=True)
B("Shoulder",  (4.6, 9.9, 0.0),  (2.8, 1.4, 3.2), "accent", mirror=True)
B("Forearm",   (5.2, 5.9, 0.3),  (2.6, 2.4, 2.8), "main",   mirror=True)
B("ElbowPlate",(6.55, 6.2, 0.3), (0.5, 1.6, 1.8), "accent", mirror=True)
B("Fist",      (5.3, 3.7, 0.4),  (3.2, 2.4, 3.2), "main",   mirror=True)
B("Knuckles",  (5.3, 3.9, 2.1),  (2.6, 1.2, 0.4), "accent", mirror=True)

# ---------- Правило 0,1 ----------
def bounds(b):
    c, s = np.array(b["c"]), np.array(b["s"])
    return c - s/2, c + s/2

def set_bounds(b, lo, hi):
    b["c"] = list((lo + hi) / 2); b["s"] = list(hi - lo)

def overlaps(a, b):
    alo, ahi = bounds(a); blo, bhi = bounds(b)
    return all(alo[i] < bhi[i] and blo[i] < ahi[i] for i in range(3))

def vol(b): return float(np.prod(b["s"]))

def find_conflicts():
    out = []
    axb = [b for b in blocks if b["rz"] == 0]
    for i in range(len(axb)):
        for j in range(i+1, len(axb)):
            a, b = axb[i], axb[j]
            if not overlaps(a, b): continue
            alo, ahi = bounds(a); blo, bhi = bounds(b)
            for ax in range(3):
                if abs(alo[ax]-blo[ax]) < 0.1 - 1e-9: out.append((a, b, ax, "min"))
                if abs(ahi[ax]-bhi[ax]) < 0.1 - 1e-9: out.append((a, b, ax, "max"))
    return out

fixed = 0
for _ in range(50):
    conf = find_conflicts()
    if not conf: break
    a, b, ax, side = conf[0]
    small, big = (a, b) if vol(a) <= vol(b) else (b, a)  # рухаємо дрібнішу деталь
    lo, hi = bounds(small); blo, bhi = bounds(big)
    if side == "max":
        hi[ax] = bhi[ax] + 0.1 if hi[ax] >= bhi[ax] - 1e-9 else bhi[ax] - 0.1
    else:
        lo[ax] = blo[ax] - 0.1 if lo[ax] <= blo[ax] + 1e-9 else blo[ax] + 0.1
    set_bounds(small, lo, hi); fixed += 1
remaining = len(find_conflicts())

# ---------- Точка опори: центр X/Z, низ на Y=0 ----------
def corners(b):
    lo, hi = bounds(b); c = np.array(b["c"])
    pts = np.array([[x, y, z] for x in (lo[0], hi[0]) for y in (lo[1], hi[1]) for z in (lo[2], hi[2])])
    if b["rz"]:
        r = b["rz"]; R = np.array([[math.cos(r), -math.sin(r), 0], [math.sin(r), math.cos(r), 0], [0, 0, 1]])
        pts = (pts - c) @ R.T + c
    return pts

allp = np.vstack([corners(b) for b in blocks])
mn, mx = allp.min(0), allp.max(0)
shift = np.array([-(mn[0]+mx[0])/2, -mn[1], -(mn[2]+mx[2])/2])

# ---------- Геометрія (пласкі нормалі, 24 вершини / 12 трикутників на блок) ----------
FACES = [  # (нормаль, 4 кути в одиничному кубі)
    ((1,0,0),  [(1,0,0),(1,1,0),(1,1,1),(1,0,1)]),
    ((-1,0,0), [(0,0,1),(0,1,1),(0,1,0),(0,0,0)]),
    ((0,1,0),  [(0,1,0),(0,1,1),(1,1,1),(1,1,0)]),
    ((0,-1,0), [(0,0,1),(0,0,0),(1,0,0),(1,0,1)]),
    ((0,0,1),  [(1,0,1),(1,1,1),(0,1,1),(0,0,1)]),
    ((0,0,-1), [(0,0,0),(0,1,0),(1,1,0),(1,0,0)]),
]

def hex2lin(h):
    rgb = [int(h[i:i+2], 16)/255 for i in (1, 3, 5)]
    return [c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4 for c in rgb] + [1.0]

def block_geo(b):
    lo, hi = bounds(b); c = np.array(b["c"]); r = b["rz"]
    R = np.array([[math.cos(r), -math.sin(r), 0], [math.sin(r), math.cos(r), 0], [0, 0, 1]])
    P, N, I = [], [], []
    for n, quad in FACES:
        base = len(P)
        for q in quad:
            p = lo + (hi - lo) * np.array(q)
            P.append((p - c) @ R.T + c + shift)
            N.append(R @ np.array(n, float))
        I += [base, base+1, base+2, base, base+2, base+3]
    # перевірка орієнтації (проти годинникової стрілки назовні)
    return np.array(P, np.float32), np.array(N, np.float32), np.array(I, np.uint32)

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
    # виправити порядок вершин так, щоб нормаль трикутника збігалась з нормаллю грані
    for t in range(0, len(I), 3):
        a_, b_, c_ = P[I[t]], P[I[t+1]], P[I[t+2]]
        if np.dot(np.cross(b_-a_, c_-a_), N[I[t]]) < 0:
            I[t+1], I[t+2] = I[t+2], I[t+1]
    pa = add(P, 34962, "VEC3", 5126); na = add(N, 34962, "VEC3", 5126); ia = add(I, 34963, "SCALAR", 5125)
    meshes.append(dict(name=b["name"], primitives=[dict(attributes=dict(POSITION=pa, NORMAL=na),
                                                        indices=ia, material=order.index(b["col"]))]))
    nodes.append(dict(name=b["name"], mesh=len(meshes)-1))

materials = [dict(name=k, pbrMetallicRoughness=dict(baseColorFactor=hex2lin(v), metallicFactor=0.0,
                                                    roughnessFactor=0.85)) for k, v in COLORS.items()]
nodes.append(dict(name="StoneGolem", children=list(range(len(blocks)))))
gltf = dict(asset=dict(version="2.0", generator="golem_generator.py"), scene=0,
            scenes=[dict(nodes=[len(nodes)-1])], nodes=nodes, meshes=meshes, materials=materials,
            accessors=accs, bufferViews=views, buffers=[dict(byteLength=len(buf))])
while len(buf) % 4: buf += b"\0"
gltf["buffers"][0]["byteLength"] = len(buf)
js = json.dumps(gltf, separators=(",", ":")).encode()
while len(js) % 4: js += b" "
glb = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(buf))
glb += struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(buf), 0x004E4942) + bytes(buf)
open("StoneGolem_Static.glb", "wb").write(glb)

size = (mx - mn)
rep = (f"Блоків: {len(blocks)}\nТрикутників: {len(blocks)*12}\nКольорів: {len(COLORS)}\n"
       f"Правило 0,1: виправлено {fixed}, залишилось збігів {remaining}\n"
       f"Розмір (од.): {size[0]:.2f} x {size[1]:.2f} x {size[2]:.2f}\n"
       f"Розмір (стади): {size[0]/2:.2f} x {size[1]/2:.2f} x {size[2]/2:.2f}\n"
       f"Блоки з нахилом (перевірити оком): {[b['name'] for b in blocks if b['rz']]}\n")
open("stone_golem_report.txt", "w", encoding="utf-8").write(rep)
json.dump([dict(b, shift=shift.tolist()) for b in blocks], open("blocks.json", "w"))
print(rep)
