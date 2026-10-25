# Іконки кнопок E: «ENTER CAVE» (вхід у печеру) і «ROLL» (важіль ролу).
# Стиль пака (як картки табла плоту): контур #040435 з видавлюванням, пласкі грані, клин-блики, без тіні. Полотно 256.
import sys, math
sys.path.insert(0, "/mnt/user-data/outputs/ui/plot_ui")
from gen_own_icons import N, svg, wedge, clip, poly
from gen_forge_icons import P, outline, side, unit

ROCK = ("#a3aebb", "#c3ccd6", "#7f8a98", "#5f6974")   # основа, світла, темна, бік
MOSS = ("#6cc24a", "#9be36a", "#4a9a2e", "#3a7a22")
WOOD = ("#9a6a44", "#c08a5c", "#7a5232", "#5c3d24")

def cave(variant="a"):
    # пагорб із валунів (силует), темний прохід-арка, дерев'яне кріплення, моховий верх
    HILL = [(20, 222), (26, 160), (52, 120), (84, 98), (112, 66), (150, 58), (186, 82), (214, 118), (234, 168), (238, 222)]
    MOSSP = [(84, 98), (112, 66), (150, 58), (186, 82), (174, 96), (150, 86), (122, 92), (100, 108)]
    ARCH = "M86 222 L86 156 Q86 116 128 112 Q170 116 170 156 L170 222Z"
    INNER = "M100 222 L100 160 Q100 130 128 127 Q156 130 156 160 L156 222Z"
    POSTL = [(78, 222), (78, 140), (94, 140), (94, 222)]
    POSTR = [(162, 222), (162, 140), (178, 140), (178, 222)]
    BEAM = [(68, 146), (68, 128), (188, 128), (188, 146)]
    d = clip("h", P(HILL)) + clip("m", P(MOSSP)) + clip("bm", P(BEAM))
    s = outline([P(HILL), P(BEAM), P(POSTL), P(POSTR)], 9, 26)
    s += side([P(HILL)], ROCK[3], 9) + side([P(BEAM), P(POSTL), P(POSTR)], WOOD[3], 9)
    s += poly(HILL, ROCK[0])
    # валуни: світліші/темніші грані, що роблять силует «з каменів»
    s += poly([(20, 222), (26, 160), (52, 120), (84, 98), (96, 140), (70, 222)], ROCK[2], "h")
    s += poly([(26, 160), (52, 120), (70, 132), (50, 176)], ROCK[1], "h")
    s += poly([(186, 82), (214, 118), (234, 168), (238, 222), (196, 222), (190, 150)], ROCK[2], "h")
    s += poly([(150, 58), (186, 82), (176, 112), (140, 96)], ROCK[1], "h")
    # шви між валунами
    for a, b in [((84, 98), (100, 140)), ((186, 82), (176, 140)), ((52, 120), (48, 186)), ((214, 118), (204, 170))]:
        s += f'<path d="M{a[0]} {a[1]} L{b[0]} {b[1]}" stroke="{N}" stroke-width="5" stroke-opacity=".45"/>'
    # мох на верхівці
    s += poly(MOSSP, MOSS[0]) + poly([(84, 98), (112, 66), (150, 58), (140, 72), (112, 80), (96, 100)], MOSS[1], "m")
    s += poly([(100, 108), (122, 92), (150, 86), (174, 96), (172, 104), (150, 96), (122, 102)], MOSS[2], "m")
    # прохід: темний, всередині — ще темніший
    s += f'<path d="{ARCH}" fill="#2a2d33"/><path d="{INNER}" fill="#0b0c0f"/>'
    if variant == "b":  # очі в темряві (големи сплять у сховищі)
        s += '<rect x="113" y="170" width="9" height="9" fill="#5ff2ff"/><rect x="134" y="170" width="9" height="9" fill="#5ff2ff"/>'
    # дерев'яне кріплення
    for pts in (POSTL, POSTR):
        s += poly(pts, WOOD[0]) + poly([(pts[0][0], pts[0][1]), (pts[1][0], pts[1][1]), (pts[1][0] + 6, pts[1][1]), (pts[0][0] + 6, pts[0][1])], WOOD[1])
    s += poly(BEAM, WOOD[0]) + poly([(68, 128), (188, 128), (188, 134), (68, 134)], WOOD[1], "bm")
    for x in (86, 170):
        s += f'<rect x="{x-6}" y="131" width="12" height="12" fill="#3a3f48" stroke="{N}" stroke-width="3"/>'
    # блики
    s += '<g clip-path="url(#h)">' + wedge(30, 160, unit((26, 160), (52, 120)), unit((26, 160), (20, 222)), 30, 30) + '</g>'
    s += wedge(70, 130, (1, 0), (0, 1), 34, 10)
    return svg(f'<g transform="translate(0 4)">{s}</g>', d)

