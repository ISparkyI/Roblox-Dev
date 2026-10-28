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
  // ---- studio name OSIRIUS (27.10.2026; до цього OREKO, size 148 / NM x200 w600 — див. oreko_assets_v5_oreko.js):
  // Montserrat 900 (fontsource latin-900) у контурах, HarfBuzz-кернінг, size 136 (7 літер замість 5 — на 8 % нижче, щоб влізти в камінь),
  // центр x 500, baseline 375.8 (центр капітелі як у OREKO: 328.2). Генератор: namepath.py (uharfbuzz + fontTools). Картинка: різка на будь-якому екрані ----
  const NGY=[278.4,378.6];const NAME_D="M259.21 377.98Q247.52 377.98 237.66 374.3Q227.8 370.63 220.59 363.9Q213.38 357.17 209.37 348.06Q205.36 338.94 205.36 328.2Q205.36 317.32 209.37 308.28Q213.38 299.23 220.59 292.5Q227.8 285.77 237.66 282.1Q247.52 278.42 259.08 278.42Q270.77 278.42 280.56 282.1Q290.36 285.77 297.56 292.5Q304.77 299.23 308.78 308.28Q312.8 317.32 312.8 328.2Q312.8 338.94 308.78 348.06Q304.77 357.17 297.56 363.9Q290.36 370.63 280.56 374.3Q270.77 377.98 259.21 377.98ZM259.08 352.0Q263.56 352.0 267.44 350.37Q271.32 348.74 274.24 345.68Q277.16 342.62 278.8 338.2Q280.43 333.78 280.43 328.2Q280.43 322.62 278.8 318.2Q277.16 313.78 274.24 310.72Q271.32 307.66 267.44 306.03Q263.56 304.4 259.08 304.4Q254.59 304.4 250.71 306.03Q246.84 307.66 243.91 310.72Q240.99 313.78 239.36 318.2Q237.72 322.62 237.72 328.2Q237.72 333.78 239.36 338.2Q240.99 342.62 243.91 345.68Q246.84 348.74 250.71 350.37Q254.59 352.0 259.08 352.0ZM359.99 377.98Q348.02 377.98 336.87 375.26Q325.72 372.54 318.51 368.18L328.84 344.79Q335.64 348.74 344.01 351.12Q352.37 353.5 360.26 353.5Q364.88 353.5 367.54 352.88Q370.19 352.27 371.41 351.12Q372.64 349.96 372.64 348.33Q372.64 345.74 369.78 344.25Q366.92 342.75 362.23 341.73Q357.54 340.71 351.96 339.56Q346.39 338.4 340.74 336.5Q335.1 334.59 330.41 331.46Q325.72 328.34 322.86 323.24Q320.0 318.14 320.0 310.52Q320.0 301.68 324.97 294.4Q329.93 287.13 339.79 282.78Q349.65 278.42 364.34 278.42Q374.0 278.42 383.38 280.46Q392.76 282.5 400.24 286.72L390.59 309.98Q383.52 306.44 376.92 304.67Q370.32 302.9 364.07 302.9Q359.44 302.9 356.72 303.72Q354.0 304.54 352.85 305.9Q351.69 307.26 351.69 308.89Q351.69 311.34 354.55 312.76Q357.4 314.19 362.1 315.14Q366.79 316.1 372.43 317.18Q378.08 318.27 383.65 320.18Q389.23 322.08 393.92 325.21Q398.61 328.34 401.47 333.37Q404.32 338.4 404.32 345.88Q404.32 354.58 399.36 361.86Q394.4 369.14 384.6 373.56Q374.81 377.98 359.99 377.98ZM413.84 375.8L413.84 280.6L445.94 280.6L445.94 375.8ZM461.44 375.8L461.44 280.6L507.28 280.6Q520.6 280.6 530.33 284.95Q540.05 289.3 545.36 297.4Q550.66 305.49 550.66 316.5Q550.66 327.52 545.36 335.41Q540.73 342.48 532.71 346.56L552.7 375.8L518.43 375.8L502.24 351.86L493.54 351.86L493.54 375.8ZM493.54 327.66L505.24 327.66Q511.9 327.66 515.1 324.66Q518.29 321.67 518.29 316.5Q518.29 311.34 515.1 308.34Q511.9 305.35 505.24 305.35L493.54 305.35ZM562.76 375.8L562.76 280.6L594.86 280.6L594.86 375.8ZM655.92 377.98Q634.03 377.98 621.79 366.14Q609.55 354.31 609.55 332.96L609.55 280.6L641.64 280.6L641.64 332.01Q641.64 342.89 645.59 347.44Q649.53 352.0 656.2 352.0Q663.0 352.0 666.87 347.44Q670.75 342.89 670.75 332.01L670.75 280.6L702.3 280.6L702.3 332.96Q702.3 354.31 690.06 366.14Q677.82 377.98 655.92 377.98ZM752.48 377.98Q740.52 377.98 729.36 375.26Q718.21 372.54 711.0 368.18L721.34 344.79Q728.14 348.74 736.5 351.12Q744.87 353.5 752.76 353.5Q757.38 353.5 760.03 352.88Q762.68 352.27 763.91 351.12Q765.13 349.96 765.13 348.33Q765.13 345.74 762.28 344.25Q759.42 342.75 754.73 341.73Q750.04 340.71 744.46 339.56Q738.88 338.4 733.24 336.5Q727.6 334.59 722.9 331.46Q718.21 328.34 715.36 323.24Q712.5 318.14 712.5 310.52Q712.5 301.68 717.46 294.4Q722.43 287.13 732.29 282.78Q742.15 278.42 756.84 278.42Q766.49 278.42 775.88 280.46Q785.26 282.5 792.74 286.72L783.08 309.98Q776.01 306.44 769.42 304.67Q762.82 302.9 756.56 302.9Q751.94 302.9 749.22 303.72Q746.5 304.54 745.34 305.9Q744.19 307.26 744.19 308.89Q744.19 311.34 747.04 312.76Q749.9 314.19 754.59 315.14Q759.28 316.1 764.93 317.18Q770.57 318.27 776.15 320.18Q781.72 322.08 786.42 325.21Q791.11 328.34 793.96 333.37Q796.82 338.4 796.82 345.88Q796.82 354.58 791.86 361.86Q786.89 369.14 777.1 373.56Q767.31 377.98 752.48 377.98Z";const NM={x:180,y:258,w:640,h:148};const SCN=1024/640;
  const nameBody=`<defs><linearGradient id="gold" gradientUnits="userSpaceOnUse" x1="0" y1="${NGY[0]}" x2="0" y2="${NGY[1]}"><stop offset="0" stop-color="#fff6b0"/><stop offset=".45" stop-color="#ffd23a"/><stop offset="1" stop-color="#ff9a1a"/></linearGradient></defs>
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
