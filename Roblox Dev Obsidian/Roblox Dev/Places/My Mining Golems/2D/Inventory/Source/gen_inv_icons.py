# Власні іконки інвентаря в стилі пака: вкладки Golems (голова кам'яного голема), Ores/Bars (руда + злиток), Potions (колба).
# Будівельні функції — з gen_own_icons.py (видавлювання ext, клин-блик wedge, clip, poly). Контур #040435.
import math
from gen_own_icons import N, svg, ext, wedge, clip, poly

def unit(a, b):
    dx, dy = b[0]-a[0], b[1]-a[1]; l = math.hypot(dx, dy); return (dx/l, dy/l)
def P(pts): return "M" + " L".join(f"{x} {y}" for x, y in pts) + "Z"

# ---------- Golems: квадратна кам'яна голова, світні очі, кристал на лобі ----------
# pal: face, light, dark, side, brow, eye, crystal (light, dark)
GOLEM_PALS = {
    "stone":  ("#a3aebb", "#c3ccd6", "#7f8a98", "#6b7684", "#5d6876", "#5ff3ff", ("#7ff7e4", "#22b8a8")),
    "wood":   ("#c98a52", "#e0a86e", "#a36a38", "#8a5428", "#6e4220", "#ffd34d", ("#9df26a", "#3fa832")),
    "iron":   ("#cfd6df", "#eef2f6", "#a7b1bd", "#8a95a3", "#6b7684", "#ff6b5e", ("#ff9ab0", "#d8214b")),
    "gold":   ("#ffc531", "#ffe27a", "#e0960f", "#c97a06", "#a85f08", "#ffffff", ("#9fd8ff", "#1c68c4")),
    "crystal":("#b88af7", "#d6b8ff", "#8a5ad8", "#6b3fb8", "#4d2a8a", "#fff36b", ("#ffffff", "#c9a6ff")),
}
HEAD = "M54 82 H202 V212 H54Z"
def golem(kind="stone"):
    f, l, dk, side, brow, eye, (cl, cd) = GOLEM_PALS[kind]
    d = clip("gh", HEAD)
    s = '<g transform="rotate(-6 128 140)">'
    s += ext(HEAD, 10, -1, -1, side)
    s += f'<path d="{HEAD}" fill="{f}"/>'
    s += poly([(40, 70), (150, 70), (90, 140), (40, 140)], l, "gh")                 # світла грань угорі ліворуч
    s += poly([(40, 186), (220, 180), (220, 230), (40, 230)], dk, "gh")             # нижня темна смуга (щелепа)
    # брова
    s += f'<path d="M66 112 H190 V132 H66Z" fill="{brow}"/>'
    # очі: квадрати з білим центром
    for ex in (78, 144):
        e = f"M{ex} 138 H{ex+34} V166 H{ex}Z"
        s += f'<path d="{e}" fill="{N}" stroke="{N}" stroke-width="8" stroke-linejoin="round"/><path d="{e}" fill="{eye}"/>'
        s += f'<path d="M{ex+6} 144 H{ex+18} V156 H{ex+6}Z" fill="#fff"/>'
    # рот
    s += f'<path d="M98 186 H158 V198 H98Z" fill="{N}"/>'
    # тріщина
    s += f'<path d="M186 88 L176 104 L186 112" stroke="{dk}" stroke-width="5" fill="none" stroke-linejoin="round" stroke-linecap="round"/>'
    # кристал на лобі (ромб, видавлений)
    cr = "M128 40 L152 78 L128 104 L104 78Z"
    s += f'<path d="{cr}" fill="{N}" stroke="{N}" stroke-width="22" stroke-linejoin="round"/>'
    s += f'<path d="{cr}" fill="{cl}"/><path d="M128 40 L152 78 L128 78Z" fill="{cd}"/><path d="M104 78 L128 104 L128 78Z" fill="{cd}" opacity=".55"/>'
    s += f'<clipPath id="gc"><path d="{cr}"/></clipPath><g clip-path="url(#gc)">' + wedge(112, 72, unit((104,78),(128,40)), unit((104,78),(128,104)), 22, 12) + '</g>'
    # блики голови
    s += '<g clip-path="url(#gh)">' + wedge(60, 88, (1, 0), (0, 1), 40, 36) + wedge(196, 206, (-1, 0), (0, -1), 22, 18) + '</g>'
    s += '</g>'
    return svg(s, d)

