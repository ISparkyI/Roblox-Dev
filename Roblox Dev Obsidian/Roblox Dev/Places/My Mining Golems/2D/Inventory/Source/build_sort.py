# Збирає sort_mock.html: sort_template.html + helpers.js (з inventory_filter) + асети (StyleA, іконки з чорним контуром, голови големів) + шрифти + дані каталогу
import base64,json,os,io
from PIL import Image
HERE=os.path.dirname(os.path.abspath(__file__)); UI=os.path.join(HERE,"..")
V="/mnt/user-data/uploads/Roblox Dev Obsidian/Roblox Dev"; S=V+"/Style/Roblox/"
def d(p,size=None):
    if size:
        im=Image.open(p).convert("RGBA"); im.thumbnail((size,size),Image.LANCZOS); b=io.BytesIO(); im.save(b,"PNG"); raw=b.getvalue()
    else: raw=open(p,"rb").read()
    return "data:image/png;base64,"+base64.b64encode(raw).decode()
A={}
for c in ["green","gray","red","blue","yellow"]: A["base_"+c]=d(S+f"stylea_base_{c}.png")
for c in ["green","gray","red"]: A["tile_"+c]=d(S+f"stylea_tile_{c}.png")
for c in ["blue","yellow","green","gray"]: A["tile_"+c+"_half"]=d(S+f"stylea_tile_{c}_half.png")
A["icon_x"]=d(S+"stylea_icon_x.png",128)
B=os.path.join(UI,"inventory_black")
for n in ["tab_golems","tab_orebars","tab_potions","icon_trash","icon_lock"]: A[n]=d(os.path.join(B,"inv_"+n+".png"),192)
for k in ["all","miner","carrier","warrior"]: A["class_"+k]=d(os.path.join(B,f"inv_class_{k}.png"),128)
A["title_backpack"]=d(os.path.join(B,"inv_title_backpack.png"),256)
for k in ["stone","wood","iron","gold","crystal"]: A["golem_"+k]=d(os.path.join(UI,"inventory",f"golem_{k}.png"),200)
fd="/tmp/fonts/node_modules/@fontsource/montserrat/files/montserrat-latin-%s-normal.woff2"
f=lambda w: base64.b64encode(open(fd%w,"rb").read()).decode()
t=open(os.path.join(HERE,"sort_template.html")).read()
t=(t.replace("__HELPERS__",open(os.path.join(UI,"inventory_filter","helpers.js")).read()).replace("__ASSETS__",json.dumps(A))
    .replace("__CATALOG__",open(os.path.join(HERE,"catalog.json")).read()).replace("__SORTICON__",json.dumps(d(os.path.join(HERE,"sort_icon.png"))))
    .replace("__F800__",f(800)).replace("__F900__",f(900)))
open(os.path.join(HERE,"sort_mock.html"),"w").write(t); print(len(t))
