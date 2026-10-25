# Іконка картки Auto Sell (табло плоту): золота монета «$» у кільці з двох зелених стрілок (автоматично, по колу)
# + мідна руда знизу ліворуч, що «заходить» у цикл. Стиль пака: контур #040435, видавлювання, пласкі грані, клин-блики.
import math, sys
sys.path.insert(0, "/mnt/user-data/outputs/ui/plot_ui")
from gen_own_icons import N, svg, wedge, clip, poly
from gen_forge_icons import P, outline, side, crystal, COPPER, unit

CX, CY = 118, 104
def arc_arrow(a0, a1, r=86, w=26, head=30):
    """дуга-стрічка від a0 до a1 (градуси, за годинниковою), на кінці — наконечник"""
    pts_o, pts_i = [], []
    n = 22
    for k in range(n + 1):
        a = math.radians(a0 + (a1 - a0) * k / n)
        pts_o.append((CX + (r + w / 2) * math.cos(a), CY + (r + w / 2) * math.sin(a)))
        pts_i.append((CX + (r - w / 2) * math.cos(a), CY + (r - w / 2) * math.sin(a)))
    a = math.radians(a1); t = (-math.sin(a), math.cos(a))  # дотична в бік руху
    base_o = (CX + (r + head) * math.cos(a), CY + (r + head) * math.sin(a))
    base_i = (CX + (r - head) * math.cos(a), CY + (r - head) * math.sin(a))
    tip = (CX + r * math.cos(a) + t[0] * head * 1.25, CY + r * math.sin(a) + t[1] * head * 1.25)
    return pts_o + [base_o, tip, base_i] + pts_i[::-1]

def autosell():
    A1 = arc_arrow(178, 318)    # верхня дуга: зліва → праворуч
    A2 = arc_arrow(-2, 138)     # нижня дуга: справа → ліворуч
    coin = f"M{CX-54} {CY} A54 54 0 1 0 {CX+54} {CY} A54 54 0 1 0 {CX-54} {CY}Z"
    OX = 120
    ROCK = f"M{18+OX} 226 L{28+OX} 196 L{64+OX} 184 L{104+OX} 190 L{122+OX} 210 L{116+OX} 230Z"
    C1 = [(x + OX, y) for x, y in [(36, 206), (30, 168), (46, 148), (62, 166), (62, 204)]]
    C2 = [(x + OX, y) for x, y in [(62, 200), (68, 140), (88, 118), (108, 140), (102, 202)]]
    d = clip("a1", P(A1)) + clip("a2", P(A2)) + clip("cn", coin) + clip("r", ROCK) + clip("c1", P(C1)) + clip("c2", P(C2))
    s = outline([P(A1), P(A2)], 9, 24) + side([P(A1), P(A2)], "#237a16", 9)
    s += poly(A1, "#43b62a") + poly(A2, "#43b62a")
    s += poly([(0, -20), (300, -20), (300, 70), (0, 110)], "#8ef05a", "a1") + poly([(0, 90), (300, 60), (300, 150), (0, 150)], "#8ef05a", "a2")
    # монета
    s += outline([coin], 10, 24) + side([coin], "#b0680a", 10)
    s += f'<path d="{coin}" fill="#ffc531"/>'
    s += poly([(-10, -10), (CX - 18, -10), (CX - 58, 300), (-10, 300)], "#ffd86a", "cn")
    s += f'<circle cx="{CX}" cy="{CY}" r="40" fill="none" stroke="#e0960f" stroke-width="6"/>'
    s += f'<text x="{CX}" y="{CY+22}" font-family="Montserrat,Arial Black,Arial" font-weight="900" font-size="64" text-anchor="middle" fill="#fff6d0" stroke="{N}" stroke-width="10" paint-order="stroke fill">$</text>'
    s += '<g clip-path="url(#cn)">' + wedge(CX - 40, CY - 34, unit((CX - 54, CY), (CX - 30, CY - 46)), (1, 0), 30, 14) + '</g>'
    # руда
    s += outline([P(C1), P(C2), ROCK], 8, 24) + side([P(C1), P(C2)], COPPER[3], 8) + side([ROCK], "#6b7684", 8)
    s += crystal(C1, "c1", COPPER[0], COPPER[1], COPPER[2]) + crystal(C2, "c2", COPPER[0], COPPER[1], COPPER[2])
    s += f'<path d="{ROCK}" fill="#a3aebb"/>' + poly([(10 + OX, 176), (130 + OX, 176), (130 + OX, 202), (10 + OX, 212)], "#c3ccd6", "r")
    s += '<g clip-path="url(#c2)">' + wedge(72 + OX, 144, unit((68, 140), (88, 118)), unit((68, 140), (62, 200)), 16, 24) + '</g>'
    return svg(s, d)

open("plot_autosell.svg", "w").write(autosell())
print("ok")
