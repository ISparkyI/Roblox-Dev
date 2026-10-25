"""
Test Golem — дерев'яний блоковий голем за «GDD: Wooden Golem — Low-Poly Block Character».

Запуск (Blender 4.2+ або 5.x):
    blender --background --python build_test_golem.py -- --out <папка>
або з модулем bpy:
    python build_test_golem.py --out <папка>

Що робить скрипт:
  1. Описує всі блоки (прямокутні призми) і листки (п'ятикутні призми зі скошеним кутом).
  2. Перевіряє і виправляє співпадіння граней (z-fighting) для блоків без нахилу.
  3. Центрує модель: X/Z = 0, нижня точка Y = 0.
  4. Будує меші в Blender, по одному об'єкту на сегмент майбутнього ригу,
     з точкою опори в суглобі. Призначає матеріали з палітри GDD.
  5. Експортує TestGolem.glb.
  6. Рендерить ракурси: Front, Back, Left, Right, 3/4, Wireframe.
  7. Пише звіт report.json.

Система координат у цьому файлі: X — ширина (+X = ліва рука персонажа),
Y — висота, Z — глибина (персонаж дивиться в +Z). У Blender це перетворюється
в (X, -Z, Y), а glTF-експорт повертає Y-вгору й +Z-вперед.
"""
import bpy, bmesh, math, sys, os, json
from mathutils import Euler, Vector

# ------------------------------------------------------------------ параметри
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
OUT = os.path.abspath(argv[argv.index("--out") + 1]) if "--out" in argv else \
      os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")
NO_RENDER = "--no-render" in argv
SAMPLES = 48
os.makedirs(OUT, exist_ok=True)

PALETTE = {                      # розділ 13 GDD
    "wood":    "#8B5E3C",        # основна світла деревина
    "wood_dk": "#6F4E37",        # темніша деревина
    "gap":     "#3E2D25",        # тіньові проміжки
    "leaf":    "#A7C957",        # яскраве листя
    "moss":    "#5E8F3A",        # темно-зелені брови та мох
    "eye":     "#F7E1A3",        # білки очей
    "iris":    "#E6A94D",        # райдужка (і грудна пластина, як на референсі)
    "pupil":   "#241D18",        # зіниці
    "shine":   "#FFF4D6",        # відблиск
}
MIN_GAP = 0.05                   # розділ 15: накладки виступають мінімум на 0.05
PI = math.pi

# ------------------------------------------------------------------ опис блоків
blocks = []

def _add(kind, name, group, c, dims, col, rot, mirror):
    variants = [("L", 1)] + ([("R", -1)] if mirror else [])
    for side, sx in variants:
        blocks.append(dict(
            kind=kind,
            name=name.replace("{S}", side) if mirror else name,
            group=group.replace("{S}", side),
            c=[c[0] * sx, c[1], c[2]], dims=list(dims), col=col,
            rot=[rot[0], rot[1] * sx, rot[2] * sx]))

def box(name, group, c, s, col, rot=(0, 0, 0), mirror=False):
    _add("box", name, group, c, s, col, rot, mirror)

def leaf(name, group, c, w, l, t, col, rot, mirror=False):
    """Листок: товста п'ятикутна пластина (прямокутник зі скошеним кутом).
    Локально: ширина w по X, довжина l по Y, товщина t по Z (нормаль)."""
    _add("leaf", name, group, c, (w, l, t), col, rot, mirror)

