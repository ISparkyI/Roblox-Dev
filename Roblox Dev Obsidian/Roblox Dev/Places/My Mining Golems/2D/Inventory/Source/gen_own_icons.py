import math
N="#040435"
def svg(inner,d=""): return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256"><defs>{d}</defs>{inner}</svg>'
def ext(path,depth,dx,dy,side,sw=26):
    o=''.join(f'<path d="{path}" transform="translate({dx*k},{dy*k})"/>' for k in range(0,depth+1))
    return f'<g fill="{N}" stroke="{N}" stroke-width="{sw}" stroke-linejoin="round">{o}</g><g fill="{side}" stroke="{side}" stroke-width="1" stroke-linejoin="round">{o}</g>'
def wedge(cx,cy,u1,u2,l1,l2,k=.21,fill="#fff"):
    """pack-style corner glint: sharp white sliver hugging two edges that meet at (cx,cy)"""
    t1=(cx+u1[0]*l1,cy+u1[1]*l1); t2=(cx+u2[0]*l2,cy+u2[1]*l2)
    c=(cx+(u1[0]*l1+u2[0]*l2)*k,cy+(u1[1]*l1+u2[1]*l2)*k)
    return f'<path d="M{cx:.1f} {cy:.1f} L{t1[0]:.1f} {t1[1]:.1f} L{c[0]:.1f} {c[1]:.1f} L{t2[0]:.1f} {t2[1]:.1f}Z" fill="{fill}"/>'
def clip(i,p): return f'<clipPath id="{i}"><path d="{p}"/></clipPath>'
def poly(pts,fill,cid=None):
    g=f' clip-path="url(#{cid})"' if cid else ''
    return f'<path d="M{" L".join(f"{x} {y}" for x,y in pts)}Z" fill="{fill}"{g}/>'
E=(1,0);S=(0,1);W=(-1,0);Nn=(0,-1)

bub="M70 58 H186 Q218 58 218 90 V144 Q218 176 186 176 H168 L190 220 L112 176 H70 Q38 176 38 144 V90 Q38 58 70 58Z"
def feedback():
    d=clip("cb",bub)
    s=ext(bub,10,-1,-1,"#6fc8d2")+f'<path d="{bub}" fill="#cdeefa"/>'
    s+=poly([(30,40),(150,40),(74,150),(30,150)],"#e6f8fe","cb")+poly([(30,146),(230,134),(230,230),(30,230)],"#a6dbee","cb")
    s+=poly([(182,40),(230,40),(230,230),(198,230)],"#b6e3f3","cb")
    h="M128 154 C96 132 84 114 84 98 C84 82 96 74 108 74 C118 74 125 79 128 86 C131 79 138 74 148 74 C160 74 172 82 172 98 C172 114 160 132 128 154Z"
    s+=f'<path d="{h}" fill="{N}" stroke="{N}" stroke-width="12" stroke-linejoin="round"/><path d="{h}" fill="#ff4f78"/>'
    s+=f'<clipPath id="ch"><path d="{h}"/></clipPath>'+poly([(128,60),(190,60),(190,170),(128,170)],"#d8214b","ch")
    s+='<g clip-path="url(#ch)"><path d="M114 80 C96 83 87 104 92 130 C95 106 102 92 114 80Z" fill="#fff"/></g>'
    s+='<g clip-path="url(#cb)">'+wedge(48,66,E,S,34,32)+wedge(210,168,W,Nn,24,22)+'</g>'
    return svg(s,d)

tk="M48 94 H188 Q198 94 198 104 V116 A12 12 0 0 0 198 140 V152 Q198 162 188 162 H48 Q38 162 38 152 V140 A12 12 0 0 0 38 116 V104 Q38 94 48 94Z"
STAR="M62 92 L69 106 L84 108 L73 118 L76 133 L62 126 L48 133 L51 118 L40 108 L55 106Z"
def star(cx,cy,sc,l,r,ol):
    tr=f"translate({cx},{cy}) scale({sc}) translate(-62,-114)"
    return (f'<g transform="{tr}"><path d="{STAR}" fill="{ol}" stroke="{ol}" stroke-width="9" stroke-linejoin="round"/><path d="{STAR}" fill="{l}"/>'
            f'<clipPath id="cs{int(cx)}{int(cy)}"><path d="{STAR}"/></clipPath><path d="M62 80 L100 80 L100 140 L62 140Z" fill="{r}" clip-path="url(#cs{int(cx)}{int(cy)})"/></g>')
