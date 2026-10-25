"""Стиль A для плиток-іконок (квадратні) і верхніх плашок-чипів: та сама будова, що й кнопки стилю A,
але візерунок studs удвічі слабший (pk = 0.5), щоб не заважав іконці / напису.
Пише tiles_v2.html: плитки руди й злитків, плитки всіх кольорів, чипи, макет рядків вікна кузні.
"""
import base64, pathlib, importlib.util

HERE = pathlib.Path(__file__).parent
spec = importlib.util.spec_from_file_location('gb', HERE / 'gen_buttons.py')
gb = importlib.util.module_from_spec(spec); spec.loader.exec_module(gb)
INK, mix, dark, light, f900 = gb.INK, gb.mix, gb.dark, gb.light, gb.f900
PK = 0.5                       # studs удвічі слабші, ніж на кнопках
ICONS = pathlib.Path('/mnt/user-data/outputs/ui/forge_window/icons')

def pal_from(top, bottom):
    """Палітра стилю A з двох кольорів за правилом GDD."""
    return dict(top=top, bottom=bottom, border=mix(bottom, light(top, .3), .45), outline=dark(bottom, .78),
                line=light(top, .55), lip=dark(bottom, .25))

# плитки руди: кольори руди / злитка (тон плитки — як у вікні кузні, але в стилі A)
ORE_PAL = {
    'coal':   pal_from('#767c86', '#2c3036'),
    'copper': pal_from('#f08a5a', '#a8441c'),
    'iron':   pal_from('#e2c49c', '#9a7450'),
}
_b = {}
def img(name):
    if name not in _b: _b[name] = 'data:image/png;base64,' + base64.b64encode((ICONS / f'{name}.png').read_bytes()).decode()
    return _b[name]

def inline(w, h, scale=1.0, **kw):
    d, b = gb.button('A', kw.pop('color', 'green'), w, h, pk=PK, **kw)
    return f'<svg width="{w * scale:.0f}" height="{h * scale:.0f}" viewBox="0 0 {w} {h}" style="display:block"><defs>{d}</defs>{b}</svg>'

def tile(pal=None, color='green', image=None, size=100, scale=1.0):
    return inline(size, size, scale, pal=pal, color=color, image=image, rows=4)

def chip(text, color, w=None, h=50, scale=1.0, size=22):
    w = w or int(len(text) * size * 0.74 + 52)
    return inline(w, h, scale, color=color, label=text, size=size, rows=3)

# ---------- секції ----------
ores = ''.join(
    f'<div class="cell">{tile(ORE_PAL[k], image=img(f"forge_ore_{k}"), scale=1.2)}<span>руда {k}</span></div>'
    f'<div class="cell">{tile(ORE_PAL[k], image=img(f"forge_bar_{k}"), scale=1.2)}<span>злиток {k}</span></div>'
    for k in ORE_PAL)
allc = ''.join(f'<div class="cell">{tile(color=c, scale=.9)}<span>{c}</span></div>' for c in gb.COLORS)
chips = (f'<div class="chips">{chip("WORKING", "green")}{chip("1 ore every 3s", "blue")}{chip("Bar = ×1.5 ore price", "orange")}</div>'
         f'<div class="chips">{chip("ASLEEP", "blue")}{chip("WAKING UP", "yellow")}{chip("FALLING ASLEEP", "purple")}{chip("MAX", "gray")}</div>'
         f'<div class="chips">' + ''.join(chip(c.upper(), c) for c in gb.COLORS) + '</div>')

# порівняння studs: кнопка (1×) і плитка / чип (0.5×)
d1, b1 = gb.button('A', 'orange', 200, 200, rows=4)
d2, b2 = gb.button('A', 'orange', 200, 200, rows=4, pk=PK)
cmpx = (f'<div class="chips"><div class="cell"><svg width="200" height="200" viewBox="0 0 200 200"><defs>{d1}</defs>{b1}</svg><span>studs як на кнопках</span></div>'
        f'<div class="cell"><svg width="200" height="200" viewBox="0 0 200 200"><defs>{d2}</defs>{b2}</svg><span>studs удвічі слабші (плитки, чипи)</span></div></div>')

