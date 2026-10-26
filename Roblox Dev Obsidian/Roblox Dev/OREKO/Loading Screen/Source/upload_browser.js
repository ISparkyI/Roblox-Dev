// Запускається у вкладці create.roblox.com (користувач увійшов): растеризує SVG з buildAssets() і вантажить як Decal.
window.__oreko={status:"start",ids:{}};window.__orekoKeys=window.__orekoKeys||Object.keys(buildAssets().svg);
(async()=>{try{
const A=buildAssets();let csrf="";
async function raster(svg){const img=new Image();await new Promise((r,j)=>{img.onload=r;img.onerror=j;img.src=URL.createObjectURL(new Blob([svg],{type:"image/svg+xml"}))});
  const c=document.createElement("canvas");c.width=img.width;c.height=img.height;c.getContext("2d").drawImage(img,0,0);return await new Promise(z=>c.toBlob(z,"image/png"))}
async function post(url,body){for(let i=0;i<3;i++){const r=await fetch(url,{method:"POST",credentials:"include",headers:{"x-csrf-token":csrf},body});
  if(r.status==403&&r.headers.get("x-csrf-token")){csrf=r.headers.get("x-csrf-token");continue}return r}}
for(const [k,svg] of Object.entries(A.svg)){ if(!window.__orekoKeys.includes(k)) continue;
  window.__oreko.status="raster "+k;const blob=await raster(svg);
  const fd=new FormData();fd.append("request",JSON.stringify({assetType:"Decal",displayName:"oreko_ls_"+k+"_v2",description:"OREKO loading screen ("+k+")",creationContext:{creator:{userId:"3696478279"}}}));
  fd.append("fileContent",blob,"oreko_ls_"+k+".png");
  window.__oreko.status="upload "+k;const r=await post("https://apis.roblox.com/assets/user-auth/v1/assets",fd);const j=await r.json();
  let op=j,tries=0;
  while(!op.done&&tries<40){await new Promise(z=>setTimeout(z,1500));tries++;
    const id=(op.path||"").split("/").pop();const q=await fetch("https://apis.roblox.com/assets/user-auth/v1/operations/"+id,{credentials:"include"});op=await q.json()}
  window.__oreko.ids[k]=op.response?op.response.assetId:JSON.stringify(op).slice(0,300);
}
window.__oreko.status="done";}catch(e){window.__oreko.status="error "+e}})();
"started"
