"""Stone Golem v2 — генератор блокової моделі за GDD «Блоковий стиль моделей»
з розділом «Повороти для округлення і живості».

Запуск:  python golem_generator_v2.py  ->  StoneGolem_Static.glb, stone_golem_report.txt
Осі: X — вправо, Y — вгору, Z — вперед (обличчя дивиться в +Z). 1 одиниця моделі = 0,5 стада.

Що нового у v2 (порівняно з v1):
- кінцівки, наплічники, плити, стопи й кулаки повернуті на невеликі кути (дзеркально для L/R);
- кристал-серце стоїть ромбом (45°), з плечей і спини ростуть кристалічні уламки;
- на маківці кам'яна «шапка», носки стоп округлені блоком під 45°;
- деталі (кісточки, налікотники, наколінники) прив'язані до свого батька і повертаються разом з ним;
- обличчя лишається рівним і дзеркальним.

API для golem_rig_v2.py: blocks (name, c — центр ДО зсуву, s, col, R), block_geo(b), shift, COLORS, hex2lin.
"""
import json, struct, math
import numpy as np

COLORS = {
    "main":    "#8b96a3",  # основний: камінь
    "accent":  "#66717e",  # темніший акцент
    "light":   "#f1f5f8",  # спільний світлий
    "dark":    "#1c2836",  # спільний темний
    "pink":    "#f2a0b4",  # спільний рожевий
    "crystal": "#6fd3e0",  # кристал
}

def Rx(a): c, s = math.cos(a), math.sin(a); return np.array([[1,0,0],[0,c,-s],[0,s,c]])
def Ry(a): c, s = math.cos(a), math.sin(a); return np.array([[c,0,s],[0,1,0],[-s,0,c]])
def Rz(a): c, s = math.cos(a), math.sin(a); return np.array([[c,-s,0],[s,c,0],[0,0,1]])
def E(rx=0.0, ry=0.0, rz=0.0): return Rz(rz) @ Ry(ry) @ Rx(rx)

blocks, by_name = [], {}

def _add(name, c, s, col, rot, parent):
    Rl = E(*rot)
    if parent:
        p = by_name[parent]
        R = p["R"] @ Rl
        c = list(np.array(p["c"]) + p["R"] @ np.array(c, float))
    else:
        R = Rl
    b = dict(name=name, c=list(map(float, c)), s=list(map(float, s)), col=col, R=R, parent=parent)
    blocks.append(b); by_name[name] = b

def B(name, c, s, col, rot=(0, 0, 0), mirror=False, parent=None):
    """mirror=True: блоки _R (x як є) і _L (x дзеркально, повороти ry/rz з протилежним знаком)."""
    if mirror:
        for side, sx in (("R", 1), ("L", -1)):
            cc = [c[0] * sx, c[1], c[2]]
            rr = (rot[0], rot[1] * sx, rot[2] * sx)
            _add(f"{name}_{side}", cc, s, col, rr, f"{parent}_{side}" if parent else None)
    else:
        _add(name, c, s, col, rot, parent)

