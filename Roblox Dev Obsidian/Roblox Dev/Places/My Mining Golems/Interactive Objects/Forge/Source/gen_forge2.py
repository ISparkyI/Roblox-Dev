"""Forge Upgrades — екран у стилі Roll Upgrades: 2D-підкладка зі studs + 2 вертикальні картки з іконками."""
import pathlib
HERE = pathlib.Path(__file__).parent
ns = {'__file__': str(HERE / 'gen_roll.py')}
src = (HERE / 'gen_roll.py').read_text(encoding='utf-8')
exec(src[:src.index("x0 = (W - (2 * CW + GAP)) / 2")], ns)
fns = {'__file__': str(HERE / 'gen_forge.py')}
fsrc = (HERE / 'gen_forge.py').read_text(encoding='utf-8')
exec(fsrc[:fsrc.index("# ---------- веб-прев'ю ----------")], fns)

INK, txt, studs_pattern, card_studs = ns['INK'], ns['txt'], ns['studs_pattern'], ns['card_studs']
f800, f900 = ns['f800'], ns['f900']
roll_svg = pathlib.Path('/mnt/user-data/outputs/ui/roll_upgrades_ui.svg').read_text(encoding='utf-8')
roll_defs = roll_svg[roll_svg.index('<defs>') + 6:roll_svg.index('</defs>')]

W, H = 1280, 1000                       # полотно табла кузні (16 × 12.5 стада)
CW, CH, GAP = 500, 790, 88
THEMES = {
    'cap':   ('capG', '#ffd2a3', 'capStuds', [('0', '#ffb15c'), ('.55', '#f07a1e'), ('1', '#b8500c')], '#ffc890', '#b3520f'),
    'speed': ('spdG', '#bfe6ff', 'spdStuds', [('0', '#6fc6ff'), ('.55', '#2f8ee6'), ('1', '#1a5cb0')], '#8fd2ff', '#1b62b8'),
}

def card(x, y, kind, title, cur, nxt, price, icon_body, can_buy=True, maxed=False):
    grad, rim, studs, *_ = THEMES[kind]
    o = [f'<g transform="translate({x},{y})">']
    o.append(f'<rect x="0" y="14" width="{CW}" height="{CH}" rx="40" fill="#000" opacity=".35"/>')
    o.append(f'<rect width="{CW}" height="{CH}" rx="40" fill="url(#{grad})" stroke="{INK}" stroke-width="12"/>')
    o.append(f'<rect x="10" y="10" width="{CW-20}" height="{CH-20}" rx="31" fill="url(#{studs})" opacity=".32"/>')
    o.append(f'<rect x="10" y="{CH-70}" width="{CW-20}" height="60" rx="30" fill="#000" opacity=".12"/>')
    o.append(f'<rect x="22" y="20" width="{CW-44}" height="{CH*0.36}" rx="28" fill="url(#gloss)"/>')
    o.append(f'<rect x="12" y="12" width="{CW-24}" height="{CH-24}" rx="30" fill="none" stroke="{rim}" stroke-width="6" opacity=".75"/>')
    # іконка (полотно 480 → 330 px)
    o.append(f'<svg x="{CW/2-170}" y="70" width="340" height="340" viewBox="-240 -240 480 480">{icon_body}</svg>')
    o.append(txt(CW / 2, 500, title, 72))
    if maxed:
        o.append(txt(CW / 2, 584, 'MAX', 52, '#d4ff3e'))
    else:
        o.append(f'<text x="{CW/2}" y="584" font-family="Montserrat" font-weight="900" font-size="48" text-anchor="middle" stroke="{INK}" stroke-width="10" '
                 f'stroke-linejoin="round" paint-order="stroke fill"><tspan fill="#fff">{cur}</tspan><tspan fill="#d4ff3e" dx="12">›</tspan><tspan fill="#d4ff3e" dx="12">{nxt}</tspan></text>')
    bx, by, bw, bh = 70, 640, CW - 140, 100
    btn = 'grayG' if maxed else ('limeG' if can_buy else 'dimG')
    o.append(f'<rect x="{bx}" y="{by+8}" width="{bw}" height="{bh}" rx="30" fill="#000" opacity=".3"/>')
    o.append(f'<rect x="{bx}" y="{by}" width="{bw}" height="{bh}" rx="30" fill="url(#{btn})" stroke="{INK}" stroke-width="10"/>')
    o.append(f'<rect x="{bx+16}" y="{by+12}" width="{bw-32}" height="{bh*0.36}" rx="18" fill="#fff" opacity=".35"/>')
    o.append(txt(CW / 2, by + bh / 2 + 21, 'MAX' if maxed else price, 58))
    o.append('</g>')
    return ''.join(o)

