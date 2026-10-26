# Збирає index_mock.html: шаблон + helpers.js з інвентаря + картинки (base64) + шрифт + дані з GolemCatalog.lua
import base64, json, os, re
V = "/mnt/user-data/uploads/Roblox Dev Obsidian/Roblox Dev"
S = V + "/Style/Roblox/"
F = V + "/Places/My Mining Golems/Interactive Objects/Forge/Roblox/"
HUD = V + "/Places/My Mining Golems/2D/Main HUD/Roblox/Import/"
HERE = os.path.dirname(os.path.abspath(__file__))
INV = os.path.join(HERE, "../inventory")
ROLE = os.path.join(HERE, "../roll_station/icons")
CAT = "/mnt/user-data/outputs/golems/GolemCatalog.lua"

def d(p): return "data:image/png;base64," + base64.b64encode(open(p, "rb").read()).decode()

A = {}
for c in ["green", "gray", "red", "blue", "yellow", "orange"]: A["base_" + c] = d(S + f"stylea_base_{c}.png")
for c in ["green", "gray", "red"]: A["tile_" + c] = d(S + f"stylea_tile_{c}.png")
for c in ["blue", "yellow", "orange", "green", "gray"]: A["tile_" + c + "_half"] = d(S + f"stylea_tile_{c}_half.png")
A["icon_x"] = d(S + "stylea_icon_x.png")
for k in ["stone", "wood", "iron", "gold", "crystal"]: A["golem_" + k] = d(os.path.join(INV, f"golem_{k}.png"))
A["tab_golems"] = d(os.path.join(INV, "tab_golems.png"))
A["tab_orebars"] = d(os.path.join(INV, "tab_orebars.png"))
for k in ["miner", "carrier", "warrior"]: A["role_" + k] = d(os.path.join(ROLE, f"role_{k}.png"))
for k in ["boss", "index", "diamond"]: A["hud_" + k] = d(HUD + f"hud_{k}.png")
for k, f in [("Coal", "forge_ore_coal_v2"), ("Copper", "forge_ore_copper_v2"), ("Iron", "forge_ore_iron_v2")]: A["ore_" + k] = d(F + f + ".png")

# каталог: ORDER, RARITIES, RARITY_COLOR, MUTATIONS, GOLEMS (значення Normal) — прямо з Lua
lua = open(CAT, encoding="utf-8").read()
order = re.findall(r'"(\w+)"', re.search(r"M\.ORDER = \{([^}]*)\}", lua).group(1))
rar = re.findall(r'"(\w+)"', re.search(r"M\.RARITIES = \{([^}]*)\}", lua).group(1))
rcol = dict(re.findall(r'(\w+) = Color3\.fromHex\("(\w+)"\)', re.search(r"M\.RARITY_COLOR = \{(.*?)\n\}", lua, re.S).group(1)))
muts = [{"key": k, "odds": float(o), "color": "#" + c} for k, o, c in re.findall(r'key = "(\w+)", odds = ([\d.]+), color = Color3\.fromHex\("(\w+)"\)', lua)]
num = lambda s: float(s) if "." in s else int(s)
golems = []
for gid in order:
    m = re.search(gid + r' = \{ name = "([^"]+)", rarity = "(\w+)", map = (\d+), odds = ([\d.]+).*?\n\s*miner = \{([^}]*)\},\s*\n\s*carrier = \{([^}]*)\},\s*\n\s*warrior = \{([^}]*)\} \},', lua, re.S)
    st = lambda s: {k: num(v) for k, v in re.findall(r"(\w+) = ([\d.]+)", s)}
    golems.append({"id": gid, "name": m.group(1), "rarity": m.group(2), "map": int(m.group(3)), "odds": num(m.group(4)),
                   "miner": st(m.group(5)), "carrier": st(m.group(6)), "warrior": st(m.group(7))})
assert len(golems) == 24 and len(muts) == 8
CATJS = json.dumps({"order": order, "rarities": rar, "rcol": {k: "#" + v for k, v in rcol.items()}, "muts": muts, "golems": golems})

fd = "/tmp/fonts/node_modules/@fontsource/montserrat/files/montserrat-latin-%s-normal.woff2"
f = lambda w: base64.b64encode(open(fd % w, "rb").read()).decode()
t = open(os.path.join(HERE, "index_template.html"), encoding="utf-8").read()
t = (t.replace("__HELPERS__", open(os.path.join(INV, "helpers.js"), encoding="utf-8").read())
      .replace("__ASSETS__", json.dumps(A)).replace("__CATALOG__", CATJS)
      .replace("__F800__", f(800)).replace("__F900__", f(900)))
open(os.path.join(HERE, "index_mock.html"), "w", encoding="utf-8").write(t)
print(len(t), [g["name"] for g in golems][:3])
