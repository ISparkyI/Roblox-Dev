"""Forge Upgrades — іконки Capacity і Speed у стилі іконок Roll Upgrades + веб-прев'ю на таблі кузні."""
import base64, pathlib, math

HERE = pathlib.Path(__file__).parent
F = HERE / 'node_modules/@fontsource/montserrat/files'
f800 = base64.b64encode((F / 'montserrat-latin-800-normal.woff2').read_bytes()).decode()
f900 = base64.b64encode((F / 'montserrat-latin-900-normal.woff2').read_bytes()).decode()
INK = '#14161a'
OUT = pathlib.Path('/mnt/user-data/outputs/ui/forge_icons'); OUT.mkdir(parents=True, exist_ok=True)

def P(pts): return ' '.join(f'{x:.1f},{y:.1f}' for x, y in pts)
def iso(x, y, z, s=1.0, ox=0, oy=0):
    return (ox + (x - z) * 0.866 * s, oy + ((x + z) * 0.5 - y) * s)

def sparkle(x, y, r, op=1):
    k = r * 0.28
    return (f'<path d="M{x},{y-r} Q{x+k},{y-k} {x+r},{y} Q{x+k},{y+k} {x},{y+r} Q{x-k},{y+k} {x-r},{y} Q{x-k},{y-k} {x},{y-r}Z" '
            f'fill="#fff" opacity="{op}"/>')

DEFS = '''
<linearGradient id="woodTop" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#d99a5b"/><stop offset="1" stop-color="#b8743a"/></linearGradient>
<linearGradient id="woodL" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#b06a33"/><stop offset="1" stop-color="#8a4f24"/></linearGradient>
<linearGradient id="woodR" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8c5228"/><stop offset="1" stop-color="#6a3b1a"/></linearGradient>
<linearGradient id="limeB" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#c8ff5a"/><stop offset=".5" stop-color="#6fe01a"/><stop offset="1" stop-color="#2f9a0a"/></linearGradient>
<linearGradient id="amberB" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffe27a"/><stop offset=".5" stop-color="#ffb21e"/><stop offset="1" stop-color="#e07a06"/></linearGradient>
<linearGradient id="steel" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e3e7ec"/><stop offset=".5" stop-color="#a9b0b9"/><stop offset="1" stop-color="#6f7782"/></linearGradient>
<linearGradient id="steelSide" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7d858f"/><stop offset="1" stop-color="#555c66"/></linearGradient>
<linearGradient id="handle" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#c98a4e"/><stop offset=".55" stop-color="#9c5f2c"/><stop offset="1" stop-color="#6e3f1b"/></linearGradient>
<linearGradient id="hot" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff3b0"/><stop offset=".45" stop-color="#ffb43a"/><stop offset="1" stop-color="#ff6a1a"/></linearGradient>
'''

# ---------- Capacity: ящик з горою руди + лаймова стрілка вгору ----------
ORE = {  # top, left, right
    'copper': ('#f2995a', '#d06a2c', '#a9501d'),
    'iron':   ('#eef0f3', '#c3c8cf', '#9aa1aa'),
    'stone':  ('#a7aeb6', '#858c95', '#676e77'),
    'crystal':('#9df0fa', '#4fc6db', '#2e9db3'),
}
def cube(cx, cy, cz, a, kind, s, ox, oy, rot=0):
    """ізометричний кубик зі стороною a (центр низу в cx,cy,cz)"""
    t, l, r = ORE[kind]
    h = a / 2
    def V(x, y, z): return iso(cx + x, cy + y, cz + z, s, ox, oy)
    top = [V(-h, a, -h), V(h, a, -h), V(h, a, h), V(-h, a, h)]
    left = [V(-h, a, h), V(h, a, h), V(h, 0, h), V(-h, 0, h)]
    right = [V(h, a, -h), V(h, a, h), V(h, 0, h), V(h, 0, -h)]
    sil = [V(-h, a, -h), V(h, a, -h), V(h, 0, -h), V(h, 0, h), V(-h, 0, h), V(-h, a, h)]
    g = f'<polygon points="{P(sil)}" fill="{INK}" stroke="{INK}" stroke-width="{9*s:.1f}" stroke-linejoin="round"/>'
    g += f'<polygon points="{P(left)}" fill="{l}"/><polygon points="{P(right)}" fill="{r}"/><polygon points="{P(top)}" fill="{t}"/>'
    # відблиск на верхній грані
    hl = [V(-h * .6, a, -h * .6), V(-h * .05, a, -h * .6), V(-h * .6, a, -h * .05)]
    g += f'<polygon points="{P(hl)}" fill="#fff" opacity=".45"/>'
    return g

