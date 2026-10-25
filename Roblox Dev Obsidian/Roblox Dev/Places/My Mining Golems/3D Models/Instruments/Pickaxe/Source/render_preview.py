"""Прев'ю кірки: простий z-buffer растеризатор (2 ракурси), підтримує повернуті блоки."""
import json, numpy as np
from PIL import Image, ImageDraw, ImageFont
D = json.load(open("pickaxe_blocks.json")); sh = np.zeros(3)
L = np.array([-0.45, 0.8, 0.55]); L /= np.linalg.norm(L)
def hexrgb(h): return np.array([int(h[i:i+2],16) for i in (1,3,5)], float)
tris = []
for b in D["blocks"]:
    c=np.array(b["c"]); s_=np.array(b["s"]); R=np.array(b["R"])
    col=hexrgb(D["colors"][b["col"]])
    for ax in range(3):
        for sg in (1,-1):
            o=[i for i in range(3) if i!=ax]; q=[]
            for a_,bb in [(0,0),(1,0),(1,1),(0,1)]:
                p=np.zeros(3); p[ax]=sg*0.5; p[o[0]]=a_-0.5; p[o[1]]=bb-0.5
                q.append(R@(p*s_)+c)
            n=np.zeros(3); n[ax]=sg; n=R@n
            shade=0.58+0.42*max(0,n@L)
            tris += [(q[0],q[1],q[2],col*shade),(q[0],q[2],q[3],col*shade)]
def render(yaw, W=640, H=520, pitch=0.42, scale=36):
    cy,sy=np.cos(yaw),np.sin(yaw); cp,sp=np.cos(pitch),np.sin(pitch)
    R=np.array([[cy,0,-sy],[0,1,0],[sy,0,cy]]); P=np.array([[1,0,0],[0,cp,-sp],[0,sp,cp]])@R
    img=np.zeros((H,W,3)); img[:]=(32,36,42); zb=np.full((H,W),-1e9)
    for a,b,c,col in tris:
        pts=[]
        for p in (a,b,c):
            v=P@(p-np.array([0,4.0,1.5])); pts.append((W/2+v[0]*scale, H/2-v[1]*scale, v[2]))
        (x0,y0,z0),(x1,y1,z1),(x2,y2,z2)=pts
        den=(y1-y2)*(x0-x2)+(x2-x1)*(y0-y2)
        if abs(den)<1e-9: continue
        xmin,xmax=int(max(0,min(x0,x1,x2))),int(min(W-1,max(x0,x1,x2)))+1
        ymin,ymax=int(max(0,min(y0,y1,y2))),int(min(H-1,max(y0,y1,y2)))+1
        if xmin>=xmax or ymin>=ymax: continue
        X,Y=np.meshgrid(np.arange(xmin,xmax)+0.5,np.arange(ymin,ymax)+0.5)
        w0=((y1-y2)*(X-x2)+(x2-x1)*(Y-y2))/den; w1=((y2-y0)*(X-x2)+(x0-x2)*(Y-y2))/den; w2=1-w0-w1
        m=(w0>=-1e-6)&(w1>=-1e-6)&(w2>=-1e-6)
        Z=w0*z0+w1*z1+w2*z2
        sub=zb[ymin:ymax,xmin:xmax]; upd=m&(Z>sub)
        sub[upd]=Z[upd]; img[ymin:ymax,xmin:xmax][upd]=col
    return Image.fromarray(np.clip(img,0,255).astype(np.uint8))
# yaw: камера дивиться з +Z (спереду) при yaw=0; z у камері — до глядача
try:
    FONT=ImageFont.truetype("DejaVuSans.ttf",20)
except OSError:
    FONT=ImageFont.load_default()
views=[(1.2,"Збоку"),(0.5+np.pi,"Ззаду")]
ims=[render(-y) for y,_ in views]
out=Image.new("RGB",(ims[0].width*2,ims[0].height),(32,36,42))
for i,(im,(_,t)) in enumerate(zip(ims,views)):
    out.paste(im,(i*im.width,0)); ImageDraw.Draw(out).text((i*im.width+16,12),t,fill=(230,230,230),font=FONT)
out.save("pickaxe_preview.png")
