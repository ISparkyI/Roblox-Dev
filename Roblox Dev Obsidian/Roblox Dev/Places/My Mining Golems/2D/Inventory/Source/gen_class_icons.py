# Іконки класів големів для фільтра інвентаря (той самий стиль, що gen_inv_icons.py):
# товстий контур #040435, видавлювання ext, світлі/темні грані через clip, білі клини-блики wedge.
# class_all — сітка 2×2 з голівок големів; class_miner — кайло; class_carrier — ящик з рудою; class_warrior — меч.
import math, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "inventory"))
from gen_own_icons import N, svg, ext, wedge, clip, poly

def unit(a, b):
    dx, dy = b[0]-a[0], b[1]-a[1]; l = math.hypot(dx, dy); return (dx/l, dy/l)
def P(pts): return "M" + " L".join(f"{x} {y}" for x, y in pts) + "Z"
def R(x, y, w, h): return f"M{x} {y} H{x+w} V{y+h} H{x}Z"

# ---------- All: сітка 2×2 з маленьких голівок (кольори — камінь, дерево, залізо, кристал) ----------
MINI = [("#a3aebb", "#c3ccd6", "#7f8a98", "#6b7684", "#5ff3ff"),
        ("#c98a52", "#e0a86e", "#a36a38", "#8a5428", "#ffd34d"),
        ("#cfd6df", "#eef2f6", "#a7b1bd", "#8a95a3", "#ff6b5e"),
        ("#b88af7", "#d6b8ff", "#8a5ad8", "#6b3fb8", "#fff36b")]
def all_icon():
    cells = [(40, 40), (138, 40), (40, 138), (138, 138)]
    d = "".join(clip(f"m{i}", R(x, y, 82, 82)) for i, (x, y) in enumerate(cells))
    s = '<g transform="rotate(-6 128 128)">'
    s += f'<g fill="{N}" stroke="{N}" stroke-width="24" stroke-linejoin="round">' + "".join(
        f'<path d="{R(x, y, 82, 82)}" transform="translate({-k},{-k})"/>' for x, y in cells for k in range(0, 8)) + '</g>'
    for i, ((x, y), (f, l, dk, side, eye)) in enumerate(zip(cells, MINI)):
        p = R(x, y, 82, 82)
        s += f'<g fill="{side}" stroke="{side}" stroke-width="1">' + "".join(f'<path d="{p}" transform="translate({-k},{-k})"/>' for k in range(1, 8)) + '</g>'
        s += f'<path d="{p}" fill="{f}"/>'
        s += poly([(x-10, y-10), (x+56, y-10), (x+20, y+40), (x-10, y+40)], l, f"m{i}")
        s += poly([(x-10, y+62), (x+92, y+58), (x+92, y+92), (x-10, y+92)], dk, f"m{i}")
        for ex in (x+14, x+46):  # очі
            s += f'<path d="{R(ex, y+30, 22, 18)}" fill="{N}" stroke="{N}" stroke-width="6" stroke-linejoin="round"/><path d="{R(ex, y+30, 22, 18)}" fill="{eye}"/>'
            s += f'<path d="{R(ex+4, y+34, 7, 7)}" fill="#fff"/>'
        s += f'<g clip-path="url(#m{i})">' + wedge(x+5, y+5, (1, 0), (0, 1), 26, 22) + '</g>'
    s += '</g>'
    return svg(s, d)

