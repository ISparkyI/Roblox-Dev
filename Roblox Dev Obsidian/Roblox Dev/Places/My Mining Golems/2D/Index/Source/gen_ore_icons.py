# Універсальна іконка «руда» для вкладки Ores і кнопки «Map 1» у вікні Index — 3 варіанти в стилі пака
# (товстий контур #040435, видавлювання, світлі/темні грані, білі клини-блики). Помічники — ../../inventory/gen_own_icons.py.
#   ore_a — кам'яна брила з різнокольоровими кристалами (помаранчевий, блакитний, фіолетовий) і вкрапленнями (золото, вугілля)
#   ore_b — брила з різнокольоровими вкрапленнями + кірка позаду
#   ore_c — купка різних шматків руди (вугілля, мідь, залізо, блакитний самоцвіт)
import math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "inventory"))
from gen_own_icons import N, svg, wedge, clip, poly

def P(pts): return "M" + " L".join(f"{x} {y}" for x, y in pts) + "Z"
def unit(a, b):
    dx, dy = b[0]-a[0], b[1]-a[1]; l = math.hypot(dx, dy); return (dx/l, dy/l)
DX, DY = -0.6, 1   # напрям видавлювання (товщина видно знизу)

def outline(paths, sw=26, depth=9):
    return f'<g fill="{N}" stroke="{N}" stroke-width="{sw}" stroke-linejoin="round">' + ''.join(
        f'<path d="{p}" transform="translate({DX*k:.1f},{DY*k:.1f})"/>' for p in paths for k in range(0, depth+1)) + '</g>'
def side(p, col, depth=9):
    return f'<g fill="{col}" stroke="{col}" stroke-width="1">' + ''.join(
        f'<path d="{p}" transform="translate({DX*k:.1f},{DY*k:.1f})"/>' for k in range(1, depth+1)) + '</g>'
def rim(p, sw=9):  # тонкий контур, що відділяє передній шматок від заднього
    return f'<path d="{p}" fill="{N}" stroke="{N}" stroke-width="{sw}" stroke-linejoin="round"/>'

def crystal(pts, cid, base, light, dark, glint=True):
    s = poly(pts, base)
    mx = sum(x for x, _ in pts) / len(pts)
    s += poly([(mx, -40), (300, -40), (300, 300), (mx, 300)], dark, cid)
    s += poly([(-40, -40), (mx - 7, -40), (mx - 7, 300), (-40, 300)], light, cid)
    if glint:
        top = min(pts, key=lambda p: p[1]); lft = min(pts, key=lambda p: p[0])
        gx, gy = mx - 14, top[1] + 26
        s += f'<g clip-path="url(#{cid})">' + wedge(gx, gy, (0.08, 1), unit((gx, gy), (gx + 14, gy - 22)), 34, 14, .2) + '</g>'
    return s

def rock(path, cid, depth=9):
    s = side(path, "#6b7684", depth) + f'<path d="{path}" fill="#a3aebb"/>'
    s += poly([(-20, -20), (276, -20), (276, 118), (-20, 150)], "#c3ccd6", cid)      # світлий верх
    s += poly([(-20, 196), (276, 172), (276, 276), (-20, 276)], "#7f8a98", cid)      # темний низ
    return s

def fleck(c, r, col, light, cid, rot=0):
    """вкраплення-самородок: неправильний 6-кутник з контуром, бликом і темнішою нижньою гранню"""
    cx, cy = c
    k = [1.0, 0.78, 1.05, 0.86, 1.0, 0.72]
    pts = [(cx + r*k[i]*math.cos(math.radians(rot + i*60 - 90)), cy + r*k[i]*0.82*math.sin(math.radians(rot + i*60 - 90))) for i in range(6)]
    p = P([(round(x, 1), round(y, 1)) for x, y in pts])
    g = f' clip-path="url(#{cid})"'
    s = f'<path d="{p}" fill="{N}" stroke="{N}" stroke-width="8" stroke-linejoin="round"{g}/>'
    s += f'<path d="{p}" fill="{col}"{g}/>'
    s += f'<path d="M{cx-r*.55:.1f} {cy-r*.15:.1f} Q{cx-r*.5:.1f} {cy-r*.62:.1f} {cx+r*.05:.1f} {cy-r*.62:.1f} Q{cx-r*.3:.1f} {cy-r*.4:.1f} {cx-r*.55:.1f} {cy-r*.15:.1f}Z" fill="{light}"{g}/>'
    return s

