"""Нові іконки руди (злитки лишаються) — 3 варіанти стилю на вибір, усі за GDD 2D-іконок:
товстий темний контур, градієнти / грані світлий-основний-темний, блиск, іскорки, без тіні.
  V1 «Блок руди»  — ізометричний кам'яний блок зі studs зверху й вкрапленнями руди (як блоки в нашому світі).
  V2 «Кристали»   — гранований камінь із кластером кристалів кольору руди.
  V3 «Самородки»  — купка гранованих самородків кольору руди, без каменю.
Полотно 480 (viewBox −240…240). Пише ore_icons.html (+ svg/ для рендеру PNG після вибору).
"""
import pathlib, importlib.util, math

HERE = pathlib.Path(__file__).parent
spec = importlib.util.spec_from_file_location('gt', HERE / 'gen_tiles.py')
gt = importlib.util.module_from_spec(spec); spec.loader.exec_module(gt)
gb = gt.gb
INK, mix, dark, light = gb.INK, gb.mix, gb.dark, gb.light

ORE = {   # світлий, основний, темний, блиск
    'coal':   ('#5d636d', '#2c3036', '#14161a', '#9fb3c9'),
    'copper': ('#ffb07a', '#e0703a', '#9a3e16', '#ffe0c8'),
    'iron':   ('#f2c9a0', '#d08a55', '#8e5530', '#fff0dc'),
}
ROCK = ('#c4c9cf', '#949ba4', '#666d76')

def P(pts): return ' '.join(f'{x:.1f},{y:.1f}' for x, y in pts)
def poly(pts, fill, extra=''): return f'<polygon points="{P(pts)}" fill="{fill}" {extra}/>'
def outline(pts, w=24): return f'<polygon points="{P(pts)}" fill="{INK}" stroke="{INK}" stroke-width="{w}" stroke-linejoin="round"/>'
def sparkle(x, y, r, op=1):
    k = r * .28
    pts = [(x, y - r), (x + k, y - k), (x + r, y), (x + k, y + k), (x, y + r), (x - k, y + k), (x - r, y), (x - k, y - k)]
    return f'<polygon points="{P(pts)}" fill="#fff" opacity="{op}"/>'

def iso(x, y, z, s=1.0, ox=0, oy=0):
    return (ox + (x - z) * 0.866 * s, oy + (x + z) * 0.5 * s - y * s)

# ---------- V1: блок руди ----------
def v1(kind):
    lt, base, dk, gl = ORE[kind]
    S, ox, oy = 150, 0, 40
    def I(x, y, z): return iso(x, y, z, 1, ox, oy)
    A = [I(-S, 0, -S), I(S, 0, -S), I(S, 0, S), I(-S, 0, S)]
    T = [I(-S, 2 * S * .82, -S), I(S, 2 * S * .82, -S), I(S, 2 * S * .82, S), I(-S, 2 * S * .82, S)]
    H = 2 * S * .82
    sil = [T[0], T[1], A[1], A[2], A[3], T[3]]
    left = [T[3], T[2], A[2], A[3]]      # передня ліва грань (z = S)
    right = [T[2], T[1], A[1], A[2]]     # права грань (x = S)
    o = [outline(sil), poly(left, ROCK[1]), poly(right, ROCK[2]), poly(T, ROCK[0])]
    # вкраплення руди: квадратики на гранях
    def spot_left(u, v, w):        # u: −S..S уздовж x, v: висота
        q = [I(u, v, S), I(u + w, v, S), I(u + w, v - w, S), I(u, v - w, S)]
        return poly(q, base, f'stroke="{INK}" stroke-width="6" stroke-linejoin="round"') + poly(q[:2] + [I(u + w, v - w * .35, S), I(u, v - w * .35, S)], lt)
    def spot_right(u, v, w):       # u: −S..S уздовж z
        q = [I(S, v, u), I(S, v, u - w), I(S, v - w, u - w), I(S, v - w, u)]
        return poly(q, dk, f'stroke="{INK}" stroke-width="6" stroke-linejoin="round"') + poly(q[:2] + [I(S, v - w * .35, u - w), I(S, v - w * .35, u)], base)
    def spot_top(u, z, w):
        q = [I(u, H, z), I(u + w, H, z), I(u + w, H, z + w), I(u, H, z + w)]
        return poly(q, lt, f'stroke="{INK}" stroke-width="6" stroke-linejoin="round"')
    o += [spot_left(-120, 200, 70), spot_left(10, 110, 80), spot_left(-60, 70, 50),
          spot_right(110, 190, 66), spot_right(-10, 100, 74), spot_top(-110, -110, 60), spot_top(30, 20, 56)]
    # studs зверху (2×2)
    for sx, sz in ((-75, -75), (75, -75), (-75, 75), (75, 75)):
        c = I(sx, H, sz); r = 30
        top = (c[0], c[1] - 18)
        o.append(f'<path d="M{c[0] - r * .866:.1f},{c[1] - 18:.1f} L{c[0] - r * .866:.1f},{c[1]:.1f} A{r * .866:.1f},{r * .5:.1f} 0 0 0 {c[0] + r * .866:.1f},{c[1]:.1f} '
                 f'L{c[0] + r * .866:.1f},{c[1] - 18:.1f} Z" fill="{ROCK[1]}" stroke="{INK}" stroke-width="6"/>')
        o.append(f'<ellipse cx="{top[0]:.1f}" cy="{top[1]:.1f}" rx="{r * .866:.1f}" ry="{r * .5:.1f}" fill="{ROCK[0]}" stroke="{INK}" stroke-width="6"/>')
    o.append(f'<polyline points="{P([T[3], T[2], T[1]])}" fill="none" stroke="#fff" stroke-width="6" opacity=".5"/>')
    body = f'<g transform="translate(0,62) scale(.75)">{"".join(o)}</g>'
    return body + sparkle(-175, -150, 30) + sparkle(-130, -195, 14, .8)