def capacity_icon():
    s, ox, oy = 1.0, 0, 60
    W2, H2 = 110, 110       # півширина ящика, висота
    def V(x, y, z): return iso(x, y, z, s, ox, oy)
    out = []
    # силует-обведення ящика
    sil = [V(-W2, H2, -W2), V(W2, H2, -W2), V(W2, 0, -W2), V(W2, 0, W2), V(-W2, 0, W2), V(-W2, H2, W2)]
    out.append(f'<polygon points="{P(sil)}" fill="{INK}" stroke="{INK}" stroke-width="22" stroke-linejoin="round"/>')
    left = [V(-W2, H2, W2), V(W2, H2, W2), V(W2, 0, W2), V(-W2, 0, W2)]
    right = [V(W2, H2, -W2), V(W2, H2, W2), V(W2, 0, W2), V(W2, 0, -W2)]
    out.append(f'<polygon points="{P(left)}" fill="url(#woodL)"/><polygon points="{P(right)}" fill="url(#woodR)"/>')
    # дошки: горизонтальні шви
    for k in (1, 2):
        yy = H2 * k / 3
        out.append(f'<polyline points="{P([V(-W2, yy, W2), V(W2, yy, W2), V(W2, yy, -W2)])}" fill="none" stroke="{INK}" stroke-width="5" opacity=".55"/>')
    # кутові бруси (світлі ребра)
    for (a, b) in ((V(W2, 4, W2), V(W2, H2 - 4, W2)), (V(-W2 + 4, 4, W2), V(-W2 + 4, H2 - 4, W2)), (V(W2, 4, -W2 + 4), V(W2, H2 - 4, -W2 + 4))):
        out.append(f'<line x1="{a[0]:.1f}" y1="{a[1]:.1f}" x2="{b[0]:.1f}" y2="{b[1]:.1f}" stroke="#e7b07a" stroke-width="7" stroke-linecap="round" opacity=".8"/>')
    # верх ящика (внутрішній бортик)
    rim = [V(-W2, H2, -W2), V(W2, H2, -W2), V(W2, H2, W2), V(-W2, H2, W2)]
    out.append(f'<polygon points="{P(rim)}" fill="url(#woodTop)"/>')
    inner = [V(-W2 + 16, H2, -W2 + 16), V(W2 - 16, H2, -W2 + 16), V(W2 - 16, H2, W2 - 16), V(-W2 + 16, H2, W2 - 16)]
    out.append(f'<polygon points="{P(inner)}" fill="#3a2414"/>')
    # гора руди (від дальніх до ближніх)
    A = 56
    y1, y2, y3 = H2 - 30, H2 + 18, H2 + 66
    pile = [
        (-58, y1, -58, 'stone'), (0, y1, -62, 'iron'), (58, y1, -52, 'copper'),
        (-62, y1, 0, 'copper'), (0, y1, 0, 'stone'), (60, y1, 4, 'stone'),
        (-55, y1, 58, 'iron'), (2, y1, 60, 'crystal'), (58, y1, 58, 'copper'),
        (-30, y2, -28, 'iron'), (30, y2, -24, 'crystal'), (-26, y2, 30, 'stone'), (32, y2, 32, 'copper'),
        (2, y3, 2, 'copper'),
    ]
    pile.sort(key=lambda c: (c[1], c[0] + c[2]))
    for cx, cy, cz, kind in pile:
        out.append(cube(cx, cy, cz, A, kind, s, ox, oy))
    # лаймова стрілка вгору (більше руди)
    bx, by = 150, -150
    out.append(f'<g transform="translate({bx},{by})"><circle r="58" fill="{INK}"/><circle r="47" fill="url(#limeB)"/>'
               '<ellipse cx="-8" cy="-22" rx="26" ry="11" fill="#fff" opacity=".35"/>'
               f'<path d="M0,-30 L28,2 L11,2 L11,30 L-11,30 L-11,2 L-28,2 Z" fill="#fff" stroke="{INK}" stroke-width="7" stroke-linejoin="round" paint-order="stroke"/></g>')
    out.append(sparkle(-170, -40, 26)); out.append(sparkle(-130, -95, 13, .8))
    return ''.join(out)

