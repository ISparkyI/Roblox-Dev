# Іконки типів голема для карток станції ролу: голова голема (як в інвентарі) + інструмент ролі.
# Miner — кирка, Carrier — ящик з рудою, Warrior — меч і щит. Стиль пака: контур #040435, видавлювання, клин-блики.
import sys, re
sys.path.insert(0, "/mnt/user-data/outputs/ui/plot_ui")
from gen_own_icons import N, svg, wedge, clip, poly
from gen_forge_icons import P, outline, side, unit, COPPER, IRON
from gen_inv_icons import golem

def inner(full, suffix):
    d = re.search(r"<defs>(.*)</defs>", full, re.S).group(1)
    body = full.split("</defs>", 1)[1].rsplit("</svg>", 1)[0]
    for i in set(re.findall(r'id="([^"]+)"', d + body)):
        d = d.replace(f'id="{i}"', f'id="{i}{suffix}"'); body = body.replace(f'id="{i}"', f'id="{i}{suffix}"')
        d = d.replace(f'url(#{i})', f'url(#{i}{suffix})'); body = body.replace(f'url(#{i})', f'url(#{i}{suffix})')
    return d, body

WOOD = ("#9a6a44", "#c08a5c", "#7a5232", "#5c3d24")
STEEL = ("#c9ced4", "#eef2f6", "#9aa2ad", "#6b7684")

def head(kind="stone", tx=-16, ty=-10, sc=0.86):
    d, b = inner(golem(kind), "h" + kind)
    return d, f'<g transform="translate({tx} {ty}) scale({sc})">{b}</g>'

def miner():
    d, h = head("stone", -26, -22, 0.8)
    import math
    B, T = (122, 244), (196, 138)                      # руків'я: низ ліворуч → верх праворуч
    L = math.hypot(T[0] - B[0], T[1] - B[1]); u = ((T[0] - B[0]) / L, (T[1] - B[1]) / L); n = (-u[1], u[0])
    pt = lambda base, a, b: (base[0] + u[0] * a + n[0] * b, base[1] + u[1] * a + n[1] * b)
    w = 9
    HANDLE = [pt(B, -6, -w), pt(B, -6, w), pt(T, 10, w), pt(T, 10, -w)]
    # голівка кирки: дугоподібний «півмісяць» поперек руків'я, обидва кінці гострі
    tA, tB = pt(T, -30, 74), pt(T, -30, -74)
    oA, oM, oB = pt(T, 36, 48), pt(T, 28, 0), pt(T, 36, -48)
    iA, iB = pt(T, -12, 60), pt(T, -12, -60)
    iM = pt(T, 6, 0)
    f = lambda p: f"{p[0]:.1f} {p[1]:.1f}"
    PICK = f"M{f(tA)} Q{f(oA)} {f(oM)} Q{f(oB)} {f(tB)} Q{f(pt(T, 10, -30))} {f(iM)} Q{f(pt(T, 10, 30))} {f(tA)}Z"
    SOCK = [pt(T, -10, -15), pt(T, -10, 15), pt(T, 22, 15), pt(T, 22, -15)]
    d += clip("pk", PICK) + clip("ph", P(HANDLE))
    s = h + outline([P(HANDLE), PICK, P(SOCK)], 8, 22) + side([P(HANDLE)], WOOD[3], 8) + side([PICK], "#4f6278", 8) + side([P(SOCK)], "#3a3f48", 8)
    s += poly(HANDLE, WOOD[0]) + poly([pt(B, -6, -w), pt(T, 10, -w), pt(T, 10, -w + 7), pt(B, -6, -w + 7)], WOOD[1], "ph")
    for k in (0.62, 0.72):  # обмотка руків'я
        a, b = pt(B, L * k, -w - 2), pt(B, L * k, w + 2)
        s += f'<path d="M{f(a)} L{f(b)}" stroke="{WOOD[3]}" stroke-width="6"/>'
    s += f'<path d="{PICK}" fill="#a9bccf"/>'
    s += f'<path d="M{f(tA)} Q{f(oA)} {f(oM)} L{f(pt(T, 18, 0))} Q{f(pt(T, 24, 34))} {f(pt(T, -16, 58))}Z" fill="#e4eef8" clip-path="url(#pk)"/>'
    s += poly(SOCK, "#5a616c")
    return svg(s, d)

