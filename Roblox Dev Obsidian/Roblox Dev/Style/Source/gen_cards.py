"""Картки — задні фони в нашому стилі (як зараз у грі) у всіх кольорах тем, з кнопками стилю A.
Картка: тінь, градієнт теми, ледь помітні studs, три косі смуги світла, прямокутна смуга блиску, обідок,
темна нижня планка, іконка, назва, «зараз › далі», кнопка стилю A. Плюс широка плашка (рядок списку / магазину).
Пише cards_v2.html.
"""
import base64, pathlib, importlib.util

HERE = pathlib.Path(__file__).parent
spec = importlib.util.spec_from_file_location('gb', HERE / 'gen_buttons.py')
gb = importlib.util.module_from_spec(spec); spec.loader.exec_module(gb)
INK, mix, dark, light, f900 = gb.INK, gb.mix, gb.dark, gb.light, gb.f900

# теми карток: світлий / основний / темний, rim, stud, studShade (з GDD) + 4 нові за правилом GDD
THEMES = {
    'green':  ('#a6e862', '#6cc934', '#3f9d18', '#d6ff9e', '#b6f07a', '#3f9a19'),
    'red':    ('#ff6f66', '#e2322f', '#a8161b', '#ffb0a8', '#ff8f86', '#a3161b'),
    'orange': ('#ffb15c', '#f07a1e', '#b8500c', '#ffd2a3', '#ffc890', '#b3520f'),
    'blue':   ('#6fc6ff', '#2f8ee6', '#1a5cb0', '#bfe6ff', '#8fd2ff', '#1b62b8'),
    'purple': ('#b98cff', '#7a3cf0', '#4a1ab0', '#dcc6ff', '#c9a6ff', '#4a1aa8'),
    'yellow': ('#ffe26a', '#f7b812', '#b9800a', '#fff1b0', '#ffe68a', '#b37a08'),
    'cyan':   ('#8ff0ff', '#22c6e0', '#0d8aa3', '#c8f8ff', '#a6f2ff', '#0d84a0'),
    'pink':   ('#ff9ccc', '#ec3f96', '#a81862', '#ffc8e2', '#ffb0d6', '#a3175e'),
}
ICON = {
    'green': '/mnt/user-data/outputs/ui/icons/clover.png', 'red': '/mnt/user-data/outputs/ui/icons/roll_stand.png',
    'orange': '/mnt/user-data/outputs/ui/forge_icons/forge_capacity.png', 'blue': '/mnt/user-data/outputs/ui/forge_icons/forge_speed.png',
}
_b64 = {}
def icon_href(c):
    p = ICON.get(c)
    if not p: return None
    if p not in _b64: _b64[p] = base64.b64encode(pathlib.Path(p).read_bytes()).decode()
    return 'data:image/png;base64,' + _b64[p]

TITLES = {'green': ('Roll Luck', '5%', '10%', '$1,000'), 'red': ('Roll Stands', '1', '2', '$500'),
          'orange': ('Capacity', '$300', '$600', '$250'), 'blue': ('Speed', '3.00s', '2.75s', '$200'),
          'purple': ('Rare Drop', '1%', '2%', '$5,000'), 'yellow': ('Gold Bonus', 'x1', 'x2', '$2,500'),
          'cyan': ('Golem Speed', '1.0', '1.2', '$800'), 'pink': ('Event Boost', '0%', '5%', '$1,200')}
BANDS = [(0, 1), (.16, 1), (.17, .82), (.31, .82), (.32, 1), (.47, 1), (.48, .9), (.53, .9), (.54, 1),
         (.70, 1), (.71, .85), (.83, .85), (.84, 1), (1, 1)]

_u = [0]
def uid(p):
    _u[0] += 1
    return f'{p}{_u[0]}'