def codes():
    d=clip("ct",tk)
    s='<g transform="rotate(-24 128 128)">'+ext(tk,9,-1,-1,"#8fa2cf")+f'<path d="{tk}" fill="#dfe6f8"/>'
    s+=poly([(30,80),(130,80),(100,160),(30,160)],"#eef2fd","ct")+poly([(30,140),(210,132),(210,170),(30,170)],"#c2ccea","ct")
    s+='<path d="M92 104 V152" stroke="#9fb0d6" stroke-width="4" stroke-dasharray="7 7" stroke-linecap="round"/>'
    s+=star(68,128,.74,"#ffd23a","#ff9f1c","#b85f08")
    for i in range(3): s+=f'<rect x="{108+i*21}" y="112" width="15" height="15" rx="4.5" fill="{N}"/>'
    s+='<rect x="108" y="135" width="58" height="8" rx="4" fill="#ff5c86"/>'
    s+='<g clip-path="url(#ct)">'+wedge(44,100,E,S,30,18)+wedge(192,156,W,Nn,22,16)+'</g>'
    s+='</g>'
    return svg(s,d)

def updates():
    body="M58 104 L166 66 L166 190 L58 152Z"
    cap="M34 100 Q34 92 42 92 H66 V164 H42 Q34 164 34 156Z"
    handle="M76 150 L110 160 L120 214 Q121 224 111 224 L92 224 Q82 224 82 214Z"
    d=clip("cb2",body)+clip("cc2",cap)+'<clipPath id="ce2"><ellipse cx="170" cy="128" rx="26" ry="68"/></clipPath>'
    s='<g transform="rotate(-16 128 128)">'
    waves=["M204 100 Q222 128 204 156","M224 78 Q256 128 224 178"]
    for p in waves: s+=f'<path d="{p}" fill="none" stroke="{N}" stroke-width="22" stroke-linecap="round"/>'
    for p in waves: s+=f'<path d="{p}" fill="none" stroke="#3aa6ff" stroke-width="9" stroke-linecap="round"/>'
    s+=f'<g fill="{N}" stroke="{N}" stroke-width="26" stroke-linejoin="round"><path d="{handle}"/><path d="{cap}"/><path d="{body}"/><ellipse cx="170" cy="128" rx="26" ry="68"/></g>'
    s+=f'<path d="{handle}" fill="#8fd6de"/><path d="M96 158 L110 160 L120 214 Q121 224 111 224 L100 224Z" fill="#5fb7c4"/>'
    s+=f'<path d="{cap}" fill="#ff4f78"/>'+poly([(30,130),(70,130),(70,170),(30,170)],"#c4123b","cc2")
    s+=f'<path d="{body}" fill="#e9f6fd"/>'+poly([(50,124),(170,118),(170,200),(50,200)],"#b3d8ee","cb2")
    s+='<ellipse cx="170" cy="128" rx="26" ry="68" fill="#ffffff"/><ellipse cx="174" cy="128" rx="17" ry="54" fill="#3aa6ff"/>'
    s+='<path d="M174 74 A17 54 0 0 1 174 182 A8 54 0 0 0 174 74Z" fill="#1f86e0"/>'
    s+='<g clip-path="url(#cb2)">'+wedge(60,106,(0.943,-0.332),S,46,22)+'</g><g clip-path="url(#cc2)">'+wedge(40,94,E,S,20,16,.1,"#ffd0da")+'</g>'
    s+='<g clip-path="url(#ce2)"><path d="M170 62 Q192 58 198 94 Q186 76 170 62Z" fill="#fff"/></g>'
    s+='</g>'
    return svg(s,d)

TKT="M82 52 H108 A20 20 0 0 0 148 52 H174 Q186 52 186 64 V192 Q186 204 174 204 H148 A20 20 0 0 0 108 204 H82 Q70 204 70 192 V64 Q70 52 82 52Z"
def ticket():
    d=clip("ck",TKT)
    s='<g transform="rotate(14 128 128)">'+ext(TKT,10,-1,-1,"#d4780f")+f'<path d="{TKT}" fill="#ffbd2b"/>'
    s+=poly([(60,176),(196,164),(196,214),(60,214)],"#f59a1c","ck")+poly([(60,40),(112,40),(86,150),(60,150)],"#ffd35c","ck")
    s+='<path d="M88 96 H168" stroke="#c96d10" stroke-width="4" stroke-dasharray="7 7" stroke-linecap="round" opacity=".8"/>'
    s+=star(128,138,1.6,"#fff2b8","#ffd36a","#b85f08")
    s+='<g clip-path="url(#ck)">'+wedge(76,58,E,S,34,44)+wedge(180,198,W,Nn,26,26)+'</g>'
    s+='</g>'
    return svg(s,d)
if __name__=="__main__":
    out={"feedback":feedback(),"codes":codes(),"updates":updates(),"ticket_D":ticket()}
    for k,v in out.items(): open(k+".svg","w").write(v)
    html='<body style="margin:0;background:#4a3a30;display:flex;gap:20px;padding:20px;align-items:end">'
    for k,v in out.items(): html+=f'<div style="text-align:center;color:#fff;font:12px sans-serif">{v}<br><div style="width:42px;height:42px;margin:6px auto">{v.replace("width=\"256\" height=\"256\"","width=\"42\" height=\"42\"")}</div>{k}</div>'
    open("sheet.html","w").write(html)
