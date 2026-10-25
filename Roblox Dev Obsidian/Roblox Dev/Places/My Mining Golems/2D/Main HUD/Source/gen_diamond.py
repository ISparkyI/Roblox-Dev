from gen_own_icons import N,svg,ext,clip,poly
def PP(pts): return "M"+" L".join(f"{x:.1f} {y:.1f}" for x,y in pts)+"Z"
def lerp(a,b,t): return (a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t)
def dist(a,b): return ((a[0]-b[0])**2+(a[1]-b[1])**2)**.5
def along(V,to,d):  # point at distance d from V toward 'to' (along the facet edge)
    L=dist(V,to); return lerp(V,to,min(1,d/L))
def glint(V,tips,t=.16,fill="#fff"):
    """pack glint: vertex V where facet edges meet; arms run along those edges to sharp tips; between tips the contour dives
    straight (not curved) to an inner point close to V and comes back -> concave sharp star"""
    pts=[]
    for i,tp in enumerate(tips):
        nx=tips[(i+1)%len(tips)]
        pts.append(tp)
        if len(tips)==2 and i==1: break
        pts.append((V[0]+(tp[0]-V[0]+nx[0]-V[0])*t, V[1]+(tp[1]-V[1]+nx[1]-V[1])*t))
    if len(tips)==2: pts=[tips[0],(V[0]+(tips[0][0]-V[0]+tips[1][0]-V[0])*t,V[1]+(tips[0][1]-V[1]+tips[1][1]-V[1])*t),tips[1],V]
    return f'<path d="{PP(pts)}" fill="{fill}"/>'
# ---- exact facet geometry of the pack's Blue Diamond (256 canvas) ----
SIL=[(64,45),(129,31),(192,45),(233,78),(241,113),(129,234),(16,113),(22,79)]
F={ "top":[(66,43),(129,31),(190,43),(195,66),(125,83),(85,73),(64,65),(64,50)],
    "band":[(16,113),(83,134),(120,138),(127,103),(127,85),(80,73),(61,72),(49,79)],
    "pavL":[(17,115),(127,234),(127,149)],
    "midR":[(241,113),(196,68),(129,85),(129,147)],
    "upL":[(64,45),(22,79),(15,111),(58,66)],
    "pavR":[(240,115),(129,149),(129,234)],
    "upR":[(192,45),(199,69),(241,110),(233,78)]}
COL_BLUE={"base":"#33b6ff","top":"#33b6ff","band":"#4dc9ff","pavL":"#33b6ff","midR":"#33a8ff","upL":"#33a8ff","pavR":"#3386ff","upR":"#3386ff"}
def diamond_group(col,tf="",sw=20,depth=0,side="#1b5fc4",glints=True):
    sh=PP(SIL); cp="d%d"%(abs(hash((tf,depth)))%9999)
    g=f'<clipPath id="{cp}"><path d="{sh}"/></clipPath>'
    s=f'<g transform="{tf}">'
    if depth: s+=ext(sh,depth,-1,-1,side,sw)
    else: s+=f'<path d="{sh}" fill="{N}" stroke="{N}" stroke-width="{sw}" stroke-linejoin="round"/>'
    s+=f'<path d="{sh}" fill="{col["base"]}"/>'
    for k in ("top","band","pavL","midR","upL","pavR","upR"): s+=poly(F[k],col[k],cp)
    if glints:
        # big glint: vertex where centre edge meets lower edge of the band; arms along both edges
        V=(128,148); s+=glint(V,[along(V,(127,85),40),along(V,(16,113),38)])
        # small 3-arm glint: vertex of the band's upper-left corner; arms along the three facet edges meeting there
        V2=(61,71); s+=glint(V2,[along(V2,(64,50),14),along(V2,(49,79),15),along(V2,(85,73),17)],.2)
    s+='</g>'
    return g,s
def v_pair():
    g1,s1=diamond_group(COL_BLUE,"translate(120 18) scale(.5)",sw=26,glints=True)
    g2,s2=diamond_group(COL_BLUE,"translate(0 48) scale(.8)",sw=22)
    return svg(s1+s2,g1+g2)
def v_3d():
    g,s=diamond_group(COL_BLUE,"translate(10 8) rotate(-12 128 128) scale(.93)",sw=21,depth=9)
    return svg(s,g)
# rhomb gem: outer rhombus + inner table, glints at real vertices
def v_rhomb():
    T,R,B,L=(128,18),(210,128),(128,238),(46,128)
    t,r,b,l=(128,66),(172,128),(128,190),(84,128)
    sh=PP([T,R,B,L]); cp="rh"
    s=f'<clipPath id="{cp}"><path d="{sh}"/></clipPath>'
    s+=f'<path d="{sh}" fill="{N}" stroke="{N}" stroke-width="20" stroke-linejoin="round"/><path d="{sh}" fill="#33a8ff"/>'
    s+=poly([T,L,l,t],"#4dc9ff",cp)+poly([T,R,r,t],"#33b6ff",cp)+poly([L,B,b,l],"#33a8ff",cp)+poly([R,B,b,r],"#3386ff",cp)
    s+=poly([t,r,b,l],"#6fd9ff",cp)+poly([t,r,(128,128)],"#8de4ff",cp)
    s+=glint(t,[along(t,T,34),along(t,l,40),along(t,r,40)],.17)
    s+=glint(l,[along(l,L,24),along(l,b,36)],.2)
    return svg(s,"")
def variants(): return {"dia_A":v_pair(),"dia_B":v_3d(),"dia_C":v_rhomb()}
def pack_like():
    g,s=diamond_group(COL_BLUE); return svg(s,g)
if __name__=="__main__":
    out=variants(); out["dia_ref"]=pack_like()
    for k,v in out.items(): open(k+".svg","w").write(v)
    html='<body style="margin:0;background:#4a3a30;display:flex;gap:20px;padding:20px;align-items:end">'
    for k,v in out.items(): html+=f'<div style="text-align:center;color:#fff;font:12px sans-serif">{v}<br><div style="width:42px;height:42px;margin:6px auto">{v.replace("width=\"256\" height=\"256\"","width=\"42\" height=\"42\"")}</div>{k}</div>'
    html+='<div><img src="file:///mnt/user-data/uploads/Roblox Dev Obsidian/Roblox Dev/Style/Preview/Free Icon Pack v3.1 (Basic)/Currency/Diamond/256px/Blue Diamond 1st Outline 256px.png" width=256><div style="color:#fff;font:12px sans-serif;text-align:center">пак</div></div>'
    open("sheet.html","w").write(html)