# ---------- Miner: кайло (дерев'яне руків'я + сталева дуга з втулкою) ----------
HEADP = "M18 110 Q128 -34 238 110 L222 120 Q128 30 34 120Z"
SOCK = "M106 52 H150 V96 H106Z"
def miner():
    d = clip("ph", HEADP) + clip("ps", SOCK)
    s = '<g transform="rotate(45 128 128) translate(0 6)">'
    hl = "M128 70 V236"
    s += f'<path d="{hl}" stroke="{N}" stroke-width="50" stroke-linecap="round"/>'
    s += f'<path d="{hl}" stroke="#a36a38" stroke-width="26" stroke-linecap="round"/>'
    s += f'<path d="M122 76 V232" stroke="#e0a86e" stroke-width="9" stroke-linecap="round"/>'
    s += f'<path d="M128 196 V216" stroke="#6e4220" stroke-width="26"/>'   # обмотка
    s += ext(HEADP, 8, -1, 1, "#6b7684", 24) + ext(SOCK, 8, -1, 1, "#5d6876", 24)
    s += f'<path d="{HEADP}" fill="#b9c3cf"/>'
    s += f'<path d="M18 110 Q128 -34 238 110 L232 114 Q128 -8 24 114Z" fill="#e6ecf3" clip-path="url(#ph)"/>'
    s += poly([(128, 0), (240, 0), (240, 130), (128, 130)], "#9aa6b4", "ph")
    s += f'<path d="{SOCK}" fill="#8a95a3"/>' + poly([(128, 40), (160, 40), (160, 100), (128, 100)], "#6b7684", "ps")
    s += '<g clip-path="url(#ph)">' + wedge(46, 88, unit((18,110),(80,46)), (0.5, 0.86), 40, 14, .18) + '</g>'
    s += '<g clip-path="url(#ps)">' + wedge(108, 54, (1, 0), (0, 1), 18, 22) + '</g>'
    s += '</g>'
    return svg(s, d)

# ---------- Carrier: дерев'яний ящик (3/4) з рудою зверху ----------
FR = "M44 118 H178 V222 H44Z"                 # передня грань
TOPF = "M44 118 L80 92 H214 L178 118Z"        # верх (відкритий)
SIDE = "M178 118 L214 92 V196 L178 222Z"      # бокова грань
BOXALL = "M44 118 L80 92 H214 V196 L178 222 H44Z"
ROCK = "M70 112 L88 72 L132 62 L176 74 L196 104 L176 120 L92 122Z"
CR1 = [(70, 124), (66, 62), (86, 42), (104, 62), (102, 124)]
CR2 = [(104, 124), (110, 36), (134, 12), (158, 36), (154, 124)]
CR3 = [(150, 124), (160, 72), (182, 58), (198, 84), (180, 124)]
def carrier():
    d = clip("bf", FR) + clip("bs", SIDE) + clip("ro", ROCK) + clip("k1", P(CR1)) + clip("k2", P(CR2)) + clip("k3", P(CR3))
    s = '<g transform="rotate(-6 128 128) translate(0 14)">'
    s += f'<path d="{BOXALL}" fill="{N}" stroke="{N}" stroke-width="24" stroke-linejoin="round"/>'
    s += f'<path d="{TOPF}" fill="#6e4220"/>'
    s += f'<path d="M58 118 L84 100 H200 L178 118Z" fill="#3a2210"/>'     # темна порожнина
    ore = [P(CR1), P(CR2), P(CR3)]
    s += f'<g fill="{N}" stroke="{N}" stroke-width="16" stroke-linejoin="round">' + ''.join(
        f'<path d="{p}" transform="translate({-k},{-k})"/>' for p in ore for k in range(0, 6)) + '</g>'
    s += f'<g fill="#c4581f" stroke="#c4581f" stroke-width="1">' + ''.join(
        f'<path d="{p}" transform="translate({-k},{-k})"/>' for p in ore for k in range(1, 6)) + '</g>'
    for c, cid in ((CR1, "k1"), (CR2, "k2"), (CR3, "k3")):
        s += poly(c, "#ff8a3d")
        mx = sum(x for x, _ in c) / len(c)
        s += poly([(mx, -20), (240, -20), (240, 200), (mx, 200)], "#e0662a", cid)
        s += poly([(0, -20), (mx - 6, -20), (mx - 6, 200), (0, 200)], "#ffb27a", cid)
    s += '<g clip-path="url(#k2)">' + wedge(124, 34, unit((122,28),(144,8)), (0.05, 1), 22, 26) + '</g>'
    s += '<g clip-path="url(#k1)">' + wedge(84, 56, unit((80,52),(98,34)), (0.05, 1), 12, 18) + '</g>'
    s += f'<path d="{SIDE}" fill="#a36a38"/>'
    s += f'<path d="{FR}" fill="#e0a86e"/>'
    # дошки
    for y in (152, 188):
        s += f'<path d="M44 {y} H178" stroke="#a36a38" stroke-width="5"/>'
        s += f'<path d="M178 {y} L214 {y-26}" stroke="#8a5428" stroke-width="5"/>'
    # рамка-окуття: темні планки по краях + діагональ
    s += f'<path d="M50 124 H172 V216 H50Z" fill="none" stroke="#c98a52" stroke-width="12" stroke-linejoin="round"/>'
    s += f'<path d="M56 210 L166 130" stroke="#c98a52" stroke-width="12" stroke-linecap="round"/>'
    s += f'<path d="M44 118 H178 V222 H44Z" fill="none" stroke="{N}" stroke-width="6"/>'
    s += f'<path d="M178 118 L214 92" stroke="{N}" stroke-width="6"/>'
    for x, y in ((56, 130), (166, 130), (56, 210), (166, 210)):
        s += f'<circle cx="{x}" cy="{y}" r="5" fill="{N}"/>'
    s += '<g clip-path="url(#bf)">' + wedge(47, 121, (1, 0), (0, 1), 34, 30) + wedge(175, 219, (-1, 0), (0, -1), 22, 18) + '</g>'
    s += '</g>'
    return svg(s, d)