def screen(state='normal'):
    defs = [roll_defs, fns['DEFS']]
    for k, (grad, rim, studs, stops, sl, sd) in THEMES.items():
        defs.append(f'<linearGradient id="{grad}" x1="0" y1="0" x2="0" y2="1">' + ''.join(f'<stop offset="{a}" stop-color="{c}"/>' for a, c in stops) + '</linearGradient>')
        defs.append(card_studs(studs, 46, sl, sd))
    defs.append('<linearGradient id="dimG" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#d9e2b0"/><stop offset=".5" stop-color="#aab884"/><stop offset="1" stop-color="#7d8a5c"/></linearGradient>')
    defs.append(studs_pattern('frameStudsF', 64, '#4c5158', '#575c64', '#33373c', '#6a7078'))
    defs.append(studs_pattern('panelStudsF', 56, '#8e939a', '#979ca3', '#6c7178', '#aeb3b9'))
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" style="width:100%;height:auto;display:block"><defs>{"".join(defs)}</defs>']
    o.append(f'<rect width="{W}" height="{H}" rx="26" fill="url(#frameStudsF)"/>')
    o.append(f'<rect x="5" y="5" width="{W-10}" height="{H-10}" rx="22" fill="none" stroke="{INK}" stroke-width="10"/>')
    o.append(f'<rect x="64" y="64" width="{W-128}" height="{H-128}" rx="18" fill="url(#panelStudsF)"/>')
    o.append(f'<rect x="64" y="64" width="{W-128}" height="{H-128}" rx="18" fill="url(#panelShade)"/>')
    o.append(f'<rect x="64" y="64" width="{W-128}" height="{H-128}" rx="18" fill="none" stroke="{INK}" stroke-width="10"/>')
    x0 = (W - (2 * CW + GAP)) / 2; y0 = (H - CH) / 2 - 4
    cap, spd = fns['capacity_icon'](), fns['speed_icon']()
    if state == 'normal':
        o.append(card(x0, y0, 'cap', 'Capacity', '$600', '$900', '$400', cap, can_buy=False))
        o.append(card(x0 + CW + GAP, y0, 'speed', 'Speed', '2.75s', '2.50s', '$340', spd, can_buy=True))
    elif state == 'max':
        o.append(card(x0, y0, 'cap', 'Capacity', '', '', '', cap, maxed=True))
        o.append(card(x0 + CW + GAP, y0, 'speed', 'Speed', '', '', '', spd, maxed=True))
    else:  # asleep — картки під затемненням з написом
        o.append(card(x0, y0, 'cap', 'Capacity', '$300', '$600', '$250', cap, can_buy=False))
        o.append(card(x0 + CW + GAP, y0, 'speed', 'Speed', '3.00s', '2.75s', '$200', spd, can_buy=False))
        o.append(f'<rect x="64" y="64" width="{W-128}" height="{H-128}" rx="18" fill="#0d0f12" opacity=".72"/>')
        o.append(txt(W / 2, H / 2 - 10, 'WAKE THE GOLEM', 84, '#ffd34d'))
        o.append(txt(W / 2, H / 2 + 70, 'FIRST', 84, '#ffd34d'))
    o.append('</svg>')
    return ''.join(o)

html = f'''<!doctype html><html lang="uk"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Forge Upgrades — UI табла</title>
<style>
@font-face {{ font-family: Montserrat; font-weight: 800; src: url(data:font/woff2;base64,{f800}) format('woff2'); }}
@font-face {{ font-family: Montserrat; font-weight: 900; src: url(data:font/woff2;base64,{f900}) format('woff2'); }}
body{{margin:0;background:#20242a;color:#e8edf2;font-family:system-ui,sans-serif}}
.wrap{{max-width:1180px;margin:0 auto;padding:24px 16px 48px}}
h1{{font-size:20px;color:#ffd34d;margin:0 0 6px}} h2{{font-size:16px;margin:26px 0 10px;color:#c9d2dc}}
p{{color:#b9c2cc;font-size:14px;line-height:1.5;margin:0 0 10px}}
.main{{max-width:760px;margin:0 auto;border-radius:16px;overflow:hidden;box-shadow:0 10px 36px rgba(0,0,0,.45)}}
.row{{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:18px}}
.row > div{{border-radius:14px;overflow:hidden;box-shadow:0 8px 24px rgba(0,0,0,.4)}}
.cap{{text-align:center;font-size:13px;color:#b9c2cc;margin-top:6px}}
</style></head><body><div class="wrap">
<h1>Forge Upgrades — UI табла (стиль Roll Upgrades)</h1>
<p>Та сама 2D-підкладка зі studs і вертикальні картки, що й на таблі Roll Upgrades. Полотно під екран табла кузні (16 × 12,5 стада). Capacity — помаранчева картка з ящиком руди, Speed — синя з молотом. Кнопка лаймова, якщо грошей вистачає, тьмяна — якщо ні, сіра MAX — на максимумі.</p>
<div class="main">{screen('normal')}</div>
<h2>Інші стани</h2>
<div class="row"><div>{screen('asleep')}</div><div>{screen('max')}</div></div>
<div class="row"><p class="cap">голем спить — картки під затемненням</p><p class="cap">обидва покращення на максимумі</p></div>
</div></body></html>'''
out = pathlib.Path('/mnt/user-data/outputs/ui/forge_icons/forge_upgrades_ui.html')
out.write_text(html, encoding='utf-8')
print(out)