def carrier():
    d, h = head("wood", -8, -18, 0.8)
    TOP = [(118, 168), (190, 150), (238, 170), (166, 190)]
    LF = [(118, 168), (166, 190), (166, 238), (118, 214)]
    RF = [(166, 190), (238, 170), (238, 216), (166, 238)]
    SIL = [(118, 168), (190, 150), (238, 170), (238, 216), (166, 238), (118, 214)]
    d += clip("ct", P(TOP)) + clip("cl", P(LF)) + clip("cr", P(RF))
    s = h + outline([P(SIL)], 8, 22) + side([P(SIL)], WOOD[3], 8)
    s += poly(LF, WOOD[0]) + poly(RF, WOOD[2]) + poly(TOP, "#2c2f35")
    # руда в ящику (кристали міді й заліза над краєм)
    for pts, pal in (([(140, 172), (146, 146), (158, 136), (166, 152), (162, 176)], COPPER), ([(170, 176), (178, 140), (192, 128), (200, 146), (194, 178)], IRON), ([(198, 172), (206, 152), (216, 148), (220, 162), (214, 176)], COPPER)):
        s += f'<path d="{P(pts)}" fill="{pal[0]}" stroke="{N}" stroke-width="7" stroke-linejoin="round"/>'
        mx = sum(x for x, _ in pts) / len(pts)
        s += f'<path d="M{pts[1][0]} {pts[1][1]} L{pts[2][0]} {pts[2][1]} L{mx} {pts[-1][1]}Z" fill="{pal[1]}" opacity=".8"/>'
    # дошки
    for k in (0.33, 0.66):
        a = (118, 168 + (214 - 168) * k); b = (166, 190 + (238 - 190) * k)
        s += f'<path d="M{a[0]} {a[1]:.0f} L{b[0]} {b[1]:.0f}" stroke="{WOOD[3]}" stroke-width="5"/>'
        a = (166, 190 + (238 - 190) * k); b = (238, 170 + (216 - 170) * k)
        s += f'<path d="M{a[0]} {a[1]:.0f} L{b[0]} {b[1]:.0f}" stroke="{WOOD[3]}" stroke-width="5"/>'
    s += '<g clip-path="url(#cl)">' + wedge(122, 172, (0, 1), unit((118, 168), (166, 190)), 30, 30) + '</g>'
    return svg(s, d)

def warrior():
    d, h = head("iron", -14, -10, 0.84)
    BLADE = [(150, 214), (138, 202), (222, 70), (240, 62), (234, 82)]
    GUARD = [(128, 186), (140, 172), (176, 204), (164, 218)]
    GRIP = [(132, 218), (146, 204), (122, 234), (110, 240)]
    SHIELD = "M170 150 L240 138 L246 198 Q228 238 198 250 Q168 226 166 194Z"
    d += clip("bl", P(BLADE)) + clip("sh", SHIELD)
    # меч — позаду щита: спершу меч (контур + заливка), потім щит з власним контуром поверх
    s = h + outline([P(BLADE), P(GUARD), P(GRIP)], 8, 22)
    s += side([P(BLADE)], STEEL[3], 8) + side([P(GUARD), P(GRIP)], "#3a3f48", 8)
    s += poly(BLADE, STEEL[0]) + poly([(150, 214), (138, 202), (222, 70), (240, 62)], STEEL[1], "bl")
    s += poly(GRIP, WOOD[0]) + poly(GUARD, "#ffc531")
    s += outline([SHIELD], 8, 22) + side([SHIELD], "#7a1a1a", 8)
    s += f'<path d="{SHIELD}" fill="#d83a34"/>' + poly([(150, 120), (206, 120), (196, 270), (150, 270)], "#ff6a5c", "sh")
    s += f'<path d="M205 162 L207 222" stroke="#ffc531" stroke-width="11"/><path d="M182 186 L232 182" stroke="#ffc531" stroke-width="11"/>'
    s += f'<path d="M205 162 L207 222 M182 186 L232 182" stroke="{N}" stroke-width="3" fill="none" opacity=".0"/>'
    return svg(s, d)

if __name__ == "__main__":
    import os
    out = "/mnt/user-data/outputs/ui/roll_station/icons"; os.makedirs(out, exist_ok=True)
    for n, f in (("role_miner", miner), ("role_carrier", carrier), ("role_warrior", warrior)):
        open(f"{out}/{n}.svg", "w").write(f())
    print("ok")