M = True  # дзеркально на обидва боки
# ---- Ноги (короткі, широкі) ----
box("Thigh_{S}",     "Thigh_{S}", (0.42, 1.30, 0.00), (0.74, 0.55, 0.80), "wood",    mirror=M)
box("Knee_{S}",      "Shin_{S}",  (0.42, 0.97, 0.05), (0.78, 0.26, 0.80), "wood_dk", mirror=M)
box("Shin_{S}",      "Shin_{S}",  (0.42, 0.56, 0.00), (0.68, 0.66, 0.74), "wood",    mirror=M)
box("Foot_{S}",      "Foot_{S}",  (0.45, 0.14, 0.12), (0.86, 0.28, 1.15), "wood_dk", mirror=M)
box("FootStep_{S}",  "Foot_{S}",  (0.45, 0.33, 0.22), (0.72, 0.14, 0.66), "wood",    mirror=M)
# ---- Таз і торс (короткий, широкий, сегментований) ----
box("Pelvis",        "Pelvis",    (0, 1.60, 0.00),  (1.45, 0.35, 0.95), "wood_dk")
box("WaistGap",      "Pelvis",    (0, 1.84, 0.00),  (1.40, 0.20, 0.85), "gap")
box("Torso",         "Torso",     (0, 2.55, 0.00),  (1.65, 1.30, 1.05), "wood_dk")
box("Belly",         "Torso",     (0, 2.12, 0.55),  (1.05, 0.24, 0.14), "wood")
box("ChestPlate",    "Torso",     (0, 2.72, 0.60),  (1.15, 0.72, 0.18), "iris")
box("SidePlate_{S}", "Torso",     (0.87, 2.62, 0.05), (0.14, 0.85, 0.78), "wood", mirror=M)
box("ShoulderGirdle","Torso",     (0, 3.28, -0.02), (1.95, 0.30, 1.00), "wood")
box("BackPlate",     "Torso",     (0, 2.65, -0.58), (0.95, 0.95, 0.16), "wood")
box("BackSegment",   "Torso",     (0, 2.00, -0.56), (0.70, 0.28, 0.12), "wood")
box("NeckGap",       "Torso",     (0, 3.50, 0.00),  (0.90, 0.20, 0.70), "gap")
# ---- Голова (велика, прямокутна, «маска» з блоків) ----
box("Skull",         "Head",      (0, 4.15, 0.00),  (2.00, 1.25, 1.40), "wood")
box("Temple_{S}",    "Head",      (1.06, 4.30, -0.05), (0.24, 0.80, 1.10), "wood_dk", mirror=M)
box("TopPlate",      "Head",      (0, 4.82, 0.05),  (1.30, 0.16, 1.00), "wood")
box("Forehead",      "Head",      (0, 4.60, 0.76),  (0.36, 0.32, 0.14), "wood")
box("Cheek_{S}",     "Head",      (0.82, 3.82, 0.58), (0.42, 0.50, 0.28), "wood_dk", mirror=M)
box("HeadBackPlate", "Head",      (0, 4.25, -0.76), (1.20, 0.60, 0.12), "wood_dk")
box("Muzzle",        "Head",      (0, 3.66, 0.85),  (1.00, 0.36, 0.50), "wood")
box("Mouth",         "Head",      (0, 3.445, 0.81), (0.80, 0.09, 0.34), "gap")
box("Jaw",           "Head",      (0, 3.27, 0.78),  (0.86, 0.28, 0.50), "wood_dk")
# ---- Очі: основа -> райдужка -> зіниця -> відблиск ----
box("EyeWhite_{S}",  "Head",      (0.50, 4.17, 0.74), (0.62, 0.66, 0.10), "eye",   mirror=M)
box("Iris_{S}",      "Head",      (0.50, 4.15, 0.80), (0.52, 0.56, 0.08), "iris",  mirror=M)
box("Pupil_{S}",     "Head",      (0.47, 4.13, 0.86), (0.30, 0.42, 0.08), "pupil", mirror=M)
box("EyeShine_{S}",  "Head",      (0.40, 4.27, 0.92), (0.09, 0.09, 0.06), "shine", mirror=M)
# ---- Брови: товсті, темно-зелені, зосереджені (внутрішній кінець трохи нижче) ----
box("Brow_{S}",      "Head",      (0.52, 4.63, 0.78), (0.86, 0.30, 0.26), "moss", rot=(0, 0, 0.12), mirror=M)
# ---- Руки (довгі, масивні) ----
box("Shoulder_{S}",  "UpperArm_{S}", (1.22, 3.22, 0.00), (0.95, 0.70, 1.10), "wood",    mirror=M)
box("UpperArm_{S}",  "UpperArm_{S}", (1.30, 2.55, 0.00), (0.60, 0.62, 0.72), "wood",    mirror=M)
box("Elbow_{S}",     "Forearm_{S}",  (1.30, 2.16, -0.02), (0.54, 0.34, 0.68), "wood_dk", mirror=M)
box("Forearm_{S}",   "Forearm_{S}",  (1.32, 1.67, 0.04), (0.95, 0.75, 0.90), "wood",    mirror=M)
box("Fist_{S}",      "Hand_{S}",     (1.34, 0.98, 0.08), (1.00, 0.48, 0.92), "wood_dk", mirror=M)
for i, dx in enumerate((-0.30, 0.0, 0.30)):
    box(f"Finger{i+1}_{{S}}", "Hand_{S}", (1.34 + dx, 0.64, 0.38), (0.27, 0.28, 0.28), "wood", mirror=M)