# --- Ноги ---
B("Foot",      (1.9, 0.5, 0.4),  (2.8, 1.0, 3.6), "accent", rot=(0, 0.10, 0), mirror=True)   # носки трохи назовні
B("Toe",       (0.0, -0.05, 1.75), (1.9, 0.8, 1.9), "accent", rot=(0, 0.785, 0), mirror=True, parent="Foot")  # округлений носок
B("Shin",      (1.9, 2.2, 0.0),  (2.2, 2.6, 2.2), "main",   rot=(0, 0.06, 0), mirror=True)
B("KneePlate", (0.0, 0.4, 1.1),  (1.6, 1.2, 0.5), "accent", rot=(-0.22, 0, 0), mirror=True, parent="Shin")
B("Thigh",     (1.8, 4.2, 0.0),  (2.4, 1.8, 2.4), "main",   rot=(0, -0.10, 0), mirror=True)
# --- Таз ---
B("Pelvis",    (0, 5.2, 0.0),    (5.4, 1.6, 3.2), "main")
# --- Корпус ---
B("Torso",     (0, 7.8, 0.0),    (7.0, 4.0, 4.2), "main")
B("Chest",     (0, 9.6, -0.2),   (8.0, 1.6, 4.6), "main")
B("CorePlate", (0, 7.6, 2.2),    (3.0, 2.4, 0.6), "accent")
B("Crystal",   (0, 7.7, 2.5),    (1.3, 1.3, 0.6), "crystal", rot=(0, 0, 0.785))           # ромб
B("CrystalShine", (-0.22, 0.22, 0.4), (0.35, 0.35, 0.2), "light", parent="Crystal")
B("BackPlateUp",  (0, 8.6, -2.3), (4.4, 2.6, 0.6), "accent", rot=(0.10, 0, 0.04))
B("BackPlateLow", (0, 6.4, -2.2), (3.0, 1.4, 0.6), "accent", rot=(-0.08, 0, -0.05))
# кристалічні уламки на спині та плечах (ростуть з каменю)
B("BackShard",  (1.1, 9.3, -2.5), (0.7, 1.9, 0.7), "crystal", rot=(-0.55, 0.3, -0.35), mirror=True)
B("BackShardS", (0.0, 10.0, -2.3), (0.5, 1.3, 0.5), "crystal", rot=(-0.45, 0.6, 0.0))
# --- Голова (маса рівна, обличчя рівне) ---
B("Head",      (0, 11.5, 0.6),   (3.6, 2.8, 3.2), "main")
B("HeadCap",   (-0.2, 12.85, -0.1), (2.6, 0.7, 2.2), "accent", rot=(0.0, 0.35, 0.10))     # кам'яна «шапка»
B("BrowRidge", (0, 12.75, 1.95), (3.4, 0.6, 0.7), "main")
B("Jaw",       (0, 10.35, 1.0),  (3.2, 0.9, 2.8), "main")
B("Mouth",     (0, 10.8, 2.35),  (2.0, 0.25, 0.3), "dark")
# --- Обличчя: шари по 0,1 (без змін) ---
B("EyeWhite",  (0.85, 11.75, 2.2), (1.1, 1.1, 0.2),  "light", mirror=True)
B("Pupil",     (0.75, 11.6, 2.3),  (0.6, 0.75, 0.2), "dark",  mirror=True)
B("EyeShine",  (0.6, 11.85, 2.4),  (0.2, 0.2, 0.2),  "light", mirror=True)
B("Brow",      (0.85, 12.42, 2.3), (1.3, 0.3, 0.3),  "accent", rot=(0, 0, 0.35), mirror=True)
B("Cheek",     (1.5, 11.0, 2.25),  (0.55, 0.25, 0.2), "pink", mirror=True)
# --- Руки ---
B("UpperArm",  (4.9, 8.2, 0.0),  (2.2, 2.6, 2.4), "main",   rot=(0, 0.08, 0), mirror=True)
B("Shoulder",  (4.6, 9.9, 0.0),  (2.8, 1.4, 3.2), "accent", rot=(0, 0.05, -0.22), mirror=True)   # нахилений назовні
B("ShoulderTop", (0.3, 0.75, -0.2), (1.6, 0.5, 2.0), "main", rot=(0, 0.45, 0), mirror=True, parent="Shoulder")
B("ShoulderShard", (0.6, 1.1, -0.7), (0.5, 1.4, 0.5), "crystal", rot=(-0.35, 0, -0.45), mirror=True, parent="Shoulder")
B("Forearm",   (5.2, 5.9, 0.3),  (2.6, 2.4, 2.8), "main",   rot=(0, -0.10, 0), mirror=True)
B("ElbowPlate", (1.35, 0.3, 0.0), (0.5, 1.6, 1.8), "accent", rot=(0, 0, -0.15), mirror=True, parent="Forearm")
B("Fist",      (5.3, 3.7, 0.4),  (3.2, 2.4, 3.2), "main",   rot=(0, 0.12, 0), mirror=True)
B("Knuckles",  (0.0, 0.2, 1.7),  (2.6, 1.2, 0.4), "accent", mirror=True, parent="Fist")

# ---------- Правило 0,1 (лише для блоків рівно по осях, як у v1) ----------
def is_axis(b): return np.allclose(b["R"], np.eye(3), atol=1e-9)
def bounds(b):
    c, s = np.array(b["c"]), np.array(b["s"]); return c - s/2, c + s/2
def set_bounds(b, lo, hi):
    b["c"] = list((lo + hi) / 2); b["s"] = list(hi - lo)
def overlaps(a, b):
    alo, ahi = bounds(a); blo, bhi = bounds(b)
    return all(alo[i] < bhi[i] and blo[i] < ahi[i] for i in range(3))
def vol(b): return float(np.prod(b["s"]))
def find_conflicts():
    out = []
    axb = [b for b in blocks if is_axis(b)]
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
for _ in range(80):
    conf = find_conflicts()
    if not conf: break
    a, b, ax, side = conf[0]
    small, big = (a, b) if vol(a) <= vol(b) else (b, a)
    lo, hi = bounds(small); blo, bhi = bounds(big)
    if side == "max":
        hi[ax] = bhi[ax] + 0.1 if hi[ax] >= bhi[ax] - 1e-9 else bhi[ax] - 0.1
    else:
        lo[ax] = blo[ax] - 0.1 if lo[ax] <= blo[ax] + 1e-9 else blo[ax] + 0.1
    set_bounds(small, lo, hi); fixed += 1