# ---------- V2: кристали ----------
def crystal(cx, by, w, h, ang, kind):
    lt, base, dk, gl = ORE[kind]
    a = math.radians(ang)
    def R(x, y): return (cx + x * math.cos(a) - y * math.sin(a), by + x * math.sin(a) + y * math.cos(a))
    body = [R(-w, 0), R(-w, -h), R(0, -h - w * 1.2), R(w, -h), R(w, 0)]
    lf = [R(-w, 0), R(-w, -h), R(0, -h - w * 1.2), R(0, 0)]
    rt = [R(0, 0), R(0, -h - w * 1.2), R(w, -h), R(w, 0)]
    return (outline(body, 18) + poly(lf, lt) + poly(rt, base) +
            poly([R(-w * .6, -h * .15), R(-w * .6, -h * .85), R(-w * .25, -h * .9), R(-w * .25, -h * .2)], '#fff', 'opacity=".45"'))

def v2(kind):
    pts = [(-185, 60), (-140, -30), (-60, -70), (50, -60), (150, -20), (190, 70), (130, 150), (-10, 170), (-150, 140)]
    M = (0, 60)
    o = [outline(pts), poly(pts, ROCK[1]),
         poly([pts[0], pts[1], pts[2], pts[3], pts[4], pts[5], M], ROCK[0]),
         poly([M, pts[5], pts[6], pts[7]], ROCK[2]),
         f'<polyline points="{P([pts[0], M, pts[5]])}" fill="none" stroke="{INK}" stroke-width="7" opacity=".45"/>',
         f'<polyline points="{P([M, pts[7]])}" fill="none" stroke="{INK}" stroke-width="7" opacity=".45"/>']
    o += [crystal(-70, 20, 36, 120, -18, kind), crystal(60, 30, 30, 90, 22, kind), crystal(0, 10, 46, 175, 2, kind)]
    o.append(sparkle(-160, -150, 30)); o.append(sparkle(150, -185, 15, .8))
    return ''.join(o)

# ---------- V3: самородки ----------
def nugget(x, y, r, kind):
    lt, base, dk, gl = ORE[kind]
    pts = [(x - r, y - r * .1), (x - r * .55, y - r * .85), (x + r * .35, y - r * .95), (x + r, y - r * .25), (x + r * .75, y + r * .7), (x - r * .2, y + r * .85), (x - r * .85, y + r * .55)]
    c = (x - r * .05, y - r * .1)
    top = [pts[0], pts[1], pts[2], pts[3], c]
    rt = [c, pts[3], pts[4], pts[5]]
    return (outline(pts, 20) + poly(pts, base) + poly(rt, dk) + poly(top, lt) +
            f'<polygon points="{P([(x - r * .55, y - r * .45), (x - r * .25, y - r * .8), (x + r * .15, y - r * .78), (x - r * .3, y - r * .4)])}" fill="#fff" opacity=".55"/>')

