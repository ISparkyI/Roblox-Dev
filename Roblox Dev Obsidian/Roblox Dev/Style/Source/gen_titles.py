"""Заголовки вікон — шрифт той самий (Montserrat 900), КАПСОМ, градієнт + білий відблиск, що пробігає зліва направо
(як на кнопках). Варіанти градієнтів: статичні вертикальні та «переливання» (кольори повільно пливуть по горизонталі).
Пише titles.html.
"""
import base64, pathlib

HERE = pathlib.Path(__file__).parent
FS = pathlib.Path('/tmp/claude-0/-home-claude/8add1236-f2d8-59ff-a5ae-4d35d196baed/scratchpad/ui/node_modules/@fontsource/montserrat/files')
f900 = base64.b64encode((FS / 'montserrat-latin-900-normal.woff2').read_bytes()).decode()
f800 = base64.b64encode((FS / 'montserrat-latin-800-normal.woff2').read_bytes()).decode()
INK = '#14161a'

VARS = [  # id, назва, тип ('v' — вертикальний, 'flow' — пливе по горизонталі), стопи
    ('gold', 'Золото (як зараз)', 'v', [(0, '#fff2a0'), (.5, '#ffc531'), (1, '#f07a1e')]),
    ('ember', 'Жар', 'v', [(0, '#fff4c8'), (.35, '#ffc54a'), (.7, '#ff7a24'), (1, '#e0381c')]),
    ('sunset', 'Захід', 'v', [(0, '#ffe680'), (.5, '#ff9a3c'), (1, '#ff4f7a')]),
    ('lava', 'Лава — переливається', 'flow', [(0, '#ffd23a'), (.25, '#ff8a1e'), (.5, '#ff4a2a'), (.75, '#ff8a1e'), (1, '#ffd23a')]),
    ('goldflow', 'Золото — переливається', 'flow', [(0, '#fff6b0'), (.25, '#ffc531'), (.5, '#ff9a1a'), (.75, '#ffc531'), (1, '#fff6b0')]),
    ('steel', 'Сталь', 'v', [(0, '#ffffff'), (.5, '#cfd8e2'), (1, '#8796a8')]),
]

def title_svg(vid, kind, stops, word='FORGE', w=560, h=150, size=104):
    g, sh = f'g_{vid}', f's_{vid}'
    if kind == 'v':
        grad = f'<linearGradient id="{g}" x1="0" y1="0" x2="0" y2="1">' + ''.join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops) + '</linearGradient>'
    else:   # горизонтальний, повторюється, повільно пливе
        grad = (f'<linearGradient id="{g}" x1="0" y1="0" x2="{w / 2}" y2="0" gradientUnits="userSpaceOnUse" spreadMethod="repeat">' +
                ''.join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops) +
                f'<animateTransform attributeName="gradientTransform" type="translate" from="0 0" to="{w / 2} 0" dur="4s" repeatCount="indefinite"/></linearGradient>')
    shine = (f'<linearGradient id="{sh}" class="shine" x1="0" y1="0" x2="{w}" y2="{w * .47:.0f}" gradientUnits="userSpaceOnUse" gradientTransform="translate(-{w * 1.3:.0f} 0)">'
             '<stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset=".40" stop-color="#fff" stop-opacity="0"/>'
             '<stop offset=".44" stop-color="#fff" stop-opacity=".75"/><stop offset=".49" stop-color="#fff" stop-opacity="0"/>'
             '<stop offset=".53" stop-color="#fff" stop-opacity="0"/><stop offset=".555" stop-color="#fff" stop-opacity=".5"/>'
             '<stop offset=".58" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>')
    base = f'x="20" y="{h / 2 + size * .36:.0f}" font-family="Montserrat" font-weight="900" font-size="{size}" letter-spacing="2"'
    return (f'<svg viewBox="0 0 {w} {h}" data-w="{w}" style="width:100%;height:auto;display:block"><defs>{grad}{shine}</defs>'
            f'<text {base} transform="translate(0 7)" fill="{INK}" stroke="{INK}" stroke-width="18" stroke-linejoin="round">{word}</text>'
            f'<text {base} fill="url(#{g})" stroke="{INK}" stroke-width="16" stroke-linejoin="round" paint-order="stroke fill">{word}</text>'
            f'<text {base} fill="url(#{sh})">{word}</text></svg>')

cards = ''.join(f'<div class="v"><h3>{name}</h3>{title_svg(vid, kind, stops)}</div>' for vid, name, kind, stops in VARS)

# табличка над кузнею (BillboardGui) — як виглядатиме з капсом
board = ''.join(
    f'<div class="v bb"><h3>Табличка над кузнею — {name}</h3>'
    + title_svg('bb_' + vid, kind, stops, 'FORGE', 420, 110, 72).replace('<svg ', '<svg class="bbt" ')
    + '<div class="state">ASLEEP</div></div>' for vid, name, kind, stops in VARS[:2])

