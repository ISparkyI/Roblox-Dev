"""Money HUD v3 — без монети, проста «+», темна підкладка з прозорим градієнтом і слабкими studs,
ширина підкладки підлаштовується під довжину суми; TOTAL MULTI зверху на ще прозорішій підкладці.
HTML/CSS (inline-block + padding = автоширина, як AutomaticSize X у Roblox). Пише money_v3.html.
"""
import base64, pathlib, importlib.util, urllib.parse

HERE = pathlib.Path(__file__).parent
spec = importlib.util.spec_from_file_location('gt', HERE / 'gen_tiles.py')
gt = importlib.util.module_from_spec(spec); spec.loader.exec_module(gt)
gb = gt.gb
INK, f900 = gb.INK, gb.f900

def stud_tile(cell=14, col='#3a4048', k=.55):
    t = cell * 2
    s = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{t}" height="{t}"><defs>{gb.pattern_a("p", cell, col, 0, 0, k)}</defs>'
         f'<rect width="{t}" height="{t}" fill="url(#p)"/></svg>')
    return 'url("data:image/svg+xml,' + urllib.parse.quote(s) + '")', t

STUD, ST = stud_tile()

def plus_btn(size, flat=False):
    """Спрощена «+»: квадрат, зелений вертикальний градієнт, темний контур, невелика губа, білий плюс. Без studs."""
    lip = 0 if flat else size * .12
    r, c, fy = size * .2, size / 2, (size - lip) / 2
    p = ''.join(f'<path d="M{c - r:.1f},{fy:.1f} H{c + r:.1f} M{c:.1f},{fy - r:.1f} V{fy + r:.1f}" stroke="{col}" stroke-width="{sw:.1f}" stroke-linecap="square"/>'
                for sw, col in ((size * .2, INK), (size * .1, '#fff')))
    g = f'pg{size}{int(flat)}'
    return (f'<svg class="plus" width="{size}" height="{size}" viewBox="0 0 {size} {size}">'
            f'<defs><linearGradient id="{g}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9dff4a"/><stop offset="1" stop-color="#2fc21c"/></linearGradient></defs>'
            f'<rect x="1.5" y="1.5" width="{size - 3}" height="{size - 3}" fill="#1f7a14" stroke="{INK}" stroke-width="3"/>'
            f'<rect x="3" y="3" width="{size - 6}" height="{size - 6 - lip}" fill="url(#{g})"/>'
            f'<rect x="3" y="3" width="{size - 6}" height="{size * .1:.1f}" fill="#fff" opacity=".35"/>{p}</svg>')

# ---------- три варіанти: (id, назва, опис, html-фабрика) ----------
def hud(v, money):
    pb = plus_btn(52, flat=(v == 'vc'))
    return (f'<div class="hud {v}"><div class="multi"><span class="ml">TOTAL MULTI</span> <span class="mx">x1</span></div>'
            f'<div class="line"><div class="cash"><span class="mv">{money}</span></div>{pb}</div></div>')

VARS = [
    ('va', 'A. Затухання вправо',
     'Підкладка темна зліва і плавно зникає праворуч (UIGradient Transparency по горизонталі). Studs ледь видно, теж затухають. '
     'TOTAL MULTI — та сама форма, але ще прозоріша й тонша. «+» — простий зелений квадрат одразу за сумою.'),
    ('vb', 'B. Рівна напівпрозора плашка з рамкою',
     'Прямокутна темна плашка з тонкою темною рамкою, градієнт зверху вниз (зверху щільніша). Studs слабкі. '
     'TOTAL MULTI — маленька плашка без рамки над лівим краєм. «+» прилягає до правого краю плашки.'),
    ('vc', 'C. Стрічка — затухання з обох боків',
     'Підкладка-стрічка: прозора по краях, темна в середині, сума по центру. TOTAL MULTI — така сама стрічка, вужча й прозоріша, по центру над сумою. '
     '«+» окремо праворуч, плаский (без губи).'),
]