remaining = len(find_conflicts())

# пари повернутих блоків з однаковою орієнтацією (для звіту)
def same_orient_conflicts():
    out = []
    rb = [b for b in blocks if not is_axis(b)]
    for i in range(len(rb)):
        for j in range(i+1, len(rb)):
            a, b = rb[i], rb[j]
            if not np.allclose(a["R"], b["R"], atol=1e-6): continue
            ca, cb = a["R"].T @ np.array(a["c"]), a["R"].T @ np.array(b["c"])
            sa, sb = np.array(a["s"]) / 2, np.array(b["s"]) / 2
            if not all(ca[k]-sa[k] < cb[k]+sb[k] and cb[k]-sb[k] < ca[k]+sa[k] for k in range(3)): continue
            for k in range(3):
                if abs((ca[k]-sa[k])-(cb[k]-sb[k])) < 0.1-1e-9 or abs((ca[k]+sa[k])-(cb[k]+sb[k])) < 0.1-1e-9:
                    out.append((a["name"], b["name"], k))
    return out
rot_conf = same_orient_conflicts()

# ---------- Точка опори ----------
UNIT = np.array([[x, y, z] for x in (-.5, .5) for y in (-.5, .5) for z in (-.5, .5)])
def corners(b): return (UNIT * np.array(b["s"])) @ b["R"].T + np.array(b["c"])
allp = np.vstack([corners(b) for b in blocks])
mn, mx = allp.min(0), allp.max(0)
shift = np.array([-(mn[0]+mx[0])/2, -mn[1], -(mn[2]+mx[2])/2])

# ---------- Геометрія ----------
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
            P.append(b["R"] @ ((np.array(q) - 0.5) * np.array(b["s"])) + np.array(b["c"]) + shift)
            N.append(b["R"] @ np.array(n, float))
        I += [base, base+1, base+2, base, base+2, base+3]
    return np.array(P, np.float32), np.array(N, np.float32), np.array(I, np.uint32)

if __name__ == "__main__":
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
        for t in range(0, len(I), 3):
            a_, b_, c_ = P[I[t]], P[I[t+1]], P[I[t+2]]
            if np.dot(np.cross(b_-a_, c_-a_), N[I[t]]) < 0: I[t+1], I[t+2] = I[t+2], I[t+1]
        pa = add(P, 34962, "VEC3", 5126); na = add(N, 34962, "VEC3", 5126); ia = add(I, 34963, "SCALAR", 5125)
        meshes.append(dict(name=b["name"], primitives=[dict(attributes=dict(POSITION=pa, NORMAL=na), indices=ia, material=order.index(b["col"]))]))
        nodes.append(dict(name=b["name"], mesh=len(meshes)-1))
    materials = [dict(name=k, pbrMetallicRoughness=dict(baseColorFactor=hex2lin(v), metallicFactor=0.0, roughnessFactor=0.85)) for k, v in COLORS.items()]
    nodes.append(dict(name="StoneGolem", children=list(range(len(blocks)))))
    gltf = dict(asset=dict(version="2.0", generator="golem_generator_v2.py"), scene=0, scenes=[dict(nodes=[len(nodes)-1])],
                nodes=nodes, meshes=meshes, materials=materials, accessors=accs, bufferViews=views, buffers=[dict(byteLength=0)])
    while len(buf) % 4: buf += b"\0"
    gltf["buffers"][0]["byteLength"] = len(buf)
    js = json.dumps(gltf, separators=(",", ":")).encode()
    while len(js) % 4: js += b" "
    glb = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(buf))
    glb += struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(buf), 0x004E4942) + bytes(buf)
    open("StoneGolem_Static.glb", "wb").write(glb)
    size = mx - mn
    rotated = [b["name"] for b in blocks if not is_axis(b)]
    rep = (f"Блоків: {len(blocks)} (повернутих: {len(rotated)})\nТрикутників: {len(blocks)*12}\nКольорів: {len(COLORS)}\n"
           f"Правило 0,1: виправлено {fixed}, залишилось збігів {remaining}; повернуті з однаковою орієнтацією: {len(rot_conf)} {rot_conf}\n"
           f"Розмір (од.): {size[0]:.2f} x {size[1]:.2f} x {size[2]:.2f}\n"
           f"Розмір (стади): {size[0]/2:.2f} x {size[1]/2:.2f} x {size[2]/2:.2f}\n")
    open("stone_golem_report.txt", "w", encoding="utf-8").write(rep)
    json.dump(dict(colors=COLORS, shift=shift.tolist(),
                   blocks=[dict(name=b["name"], col=b["col"], s=b["s"], c=(np.array(b["c"]) + shift).tolist(), R=b["R"].tolist()) for b in blocks]),
              open("stone_golem_blocks.json", "w"), ensure_ascii=False)
    print(rep)
