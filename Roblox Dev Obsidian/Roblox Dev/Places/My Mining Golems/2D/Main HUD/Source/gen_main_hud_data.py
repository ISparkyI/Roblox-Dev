import base64, io, json
from PIL import Image
P="/mnt/user-data/uploads/Roblox Dev Obsidian/Roblox Dev/Style/Preview/Free Icon Pack v3.1 (Basic)/"
A="/mnt/user-data/outputs/ui/buttons_v2/assets/"
def webp(path,size=160):
    im=Image.open(path).convert("RGBA").resize((size,size),Image.LANCZOS)
    b=io.BytesIO(); im.save(b,"WEBP",quality=90,method=6); return "data:image/webp;base64,"+base64.b64encode(b.getvalue()).decode()
def png(path):
    return "data:image/png;base64,"+base64.b64encode(open(path,"rb").read()).decode()
ICONS={ # key: (file, label for table)
 "shop":"Main/Shopping Cart/256px/Red Shopping Cart 1st Outline 256px.png",
 "index":"Item/Book/256px/Blue Book 1st Outline 256px.png",
 "quests":"Item/Scroll/256px/Scroll 1st Outline 256px.png",
 "rebirth":"Main/Rebirth and Auto Open/256px/Rebirth 1st Outline 256px.png",
 "diamond":"Currency/Diamond/256px/Blue Diamond 1st Outline 256px.png",
 "ticket":"Currency/Ticket/256px/Golden Ticket 1st Outline 256px.png",
 "boss":"Player/Skull/256px/Skull 1st Outline 256px.png",
 "multi":"Currency/Cash/256px/Green Cash 1st Outline 256px.png",
 "robux":"Currency/Robux/256px/Green Robux 1st Outline 256px.png",
 "invite":"Player/Add Player/256px/Add Player 1st Outline 256px.png",
 "settings":"Main/Settings/256px/Settings 1 1st Outline 256px.png",
 "inventory":"Item/Backpack/256px/Backpack 1st Outline 256px.png",
 "feedback":"UI/Chat/256w/Chat 1st Outline 256px.png",
 "codes":"Main/Codes/256px/Codes 1st Outline 256px.png",
 "updates":"Item/Newspaper/256px/Newspaper 1st Outline 256px.png",
}
CAND={
 "Feedback":[("Heart","Main/Heart/256px/Heart 1st Outline 256px.png"),("Gold Heart","Main/Heart/256px/Golden Heart 1st Outline 256px.png"),("Blue Star","Main/Star/256px/Blue Star 1st Outline 256px.png"),("Yellow Pencil","Item/Pencil/256px/Yellow Pencil 1st Outline 256px.png"),("Info","UI/Info/256px/Info 1st Outline 256px.png")],
 "Codes":[("Red Gift","Item/Gift/256px/Red Gift 1st Outline 256px.png"),("Green Gift","Item/Gift/256px/Green Gift 1st Outline 256px.png"),("Gold Key","Item/Key/256px/Golden Key 1st Outline 256px.png"),("Blue Key","Item/Key/256px/Blue Key 1st Outline 256px.png"),("Codes (старий)","Main/Codes/256px/Codes 1st Outline 256px.png")],
 "Updates":[("Rocket","Item/Rocket/256px/Rocket 1st Outline 256px.png"),("Gold Calendar","Item/Calendar/256px/Golden Calendar 1st Outline 256px.png"),("Exclamation","UI/Exclamation Mark/256px/Exclamation Mark 1st Outline 256px.png"),("Green Upgrade","Main/Upgrade/256px/Green Upgrade 1st Outline 256px.png"),("Newspaper (старий)","Item/Newspaper/256px/Newspaper 1st Outline 256px.png")],
}
ICONS["feedback"]=CAND["Feedback"][0][1];ICONS["codes"]=CAND["Codes"][0][1];ICONS["updates"]=CAND["Updates"][0][1]
G="../gen/"
OWN={"feedback":"власний: бульбашка з серцем","codes":"власний: білий купон із зіркою","updates":"власний: мегафон"}
ASP={}
def webp_fit(path,size=160,key=None):
    im=Image.open(path).convert("RGBA"); bb=im.getbbox(); im=im.crop(bb)
    asp=im.width/im.height; w=round(size*asp)
    c=im.resize((w,size),Image.LANCZOS)
    if key: ASP[key]=asp
    b=io.BytesIO(); c.save(b,"WEBP",quality=90,method=6); return "data:image/webp;base64,"+base64.b64encode(b.getvalue()).decode()
TOP=["invite","settings","inventory","feedback","codes","updates"]
icons={k:(webp_fit(P+v,key=k) if k in TOP else webp(P+v)) for k,v in ICONS.items()}
files=dict(ICONS)
for k,t in OWN.items():
    icons[k]=webp_fit(G+k+".png",key=k); files[k]=t
icons["ticket"]=webp(G+"ticket_D.png"); files["ticket"]="власний: золотий вертикальний тікет із зіркою "
# counter icons: bbox-fitted copies so all counters get the same height and stay inside the plate
for k,pth in [("c_diamond",G+"dia_C.png"),("c_ticket",G+"ticket_D.png"),("c_rebirth",P+ICONS["rebirth"])]:
    icons[k]=webp_fit(pth,key=k)
icons["diamond"]=webp(G+"dia_C.png"); files["diamond"]="власний: ромбовидний кристал (діаманти)"
data={"icons":icons,"files":files,"asp":ASP}
json.dump(data,open("data.json","w"))
