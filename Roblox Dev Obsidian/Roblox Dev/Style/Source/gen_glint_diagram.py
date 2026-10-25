import math,os
from playwright.sync_api import sync_playwright
def pt(V,ang,l): return (V[0]+math.cos(math.radians(ang))*l, V[1]+math.sin(math.radians(ang))*l)
def P(pts): return " ".join(f"{x:.1f},{y:.1f}" for x,y in pts)
def inner(V,tips,k): return (V[0]+sum(t[0]-V[0] for t in tips)*k, V[1]+sum(t[1]-V[1] for t in tips)*k)
def glintpoly(V,tips,k):
    pts=[];n=len(tips)
    for i,t in enumerate(tips):
        nx=tips[(i+1)%n]; pts.append(t); pts.append((V[0]+(t[0]-V[0]+nx[0]-V[0])*k, V[1]+(t[1]-V[1]+nx[1]-V[1])*k))
    return pts
def text(x,y,s,sz=16,c="#e8eef8",w=500): return f'<text x="{x}" y="{y}" font-size="{sz}" fill="{c}" font-weight="{w}" font-family="DejaVu Sans, Arial, sans-serif">{s}</text>'
S=[]
def frame(x,title):
    S.append(f'<rect x="{x}" y="16" width="500" height="648" rx="10" fill="#262c36"/>'); S.append(text(x+20,50,title,20,"#fff",700))
def dot(p,c="#ff5c86",r=7,lab=None,dx=10,dy=-10):
    S.append(f'<circle cx="{p[0]:.0f}" cy="{p[1]:.0f}" r="{r}" fill="{c}" stroke="#040435" stroke-width="2"/>')
    if lab: S.append(f'<text x="{p[0]+dx:.0f}" y="{p[1]+dy:.0f}" font-size="18" font-weight="700" fill="#fff" stroke="#040435" stroke-width="4" paint-order="stroke" font-family="DejaVu Sans, Arial, sans-serif">{lab}</text>')
def facets(x,y,w,h,V,angs,cols,inner_cols=None):
    """nested svg clipped to the area; facets are wedges around V between consecutive edge rays"""
    out=f'<svg x="{x}" y="{y}" width="{w}" height="{h}" viewBox="{x} {y} {w} {h}">'
    n=len(angs); R=900
    ends=[pt(V,a,R) for a in angs]
    for i in range(n):
        a=ends[i]; b=ends[(i+1)%n]
        # polygon: V, end_i, corner-ish far point (mid angle), end_next
        ma=(angs[i]+((angs[(i+1)%n]-angs[i])%360)/2)
        m=pt(V,ma,R*1.3)
        out+=f'<polygon points="{P([V,a,m,b])}" fill="{cols[i]}"/>'
    return out
def two_facets(fx,fy,w,h,V,e2y_at_left):
    return (f'<polygon points="{P([(fx,fy),(V[0],fy),V,(fx,e2y_at_left)])}" fill="#4dc9ff"/>'
            f'<polygon points="{P([(fx,e2y_at_left),V,(V[0],fy+h),(fx,fy+h)])}" fill="#33a8ff"/>'
            f'<polygon points="{P([(V[0],fy),(fx+w,fy),(fx+w,fy+h),(V[0],fy+h),V])}" fill="#3386ff"/>')
def panel_two(x0):
    frame(x0,"1. Блик у вершині: два ребра")
    fx,fy,w,h=x0+20,80,460,440; V=(x0+250,400)
    S.append(f'<svg x="{fx}" y="{fy}" width="{w}" height="{h}" viewBox="{fx} {fy} {w} {h}">'+two_facets(fx,fy,w,h,V,333))
    T1=(V[0],V[1]-190);T2=pt(V,-163,170);I=inner(V,[T1,T2],0.17)
    S.append(f'<polygon points="{P([T1,I,T2,V])}" fill="#fff"/></svg>')
    dot(V,"#ffd23a",8,"V",12,26);dot(I,"#ffd23a",6,"I",12,-12);dot(T1,lab="T1",dx=12,dy=6);dot(T2,lab="T2",dx=-6,dy=-14)
    for i,l in enumerate(["V — вершина, де сходяться ребра граней","T1, T2 — кінці рук, лежать на самих ребрах","I = V + ((T1−V)+(T2−V))·k,  k ≈ 0,15–0,2","контур: V → T1 → I → T2 → V, усі відрізки прямі"]):
        S.append(text(x0+24,545+i*26,l,15,"#fff" if i==3 else "#cfd8e6",700 if i==3 else 500))