# ---------- Speed: молот у русі + бурштиновий значок-блискавка ----------
def speed_icon():
    out = []
    # лінії руху (за молотом)
    # дуги руху замаху (зліва від голови молота)
    for (x0, y0, x1, y1, cx, cy) in ((-190, -120, -150, -15, -190, -65), (-160, -175, -100, -65, -165, -115), (-205, -50, -180, 30, -212, -8)):
        d = f'M{x0},{y0} Q{cx},{cy} {x1},{y1}'
        out.append(f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="26" stroke-linecap="round"/>')
        out.append(f'<path d="{d}" fill="none" stroke="#ffffff" stroke-width="12" stroke-linecap="round"/>')
    g = ['<g transform="rotate(-35)">']
    # ручка
    g.append(f'<rect x="-22" y="-40" width="44" height="230" rx="20" fill="{INK}" stroke="{INK}" stroke-width="20" stroke-linejoin="round"/>')
    g.append('<rect x="-22" y="-40" width="44" height="230" rx="20" fill="url(#handle)"/>')
    g.append('<rect x="-12" y="-30" width="9" height="200" rx="4" fill="#e9b47e" opacity=".65"/>')
    for yy in (120, 145, 170):  # обмотка
        g.append(f'<rect x="-24" y="{yy}" width="48" height="12" rx="6" fill="#4a2c14" opacity=".75"/>')
    # голова молота
    g.append(f'<rect x="-120" y="-150" width="240" height="120" rx="22" fill="{INK}" stroke="{INK}" stroke-width="22" stroke-linejoin="round"/>')
    g.append('<rect x="-120" y="-150" width="240" height="120" rx="22" fill="url(#steel)"/>')
    g.append('<rect x="-120" y="-150" width="40" height="120" rx="14" fill="url(#steelSide)"/>')
    g.append('<rect x="80" y="-150" width="40" height="120" rx="14" fill="url(#hot)"/>')  # розжарений бік (удар)
    g.append('<rect x="-62" y="-138" width="150" height="20" rx="10" fill="#fff" opacity=".55"/>')
    g.append(f'<rect x="-34" y="-150" width="68" height="120" fill="none" stroke="{INK}" stroke-width="6" opacity=".35"/>')
    g.append('</g>')
    out.append(''.join(g))
    # іскри біля розжареного боку
    for (x, y, r) in ((60, -200, 14), (100, -175, 10), (35, -225, 8)):
        out.append(f'<circle cx="{x}" cy="{y}" r="{r+5}" fill="{INK}"/><circle cx="{x}" cy="{y}" r="{r}" fill="#ffd34d"/>')
    # бурштиновий значок-блискавка
    bx, by = 150, 120
    out.append(f'<g transform="translate({bx},{by})"><circle r="58" fill="{INK}"/><circle r="47" fill="url(#amberB)"/>'
               '<ellipse cx="-8" cy="-22" rx="26" ry="11" fill="#fff" opacity=".35"/>'
               f'<path d="M8,-34 L-20,6 L-2,6 L-10,34 L20,-8 L2,-8 Z" fill="#fff" stroke="{INK}" stroke-width="7" stroke-linejoin="round" paint-order="stroke"/></g>')
    out.append(sparkle(-60, -205, 24)); out.append(sparkle(-15, -215, 12, .8))
    return ''.join(out)

def svg(body, vb='-240 -240 480 480', w=None, h=None):
    size = f' width="{w}" height="{h}"' if w else ''
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}"{size}><defs>{DEFS}</defs>{body}</svg>'

ICONS = {'forge_capacity': capacity_icon(), 'forge_speed': speed_icon()}
for n, b in ICONS.items():
    (OUT / f'{n}.svg').write_text(svg(b), encoding='utf-8')

# ---------- веб-прев'ю ----------
def studs_bg(pid, cell, base, stud, shade):
    s = cell * 0.62; o = (cell - s) / 2; d = 3
    return (f'<pattern id="{pid}" width="{cell}" height="{cell}" patternUnits="userSpaceOnUse"><rect width="{cell}" height="{cell}" fill="{base}"/>'
            f'<rect x="{o-d/2}" y="{o+d/2}" width="{s}" height="{s}" rx="5" fill="{shade}"/><rect x="{o+d/2}" y="{o-d/2}" width="{s}" height="{s}" rx="5" fill="{stud}"/></pattern>')