def v3(kind):
    o = [nugget(-85, 70, 95, kind), nugget(95, 80, 85, kind), nugget(5, -45, 110, kind)]
    o.append(sparkle(-150, -150, 30)); o.append(sparkle(150, -120, 15, .8))
    return ''.join(o)

VAR = {'V1': ('Блок руди', v1), 'V2': ('Кристали', v2), 'V3': ('Самородки', v3)}
(HERE / 'svg').mkdir(exist_ok=True)
for vk, (_, fn) in VAR.items():
    for k in ORE:
        (HERE / 'svg' / f'ore_{k}_{vk}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-240 -240 480 480">{fn(k)}</svg>', encoding='utf-8')

def ico(body, size): return f'<svg width="{size}" height="{size}" viewBox="-240 -240 480 480">{body}</svg>'
def on_tile(kind, body, size=150):
    d, b = gb.button('A', 'green', 100, 100, pk=gt.PK, pal=gt.ORE_PAL[kind], rows=4)
    m = 100 * .06
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 100 100"><defs>{d}</defs>{b}'
            f'<svg x="8" y="7" width="84" height="76" viewBox="-240 -240 480 480">{body}</svg></svg>')

bar_new = 'data:image/png;base64,' + __import__('base64').b64encode(pathlib.Path('/mnt/user-data/outputs/ui/forge_window/icons/forge_bar_iron.png').read_bytes()).decode()
bar_old = 'data:image/png;base64,' + __import__('base64').b64encode(pathlib.Path('/mnt/user-data/outputs/ui/forge_window/icons/forge_bar_iron_old.png').read_bytes()).decode()
old = {k: gt.img(f'forge_ore_{k}') for k in ORE}

secs = []
for vk, (name, fn) in VAR.items():
    cells = ''.join(f'<div class="cell">{ico(fn(k), 200)}{on_tile(k, fn(k))}<span>{k}</span></div>' for k in ORE)
    secs.append(f'<h2>{vk} — {name}</h2><div class="grid">{cells}</div>')
olds = ''.join(f'<div class="cell"><img src="{old[k]}" width="150"><span>{k} (зараз)</span></div>' for k in ORE)
html = f'''<!doctype html><html lang="uk"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Іконки руди — варіанти</title><style>
body{{margin:0;background:#3b3f45;color:#e8edf2;font-family:system-ui,sans-serif}}
.wrap{{max-width:1180px;margin:0 auto;padding:24px 16px 60px}} h1{{font-size:22px;color:#ffd34d;margin:0 0 6px}}
h2{{font-size:18px;margin:28px 0 10px}} p{{color:#c3cbd4;font-size:14px;line-height:1.5;margin:0 0 12px}}
.grid{{display:flex;flex-wrap:wrap;gap:26px}} .cell{{display:flex;align-items:center;gap:14px;background:#2e3237;padding:12px;border:2px solid #23262a}}
.cell span{{font-size:13px;color:#c3cbd4;width:60px}}
</style></head><body><div class="wrap">
<h1>Іконки руди — 3 варіанти стилю</h1>
<p>Злитки лишаються. Кожна руда показана окремо і на новій плитці стилю A (studs удвічі слабші). Вибери варіант (або скажи, що змішати).</p>
<h2>Зараз</h2><div class="grid">{olds}</div>
{"".join(secs)}
<h2>Злиток заліза — сіріший</h2><div class="grid"><div class="cell"><img src="{bar_old}" width="150"><span>було</span></div><div class="cell"><img src="{bar_new}" width="150"><span>стало</span></div></div>
</div></body></html>'''
(HERE / 'ore_icons.html').write_text(html, encoding='utf-8')
print('ok', len(html))


# ================= V2 (нова): кристали ростуть із каменя =================
ORE['coal'] = ('#6a717c', '#33373e', '#1d2025', '#b8cbe0')