# ---- Листя (15 елементів, частково асиметрично, як на референсі) ----
leaf("LeafTop",        "Head", (-0.20, 4.98, 0.10), 0.85, 0.70, 0.14, "leaf", (-PI/2 + 0.30, 0, 0.35))
leaf("LeafSide_{S}",   "Head", (1.08, 4.95, 0.15),  0.66, 0.56, 0.14, "leaf", (-0.50, 0, 0.55), mirror=M)
leaf("LeafBack",       "Head", (0.35, 4.95, -0.50), 0.50, 0.45, 0.12, "moss", (-PI/2 - 0.50, 0, -0.20))
leaf("LeafTemple_L",   "Head", (1.20, 4.45, 0.25),  0.32, 0.40, 0.10, "leaf", (0, PI/2, 0.30))
leaf("ShoulderLeaf_{S}", "UpperArm_{S}", (1.40, 3.62, 0.00), 0.72, 0.82, 0.15, "leaf", (-PI/2 + 0.25, 0, 0.55), mirror=M)
leaf("HeadBackLeaf",   "Head", (-0.40, 4.55, -0.80), 0.42, 0.38, 0.10, "moss", (0, PI, 0.40))
leaf("BackLeaf",       "Torso", (0.05, 3.05, -0.66), 0.60, 0.50, 0.12, "leaf", (0, PI, 0.20))
leaf("NapeLeaf",       "Torso", (-0.30, 3.62, -0.56), 0.42, 0.36, 0.10, "moss", (0.30, PI, -0.30))
leaf("ForearmLeaf_{S}", "Forearm_{S}", (1.74, 1.78, 0.05), 0.42, 0.45, 0.10, "leaf", (0, PI/2, 0.15), mirror=M)
leaf("KneeLeaf_{S}",   "Shin_{S}", (0.42, 1.00, 0.45),  0.38, 0.30, 0.10, "leaf", (0, 0, 0.25), mirror=M)
leaf("ShinLeaf_R",     "Shin_R",   (-0.79, 0.55, 0.05), 0.32, 0.36, 0.10, "moss", (0, -PI/2, 0.20))
leaf("FootLeaf_L",     "Foot_L",   (0.30, 0.42, 0.50),  0.28, 0.24, 0.08, "leaf", (-PI/2 + 0.20, 0, 0.30))

# Голова сидить нижче між плечима, як на референсі (щелепа заходить на груди)
HEAD_DROP = 0.12
for b in blocks:
    if b["group"] == "Head": b["c"][1] -= HEAD_DROP

