import base64,json,os
V="/mnt/user-data/uploads/Roblox Dev Obsidian/Roblox Dev"
S=V+"/Style/Roblox/"; F=V+"/Places/My Mining Golems/Interactive Objects/Forge/Roblox/"
def d(p): return "data:image/png;base64,"+base64.b64encode(open(p,"rb").read()).decode()
A={}
for c in ["green","gray","red","blue","yellow","orange","ore_coal","ore_copper","ore_iron"]:
    A["base_"+c]=d(S+f"stylea_base_{c}.png")
for c in ["green","gray","red"]: A["tile_"+c]=d(S+f"stylea_tile_{c}.png")
for c in ["blue","yellow","orange","green","gray","ore_coal","ore_copper","ore_iron"]: A["tile_"+c+"_half"]=d(S+f"stylea_tile_{c}_half.png")
A["icon_x"]=d(S+"stylea_icon_x.png")
for k,f in [("Coal","forge_ore_coal_v2"),("Copper","forge_ore_copper_v2"),("Iron","forge_ore_iron_v2")]: A["ore_"+k]=d(F+f+".png")
for k,f in [("Coal","forge_bar_coal"),("Copper","forge_bar_copper"),("Iron","forge_bar_iron_v2")]: A["bar_"+k]=d(F+f+".png")
fd="/tmp/fonts/node_modules/@fontsource/montserrat/files/montserrat-latin-%s-normal.woff2"
f=lambda w: base64.b64encode(open(fd%w,"rb").read()).decode()
t=open("/mnt/user-data/outputs/ui/sell_window/sell_template4.html").read().replace("__ASSETS__",json.dumps(A)).replace("__F800__",f(800)).replace("__F900__",f(900))
open("/mnt/user-data/outputs/ui/sell_window/sell_window_v4.html","w").write(t); print(len(t))