# ---------- Warrior: меч (срібне лезо, золота гарда, коричневе руків'я, навершя) ----------
BLADE = "M128 10 L154 40 V160 H102 V40Z"
GUARD = "M70 156 Q70 148 78 148 H178 Q186 148 186 156 V172 Q186 180 178 180 H78 Q70 180 70 172Z"
GRIP = "M114 178 H142 V222 H114Z"
def warrior():
    d = clip("sb", BLADE) + clip("sg", GUARD)
    s = '<g transform="rotate(45 128 128) translate(0 4)">'
    s += f'<g fill="{N}" stroke="{N}" stroke-width="24" stroke-linejoin="round">' + ''.join(
        f'<path d="{p}" transform="translate({-k},{k})"/>' for p in (BLADE, GRIP, GUARD) for k in range(0, 8)) + \
        ''.join(f'<circle cx="{128-k}" cy="{234+k}" r="17"/>' for k in range(0, 8)) + '</g>'
    s += f'<g fill="#7f8a98" stroke="#7f8a98" stroke-width="1">' + ''.join(f'<path d="{BLADE}" transform="translate({-k},{k})"/>' for k in range(1, 8)) + '</g>'
    s += f'<g fill="#c97a06" stroke="#c97a06" stroke-width="1">' + ''.join(f'<path d="{GUARD}" transform="translate({-k},{k})"/>' for k in range(1, 8)) + \
        ''.join(f'<circle cx="{128-k}" cy="{234+k}" r="17"/>' for k in range(1, 8)) + '</g>'
    # руків'я
    s += f'<path d="{GRIP}" fill="#8a5428"/>'
    for y in (186, 200, 214):
        s += f'<path d="M114 {y} L142 {y-6}" stroke="#5c3518" stroke-width="5"/>'
    # навершя
    s += '<circle cx="128" cy="234" r="17" fill="#ffc531"/><path d="M128 217 A17 17 0 0 1 128 251Z" fill="#e0960f"/>'
    s += '<circle cx="122" cy="228" r="5" fill="#fff"/>'
    # лезо: світла ліва половина, темніша права, дол посередині
    s += f'<path d="{BLADE}" fill="#e6ecf3"/>' + poly([(128, 0), (170, 0), (170, 170), (128, 170)], "#b9c3cf", "sb")
    s += f'<path d="M128 44 V150" stroke="#9aa6b4" stroke-width="8" stroke-linecap="round"/>'
    s += '<g clip-path="url(#sb)">' + wedge(106, 46, unit((102,40),(128,10)), (0, 1), 30, 70, .14) + '</g>'
    # гарда
    s += f'<path d="{GUARD}" fill="#ffc531"/>' + poly([(60, 168), (200, 164), (200, 190), (60, 190)], "#e0960f", "sg")
    s += '<rect x="118" y="152" width="20" height="20" rx="4" fill="#3aa6ff" stroke="#040435" stroke-width="5"/>'
    s += '<g clip-path="url(#sg)">' + wedge(74, 151, (1, 0), (0, 1), 30, 14) + '</g>'
    s += '</g>'
    return svg(s, d)

if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    out = {"class_all": all_icon(), "class_miner": miner(), "class_carrier": carrier(), "class_warrior": warrior()}
    for k, v in out.items(): open(os.path.join(here, k + ".svg"), "w").write(v)
    print(list(out))
