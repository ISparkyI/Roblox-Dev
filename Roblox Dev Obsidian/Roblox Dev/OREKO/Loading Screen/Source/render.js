const {buildAssets}=require('./oreko_assets.js');const fs=require('fs');
const {chromium}=require('playwright');
(async()=>{const A=buildAssets();fs.writeFileSync('meta.json',JSON.stringify(A.meta));
const b=await chromium.launch();const p=await b.newPage();
for(const [k,svg] of Object.entries(A.svg)){
  const res=await p.evaluate(async(svg)=>{const img=new Image();await new Promise((r,j)=>{img.onload=r;img.onerror=j;img.src='data:image/svg+xml;base64,'+btoa(unescape(encodeURIComponent(svg)))});
    const c=document.createElement('canvas');c.width=img.width;c.height=img.height;c.getContext('2d').drawImage(img,0,0);return c.toDataURL('image/png')},svg);
  fs.writeFileSync(k+'.png',Buffer.from(res.split(',')[1],'base64'));}
await b.close();console.log('ok')})();