# ---------- A: брила з кристалами ----------
ROCK_A = "M30 168 L52 118 L98 98 L168 96 L214 116 L234 166 L212 214 L140 228 L58 220Z"
KA1 = [(54, 132), (46, 64), (72, 36), (96, 62), (100, 128)]               # помаранчевий (мідь)
KA2 = [(96, 120), (100, 30), (128, 2), (156, 30), (156, 116)]            # блакитний (самоцвіт)
KA3 = [(150, 124), (158, 66), (184, 46), (206, 74), (198, 130)]           # фіолетовий
def ore_a():
    d = clip("ra", ROCK_A) + clip("a1", P(KA1)) + clip("a2", P(KA2)) + clip("a3", P(KA3))
    s = '<g transform="rotate(-5 128 128) translate(0 6)">'
    s += outline([P(KA1), P(KA2), P(KA3), ROCK_A])
    s += side(P(KA1), "#c4581f") + side(P(KA2), "#1c7fb8") + side(P(KA3), "#6b3fb8")
    s += crystal(KA1, "a1", "#ff8a3d", "#ffb27a", "#e0662a")
    s += crystal(KA3, "a3", "#b88af7", "#d6b8ff", "#8a5ad8")
    s += crystal(KA2, "a2", "#5cd6ff", "#b8f1ff", "#2aa3e0")
    s += rim(ROCK_A, 10) + rock(ROCK_A, "ra")
    # вкраплення на брилі: золото, вугілля, залізо (бежеве), мідь
    s += fleck((76, 174), 15, "#ffc531", "#fff1a8", "ra", 10)
    s += fleck((126, 188), 14, "#2b3038", "#7f8a98", "ra", -14)
    s += fleck((180, 158), 14, "#e8c8a0", "#fff4e0", "ra", 24)
    s += fleck((186, 198), 10, "#ff8a3d", "#ffd0a8", "ra", 0)
    s += fleck((104, 146), 9, "#ff6b5e", "#ffc8c2", "ra", 30)
    s += '<g clip-path="url(#ra)">' + wedge(56, 124, unit((52, 118), (98, 98)), (0.3, 0.95), 34, 22) + '</g>'
    s += '</g>'
    return svg(s, d)

# ---------- B: брила з вкрапленнями + кірка спереду (по діагоналі, як у class_miner) ----------
ROCK_B = "M22 172 L42 112 L100 84 L170 90 L218 122 L230 178 L204 222 L118 234 L46 222Z"
PH = "M18 110 Q128 -34 238 110 L222 120 Q128 30 34 120Z"
SOCK = "M106 52 H150 V96 H106Z"
def ore_b():
    d = clip("rb", ROCK_B) + clip("ph", PH) + clip("ps", SOCK)
    s = '<g transform="translate(-10 14) scale(0.94)">'
    s += outline([ROCK_B], 26, 9) + rock(ROCK_B, "rb")
    fl = [((70, 156), 15, "#ff8a3d", "#ffd0a8", 8), ((118, 124), 12, "#5cd6ff", "#e0f8ff", -20),
          ((96, 196), 14, "#2b3038", "#7f8a98", 16), ((150, 176), 13, "#ffc531", "#fff1a8", 40),
          ((186, 136), 11, "#b88af7", "#ecdcff", 0), ((190, 192), 11, "#e8c8a0", "#fff4e0", -10)]
    for c, r, col, l, rot in fl: s += fleck(c, r, col, l, "rb", rot)
    s += '<g clip-path="url(#rb)">' + wedge(48, 118, unit((42, 112), (100, 84)), (0.3, 0.95), 42, 24) + '</g>'
    s += '</g>'
    # кірка: повернута на 45°, сталь угорі праворуч, руків'я вниз ліворуч через брилу
    s += '<g transform="translate(156 92) rotate(36) scale(0.72) translate(-128 -128)">'
    hl = "M128 70 V236"
    s += f'<path d="{hl}" stroke="{N}" stroke-width="54" stroke-linecap="round"/>'
    s += f'<g fill="{N}" stroke="{N}" stroke-width="28" stroke-linejoin="round"><path d="{PH}"/><path d="{SOCK}"/></g>'
    s += f'<path d="{hl}" stroke="#a36a38" stroke-width="28" stroke-linecap="round"/>'
    s += f'<path d="M121 76 V232" stroke="#e0a86e" stroke-width="10" stroke-linecap="round"/>'
    s += f'<path d="M128 196 V216" stroke="#6e4220" stroke-width="28"/>'
    s += f'<path d="{PH}" fill="#b9c3cf"/>'
    s += f'<path d="M18 110 Q128 -34 238 110 L232 114 Q128 -8 24 114Z" fill="#e6ecf3" clip-path="url(#ph)"/>'
    s += poly([(128, 0), (240, 0), (240, 130), (128, 130)], "#9aa6b4", "ph")
    s += f'<path d="{SOCK}" fill="#8a95a3"/>' + poly([(128, 40), (160, 40), (160, 100), (128, 100)], "#6b7684", "ps")
    s += '<g clip-path="url(#ph)">' + wedge(46, 88, unit((18, 110), (80, 46)), (0.5, 0.86), 40, 14, .18) + '</g>'
    s += '</g>'
    return svg(s, d)