def panel_three(x0):
    frame(x0,"2. Куток із трьох ребер: тризуб")
    fx,fy,w,h=x0+20,80,460,440; V=(x0+250,320)
    ex1=207.7+x0-0; ex1=V[0]-42.3; ly=360.5; ry=403.7
    S.append(f'<svg x="{fx}" y="{fy}" width="{w}" height="{h}" viewBox="{fx} {fy} {w} {h}">'
      f'<polygon points="{P([(fx,fy),(ex1,fy),V,(fx,ly)])}" fill="#4dc9ff"/>'
      f'<polygon points="{P([(ex1,fy),(fx+w,fy),(fx+w,ry),V])}" fill="#3386ff"/>'
      f'<polygon points="{P([(fx,ly),V,(fx+w,ry),(fx+w,fy+h),(fx,fy+h)])}" fill="#33a8ff"/>')
    tips=[pt(V,-100,150),pt(V,20,160),pt(V,170,140)]
    S.append(f'<polygon points="{P(glintpoly(V,tips,0.2))}" fill="#fff"/></svg>')
    dot(V,"#ffd23a",8,"V",14,28)
    for i,p in enumerate(tips): dot(p,lab="T%d"%(i+1),dx=12,dy=6)
    for i,l in enumerate(["між кожною парою кінців — своя внутрішня точка I","кожен кінець лежить на своєму ребрі","довга рука ≈ 15–17% ширини іконки,","коротка (другорядний блик) ≈ 5–6%"]):
        S.append(text(x0+24,545+i*26,l,15,"#cfd8e6"))
def cell(x,y,kind,l1,l2):
    S.append(f'<rect x="{x}" y="{y}" width="460" height="170" rx="8" fill="#1f242d"/>')
    fx,fy,w,h=x+14,y+12,190,146; V=(fx+95,fy+112)
    S.append(f'<svg x="{fx}" y="{fy}" width="{w}" height="{h}" viewBox="{fx} {fy} {w} {h}">'+two_facets(fx,fy,w,h,V,fy+84))
    T1=(V[0],V[1]-90);T2=pt(V,-163,80)
    if kind=="curve":
        c=inner(V,[T1,T2],0.5); S.append(f'<path d="M{V[0]},{V[1]} L{T1[0]:.0f},{T1[1]:.0f} Q{c[0]:.0f},{c[1]:.0f} {T2[0]:.0f},{T2[1]:.0f} Z" fill="#fff"/>')
    elif kind=="line":
        S.append(f'<path d="M{fx+30},{fy+50} Q{fx+60},{fy+30} {fx+100},{fy+42}" stroke="#fff" stroke-width="13" fill="none" stroke-linecap="round"/>')
    else:
        C=(fx+70,fy+60); T1=pt(C,-80,48); T2=pt(C,200,46); S.append(f'<polygon points="{P([C,T1,inner(C,[T1,T2],0.17),T2])}" fill="#fff"/>')
    S.append('</svg>')
    S.append(f'<g stroke="#ff4d4d" stroke-width="8" stroke-linecap="round"><line x1="{x+170}" y1="{y+22}" x2="{x+196}" y2="{y+48}"/><line x1="{x+196}" y1="{y+22}" x2="{x+170}" y2="{y+48}"/></g>')
    S.append(text(x+215,y+84,l1,16,"#fff",700)); S.append(text(x+215,y+108,l2,15,"#cfd8e6"))
def panel_wrong(x0):
    frame(x0,"3. Так не можна")
    cell(x0+20,70,"curve","внутрішня сторона — дуга","має бути прямі лінії до точки I")
    cell(x0+20,260,"line","заокруглена лінія-смужка","має бути гострий кут з кінцями")
    cell(x0+20,450,"float","блик не у вершині ребер","«просто так» на грані — ні")
panel_two(20);panel_three(540);panel_wrong(1060)
svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="1580" height="680" viewBox="0 0 1580 680"><rect width="1580" height="680" fill="#1b2027"/>{"".join(S)}</svg>'
open("anatomy.svg","w").write(svg)
with sync_playwright() as p:
    b=p.chromium.launch(); pg=b.new_page(viewport={"width":1580,"height":680})
    pg.goto("file://"+os.getcwd()+"/anatomy.svg"); pg.screenshot(path="glint_anatomy.png"); b.close()