caps = '''<table><tr><th>Що</th><th>Регістр</th><th>Приклад</th></tr>
<tr><td>Заголовки вікон і таблички над об'єктами</td><td><b>КАПС</b></td><td>FORGE, STORE, ROLL UPGRADES</td></tr>
<tr><td>Статуси й чипи</td><td><b>КАПС</b></td><td>WORKING, ASLEEP, WAKING UP, MAX</td></tr>
<tr><td>Великі попередження / затемнення</td><td><b>КАПС</b></td><td>WAKE THE GOLEM FIRST</td></tr>
<tr><td>Кнопки</td><td>Кожне слово з великої</td><td>Put Ore, Take Bars (3), Wake Up</td></tr>
<tr><td>Назви предметів і покращень</td><td>Кожне слово з великої</td><td>Coal, Roll Luck, Capacity</td></tr>
<tr><td>Підписи до шкал</td><td>Кожне слово з великої</td><td>Ore Given, Ore Pallet</td></tr>
<tr><td>Пояснення й речення</td><td>Як у реченні</td><td>The golem is asleep. Bring ore to wake him up.</td></tr>
<tr><td>Числа й ціни</td><td>—</td><td>$1,000 · 3.00s › 2.75s · ×8</td></tr></table>'''

html = f'''<!doctype html><html lang="uk"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Заголовки КАПСОМ</title><style>
@font-face{{font-family:Montserrat;font-weight:900;src:url(data:font/woff2;base64,{f900}) format('woff2')}}
@font-face{{font-family:Montserrat;font-weight:800;src:url(data:font/woff2;base64,{f800}) format('woff2')}}
body{{margin:0;background:#3b3f45;color:#e8edf2;font-family:system-ui,sans-serif}}
.wrap{{max-width:1200px;margin:0 auto;padding:24px 16px 60px}} h1{{font-size:22px;color:#ffd34d;margin:0 0 6px}}
h2{{font-size:18px;margin:30px 0 8px}} h3{{font-size:14px;margin:0 0 6px;color:#ffd34d}} p{{color:#c3cbd4;font-size:14px;line-height:1.5;margin:0 0 12px}}
.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(360px,1fr));gap:16px}}
.v{{background:#a9aeb5;padding:10px 12px;border:4px solid #14161a}} .v h3{{color:#14161a}}
.bb{{background:#6b5a4a;text-align:center}} .bb svg{{max-width:420px;margin:0 auto}}
.state{{font-family:Montserrat;font-weight:900;font-size:30px;color:#ffc531;-webkit-text-stroke:7px #14161a;paint-order:stroke fill;margin-top:-6px}}
table{{border-collapse:collapse;width:100%;background:#2e3237}} td,th{{border:1px solid #23262a;padding:8px 10px;text-align:left;font-size:14px}} th{{background:#23262a}}
button{{font:600 14px system-ui;padding:8px 14px;margin:6px 0 12px;cursor:pointer}}
</style></head><body><div class="wrap">
<h1>Заголовки — КАПСОМ, градієнт + білий відблиск</h1>
<p>Шрифт той самий (Montserrat 900), без 3D-ефектів: градієнт, темний контур і тверда тінь, як зараз. По напису час від часу (випадково, кожні 3–6 с) пробігає білий відблиск зліва направо — як на кнопках. Два варіанти «переливаються»: кольори повільно пливуть по горизонталі.</p>
<button onclick="document.querySelectorAll('svg[data-w]').forEach(s=>sweep(s))">Запустити відблиск на всіх</button>
<h2>Варіанти градієнта</h2><div class="grid">{cards}</div>
<h2>Табличка над кузнею</h2><div class="grid">{board}</div>
<h2>Де писати КАПСОМ (пропозиція)</h2>{caps}
</div>
<script>
function sweep(svg){{
  const g=svg.querySelector('.shine'); if(!g||svg._run) return; svg._run=true;
  const w=+svg.dataset.w, t0=performance.now(), dur=1100;
  (function f(t){{ let k=Math.min(1,(t-t0)/dur); k=k<.5?2*k*k:1-Math.pow(-2*k+2,2)/2;
    g.setAttribute('gradientTransform',`translate(${{(-1.3+2.6*k)*w}} 0)`);
    if(k<1) requestAnimationFrame(f); else {{ g.setAttribute('gradientTransform',`translate(${{-1.3*w}} 0)`); svg._run=false; }} }})(t0);
}}
document.querySelectorAll('svg[data-w]').forEach(s=>{{ const loop=()=>{{ sweep(s); setTimeout(loop,3000+Math.random()*3000); }}; setTimeout(loop,500+Math.random()*2500); }});
</script></body></html>'''
(HERE / 'titles.html').write_text(html, encoding='utf-8')
print('ok', len(html))