def lever(variant="a"):
    # важіль: дерев'яна основа (ізометрія), металевий паз, ручка під кутом з червоною кулькою-блоком
    TOP = [(40, 182), (128, 152), (216, 182), (128, 212)]
    LF = [(40, 182), (128, 212), (128, 240), (40, 210)]
    RF = [(128, 212), (216, 182), (216, 210), (128, 240)]
    SIL = [(40, 182), (128, 152), (216, 182), (216, 210), (128, 240), (40, 210)]
    SLOT = [(96, 186), (128, 175), (160, 186), (128, 197)]
    a = math.radians(-58 if variant == "a" else -40)
    px, py = 128, 186
    L = 128
    ex, ey = px + math.cos(a) * L * 0.62, py + math.sin(a) * L
    nx, ny = -math.sin(a), math.cos(a)
    w = 9
    ARM = [(px + nx * w, py + ny * w), (ex + nx * w, ey + ny * w), (ex - nx * w, ey - ny * w), (px - nx * w, py - ny * w)]
    k = 26
    KNOB = [(ex - k, ey - k), (ex + k, ey - k), (ex + k, ey + k), (ex - k, ey + k)]
    HUB = [(px - 20, py - 12), (px + 20, py - 12), (px + 20, py + 12), (px - 20, py + 12)]
    d = clip("t", P(TOP)) + clip("k", P(KNOB)) + clip("a", P(ARM))
    s = outline([P(SIL), P(ARM), P(KNOB), P(HUB)], 9, 26)
    s += side([P(SIL)], WOOD[3], 9) + side([P(KNOB)], "#9e1f1a", 9) + side([P(ARM), P(HUB)], "#3a3f48", 9)
    s += poly(TOP, WOOD[1]) + poly(LF, WOOD[0]) + poly(RF, WOOD[2])
    for t in (0.33, 0.66):  # дошки
        a1 = (40 + (128 - 40) * t, 182 + (152 - 182) * t); b1 = (128 + (216 - 128) * t, 212 + (182 - 212) * t)
        s += f'<path d="M{a1[0]:.0f} {a1[1]:.0f} L{b1[0]:.0f} {b1[1]:.0f}" stroke="{WOOD[2]}" stroke-width="5"/>'
    s += poly(SLOT, "#1a1d22")
    s += poly(ARM, "#c9ced4") + poly([(px - nx * w, py - ny * w), (ex - nx * w, ey - ny * w), (ex, ey), (px, py)], "#eef2f6", "a")
    s += poly(HUB, "#5a616c")
    s += poly(KNOB, "#e8463c") + poly([(ex - k, ey - k), (ex + k, ey - k), (ex - k, ey + k)], "#ff7a6a", "k")
    s += wedge(ex - k + 4, ey - k + 4, (1, 0), (0, 1), 22, 22)
    s += '<g clip-path="url(#t)">' + wedge(52, 182, unit((40, 182), (128, 152)), unit((40, 182), (128, 212)), 40, 30) + '</g>'
    if variant == "b":  # іскорки «ролу»
        for cx, cy, r in ((200, 70, 16), (222, 112, 10)):
            s += f'<path d="M{cx} {cy-r} L{cx+r*0.3} {cy-r*0.3} L{cx+r} {cy} L{cx+r*0.3} {cy+r*0.3} L{cx} {cy+r} L{cx-r*0.3} {cy+r*0.3} L{cx-r} {cy} L{cx-r*0.3} {cy-r*0.3}Z" fill="#ffd34d" stroke="{N}" stroke-width="5" stroke-linejoin="round"/>'
    return svg(s, d)

if __name__ == "__main__":
    import os
    out = "/mnt/user-data/outputs/ui/cave/icons"; os.makedirs(out, exist_ok=True)
    for n, f in (("cave_a", lambda: cave("a")), ("cave_b", lambda: cave("b")), ("lever_a", lambda: lever("a")), ("lever_b", lambda: lever("b"))):
        open(f"{out}/{n}.svg", "w").write(f())
    print("ok")
