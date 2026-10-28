# usage: namepath.py font.ttf TEXT size centerX baselineY
import sys, uharfbuzz as hb
from fontTools.ttLib import TTFont
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.recordingPen import RecordingPen
fp,text,size,cx,by=sys.argv[1],sys.argv[2],float(sys.argv[3]),float(sys.argv[4]),float(sys.argv[5])
blob=hb.Blob.from_file_path(fp);face=hb.Face(blob);font=hb.Font(face)
buf=hb.Buffer();buf.add_str(text);buf.guess_segment_properties();hb.shape(font,buf,{"kern":True,"liga":True})
tt=TTFont(fp);gs=tt.getGlyphSet();order=tt.getGlyphOrder();upm=tt['head'].unitsPerEm;s=size/upm
total=sum(p.x_advance for p in buf.glyph_positions)
x0=cx-total*s/2;x=0;out=[];kern=[]
def f(v):
    t=("%.2f"%v).rstrip('0');return t+'0' if t.endswith('.') else t
for info,pos in zip(buf.glyph_infos,buf.glyph_positions):
    g=order[info.codepoint];rp=RecordingPen()
    tp=TransformPen(rp,(s,0,0,-s,x0+(x+pos.x_offset)*s,by-pos.y_offset*s));gs[g].draw(tp)
    for op,args in rp.value:
        if op=='moveTo':out.append('M'+f(args[0][0])+' '+f(args[0][1]))
        elif op=='lineTo':out.append('L'+f(args[0][0])+' '+f(args[0][1]))
        elif op=='qCurveTo':
            # expand implied on-curve points
            pts=list(args)
            for i in range(len(pts)-1):
                c=pts[i];e=pts[i+1] if i==len(pts)-2 else ((pts[i][0]+pts[i+1][0])/2,(pts[i][1]+pts[i+1][1])/2)
                out.append('Q'+f(c[0])+' '+f(c[1])+' '+f(e[0])+' '+f(e[1]))
        elif op=='curveTo':out.append('C'+' '.join(f(a)+' '+f(b) for a,b in args))
        elif op=='closePath':out.append('Z')
    kern.append((g,pos.x_advance));x+=pos.x_advance
print(''.join(out))
print("left",x0,"right",x0+total*s,"adv",kern,file=sys.stderr)
