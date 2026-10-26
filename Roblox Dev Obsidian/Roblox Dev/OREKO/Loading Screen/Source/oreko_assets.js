// OREKO loading screen — генератор картинок для Roblox (той самий код геометрії, що й у веб-макеті oreko_splash.html).
// buildAssets() → { svg: {stone, stoneWhite, chunks, cracks, pick, pickWhite}, size: {...}, meta }
// Працює і в браузері (растеризація через canvas), і в Node (лише SVG + meta).
function buildAssets(){
  const INK="#14161a",SC=1.4;
  let seed=11;function rnd(){seed=(seed*16807)%2147483647;return (seed-1)/2147483646}
  const lerp=(a,b,t)=>a+(b-a)*t, pts=a=>"M"+a.map(p=>(+p[0].toFixed(2))+" "+(+p[1].toFixed(2))).join(" L")+" Z";
  const SIL=[[166,250],[196,214],[290,214],[306,198],[452,198],[468,206],[620,206],[640,188],[770,188],[800,214],[832,244],[842,318],[834,398],[806,434],[650,446],[480,440],[318,448],[204,438],[170,404],[158,320]];
  const TOPN=10,BAND=24;
  const FACE=SIL.map((p,i)=>i<TOPN?[p[0],p[1]+BAND]:p).map((p,i)=>i==0?[p[0]+6,p[1]]:i==TOPN-1?[p[0]-4,p[1]]:p);
  function stylePat(id,c,od,ol){const s=c/64,r=(x,y,w,h,f,o)=>`<rect x="${x*s}" y="${y*s}" width="${w*s}" height="${h*s}" fill="${f}" opacity="${o}"/>`;
    const L=(ox,oy)=>r(ox+14,oy+14,6,36,"#000",od)+r(ox+14,oy+44,36,6,"#000",od);
    const Q=(ox,oy)=>r(ox+14,oy+14,34,36,"#000",od)+r(ox+14,oy+14,34,6,"#fff",ol)+r(ox+14,oy+14,6,36,"#fff",ol);
    return `<pattern id="${id}" width="${2*c}" height="${2*c}" patternUnits="userSpaceOnUse">${L(0,0)}${Q(64,0)}${Q(0,64)}${L(64,64)}</pattern>`}
  const DEFS=`<defs><linearGradient id="faceB" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4e555f"/><stop offset="1" stop-color="#2c3138"/></linearGradient>
<linearGradient id="topB" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#b3bbc5"/><stop offset="1" stop-color="#858e9a"/></linearGradient>
${stylePat("studs",15,.22,.16)}${stylePat("studsS",9,.2,.3)}<clipPath id="faceClip"><path d="${pts(FACE)}"/></clipPath><mask id="faceIn" maskUnits="userSpaceOnUse" x="0" y="0" width="1000" height="600"><path d="${pts(FACE)}" fill="#fff"/><path d="${pts(FACE)}" fill="none" stroke="#000" stroke-width="5" stroke-linejoin="round"/></mask>
<filter id="toWhite" x="-5%" y="-5%" width="110%" height="110%"><feColorMatrix type="matrix" values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 1 0"/></filter></defs>`;
  const svgDoc=(vb,w,h,body)=>`<svg xmlns="http://www.w3.org/2000/svg" width="${Math.round(w)}" height="${Math.round(h)}" viewBox="${vb}">${DEFS}${body}</svg>`;
  // ---- stone (back, stays) ----
  const ST={x:150,y:182,w:700,h:274};
  const stoneBody=`<path d="${pts(SIL)}" fill="url(#topB)"/><path d="${pts(FACE)}" fill="url(#faceB)"/><path d="${pts(FACE)}" fill="url(#studs)"/>
<path d="${pts(FACE)}" fill="none" stroke="${INK}" stroke-width="6" stroke-linejoin="round"/>
<path d="M${SIL.slice(0,TOPN).map(p=>p[0]+" "+(p[1]+5)).join(" L")}" fill="none" stroke="#fff" stroke-width="4" opacity=".35" stroke-linejoin="round"/>
<path d="${pts(SIL)}" fill="none" stroke="${INK}" stroke-width="8" stroke-linejoin="round"/>`;
  const stone=svgDoc(`${ST.x} ${ST.y} ${ST.w} ${ST.h}`,ST.w*SC,ST.h*SC,stoneBody);
  // front part of the stone (everything 12 units below the top outline): drawn OVER the pick, so the pick sinks into the stone top
  const stoneFront=svgDoc(`${ST.x} ${ST.y} ${ST.w} ${ST.h}`,ST.w*SC,ST.h*SC,`<mask id="frontMask" maskUnits="userSpaceOnUse" x="0" y="0" width="1000" height="600"><path d="${pts(SIL)}" transform="translate(0 12)" fill="#fff"/></mask><g mask="url(#frontMask)">${stoneBody}</g>`);
  const stoneWhite=svgDoc(`${ST.x} ${ST.y} ${ST.w} ${ST.h}`,ST.w*SC,ST.h*SC,`<g filter="url(#toWhite)">${stoneBody}</g>`);
  // ---- front shell chunks (same random sequence as the mock) ----
  const HIT={x:545,y:300};
  const BX0=150,BX1=850,BY0=204,BY1=452,COLS=8,ROWS=3; // BY0 вище за верх грані (212), інакше під корою видно смугу заднього каменю
  const V=[];for(let j=0;j<=ROWS;j++){V[j]=[];for(let i=0;i<=COLS;i++){let x=lerp(BX0,BX1,i/COLS),y=lerp(BY0,BY1,j/ROWS);if(i>0&&i<COLS)x+=(rnd()-.5)*46;if(j>0&&j<ROWS)y+=(rnd()-.5)*34;V[j][i]=[x,y]}}
  const shades=["#8d959f","#838b96","#97a0aa","#7e8691","#9ca4ad","#88909b"];
  const chunks=[];
  for(let j=0;j<ROWS;j++)for(let i=0;i<COLS;i++){
    const p=[V[j][i],V[j][i+1],V[j+1][i+1],V[j+1][i]];
    const cx=p.reduce((a,b)=>a+b[0],0)/4,cy=p.reduce((a,b)=>a+b[1],0)/4;
    const dx=cx-HIT.x,dy=cy-HIT.y,dist=Math.hypot(dx,dy);
    chunks.push({p,cx,cy,fill:shades[(i*3+j*5)%6],vx:dx*0.9+(rnd()-.5)*140,vy:-90-rnd()*200+dy*.5,vr:(rnd()-.5)*560,delay:dist/2400});
  }
  // atlas: chunk bboxes (clamped to the face bounds) packed in rows
  const FB={x0:158,x1:842,y0:212,y1:448},M=5;
  let ax=0,ay=0,rowH=0;const AW=640;
  chunks.forEach(c=>{const xs=c.p.map(q=>q[0]),ys=c.p.map(q=>q[1]);
    c.x=Math.max(FB.x0,Math.min(...xs))-M;c.y=Math.max(FB.y0,Math.min(...ys))-M;c.w=Math.min(FB.x1,Math.max(...xs))+M-c.x;c.h=Math.min(FB.y1,Math.max(...ys))+M-c.y;
    if(ax+c.w>AW){ax=0;ay+=rowH+4;rowH=0}c.ax=ax;c.ay=ay;ax+=c.w+4;rowH=Math.max(rowH,c.h)});
  const AH=ay+rowH;
  const chunkSvg=chunks.map((c,n)=>`<mask id="cp${n}" maskUnits="userSpaceOnUse" x="0" y="0" width="1000" height="600"><path d="${pts(c.p)}" fill="#fff" stroke="#fff" stroke-width="3" stroke-linejoin="round"/></mask><g transform="translate(${(c.ax-c.x).toFixed(2)} ${(c.ay-c.y).toFixed(2)})"><g mask="url(#cp${n})"><g mask="url(#faceIn)">
<path d="${pts(c.p)}" fill="${c.fill}"/><path d="${pts(c.p)}" fill="url(#studs)"/><path d="${pts(c.p)}" fill="none" stroke="#454c56" stroke-width="3" stroke-linejoin="round"/><path d="${pts(FACE)}" fill="none" stroke="${INK}" stroke-width="12" stroke-linejoin="round"/></g></g></g>`).join("");
  const chunksDoc=svgDoc(`0 0 ${AW} ${AH}`,AW*SC,AH*SC,chunkSvg);
  // ---- cracks: 3 stages (same walks as the mock) ----
  function walk(x,y,ang,steps,len){const a=[[x,y]];for(let s=0;s<steps;s++){ang+=(rnd()-.5)*1.1;x+=Math.cos(ang)*len*(0.7+rnd()*.6);y+=Math.sin(ang)*len*(0.7+rnd()*.6);a.push([Math.round(x),Math.round(y)])}return a}
  const stages=[[],[],[]],tips=[];
  [-2.6,-1.2,0.1,1.2,2.4].forEach(ang=>{const w=walk(HIT.x,HIT.y,ang,3,22);stages[0].push(w);tips.push({p:w[w.length-1],ang})});
  tips.forEach(t=>{const w=walk(t.p[0],t.p[1],t.ang,4,30);stages[1].push(w);t.p=w[w.length-1]});
  tips.forEach(t=>{const w=walk(t.p[0],t.p[1],t.ang,6,40);stages[2].push(w);if(rnd()<.6)stages[2].push(walk(w[2][0],w[2][1],t.ang+(rnd()<.5?-1:1),3,30))});
  const all=stages.flat(2);
  const CR={x:Math.max(FB.x0,Math.min(...all.map(p=>p[0])))-8,y:Math.max(FB.y0,Math.min(...all.map(p=>p[1])))-8};
  CR.w=Math.min(FB.x1,Math.max(...all.map(p=>p[0])))+8-CR.x;CR.h=Math.min(FB.y1,Math.max(...all.map(p=>p[1])))+8-CR.y;
  const crackSvg=stages.map((st,i)=>`<g transform="translate(${-CR.x} ${i*(CR.h+4)-CR.y})"><g clip-path="url(#faceClip)" fill="none" stroke="${INK}" stroke-linecap="round" stroke-linejoin="round">${
    st.map(w=>`<path d="M${w.map(p=>p.join(" ")).join(" L")}" stroke-width="${[7,6,5][i]}"/>`).join("")}</g></g>`).join("");
  const SCC=0.9,cracksDoc=svgDoc(`0 0 ${CR.w} ${3*CR.h+8}`,CR.w*SCC,(3*CR.h+8)*SCC,crackSvg);
  // ---- pickaxe (Stone Golem pickaxe profile, mirrored), canvas centred on the grip ----
  const S=72,HS=350;let pk="";
  function blk(z,y,w,h,rot,fill,sw,extra){const x=-(z+.57)*S,yy=-(y+1.88)*S;
    pk+=`<g transform="translate(${x.toFixed(2)} ${yy.toFixed(2)}) rotate(${-rot})"><rect x="${-w*S/2}" y="${-h*S/2}" width="${w*S}" height="${h*S}" rx="3" fill="${fill}" stroke="${INK}" stroke-width="${sw||5}" stroke-linejoin="round"/>${extra?extra(w*S,h*S)+`<rect x="${-w*S/2}" y="${-h*S/2}" width="${w*S}" height="${h*S}" rx="3" fill="none" stroke="${INK}" stroke-width="${sw||5}" stroke-linejoin="round"/>`:""}</g>`}
  const hiTop=(w,h)=>`<rect x="${-w/2+4}" y="${-h/2+3}" width="${w-8}" height="${Math.max(3,h*.22)}" rx="2" fill="#fff" opacity=".4"/>`;
  const studsOn=(w,h)=>`<rect x="${-w/2}" y="${-h/2}" width="${w}" height="${h}" fill="url(#studsS)"/>`;
  blk(-.57,-.18,.42,4.6,0,"#a8754a",6,(w,h)=>studsOn(w,h)+`<rect x="${-w/2+5}" y="${-h/2+6}" width="6" height="${h-12}" rx="3" fill="#d6a06a" opacity=".75"/>`);
  blk(-.57,-.95,.52,.2,0,"#7a5233",5);
  blk(-.57,-1.88,.47,1.2,0,"#7a5233",5,(w,h)=>[1,2,3].map(i=>`<line x1="${-w/2+3}" y1="${-h/2+i*h/4}" x2="${w/2-3}" y2="${-h/2+i*h/4-6}" stroke="${INK}" stroke-width="3" opacity=".55"/>`).join(""));
  blk(-.57,-2.6,.71,.3,0,"#6e7884",5,hiTop);
  blk(-1.22,2.15,.7,.5,-6,"#a3adb8",5,hiTop);blk(-1.69,2.10,.5,.35,-23,"#a3adb8",5,hiTop);blk(-1.95,2.0,.15,.5,-23,"#6e7884",5);
  blk(-.57,2.20,.78,1.0,0,"#6e7884",5);
  blk(-.57,2.17,.9,.8,0,"#6e7884",5,(w,h)=>studsOn(w,h)+`<circle cx="0" cy="0" r="7" fill="#a3adb8" stroke="${INK}" stroke-width="3"/>`);
  blk(.21,2.15,.95,.52,6,"#a3adb8",5,hiTop);blk(.95,2.08,.8,.4,18,"#a3adb8",5,hiTop);blk(1.52,1.89,.65,.3,32,"#a3adb8",5,hiTop);blk(1.88,1.66,.45,.2,46,"#a3adb8",5);
  blk(1.02,2.27,.5,.12,18,"#f1f5f8",3);blk(-.57,2.65,.56,.2,0,"#a3adb8",5,hiTop);
  // ---- name OREKO: Montserrat 900 outlined (text → path), as an image: sharp at any screen size ----
  const NAME_D="M277.70 382.36Q264.97 382.36 254.24 378.37Q243.51 374.37 235.67 367.04Q227.82 359.72 223.46 349.80Q219.09 339.89 219.09 328.2Q219.09 316.36 223.46 306.51Q227.82 296.67 235.67 289.35Q243.51 282.02 254.24 278.02Q264.97 274.03 277.55 274.03Q290.28 274.03 300.94 278.02Q311.59 282.02 319.44 289.35Q327.28 296.67 331.65 306.51Q336.01 316.36 336.01 328.2Q336.01 339.89 331.65 349.80Q327.28 359.72 319.44 367.04Q311.59 374.37 300.94 378.37Q290.28 382.36 277.70 382.36ZM277.55 354.1Q282.44 354.1 286.65 352.32Q290.87 350.54 294.05 347.21Q297.24 343.88 299.01 339.07Q300.79 334.26 300.79 328.2Q300.79 322.13 299.01 317.32Q297.24 312.51 294.05 309.18Q290.87 305.85 286.65 304.07Q282.44 302.3 277.55 302.3Q272.67 302.3 268.45 304.07Q264.23 305.85 261.05 309.18Q257.87 312.51 256.09 317.32Q254.32 322.13 254.32 328.2Q254.32 334.26 256.09 339.07Q257.87 343.88 261.05 347.21Q264.23 350.54 268.45 352.32Q272.67 354.1 277.55 354.1ZM348.74 380.0V276.4H398.62Q413.12 276.4 423.70 281.13Q434.28 285.87 440.06 294.67Q445.83 303.48 445.83 315.47Q445.83 327.46 440.06 336.04Q435.02 343.74 426.29 348.18L448.05 380.0H410.75L393.14 353.95H383.67V380.0ZM383.67 327.60H396.4Q403.65 327.60 407.13 324.35Q410.60 321.09 410.60 315.47Q410.60 309.84 407.13 306.59Q403.65 303.33 396.4 303.33H383.67ZM493.34 353.65H545.14V380.0H459.00V276.4H543.21V302.74H493.34V314.88H537.14V340.04H493.34ZM558.60 380.0V276.4H592.94V313.99L626.98 276.4H665.02L623.58 321.98L667.09 380.0H626.68L600.78 345.66L592.94 354.39V380.0ZM722.59 382.36Q709.86 382.36 699.13 378.37Q688.40 374.37 680.56 367.04Q672.71 359.72 668.35 349.80Q663.98 339.89 663.98 328.2Q663.98 316.36 668.35 306.51Q672.71 296.67 680.56 289.35Q688.40 282.02 699.13 278.02Q709.86 274.03 722.44 274.03Q735.17 274.03 745.82 278.02Q756.48 282.02 764.32 289.35Q772.17 296.67 776.53 306.51Q780.90 316.36 780.90 328.2Q780.90 339.89 776.53 349.80Q772.17 359.72 764.32 367.04Q756.48 374.37 745.82 378.37Q735.17 382.36 722.59 382.36ZM722.44 354.1Q727.32 354.1 731.54 352.32Q735.76 350.54 738.94 347.21Q742.12 343.88 743.90 339.07Q745.68 334.26 745.68 328.2Q745.68 322.13 743.90 317.32Q742.12 312.51 738.94 309.18Q735.76 305.85 731.54 304.07Q727.32 302.3 722.44 302.3Q717.56 302.3 713.34 304.07Q709.12 305.85 705.94 309.18Q702.76 312.51 700.98 317.32Q699.20 322.13 699.20 328.2Q699.20 334.26 700.98 339.07Q702.76 343.88 705.94 347.21Q709.12 350.54 713.34 352.32Q717.56 354.1 722.44 354.1Z",NM={x:200,y:258,w:600,h:148},SCN=1024/600;
  const nameBody=`<defs><linearGradient id="gold" gradientUnits="userSpaceOnUse" x1="0" y1="274" x2="0" y2="383"><stop offset="0" stop-color="#fff6b0"/><stop offset=".45" stop-color="#ffd23a"/><stop offset="1" stop-color="#ff9a1a"/></linearGradient></defs>
<path d="${NAME_D}" transform="translate(0 8)" fill="#0c0e12" stroke="${INK}" stroke-width="22" stroke-linejoin="round"/>
<path d="${NAME_D}" fill="none" stroke="${INK}" stroke-width="20" stroke-linejoin="round"/><path d="${NAME_D}" fill="url(#gold)"/>`;
  const name=svgDoc(`${NM.x} ${NM.y} ${NM.w} ${NM.h}`,NM.w*SCN,NM.h*SCN,nameBody);
  const nameGlow=svgDoc(`${NM.x} ${NM.y} ${NM.w} ${NM.h}`,NM.w*SCN,NM.h*SCN,`<path d="${NAME_D}" fill="#fff"/>`);
  const pick=svgDoc(`${-HS} ${-HS} ${2*HS} ${2*HS}`,2*HS*SC,2*HS*SC,pk);
  const pickWhite=svgDoc(`${-HS} ${-HS} ${2*HS} ${2*HS}`,2*HS*SC,2*HS*SC,`<g filter="url(#toWhite)">${pk}</g>`);
  const TIPL=(()=>{const z=1.88+.225*Math.cos(46*Math.PI/180),y=1.66-.225*Math.sin(46*Math.PI/180);return [-(z+.57)*S,-(y+1.88)*S]})();
  const HEADL=[0,-(2.17+1.88)*S],TEXTL=[0,-(.78+1.88)*S];
  const meta={SC,ST,HIT,SIL,TOPN,FACE,chunks:chunks.map(c=>({x:+c.x.toFixed(1),y:+c.y.toFixed(1),w:+c.w.toFixed(1),h:+c.h.toFixed(1),ax:+c.ax.toFixed(1),ay:+c.ay.toFixed(1),
    vx:+c.vx.toFixed(1),vy:+c.vy.toFixed(1),vr:+c.vr.toFixed(1),delay:+c.delay.toFixed(3),cx:+c.cx.toFixed(1),cy:+c.cy.toFixed(1)})),atlas:{w:AW,h:AH},CR,SCC,HS,S,TIPL,HEADL,TEXTL,NM};
  return {svg:{stone,stoneFront,stoneWhite,chunks:chunksDoc,cracks:cracksDoc,pick,pickWhite,name,nameGlow},meta};
}
if(typeof module!=="undefined")module.exports={buildAssets};
