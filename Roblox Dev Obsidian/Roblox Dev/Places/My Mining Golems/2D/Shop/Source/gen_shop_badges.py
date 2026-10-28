import math
from PIL import Image, ImageDraw, ImageFilter, ImageChops
SS=4
INK=(20,22,26,255)
def badge(size, top, bot, symbol):
    """size — діаметр у px (фінальних); symbol(draw, cx, cy, r) малює білий символ у масці"""
    S=size*SS; im=Image.new("RGBA",(S,S),(0,0,0,0)); d=ImageDraw.Draw(im)
    d.ellipse([0,0,S-1,S-1],fill=INK)
    ring=int(S*0.085)
    # вертикальний градієнт заливки
    g=Image.new("RGBA",(S,S)); gd=ImageDraw.Draw(g)
    for y in range(S):
        t=y/S; c=tuple(int(top[i]+(bot[i]-top[i])*t) for i in range(3))+(255,)
        gd.line([(0,y),(S,y)],fill=c)
    m=Image.new("L",(S,S),0); ImageDraw.Draw(m).ellipse([ring,ring,S-1-ring,S-1-ring],fill=255)
    im.paste(g,(0,0),m)
    # блиск угорі
    gl=Image.new("RGBA",(S,S),(0,0,0,0)); ImageDraw.Draw(gl).ellipse([int(S*0.28),int(S*0.17),int(S*0.62),int(S*0.33)],fill=(255,255,255,90))
    im=Image.alpha_composite(im,gl)
    # символ: біла маска + темний контур
    sm=Image.new("L",(S,S),0); symbol(ImageDraw.Draw(sm),S/2,S/2,S/2)
    ol=sm.filter(ImageFilter.MaxFilter(int(S*0.05)//2*2+1))
    inkl=Image.new("RGBA",(S,S),INK); im.paste(inkl,(0,0),ol)
    wl=Image.new("RGBA",(S,S),(255,255,255,255)); im.paste(wl,(0,0),sm)
    return im.resize((size,size),Image.LANCZOS)
def sym_bolt(d,cx,cy,r):
    p=[(0.08,-0.62),(-0.36,0.06),(-0.04,0.06),(-0.14,0.62),(0.36,-0.12),(0.04,-0.12),(0.16,-0.62)]
    d.polygon([(cx+x*r,cy+y*r) for x,y in p],fill=255)
def sym_check(d,cx,cy,r):
    w=int(r*0.26)
    d.line([(cx-0.42*r,cy+0.02*r),(cx-0.1*r,cy+0.34*r),(cx+0.46*r,cy-0.32*r)],fill=255,width=w,joint="curve")
    for x,y in [(cx-0.42*r,cy+0.02*r),(cx+0.46*r,cy-0.32*r)]: d.ellipse([x-w/2,y-w/2,x+w/2,y+w/2],fill=255)
def sym_arrows(d,cx,cy,r):
    rr=r*0.44; w=int(r*0.17)
    box=[cx-rr,cy-rr,cx+rr,cy+rr]
    d.arc(box,start=200,end=330,fill=255,width=w)
    d.arc(box,start=20,end=150,fill=255,width=w)
    def head(a,dirn):
        a=math.radians(a); x=cx+rr*math.cos(a); y=cy+rr*math.sin(a)
        t=a+dirn*math.pi/2; s=r*0.24
        nx,ny=math.cos(a),math.sin(a)
        tip=(x+math.cos(t)*s*1.1,y+math.sin(t)*s*1.1)
        d.polygon([tip,(x+nx*s,y+ny*s),(x-nx*s,y-ny*s)],fill=255)
    head(335,1); head(155,1)
def sparkle(d,cx,cy,r,alpha=255):
    p=[]
    for i in range(8):
        a=math.pi/4*i; rr=r if i%2==0 else r*0.28
        p.append((cx+math.cos(a-math.pi/2)*rr, cy+math.sin(a-math.pi/2)*rr))
    d.polygon(p,fill=(255,255,255,alpha))
