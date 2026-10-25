import json,math,sys
d=json.load(open('models_fixed.json'))['F']['items']
SC={'coal':0.68,'copper':1.0,'iron':1.0,'barCu':1.0,'barFe':1.0}
VT={'b':[(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)],'w':[(-1,-1,-1),(1,-1,-1),(1,-1,1),(-1,-1,1),(-1,1,1),(1,1,1)],'c':[(-1,-1,-1),(1,-1,-1),(1,-1,1),(-1,-1,1),(1,1,-1)]}
def verts(p):
    m=p['m']; sx,sy,sz=[v/2 for v in p['s']]
    for a,b,c in VT[p['t']]:
        x,y,z=a*sx,b*sy,c*sz
        yield (m[0]*x+m[4]*y+m[8]*z+m[12], m[1]*x+m[5]*y+m[9]*z+m[13], m[2]*x+m[6]*y+m[10]*z+m[14])
out=[]
for k,parts in d.items():
    pts=[q for p in parts for q in verts(p)]
    cx=(min(q[0] for q in pts)+max(q[0] for q in pts))/2; cz=(min(q[2] for q in pts)+max(q[2] for q in pts))/2; miny=min(q[1] for q in pts)
    s=SC[k]; rows=[]
    fb=next(p for p in parts if p['t']=='b'); a=fb['m'][12:15]
    rows.append("{'a',0.04,0.04,0.04,%.4f,%.4f,%.4f}"%((a[0]-cx)*s,(a[1]-miny)*s,(a[2]-cz)*s))
    for p in parts:
        m=p['m']; R=[m[0],m[4],m[8],m[1],m[5],m[9],m[2],m[6],m[10]]
        rows.append("{'%s',%s,%s,%s,'%s'}"%(p['t'],",".join("%.4f"%(v*s) for v in p['s']),",".join("%.4f"%v for v in [(m[12]-cx)*s,(m[13]-miny)*s,(m[14]-cz)*s]),",".join("%.5f"%v for v in R),p['c']))
    print(k,'size',round((max(q[0] for q in pts)-min(q[0] for q in pts))*s,2),round((max(q[1] for q in pts)-miny)*s,2),round((max(q[2] for q in pts)-min(q[2] for q in pts))*s,2))
    out.append("%s={%s}"%(k,",".join(rows)))
open('studio_data.lua','w').write("local D={"+",\n".join(out)+"}\n")
