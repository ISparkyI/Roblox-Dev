function oreSvg(){
const A="M54 132 L46 64 L72 36 L96 62 L100 128Z",B="M96 120 L100 30 L128 2 L156 30 L156 116Z",Cc="M150 124 L158 66 L184 46 L206 74 L198 130Z",R="M30 168 L52 118 L98 98 L168 96 L214 116 L234 166 L212 214 L140 228 L58 220Z";
const T=i=>`translate(-${(0.6*i).toFixed(1)},${i.toFixed(1)})`;
const rep=(d,a,b)=>{let s="";for(let i=a;i<=b;i++)s+=`<path d="${d}" transform="${T(i)}"/>`;return s};
const grp=(c,d)=>`<g fill="${c}" stroke="${c}" stroke-width="1">${rep(d,1,9)}</g>`;
const peb=(d,c,hl,hc)=>`<path d="${d}" fill="#14161a" stroke="#14161a" stroke-width="8" stroke-linejoin="round" clip-path="url(#ra)"/><path d="${d}" fill="${c}" clip-path="url(#ra)"/><path d="${hl}" fill="${hc}" clip-path="url(#ra)"/>`;
const cry=(d,base,xr,dark,xl,light,id,hl)=>`<path d="${d}" fill="${base}"/><path d="M${xr} -40 L300 -40 L300 300 L${xr} 300Z" fill="${dark}" clip-path="url(#${id})"/><path d="M-40 -40 L${xl} -40 L${xl} 300 L-40 300Z" fill="${light}" clip-path="url(#${id})"/><g clip-path="url(#${id})"><path d="${hl}" fill="#fff"/></g>`;
return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256"><defs><clipPath id="ra"><path d="${R}"/></clipPath><clipPath id="a1"><path d="${A}"/></clipPath><clipPath id="a2"><path d="${B}"/></clipPath><clipPath id="a3"><path d="${Cc}"/></clipPath></defs><g transform="rotate(-5 128 128) translate(0 6)">`
+`<g fill="#14161a" stroke="#14161a" stroke-width="26" stroke-linejoin="round">${rep(A,0,9)}${rep(B,0,9)}${rep(Cc,0,9)}${rep(R,0,9)}</g>`
+grp("#c4581f",A)+grp("#1c7fb8",B)+grp("#6b3fb8",Cc)
+cry(A,"#ff8a3d","73.6","#e0662a","66.6","#ffb27a","a1","M59.6 62.0 L62.3 96.0 L61.6 66.4 L67.1 50.2Z")
+cry(Cc,"#b88af7","179.2","#8a5ad8","172.2","#d6b8ff","a3","M165.2 72.0 L167.9 106.0 L167.2 76.4 L172.7 60.2Z")
+cry(B,"#5cd6ff","127.2","#2aa3e0","120.2","#b8f1ff","a2","M113.2 28.0 L115.9 62.0 L115.2 32.4 L120.7 16.2Z")
+`<path d="${R}" fill="#14161a" stroke="#14161a" stroke-width="10" stroke-linejoin="round"/>`+grp("#6b7684",R)
+`<path d="${R}" fill="#a3aebb"/><path d="M-20 -20 L276 -20 L276 118 L-20 150Z" fill="#c3ccd6" clip-path="url(#ra)"/><path d="M-20 196 L276 172 L276 276 L-20 276Z" fill="#7f8a98" clip-path="url(#ra)"/>`
+peb("M78.6 161.9 L87.0 170.7 L88.1 182.3 L73.8 184.4 L61.9 178.2 L67.7 168.3Z","#ffc531","M67.8 171.8 Q68.5 164.7 76.8 164.7 Q71.5 168.0 67.8 171.8Z","#fff1a8")
+peb("M122.6 176.9 L133.9 181.8 L140.1 191.3 L128.9 197.6 L115.9 196.0 L116.3 185.7Z","#2b3038","M118.3 185.9 Q119.0 179.3 126.7 179.3 Q121.8 182.4 118.3 185.9Z","#7f8a98")
+peb("M185.7 147.5 L190.9 157.1 L188.6 167.8 L175.1 167.0 L166.1 159.2 L174.1 151.3Z","#e8c8a0","M172.3 155.9 Q173.0 149.3 180.7 149.3 Q175.8 152.4 172.3 155.9Z","#fff4e0")
+peb("M186.0 189.8 L192.8 194.8 L195.1 202.3 L186.0 205.1 L177.3 202.1 L179.8 195.0Z","#ff8a3d","M180.5 196.5 Q181.0 191.8 186.5 191.8 Q183.0 194.0 180.5 196.5Z","#ffd0a8")
+peb("M108.5 139.6 L111.0 146.0 L108.7 152.7 L100.1 151.5 L95.0 146.0 L100.8 141.4Z","#ff6b5e","M99.0 144.7 Q99.5 140.4 104.5 140.4 Q101.3 142.4 99.0 144.7Z","#ffc8c2")
+`<g clip-path="url(#ra)"><path d="M56.0 124.0 L87.2 110.4 L63.9 125.5 L62.6 144.9Z" fill="#fff"/></g></g></svg>`;}
if (typeof module !== "undefined") module.exports = oreSvg;