# ---------- Ores/Bars: мідна руда (кристали з каменя) позаду + золотий злиток спереду ----------
ROCK = "M44 150 L64 116 L110 104 L160 112 L188 140 L176 170 L120 184 L62 178Z"
CR1 = [(70, 128), (60, 74), (78, 52), (96, 70), (98, 124)]
CR2 = [(102, 120), (106, 50), (128, 26), (150, 50), (146, 120)]
CR3 = [(148, 126), (156, 80), (176, 64), (190, 86), (176, 134)]
BAR_TOP = [(104, 150), (196, 150), (218, 176), (82, 176)]
BAR_FRONT = [(82, 176), (218, 176), (218, 212), (82, 212)]
BAR = P([(104, 150), (196, 150), (218, 176), (218, 212), (82, 212), (82, 176)])
def orebars():
    d = clip("cr", ROCK) + clip("c1", P(CR1)) + clip("c2", P(CR2)) + clip("c3", P(CR3)) + clip("cb", BAR)
    s = '<g transform="rotate(-6 128 128)">'
    back = [P(CR1), P(CR2), P(CR3), ROCK]
    # спільний контур і видавлювання для руди
    s += f'<g fill="{N}" stroke="{N}" stroke-width="26" stroke-linejoin="round">' + ''.join(
        f'<path d="{p}" transform="translate({-k},{-k})"/>' for p in back for k in range(0, 9)) + '</g>'
    s += f'<g fill="#c4581f" stroke="#c4581f" stroke-width="1">' + ''.join(
        f'<path d="{p}" transform="translate({-k},{-k})"/>' for p in back[:3] for k in range(1, 9)) + '</g>'
    s += f'<g fill="#6b7684" stroke="#6b7684" stroke-width="1">' + ''.join(
        f'<path d="{ROCK}" transform="translate({-k},{-k})"/>' for k in range(1, 9)) + '</g>'
    for c, cid in ((CR1, "c1"), (CR2, "c2"), (CR3, "c3")):
        s += poly(c, "#ff8a3d")
        mx = sum(x for x, _ in c) / len(c)
        s += poly([(mx, 0), (240, 0), (240, 200), (mx, 200)], "#e0662a", cid)       # тінь праворуч
        s += poly([(0, 0), (mx - 6, 0), (mx - 6, 200), (0, 200)], "#ffb27a", cid)   # світло ліворуч
    s += f'<path d="{ROCK}" fill="#a3aebb"/>'
    s += poly([(30, 90), (200, 90), (200, 136), (30, 150)], "#c3ccd6", "cr")
    s += poly([(30, 166), (200, 156), (200, 200), (30, 200)], "#7f8a98", "cr")
    s += '<g clip-path="url(#c2)">' + wedge(110, 56, unit((106,50),(128,26)), (0.05, 1), 26, 30) + '</g>'
    # злиток
    s += ext(BAR, 8, -1, -1, "#c97a06")
    s += poly(BAR_FRONT, "#ffbd2b") + poly(BAR_TOP, "#ffe27a")
    s += poly([(196, 150), (218, 176), (218, 212), (206, 212)], "#e0960f", "cb")
    s += f'<path d="M82 176 H218" stroke="#d4780f" stroke-width="4"/>'
    s += '<g clip-path="url(#cb)">' + wedge(108, 153, (1, 0), unit((104,150),(82,176)), 34, 18) + wedge(88, 180, (1, 0), (0, 1), 22, 20) + '</g>'
    s += '</g>'
    return svg(s, d)

