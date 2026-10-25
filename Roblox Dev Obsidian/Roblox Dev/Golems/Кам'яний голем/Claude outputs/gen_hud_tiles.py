"""HUD mock: A — як зараз у грі (без підкладок), B — з підкладками стилю A. Вихід: hud_tiles_mock.html"""
import base64, io, json, os
from PIL import Image

SRC = "/mnt/user-data/uploads/Roblox Dev Obsidian/Roblox Dev/Places/My Mining Golems/2D/Main HUD/Roblox/Import"
OUT = os.path.dirname(os.path.abspath(__file__))
names = {"shop": "hud_shop", "index": "hud_index", "quests": "hud_quests", "rebirth": "hud_rebirth", "c_rebirth": "hud_rebirth_c",
         "diamond": "hud_diamond", "ticket": "hud_ticket", "boss": "hud_boss", "multi": "hud_cash", "robux": "hud_robux",
         "invite": "hud_invite", "settings": "hud_settings", "inventory": "hud_inventory", "feedback": "hud_feedback",
         "codes": "hud_codes", "updates": "hud_updates"}
icons, asp = {}, {}
for k, f in names.items():
    im = Image.open(f"{SRC}/{f}.png").convert("RGBA")
    im = im.crop(im.getbbox())
    asp[k] = im.width / im.height
    s = 160 / max(im.size)
    im = im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.LANCZOS)
    b = io.BytesIO(); im.save(b, "PNG", optimize=True)
    icons[k] = "data:image/png;base64," + base64.b64encode(b.getvalue()).decode()
data = json.dumps({"icons": icons, "asp": asp})
html = open(f"{OUT}/hud_tiles_template.html", encoding="utf-8").read().replace("__DATA__", data)
open(f"{OUT}/hud_tiles_mock.html", "w", encoding="utf-8").write(html)
print("ok", len(html))
