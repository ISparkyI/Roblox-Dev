"""Збирає концепт-лист clay_golem_concept.png з рендерів render_shots.js."""
import os
from PIL import Image, ImageDraw, ImageFont
O = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
F = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"; FB = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
font = lambda n, b=False: ImageFont.truetype(FB if b else F, n)
BG = (29, 33, 41); FG = (232, 235, 240); MUT = (154, 163, 178)
W = 2400
sheet = Image.new("RGB", (W, 2360), BG); d = ImageDraw.Draw(sheet)
d.text((40, 30), "Clay Golem — концепт-лист", font=font(48, True), fill=FG)
d.text((40, 92), "глиняний голем · Common · «важкий, повільний» · size 1.05 · блоковий стиль (1 од. = 0,5 стада)", font=font(26), fill=MUT)

def tile(name, box, label, crop=None):
    im = Image.open(os.path.join(O, name)).convert("RGB")
    if crop: im = im.crop(crop)
    x, y, w, h = box
    k = min(w / im.width, (h - 44) / im.height); im = im.resize((int(im.width*k), int(im.height*k)), Image.LANCZOS)
    sheet.paste(im, (x + (w - im.width)//2, y + 44))
    d.text((x + 12, y + 6), label, font=font(28, True), fill=FG)

CROP = (190, 120, 1018, 900)   # центр кадру з големом
row1 = [("clay_front.png", "Спереду"), ("clay_34.png", "3/4"), ("clay_side.png", "Збоку"), ("clay_back.png", "Ззаду")]
cw = (W - 80) // 4
for i, (n, l) in enumerate(row1): tile(n, (40 + i*cw, 150, cw, 700), l, CROP)
row2 = [("clay_miner.png", "Майнер — кірка"), ("clay_carrier.png", "Носій — ящичок з рудою"), ("clay_warrior.png", "Воїн — меч"), ("clay_miner_swing.png", "Mine: замах")]
for i, (n, l) in enumerate(row2): tile(n, (40 + i*cw, 870, cw, 700), l, CROP if i < 3 else (150, 0, 1150, 900))
tile("clay_items.png", (40, 1590, 1560, 520), "Предмети: кірка · ящичок · меч")
# палітра
pal = [("#c4714a", "теракота (основний)"), ("#8c4a33", "мокра глина (акцент)"), ("#a39e94", "камінці"),
       ("#e3ab80", "суха глина (лише предмети)"), ("#f1f5f8", "світлий (спільний)"), ("#1c2836", "темний (спільний)"), ("#f2a0b4", "щічки (спільний)")]
x0, y0 = 1650, 1600
d.text((x0, y0), "Палітра", font=font(28, True), fill=FG)
for i, (h, n) in enumerate(pal):
    y = y0 + 52 + i*58
    d.rounded_rectangle((x0, y, x0 + 46, y + 46), 8, fill=h, outline=(80, 88, 100))
    d.text((x0 + 62, y + 2), h, font=font(24, True), fill=FG); d.text((x0 + 62, y + 26), n, font=font(18), fill=MUT)
notes = ["Фірмові деталі: відбиток долоні на пузі, сліди пальців на спині,",
         "патьоки мокрої глини, втиснуті камінці, тріщини, «защип» на маківці.",
         "Обличчя дружнє: великі очі шарами по 0,1, брови вгору до центру, щічки, усмішка.",
         "Тіло: 67 блоків, 804 трикутники, 6 кольорів, правило 0,1 — 0 збігів. Кірка 15, меч 11, ящичок 18 блоків + 10 гнізд руди."]
for i, t in enumerate(notes): d.text((40, 2150 + i*44), t, font=font(26), fill=MUT if i else FG)
sheet.save(os.path.join(O, "clay_golem_concept.png"))
print("ok", sheet.size)