# ---------- Potions: кругла колба з корком, рідина, бульбашки ----------
POT_PALS = {
    "purple": ("#c86bff", "#8a2be2", "#e2b0ff"),
    "green":  ("#7ef05a", "#2fae3a", "#c4ff9e"),
    "blue":   ("#5cc8ff", "#1c7fd8", "#b8ecff"),
    "gold":   ("#ffd23a", "#e0900f", "#fff0a0"),
    "red":    ("#ff5c6e", "#c4123b", "#ffb0bb"),
}
BULB = "M128 96 C178 96 196 132 196 160 C196 200 166 222 128 222 C90 222 60 200 60 160 C60 132 78 96 128 96Z"
NECK = "M106 52 H150 V108 H106Z"
CORK = "M98 30 H158 V60 H98Z"
def potion(kind="purple"):
    lq, ld, ll = POT_PALS[kind]
    d = clip("pb", BULB) + clip("pk", CORK)
    s = '<g transform="rotate(8 128 128)">'
    s += f'<g fill="{N}" stroke="{N}" stroke-width="26" stroke-linejoin="round">' + ''.join(
        f'<path d="{p}" transform="translate({-k},{-k})"/>' for p in (BULB, NECK, CORK) for k in range(0, 9)) + '</g>'
    s += f'<g fill="#7fb0c8" stroke="#7fb0c8" stroke-width="1">' + ''.join(
        f'<path d="{p}" transform="translate({-k},{-k})"/>' for p in (BULB, NECK) for k in range(1, 9)) + '</g>'
    s += f'<g fill="#8a5428" stroke="#8a5428" stroke-width="1">' + ''.join(f'<path d="{CORK}" transform="translate({-k},{-k})"/>' for k in range(1, 9)) + '</g>'
    # скло
    s += f'<path d="{NECK}" fill="#d8f2ff"/><path d="{BULB}" fill="#d8f2ff"/>'
    # рідина (нижні ~2/3 колби) з хвилею
    s += f'<g clip-path="url(#pb)"><path d="M40 146 Q84 132 128 146 Q172 160 216 146 V240 H40Z" fill="{lq}"/>'
    s += f'<path d="M128 140 V240 H216 V140Z" fill="{ld}" opacity=".55"/>'
    s += f'<path d="M40 146 Q84 132 128 146 Q172 160 216 146 V154 Q172 168 128 154 Q84 140 40 154Z" fill="{ll}"/>'
    for bx, by, br in ((100, 182, 9), (126, 200, 6), (150, 176, 5)):
        s += f'<circle cx="{bx}" cy="{by}" r="{br}" fill="#fff" opacity=".9"/>'
    s += '</g>'
    # корок
    s += f'<path d="{CORK}" fill="#c98a52"/>' + poly([(128, 20), (170, 20), (170, 70), (128, 70)], "#a36a38", "pk")
    s += f'<path d="M98 50 H158" stroke="#8a5428" stroke-width="4"/>'
    # блики: півмісяць на колбі ліворуч угорі (кругла форма) + клин на шийці
    s += '<g clip-path="url(#pb)"><path d="M76 150 Q78 112 116 104 Q88 118 84 152Z" fill="#fff"/></g>'
    s += f'<clipPath id="pn"><path d="{NECK}"/></clipPath><g clip-path="url(#pn)">' + wedge(110, 56, (1, 0), (0, 1), 14, 30) + '</g>'
    s += '</g>'
    return svg(s, d)

if __name__ == "__main__":
    out = {"tab_golems": golem("stone"), "tab_orebars": orebars(), "tab_potions": potion("purple")}
    for k in GOLEM_PALS: out["golem_" + k] = golem(k)
    for k in POT_PALS: out["potion_" + k] = potion(k)
    for k, v in out.items(): open(k + ".svg", "w").write(v)
    print(list(out))

