"""Clay Golem (глиняний голем, id `clay`) — генератор блокової моделі + 3 предмети (кірка, меч, ящичок-корито).
За GDD «Блоковий стиль моделей» і зразками Stone Golem v2 / Wooden Golem (ті самі осі, масштаб і формат GolemData).

Запуск:  python clay_golem_generator.py
  -> ../clay_golem_blocks.json   (палітра, кістки, блоки тіла й предметів з повним cf — формат GolemData)
  -> ../ClayGolemData.lua        (те саме у форматі ModuleScript GolemData для Roblox)
  -> clay_golem_report.txt
Осі: X — вправо, Y — вгору, Z — вперед (обличчя в +Z). 1 од. моделі = 0,5 стада. Низ на Y = 0, центр X/Z.
Предмети: локальна система як у pickaxe_generator.py (+Y — держак/лезо від хвату, +Z — робоче лезо кірки,
(0,0,0) — точка хвату); у позі спокою ставляться в кулак Fist_L з поворотом держака Rx(1.449) — як Stone/Wooden.
"""
import json, math, os
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(HERE)

COLORS = {
    "main":   "#c4714a",  # основний: теракотова глина
    "wet":    "#8c4a33",  # темніший акцент: мокра глина (ступні, кулаки, таз, відбитки, тріщини)
    "pebble": "#a39e94",  # камінці, втиснуті в глину
    "light":  "#f1f5f8",  # спільний світлий: білки, блиск
    "dark":   "#1c2836",  # спільний темний: зіниці, рот
    "pink":   "#f2a0b4",  # спільний рожевий: щічки
    "dry":    "#e3ab80",  # суха / випалена світла глина — лише предмети
}
ORE = {"ore_copper": "#e8772e", "ore_stone": "#7d8590", "ore_coal": "#2e3138", "ore_iron": "#d9b49a"}

def Rx(a): c, s = math.cos(a), math.sin(a); return np.array([[1,0,0],[0,c,-s],[0,s,c]])
def Ry(a): c, s = math.cos(a), math.sin(a); return np.array([[c,0,s],[0,1,0],[-s,0,c]])
def Rz(a): c, s = math.cos(a), math.sin(a); return np.array([[c,-s,0],[s,c,0],[0,0,1]])
def E(rx=0.0, ry=0.0, rz=0.0): return Rz(rz) @ Ry(ry) @ Rx(rx)

class Builder:
    def __init__(self): self.blocks, self.by = [], {}
    def _add(self, name, c, s, col, rot, parent, **kw):
        Rl = E(*rot)
        if parent:
            p = self.by[parent]; R = p["R"] @ Rl; c = p["c"] + p["R"] @ np.array(c, float)
        else:
            R = Rl; c = np.array(c, float)
        b = dict(name=name, c=c, s=np.array(s, float), col=col, R=R, parent=parent, **kw)
        self.blocks.append(b); self.by[name] = b
    def B(self, name, c, s, col, rot=(0, 0, 0), mirror=False, parent=None, **kw):
        if mirror:
            for side, sx in (("R", 1), ("L", -1)):
                self._add(f"{name}_{side}", [c[0]*sx, c[1], c[2]], s, col, (rot[0], rot[1]*sx, rot[2]*sx),
                          f"{parent}_{side}" if parent else None, **kw)
        else:
            self._add(name, c, s, col, rot, parent, **kw)

