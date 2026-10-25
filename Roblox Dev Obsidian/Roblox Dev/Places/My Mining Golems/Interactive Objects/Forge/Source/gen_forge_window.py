"""Forge — модальне вікно кузні (по центру екрана) у стилі наших карток покращень.
Пише forge_window.html: 6 станів, кнопка «відкрити знову», превʼю ПК (1280×720) і телефона (844×390).
Режим скриншота: forge_window.html?shot=<стан>&f=desk|phone — лише один екран 1:1.
"""
import pathlib, json
from fontTools.ttLib import TTFont

UI = pathlib.Path('/tmp/claude-0/-home-claude/8add1236-f2d8-59ff-a5ae-4d35d196baed/scratchpad/ui')
OUT = pathlib.Path(__file__).resolve().parent

# ---- повторно використовуємо gen_roll.py: шрифти, txt(), studs, sparkle ----
ns = {'__file__': str(UI / 'gen_roll.py')}
src = (UI / 'gen_roll.py').read_text(encoding='utf-8')
exec(src[:src.index("# ---------- іконки ----------")], ns)
INK, f800, f900, sparkle, card_studs = ns['INK'], ns['f800'], ns['f900'], ns['sparkle'], ns['card_studs']
_txt = ns['txt']
LIME = '#d4ff3e'

# ---- метрики шрифту (щоб перевірити, що текст влазить) ----
FM = {}
for wgt in (800, 900):
    f = TTFont(str(UI / f'node_modules/@fontsource/montserrat/files/montserrat-latin-{wgt}-normal.woff'))
    FM[wgt] = (f.getBestCmap(), f['hmtx'], f['head'].unitsPerEm)
def tw(s, size, wgt=900):
    cmap, hm, upm = FM[wgt]
    return sum(hm[cmap[ord(c)]][0] for c in s) / upm * size
FIT = []                                   # (текст, ширина, доступно) — перевірка в кінці
def fit(s, size, avail, wgt=900):
    FIT.append((s, round(tw(s, size, wgt)), avail))

def txt(x, y, s, size, fill='#fff', anchor='middle', wgt=900, sw=None, extra=''):
    """y — центр рядка (по висоті великих літер, capHeight = 0.70 em)."""
    return _txt(x, round(y + 0.35 * size, 1), s, size, fill, INK, sw, wgt, anchor, extra)

def rect(x, y, w, h, r, fill, stroke=None, sw=0, op=None, extra=''):
    s = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ''
    o = f' opacity="{op}"' if op is not None else ''
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}"{s}{o} {extra}/>'

def grad(gid, stops, vertical=True):
    xy = 'x1="0" y1="0" x2="0" y2="1"' if vertical else 'x1="0" y1="0" x2="1" y2="0"'
    return f'<linearGradient id="{gid}" {xy}>' + ''.join(
        f'<stop offset="{o}" stop-color="{c}"' + (f' stop-opacity="{a}"' if a is not None else '') + '/>'
        for o, c, *rest in stops for a in [rest[0] if rest else None]) + '</linearGradient>'

# ================= ПАЛІТРА =================
THEME = {   # light, main, dark  (як у GDD; фіолетова — нова тема за правилом HSL)
    'green':  ('#a6e862', '#6cc934', '#3f9d18'),
    'blue':   ('#6fc6ff', '#2f8ee6', '#1a5cb0'),
    'orange': ('#ffb15c', '#f07a1e', '#b8500c'),
    'red':    ('#ff6f66', '#e2322f', '#a8161b'),
    'purple': ('#c08af7', '#8a3fe6', '#561aa8'),
    'amber':  ('#ffe27a', '#ffb21e', '#e07a06'),
}
BTN = {'lime': ('#eaff9a', '#c3f04a', '#8ccc22'), 'dim': ('#d9e2b0', '#aab884', '#7d8a5c'), 'gray': ('#f4f5f6', '#d6d8db', '#a9adb2')}
BARF = {'cyan': ('#9ff0ff', '#3cc4f0', '#1688c8'), 'lime': BTN['lime'], 'orange': THEME['orange'], 'amber': THEME['amber'], 'purple': THEME['purple']}
TITLE_G = ('#fff2a0', '#ffc531', '#f07a1e')          # «Forge»: світло-жовтий → бурштин → помаранчевий
ORES = {   # name: (колір руди, колір злитка, плитка верх, плитка низ, потрібно)
    'Coal':   ('#2b2e33', '#34373d', '#5a5f67', '#23262b', 20),
    'Copper': ('#c8643a', '#d9733f', '#c9643a', '#6e2a12', 10),
    'Iron':   ('#d08a55', '#e0e4ea', '#c7a27a', '#6b5038', 5),
}

# ================= РОЗКЛАДКА (одиниці дизайну) =================
CANVAS = (1120, 740)               # ModalRoot; UIScale масштабує все
WIN = (40, 60, 1040, 650)          # x, y, w, h вікна в ModalRoot
WIN_R, RIM = 40, 18                # кут вікна, ширина темного обідка
PAN_R = 26
CX0, CW = 42, 956                  # ліва межа й ширина вмісту (у координатах вікна)
ROW1 = (68, 50)                    # чипи стану: y, h
ROW2 = (128, 50)                   # рядок-шкала (Ore given / Ore pallet): y, h
ROWS_Y, ROW_H, ROW_GAP = 192, 96, 10
BTN_Y, BTN_H, BTN_W, BTN_GAP = 520, 82, 400, 32
TILE = 80
X_BTN = (1070, 70, 92)             # центр x, y і розмір кнопки X (у ModalRoot)
TITLE = (72, 91, 112)              # x, baseline, розмір шрифту «Forge» (у ModalRoot)

