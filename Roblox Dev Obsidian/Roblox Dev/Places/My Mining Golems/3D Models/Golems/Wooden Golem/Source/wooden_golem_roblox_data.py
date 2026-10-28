"""Wooden Golem -> GolemData (формат Stone Golem v2) + дерев'яні кірка й меч.
Блоки тіла: wooden_golem_generator.py (після правила 0,1); кістки й прив'язка: як у wooden_golem_rig.py.
Кірка: блоки Stone-кірки (pickaxe_generator.py, хват у Fist_L) зсунуті на різницю центрів кулаків, дерев'яні кольори.
Меч: нові блоки вздовж тієї ж осі хвату, що й держак кірки.

Запуск:  python wooden_golem_roblox_data.py  ->  WoodenGolemData.lua (вміст ModuleScript GolemData у Studio)."""
import math, re
import numpy as np
import wooden_golem_generator as G   # пише WoodenGolem_Static.glb і blocks.json поруч — це нормально

blocks = G.blocks
shift = np.array(G.shift)
# блоки кірки Stone Golem (ReplicatedStorage/PlotAssets/Golem/GolemData, згенеровані pickaxe_generator.py; хват у Fist_L Stone)
stone_src = r'''
  {name="Handle",group="Pickaxe",bone="Forearm_L",col="wood",cf=CFrame.new(-5.3000,4.0894,3.5186,1.00000,0.00000,0.00000,0.00000,0.12170,-0.99257,0.00000,0.99257,0.12170),s=Vector3.new(0.6000,9.2000,0.6000)},
  {name="Grip",group="Pickaxe",bone="Forearm_L",col="wood_dk",cf=CFrame.new(-5.3000,3.6757,0.1439,0.98007,0.00000,0.19867,0.19719,0.12170,-0.97278,-0.02418,0.99257,0.11927),s=Vector3.new(0.8000,2.4000,0.8000)},
  {name="Pommel",group="Pickaxe",bone="Forearm_L",col="metal_dk",cf=CFrame.new(-5.3000,3.4992,-1.2953,0.71091,0.00000,0.70328,0.69805,0.12170,-0.70563,-0.08559,0.99257,0.08652),s=Vector3.new(1.0000,0.6000,1.0000)},
  {name="Band",group="Pickaxe",bone="Forearm_L",col="wood_dk",cf=CFrame.new(-5.3000,4.1381,3.9156,0.85252,0.00000,0.52269,0.51880,0.12170,-0.84619,-0.06361,0.99257,0.10375),s=Vector3.new(0.7500,0.4000,0.7500)},
  {name="Head",group="Pickaxe",bone="Forearm_L",col="metal_dk",cf=CFrame.new(-5.3000,4.6614,8.1837,1.00000,0.00000,0.00000,0.00000,0.12170,-0.99257,0.00000,0.99257,0.12170),s=Vector3.new(1.4000,1.6000,1.8000)},
  {name="HeadRound",group="Pickaxe",bone="Forearm_L",col="metal_dk",cf=CFrame.new(-5.3000,4.6675,8.2333,0.70739,0.00000,0.70683,0.70157,0.12170,-0.70213,-0.08602,0.99257,0.08609),s=Vector3.new(1.1000,2.0000,1.1000)},
  {name="HeadCap",group="Pickaxe",bone="Forearm_L",col="metal",cf=CFrame.new(-5.3000,4.7770,9.1266,0.95534,0.00000,0.29552,0.29332,0.12170,-0.94824,-0.03596,0.99257,0.11626),s=Vector3.new(0.9000,0.4000,0.9000)},
  {name="Pick1",group="Pickaxe",bone="Forearm_L",col="metal",cf=CFrame.new(-5.3000,3.1168,8.3227,1.00000,0.00000,0.00000,0.00000,0.02200,-0.99976,0.00000,0.99976,0.02200),s=Vector3.new(1.0000,1.0500,1.9000)},
  {name="Pick2",group="Pickaxe",bone="Forearm_L",col="metal",cf=CFrame.new(-5.3000,1.6172,8.3557,1.00000,0.00000,0.00000,0.00000,-0.19671,-0.98046,0.00000,0.98046,-0.19671),s=Vector3.new(0.8000,0.8000,1.6000)},
  {name="Pick3",group="Pickaxe",bone="Forearm_L",col="metal",cf=CFrame.new(-5.3000,0.4407,8.1196,1.00000,0.00000,0.00000,0.00000,-0.41505,-0.90980,0.00000,0.90980,-0.41505),s=Vector3.new(0.6000,0.6000,1.3000)},
  {name="Pick4",group="Pickaxe",bone="Forearm_L",col="metal",cf=CFrame.new(-5.3000,-0.3327,7.7668,1.00000,0.00000,0.00000,0.00000,-0.62724,-0.77883,0.00000,0.77883,-0.62724),s=Vector3.new(0.4000,0.4000,0.9000)},
  {name="Back1",group="Pickaxe",bone="Forearm_L",col="metal",cf=CFrame.new(-5.3000,5.9457,7.9758,1.00000,0.00000,0.00000,0.00000,0.22018,-0.97546,0.00000,0.97546,0.22018),s=Vector3.new(1.0000,1.0000,1.4000)},
  {name="Back2",group="Pickaxe",bone="Forearm_L",col="metal",cf=CFrame.new(-5.3000,6.8723,7.7667,1.00000,0.00000,0.00000,0.00000,0.49861,-0.86682,0.00000,0.86682,0.49861),s=Vector3.new(0.8000,0.7000,1.0000)},
  {name="PickGlint",group="Pickaxe",bone="Forearm_L",col="light",cf=CFrame.new(-5.3000,1.5346,8.7675,1.00000,0.00000,0.00000,0.00000,-0.19671,-0.98046,0.00000,0.98046,-0.19671),s=Vector3.new(1.0000,0.2500,0.5000)},
  {name="BackFlat",group="Pickaxe",bone="Forearm_L",col="metal_dk",cf=CFrame.new(-5.3000,7.3491,7.4924,1.00000,0.00000,0.00000,0.00000,0.49861,-0.86682,0.00000,0.86682,0.49861),s=Vector3.new(1.1500,1.0000,0.3000)},
'''