# ======================= ТІЛО =======================
g = Builder(); B = g.B
# --- Ноги: короткі, товсті, пласкі важкі стопи ---
B("Foot",      (2.15, 0.5, 0.35), (3.3, 1.0, 3.9), "wet",  rot=(0, 0.10, 0), mirror=True)
B("Toe",       (0.0, -0.05, 1.85), (2.1, 0.8, 2.1), "wet", rot=(0, 0.785, 0), mirror=True, parent="Foot")
B("Shin",      (2.1, 2.05, 0.0),  (2.7, 2.3, 2.7), "main", rot=(0, 0.06, 0), mirror=True)
B("ShinDrip",  (0.55, 0.35, 1.4), (0.7, 1.3, 0.4), "wet",  rot=(0, 0, 0.12), mirror=True, parent="Shin")   # стікає мокра глина
B("KneePebble",(-0.55, 0.9, 1.4), (0.7, 0.5, 0.5), "pebble", rot=(0.25, 0.4, 0.3), mirror=True, parent="Shin")
B("Thigh",     (2.0, 3.85, 0.0),  (2.9, 1.6, 2.9), "main", rot=(0, -0.10, 0), mirror=True)
# --- Таз ---
B("Pelvis",    (0, 4.85, 0.0),    (6.2, 1.6, 3.7), "wet")
# --- Корпус: важке «пузо» і широкі обвислі плечі ---
B("Torso",     (0, 7.5, 0.0),     (7.6, 4.0, 4.6), "main")
B("Belly",     (0, 6.9, 2.0),     (5.6, 2.8, 1.2), "main")                       # пузо виступає вперед
B("BellyLow",  (0, 6.75, 2.35),   (4.4, 2.2, 1.2), "main")                       # друга сходинка пуза
B("Chest",     (0, 9.45, -0.2),   (8.8, 1.7, 5.0), "main")
# відбиток долоні на пузі (фірмова деталь)
B("HandPalm",  (0.55, 6.6, 3.05), (1.5, 1.3, 0.2), "wet", rot=(0, 0, 0.14))
B("HandFinger1", (-0.55, 1.05, 0.0), (0.32, 0.9, 0.2), "wet", rot=(0, 0, 0.10), parent="HandPalm")
B("HandFinger2", (-0.13, 1.15, 0.0), (0.32, 1.05, 0.2), "wet", rot=(0, 0, 0.03), parent="HandPalm")
B("HandFinger3", (0.29, 1.1, 0.0),  (0.32, 0.95, 0.2), "wet", rot=(0, 0, -0.10), parent="HandPalm")
B("HandFinger4", (0.66, 0.9, 0.0),  (0.3, 0.75, 0.2), "wet", rot=(0, 0, -0.22), parent="HandPalm")
B("HandThumb",   (-0.95, 0.05, 0.0), (0.75, 0.32, 0.2), "wet", rot=(0, 0, 0.55), parent="HandPalm")
# тріщини
B("Crack1",    (-2.35, 8.6, 2.38), (0.22, 1.5, 0.2), "wet", rot=(0, 0, 0.45))
B("Crack2",    (0.25, -0.85, 0.0), (0.22, 0.9, 0.2), "wet", rot=(0, 0, -0.9), parent="Crack1")
B("ChestPebble", (2.6, 9.0, 2.4), (0.7, 0.55, 0.5), "pebble", rot=(0.2, 0.35, 0.5))
# спина: мокра плита зі слідами пальців
B("BackSlab",  (0, 7.9, -2.4),    (5.0, 3.2, 0.6), "wet", rot=(0.06, 0, 0.04))
B("FingerMark1", (0, 0.85, -0.35), (3.8, 0.32, 0.2), "main", rot=(0, 0, 0.08), parent="BackSlab")
B("FingerMark2", (0.2, 0.0, -0.35), (3.6, 0.32, 0.2), "main", rot=(0, 0, -0.05), parent="BackSlab")
B("FingerMark3", (-0.1, -0.85, -0.35), (3.4, 0.32, 0.2), "main", rot=(0, 0, 0.12), parent="BackSlab")
B("BackPebble1", (1.9, 9.9, -2.55), (0.8, 0.6, 0.6), "pebble", rot=(-0.3, 0.5, 0.2))
B("BackPebble2", (-2.3, 6.3, -2.45), (0.6, 0.5, 0.5), "pebble", rot=(0.2, -0.4, 0.5))
# --- Голова: невелика, втоплена в плечі; зверху защипнута грудка глини ---
B("Head",      (0, 11.15, 0.75),  (3.8, 2.7, 3.3), "main")
B("HeadLump",  (0.25, 12.75, 0.4), (2.8, 0.8, 2.5), "main", rot=(0.0, 0.5, 0.10))
B("HeadPinch", (-0.35, 13.3, 0.25), (1.3, 0.7, 1.2), "wet", rot=(0.15, -0.35, -0.2))   # «защип» пальцями
B("Jaw",       (0, 10.1, 1.05),   (3.3, 0.8, 2.9), "main")
# --- Обличчя: рівне, дзеркальне, шари по 0,1; дружнє ---
B("EyeWhite",  (0.85, 11.4, 2.45), (1.2, 1.25, 0.2), "light", mirror=True)
B("Pupil",     (0.78, 11.28, 2.55), (0.66, 0.85, 0.2), "dark", mirror=True)
B("EyeShine",  (0.62, 11.55, 2.65), (0.22, 0.22, 0.2), "light", mirror=True)
B("Brow",      (0.9, 12.3, 2.5),  (1.3, 0.32, 0.3), "wet", rot=(0, 0, -0.15), mirror=True)   # трохи вгору до центру — дружній
B("Cheek",     (1.55, 10.75, 2.5), (0.55, 0.26, 0.2), "pink", mirror=True)
B("Mouth",     (0, 10.45, 2.6),   (1.1, 0.26, 0.3), "dark")
B("MouthCorner", (0.65, 10.6, 2.6), (0.3, 0.26, 0.3), "dark", mirror=True)
# --- Руки: масивні, кулаки з мокрої глини ---
B("UpperArm",  (5.25, 8.0, 0.0),  (2.5, 2.6, 2.6), "main", rot=(0, 0.08, 0), mirror=True)
B("Shoulder",  (5.0, 9.85, 0.0),  (3.2, 1.7, 3.5), "main", rot=(0, 0.05, -0.20), mirror=True)   # обвисле глиняне плече
B("ShoulderDrip", (1.25, -1.2, 1.05), (0.6, 1.1, 0.5), "wet", rot=(0, 0, 0.1), mirror=True, parent="Shoulder")
B("ShoulderPebble", (-0.35, 0.95, 0.4), (0.75, 0.5, 0.65), "pebble", rot=(0.2, 0.5, 0.3), mirror=True, parent="Shoulder")
B("Forearm",   (5.55, 5.75, 0.3), (2.8, 2.4, 3.0), "main", rot=(0, -0.10, 0), mirror=True)
B("ElbowCrack",(1.5, 0.25, 0.1),  (0.2, 1.3, 0.5), "wet", rot=(0, 0, -0.3), mirror=True, parent="Forearm")
B("Fist",      (5.65, 3.45, 0.4), (3.4, 2.6, 3.4), "wet", rot=(0, 0.12, 0), mirror=True)
B("Knuckles",  (0.0, 0.3, 1.8),   (2.8, 1.0, 0.4), "main", mirror=True, parent="Fist")
B("Thumb",     (-1.8, 0.1, 0.9),  (0.5, 1.2, 1.0), "wet", rot=(0, 0, 0.1), mirror=True, parent="Fist")
body = g.blocks