CSS = f'''
.hud{{display:inline-flex;flex-direction:column;align-items:flex-start;gap:4px;font-family:Montserrat;font-weight:900}}
.line{{display:flex;align-items:center;gap:8px}}
.cash{{position:relative;display:inline-block;padding:4px 34px 6px 14px;line-height:1}}
.cash::before,.multi::before{{content:"";position:absolute;inset:0;z-index:0}}
.cash::after{{content:"";position:absolute;inset:0;z-index:0;background:{STUD};background-size:{ST}px {ST}px}}
.mv{{position:relative;z-index:1;font-size:44px;color:#7dff3a;-webkit-text-stroke:7px {INK};paint-order:stroke fill;letter-spacing:.5px}}
.multi{{position:relative;display:inline-block;padding:3px 22px 4px 10px;line-height:1;font-size:16px;letter-spacing:.6px}}
.multi span{{position:relative;z-index:1;-webkit-text-stroke:4px {INK};paint-order:stroke fill}}
.ml{{color:#e6edf5}} .mx{{color:#5ff2ff}}
.plus{{display:block;flex:none}}

/* A — затухання вправо */
.va .cash::before{{background:linear-gradient(90deg,rgba(14,16,20,.78) 0%,rgba(14,16,20,.7) 60%,rgba(14,16,20,0) 100%)}}
.va .cash::after{{-webkit-mask:linear-gradient(90deg,#000 0%,#000 50%,transparent 100%);mask:linear-gradient(90deg,#000 0%,#000 50%,transparent 100%);opacity:.8}}
.va .multi::before{{background:linear-gradient(90deg,rgba(14,16,20,.5) 0%,rgba(14,16,20,.42) 55%,rgba(14,16,20,0) 100%)}}
.va .line{{gap:4px}}

/* B — рівна плашка з рамкою */
.vb .cash{{padding:4px 16px 6px 14px;box-shadow:inset 0 0 0 3px rgba(20,22,26,.85)}}
.vb .cash::before{{background:linear-gradient(180deg,rgba(26,29,34,.78) 0%,rgba(14,16,20,.55) 100%)}}
.vb .cash::after{{opacity:.7;inset:3px}}
.vb .multi{{padding:3px 10px 4px 10px}}
.vb .multi::before{{background:rgba(14,16,20,.4)}}
.vb .line{{gap:0}} .vb .plus{{margin-left:-3px}} .vb .plus{{width:58px;height:58px}}

/* C — стрічка з обох боків */
.vc{{align-items:center}}
.vc .cash{{padding:4px 46px 6px 46px}}
.vc .cash::before{{background:linear-gradient(90deg,rgba(14,16,20,0) 0%,rgba(14,16,20,.75) 22%,rgba(14,16,20,.75) 78%,rgba(14,16,20,0) 100%)}}
.vc .cash::after{{-webkit-mask:linear-gradient(90deg,transparent 0%,#000 25%,#000 75%,transparent 100%);mask:linear-gradient(90deg,transparent 0%,#000 25%,#000 75%,transparent 100%);opacity:.8}}
.vc .multi{{padding:3px 30px 4px 30px}}
.vc .multi::before{{background:linear-gradient(90deg,rgba(14,16,20,0) 0%,rgba(14,16,20,.45) 25%,rgba(14,16,20,.45) 75%,rgba(14,16,20,0) 100%)}}
.vc .line{{gap:2px}}
.vc .hudwrap{{}}
'''

def scene(v, w, h, phone, money):
    rb = ('<div class="rb"><i></i><b></b></div>')
    extra = '<div class="joy"></div><div class="jump">jump</div>' if phone else ''
    pos = 'left:18px;top:72px;transform:scale(.75);transform-origin:0 0' if phone else 'left:24px;bottom:28px'
    return (f'<div class="fit" data-w="{w}" data-h="{h}"><div class="scene{" phone" if phone else ""}" style="width:{w}px;height:{h}px">{rb}{extra}'
            f'<div style="position:absolute;{pos}">{hud(v, money)}</div></div></div>')

