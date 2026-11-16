import numpy as np, glob, json
from PIL import Image
D='/tmp/claude-tool-results/2dc1b62d-cf10-5a62-9f54-14b777c3deef/'
ids=[('244446','254532'),('262152','269958'),('276642','282781'),('289718','296050'),('302684','311923'),('318461','326004')]
def f(t): return glob.glob(D+f'mcp-remote-devices-blob-1794756{t}-*.jpg')[0]
S=1920/1999; CW,CH=647,411
icons=[]
for b,(k,w) in enumerate(ids):
    K=np.asarray(Image.open(f(k)).convert('RGB')).astype(np.float32)/255
    Wt=np.asarray(Image.open(f(w)).convert('RGB')).astype(np.float32)/255
    for c in range(6):
        tier=b*6+c+1
        if tier>35: break
        x0=int((10+(c%3)*(CW+12))*S)+2; y0=int((70+(c//3)*(CH+12))*S)+2
        x1=int(x0+CW*S)-4; y1=int(y0+CH*S)-4
        k_=K[y0:y1,x0:x1]; w_=Wt[y0:y1,x0:x1]
        a=1-(w_-k_).mean(axis=2)
        a=np.clip((a-0.05)/0.9,0,1)
        col=np.where(a[...,None]>0.02, np.clip(k_/np.maximum(a[...,None],1e-3),0,1), 0)
        ys,xs=np.where(a>0.1)
        pad=3
        cy0,cy1,cx0,cx1=max(ys.min()-pad,0),ys.max()+pad,max(xs.min()-pad,0),xs.max()+pad
        rgba=np.dstack([col,a])[cy0:cy1,cx0:cx1]
        # premultiply for resizing
        pm=rgba.copy(); pm[...,:3]*=pm[...,3:4]
        im=Image.fromarray((pm*255+0.5).astype(np.uint8),'RGBA')
        icons.append((tier,im,rgba.shape[1],rgba.shape[0]))
CELL=256; M=10
sheets=[]; meta={}
for i,(tier,im,w,h) in enumerate(icons):
    s=i//16; j=i%16
    while len(sheets)<=s: sheets.append(np.zeros((1024,1024,4),np.float32))
    sc=min((CELL-2*M)/w,(CELL-2*M)/h)
    nw,nh=max(1,round(w*sc)),max(1,round(h*sc))
    r=np.asarray(im.resize((nw,nh),Image.LANCZOS)).astype(np.float32)/255
    ox=(j%4)*CELL+(CELL-nw)//2; oy=(j//4)*CELL+(CELL-nh)//2
    sheets[s][oy:oy+nh,ox:ox+nw]=r
    meta[tier]=[s,(j%4)*CELL,(j//4)*CELL]
for s,a in enumerate(sheets):
    a=np.clip(a,0,1); al=a[...,3:4]
    rgb=np.where(al>0.003,a[...,:3]/np.maximum(al,1e-4),0)
    # bleed colour into transparent pixels to avoid dark fringes when Roblox filters
    out=np.dstack([np.clip(rgb,0,1),al[...,0]])
    Image.fromarray((out*255+0.5).astype(np.uint8),'RGBA').save(f'WeaponIcons_{s+1}.png')
json.dump(meta,open('meta.json','w'))
# preview on dark bg
for s in range(len(sheets)):
    im=Image.open(f'WeaponIcons_{s+1}.png'); bg=Image.new('RGBA',im.size,(30,34,60,255)); bg.alpha_composite(im); bg.convert('RGB').save(f'preview_{s+1}.jpg',quality=90)
print(len(icons),len(sheets))