# ---------- Правило 0,1 (блоки рівно по осях; як у golem_generator_v2.py) ----------
def is_axis(b): return np.allclose(b["R"], np.eye(3), atol=1e-9)
def bounds(b): return b["c"] - b["s"]/2, b["c"] + b["s"]/2
def overlaps(a, b):
    alo, ahi = bounds(a); blo, bhi = bounds(b)
    return all(alo[i] < bhi[i] and blo[i] < ahi[i] for i in range(3))
def find_conflicts(bl):
    out = []; axb = [b for b in bl if is_axis(b)]
    for i in range(len(axb)):
        for j in range(i+1, len(axb)):
            a, b = axb[i], axb[j]
            if not overlaps(a, b): continue
            alo, ahi = bounds(a); blo, bhi = bounds(b)
            for ax in range(3):
                if abs(alo[ax]-blo[ax]) < 0.1-1e-9: out.append((a, b, ax, "min"))
                if abs(ahi[ax]-bhi[ax]) < 0.1-1e-9: out.append((a, b, ax, "max"))
    return out
def fix01(bl):
    fixed = 0
    for _ in range(100):
        conf = find_conflicts(bl)
        if not conf: break
        a, b, ax, side = conf[0]
        small, big = (a, b) if np.prod(a["s"]) <= np.prod(b["s"]) else (b, a)
        lo, hi = bounds(small); blo, bhi = bounds(big)
        if side == "max": hi[ax] = bhi[ax]+0.1 if hi[ax] >= bhi[ax]-1e-9 else bhi[ax]-0.1
        else:             lo[ax] = blo[ax]-0.1 if lo[ax] <= blo[ax]+1e-9 else blo[ax]+0.1
        small["c"] = (lo+hi)/2; small["s"] = hi-lo; fixed += 1
    return fixed, len(find_conflicts(bl))