# Точки опори сегментів (суглоби) — для майбутнього ригу / Motor6D у Roblox
PIVOTS = {
    "Pelvis": (0, 1.60, 0), "Torso": (0, 1.85, 0), "Head": (0, 3.33, 0),
    "UpperArm_L": (1.22, 3.10, 0), "Forearm_L": (1.30, 2.20, 0), "Hand_L": (1.32, 1.22, 0.05),
    "Thigh_L": (0.42, 1.55, 0), "Shin_L": (0.42, 1.05, 0), "Foot_L": (0.42, 0.30, 0),
}
for k in list(PIVOTS):
    if k.endswith("_L"):
        x, y, z = PIVOTS[k]; PIVOTS[k[:-2] + "_R"] = (-x, y, z)

# ------------------------------------------------------------------ поза рук (розділ 10: невеликий нахил)
# Руки трохи відведені назовні в плечі й зігнуті вперед у лікті, як на референсі.
# Застосовується після перевірки z-fighting, обертає цілі сегменти навколо суглобів.
POSE = []   # (групи, суглоб, ейлер) — від найближчого до кисті суглоба до плеча
for side, sx in (("L", 1), ("R", -1)):
    POSE.append(({f"Forearm_{side}", f"Hand_{side}"}, PIVOTS[f"Forearm_{side}"], (-0.10, 0, 0.03 * sx)))
    POSE.append(({f"UpperArm_{side}", f"Forearm_{side}", f"Hand_{side}"}, PIVOTS[f"UpperArm_{side}"], (0, 0, 0.07 * sx)))
POSE_PIVOTS = {}

def pose_point(group, v):
    for groups_, pivot, eul in POSE:
        if group in groups_:
            pv = Vector(pivot); v = pv + Euler(eul, "XYZ").to_matrix() @ (v - pv)
    return v

# ------------------------------------------------------------------ перевірка z-fighting
def bounds(b):
    return ([b["c"][i] - b["dims"][i] / 2 for i in range(3)],
            [b["c"][i] + b["dims"][i] / 2 for i in range(3)])

def set_bounds(b, lo, hi):
    b["c"] = [(lo[i] + hi[i]) / 2 for i in range(3)]
    b["dims"] = [hi[i] - lo[i] for i in range(3)]

def axis_boxes():
    return [b for b in blocks if b["kind"] == "box" and not any(b["rot"])]

def overlap(a, b):
    alo, ahi = bounds(a); blo, bhi = bounds(b)
    return all(alo[i] < bhi[i] and blo[i] < ahi[i] for i in range(3))

def conflicts():
    out, ab = [], axis_boxes()
    for i in range(len(ab)):
        for j in range(i + 1, len(ab)):
            a, b = ab[i], ab[j]
            if not overlap(a, b): continue
            alo, ahi = bounds(a); blo, bhi = bounds(b)
            for ax in range(3):
                if abs(alo[ax] - blo[ax]) < MIN_GAP - 1e-9: out.append((a, b, ax, 0))
                if abs(ahi[ax] - bhi[ax]) < MIN_GAP - 1e-9: out.append((a, b, ax, 1))
    return out

def vol(b): return b["dims"][0] * b["dims"][1] * b["dims"][2]

fixes = 0
for _ in range(200):
    cf = conflicts()
    if not cf: break
    a, b, ax, side = cf[0]
    small, big = (a, b) if vol(a) <= vol(b) else (b, a)      # рухаємо дрібнішу деталь
    lo, hi = bounds(small); blo, bhi = bounds(big)
    if side == 1:
        hi[ax] = bhi[ax] + MIN_GAP if hi[ax] >= bhi[ax] - 1e-9 else bhi[ax] - MIN_GAP
    else:
        lo[ax] = blo[ax] - MIN_GAP if lo[ax] <= blo[ax] + 1e-9 else blo[ax] + MIN_GAP
    set_bounds(small, lo, hi); fixes += 1
remaining = len(conflicts())

