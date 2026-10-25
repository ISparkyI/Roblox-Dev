# Іконки карток табла кузні в стилі пака (як HUD та інвентар): Capacity (ящик з рудою), Speed (молот зі слідом руху),
# Ore per Hit (ковадло з рудою та спалахом удару). Без бейджів. Полотно 256, контур #040435, видавлювання ext, клин-блик wedge.
import math
from gen_own_icons import N, svg, ext, wedge, clip, poly

def unit(a, b):
    dx, dy = b[0]-a[0], b[1]-a[1]; l = math.hypot(dx, dy); return (dx/l, dy/l)
def P(pts): return "M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in pts) + "Z"
def outline(paths, depth=9, sw=26):
    return f'<g fill="{N}" stroke="{N}" stroke-width="{sw}" stroke-linejoin="round">' + ''.join(
        f'<path d="{p}" transform="translate({-k},{-k})"/>' for p in paths for k in range(0, depth)) + '</g>'
def side(paths, color, depth=9):
    return f'<g fill="{color}" stroke="{color}" stroke-width="1" stroke-linejoin="round">' + ''.join(
        f'<path d="{p}" transform="translate({-k},{-k})"/>' for p in paths for k in range(1, depth)) + '</g>'

def crystal(pts, cid, base, light, dark):
    s = poly(pts, base)
    mx = sum(x for x, _ in pts) / len(pts)
    s += poly([(mx, -50), (300, -50), (300, 300), (mx, 300)], dark, cid)
    s += poly([(-50, -50), (mx - 6, -50), (mx - 6, 300), (-50, 300)], light, cid)
    return s

COPPER = ("#ff8a3d", "#ffb27a", "#e0662a", "#c4581f")
COAL = ("#5a616c", "#7d8591", "#3d424a", "#2c3036")
IRON = ("#e0a46e", "#f2c9a0", "#c07a45", "#9a5c30")

# ---------- Capacity: дерев'яний ящик, з якого виглядає купа руди ----------
CRATE = "M44 132 H212 V218 H44Z"
ROCK = "M58 140 L72 110 L116 96 L164 102 L196 126 L198 140Z"
C1 = [(76, 124), (66, 78), (84, 56), (104, 74), (104, 122)]
C2 = [(108, 112), (112, 44), (134, 20), (156, 44), (152, 112)]
C3 = [(156, 126), (162, 84), (180, 68), (196, 90), (184, 130)]
def capacity():
    d = clip("kc", CRATE) + clip("k1", P(C1)) + clip("k2", P(C2)) + clip("k3", P(C3)) + clip("kr", ROCK)
    s = '<g transform="rotate(-6 128 140)">'
    s += outline([P(C1), P(C2), P(C3), ROCK])
    s += side([P(C1), P(C2)], COPPER[3]) + side([P(C3)], COAL[3]) + side([ROCK], "#6b7684")
    s += crystal(C1, "k1", COPPER[0], COPPER[1], COPPER[2]) + crystal(C2, "k2", COPPER[0], COPPER[1], COPPER[2])
    s += crystal(C3, "k3", COAL[0], COAL[1], COAL[2])
    s += f'<path d="{ROCK}" fill="#a3aebb"/>' + poly([(40, 90), (200, 90), (200, 116), (40, 128)], "#c3ccd6", "kr")
    s += '<g clip-path="url(#k2)">' + wedge(114, 50, unit((112, 44), (134, 20)), unit((112, 44), (108, 112)), 22, 30) + '</g>'
    # ящик
    s += ext(CRATE, 10, -1, -1, "#8a5428")
    s += f'<path d="{CRATE}" fill="#c98a52"/>'
    s += poly([(30, 120), (140, 120), (110, 160), (30, 160)], "#dda066", "kc")
    s += poly([(30, 196), (230, 190), (230, 240), (30, 240)], "#a8703e", "kc")
    for y in (160, 189):
        s += f'<path d="M44 {y} H212" stroke="#8a5428" stroke-width="5"/>'
    for x0 in (44, 186):
        s += f'<path d="M{x0} 132 H{x0+26} V218 H{x0}Z" fill="#b97a42" clip-path="url(#kc)"/>'
        s += f'<path d="M{x0+26} 132 V218" stroke="#8a5428" stroke-width="5"/>'
    s += '<path d="M44 132 H212" stroke="#8a5428" stroke-width="5"/>'
    for x, y in ((57, 145), (199, 145), (57, 205), (199, 205)):
        s += f'<circle cx="{x}" cy="{y}" r="4.5" fill="{N}"/>'
    s += '<g clip-path="url(#kc)">' + wedge(50, 138, (1, 0), (0, 1), 40, 34) + wedge(206, 212, (-1, 0), (0, -1), 22, 18) + '</g>'
    s += '</g>'
    return svg(s, d)