def crystal3(cx, by, w, h, ang, kind, back=False):
    """Кристал-призма з трьома гранями (світла / основна / темна) і загостреним верхом.
    Повертає (outline, fill) — контури малюємо першими для всього, грані — потім, щоб камінь міг перекрити основу."""
    lt, base, dk, gl = ORE[kind]
    if back: lt, base, dk = mix(lt, dk, .25), mix(base, dk, .3), dk
    a = math.radians(ang)
    def R(x, y): return (cx + x * math.cos(a) - y * math.sin(a), by + x * math.sin(a) + y * math.cos(a))
    ap = -h - w * 1.1
    body = [R(-w, 30), R(-w, -h), R(0, ap), R(w, -h), R(w, 30)]
    left = [R(-w, 30), R(-w, -h), R(0, ap), R(-.3 * w, -h), R(-.3 * w, 30)]
    mid = [R(-.3 * w, 30), R(-.3 * w, -h), R(0, ap), R(.4 * w, -h), R(.4 * w, 30)]
    right = [R(.4 * w, 30), R(.4 * w, -h), R(0, ap), R(w, -h), R(w, 30)]
    hl = [R(-.85 * w, -h * .1), R(-.85 * w, -h * .92), R(-.6 * w, -h * .98), R(-.6 * w, -h * .15)]
    ol = outline(body, 20)
    fl = (poly(left, lt) + poly(mid, base) + poly(right, dk) + poly(hl, '#fff', 'opacity=".5"') +
          f'<polyline points="{P([R(-.3 * w, 30), R(-.3 * w, -h), R(0, ap), R(.4 * w, -h), R(.4 * w, 30)])}" fill="none" stroke="{INK}" stroke-width="4" opacity=".35"/>' +
          f'<polygon points="{P([R(-.3 * w, -h), R(0, ap), R(.4 * w, -h)])}" fill="#fff" opacity=".18"/>')
    return ol, fl

def pebble(x, y, r, rot=0):
    """Уламок каменю біля основи кристала (перекриває основу — кристал «входить» у камінь)."""
    a = math.radians(rot)
    base = [(-1, -.2), (-.45, -.85), (.4, -.8), (1, -.1), (.6, .7), (-.6, .65)]
    pts = [(x + (u * math.cos(a) - v * math.sin(a)) * r, y + (u * math.sin(a) + v * math.cos(a)) * r) for u, v in base]
    c = (x, y - r * .05)
    return (outline(pts, 14) + poly(pts, ROCK[1]) + poly([pts[0], pts[1], pts[2], pts[3], c], ROCK[0]) +
            poly([c, pts[3], pts[4]], ROCK[2]))

