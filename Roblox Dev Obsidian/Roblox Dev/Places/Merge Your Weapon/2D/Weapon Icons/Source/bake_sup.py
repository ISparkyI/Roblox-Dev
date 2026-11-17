import numpy as np, glob
from PIL import Image
D='/tmp/claude-tool-results/2dc1b62d-cf10-5a62-9f54-14b777c3deef/'
def f(t): return glob.glob(D+f'mcp-remote-devices-blob-1794756{t}-*.jpg')[0]
pairs=[('683873','695032',8),('708852','714990',2)]
S=1920/1999; C=411
ids=['Bandage','EnergyDrink','Mine','Medkit','Grenade','Molotov','BodyArmor','IceGrenade','KamikazeDrone','Turret']
icons=[]
for k,w,n in pairs:
    K=np.asarray(Image.open(f(k)).convert('RGB')).astype(np.float32)/255
    W=np.asarray(Image.open(f(w)).convert('RGB')).astype(np.float32)/255
    for c in range(n):
        x0=int((10+(c%4)*(C+12))*S)+2; y0=int((70+(c//4)*(C+12))*S)+2
        x1=int(x0+C*S)-3; y1=min(int(y0+C*S)-3,K.shape[0])
        kk=K[y0:y1,x0:x1]; ww=W[y0:y1,x0:x1]
        a=np.clip((1-(ww-kk).mean(axis=2)-0.05)/0.9,0,1)
        col=np.where(a[...,None]>0.02,np.clip(kk/np.maximum(a[...,None],1e-3),0,1),0)
        ys,xs=np.where(a>0.1); p=3
        rgba=np.dstack([col,a])[max(ys.min()-p,0):ys.max()+p,max(xs.min()-p,0):xs.max()+p]
        pm=rgba.copy(); pm[...,:3]*=pm[...,3:4]
        icons.append(Image.fromarray((pm*255+0.5).astype(np.uint8),'RGBA'))
CELL=256; M=10
sheet=np.zeros((1024,1024,4),np.float32)
for i,im in enumerate(icons):
    w,h=im.size; sc=min((CELL-2*M)/w,(CELL-2*M)/h)
    nw,nh=round(w*sc),round(h*sc)
    r=np.asarray(im.resize((nw,nh),Image.LANCZOS)).astype(np.float32)/255
    ox=(i%4)*CELL+(CELL-nw)//2; oy=(i//4)*CELL+(CELL-nh)//2
    sheet[oy:oy+nh,ox:ox+nw]=r
al=sheet[...,3:4]; rgb=np.where(al>0.003,sheet[...,:3]/np.maximum(al,1e-4),0)
Image.fromarray((np.dstack([np.clip(rgb,0,1),al[...,0]])*255+0.5).astype(np.uint8),'RGBA').save('SupplyIcons.png')
im=Image.open('SupplyIcons.png'); bg=Image.new('RGBA',im.size,(30,34,60,255)); bg.alpha_composite(im); bg.convert('RGB').save('preview_supplies.jpg',quality=90)
print(len(icons))