def panel(with_icons=True):
    # мок табла кузні: 800 × 620 (пропорції 16 × 12.5)
    W, H = 800, 625
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" style="width:100%;height:auto;display:block"><defs>{DEFS}{studs_bg("beige", 40, "#e5c496", "#ecd0a6", "#c9a777")}</defs>']
    o.append(f'<rect width="{W}" height="{H}" fill="url(#beige)"/>')
    o.append(f'<text x="{W/2}" y="88" text-anchor="middle" font-family="Montserrat" font-weight="900" font-size="56" fill="#4a2c14">FORGE UPGRADES</text>')
    rows = [('Capacity', 'Lv 2', '$600 → $900 of ore', '$400', 'forge_capacity'), ('Speed', 'Lv 2', '2.75s → 2.50s / ore', '$340', 'forge_speed')]
    for i, (t, lv, val, price, ic) in enumerate(rows):
        y = 130 + i * 205
        o.append(f'<rect x="40" y="{y}" width="{W-80}" height="180" rx="22" fill="#f3dcae" stroke="#9c6b3a" stroke-width="5"/>')
        x0 = 60
        if with_icons:
            o.append(f'<svg x="50" y="{y+5}" width="170" height="170" viewBox="-240 -240 480 480">{ICONS[ic]}</svg>')
            x0 = 230
        k = 0.8 if with_icons else 1
        o.append(f'<text x="{x0}" y="{y+68}" font-family="Montserrat" font-weight="900" font-size="{46*k}" fill="#4a2c14">{t}</text>')
        o.append(f'<text x="{x0+ (250 if t=="Capacity" else 170)*k}" y="{y+66}" font-family="Montserrat" font-weight="800" font-size="{26*k}" fill="#7a5530">{lv}</text>')
        o.append(f'<text x="{x0}" y="{y+128}" font-family="Montserrat" font-weight="800" font-size="{34*k}" fill="#4a2c14">{val}</text>')
        o.append(f'<rect x="{W-245}" y="{y+45}" width="175" height="90" rx="20" fill="#8a8a7e" stroke="#4a2c14" stroke-width="5"/>')
        o.append(f'<text x="{W-157}" y="{y+104}" text-anchor="middle" font-family="Montserrat" font-weight="900" font-size="40" fill="#fff" stroke="#4a2c14" stroke-width="7" paint-order="stroke">{price}</text>')
    o.append(f'<text x="{W/2}" y="{H-30}" text-anchor="middle" font-family="Montserrat" font-weight="800" font-size="24" fill="#7a5530">Your money: $50</text>')
    o.append('</svg>')
    return ''.join(o)

def tile(name, label, bg):
    return (f'<figure><div class="tile" style="background:{bg}">{svg(ICONS[name], w=None)}</div><figcaption>{label}</figcaption></figure>')

html = f'''<!doctype html><html lang="uk"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Forge Upgrades — іконки</title>
<style>
@font-face {{ font-family: Montserrat; font-weight: 800; src: url(data:font/woff2;base64,{f800}) format('woff2'); }}
@font-face {{ font-family: Montserrat; font-weight: 900; src: url(data:font/woff2;base64,{f900}) format('woff2'); }}
body{{margin:0;background:#20242a;color:#e8edf2;font-family:system-ui,sans-serif}}
.wrap{{max-width:1180px;margin:0 auto;padding:24px 16px 48px}}
h1{{font-size:20px;color:#ffd34d;margin:0 0 6px}} h2{{font-size:16px;margin:28px 0 10px;color:#c9d2dc}}
p{{color:#b9c2cc;font-size:14px;line-height:1.5;margin:0 0 10px}}
.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:16px}}
figure{{margin:0}} figcaption{{font-size:13px;color:#b9c2cc;margin-top:6px;text-align:center}}
.tile{{border-radius:18px;padding:14px;box-shadow:0 8px 24px rgba(0,0,0,.35)}} .tile svg{{width:100%;height:auto;display:block}}
.panels{{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:20px}}
.panel{{border:14px solid #5a3a22;border-radius:12px;box-shadow:0 10px 30px rgba(0,0,0,.4)}}
</style></head><body><div class="wrap">
<h1>Forge Upgrades — іконки (вектор)</h1>
<p>Той самий стиль, що конюшина й підставка Roll Upgrades: товстий темний контур, соковиті градієнти, світлий блиск, іскорки й круглий значок-бейдж. Після «переносимо» рендеримо PNG 512 px з прозорим фоном і ставимо на табло кузні.</p>
<h2>Іконки на різних фонах</h2>
<div class="grid">
{tile('forge_capacity', 'Capacity — ящик, повний руди, + стрілка вгору', '#e5c496')}
{tile('forge_speed', 'Speed — молот у русі, розжарений бік, + блискавка', '#e5c496')}
{tile('forge_capacity', 'на темному', '#2b3038')}
{tile('forge_speed', 'на темному', '#2b3038')}
</div>
<h2>Як виглядатиме на таблі кузні</h2>
<div class="panels"><div><div class="panel">{panel(True)}</div><p style="text-align:center;margin-top:8px">з іконками</p></div>
<div><div class="panel">{panel(False)}</div><p style="text-align:center;margin-top:8px">зараз</p></div></div>
</div></body></html>'''
(OUT / 'forge_upgrades_icons.html').write_text(html, encoding='utf-8')
print('ok')