def txt(x, y, s, size, fill='#fff', sw=None, anchor='middle'):
    sw = sw if sw is not None else size * .16
    return (f'<text x="{x}" y="{y}" font-family="Montserrat" font-weight="900" font-size="{size}" text-anchor="{anchor}" fill="{fill}" '
            f'stroke="{INK}" stroke-width="{sw:.1f}" stroke-linejoin="round" paint-order="stroke fill">{s}</text>')

def back(w, h, theme, bands_k=1.0, strip=None):
    """Задній фон картки w×h. Повертає (defs, body) у координатах 0..w, 0..h."""
    lt, base, dk, rim, stud, studShade = THEMES[theme]
    g, sp, bd, gl, cl = uid('g'), uid('s'), uid('b'), uid('l'), uid('c')
    cell = 46
    s_ = cell * .6; o_ = (cell - s_) / 2
    defs = [f'<linearGradient id="{g}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{lt}"/><stop offset=".55" stop-color="{base}"/><stop offset="1" stop-color="{dk}"/></linearGradient>',
            f'<pattern id="{sp}" x="10" y="10" width="{cell}" height="{cell}" patternUnits="userSpaceOnUse">'
            f'<rect x="{o_ - 2:.1f}" y="{o_ + 2:.1f}" width="{s_:.1f}" height="{s_:.1f}" fill="{studShade}"/>'
            f'<rect x="{o_:.1f}" y="{o_:.1f}" width="{s_:.1f}" height="{s_:.1f}" fill="{stud}"/></pattern>',
            f'<linearGradient id="{bd}" gradientTransform="rotate(65 .5 .5)">' +
            ''.join(f'<stop offset="{a}" stop-color="#fff" stop-opacity="{(1 - t) * bands_k:.3f}"/>' for a, t in BANDS) + '</linearGradient>',
            f'<linearGradient id="{gl}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".32"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>',
            f'<clipPath id="{cl}"><rect x="6" y="6" width="{w - 12}" height="{h - 12}"/></clipPath>']
    sh = strip if strip is not None else max(10, int(h * .03))
    o = [f'<rect x="0" y="14" width="{w}" height="{h}" fill="#000" opacity=".35"/>',
         f'<rect x="0" y="0" width="{w}" height="{h}" fill="url(#{g})"/>',
         f'<g clip-path="url(#{cl})">',
         f'<rect x="10" y="10" width="{w - 20}" height="{h - 20}" fill="url(#{sp})" opacity=".32"/>',
         f'<rect x="6" y="6" width="{w - 12}" height="{h - 12}" fill="url(#{bd})"/>',
         f'<rect x="6" y="6" width="{w - 12}" height="{h * .36:.0f}" fill="url(#{gl})"/>',
         f'<rect x="6" y="{h - 6 - sh}" width="{w - 12}" height="{sh}" fill="{dark(dk, .3)}"/>',
         '</g>',
         f'<rect x="12" y="12" width="{w - 24}" height="{h - 24 - sh}" fill="none" stroke="{rim}" stroke-width="6" opacity=".75"/>',
         f'<rect x="3" y="3" width="{w - 6}" height="{h - 6}" fill="none" stroke="{INK}" stroke-width="6"/>']
    return ''.join(defs), ''.join(o)

def card(theme, affordable=True):
    W, H = 500, 790
    d, b = back(W, H, theme)
    title, cur, nxt, price = TITLES[theme]
    o = [b]
    href = icon_href(theme)
    if href:
        o.append(f'<image href="{href}" x="{W / 2 - 170}" y="70" width="340" height="340"/>')
    else:   # нові кольори — плейсхолдер іконки (іконку малюємо за GDD іконок)
        o.append(f'<rect x="{W / 2 - 120}" y="120" width="240" height="240" fill="#fff" opacity=".18"/>' + txt(W / 2, 262, '?', 120, '#fff', 14))
    o.append(txt(W / 2, 500, title, 66 if len(title) > 10 else 72, '#fff', 12))
    o.append(f'<text x="{W / 2}" y="584" font-family="Montserrat" font-weight="900" font-size="48" text-anchor="middle" stroke="{INK}" stroke-width="10" '
             f'stroke-linejoin="round" paint-order="stroke fill"><tspan fill="#fff">{cur}</tspan><tspan fill="#d4ff3e" dx="12">›</tspan><tspan fill="#d4ff3e" dx="12">{nxt}</tspan></text>')
    bd, bb = gb.button('A', 'green' if affordable else 'gray', 360, 100, label=price, size=44)
    o.append(f'<g transform="translate(70,640)">{bb}</g>')
    return f'<svg viewBox="-4 -4 508 812" style="width:100%;height:auto;display:block"><defs>{d}{bd}</defs>{"".join(o)}</svg>'