# ================= ІКОНКИ (полотно 480, viewBox −240…240) =================
def P(pts): return ' '.join(f'{x:.1f},{y:.1f}' for x, y in pts)
def shade(hexc, k):
    c = [int(hexc[i:i + 2], 16) for i in (1, 3, 5)]
    c = [min(255, max(0, round(v + (255 - v) * k if k > 0 else v * (1 + k)))) for v in c]
    return '#' + ''.join(f'{v:02x}' for v in c)

def nugget(x, y, r, col):
    l, m, d = shade(col, .45), col, shade(col, -.35)
    pts = [(x, y - r), (x + r, y - r * .25), (x + r * .62, y + r), (x - r * .62, y + r), (x - r, y - r * .25)]
    top = [(x, y - r), (x + r, y - r * .25), (x, y + r * .05), (x - r, y - r * .25)]
    rgt = [(x + r, y - r * .25), (x + r * .62, y + r), (x, y + r), (x, y + r * .05)]
    return (f'<polygon points="{P(pts)}" fill="{INK}" stroke="{INK}" stroke-width="16" stroke-linejoin="round"/>'
            f'<polygon points="{P(pts)}" fill="{m}"/><polygon points="{P(rgt)}" fill="{d}"/><polygon points="{P(top)}" fill="{l}"/>'
            f'<ellipse cx="{x - r * .35:.1f}" cy="{y - r * .38:.1f}" rx="{r * .28:.1f}" ry="{r * .14:.1f}" fill="#fff" opacity=".6"/>')

def ore_icon(kind):
    """Кусок руди: грубий камінь у 3 гранях + самородки кольору руди."""
    col = ORES[kind][0]
    rock = ('#c9ced4', '#959ca5', '#6a717a') if kind == '_plain' else ('#a9afb7', '#7c838c', '#575d65')
    A, B, C, D, E, F, G, H = (-178, 0), (-120, -112), (0, -158), (130, -122), (182, -6), (138, 112), (0, 158), (-136, 116)
    M = (12, 6)
    o = [f'<polygon points="{P([A, B, C, D, E, F, G, H])}" fill="{INK}" stroke="{INK}" stroke-width="24" stroke-linejoin="round"/>',
         f'<polygon points="{P([A, M, G, H])}" fill="{rock[1]}"/>',
         f'<polygon points="{P([M, E, F, G])}" fill="{rock[2]}"/>',
         f'<polygon points="{P([A, B, C, D, E, M])}" fill="{rock[0]}"/>',
         f'<polyline points="{P([A, M, E])}" fill="none" stroke="{INK}" stroke-width="7" stroke-linejoin="round" opacity=".45"/>',
         f'<polyline points="{P([M, G])}" fill="none" stroke="{INK}" stroke-width="7" opacity=".45"/>',
         f'<polygon points="{P([(-112, -78), (-40, -122), (-2, -116), (-84, -58)])}" fill="#fff" opacity=".45"/>']
    if kind == '_plain':   # тріщини (камінь без руди; зараз не використовується)
        o.append(f'<polyline points="{P([(-90, 40), (-54, 70), (-66, 104)])}" fill="none" stroke="{INK}" stroke-width="8" stroke-linecap="round" stroke-linejoin="round" opacity=".5"/>')
        o.append(f'<polyline points="{P([(70, 30), (96, 64), (84, 92)])}" fill="none" stroke="{INK}" stroke-width="8" stroke-linecap="round" stroke-linejoin="round" opacity=".5"/>')
        o.append(f'<polyline points="{P([(40, -96), (78, -70)])}" fill="none" stroke="{INK}" stroke-width="7" stroke-linecap="round" opacity=".35"/>')
    else:
        for (x, y, r) in ((-58, -58, 54), (78, -40, 44), (-20, 76, 46)):
            o.append(nugget(x, y, r, col))
    o.append(sparkle(-150, -150, 30)); o.append(sparkle(-104, -192, 14, .8))
    return ''.join(o)