# ---------- Speed: молот у замаху + слід руху ----------
# Слід — дві загострені смуги-півмісяці навколо точки замаху (низ руків'я): широкі біля молота, сходяться в гострий кінець.
# Пласкі грані: біла смуга + блакитна внутрішня половина, спільний контур.
PIV = (147, 236)
def band(r0, w0, a0, a1, n=24):
    out, inn = [], []
    for i in range(n + 1):
        t = i / n
        a = math.radians(a0 + (a1 - a0) * t)
        hw = w0 * (1 - t) ** 0.85 / 2
        out.append((PIV[0] + (r0 + hw) * math.cos(a), PIV[1] + (r0 + hw) * math.sin(a)))
        inn.append((PIV[0] + (r0 - hw) * math.cos(a), PIV[1] + (r0 - hw) * math.sin(a)))
    return out + inn[::-1], inn
def swoosh():
    # три загострені штрихи руху на рівні верху, середини й низу голови молота
    streaks = [band(180, 15, -117, -160), band(156, 15, -118, -152), band(132, 13, -119, -146)]
    s = outline([P(b) for b, _ in streaks], 1, 12)
    for i, (b, inn) in enumerate(streaks):
        s += poly(b, "#ffffff")
    return s

HHEAD = "M86 46 H206 V112 H86Z"
HANDLE = "M134 108 H160 V236 H134Z"
def speed():
    d = clip("sh", HHEAD) + clip("sg", HANDLE)
    s = '<g transform="translate(140 136) scale(0.86) translate(-128 -128)">'
    s += '<g transform="rotate(28 150 150) translate(-16 6)">'
    s += swoosh()
    s += outline([HANDLE, HHEAD], 10)
    s += side([HANDLE], "#8a5428", 10) + side([HHEAD], "#6b7684", 10)
    # руків'я
    s += f'<path d="{HANDLE}" fill="#c98a52"/>' + poly([(148, 100), (170, 100), (170, 240), (148, 240)], "#a36a38", "sg")
    for y in (196, 214):
        s += f'<path d="M134 {y} H160 V{y+10} H134Z" fill="#6e4220"/>'
    # голова
    s += f'<path d="{HHEAD}" fill="#c3ccd6"/>'
    s += poly([(70, 30), (160, 30), (130, 80), (70, 80)], "#e6ecf3", "sh")
    s += poly([(70, 94), (220, 90), (220, 130), (70, 130)], "#8f9aa8", "sh")
    s += poly([(188, 30), (220, 30), (220, 130), (188, 130)], "#a7b1bd", "sh")        # бойок справа — темніша грань
    s += poly([(70, 30), (102, 30), (102, 130), (70, 130)], "#a7b1bd", "sh")
    s += '<path d="M188 46 V112 M102 46 V112" stroke="#6b7684" stroke-width="5"/>'
    s += '<g clip-path="url(#sh)">' + wedge(108, 52, (1, 0), (0, 1), 40, 26) + wedge(200, 106, (-1, 0), (0, -1), 16, 14) + '</g>'
    s += '<g clip-path="url(#sg)">' + wedge(138, 116, (1, 0), (0, 1), 8, 34) + '</g>'
    s += '</g></g>'
    return svg(s, d)