def bone_for(name):
    base, _, s = name.partition("_")
    if base in ("Foot", "Shin", "ShinMoss", "CalfPlate"): return f"Shin_{s}"
    if base in ("Thigh", "ThighMoss"): return f"Thigh_{s}"
    if base == "Pelvis": return "Hips"
    if base in ("UpperArm", "ArmMoss"): return f"UpperArm_{s}"
    if base in ("Forearm", "ForearmLeaf", "Fist", "Fingers", "Thumb"): return f"Forearm_{s}"
    if base == "EyeWhite": return f"Eye_{s}"
    if base in ("Iris", "Pupil", "EyeShine"): return f"Pupil_{s}"
    if base == "Brow": return f"Brow_{s}"
    if base == "Mouth": return "Mouth"
    if base == "MouthCorner": return f"MouthCorner_{s}"
    if base.startswith("Sprout"): return "Leaves"
    if base == "SideLeaf": return f"SideLeaf_{s}"
    if base in ("Head", "Muzzle", "LeafCap", "Cheek"): return "Head"
    return "Torso"
C = {b["name"]: np.array(b["c"]) for b in blocks}
BONES = [("Root", None, (0, 0, 0)), ("Hips", "Root", (0, 5.4, 0)), ("Torso", "Hips", (0, 6.2, 0)),
    ("Head", "Torso", (0, 10.4, 0.4)), ("Leaves", "Head", (0, 14.3, 0.2)),
    ("SideLeaf_R", "Head", (2.4, 13.3, 0)), ("SideLeaf_L", "Head", (-2.4, 13.3, 0)),
    ("UpperArm_R", "Torso", (4.7, 9.3, 0)), ("Forearm_R", "UpperArm_R", (5.0, 6.9, 0.3)),
    ("UpperArm_L", "Torso", (-4.7, 9.3, 0)), ("Forearm_L", "UpperArm_L", (-5.0, 6.9, 0.3)),
    ("Thigh_R", "Hips", (1.8, 5.2, 0)), ("Shin_R", "Thigh_R", (1.9, 3.6, 0)),
    ("Thigh_L", "Hips", (-1.8, 5.2, 0)), ("Shin_L", "Thigh_L", (-1.9, 3.6, 0))]
for s in ("R", "L"):
    BONES += [(f"Eye_{s}", "Head", C[f"EyeWhite_{s}"]), (f"Pupil_{s}", f"Eye_{s}", C[f"Pupil_{s}"]), (f"Brow_{s}", "Head", C[f"Brow_{s}"])]
BONES += [("Mouth", "Head", C["Mouth"]), ("MouthCorner_R", "Head", C["MouthCorner_R"]), ("MouthCorner_L", "Head", C["MouthCorner_L"])]

def f(x, nd=4):
    t = (("%." + str(nd) + "f") % x).rstrip("0").rstrip(".")
    return "0" if t in ("-0", "") else t
def v3(p): return "Vector3.new(%s)" % ",".join(f(x) for x in p)
def cfs(p, R):
    return "CFrame.new(%s,%s)" % (",".join(f(x) for x in p), ",".join(f(x, 5) for x in np.array(R).flatten()))