def ingot_icon(kind):
    """Злиток в ізометрії: трапецієподібна призма кольору злитка."""
    col = ORES[kind][1]
    l, m, d = shade(col, .5), col, shade(col, -.3)
    if kind == 'Iron':
        l, m, d = '#ffffff', '#d9dee5', '#9aa2ac'
    if kind == 'Coal':
        l, m, d = '#6b7079', '#3a3d43', '#202226'
    def iso(x, y, z): return ((x - z) * 0.866, (x + z) * 0.5 - y + 40)
    L, Dp, Hh, ins = 150, 82, 92, 30
    b = [iso(-L, 0, -Dp), iso(L, 0, -Dp), iso(L, 0, Dp), iso(-L, 0, Dp)]
    t = [iso(-L + ins, Hh, -Dp + ins), iso(L - ins, Hh, -Dp + ins), iso(L - ins, Hh, Dp - ins), iso(-L + ins, Hh, Dp - ins)]
    sil = [t[0], t[1], b[1], b[2], b[3], t[3]]
    front = [t[3], t[2], b[2], b[3]]      # ліва-передня (довга) грань
    side = [t[2], t[1], b[1], b[2]]       # права (торець)
    o = [f'<polygon points="{P(sil)}" fill="{INK}" stroke="{INK}" stroke-width="24" stroke-linejoin="round"/>',
         f'<polygon points="{P(front)}" fill="{m}"/>', f'<polygon points="{P(side)}" fill="{d}"/>',
         f'<polygon points="{P(t)}" fill="{l}"/>',
         f'<polyline points="{P([t[3], t[2], t[1]])}" fill="none" stroke="{INK}" stroke-width="7" stroke-linejoin="round" opacity=".4"/>',
         f'<polyline points="{P([t[2], b[2]])}" fill="none" stroke="{INK}" stroke-width="7" opacity=".4"/>']
    g1 = [iso(-L + ins + 14, Hh, Dp - ins - 16), iso(L - ins - 60, Hh, Dp - ins - 16), iso(L - ins - 80, Hh, Dp - ins - 36), iso(-L + ins + 14, Hh, Dp - ins - 36)]
    o.append(f'<polygon points="{P(g1)}" fill="#fff" opacity=".6"/>')
    o.append(f'<polyline points="{P([iso(-L + 10, 8, Dp), iso(L - 40, 8, Dp)])}" fill="none" stroke="#fff" stroke-width="8" stroke-linecap="round" opacity=".35"/>')
    o.append(sparkle(-120, -112, 30)); o.append(sparkle(150, -86, 15, .8))
    return ''.join(o)

def icon(body, x, y, size):
    return f'<svg x="{x}" y="{y}" width="{size}" height="{size}" viewBox="-240 -240 480 480">{body}</svg>'

# ================= DEFS (спільні для всіх SVG сторінки) =================
def studs(pid, cell, base, stud, shade_, edge, ox=0, oy=0):
    s = cell * 0.62; o = (cell - s) / 2; d = s * 0.12; r = s * 0.16
    return (f'<pattern id="{pid}" x="{ox}" y="{oy}" width="{cell}" height="{cell}" patternUnits="userSpaceOnUse">'
            f'<rect width="{cell}" height="{cell}" fill="{base}"/>'
            f'<rect x="{o - d/2:.2f}" y="{o + d/2:.2f}" width="{s:.2f}" height="{s:.2f}" rx="{r:.2f}" fill="{shade_}"/>'
            f'<rect x="{o + d/2:.2f}" y="{o - d/2:.2f}" width="{s:.2f}" height="{s:.2f}" rx="{r:.2f}" fill="{stud}" stroke="{edge}" stroke-width="2"/></pattern>')

