"""Кнопки v2 — векторні кнопки за референсами користувача (зелена й червона з набору кнопок).
Стиль A («зелена»): вертикальний градієнт, світла внутрішня рамка, світла лінія над губою, візерунок «квадратик + L».
Стиль B («червона»): насичений центр зі світлішим сяйвом по краях, візерунок з порожніх квадратиків (темний / світлий).
Обидва: товстий темний контур кольору кнопки, темніша «губа» знизу, без заокруглень.
Пише buttons_v2.html (усі кольори, формати: широка кнопка, квадратна іконка, чип) і svg/*.svg для рендеру PNG.
"""
import base64, pathlib

HERE = pathlib.Path(__file__).parent
UI = pathlib.Path('/tmp/claude-0/-home-claude/8add1236-f2d8-59ff-a5ae-4d35d196baed/scratchpad/ui')
F = UI / 'node_modules/@fontsource/montserrat/files'
f900 = base64.b64encode((F / 'montserrat-latin-900-normal.woff2').read_bytes()).decode()
INK = '#14161a'


def mix(a, b, t):
    a = [int(a[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(b[i:i + 2], 16) for i in (1, 3, 5)]
    return '#' + ''.join(f'{round(x + (y - x) * t):02x}' for x, y in zip(a, b))
def dark(c, k): return mix(c, '#000000', k)
def light(c, k): return mix(c, '#ffffff', k)

# ---------- палітри ----------
# A: top, bottom, border (світла внутрішня рамка), outline, line (світла лінія над губою), lip
PAL = {
    'green':  dict(top='#f6ff14', bottom='#6aec1c', border='#1fd02a', outline='#0c3812', line='#f6ff3c', lip='#1fc12a'),
    'red':    dict(top='#ff8a9a', bottom='#ff1f46', border='#ff3a58', outline='#3d0a12', line='#ffc4cc', lip='#cc0a2a'),
    'orange': dict(top='#ffd81f', bottom='#ff9614', border='#ffb31a', outline='#3a240c', line='#fff06a', lip='#c96d0f'),
    'yellow': dict(top='#fff7a8', bottom='#ffcc12', border='#ffe24a', outline='#3d3008', line='#fffbd6', lip='#d39a0a'),
    'cyan':   dict(top='#f2ffff', bottom='#58e0ff', border='#8eefff', outline='#0b3a44', line='#ffffff', lip='#14a6c0'),
    'blue':   dict(top='#a6deff', bottom='#2f8ee6', border='#5fb8ff', outline='#0b2a55', line='#d4f0ff', lip='#1a5cb0'),
    'purple': dict(top='#b99cff', bottom='#6a2cff', border='#a35cff', outline='#24104f', line='#dccbff', lip='#4a17c0'),
    'pink':   dict(top='#ffb4da', bottom='#ff4fa8', border='#ff7ac0', outline='#4a0b2c', line='#ffe2f1', lip='#c81f78'),
    'gray':   dict(top='#f1f2f4', bottom='#a9adb2', border='#cdd0d4', outline='#2a2d31', line='#fafbfc', lip='#7f8388'),
}
ROLE = {  # для чого колір у грі
    'green': 'купити / дія доступна', 'red': 'закрити / небезпечна дія', 'orange': 'місткість, запас',
    'yellow': 'нагорода, золото', 'cyan': 'швидкість, час (світла)', 'blue': 'швидкість, інформація',
    'purple': 'особливе, рідкісне', 'pink': 'бонус, подія', 'gray': 'недоступно / службова',
}

_uid = [0]
def uid(p):
    _uid[0] += 1
    return f'{p}{_uid[0]}'


def pattern_a(pid, cell, col, x0=0, y0=0, k=1.0):
    """Візерунок стилю A: шахівниця з «квадратика» (тонований, світлий верх-ліво) і «L» (тінь ліво-низ)."""
    s = cell * 0.48
    o = (cell - s) / 2
    sq = (f'<rect x="{o:.1f}" y="{o:.1f}" width="{s:.1f}" height="{s:.1f}" fill="{dark(col, .32)}" opacity="{.22 * k:.3f}"/>'
          f'<path d="M{o:.1f},{o + s:.1f} V{o:.1f} H{o + s:.1f}" fill="none" stroke="#ffffff" stroke-width="{cell * .07:.1f}" opacity="{.35 * k:.3f}"/>'
          f'<path d="M{o + s:.1f},{o:.1f} V{o + s:.1f} H{o:.1f}" fill="none" stroke="{dark(col, .45)}" stroke-width="{cell * .07:.1f}" opacity="{.45 * k:.3f}"/>')
    L = (f'<path d="M{o:.1f},{o:.1f} V{o + s:.1f} H{o + s:.1f}" fill="none" stroke="{dark(col, .45)}" stroke-width="{cell * .085:.1f}" '
         f'stroke-linecap="square" opacity="{.42 * k:.3f}"/>')
    t = cell * 2
    return (f'<pattern id="{pid}" x="{x0:.1f}" y="{y0:.1f}" width="{t}" height="{t}" patternUnits="userSpaceOnUse">'
            f'<g>{L}</g><g transform="translate({cell},0)">{sq}</g>'
            f'<g transform="translate(0,{cell})">{sq}</g><g transform="translate({cell},{cell})">{L}</g></pattern>')


def pattern_b(pid, cell, col, x0=0, y0=0):
    """Візерунок стилю B: порожні квадратики в шаховому порядку — темний і світлий."""
    s = cell * 0.5
    o = (cell - s) / 2
    sw = cell * 0.085
    d = f'<rect x="{o:.1f}" y="{o:.1f}" width="{s:.1f}" height="{s:.1f}" fill="none" stroke="{dark(col, .38)}" stroke-width="{sw:.1f}" opacity=".55"/>'
    l = f'<rect x="{o:.1f}" y="{o:.1f}" width="{s:.1f}" height="{s:.1f}" fill="none" stroke="{light(col, .65)}" stroke-width="{sw:.1f}" opacity=".55"/>'
    t = cell * 2
    return (f'<pattern id="{pid}" x="{x0:.1f}" y="{y0:.1f}" width="{t}" height="{t}" patternUnits="userSpaceOnUse">'
            f'<g>{d}</g><g transform="translate({cell},0)">{l}</g>'
            f'<g transform="translate(0,{cell})">{l}</g><g transform="translate({cell},{cell})">{d}</g></pattern>')


def button(style, color, w, h, label=None, icon=None, size=None, pk=1.0, pal=None, image=None, rows=None):
    """Одна кнопка w×h (координати 0..w, 0..h). Повертає (defs, body)."""
    p = pal or PAL[color]
    O = max(3, round(h * 0.04))            # темний контур
    B = max(2, round(h * 0.028))           # світла внутрішня рамка
    L = max(6, round(h * 0.12))            # губа
    LN = max(2, round(h * 0.035))          # світла лінія над губою
    fx, fy = O + B, O + B
    fw, fh = w - 2 * (O + B), h - O - B - L - LN - O * 0  # грань
    fh = h - O - L - LN - fy
    cell = fh / (rows or (4 if h >= 70 else 3))
    xoff = fx + (fw % cell) / 2
    g, pat, clip, glow = uid('g'), uid('p'), uid('c'), uid('f')
    defs = [f'<clipPath id="{clip}"><rect x="{fx}" y="{fy}" width="{fw}" height="{fh}"/></clipPath>']
    o = [f'<rect x="0" y="0" width="{w}" height="{h}" fill="{p["outline"]}"/>']
    if style == 'A':
        defs.append(f'<linearGradient id="{g}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{p["top"]}"/>'
                    f'<stop offset=".55" stop-color="{mix(p["top"], p["bottom"], .62)}"/><stop offset="1" stop-color="{p["bottom"]}"/></linearGradient>')
        defs.append(pattern_a(pat, cell, mix(p['top'], p['bottom'], .5), xoff, fy, pk))
        o.append(f'<rect x="{O}" y="{O}" width="{w - 2 * O}" height="{h - 2 * O}" fill="{p["border"]}"/>')
        o.append(f'<rect x="{fx}" y="{fy}" width="{fw}" height="{fh}" fill="url(#{g})"/>')
        o.append(f'<g clip-path="url(#{clip})"><rect x="{fx}" y="{fy}" width="{fw}" height="{fh}" fill="url(#{pat})"/></g>')
        # м'яке світло по центру зверху
        defs.append(f'<radialGradient id="{glow}" cx=".5" cy=".18" r=".7"><stop offset="0" stop-color="#ffffff" stop-opacity=".28"/>'
                    f'<stop offset="1" stop-color="#ffffff" stop-opacity="0"/></radialGradient>')
        o.append(f'<rect x="{fx}" y="{fy}" width="{fw}" height="{fh}" fill="url(#{glow})"/>')
    else:
        center = p['bottom']
        edge = light(p['top'], .15)
        defs.append(f'<radialGradient id="{g}" cx=".5" cy=".5" r=".75" gradientTransform="translate(0 0) scale(1 1)">'
                    f'<stop offset="0" stop-color="{center}"/><stop offset=".55" stop-color="{mix(center, edge, .18)}"/>'
                    f'<stop offset="1" stop-color="{edge}"/></radialGradient>')
        defs.append(pattern_b(pat, cell, center, xoff, fy))
        defs.append(f'<filter id="{glow}" x="-10%" y="-10%" width="120%" height="120%"><feGaussianBlur stdDeviation="{max(2, h * .05):.1f}"/></filter>')
        o.append(f'<rect x="{O}" y="{O}" width="{w - 2 * O}" height="{h - 2 * O}" fill="{p["border"]}"/>')
        o.append(f'<rect x="{fx}" y="{fy}" width="{fw}" height="{fh}" fill="url(#{g})"/>')
        o.append(f'<g clip-path="url(#{clip})">'
                 f'<rect x="{fx}" y="{fy}" width="{fw}" height="{fh}" fill="url(#{pat})"/>'
                 f'<rect x="{fx}" y="{fy}" width="{fw}" height="{fh}" fill="none" stroke="{light(center, .55)}" stroke-width="{h * .2:.1f}" opacity=".55" filter="url(#{glow})"/>'
                 f'</g>')
    # світла лінія над губою і губа
    o.append(f'<rect x="{fx}" y="{fy + fh}" width="{fw}" height="{LN}" fill="{p["line"]}" opacity=".75"/>')  # світла лінія над губою — на 25 % прозоріша
    o.append(f'<rect x="{O}" y="{h - O - L}" width="{w - 2 * O}" height="{L}" fill="{p["lip"]}"/>')
    cy = fy + fh / 2
    if image:
        m = fh * 0.06
        o.append(f'<image href="{image}" x="{fx + m:.1f}" y="{fy + m:.1f}" width="{fw - 2 * m:.1f}" height="{fh - 2 * m:.1f}"/>')
    if label:
        fs = size or round(fh * 0.52)
        o.append(f'<text x="{w / 2}" y="{cy + fs * .36:.1f}" font-family="Montserrat" font-weight="900" font-size="{fs}" text-anchor="middle" '
                 f'fill="#fff" stroke="{INK}" stroke-width="{fs * .16:.1f}" stroke-linejoin="round" paint-order="stroke fill">{label}</text>')
    if icon == 'x':
        r = fh * 0.30
        cx = w / 2
        for sw, col in ((fh * .26, INK), (fh * .15, '#ffffff')):
            o.append(f'<path d="M{cx - r:.1f},{cy - r:.1f} L{cx + r:.1f},{cy + r:.1f} M{cx + r:.1f},{cy - r:.1f} L{cx - r:.1f},{cy + r:.1f}" '
                     f'stroke="{col}" stroke-width="{sw:.1f}" stroke-linecap="square"/>')
    return ''.join(defs), ''.join(o)


def svg(style, color, w, h, **kw):
    d, b = button(style, color, w, h, **kw)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
            f'<defs><style>@font-face{{font-family:Montserrat;font-weight:900;src:url(data:font/woff2;base64,{f900}) format("woff2")}}</style>{d}</defs>{b}</svg>')


def inline(style, color, w, h, scale=1.0, **kw):
    d, b = button(style, color, w, h, **kw)
    return f'<svg width="{w * scale:.0f}" height="{h * scale:.0f}" viewBox="0 0 {w} {h}" style="display:block"><defs>{d}</defs>{b}</svg>'


COLORS = ['green', 'red', 'orange', 'yellow', 'cyan', 'blue', 'purple', 'pink', 'gray']
LABELS = {'green': 'Give Ore', 'red': 'Sell All', 'orange': 'Put Ore', 'yellow': 'Claim', 'cyan': 'Speed',
          'blue': 'Info', 'purple': 'Special', 'pink': 'Bonus', 'gray': 'MAX'}


def section(style, title, note):
    rows = []
    for c in COLORS:
        rows.append(f'<div class="row"><div class="cap"><b>{c}</b><span>{ROLE[c]}</span></div>'
                    f'{inline(style, c, 400, 100, 0.9, label=LABELS[c])}'
                    f'{inline(style, c, 100, 100, 0.9, icon="x")}'
                    f'{inline(style, c, 240, 56, 0.9, label=c.upper(), size=24)}</div>')
    return f'<h2>{title}</h2><p>{note}</p><div class="grid">{"".join(rows)}</div>'


ref_a = base64.b64encode((HERE / 'ref_green_zoom.png').read_bytes()).decode()
ref_b = base64.b64encode((HERE / 'ref_red_zoom.png').read_bytes()).decode()
cmp = (f'<div class="cmp"><div><img src="data:image/png;base64,{ref_a}"><span>референс — зелена</span></div>'
       f'<div>{inline("A", "green", 550, 175, 1.0)}<span>наша — стиль A</span></div></div>'
       f'<div class="cmp"><div><img src="data:image/png;base64,{ref_b}"><span>референс — червона</span></div>'
       f'<div>{inline("B", "red", 550, 175, 1.0)}<span>наша — стиль B</span></div></div>')

html = f'''<!doctype html><html lang="uk"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Кнопки v2</title><style>
@font-face{{font-family:Montserrat;font-weight:900;src:url(data:font/woff2;base64,{f900}) format('woff2')}}
body{{margin:0;background:#3b3f45;color:#e8edf2;font-family:system-ui,sans-serif}}
.wrap{{max-width:1180px;margin:0 auto;padding:24px 16px 60px}}
h1{{font-size:22px;color:#ffd34d;margin:0 0 6px}} h2{{font-size:18px;margin:34px 0 6px;color:#fff}}
p{{color:#c3cbd4;font-size:14px;line-height:1.5;margin:0 0 12px}}
.cmp{{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin:10px 0}}
.cmp img,.cmp svg{{width:100%;height:auto}} .cmp span{{display:block;text-align:center;font-size:13px;color:#c3cbd4;margin-top:4px}}
.grid{{display:flex;flex-direction:column;gap:14px}}
.row{{display:flex;align-items:center;gap:18px;flex-wrap:wrap;background:#2e3237;padding:12px;border:2px solid #23262a}}
.cap{{width:150px;display:flex;flex-direction:column}} .cap b{{font-size:15px}} .cap span{{font-size:12px;color:#aab3bd}}
@media (max-width:700px){{.cmp{{grid-template-columns:1fr}} .cap{{width:100%}}}}
</style></head><body><div class="wrap">
<h1>Кнопки v2 — за референсами</h1>
<p>Дві основи з твого набору: <b>A — як зелена</b> (вертикальний градієнт, світла внутрішня рамка, світла лінія над губою, візерунок «квадратик + L») і <b>B — як червона</b> (насичений центр, світле сяйво по краях, візерунок з порожніх квадратиків темний/світлий). Обидві: товстий темний контур у колір кнопки, темніша губа знизу, без заокруглень. Нижче — порівняння з референсом і всі кольори у трьох форматах: широка кнопка, квадратна кнопка-іконка (X), чип.</p>
{cmp}
{section('A', 'Стиль A — як зелена', 'Для всіх кольорів: верх світлий, низ насичений; візерунок тоном темніший.')}
{section('B', 'Стиль B — як червона', 'Центр насичений, краї світліші (м’яке сяйво зсередини), квадратики темні й світлі по черзі.')}
</div></body></html>'''
out = HERE / 'buttons_v2.html'
out.write_text(html, encoding='utf-8')
print(out, len(html))