# ---------- Ore per Hit: ковадло, на ньому три шматки руди, над ними спалах удару ----------
ANVIL = "M20 118 L64 106 H218 V136 H180 L164 146 L162 172 L192 180 V214 H64 V180 L94 172 L92 146 L78 138 Q44 136 20 118Z"
def chunk(cx, by, w, h):
    return [(cx - w*0.5, by), (cx - w*0.56, by - h*0.55), (cx - w*0.22, by - h), (cx + w*0.3, by - h*0.96), (cx + w*0.56, by - h*0.5), (cx + w*0.46, by)]
def burst(cx, cy, ro, ri, n=8, rot=-90):
    pts = []
    for i in range(n*2):
        a = math.radians(rot + i*180/n); r = ro if i % 2 == 0 else ri
        pts.append((cx + r*math.cos(a), cy + r*math.sin(a)))
    return pts
def oph():
    ch = [(chunk(82, 112, 48, 40), COPPER), (chunk(136, 112, 54, 48), COAL), (chunk(188, 112, 46, 38), IRON)]
    st = burst(136, 44, 38, 17)
    d = clip("av", ANVIL) + ''.join(clip(f"oc{i}", P(c)) for i, (c, _) in enumerate(ch)) + clip("bs", P(st))
    s = '<g transform="rotate(-4 128 150)">'
    # ковадло
    s += ext(ANVIL, 10, -1, -1, "#4d5866")
    s += f'<path d="{ANVIL}" fill="#8f9aa8"/>'
    s += poly([(0, 96), (230, 96), (230, 122), (0, 130)], "#c3ccd6", "av")              # світла робоча поверхня
    s += poly([(0, 128), (230, 124), (230, 136), (0, 140)], "#a7b1bd", "av")
    s += poly([(0, 180), (230, 178), (230, 230), (0, 230)], "#6b7684", "av")              # темна основа
    s += poly([(150, 136), (230, 136), (230, 180), (150, 180)], "#7a8594", "av")          # тінь праворуч під плитою
    s += '<g clip-path="url(#av)">' + wedge(66, 110, (1, 0), unit((64, 106), (20, 118)), 40, 26) + wedge(70, 186, (1, 0), (0, 1), 22, 18) + '</g>'
    # руда (позаду ковадла: низ шматків ховається за верхом)
    s += outline([P(c) for c, _ in ch], 8, 22)
    for c, pal in ch: s += side([P(c)], pal[3], 8)
    for i, (c, pal) in enumerate(ch):
        s += crystal(c, f"oc{i}", pal[0], pal[1], pal[2])
        top = c[2]
        s += f'<g clip-path="url(#oc{i})">' + wedge(c[1][0] + 4, c[1][1] - 1, unit(c[1], c[2]), unit(c[1], c[0]), 16, 10) + '</g>'
    # спалах удару
    s += f'<path d="{P(st)}" fill="{N}" stroke="{N}" stroke-width="16" stroke-linejoin="round"/>'
    s += f'<path d="{P(st)}" fill="#ffd23a"/>' + poly([(136, -10), (240, -10), (240, 120), (136, 120)], "#ffaa1c", "bs")
    s += poly(burst(136, 44, 18, 8), "#fff6c8")
    for x, y, r in ((70, 44, 13), (204, 46, 10)):
        sp = burst(x, y, r, r*0.3, 4)
        s += f'<path d="{P(sp)}" fill="{N}" stroke="{N}" stroke-width="8" stroke-linejoin="round"/><path d="{P(sp)}" fill="#fff"/>'
    s += '</g>'
    return svg(s, d)

if __name__ == "__main__":
    out = {"forge_capacity_v2": capacity(), "forge_speed_v2": speed(), "forge_ore_per_hit_v2": oph()}
    for k, v in out.items(): open(k + ".svg", "w").write(v)
    print(list(out))