def rz(a):
    c, s = math.cos(a), math.sin(a); return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])

out = []
for b in blocks:
    p = np.array(b["c"]) + shift
    out.append(dict(name=b["name"], bone=bone_for(b["name"]), col=b["col"], p=p, R=rz(b["rz"]), s=np.array(b["s"])))

# --- кірка: блоки зі Stone GolemData ---
fistS = np.array([-5.3, 3.7, 0.3424])
fistW = C["Fist_L"] + shift
d = fistW - fistS
PICK_COL = {"Handle": "main", "Grip": "moss", "Pommel": "dark", "Band": "moss", "Head": "dark", "HeadRound": "dark",
            "HeadCap": "leaf", "Pick1": "plank", "Pick2": "plank", "Pick3": "plank", "Pick4": "plank",
            "Back1": "plank", "Back2": "plank", "PickGlint": "light", "BackFlat": "dark"}
pat = re.compile(r'\{name="(\w+)",group="Pickaxe",bone="Forearm_L",col="\w+",cf=CFrame\.new\(([^)]*)\),s=Vector3\.new\(([^)]*)\)\}')
handleR = None
for m in pat.finditer(stone_src):
    n = m.group(1); v = [float(x) for x in m.group(2).split(",")]; s = [float(x) for x in m.group(3).split(",")]
    R = np.array(v[3:]).reshape(3, 3)
    if n == "Handle": handleR = R
    out.append(dict(name=n, group="Pickaxe", bone="Forearm_L", col=PICK_COL[n], p=np.array(v[:3]) + d, R=R, s=np.array(s)))
assert sum(1 for o in out if o.get("group") == "Pickaxe") == 15
# --- меч: вісь хвату = вісь Y держака кірки ---
ax = handleR[:, 1]  # напрям уперед-вгору від кулака
grip0 = fistW + np.array([0, -0.05, -0.2])
SW = [  # name, відстань уздовж осі від центру кулака, розмір (X, вздовж осі, поперек), колір
    ("SwordPommel", -2.45, (0.9, 0.6, 0.9), "dark"),
    ("SwordGrip", -0.3, (0.7, 3.8, 0.7), "main"),
    ("SwordVine", -1.8, (0.85, 0.4, 0.85), "moss"),      # лоза на руків'ї
    ("SwordGuard", 2.0, (0.8, 0.6, 2.6), "dark"),         # гарда-брусок
    ("SwordBlade", 5.6, (0.35, 6.6, 1.3), "plank"),       # лезо зі струганої дошки
    ("SwordStripe", 5.4, (0.55, 4.8, 0.35), "main"),      # темніша смуга-дол
    ("SwordTip", 9.2, (0.3, 0.8, 0.7), "plank"),
]
for n, t, s, col in SW:
    out.append(dict(name=n, group="Sword", bone="Forearm_L", col=col, p=grip0 + ax * t, R=handleR, s=np.array(s)))

COLORS = {"main": "#8b5e3c", "dark": "#6f4e37", "leaf": "#a7c957", "moss": "#5e8f3a", "light": "#f7e1a3",
          "orange": "#e6a94d", "pupil": "#1c2836", "plank": "#c8955a"}
L = ["-- Wooden Golem (= колишній Forest Golem): палітра, кістки й блоки (координати моделі в стані спокою, 1 од. = 0,5 стада).",
     "-- Тіло — forest_golem_generator.py + forest_golem_rig.py (59 блоків, 24 кістки); формат як у Stone Golem v2.",
     "-- Pickaxe — блоки Stone-кірки (pickaxe_generator.py), зсунуті в кулак Fist_L, дерев'яні кольори; Sword — дерев'яний меч (видно лише у воїна).",
     "return {",
     " colors={" + ",".join(f'{k}="{v}"' for k, v in COLORS.items()) + "},",
     " bones={"]
for n, par, p in BONES:
    L.append('  {name="%s",parent=%s,pos=%s},' % (n, f'"{par}"' if par else "nil", v3(np.array(p, float) + shift)))
L.append(" },")
L.append(" blocks={")
for o in out:
    g = f'group="{o["group"]}",' if o.get("group") else ""
    L.append('  {name="%s",%sbone="%s",col="%s",cf=%s,s=%s},' % (o["name"], g, o["bone"], o["col"], cfs(o["p"], o["R"]), v3(o["s"])))
L.append(" },")
L.append("}")
open("WoodenGolemData.lua", "w", encoding="utf-8").write("\n".join(L) + "\n")
print(len(out), "blocks;", len(BONES), "bones; fist delta", d)
print({k: sum(1 for o in out if o.get("group") == k) for k in ("Pickaxe", "Sword", None)})