# ------------------------------------------------------------------ геометрія (у координатах GDD)
def local_verts(b):
    w, h, d = b["dims"]
    if b["kind"] == "box":
        pts = [(x, y, z) for x in (-w/2, w/2) for y in (-h/2, h/2) for z in (-d/2, d/2)]
        faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
        return pts, faces
    # листок: п'ятикутник (прямокутник зі скошеним кутом), видавлений на товщину
    l, t = h, d; c = 0.45 * min(w, l)
    poly = [(-w/2, -l/2), (w/2, -l/2), (w/2, l/2 - c), (w/2 - c, l/2), (-w/2, l/2)]
    pts = [(x, y, -t/2) for x, y in poly] + [(x, y, t/2) for x, y in poly]
    n = len(poly)
    faces = [tuple(reversed(range(n))), tuple(range(n, 2*n))] + \
            [(i, (i+1) % n, n + (i+1) % n, n + i) for i in range(n)]
    return pts, faces

def world_pts(b):
    pts, faces = local_verts(b)
    R = Euler(b["rot"], "XYZ").to_matrix()
    c = Vector(b["c"])
    return [pose_point(b["group"], c + R @ Vector(p)) for p in pts], faces

allp = [p for b in blocks for p in world_pts(b)[0]]
mn = [min(p[i] for p in allp) for i in range(3)]
mx = [max(p[i] for p in allp) for i in range(3)]
SHIFT = Vector((-(mn[0] + mx[0]) / 2, -mn[1], -(mn[2] + mx[2]) / 2))
SIZE = [mx[i] - mn[i] for i in range(3)]

def to_bl(v):   # GDD (x, y-вгору, z-вперед) -> Blender (x, -z, y)
    return Vector((v.x, -v.z, v.y))

# ------------------------------------------------------------------ сцена Blender
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

def srgb_to_lin(h):
    c = [int(h[i:i+2], 16) / 255 for i in (1, 3, 5)]
    return [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c] + [1.0]

mats = {}
for key, hexv in PALETTE.items():
    m = bpy.data.materials.new(key)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = srgb_to_lin(hexv)
    bsdf.inputs["Roughness"].default_value = 0.85
    bsdf.inputs["Metallic"].default_value = 0.0
    m.diffuse_color = srgb_to_lin(hexv)
    mats[key] = m

col_model = bpy.data.collections.new("TestGolem")
scene.collection.children.link(col_model)
groups = {}
for b in blocks: groups.setdefault(b["group"], []).append(b)

objects, tri_total = [], 0
for gname, gblocks in groups.items():
    pivot = pose_point(gname, Vector(PIVOTS[gname])) + SHIFT
    me = bpy.data.meshes.new(gname)
    bm = bmesh.new()
    keys = sorted({b["col"] for b in gblocks})
    for b in gblocks:
        pts, faces = world_pts(b)
        vs = [bm.verts.new(to_bl(p + SHIFT - pivot)) for p in pts]
        for f in faces:
            face = bm.faces.new([vs[i] for i in f])
            face.material_index = keys.index(b["col"])
            face.smooth = False
            tri_total += len(f) - 2
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    for k in keys: me.materials.append(mats[k])
    ob = bpy.data.objects.new(gname, me)
    ob.location = to_bl(pivot)
    col_model.objects.link(ob)
    objects.append(ob)

# ------------------------------------------------------------------ експорт GLB
glb_path = os.path.join(OUT, "TestGolem.glb")
bpy.ops.object.select_all(action="DESELECT")
bpy.ops.export_scene.gltf(filepath=glb_path, export_format="GLB", use_selection=False,
                          export_yup=True, export_apply=True, export_materials="EXPORT")

report = dict(
    boxes=sum(1 for b in blocks if b["kind"] == "box"),
    leaves=sum(1 for b in blocks if b["kind"] == "leaf"),
    triangles=tri_total, segments=len(objects), colors=len(PALETTE),
    zfight_fixed=fixes, zfight_remaining=remaining,
    tilted_blocks_check_by_eye=[b["name"] for b in blocks if any(b["rot"])],
    size_xyz=[round(s, 3) for s in SIZE],
    min_y_after_shift=round(mn[1] + SHIFT.y, 4), glb=os.path.basename(glb_path))
