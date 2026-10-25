import base64,json,os
V="/mnt/user-data/uploads/Roblox Dev Obsidian/Roblox Dev"
S=V+"/Style/Roblox/"; F=V+"/Places/My Mining Golems/Interactive Objects/Forge/Roblox/"; HUD=V+"/Places/My Mining Golems/2D/Main HUD/Roblox/Import/"
HERE=os.path.dirname(os.path.abspath(__file__))
def d(p): return "data:image/png;base64,"+base64.b64encode(open(p,"rb").read()).decode()
A={}
for c in ["green","gray","red","blue","yellow","orange"]: A["base_"+c]=d(S+f"stylea_base_{c}.png")
for c in ["green","gray","red"]: A["tile_"+c]=d(S+f"stylea_tile_{c}.png")
for c in ["blue","yellow","orange","green","gray"]: A["tile_"+c+"_half"]=d(S+f"stylea_tile_{c}_half.png")
A["icon_x"]=d(S+"stylea_icon_x.png")
for k,f in [("Coal","forge_ore_coal_v2"),("Copper","forge_ore_copper_v2"),("Iron","forge_ore_iron_v2")]: A["ore_"+k]=d(F+f+".png")
for k,f in [("Coal","forge_bar_coal"),("Copper","forge_bar_copper"),("Iron","forge_bar_iron_v2")]: A["bar_"+k]=d(F+f+".png")
for k in ["inventory","settings","invite"]: A["hud_"+k]=d(HUD+f"hud_{k}.png")
for n in ["tab_golems","tab_orebars","tab_potions","icon_trash","icon_lock"]+["golem_"+k for k in ["stone","wood","iron","gold","crystal"]]+["potion_"+k for k in ["purple","green","blue","gold","red"]]:
    A[n]=d(os.path.join(HERE,n+".png"))
fd="/tmp/fonts/node_modules/@fontsource/montserrat/files/montserrat-latin-%s-normal.woff2"
f=lambda w: base64.b64encode(open(fd%w,"rb").read()).decode()
t=open(os.path.join(HERE,"inv_template.html")).read()
t=t.replace("__HELPERS__",open(os.path.join(HERE,"helpers.js")).read()).replace("__ASSETS__",json.dumps(A)).replace("__F800__",f(800)).replace("__F900__",f(900))
open(os.path.join(HERE,"inventory_mock.html"),"w").write(t); print(len(t))
