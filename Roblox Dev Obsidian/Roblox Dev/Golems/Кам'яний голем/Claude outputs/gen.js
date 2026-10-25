window.__gen=(()=>{
const N="#040435";
const f1=v=>Math.round(v*10)/10;
const svg=(inner,d)=>`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="512" height="512"><defs>${d}</defs>${inner}</svg>`;
const P=pts=>"M"+pts.map(([x,y])=>`${f1(x)} ${f1(y)}`).join(" L")+"Z";
const unit=(a,b)=>{const dx=b[0]-a[0],dy=b[1]-a[1],l=Math.hypot(dx,dy);return[dx/l,dy/l]};
const rep=(paths,k0,k1)=>{let o="";for(const p of paths)for(let k=k0;k<k1;k++)o+=`<path d="${p}" transform="translate(${-k},${-k})"/>`;return o};
const outline=(paths,depth=9,sw=26)=>`<g fill="${N}" stroke="${N}" stroke-width="${sw}" stroke-linejoin="round">${rep(paths,0,depth)}</g>`;
const side=(paths,c,depth=9)=>`<g fill="${c}" stroke="${c}" stroke-width="1" stroke-linejoin="round">${rep(paths,1,depth)}</g>`;
const ext=(path,depth,c,sw=26)=>`<g fill="${N}" stroke="${N}" stroke-width="${sw}" stroke-linejoin="round">${rep([path],0,depth+1)}</g><g fill="${c}" stroke="${c}" stroke-width="1" stroke-linejoin="round">${rep([path],0,depth+1)}</g>`;
const wedge=(cx,cy,u1,u2,l1,l2,k=.21,fill="#fff")=>{const t1=[cx+u1[0]*l1,cy+u1[1]*l1],t2=[cx+u2[0]*l2,cy+u2[1]*l2];
  const c=[cx+(u1[0]*l1+u2[0]*l2)*k,cy+(u1[1]*l1+u2[1]*l2)*k];
  return `<path d="M${f1(cx)} ${f1(cy)} L${f1(t1[0])} ${f1(t1[1])} L${f1(c[0])} ${f1(c[1])} L${f1(t2[0])} ${f1(t2[1])}Z" fill="${fill}"/>`};
const clip=(i,p)=>`<clipPath id="${i}"><path d="${p}"/></clipPath>`;
const poly=(pts,fill,cid)=>`<path d="${P(pts)}" fill="${fill}"${cid?` clip-path="url(#${cid})"`:""}/>`;
const crystal=(pts,cid,base,light,dark)=>{const mx=pts.reduce((a,p)=>a+p[0],0)/pts.length;
  return poly(pts,base)+poly([[mx,-50],[300,-50],[300,300],[mx,300]],dark,cid)+poly([[-50,-50],[mx-6,-50],[mx-6,300],[-50,300]],light,cid)};
const COPPER=["#ff8a3d","#ffb27a","#e0662a","#c4581f"], COAL=["#5a616c","#7d8591","#3d424a","#2c3036"], IRON=["#e0a46e","#f2c9a0","#c07a45","#9a5c30"];
const E=[1,0],S=[0,1],W=[-1,0],U=[0,-1];

// Capacity
function capacity(){
  const CRATE="M44 132 H212 V218 H44Z", ROCK="M58 140 L72 110 L116 96 L164 102 L196 126 L198 140Z";
  const C1=[[76,124],[66,78],[84,56],[104,74],[104,122]], C2=[[108,112],[112,44],[134,20],[156,44],[152,112]], C3=[[156,126],[162,84],[180,68],[196,90],[184,130]];
  const d=clip("kc",CRATE)+clip("k1",P(C1))+clip("k2",P(C2))+clip("k3",P(C3))+clip("kr",ROCK);
  let s='<g transform="rotate(-6 128 140)">';
  s+=outline([P(C1),P(C2),P(C3),ROCK]);
  s+=side([P(C1),P(C2)],COPPER[3])+side([P(C3)],COAL[3])+side([ROCK],"#6b7684");
  s+=crystal(C1,"k1",COPPER[0],COPPER[1],COPPER[2])+crystal(C2,"k2",COPPER[0],COPPER[1],COPPER[2])+crystal(C3,"k3",COAL[0],COAL[1],COAL[2]);
  s+=`<path d="${ROCK}" fill="#a3aebb"/>`+poly([[40,90],[200,90],[200,116],[40,128]],"#c3ccd6","kr");
  s+='<g clip-path="url(#k2)">'+wedge(114,50,unit([112,44],[134,20]),unit([112,44],[108,112]),22,30)+'</g>';
  s+=ext(CRATE,10,"#8a5428");
  s+=`<path d="${CRATE}" fill="#c98a52"/>`;
  s+=poly([[30,120],[140,120],[110,160],[30,160]],"#dda066","kc");
  s+=poly([[30,196],[230,190],[230,240],[30,240]],"#a8703e","kc");
  for(const y of [160,189]) s+=`<path d="M44 ${y} H212" stroke="#8a5428" stroke-width="5"/>`;
  for(const x0 of [44,186]){ s+=`<path d="M${x0} 132 H${x0+26} V218 H${x0}Z" fill="#b97a42" clip-path="url(#kc)"/>`; s+=`<path d="M${x0+26} 132 V218" stroke="#8a5428" stroke-width="5"/>`; }
  s+='<path d="M44 132 H212" stroke="#8a5428" stroke-width="5"/>';
  for(const [x,y] of [[57,145],[199,145],[57,205],[199,205]]) s+=`<circle cx="${x}" cy="${y}" r="4.5" fill="${N}"/>`;
  s+='<g clip-path="url(#kc)">'+wedge(50,138,E,S,40,34)+wedge(206,212,W,U,22,18)+'</g>';
  s+='</g>';
  return svg(s,d);
}

// Speed
const PIV=[147,236];
function band(r0,w0,a0,a1,n=24){const out=[],inn=[];
  for(let i=0;i<=n;i++){const t=i/n,a=(a0+(a1-a0)*t)*Math.PI/180,hw=w0*Math.pow(1-t,0.85)/2;
    out.push([PIV[0]+(r0+hw)*Math.cos(a),PIV[1]+(r0+hw)*Math.sin(a)]); inn.push([PIV[0]+(r0-hw)*Math.cos(a),PIV[1]+(r0-hw)*Math.sin(a)]);}
  return [out.concat(inn.slice().reverse()),inn]}
function swoosh(){const st=[band(180,15,-117,-160),band(156,15,-118,-152),band(132,13,-119,-146)];
  let s=outline(st.map(b=>P(b[0])),1,12); for(const b of st) s+=poly(b[0],"#ffffff"); return s}
function speed(){
  const HH="M86 46 H206 V112 H86Z", HA="M134 108 H160 V236 H134Z";
  const d=clip("sh",HH)+clip("sg",HA);
  let s='<g transform="translate(140 136) scale(0.86) translate(-128 -128)">';
  s+='<g transform="rotate(28 150 150) translate(-16 6)">';
  s+=swoosh();
  s+=outline([HA,HH],10);
  s+=side([HA],"#8a5428",10)+side([HH],"#6b7684",10);
  s+=`<path d="${HA}" fill="#c98a52"/>`+poly([[148,100],[170,100],[170,240],[148,240]],"#a36a38","sg");
  for(const y of [196,214]) s+=`<path d="M134 ${y} H160 V${y+10} H134Z" fill="#6e4220"/>`;
  s+=`<path d="${HH}" fill="#c3ccd6"/>`;
  s+=poly([[70,30],[160,30],[130,80],[70,80]],"#e6ecf3","sh");
  s+=poly([[70,94],[220,90],[220,130],[70,130]],"#8f9aa8","sh");
  s+=poly([[188,30],[220,30],[220,130],[188,130]],"#a7b1bd","sh");
  s+=poly([[70,30],[102,30],[102,130],[70,130]],"#a7b1bd","sh");
  s+='<path d="M188 46 V112 M102 46 V112" stroke="#6b7684" stroke-width="5"/>';
  s+='<g clip-path="url(#sh)">'+wedge(108,52,E,S,40,26)+wedge(200,106,W,U,16,14)+'</g>';
  s+='<g clip-path="url(#sg)">'+wedge(138,116,E,S,8,34)+'</g>';
  s+='</g></g>';
  return svg(s,d);
}

// Ore per Hit
const chunk=(cx,by,w,h)=>[[cx-w*0.5,by],[cx-w*0.56,by-h*0.55],[cx-w*0.22,by-h],[cx+w*0.3,by-h*0.96],[cx+w*0.56,by-h*0.5],[cx+w*0.46,by]];
function burst(cx,cy,ro,ri,n=8,rot=-90){const pts=[];for(let i=0;i<n*2;i++){const a=(rot+i*180/n)*Math.PI/180,r=i%2===0?ro:ri;pts.push([cx+r*Math.cos(a),cy+r*Math.sin(a)])}return pts}
function oph(){
  const ANVIL="M20 118 L64 106 H218 V136 H180 L164 146 L162 172 L192 180 V214 H64 V180 L94 172 L92 146 L78 138 Q44 136 20 118Z";
  const ch=[[chunk(82,112,48,40),COPPER],[chunk(136,112,54,48),COAL],[chunk(188,112,46,38),IRON]];
  const st=burst(136,44,38,17);
  const d=clip("av",ANVIL)+ch.map((c,i)=>clip("oc"+i,P(c[0]))).join("")+clip("bs",P(st));
  let s='<g transform="rotate(-4 128 150)">';
  s+=ext(ANVIL,10,"#4d5866");
  s+=`<path d="${ANVIL}" fill="#8f9aa8"/>`;
  s+=poly([[0,96],[230,96],[230,122],[0,130]],"#c3ccd6","av");
  s+=poly([[0,128],[230,124],[230,136],[0,140]],"#a7b1bd","av");
  s+=poly([[0,180],[230,178],[230,230],[0,230]],"#6b7684","av");
  s+=poly([[150,136],[230,136],[230,180],[150,180]],"#7a8594","av");
  s+='<g clip-path="url(#av)">'+wedge(66,110,E,unit([64,106],[20,118]),40,26)+wedge(70,186,E,S,22,18)+'</g>';
  s+=outline(ch.map(c=>P(c[0])),8,22);
  for(const [c,pal] of ch) s+=side([P(c)],pal[3],8);
  ch.forEach(([c,pal],i)=>{ s+=crystal(c,"oc"+i,pal[0],pal[1],pal[2]);
    s+=`<g clip-path="url(#oc${i})">`+wedge(c[1][0]+4,c[1][1]-1,unit(c[1],c[2]),unit(c[1],c[0]),16,10)+'</g>'; });
  s+=`<path d="${P(st)}" fill="${N}" stroke="${N}" stroke-width="16" stroke-linejoin="round"/>`;
  s+=`<path d="${P(st)}" fill="#ffd23a"/>`+poly([[136,-10],[240,-10],[240,120],[136,120]],"#ffaa1c","bs");
  s+=poly(burst(136,44,18,8),"#fff6c8");
  for(const [x,y,r] of [[70,44,13],[204,46,10]]){const sp=burst(x,y,r,r*0.3,4);
    s+=`<path d="${P(sp)}" fill="${N}" stroke="${N}" stroke-width="8" stroke-linejoin="round"/><path d="${P(sp)}" fill="#fff"/>`;}
  s+='</g>';
  return svg(s,d);
}
async function toPng(svgText){
  const img=new Image(); const url=URL.createObjectURL(new Blob([svgText],{type:'image/svg+xml'}));
  await new Promise((res,rej)=>{img.onload=res;img.onerror=rej;img.src=url});
  const c=document.createElement('canvas'); c.width=512;c.height=512; c.getContext('2d').drawImage(img,0,0,512,512);
  URL.revokeObjectURL(url);
  return await new Promise(r=>c.toBlob(r,'image/png'));
}
return {capacity,speed,oph,toPng};
})();