json.dump(report, open(os.path.join(OUT, "report.json"), "w"), indent=2, ensure_ascii=False)
print("REPORT", json.dumps(report, ensure_ascii=False))

# ------------------------------------------------------------------ рендер ракурсів
if not NO_RENDER:
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = SAMPLES
    scene.cycles.use_denoising = False
    scene.render.resolution_x, scene.render.resolution_y = 900, 1000
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "Standard"

    world = bpy.data.worlds.new("Studio"); scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.045, 0.05, 0.06, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 1.0

    def light(name, kind, loc, rot, energy, size=4.0):
        ld = bpy.data.lights.new(name, kind); ld.energy = energy
        if kind == "AREA": ld.size = size
        lo = bpy.data.objects.new(name, ld); lo.location = loc; lo.rotation_euler = rot
        scene.collection.objects.link(lo)
    H = SIZE[1]
    light("Key",  "AREA", (3, -4, H + 4), (math.radians(40), 0, math.radians(35)), 900, 5)
    light("Fill", "AREA", (-4, -3, H * 0.6), (math.radians(70), 0, math.radians(-55)), 300, 5)
    light("Rim",  "AREA", (0, 5, H + 2), (math.radians(-45), 0, 0), 400, 5)
    light("Back", "AREA", (3, 4, H + 3), (math.radians(-40), 0, math.radians(145)), 250, 5)

    # підлога-тінь
    bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, 0))
    floor = bpy.context.active_object
    fm = bpy.data.materials.new("Floor"); fm.use_nodes = True
    fm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.05, 0.055, 0.065, 1)
    fm.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 1.0
    floor.data.materials.append(fm)

    cam_data = bpy.data.cameras.new("Cam"); cam_data.type = "ORTHO"
    cam_data.ortho_scale = max(SIZE[1], SIZE[0]) * 1.12
    cam = bpy.data.objects.new("Cam", cam_data); scene.collection.objects.link(cam)
    scene.camera = cam
    cz = SIZE[1] / 2
    VIEWS = [  # ім'я, позиція камери, кут повороту навколо Z
        ("front", (0, -20, cz), 0),
        ("back",  (0, 20, cz), 180),
        ("left",  (20, 0, cz), 90),     # лівий бік персонажа (+X)
        ("right", (-20, 0, cz), -90),   # правий бік персонажа (-X)
        ("three_quarter", (14.1, -14.1, cz + 4), 45),
    ]
    renders = []
    for name, loc, rz in VIEWS:
        cam.location = loc
        tilt = 90 if name != "three_quarter" else 90 - math.degrees(math.atan2(4, 20))
        cam.rotation_euler = (math.radians(tilt), 0, math.radians(rz))
        scene.render.filepath = os.path.join(OUT, f"view_{name}.png")
        bpy.ops.render.render(write_still=True); renders.append(scene.render.filepath)

    # каркас: копії мешів з модифікатором Wireframe і світлим емісійним матеріалом
    wm = bpy.data.materials.new("Wire"); wm.use_nodes = True
    nt = wm.node_tree; nt.nodes.clear()
    em = nt.nodes.new("ShaderNodeEmission"); em.inputs[0].default_value = (0.55, 0.72, 0.95, 1)
    em.inputs[1].default_value = 1.5
    outn = nt.nodes.new("ShaderNodeOutputMaterial"); nt.links.new(em.outputs[0], outn.inputs[0])
    for ob in objects:
        w = ob.copy(); w.data = ob.data.copy(); scene.collection.objects.link(w)
        w.data.materials.clear(); w.data.materials.append(wm)
        mod = w.modifiers.new("wire", "WIREFRAME"); mod.thickness = 0.012; mod.use_replace = True
        ob.hide_render = True
    floor.hide_render = True
    cam.location = (0, -20, cz); cam.rotation_euler = (math.radians(90), 0, 0)
    scene.render.filepath = os.path.join(OUT, "view_wireframe.png")
    bpy.ops.render.render(write_still=True); renders.append(scene.render.filepath)
    print("RENDERS", renders)
