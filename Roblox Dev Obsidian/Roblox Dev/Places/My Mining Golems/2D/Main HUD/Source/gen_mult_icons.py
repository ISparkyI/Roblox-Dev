# Власні іконки множників у стилі пака: VIP (корона) і Map (складена мапа скарбів).
# Будівельні функції — з gen_own_icons.py (видавлювання ext, клин-блик wedge, clip, poly).
import math
from gen_own_icons import N, svg, ext, wedge, clip, poly

def unit(a, b):
    dx, dy = b[0]-a[0], b[1]-a[1]; l = math.hypot(dx, dy); return (dx/l, dy/l)

# ---------- VIP: золота корона з трьома зубцями, кульками й самоцвітами ----------
CROWN = "M46 194 L40 100 L90 134 L128 70 L166 134 L216 100 L210 194 Z"
def vip():
    d = clip("cv", CROWN)
    s = '<g transform="rotate(-10 128 140)">'
    balls = [(40, 92, 15), (128, 60, 16), (216, 92, 15)]
    # контур + видавлювання (корона й кульки разом)
    sil = CROWN
    outl = ''.join(f'<circle cx="{x-k}" cy="{y-k}" r="{r}"/>' for x, y, r in balls for k in range(0, 10))
    s += f'<g fill="{N}" stroke="{N}" stroke-width="26" stroke-linejoin="round">' + ''.join(
        f'<path d="{sil}" transform="translate({-k},{-k})"/>' for k in range(0, 10)) + outl + '</g>'
    s += '<g fill="#d4780f" stroke="#d4780f" stroke-width="1">' + ''.join(
        f'<path d="{sil}" transform="translate({-k},{-k})"/>' for k in range(1, 10)) + ''.join(
        f'<circle cx="{x-k}" cy="{y-k}" r="{r}"/>' for x, y, r in balls for k in range(1, 10)) + '</g>'
    # лице
    s += f'<path d="{CROWN}" fill="#ffbd2b"/>'
    s += poly([(30, 60), (128, 60), (128, 140), (90, 134), (40, 100), (30, 100)], "#ffd35c", "cv")   # світла ліва частина зубців
    s += poly([(128, 60), (230, 60), (230, 150), (166, 134)], "#f7a91f", "cv")                     # тінь праворуч
    s += poly([(30, 150), (230, 146), (230, 210), (30, 210)], "#f59a1c", "cv")                     # обідок
    s += poly([(30, 182), (230, 180), (230, 210), (30, 210)], "#e0800f", "cv")                     # низ обідка
    s += f'<path d="M44 150 L212 146" stroke="{N}" stroke-width="7" stroke-linecap="round"/>'
    # кульки на зубцях
    for x, y, r in balls:
        s += f'<circle cx="{x}" cy="{y}" r="{r}" fill="#ffd35c"/>'
        s += f'<clipPath id="cb{x}"><circle cx="{x}" cy="{y}" r="{r}"/></clipPath>'
        s += f'<path d="M{x} {y-r-2} L{x+r+2} {y-r-2} L{x+r+2} {y+r+2} L{x-r-2} {y+r+2}Z" fill="#f59a1c" clip-path="url(#cb{x})"/>'
        s += f'<g clip-path="url(#cb{x})"><path d="M{x-r+3} {y-2} Q{x-r+2} {y-r+3} {x-1} {y-r+3} Q{x-r+8} {y-r+8} {x-r+3} {y-2}Z" fill="#fff"/></g>'
    # самоцвіти на обідку: червоний ромб по центру, сині квадрати з боків
    gem = "M128 150 L146 166 L128 182 L110 166Z"
    s += f'<path d="{gem}" fill="{N}" stroke="{N}" stroke-width="9" stroke-linejoin="round"/><path d="{gem}" fill="#ff4f78"/>'
    s += '<path d="M128 150 L146 166 L128 166Z" fill="#d8214b"/><path d="M110 166 L128 182 L128 166Z" fill="#ff86a2"/>'
    for gx in (76, 180):
        g = f"M{gx-11} 156 H{gx+11} V178 H{gx-11}Z"
        s += f'<path d="{g}" fill="{N}" stroke="{N}" stroke-width="8" stroke-linejoin="round"/><path d="{g}" fill="#3aa6ff"/>'
        s += f'<path d="M{gx} 156 H{gx+11} V178 Z" fill="#1f86e0"/>'
    # блики: великий — лівий верхній кут обідка (ребро зубця + край обідка), малий — біля центрального зубця
    s += '<g clip-path="url(#cv)">'
    s += wedge(50, 106, unit((40,100),(90,134)), (0.07, 1), 40, 30)
    s += wedge(128, 76, unit((128,70),(90,134)), unit((128,70),(166,134)), 18, 14)
    s += '</g></g>'
    return svg(s, d)

