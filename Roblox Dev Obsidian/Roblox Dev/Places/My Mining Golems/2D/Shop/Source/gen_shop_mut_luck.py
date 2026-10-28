import math
from PIL import Image, ImageDraw, ImageFilter, ImageChops
SS=4; N=512; W=N*SS
INK=(20,22,26,255)
def P(v): return int(v*SS)
def circles_mask(cs):
    m=Image.new("L",(W,W),0); d=ImageDraw.Draw(m)
    for x,y,r in cs: d.ellipse([P(x-r),P(y-r),P(x+r),P(y+r)],fill=255)
    return m
def grad(top,mid,bot):
    g=Image.new("RGBA",(W,W)); px=g.load()
    col=[]
    for y in range(W):
        t=y/W
        if t<0.5: a,b,u=top,mid,t/0.5
        else: a,b,u=mid,bot,(t-0.5)/0.5
        col.append(tuple(int(a[i]+(b[i]-a[i])*u) for i in range(3))+(255,))
    d=ImageDraw.Draw(g)
    for y in range(W): d.line([(0,y),(W,y)],fill=col[y])
    return g
# хмара диму: велика купа зверху + хвіст-завиток донизу
puffs=[(290,190,118),(178,238,88),(392,218,78),(232,120,74),(352,108,66)]
tail=[(196,318,58),(150,370,44),(128,418,32),(150,452,22),(184,462,15)]
body=circles_mask(puffs+tail)
outline=body.filter(ImageFilter.MaxFilter(2*P(13)+1)).filter(ImageFilter.GaussianBlur(P(2))).point(lambda v:255 if v>110 else 0)
img=Image.new("RGBA",(W,W),(0,0,0,0))
img.paste(INK,(0,0),outline)
# основна заливка: рожевий → фіолетовий → темно-фіолетовий
base=grad((255,160,235),(170,90,255),(80,60,210))
img.paste(base,(0,0),body)
# світліші «верхівки» кожної кульки (обʼєм)
hl=Image.new("RGBA",(W,W),(0,0,0,0)); hd=ImageDraw.Draw(hl)
for x,y,r in puffs+tail:
    hd.ellipse([P(x-r*0.78),P(y-r*0.86),P(x+r*0.6),P(y+r*0.3)],fill=(255,215,255,70))
hl.putalpha(ImageChops.multiply(hl.split()[3],body)); img=Image.alpha_composite(img,hl)
# темніший низ кожної кульки (розділення кульок, як шви)
sh=Image.new("RGBA",(W,W),(0,0,0,0)); sd=ImageDraw.Draw(sh)
for x,y,r in []:
    sd.arc([P(x-r),P(y-r),P(x+r),P(y+r)],start=30,end=150,fill=(70,25,150,150),width=P(9))
sh.putalpha(ImageChops.multiply(sh.split()[3],body)); img=Image.alpha_composite(img,sh)
# завиток (мутація): спіраль бірюзово-рожева всередині
sw=Image.new("RGBA",(W,W),(0,0,0,0)); swd=ImageDraw.Draw(sw)
cx,cy=292,198
pts=[]
for i in range(220):
    t=i/220*2.2*math.pi; r=10+t*12
    pts.append((P(cx+math.cos(t-1.2)*r),P(cy+math.sin(t-1.2)*r*0.82)))
for i in range(len(pts)-1):
    u=i/len(pts)
    c=(int(170+85*u),int(250-10*u),255,255)
    swd.line([pts[i],pts[i+1]],fill=c,width=P(17))
# контур спіралі (тонкий темний під нею)
swo=Image.new("RGBA",(W,W),(0,0,0,0)); ImageDraw.Draw(swo).line(pts,fill=(40,16,100,255),width=P(27),joint="curve")
# спіраль прибрано (v3)
# білі дуги-блиски (як на конюшині)
gl=Image.new("RGBA",(W,W),(0,0,0,0)); gd=ImageDraw.Draw(gl)
for x,y,r,a0,a1 in [(232,120,58,200,262),(178,238,70,175,235),(352,108,50,215,265)]:
    gd.arc([P(x-r),P(y-r),P(x+r),P(y+r)],start=a0,end=a1,fill=(255,255,255,200),width=P(9))
img=Image.alpha_composite(img,gl)
# іскорки
def spark(d,cx,cy,r,a=255):
    p=[]
    for i in range(8):
        ang=math.pi/4*i-math.pi/2; rr=r if i%2==0 else r*0.26
        p.append((P(cx+math.cos(ang)*rr),P(cy+math.sin(ang)*rr)))
    d.polygon(p,fill=(255,255,255,a))
sp=Image.new("RGBA",(W,W),(0,0,0,0)); spd=ImageDraw.Draw(sp)
spark(spd,450,330,32); spark(spd,96,150,22,230); spark(spd,440,70,14,210)
img=Image.alpha_composite(img,sp)
out=img.resize((N,N),Image.LANCZOS)
bb=out.getbbox(); c=out.crop(bb); side=max(c.size)+40
sq=Image.new("RGBA",(side,side),(0,0,0,0)); sq.paste(c,((side-c.size[0])//2,(side-c.size[1])//2))
sq.resize((512,512),Image.LANCZOS).save("shop_mut_luck.png")
R="/mnt/user-data/uploads/Roblox Dev Obsidian/Roblox Dev/Places/My Mining Golems/Interactive Objects/Roll Upgrades Screen/Roblox/clover.png"
s=Image.new("RGBA",(780,260),(46,140,200,255))
cl=Image.open(R).convert("RGBA"); cl.thumbnail((250,250)); s.alpha_composite(cl,(5,5))
m=Image.open("shop_mut_luck.png"); m.thumbnail((250,250)); s.alpha_composite(m,(265,5))
m2=m.copy(); m2.thumbnail((90,90)); s.alpha_composite(m2,(560,80))
s.save("mut_preview.png")