def plate(theme, title, desc, price, btn='green'):
    W, H = 980, 230
    d, b = back(W, H, theme, strip=12)
    o = [b]
    href = icon_href(theme)
    if href: o.append(f'<image href="{href}" x="24" y="20" width="190" height="190"/>')
    else: o.append(f'<rect x="44" y="40" width="150" height="150" fill="#fff" opacity=".18"/>')
    o.append(txt(250, 82, title, 50, '#fff', 9, 'start'))
    o.append(f'<text x="250" y="132" font-family="Montserrat" font-weight="900" font-size="28" fill="#fff" stroke="{INK}" stroke-width="6" stroke-linejoin="round" paint-order="stroke fill">{desc}</text>')
    bd, bb = gb.button('A', btn, 230, 84, label=price, size=34)
    o.append(f'<g transform="translate({W - 266},{(H - 84) / 2 - 4:.0f})">{bb}</g>')
    return f'<svg viewBox="-4 -4 988 252" style="width:100%;height:auto;display:block"><defs>{d}{bd}</defs>{"".join(o)}</svg>'

cards = ''.join(f'<div class="c"><div>{card(t, i % 3 != 2)}</div><span>{t}</span></div>' for i, t in enumerate(THEMES))
plates = ''.join(f'<div class="p">{plate(t, TITLES[t][0], "Short upgrade description", TITLES[t][3], "green" if i % 2 == 0 else "gray")}</div>'
                 for i, t in enumerate(['green', 'purple', 'orange', 'cyan']))
html = f'''<!doctype html><html lang="uk"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Картки v2</title><style>
@font-face{{font-family:Montserrat;font-weight:900;src:url(data:font/woff2;base64,{f900}) format('woff2')}}
body{{margin:0;background:#8e939a;color:#14161a;font-family:system-ui,sans-serif}}
.wrap{{max-width:1180px;margin:0 auto;padding:24px 16px 60px}}
h1{{font-size:22px;margin:0 0 6px}} h2{{font-size:18px;margin:30px 0 8px}} p{{font-size:14px;line-height:1.5;margin:0 0 12px;color:#23262b}}
.grid{{display:grid;grid-template-columns:repeat(4,1fr);gap:18px}} .c span{{display:block;text-align:center;font-weight:700;margin-top:6px}}
.plates{{display:flex;flex-direction:column;gap:16px}}
@media (max-width:800px){{.grid{{grid-template-columns:repeat(2,1fr)}}}}
</style></head><body><div class="wrap">
<h1>Картки — задні фони в нашому стилі + кнопки стилю A</h1>
<p>Картки такі, як зараз у грі: квадратні, градієнт теми, ледь помітні studs, три косі смуги світла, прямокутний блиск зверху, світлий обідок і темна нижня планка. Кнопки на них — новий стиль A (зелена — можна купити, сіра — не вистачає грошей). Перші 4 теми — наші (Roll Luck, Roll Stands, Capacity, Speed), ще 4 нові кольори — для майбутніх покращень (замість іконки — заглушка).</p>
<h2>Вертикальні картки</h2><div class="grid">{cards}</div>
<h2>Широкі плашки (рядок списку / магазину)</h2><div class="plates">{plates}</div>
</div></body></html>'''
(HERE / 'cards_v2.html').write_text(html, encoding='utf-8')
print('ok', len(html))