PAN_X, PAN_Y, PAN_W, PAN_H = RIM, RIM, WIN[2] - 2 * RIM, WIN[3] - 2 * RIM
CELL = 40
SOX = PAN_X + (PAN_W - (PAN_W // CELL) * CELL) / 2      # центрована сітка studs
SOY = PAN_Y + (PAN_H - (PAN_H // CELL) * CELL) / 2
DEFS = [studs('wPanel', CELL, '#a9aeb5', '#b3b8bf', '#868b92', '#c8ccd1', SOX, SOY),
        card_studs('chipStuds', 30, '#ffffff', '#000000'),
        grad('rimG', [(0, '#5d636b'), (1, '#3c4047')]),
        grad('panelShadeW', [(0, '#000', .26), (.07, '#000', 0), (.93, '#fff', 0), (1, '#fff', .18)]),
        grad('glossW', [(0, '#fff', .32), (1, '#fff', 0)]),
        grad('trackG', [(0, '#1a1d22'), (1, '#353b44')]),
        grad('rowG', [(0, '#353b43', .5), (1, '#1b1e23', .6)]),
        grad('titleG', [(0, TITLE_G[0]), (.5, TITLE_G[1]), (1, TITLE_G[2])]),
        grad('backG', [(0, '#1d2129'), (1, '#0f1115')])]
for k, (a, b, c) in {**{f't_{k}': v for k, v in THEME.items()}, **{f'b_{k}': v for k, v in BTN.items()},
                     **{f'f_{k}': v for k, v in BARF.items()}}.items():
    DEFS.append(grad(k, [(0, a), (.5 if k[0] != 't' else .55, b), (1, c)]))
for n, (oc, bc, t0, t1, _) in ORES.items():
    DEFS.append(grad(f'tile_{n}', [(0, t0), (1, t1)]))
DEFS = ''.join(DEFS)
SPRITES = {f'ore_{n}': ore_icon(n) for n in ORES} | {f'bar_{n}': ingot_icon(n) for n in ORES}

# окремі SVG іконок (PNG 512 рендеримо після «переносимо», як у GDD)
(OUT / 'icons').mkdir(exist_ok=True)
for _n, _b in SPRITES.items():
    (OUT / 'icons' / f'{_n.lower()}.svg').write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-240 -240 480 480">{_b}</svg>', encoding='utf-8')

# ================= ЕЛЕМЕНТИ =================
def chip(x, y, label, theme, size=26, h=None):
    h = h or ROW1[1]
    w = round(tw(label, size) + 44)
    o = [rect(x, y + 5, w, h, 16, '#000', op=.3),
         rect(x, y, w, h, 16, f'url(#t_{theme})', INK, 8),
         rect(x + 8, y + 6, w - 16, h * .36, 10, '#fff', op=.3),
         txt(x + w / 2, y + h / 2, label, size)]
    return ''.join(o), w

def button(x, y, w, h, label, state, size=40, cls='btn'):
    fit(label, size, w - 40)
    a = f'class="{cls} {state}" data-state="{state}"'
    return (f'<g {a}>' + rect(x, y + 8, w, h, 28, '#000', op=.3) +
            rect(x, y, w, h, 28, f'url(#b_{state})', INK, 10) +
            rect(x + 16, y + 10, w - 32, round(h * .36), 16, '#fff', op=.35) +
            txt(x + w / 2, y + h / 2, label, size) + '</g>')

def bar(x, y, w, h, frac, fillg, label, size=28, anim=None):
    o = [rect(x, y, w, h, h / 2, 'url(#trackG)')]
    fw = 0 if frac <= 0 else max(h, w * min(1, frac))
    if fw or anim:
        av = (f'<animate attributeName="width" values="{h};{w};{w}" keyTimes="0;.85;1" dur="{anim}s" repeatCount="indefinite"/>' if anim else '')
        o.append(f'<rect x="{x}" y="{y}" width="{fw or h}" height="{h}" rx="{h/2}" fill="url(#f_{fillg})">{av}</rect>')
        o.append(f'<rect x="{x + 10}" y="{y + 5}" width="{max(0, (fw or h) - 20)}" height="{round(h * .3)}" rx="{h * .15}" fill="#fff" opacity=".4">'
                 + (f'<animate attributeName="width" values="{h-20};{w-20};{w-20}" keyTimes="0;.85;1" dur="{anim}s" repeatCount="indefinite"/>' if anim else '') + '</rect>')
    o.append(rect(x, y, w, h, h / 2, 'none', INK, 8))
    if label:
        fit(label, size, w - 30)
        o.append(txt(x + w / 2, y + h / 2, label, size))
    return ''.join(o)

def tile(x, y, kind, sprite, check=False):
    o = [rect(x, y, TILE, TILE, 18, f'url(#tile_{kind})', INK, 6),
         rect(x + 5, y + 5, TILE - 10, TILE * .4, 12, '#fff', op=.18),
         icon(SPRITES[sprite], x + 4, y + 4, TILE - 8)]
    if check:
        cx, cy = x + TILE - 4, y + 6
        o.append(f'<circle cx="{cx}" cy="{cy}" r="17" fill="{INK}"/><circle cx="{cx}" cy="{cy}" r="13" fill="url(#b_lime)"/>'
                 f'<path d="M{cx-7},{cy} L{cx-2},{cy+5} L{cx+7},{cy-5}" fill="none" stroke="{INK}" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>'
                 f'<path d="M{cx-7},{cy} L{cx-2},{cy+5} L{cx+7},{cy-5}" fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>')
    return ''.join(o)

def ore_row(i, kind, sub, right):
    y = ROWS_Y + i * (ROW_H + ROW_GAP); x = CX0
    o = [f'<g transform="translate({x},{y})">',
         rect(0, 0, CW, ROW_H, 22, 'url(#rowG)', INK, 6)]
    o.append(right['tile'])
    o.append(txt(106, 32, kind, 38, anchor='start'))
    o.append(txt(106, 70, sub, 22, '#e9edf1', anchor='start', wgt=800))
    fit(kind, 38, 300); fit(sub, 22, 440 - 106 - 12 if right.get('bar') else 600, 800)
    o.append(right['body'])
    o.append('</g>')
    return ''.join(o)

def window_body():
    W, H = WIN[2], WIN[3]
    return ''.join([
        rect(0, 14, W, H, WIN_R, '#000', op=.35),
        rect(0, 0, W, H, WIN_R, 'url(#rimG)'),
        rect(6, 6, W - 12, H - 12, WIN_R - 6, 'none', '#6a7078', 3, .9),
        rect(PAN_X, PAN_Y, PAN_W, PAN_H, PAN_R, 'url(#wPanel)'),
        rect(PAN_X, PAN_Y, PAN_W, PAN_H, PAN_R, 'url(#panelShadeW)'),
        rect(PAN_X, PAN_Y, PAN_W, PAN_H, PAN_R, 'none', INK, 8),
        rect(0, 0, W, H, WIN_R, 'none', INK, 10)])

def title_and_close():
    tx, tb, ts = TITLE
    o = [f'<text x="{tx}" y="{tb + 7}" font-family="Montserrat" font-weight="900" font-size="{ts}" fill="{INK}" stroke="{INK}" stroke-width="20" stroke-linejoin="round" paint-order="stroke fill">Forge</text>',
         f'<text x="{tx}" y="{tb}" font-family="Montserrat" font-weight="900" font-size="{ts}" fill="url(#titleG)" stroke="{INK}" stroke-width="18" stroke-linejoin="round" paint-order="stroke fill">Forge</text>',
         ]
    cx, cy, s = X_BTN; x, y = cx - s / 2, cy - s / 2
    o.append(f'<g class="btn xbtn" data-state="lime">' + rect(x, y + 8, s, s, 26, '#000', op=.3) +
             rect(x, y, s, s, 26, 'url(#t_red)', INK, 10) + rect(x + 12, y + 9, s - 24, round(s * .34), 14, '#fff', op=.35))
    for pass_ in ('ink', 'white'):
        for a in (45, -45):
            if pass_ == 'ink':
                o.append(f'<rect x="{cx-30}" y="{cy-9}" width="60" height="18" rx="7" fill="#fff" stroke="{INK}" stroke-width="10" transform="rotate({a} {cx} {cy})"/>')
            else:
                o.append(f'<rect x="{cx-30}" y="{cy-9}" width="60" height="18" rx="7" fill="#fff" transform="rotate({a} {cx} {cy})"/>')
    o.append('</g>')
    return ''.join(o)

DATA = {
    'asleep':       {'Coal': (25, 12), 'Copper': (3, 10), 'Iron': (1, 2)},
    'asleep_ready': {'Coal': (5, 20), 'Copper': (0, 10), 'Iron': (0, 5)},
    'working':      {'Coal': (6, 4, 12), 'Copper': (2, 3, 8), 'Iron': (0, 1, 3)},
    'working_empty': {'Coal': (6, 4, 0), 'Copper': (2, 3, 0), 'Iron': (0, 1, 0)},
}
STATES = [('asleep', 'Спить'), ('asleep_ready', 'Спить · усе зібрано'), ('waking', 'Прокидається'),
          ('working', 'Працює'), ('working_empty', 'Працює · злитків 0'), ('sleeping', 'Засинає')]

def test_btn():
    x, y, w, h = CX0 + CW - 150, ROW2[0] + 5, 150, 40
    return (f'<g class="btn test" data-state="gray">' + rect(x, y + 5, w, h, 14, '#000', op=.3) + rect(x, y, w, h, 14, 'url(#b_gray)', INK, 6) +
            rect(x + 8, y + 5, w - 16, 13, 7, '#fff', op=.45) + txt(x + w / 2, y + h / 2, 'TEST +10', 20, sw=5) + '</g>')

def row2(label, frac, fillg, text, anim=None):
    y, h = ROW2
    fit(label, 28, 150)
    bx = CX0 + 170                         # підпис 150 + 20; шкала 618; 18; TEST 150
    bw = CX0 + CW - 150 - 18 - bx
    return txt(CX0, y + h / 2, label, 28, anchor='start') + bar(bx, y, bw, h, frac, fillg, text, 28, anim)

def overlay(msg, fillg='amber'):
    y0, y1 = ROW2[0] - 8, ROWS_Y + 3 * ROW_H + 2 * ROW_GAP + 8
    cy = (y0 + y1) / 2
    dots = ''.join(f'<tspan class="dot d{i}">.</tspan>' for i in range(3))
    fit(msg + '...', 72, CW - 60)
    return (rect(CX0 - 8, y0, CW + 16, y1 - y0, 24, '#0d0f12', op=.72) +
            f'<text x="{CX0 + CW/2}" y="{cy - 34 + 25}" font-family="Montserrat" font-weight="900" font-size="72" text-anchor="middle" fill="#ffd34d" '
            f'stroke="{INK}" stroke-width="16" stroke-linejoin="round" paint-order="stroke fill">{msg}{dots}</text>' +
            bar(CX0 + CW / 2 - 240, cy + 28, 480, 36, 0, fillg, '', anim=2.0))

def modal(state):
    o = [f'<svg class="modalsvg" viewBox="0 0 {CANVAS[0]} {CANVAS[1]}" width="{CANVAS[0]}" height="{CANVAS[1]}" xmlns="http://www.w3.org/2000/svg">',
         f'<g transform="translate({WIN[0]},{WIN[1]})">', window_body()]
    y1, h1 = ROW1
    asleepish = state in ('asleep', 'asleep_ready', 'waking')
    if asleepish:
        d = DATA['asleep_ready' if state != 'asleep' else 'asleep']
        lab, theme = ('ASLEEP', 'blue') if state != 'waking' else ('WAKING UP', 'amber')
        c, w = chip(CX0, y1, lab, theme); o.append(c)
        msg = 'The golem is asleep. Bring ore to wake him up.' if state != 'waking' else 'All ore delivered. The golem is waking up!'
        fit(msg, 26, CW - w - 20); o.append(txt(CX0 + w + 20, y1 + h1 / 2 + 2, msg, 26, anchor='start'))
        given = sum(v[1] for v in d.values()); need = sum(ORES[k][4] for k in ORES)
        o.append(row2('Ore given', given / need, 'lime' if given >= need else 'cyan', f'{given} / {need}'))
        o.append(test_btn())
        for i, k in enumerate(ORES):
            have, g = d[k]; nd = ORES[k][4]; full = g >= nd
            body = bar(440, 22, CW - 440 - 16, 52, g / nd, 'lime' if full else 'cyan', f'{g} / {nd}', 30)
            o.append(ore_row(i, k, f'You have {have}', {'tile': tile(8, 8, k, f'ore_{k}', full), 'body': body, 'bar': 1}))
        ready = given >= need
        if state == 'waking':
            o.append(overlay('WAKING UP'))
            b1, b2 = 'dim', 'dim'
        else:
            b1 = 'lime' if any(d[k][0] > 0 and d[k][1] < ORES[k][4] for k in ORES) else 'dim'
            b2 = 'lime' if ready else 'dim'
        bx = CX0 + (CW - 2 * BTN_W - BTN_GAP) / 2
        o.append(button(bx, BTN_Y, BTN_W, BTN_H, 'Give Ore', b1))
        o.append(button(bx + BTN_W + BTN_GAP, BTN_Y, BTN_W, BTN_H, 'Wake Up', b2))
    else:
        d = DATA['working_empty' if state == 'working_empty' else 'working']
        if state == 'sleeping':
            c, w = chip(CX0, y1, 'FALLING ASLEEP', 'purple'); o.append(c)
            msg = 'The pallet is empty. The golem is falling asleep.'
            fit(msg, 24, CW - w - 20); o.append(txt(CX0 + w + 20, y1 + h1 / 2 + 2, msg, 24, anchor='start'))
        else:
            x = CX0
            for lab, th in (('WORKING', 'green'), ('1 ore every 2.75s', 'blue'), ('Bar = ×2.5 ore price', 'orange')):
                c, w = chip(x, y1, lab, th); o.append(c); x += w + 14
            FIT.append(('chips', x - 14 - CX0, CW))
        pv = 0 if state == 'sleeping' else 240
        o.append(row2('Ore pallet', pv / 600, 'orange', f'${pv} / $600'))
        o.append(test_btn())
        for i, k in enumerate(ORES):
            have, pal, bars = d[k]
            if state == 'sleeping': pal = 0
            ix = CW - 8 - TILE
            body = (txt(ix - 16, ROW_H / 2, f'×{bars}', 44, LIME if bars else '#c9ced4', anchor='end') +
                    txt(ix - 16 - tw(f'×{bars}', 44) - 14, ROW_H / 2 + 2, 'bars', 22, '#e9edf1', anchor='end', wgt=800) +
                    tile(ix, 8, k, f'bar_{k}'))
            o.append(ore_row(i, k, f'You have {have} · On pallet {pal}', {'tile': tile(8, 8, k, f'ore_{k}'), 'body': body}))
        total = sum(v[2] for v in d.values())
        if state == 'sleeping':
            o.append(overlay('FALLING ASLEEP', 'purple'))
        bx = CX0 + (CW - 2 * BTN_W - BTN_GAP) / 2
        o.append(button(bx, BTN_Y, BTN_W, BTN_H, 'Put Ore', 'dim' if state == 'sleeping' else 'lime'))
        o.append(button(bx + BTN_W + BTN_GAP, BTN_Y, BTN_W, BTN_H, f'Take Bars ({total})', 'lime' if total and state != 'sleeping' else 'dim'))
    o.append('</g>')
    o.append(title_and_close())
    o.append('</svg>')
    return ''.join(o)

# ================= ФОН «ГРИ» =================
def game_bg(W, H, phone=False):
    """Умовна сцена гри (шахта з кузнею) — лише щоб видно було, що вікно поверх гри."""
    k = H / 720
    def R(x, y, w, h, c, r=6, op=None):
        return rect(round(x, 1), round(y, 1), round(w, 1), round(h, 1), round(r * k, 1), c, op=op)
    o = [f'<svg class="bg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" xmlns="http://www.w3.org/2000/svg">',
         grad('skyG', [(0, '#7b93b0'), (1, '#4c5d74')]).join(['<defs>', '</defs>']),
         f'<rect width="{W}" height="{H}" fill="url(#skyG)"/>']
    hz = H * .6
    for i, (x, w, h) in enumerate(((-.02, .14, .34), (.1, .12, .22), (.7, .16, .4), (.84, .2, .3), (.26, .1, .14))):   # скелі-блоки
        o.append(R(x * W, hz - h * H, w * W, h * H + 4, ('#64748a', '#5a6a80', '#6b7b91')[i % 3], 10))
        o.append(R(x * W + 10 * k, hz - h * H + 10 * k, w * W - 20 * k, 14 * k, '#8597ad', 6))
    o.append(R(0, hz, W, H - hz, '#8d7556', 0))
    step = 80 * k
    for j in range(int((H - hz) / (40 * k)) + 1):
        for i in range(int(W / step) + 2):
            o.append(R(i * step - (j % 2) * step / 2 + 3 * k, hz + j * 40 * k + 3 * k, step - 6 * k, 34 * k, '#9a8160', 6))
    fx, fw = W * .38, W * .24                   # кузня
    o.append(R(fx + fw * .62, hz - 340 * k, fw * .2, 140 * k, '#6e625a', 4))
    o.append(R(fx, hz - 240 * k, fw, 240 * k, '#8e7f74', 14))
    o.append(R(fx + fw * .7, hz - 240 * k, fw * .3, 240 * k, '#76695f', 14))
    o.append(R(fx + fw * .16, hz - 160 * k, fw * .44, 100 * k, '#3b2a20', 12))
    o.append(R(fx + fw * .19, hz - 140 * k, fw * .38, 70 * k, '#ff8a2a', 10))
    o.append(R(fx + fw * .23, hz - 132 * k, fw * .3, 22 * k, '#ffd36a', 8))
    o.append(f'<ellipse cx="{fx+fw/2}" cy="{hz+90*k}" rx="{fw*.5}" ry="{40*k}" fill="none" stroke="#5fe8ff" stroke-width="{9*k}"/>')
    gx = fx + fw + 30 * k                       # сплячий голем
    o.append(R(gx, hz - 90 * k, 120 * k, 110 * k, '#8b929b', 16)); o.append(R(gx + 20 * k, hz - 150 * k, 80 * k, 66 * k, '#a3aab3', 14))
    o.append(R(gx + 34 * k, hz - 122 * k, 18 * k, 6 * k, '#2a2d33', 3)); o.append(R(gx + 68 * k, hz - 122 * k, 18 * k, 6 * k, '#2a2d33', 3))
    px = fx + fw / 2                            # гравець
    o.append(R(px - 20 * k, hz + 30 * k, 40 * k, 80 * k, '#3f7fd0', 8)); o.append(R(px - 17 * k, hz - 4 * k, 34 * k, 34 * k, '#f2c79a', 8))
    # HUD грошей (спрощено)
    o.append(R(16 * k, H - 76 * k, 200 * k, 56 * k, '#14161a', 16, .8))
    o.append(f'<text x="{32*k:.1f}" y="{H-36*k:.1f}" font-family="Montserrat" font-weight="900" font-size="{34*k:.1f}" fill="#a8ff2c" stroke="{INK}" stroke-width="{7*k:.1f}" paint-order="stroke fill">$1,240</text>')
    o.append('</svg>')
    return ''.join(o)

# ================= HTML =================
templates = ''.join(f'<template id="tpl_{k}">{modal(k)}</template>' for k, _ in STATES)
state_btns = ''.join(f'<button data-s="{k}">{n}</button>' for k, n in STATES)
html = f'''<!doctype html><html lang="uk"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Forge Window</title>
<style>
@font-face {{ font-family: Montserrat; font-weight: 800; src: url(data:font/woff2;base64,{f800}) format('woff2'); }}
@font-face {{ font-family: Montserrat; font-weight: 900; src: url(data:font/woff2;base64,{f900}) format('woff2'); }}
:root{{--bg:#20242a;--fg:#e8edf2;--mut:#b9c2cc;--acc:#ffd34d}}
body{{margin:0;background:var(--bg);color:var(--fg);font-family:system-ui,sans-serif}}
.wrap{{max-width:1180px;margin:0 auto;padding:24px 16px 48px}}
h1{{font-size:20px;color:var(--acc);margin:0 0 6px}} h2{{font-size:16px;margin:26px 0 10px;color:#c9d2dc}}
p,li{{color:var(--mut);font-size:14px;line-height:1.5;margin:0 0 8px}}
.ctl{{display:flex;flex-wrap:wrap;gap:8px;margin:14px 0}}
.ctl button{{background:#2b323b;color:#e8edf2;border:1px solid #46505c;border-radius:8px;padding:7px 12px;font:600 13px system-ui;cursor:pointer}}
.ctl button.on{{background:#c3f04a;color:#14161a;border-color:#8ccc22}}
.ctl .replay{{background:#ffb21e;color:#14161a;border-color:#e07a06}}
.fit{{width:100%;position:relative;border-radius:14px;overflow:hidden;box-shadow:0 10px 36px rgba(0,0,0,.45)}}
.screen{{position:relative;overflow:hidden;transform-origin:0 0}}
.screen .bg{{position:absolute;left:0;top:0}}
.backdrop{{position:absolute;inset:0;background:#000;opacity:.55}}
.modal{{position:absolute;left:50%;top:50%;width:{CANVAS[0]}px;height:{CANVAS[1]}px}}
.pop{{width:100%;height:100%;transform-origin:50% 50%}}
.modalsvg{{display:block;overflow:visible}}
.open .pop{{animation:pop .25s linear both}}
.open .backdrop{{animation:fade .2s linear both}}
.closing .pop{{animation:shut .12s ease-in both}} .closing .backdrop{{animation:fadeout .12s linear both}}
@keyframes pop{{0%{{transform:scale(.85);animation-timing-function:cubic-bezier(.25,.46,.45,.94)}}60%{{transform:scale(1.05);animation-timing-function:cubic-bezier(.45,0,.55,1)}}100%{{transform:scale(1)}}}}
@keyframes fade{{from{{opacity:0}}to{{opacity:.55}}}} @keyframes fadeout{{from{{opacity:.55}}to{{opacity:0}}}}
@keyframes shut{{from{{transform:scale(1);opacity:1}}to{{transform:scale(.85);opacity:0}}}}
.btn{{cursor:pointer;transform-box:fill-box;transform-origin:center;transition:transform .1s}}
.btn:hover:not(.dim){{transform:scale(1.04)}} .btn:active:not(.dim){{transform:scale(.92)}}
.btn.shake{{animation:shake .18s linear}}
@keyframes shake{{0%{{transform:translateX(-10px)}}17%{{transform:translateX(10px)}}33%{{transform:translateX(-7px)}}50%{{transform:translateX(7px)}}67%{{transform:translateX(-3px)}}100%{{transform:translateX(0)}}}}
.dot{{animation:dot 1.2s infinite}} .d1{{animation-delay:.2s}} .d2{{animation-delay:.4s}}
@keyframes dot{{0%,24%{{opacity:0}}25%,100%{{opacity:1}}}}
.phoneWrap{{display:flex;justify-content:center}}
.phone{{padding:14px 26px;background:#0b0c0e;border-radius:44px;box-shadow:0 10px 36px rgba(0,0,0,.5),inset 0 0 0 2px #333}}
.phone .screen{{border-radius:22px}}
.cap{{text-align:center;font-size:13px;color:var(--mut);margin-top:8px}}
body.shot .wrap>*:not(.shotkeep){{display:none}} body.shot .wrap{{padding:0;max-width:none}}
body.shot .fit,body.shot .phone{{box-shadow:none;border-radius:0;padding:0;background:none}} body.shot .phone .screen{{border-radius:0}}
@media (max-width:600px){{.phone{{padding:8px;border-radius:20px}}}}
</style></head><body>
<svg width="0" height="0" style="position:absolute" aria-hidden="true"><defs>{DEFS}</defs></svg>
<div class="wrap">
<h1>Forge — модальне вікно кузні</h1>
<p>Нове вікно замість тимчасової темної панелі внизу екрана. Відкривається по центру, коли гравець стає в кільце перед кузнею: темне тло 55% і «поп» 0,85 → 1,05 → 1 за 0,25 с. Полотно {CANVAS[0]} × {CANVAS[1]} одиниць, на екран його масштабує один UIScale. Кнопки внизу перемикають стан голема.</p>
<div class="ctl">{state_btns}<button class="replay" id="replay">▶ Відкрити знову</button></div>
<h2 class="dk">ПК, 1280 × 720</h2>
<div class="fit shotkeep" id="deskFit"><div class="screen" id="desk" style="width:1280px;height:720px">{game_bg(1280, 720)}<div class="backdrop"></div><div class="modal"><div class="pop"></div></div></div></div>
<h2>Телефон, 844 × 390 (горизонтально)</h2>
<div class="phoneWrap shotkeep" id="phoneWrap"><div class="phone"><div class="screen" id="phone" style="width:844px;height:390px">{game_bg(844, 390, True)}<div class="backdrop"></div><div class="modal"><div class="pop"></div></div></div></div></div>
<p class="cap">Той самий макет, UIScale ≈ 0,5. Найдрібніший текст (20–22) стає ≈ 10–11 px — читається; дрібніше на телефоні не робимо.</p>
<h2>Як працює</h2>
<ul>
<li><b>Спить:</b> три рядки руди (Coal / Copper / Iron) — скільки є в гравця і шкала «віддано / треба». Повна шкала стає лаймовою, на плитці — галочка. «Give Ore» віддає скільки можна; «Wake Up» лаймова лише коли всі шкали повні.</li>
<li><b>Прокидається / Засинає:</b> затемнення поверх рядків з жовтим написом і шкалою, обидві кнопки тьмяні.</li>
<li><b>Працює:</b> шкала «Ore pallet» ($ на палеті / місткість), чипи з темпом і множником, рядки руди з кількістю злитків. «Take Bars (N)» тьмяна, якщо злитків 0.</li>
<li>Тьмяна кнопка при натисканні хитається; наведення — 1,04, натискання — 0,92 (як у GDD). Хрестик закриває вікно (0,12 с), «Відкрити знову» — повторює появу.</li>
<li>«TEST +10» — сіра маленька кнопка тільки для розробки, праворуч від шкали.</li>
</ul>
</div>
{templates}
<script>
const CW={CANVAS[0]}, CH={CANVAS[1]};
const q=new URLSearchParams(location.search);
let cur=q.get('shot')||'asleep';
function uiScale(w,h,mx,my){{return Math.min((w-2*mx)/CW,(h-2*my)/CH)}}
function place(id,w,h,mx,my){{const s=uiScale(w,h,mx,my);const m=document.querySelector('#'+id+' .modal');
  m.style.transform=`translate(-50%,-50%) scale(${{s}})`;m.dataset.s=s.toFixed(3);}}
function show(st,anim=true){{cur=st;
  document.querySelectorAll('.ctl button[data-s]').forEach(b=>b.classList.toggle('on',b.dataset.s===st));
  for(const id of ['desk','phone']){{const scr=document.getElementById(id);const pop=scr.querySelector('.pop');
    pop.innerHTML=document.getElementById('tpl_'+st).innerHTML;scr.classList.remove('closing');
    if(anim){{scr.classList.remove('open');void scr.offsetWidth;scr.classList.add('open')}}}}
  bind();}}
function bind(){{document.querySelectorAll('.pop .btn').forEach(b=>b.addEventListener('click',()=>{{
  if(b.classList.contains('xbtn')){{const scr=b.closest('.screen');scr.classList.remove('open');scr.classList.add('closing');return}}
  if(b.classList.contains('dim')){{b.classList.remove('shake');void b.getBBox();b.classList.add('shake')}}}}))}}
function fit(){{const f=document.getElementById('deskFit');const k=Math.min(1,f.clientWidth/1280);
  const d=document.getElementById('desk');d.style.transform=`scale(${{k}})`;f.style.height=(720*k)+'px';
  const pw=document.getElementById('phoneWrap');const pk=Math.min(1,(pw.clientWidth-60)/844);const ph=document.getElementById('phone');
  ph.style.transform=`scale(${{pk}})`;ph.parentElement.style.width=(844*pk)+'px';ph.parentElement.style.height=(390*pk)+'px';}}
place('desk',1280,720,24,16);place('phone',844,390,12,8);
document.querySelectorAll('.ctl button[data-s]').forEach(b=>b.onclick=()=>show(b.dataset.s));
document.getElementById('replay').onclick=()=>show(cur);
if(q.get('shot')){{document.body.classList.add('shot');
  const keep=q.get('f')==='phone'?'phoneWrap':'deskFit';document.querySelectorAll('.shotkeep').forEach(e=>{{if(e.id!==keep)e.style.display='none'}});
  show(cur,false);}}
else{{addEventListener('resize',fit);fit();show(cur);}}
</script>
</body></html>'''
(OUT / 'forge_window.html').write_text(html, encoding='utf-8')

# ---- перевірка розмірів тексту ----
bad = [f for f in FIT if f[1] > f[2]]
for f in bad: print('OVERFLOW', f)
print('fit checks:', len(FIT), 'overflow:', len(bad))
print('chips/widths', [f for f in FIT if f[0] == 'chips'])
print(OUT / 'forge_window.html', len(html))