def same_orient_conflicts(bl):
    out = []; rb = [b for b in bl if not is_axis(b)]
    for i in range(len(rb)):
        for j in range(i+1, len(rb)):
            a, b = rb[i], rb[j]
            if not np.allclose(a["R"], b["R"], atol=1e-6): continue
            ca, cb = a["R"].T @ a["c"], a["R"].T @ b["c"]; sa, sb = a["s"]/2, b["s"]/2
            if not all(ca[k]-sa[k] < cb[k]+sb[k] and cb[k]-sb[k] < ca[k]+sa[k] for k in range(3)): continue
            for k in range(3):
                if abs((ca[k]-sa[k])-(cb[k]-sb[k])) < 0.1-1e-9 or abs((ca[k]+sa[k])-(cb[k]+sb[k])) < 0.1-1e-9:
                    out.append((a["name"], b["name"], k))
    return out

fixed, remaining = fix01(body)
rot_conf = same_orient_conflicts(body)

UNIT = np.array([[x, y, z] for x in (-.5, .5) for y in (-.5, .5) for z in (-.5, .5)])
def corners(b): return (UNIT * b["s"]) @ b["R"].T + b["c"]
allp = np.vstack([corners(b) for b in body]); mn, mx = allp.min(0), allp.max(0)
shift = np.array([-(mn[0]+mx[0])/2, -mn[1], -(mn[2]+mx[2])/2])
for b in body: b["c"] = b["c"] + shift

def bone_for(name):
    base, _, s = name.partition("_")
    if base in ("Foot", "Toe", "Shin", "ShinDrip", "KneePebble"): return f"Shin_{s}"
    if base == "Thigh": return f"Thigh_{s}"
    if base == "Pelvis": return "Hips"
    if base in ("UpperArm", "Shoulder", "ShoulderDrip", "ShoulderPebble"): return f"UpperArm_{s}"
    if base in ("Forearm", "ElbowCrack", "Fist", "Knuckles", "Thumb"): return f"Forearm_{s}"
    if base == "EyeWhite": return f"Eye_{s}"
    if base in ("Pupil", "EyeShine"): return f"Pupil_{s}"
    if base == "Brow": return f"Brow_{s}"
    if base == "Mouth": return "Mouth"
    if base == "MouthCorner": return f"MouthCorner_{s}"
    if base in ("Head", "HeadLump", "HeadPinch", "Jaw", "Cheek"): return "Head"
    return "Torso"
for b in body: b["bone"] = bone_for(b["name"])

C = {b["name"]: b["c"] for b in body}
BONES = [("Root", None, (0, 0, 0)), ("Hips", "Root", (0, 4.85, 0)), ("Torso", "Hips", (0, 5.6, 0)),
         ("Head", "Torso", (0, 9.9, 0.75)),
         ("UpperArm_R", "Torso", (5.2, 9.4, 0)), ("Forearm_R", "UpperArm_R", (5.5, 6.9, 0.3)),
         ("UpperArm_L", "Torso", (-5.2, 9.4, 0)), ("Forearm_L", "UpperArm_L", (-5.5, 6.9, 0.3)),
         ("Thigh_R", "Hips", (2.0, 4.6, 0)), ("Shin_R", "Thigh_R", (2.1, 3.15, 0)),
         ("Thigh_L", "Hips", (-2.0, 4.6, 0)), ("Shin_L", "Thigh_L", (-2.1, 3.15, 0))]
BONES = [(n, p, np.array(v, float) + shift) for n, p, v in BONES]
for s in ("R", "L"):
    BONES += [(f"Eye_{s}", "Head", C[f"EyeWhite_{s}"]), (f"Pupil_{s}", f"Eye_{s}", C[f"Pupil_{s}"]), (f"Brow_{s}", "Head", C[f"Brow_{s}"])]
BONES += [("Mouth", "Head", C["Mouth"]), ("MouthCorner_R", "Head", C["MouthCorner_R"]), ("MouthCorner_L", "Head", C["MouthCorner_L"])]