# ---------- Trash (кнопка видалення): світлий смітник з кришкою ----------
TBODY = "M64 98 H192 L178 222 H78Z"
TLID = "M48 72 H208 V100 H48Z"
THANDLE = "M100 48 H156 V76 H100Z"
def trash():
    d = clip("tb", TBODY) + clip("tl", TLID)
    s = '<g transform="rotate(-6 128 140)">'
    s += f'<g fill="{N}" stroke="{N}" stroke-width="26" stroke-linejoin="round">' + ''.join(
        f'<path d="{p}" transform="translate({-k},{-k})"/>' for p in (THANDLE, TLID, TBODY) for k in range(0, 9)) + '</g>'
    s += f'<g fill="#9fb0c8" stroke="#9fb0c8" stroke-width="1">' + ''.join(
        f'<path d="{p}" transform="translate({-k},{-k})"/>' for p in (THANDLE, TLID, TBODY) for k in range(1, 9)) + '</g>'
    s += f'<path d="{THANDLE}" fill="#dfe6f2"/><path d="M114 60 H142 V76 H114Z" fill="{N}"/>'
    s += f'<path d="{TBODY}" fill="#eef2f8"/>' + poly([(128, 90), (220, 90), (220, 230), (128, 230)], "#d3dbe8", "tb")
    s += f'<path d="{TLID}" fill="#f6f8fc"/>' + poly([(128, 60), (220, 60), (220, 110), (128, 110)], "#dde4f0", "tl")
    for x1, x2 in ((98, 102), (128, 128), (158, 154)):
        s += f'<path d="M{x1} 124 L{x2} 198" stroke="#8e9db6" stroke-width="10" stroke-linecap="round"/>'
    s += '<g clip-path="url(#tl)">' + wedge(54, 76, (1, 0), (0, 1), 34, 20) + '</g>'
    s += '<g clip-path="url(#tb)">' + wedge(70, 104, (1, 0), unit((64,98),(78,222)), 26, 40) + '</g>'
    s += '</g>'
    return svg(s, d)

# ---------- Lock (кнопка блокування / значок на слоті): золотий замок зі сріблястою дужкою ----------
LBODY = "M60 116 H196 V214 H60Z"
def lock():
    d = clip("lb", LBODY)
    s = '<g transform="rotate(-6 128 150)">'
    sh = "M86 118 V86 Q86 44 128 44 Q170 44 170 86 V118"
    s += f'<path d="{sh}" fill="none" stroke="{N}" stroke-width="50" stroke-linecap="round"/>'
    s += ext(LBODY, 9, -1, -1, "#c97a06")
    s += f'<path d="{sh}" fill="none" stroke="#b9c3cf" stroke-width="24"/>'
    s += f'<path d="M86 118 V86 Q86 44 128 44" fill="none" stroke="#e6ecf3" stroke-width="10"/>'
    s += f'<path d="{LBODY}" fill="#ffc531"/>' + poly([(40, 100), (128, 100), (90, 170), (40, 170)], "#ffe27a", "lb")
    s += poly([(40, 186), (220, 182), (220, 230), (40, 230)], "#e0960f", "lb")
    kh = "M128 140 A14 14 0 1 1 127.9 140 Z"
    s += f'<circle cx="128" cy="154" r="15" fill="{N}"/><path d="M120 160 H136 L140 192 H116Z" fill="{N}"/>'
    s += '<g clip-path="url(#lb)">' + wedge(66, 122, (1, 0), (0, 1), 40, 34) + wedge(190, 208, (-1, 0), (0, -1), 20, 16) + '</g>'
    s += '</g>'
    return svg(s, d)

if __name__ == "__main__":
    open("icon_trash.svg", "w").write(trash()); open("icon_lock.svg", "w").write(lock())