def mock_row(k, name, have, pal_n, bars):
    return (f'<div class="row">{tile(ORE_PAL[k], image=img(f"forge_ore_{k}"), size=100, scale=.86)}'
            f'<div class="t"><b>{name}</b><span>You have {have} · On pallet {pal_n}</span></div>'
            f'<div class="bars"><small>bars</small> ×{bars}</div>{tile(ORE_PAL[k], image=img(f"forge_bar_{k}"), size=100, scale=.86)}</div>')
mock = (f'<div class="mock"><div class="chips">{chip("WORKING", "green", scale=.9)}{chip("1 ore every 3s", "blue", scale=.9)}'
        f'{chip("Bar = ×1.5 ore price", "orange", scale=.9)}</div>'
        + mock_row('coal', 'Coal', 5, 0, 0) + mock_row('copper', 'Copper', 2, 0, 3) + mock_row('iron', 'Iron', 1, 0, 1) + '</div>')

html = f'''<!doctype html><html lang="uk"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Плитки й чипи — стиль A</title><style>
@font-face{{font-family:Montserrat;font-weight:900;src:url(data:font/woff2;base64,{f900}) format('woff2')}}
body{{margin:0;background:#3b3f45;color:#e8edf2;font-family:system-ui,sans-serif}}
.wrap{{max-width:1180px;margin:0 auto;padding:24px 16px 60px}}
h1{{font-size:22px;color:#ffd34d;margin:0 0 6px}} h2{{font-size:18px;margin:30px 0 10px}} p{{color:#c3cbd4;font-size:14px;line-height:1.5;margin:0 0 12px}}
.grid{{display:flex;flex-wrap:wrap;gap:18px}} .cell{{display:flex;flex-direction:column;align-items:center;gap:6px}} .cell span{{font-size:12px;color:#c3cbd4}}
.chips{{display:flex;flex-wrap:wrap;gap:12px;margin-bottom:12px;align-items:flex-end}}
.mock{{background:#a9aeb5;border:5px solid #14161a;padding:16px;max-width:900px}}
.row{{display:flex;align-items:center;gap:16px;background:rgba(27,30,35,.6);border:3px solid #14161a;padding:6px;margin-top:10px}}
.row .t{{flex:1;display:flex;flex-direction:column}}
.row b,.bars{{font-family:Montserrat;font-weight:900;color:#fff;-webkit-text-stroke:5px #14161a;paint-order:stroke fill}}
.row b{{font-size:30px}} .row .t span{{font-family:Montserrat;font-weight:900;font-size:15px;color:#e9edf1;-webkit-text-stroke:3px #14161a;paint-order:stroke fill}}
.bars{{font-size:34px;color:#d4ff3e}} .bars small{{font-size:17px;color:#e9edf1}}
</style></head><body><div class="wrap">
<h1>Плитки й чипи — стиль A</h1>
<p>Та сама будова, що в кнопках стилю A (темний контур, світла рамка, градієнт, світла лінія й губа знизу), але візерунок studs <b>удвічі слабший</b>, щоб іконка й напис читалися краще.</p>
{cmpx}
<h2>Плитки руди й злитків (квадратні)</h2><p>Кольори плиток — тон руди: вугілля, мідь, залізо.</p><div class="grid">{ores}</div>
<h2>Плитки — усі кольори стилю A</h2><div class="grid">{allc}</div>
<h2>Верхні плашки-чипи</h2><p>Форма під чипи вікна: низькі, ширина — під текст.</p>{chips}
<h2>Як це виглядатиме у вікні кузні</h2>{mock}
</div></body></html>'''
(HERE / 'tiles_v2.html').write_text(html, encoding='utf-8')
print('ok', len(html))
