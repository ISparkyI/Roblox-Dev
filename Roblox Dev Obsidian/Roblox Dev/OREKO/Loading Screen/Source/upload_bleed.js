// Завантаження картинок OREKO з «alpha bleeding»: прозорі пікселі отримують колір сусідніх непрозорих,
// інакше Roblox при фільтрації дає світлі/темні обводки на краях (білі лінії на стиках шматків).
// PNG кодуємо самі (canvas.toBlob губить колір прозорих пікселів). Запуск: вкладка create.roblox.com, вхід користувача.
window.__oreko={status:"start",ids:{}};
(async()=>{try{
const KEYS=window.__orekoKeys||["stone","stoneFront","stoneWhite","chunks","cracks","pick","pickWhite","name","nameGlow"];
const A=buildAssets();let csrf="";
const CRC=new Uint32Array(256);for(let n=0;n<256;n++){let c=n;for(let k=0;k<8;k++)c=c&1?0xedb88320^(c>>>1):c>>>1;CRC[n]=c>>>0}
function crc(b){let c=0xffffffff;for(let i=0;i<b.length;i++)c=CRC[(c^b[i])&255]^(c>>>8);return (c^0xffffffff)>>>0}
function chunk(type,data){const out=new Uint8Array(12+data.length),dv=new DataView(out.buffer);dv.setUint32(0,data.length);
  for(let i=0;i<4;i++)out[4+i]=type.charCodeAt(i);out.set(data,8);dv.setUint32(8+data.length,crc(out.subarray(4,8+data.length)));return out}
async function png(w,h,px){const st=w*4+1,raw=new Uint8Array(st*h);
  for(let y=0;y<h;y++){raw[y*st]=1;const o=y*st+1,s=y*w*4;for(let x=0;x<w*4;x++)raw[o+x]=(px[s+x]-(x>=4?px[s+x-4]:0))&255}
  const z=new Uint8Array(await new Response(new Blob([raw]).stream().pipeThrough(new CompressionStream("deflate"))).arrayBuffer());
  const ih=new Uint8Array(13),dv=new DataView(ih.buffer);dv.setUint32(0,w);dv.setUint32(4,h);ih.set([8,6,0,0,0],8);
  const parts=[new Uint8Array([137,80,78,71,13,10,26,10]),chunk("IHDR",ih),chunk("IDAT",z),chunk("IEND",new Uint8Array(0))];
  return new Blob(parts,{type:"image/png"})}
function bleed(w,h,px,passes){const done=new Uint8Array(w*h);for(let i=0;i<w*h;i++)done[i]=px[i*4+3]>=24?1:0; // майже прозорі пікселі мають «сміттєвий» колір — перефарбовуємо й їх (альфа лишається)
  for(let p=0;p<passes;p++){const add=[];
    for(let y=0;y<h;y++)for(let x=0;x<w;x++){const i=y*w+x;if(done[i])continue;let r=0,g=0,b=0,n=0;
      for(const [dx,dy] of [[1,0],[-1,0],[0,1],[0,-1],[1,1],[-1,-1],[1,-1],[-1,1]]){const X=x+dx,Y=y+dy;if(X<0||Y<0||X>=w||Y>=h)continue;const j=Y*w+X;
        if(done[j]){r+=px[j*4];g+=px[j*4+1];b+=px[j*4+2];n++}}
      if(n){add.push(i,r/n,g/n,b/n)}}
    if(!add.length)break;
    for(let k=0;k<add.length;k+=4){const i=add[k];px[i*4]=add[k+1];px[i*4+1]=add[k+2];px[i*4+2]=add[k+3];done[i]=1}}}
async function raster(svg){const img=new Image();await new Promise((r,j)=>{img.onload=r;img.onerror=j;img.src=URL.createObjectURL(new Blob([svg],{type:"image/svg+xml"}))});
  const c=document.createElement("canvas");c.width=img.width;c.height=img.height;const g=c.getContext("2d",{willReadFrequently:true});g.drawImage(img,0,0);
  const d=g.getImageData(0,0,c.width,c.height);bleed(c.width,c.height,d.data,6);return await png(c.width,c.height,d.data)}
async function post(url,body){for(let i=0;i<3;i++){const r=await fetch(url,{method:"POST",credentials:"include",headers:{"x-csrf-token":csrf},body});
  if(r.status==403&&r.headers.get("x-csrf-token")){csrf=r.headers.get("x-csrf-token");continue}return r}}
for(const k of KEYS){const svg=A.svg[k];
  window.__oreko.status="raster "+k;const blob=await raster(svg);window.__oreko["size_"+k]=blob.size;
  const fd=new FormData();fd.append("request",JSON.stringify({assetType:"Decal",displayName:"oreko_ls_"+k+"_v3",description:"OREKO loading screen ("+k+", alpha bleed)",creationContext:{creator:{userId:"3696478279"}}}));
  fd.append("fileContent",blob,"oreko_ls_"+k+".png");
  window.__oreko.status="upload "+k;let op=await (await post("https://apis.roblox.com/assets/user-auth/v1/assets",fd)).json(),tries=0;
  while(!op.done&&tries<40){await new Promise(z=>setTimeout(z,1500));tries++;
    const id=(op.path||op.operationId||"").split("/").pop();op=await (await fetch("https://apis.roblox.com/assets/user-auth/v1/operations/"+id,{credentials:"include"})).json()}
  window.__oreko.ids[k]=op.response?op.response.assetId:JSON.stringify(op).slice(0,300);
}
window.__oreko.status="done";}catch(e){window.__oreko.status="error "+e+" "+(e.stack||"")}})();
"started"