# ======================= ПРЕДМЕТИ (локальні координати, (0,0,0) — хват) =======================
# --- Глиняна кірка (15 блоків, будова як у Pickaxe) ---
p = Builder(); P = p.B
P("Handle",    (0, 3.2, 0),    (0.65, 9.2, 0.65), "wet")                        # скачаний валик мокрої глини
P("Grip",      (0, -0.2, 0),   (0.85, 2.4, 0.85), "main", rot=(0, 0.20, 0))     # обмотка-«ковбаска»
P("Pommel",    (0, -1.65, 0),  (1.05, 0.65, 1.05), "dry", rot=(0, 0.78, 0))
P("Band",      (0, 3.6, 0),    (0.8, 0.4, 0.8), "dry", rot=(0, 0.55, 0))
P("Head",      (0, 7.9, 0),    (1.5, 1.7, 1.9), "main")
P("HeadRound", (0, 7.95, 0),   (1.15, 2.1, 1.15), "main", rot=(0, 0.785, 0))
P("HeadPebble",(0.62, 8.0, 0.25), (0.45, 0.55, 0.55), "pebble", rot=(0.3, 0.2, 0.4))   # камінчик, втиснутий у голову
def blade(bl, prefix, sign, segs, col):
    parent, prev_len, angle_prev = "Head", 1.9/2, 0.0
    for i, (L, h, t, ang) in enumerate(segs):
        c = (0, 0, sign*(prev_len-0.25+L/2)) if i else (0, -0.05, sign*(prev_len+L/2-0.3))
        bl.B(f"{prefix}{i+1}", c, (t, h, L), col, rot=(sign*(ang-angle_prev), 0, 0), parent=parent)
        parent, prev_len, angle_prev = f"{prefix}{i+1}", L/2, ang
    return parent
tip = blade(p, "Pick", +1, [(1.9, 1.1, 1.05, 0.10), (1.6, 0.85, 0.85, 0.32), (1.3, 0.62, 0.62, 0.55), (0.9, 0.42, 0.42, 0.80)], "dry")
blade(p, "Back", -1, [(1.4, 1.05, 1.05, 0.10), (1.0, 0.75, 0.85, 0.40)], "dry")
P("PickGlint", (0.0, 0.42, 0.0), (1.05, 0.22, 0.45), "light", parent="Pick1")
P("Thumbprint", (0.0, 0.45, 0.0), (0.7, 0.2, 0.5), "main", parent="Pick2")   # відбиток пальця на лезі
pick = p.blocks
tb = p.by[tip]; pick_tip = tb["c"] + tb["R"] @ np.array([0, -0.1, tb["s"][2]/2])

# --- Глиняний меч (11 блоків) ---
w = Builder(); W = w.B
W("SwordPommel",  (0, -2.45, 0), (1.0, 0.7, 1.0), "wet", rot=(0, 0.785, 0))
W("SwordPommelTop", (0, -2.0, 0), (0.75, 0.3, 0.75), "dry", rot=(0, 0.3, 0))
W("SwordGrip",    (0, -0.35, 0), (0.7, 3.6, 0.7), "wet")
W("SwordCoil1",   (0, -1.1, 0), (0.88, 0.32, 0.88), "main", rot=(0, 0.35, 0.06))   # глиняні кільця-«ковбаски»
W("SwordCoil2",   (0, 0.45, 0), (0.88, 0.32, 0.88), "main", rot=(0, -0.3, -0.06))
W("SwordGuard",   (0, 1.95, 0), (0.9, 0.75, 3.0), "wet", rot=(0.06, 0.0, 0.0))     # гарда — валик мокрої глини
W("SwordGuardPebble", (0.35, 1.95, 0), (0.45, 0.55, 0.55), "pebble", rot=(0.785, 0, 0))
W("SwordBlade",   (0, 5.6, 0),  (0.4, 6.6, 1.45), "main")                          # випалене теракотове лезо
W("SwordEdge",    (0, 5.75, 0), (0.3, 6.1, 1.75), "dry")                           # світлі «загартовані» краї
W("SwordFuller",  (0, 5.2, 0),  (0.6, 4.2, 0.4), "wet")                            # дол — проведений пальцем
W("SwordTip",     (0, 9.25, 0), (0.35, 0.9, 0.8), "dry", rot=(0, 0, 0))
sword = w.blocks