# ---------- C: купка різних шматків ----------
COAL = "M24 196 L36 150 L78 132 L118 146 L128 192 L100 226 L44 228Z"
IRON = "M128 194 L136 146 L178 128 L224 146 L234 190 L206 226 L150 228Z"
CU = [(64, 140), (60, 82), (84, 56), (108, 80), (110, 138)]
CU2 = [(104, 138), (112, 96), (132, 80), (148, 100), (142, 140)]
GEM = [(140, 140), (146, 70), (172, 42), (198, 70), (196, 140)]
def chunk(path, cid, base, light, dark, sidec):
    s = side(path, sidec) + f'<path d="{path}" fill="{base}"/>'
    s += poly([(-20, -20), (276, -20), (276, 156), (-20, 166)], light, cid)
    s += poly([(-20, 204), (276, 196), (276, 276), (-20, 276)], dark, cid)
    return s
def ore_c():
    d = clip("cc", COAL) + clip("ci", IRON) + clip("u1", P(CU)) + clip("u2", P(CU2)) + clip("g1", P(GEM))
    s = '<g transform="rotate(-4 128 128) translate(0 2)">'
    s += outline([P(CU), P(CU2), P(GEM), COAL, IRON])
    s += side(P(CU), "#c4581f") + side(P(CU2), "#c4581f") + side(P(GEM), "#1c7fb8")
    s += crystal(CU, "u1", "#ff8a3d", "#ffb27a", "#e0662a")
    s += crystal(GEM, "g1", "#5cd6ff", "#b8f1ff", "#2aa3e0")
    s += crystal(CU2, "u2", "#ff8a3d", "#ffb27a", "#e0662a", glint=False)
    # вугілля (темне, грані) і залізна руда (сіра з бежевими вкрапленнями)
    s += rim(COAL, 10) + chunk(COAL, "cc", "#3a3f48", "#5d6470", "#22262c", "#1a1d22")
    s += poly([(78, 132), (118, 146), (96, 176), (70, 160)], "#4a505b", "cc")
    s += '<g clip-path="url(#cc)">' + wedge(40, 152, unit((36, 150), (78, 132)), (0.25, 0.97), 30, 18) + '</g>'
    s += rim(IRON, 10) + chunk(IRON, "ci", "#a3aebb", "#c3ccd6", "#7f8a98", "#6b7684")
    s += fleck((166, 170), 14, "#e8c8a0", "#fff4e0", "ci", 12)
    s += fleck((204, 196), 12, "#d9a36e", "#ffe2c4", "ci", -18)
    s += fleck((206, 156), 9, "#ffc531", "#fff1a8", "ci", 30)
    s += '<g clip-path="url(#ci)">' + wedge(140, 150, unit((136, 146), (178, 128)), (0.2, 0.98), 30, 18) + '</g>'
    s += '</g>'
    return svg(s, d)

if __name__ == "__main__":
    for n, f in (("ore_a", ore_a), ("ore_b", ore_b), ("ore_c", ore_c)):
        open(os.path.join(HERE, n + ".svg"), "w").write(f())
    print("svg ok")