cards = []
for v, name, note in VARS:
    demo = ''.join(f'<div class="demo">{hud(v, m)}</div>' for m in ('$500', '$12.5K', '$1.25M', '$999.99Qd'))
    cards.append(f'<div class="v"><h2>{name}</h2><p>{note}</p>'
                 f'<b class="cap">Ширина росте разом із сумою</b><div class="demos">{demo}</div>'
                 f'<div class="row"><div><b class="cap">ПК — низ ліворуч</b>{scene(v, 1000, 420, False, "$12.5K")}</div>'
                 f'<div><b class="cap">Телефон — зверху ліворуч під кнопками Roblox (×0,75)</b>{scene(v, 844, 390, True, "$12.5K")}</div></div></div>')

bg_tile = ('<svg xmlns="http://www.w3.org/2000/svg" width="70" height="70"><rect width="70" height="70" fill="#8a7a66"/>'
           '<rect x="18" y="18" width="34" height="34" fill="none" stroke="#6f6252" stroke-width="3" transform="rotate(20 35 35)"/></svg>')
BG = 'url("data:image/svg+xml,' + urllib.parse.quote(bg_tile) + '")'

html = f'''<!doctype html><html lang="uk"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Money HUD v3</title><style>
@font-face{{font-family:Montserrat;font-weight:900;src:url(data:font/woff2;base64,{f900}) format('woff2')}}
body{{margin:0;background:#3b3f45;color:#e8edf2;font-family:system-ui,sans-serif}}
.wrap{{max-width:1240px;margin:0 auto;padding:24px 16px 60px}} h1{{font-size:22px;color:#ffd34d;margin:0 0 6px}}
h2{{font-size:18px;margin:0 0 4px;color:#ffd34d}} p{{color:#c3cbd4;font-size:14px;line-height:1.5;margin:0 0 10px}}
.v{{background:#2e3237;border:2px solid #23262a;padding:14px;margin-top:18px}}
.row{{display:grid;grid-template-columns:1.2fr 1fr;gap:14px;margin-top:12px}} .row>div{{min-width:0}} .cap{{display:block;font-size:13px;margin-bottom:6px;color:#c3cbd4}}
.demos{{display:flex;flex-wrap:wrap;gap:14px 26px;align-items:flex-end;background:{BG};padding:16px;border:3px solid #14161a}}
.fit{{overflow:hidden;border:3px solid #14161a}} .scene{{position:relative;background:{BG};transform-origin:0 0}}
.rb{{position:absolute;left:18px;top:14px;display:flex;gap:8px}} .rb i{{width:44px;height:44px;border-radius:22px;background:#1d1f23d9}} .rb b{{width:96px;height:44px;border-radius:22px;background:#1d1f23d9}}
.joy{{position:absolute;left:58px;bottom:38px;width:124px;height:124px;border-radius:50%;background:#00000040}}
.jump{{position:absolute;right:64px;bottom:49px;width:92px;height:92px;border-radius:50%;background:#0000004d;color:#ffffffb3;font-size:16px;display:flex;align-items:center;justify-content:center}}
@media (max-width:820px){{.row{{grid-template-columns:1fr}}}}
{CSS}
</style></head><body><div class="wrap">
<h1>Money HUD — 3 варіанти з підкладкою</h1>
<p>Без монети. «+» — простий зелений квадрат з білим плюсом. Під сумою темна підкладка з прозорим градієнтом і ледь помітними studs; вона розширюється разом із сумою (у Roblox — AutomaticSize X + UIPadding). Над сумою — TOTAL MULTI на ще прозорішій підкладці. На телефоні все однакове, лише ×0,75, зверху ліворуч під кнопками Roblox.</p>
{"".join(cards)}
</div><script>
function fit(){{document.querySelectorAll('.fit').forEach(f=>{{const s=f.firstElementChild,w=+f.dataset.w,h=+f.dataset.h,k=f.clientWidth/w;s.style.transform=`scale(${{k}})`;f.style.height=(h*k)+'px';
 const inner=s.querySelector('div[style*="scale(.75)"]'); }});}}
addEventListener('resize',fit); document.fonts.ready.then(fit); fit();
</script></body></html>'''
(HERE / 'money_v3.html').write_text(html, encoding='utf-8')
print('ok', len(html))
