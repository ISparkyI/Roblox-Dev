# Іконки вікна інвентаря з ЧОРНИМ контуром (#14161a замість темно-синього #040435): наші SVG перегенеровано заміною кольору,
# рюкзак hud_inventory (PNG) — перефарбовано програмно (пікселі, близькі до #040435, зсунуто до #14161a з тією ж альфою).
# Усі PNG — з alpha bleed (прозорі пікселі отримують колір сусідніх), щоб у Roblox не було світлих обводок.
import os, numpy as np
from PIL import Image
from playwright.sync_api import sync_playwright
HERE = os.path.dirname(os.path.abspath(__file__))
UI = os.path.join(HERE, "..")
NAVY, INK = "#040435", "#14161a"
SRC = {  # вихідне ім'я → (svg, розмір PNG)
    "inv_tab_golems": ("inventory/tab_golems.svg", 512), "inv_tab_orebars": ("inventory/tab_orebars.svg", 512),
    "inv_tab_potions": ("inventory/tab_potions.svg", 512), "inv_icon_trash": ("inventory/icon_trash.svg", 512),
    "inv_icon_lock": ("inventory/icon_lock.svg", 512),
    "inv_potion_green": ("inventory/potion_green.svg", 512), "inv_potion_blue": ("inventory/potion_blue.svg", 512),
    "inv_potion_gold": ("inventory/potion_gold.svg", 512), "inv_potion_red": ("inventory/potion_red.svg", 512),
    "inv_class_all": ("inventory_filter/class_all.svg", 128), "inv_class_miner": ("inventory_filter/class_miner.svg", 128),
    "inv_class_carrier": ("inventory_filter/class_carrier.svg", 128), "inv_class_warrior": ("inventory_filter/class_warrior.svg", 128),
}
def bleed(a, passes=8):
    a = a.astype(np.float64); h, w, _ = a.shape; done = a[:, :, 3] >= 24
    for _ in range(passes):
        acc = np.zeros((h, w, 3)); n = np.zeros((h, w))
        for dx, dy in [(1,0),(-1,0),(0,1),(0,-1),(1,1),(-1,-1),(1,-1),(-1,1)]:
            sh = np.roll(np.roll(a[:, :, :3], dy, 0), dx, 1); sd = np.roll(np.roll(done, dy, 0), dx, 1)
            if dy == 1: sd[0, :] = False
            if dy == -1: sd[-1, :] = False
            if dx == 1: sd[:, 0] = False
            if dx == -1: sd[:, -1] = False
            acc += sh * sd[:, :, None]; n += sd
        add = (~done) & (n > 0)
        if not add.any(): break
        a[add, :3] = acc[add] / n[add][:, None]; done |= add
    return a.clip(0, 255).astype(np.uint8)
def fit(im, S, marg):
    im = im.crop(im.getbbox()); m = int(S * marg); sc = (S - 2 * m) / max(im.size)
    im2 = im.resize((round(im.size[0] * sc), round(im.size[1] * sc)), Image.LANCZOS)
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0)); out.paste(im2, ((S - im2.size[0]) // 2, (S - im2.size[1]) // 2), im2); return out
with sync_playwright() as p:
    b = p.chromium.launch(); pg = b.new_page(viewport={"width": 512, "height": 512})
    for name, (svgp, size) in SRC.items():
        svg = open(os.path.join(UI, svgp)).read().replace(NAVY, INK).replace('width="256" height="256"', 'width="512" height="512"')
        pg.set_content(f'<body style="margin:0;background:transparent">{svg}</body>'); pg.wait_for_timeout(60)
        raw = f"/tmp/{name}_blk.png"; pg.screenshot(path=raw, omit_background=True, clip={"x": 0, "y": 0, "width": 512, "height": 512})
        im = fit(Image.open(raw).convert("RGBA"), 512, 0.02)
        if size != 512: im = im.resize((size, size), Image.LANCZOS)
        Image.fromarray(bleed(np.array(im)), "RGBA").save(os.path.join(HERE, name + ".png"), optimize=True)
    b.close()
# рюкзак: перефарбування контуру
src = "/mnt/user-data/uploads/Roblox Dev Obsidian/Roblox Dev/Places/My Mining Golems/2D/Main HUD/Roblox/Import/hud_inventory.png"
a = np.array(Image.open(src).convert("RGBA")).astype(np.float64)
N = np.array([4, 4, 53.]); K = np.array([20, 22, 26.])
d = np.sqrt(((a[:, :, :3] - N) ** 2).sum(2)); wgt = np.clip(1 - d / 90, 0, 1)
a[:, :, :3] += wgt[:, :, None] * (K - N)
Image.fromarray(bleed(a.clip(0, 255).astype(np.uint8)), "RGBA").save(os.path.join(HERE, "inv_title_backpack.png"), optimize=True)
print("ok")