# --- Глиняне корито-ящичок носія (будова як CarryBox v8, в од. моделі = стади × 2) ---
k = Builder(); K = k.B
K("Bottom",   (0, 0.34, 0),    (8.44, 0.68, 4.64), "wet")        # PrimaryPart, низ на 0
K("Band",     (0, 0.22, 0),    (8.8, 0.44, 5.0), "wet", rot=(0, 0, 0))
K("WallF",    (0, 2.0, 2.0),   (8.0, 3.6, 0.6), "main")
K("WallB",    (0, 2.0, -2.0),  (8.0, 3.6, 0.6), "main")
K("WallL",    (-3.7, 2.0, 0),  (0.6, 3.6, 3.4), "main")
K("WallR",    (3.7, 2.0, 0),   (0.6, 3.6, 3.4), "main")
K("RimF",     (0, 4.0, 2.05),  (8.6, 0.5, 0.9), "dry", rot=(0.0, 0.0, 0.015))       # загорнутий край-обідок
K("RimB",     (0, 4.0, -2.05), (8.6, 0.5, 0.9), "dry", rot=(0.0, 0.0, -0.015))
K("RimL",     (-3.75, 4.02, 0), (0.95, 0.5, 3.4), "dry")
K("RimR",     (3.75, 4.02, 0),  (0.95, 0.5, 3.4), "dry")
K("LugL",     (-4.35, 2.6, 0),  (0.9, 1.2, 2.0), "wet", rot=(0, 0, 0.12))            # вушка-ручки під кулаки
K("LugR",     (4.35, 2.6, 0),   (0.9, 1.2, 2.0), "wet", rot=(0, 0, -0.12))
K("Print1",   (-2.3, 2.3, 2.35), (0.6, 0.75, 0.2), "wet", rot=(0, 0, 0.2))           # відбитки пальців на стінці
K("Print2",   (-1.4, 2.55, 2.35), (0.6, 0.75, 0.2), "wet", rot=(0, 0, -0.1))
K("Print3",   (-0.5, 2.3, 2.35), (0.6, 0.75, 0.2), "wet", rot=(0, 0, 0.15))
K("BoxPebble",(2.5, 2.1, 2.4),  (0.8, 0.6, 0.5), "pebble", rot=(0.2, 0.3, 0.5))
K("Drip",     (1.4, 3.1, 2.4),  (0.5, 1.2, 0.3), "wet", rot=(0, 0, 0.06))            # патьок під обідком
K("FloorRaised", (0, 1.55, 0),  (6.8, 2.1, 3.4), "wet")                              # підняте дно (верх на +2,6)
box = k.blocks
box_fixed, box_rem = fix01(box)
# гнізда руди 5 × 2 (як Load/L1…L10 у CarryBox v8), центр на +2,75
LOAD = [dict(name=f"L{i*2+j+1}", c=np.array([x, 3.35, z]), s=np.array([1.5, 1.5, 1.5]), R=np.eye(3))
        for i, x in enumerate((-2.68, -1.34, 0, 1.34, 2.68)) for j, z in enumerate((-0.84, 0.84))]

# ---------- поза спокою предметів у кулаці Fist_L (як у Stone / Wooden) ----------
fist = C["Fist_L"]
R_h = Rx(1.449)   # держак уздовж передпліччя вперед (cos 0.1217, sin 0.99257 — як у GolemData)
def place(items, group):
    out = []
    for b in items:
        out.append(dict(name=b["name"], group=group, bone="Forearm_L", col=b["col"],
                        c=fist + R_h @ b["c"], R=R_h @ b["R"], s=b["s"], lc=b["c"], lR=b["R"]))
    return out
pick_w = place(pick, "Pickaxe"); sword_w = place(sword, "Sword")

# ======================= ВИВІД =======================
def r(x, nd=4): return float(round(float(x), nd)) + 0.0
def cf(c, R): return [r(v) for v in c] + [r(v, 5) for v in np.array(R).flatten()]
def jb(b, local=False):
    d = dict(name=b["name"])
    if b.get("group"): d["group"] = b["group"]
    if b.get("bone"): d["bone"] = b["bone"]
    d["col"] = b["col"]
    d["cf"] = cf(b["lc"], b["lR"]) if local else cf(b["c"], b["R"])
    d["s"] = [r(v) for v in b["s"]]
    return d
