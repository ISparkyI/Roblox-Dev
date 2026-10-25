from playwright.sync_api import sync_playwright
from PIL import Image
import sys,glob,os
names=[os.path.basename(f)[:-4] for f in sorted(glob.glob("*.svg"))]
with sync_playwright() as p:
    b=p.chromium.launch(); pg=b.new_page(viewport={'width':512,'height':512})
    for n in names:
        svg=open(f"{n}.svg").read().replace('width="256" height="256"','width="512" height="512"')
        pg.set_content(f'<body style="margin:0;background:transparent">{svg}</body>'); pg.wait_for_timeout(60)
        pg.screenshot(path=f"/tmp/{n}_raw.png",omit_background=True,clip={'x':0,'y':0,'width':512,'height':512})
        im=Image.open(f"/tmp/{n}_raw.png").convert("RGBA"); bb=im.getbbox(); im=im.crop(bb)
        S=512; m=int(S*0.02); sc=(S-2*m)/max(im.size); im2=im.resize((round(im.size[0]*sc),round(im.size[1]*sc)),Image.LANCZOS)
        out=Image.new("RGBA",(S,S),(0,0,0,0)); out.paste(im2,((S-im2.size[0])//2,(S-im2.size[1])//2),im2); out.save(f"{n}.png")
    b.close()
print(names)