# ---------- Map: складена в три мапа скарбів із пунктиром і червоним X ----------
P1 = [(36, 74), (94, 58), (94, 194), (36, 210)]
P2 = [(94, 58), (162, 78), (162, 214), (94, 194)]
P3 = [(162, 78), (220, 62), (220, 198), (162, 214)]
def path(pts): return "M" + " L".join(f"{x} {y}" for x, y in pts) + "Z"
MAPP = "M36 74 L94 58 L162 78 L220 62 L220 198 L162 214 L94 194 L36 210Z"
def mapicon():
    d = clip("cm", MAPP) + clip("c1", path(P1)) + clip("c2", path(P2)) + clip("c3", path(P3))
    s = '<g transform="rotate(-8 128 136)">'
    s += ext(MAPP, 10, -1, -1, "#b8935c")
    s += poly(P1, "#f6ecd2") + poly(P2, "#dcc79c") + poly(P3, "#f6ecd2")
    # світлі / темні смуги на панелях
    s += poly([(30, 50), (94, 50), (94, 120), (30, 140)], "#fff7e3", "c1")
    s += poly([(156, 150), (230, 140), (230, 230), (156, 230)], "#e7d6b0", "c3")
    s += poly([(90, 150), (170, 168), (170, 230), (90, 230)], "#cfb88a", "c2")
    # згини
    s += f'<path d="M94 58 L94 194 M162 78 L162 214" stroke="#a88a5a" stroke-width="4"/>'
    # острівець і пунктирний шлях
    s += '<g clip-path="url(#cm)"><path d="M48 168 Q60 150 80 156 Q92 164 84 180 Q66 192 52 184Z" fill="#7cc96a"/>'
    s += '<path d="M60 178 Q66 166 76 168" stroke="#4e9a43" stroke-width="5" fill="none" stroke-linecap="round"/></g>'
    s += '<path d="M70 160 Q96 118 128 140 Q156 160 176 118" stroke="#c0562e" stroke-width="7" fill="none" stroke-dasharray="12 10" stroke-linecap="round"/>'
    # червоний X
    for a, b in (((174, 90), (206, 122)), ((206, 90), (174, 122))):
        s += f'<path d="M{a[0]} {a[1]} L{b[0]} {b[1]}" stroke="{N}" stroke-width="22" stroke-linecap="round"/>'
    for a, b in (((174, 90), (206, 122)), ((206, 90), (174, 122))):
        s += f'<path d="M{a[0]} {a[1]} L{b[0]} {b[1]}" stroke="#ff4f5e" stroke-width="10" stroke-linecap="round"/>'
    # блики: великий — лівий верхній кут першої панелі, малий — верх третьої панелі біля згину
    s += '<g clip-path="url(#c1)">' + wedge(40, 78, unit((36,74),(94,58)), (0, 1), 36, 34) + '</g>'
    s += '<g clip-path="url(#c3)">' + wedge(166, 82, unit((162,78),(220,62)), (0, 1), 16, 14) + '</g>'
    s += '</g>'
    return svg(s, d)

if __name__ == "__main__":
    for k, v in {"vip": vip(), "map": mapicon()}.items():
        open(k + ".svg", "w").write(v)
    print("ok")