def v2n(kind):
    lt, base, dk, gl = ORE[kind]
    # валун: нерівний «колотий» камінь — ламаний передній край, грані різного розміру й відтінку, низ звужується
    A, B, C, D, E, F, G = (-196, 64), (-176, -2), (-126, -42), (-40, -60), (64, -56), (146, -24), (198, 30)
    H, I, K, L, M = (172, 142), (96, 198), (2, 216), (-96, 194), (-168, 140)
    R1, R2, R3, R4, R5 = (-150, 64), (-78, 118), (14, 92), (104, 128), (172, 62)
    sil = [A, B, C, D, E, F, G, H, I, K, L, M]
    top = [A, B, C, D, E, F, G, R5, R4, R3, R2, R1]
    N = (-20, 168)     # внутрішня вершина, де сходяться грані
    faces = [([A, R1, M], mix(ROCK[0], ROCK[1], .35)), ([R1, R2, L, M], ROCK[1]), ([R2, R3, N, L], mix(ROCK[0], ROCK[1], .7)),
             ([L, N, K], mix(ROCK[1], ROCK[2], .55)), ([R3, R4, I, K, N], mix(ROCK[1], ROCK[2], .4)),
             ([R4, R5, H, I], ROCK[2]), ([R5, G, H], mix(ROCK[1], ROCK[2], .8))]
    # кристали (x, основа y, півширина, висота, кут, задній?) — від заднього до переднього
    cr = [(40, 22, 22, 86, 12, True), (-112, 40, 18, 58, -36, True),
          (-70, 52, 32, 122, -20, False), (68, 50, 28, 108, 20, False), (-4, 56, 44, 176, 1, False)]
    parts = [crystal3(x, y, w, h, a, kind, b) for x, y, w, h, a, b in cr]
    shard = crystal3(160, 112, 17, 28, 50, kind)
    o = [outline(sil)] + [p[0] for p in parts]
    o.append(poly(top, ROCK[0]))
    # гніздо — темна щілина, з якої ростуть кристали
    sock = [(-128, 44), (-88, 14), (0, 2), (84, 10), (118, 34), (74, 62), (-62, 64)]
    o.append(poly(sock, INK) + poly([(x * .9, y + 6) for x, y in sock], dark(base, .45)))
    o += [p[1] for p in parts]
    # уламки каменю на основах кристалів
    o += [pebble(-112, 56, 20, -24), pebble(-48, 74, 36, 10), pebble(28, 72, 22, -14), pebble(84, 62, 30, 20), pebble(128, 44, 14, 40)]
    # передні грані
    o += [poly(f, c) for f, c in faces]
    o.append(f'<polyline points="{P([A, R1, R2, R3, R4, R5, G])}" fill="none" stroke="{INK}" stroke-width="9" stroke-linejoin="round"/>')
    o += [f'<polyline points="{P(seg)}" fill="none" stroke="{INK}" stroke-width="6" opacity=".4"/>'
          for seg in ([R1, M], [R2, L], [R3, N, L], [N, K], [R4, I], [R5, H])]
    o.append(poly([R2, R3, (R3[0] - 20, R3[1] + 22), (R2[0] + 14, R2[1] + 4)], '#fff', 'opacity=".25"'))
    o.append(shard[0] + shard[1])
    vein = [(30, 140), (62, 158), (92, 150), (124, 166)]
    o.append(f'<polyline points="{P(vein)}" fill="none" stroke="{INK}" stroke-width="24" stroke-linecap="round" stroke-linejoin="round"/>'
             f'<polyline points="{P(vein)}" fill="none" stroke="{base}" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/>'
             f'<polyline points="{P(vein[:3])}" fill="none" stroke="{lt}" stroke-width="4" stroke-linecap="round" transform="translate(-1,-3)"/>')
    o.append(f'<circle cx="-124" cy="132" r="10" fill="{base}" stroke="{INK}" stroke-width="6"/>'
             f'<circle cx="-40" cy="190" r="6" fill="{base}" stroke="{INK}" stroke-width="5"/>')
    o.append(poly([(-166, 42), (-146, -6), (-100, -36), (-122, 6)], '#fff', 'opacity=".45"'))
    o.append(sparkle(-178, -140, 30) + sparkle(-132, -186, 14, .8) + sparkle(160, -110, 18, .9))
    return ''.join(o)

for k in ORE:
    (HERE / 'svg' / f'ore_{k}_V2N.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-240 -240 480 480">{v2n(k)}</svg>', encoding='utf-8')
cells = ''.join(f'<div class="cell">{ico(v2(k), 160)}{ico(v2n(k), 240)}{on_tile(k, v2n(k), 170)}<span>{k}</span></div>' for k in ORE)
bars = {k: gt.img(f'forge_bar_{k}') for k in ORE}
rows = ''.join(
    f'<div class="row">{on_tile(k, v2n(k), 86)}<div class="t"><b>{k.title()}</b><span>You have 5 · On pallet 0</span></div>'
    f'<div class="bars"><small>bars</small> ×2</div>'
    + gt.tile(gt.ORE_PAL[k], image=bars[k], scale=.86) + '</div>' for k in ORE)
html2 = html.split('<h1>')[0] + f'''<h1>Іконки руди — V2 (нова)</h1>
<p>Кристали ростуть із каменя: виходять із темної щілини-гнізда на верхній грані, передні грані каменю перекривають їхні основи, задні кристали темніші (глибина), з правої грані стирчить уламок, по передній грані йде жилка руди. Зліва — попередній V2 для порівняння.</p>
<div class="grid">{cells}</div>
<h2>У рядках вікна кузні</h2>
<div class="mock">{rows}</div>
<style>.mock{{background:#a9aeb5;border:5px solid #14161a;padding:16px;max-width:900px}}
.row{{display:flex;align-items:center;gap:16px;background:rgba(27,30,35,.6);border:3px solid #14161a;padding:6px;margin-top:10px}}
.row .t{{flex:1;display:flex;flex-direction:column}} .row b{{font-size:30px;color:#fff;font-weight:900}} .row .t span{{font-size:15px;color:#e9edf1;font-weight:800}}
.bars{{font-size:32px;font-weight:900;color:#d4ff3e}} .bars small{{font-size:16px;color:#e9edf1}}</style>
</div></body></html>'''
(HERE / 'ore_icons_v2.html').write_text(html2, encoding='utf-8')
print('v2n ok')