size = mx - mn
data = dict(
    golem="Clay Golem", id="clay", kind="clay", catalogSize=1.05,
    units="1 од. моделі = 0,5 стада; cf = [x,y,z, R00,R01,R02, R10,R11,R12, R20,R21,R22] (як CFrame.new у Roblox); s = розмір",
    colors={**COLORS, **ORE},
    bones=[dict(name=n, parent=par, pos=[r(v) for v in pos]) for n, par, pos in BONES],
    blocks=[jb(b) for b in body] + [jb(b) for b in pick_w] + [jb(b) for b in sword_w],
    prefabs=dict(
        ClayPickaxe=dict(hand="Fist_L", grip=[0, 0, 0], tip=[r(v) for v in pick_tip], tipBlock=tip,
                         note="локально: +Y держак, +Z робоче лезо; у кулак — Fist_L.CFrame * Rx(1.449)",
                         blocks=[jb(dict(b, lc=b["c"], lR=b["R"]), True) for b in pick]),
        ClaySword=dict(hand="Fist_L", grip=[0, 0, 0], note="локально: +Y лезо", blocks=[jb(dict(b, lc=b["c"], lR=b["R"]), True) for b in sword]),
        ClayCarryBox=dict(primary="Bottom", note="од. моделі (×0,5 = стади), низ на Y=0; InnerX 3.36, InnerZ 1.66, InnerY0 2.6, InnerY1 4.0",
                          blocks=[jb(dict(b, lc=b["c"], lR=b["R"]), True) for b in box],
                          load=[jb(dict(b, col="none", lc=b["c"], lR=b["R"]), True) for b in LOAD]),
    ),
    stats=dict(bodyBlocks=len(body), bodyTriangles=len(body)*12, bodyColors=6,
               rule01_fixed=fixed, rule01_remaining=remaining, rotatedSameOrientConflicts=len(rot_conf),
               rotatedBlocks=sum(1 for b in body if not is_axis(b)),
               sizeUnits=[r(v, 2) for v in size], sizeStuds=[r(v/2, 2) for v in size],
               sizeStudsInGame=[r(v/2*1.05, 2) for v in size],
               pickaxeBlocks=len(pick), swordBlocks=len(sword), boxBlocks=len(box)),
)
json.dump(data, open(os.path.join(OUT, "clay_golem_blocks.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)

# --- Lua (формат WoodenGolemData) ---
def f(x, nd=4):
    t = (("%." + str(nd) + "f") % x).rstrip("0").rstrip("."); return "0" if t in ("-0", "") else t
L = ["-- Clay Golem: палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада). Згенеровано clay_golem_generator.py.",
     "-- Pickaxe / Sword — глиняні предмети в кулаці Fist_L (для префабів ClayPickaxe / ClaySword). Ящичок — clay_golem_blocks.json → prefabs.ClayCarryBox.",
     "return {", " colors={" + ",".join(f'{k}="{v}"' for k, v in COLORS.items()) + "},", " bones={"]
for n, par, pos in BONES:
    L.append('  {name="%s",parent=%s,pos=Vector3.new(%s)},' % (n, f'"{par}"' if par else "nil", ",".join(f(v) for v in pos)))
L += [" },", " blocks={"]
for b in data["blocks"]:
    gg = f'group="{b["group"]}",' if b.get("group") else ""
    L.append('  {name="%s",%sbone="%s",col="%s",cf=CFrame.new(%s),s=Vector3.new(%s)},' % (
        b["name"], gg, b["bone"], b["col"], ",".join(f(v, 5) for v in b["cf"]), ",".join(f(v) for v in b["s"])))
L += [" },", "}"]
open(os.path.join(OUT, "ClayGolemData.lua"), "w", encoding="utf-8").write("\n".join(L) + "\n")

rep = (f"Блоків тіла: {len(body)} (повернутих: {data['stats']['rotatedBlocks']})\nТрикутників: {len(body)*12}\n"
       f"Кольорів тіла: 6 (+ dry лише в предметах)\nПравило 0,1: виправлено {fixed}, залишилось {remaining}; "
       f"повернуті з однаковою орієнтацією: {len(rot_conf)} {rot_conf}\n"
       f"Розмір (од.): {size[0]:.2f} x {size[1]:.2f} x {size[2]:.2f}; стади: {size[0]/2:.2f} x {size[1]/2:.2f} x {size[2]/2:.2f}; "
       f"у грі (size 1.05): {size[0]/2*1.05:.2f} x {size[1]/2*1.05:.2f} x {size[2]/2*1.05:.2f}\n"
       f"Кірка: {len(pick)} блоків, кінчик {pick_tip.round(3)}; меч: {len(sword)}; ящичок: {len(box)} (+10 гнізд), 0,1: виправлено {box_fixed}, залишилось {box_rem}\n")
open(os.path.join(HERE, "clay_golem_report.txt"), "w", encoding="utf-8").write(rep)
print(rep)
