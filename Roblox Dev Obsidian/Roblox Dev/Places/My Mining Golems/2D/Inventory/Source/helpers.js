const W=1280,H=720,INK="#14161a",FS=0.81;
const A=__ASSETS__;
const stage=document.getElementById("stage"),fit=document.getElementById("fit");
function fitStage(){const aw=Math.min(document.documentElement.clientWidth-32,1280);const s=Math.max(.2,Math.min(aw/W,(window.innerHeight-120)/H,1));stage.style.transform="scale("+s+")";fit.style.width=W*s+"px";fit.style.height=H*s+"px";window.__s=s}
addEventListener("resize",fitStage);
function mk(parent,css,cls,tag){const d=document.createElement(tag||"div");if(cls)d.className=cls;Object.assign(d.style,css||{});parent.appendChild(d);return d}
const px=v=>v+"px";
function box(p,x,y,w,h,bg,z,extra){return mk(p,Object.assign({left:px(x),top:px(y),width:px(w),height:px(h),background:bg||"transparent",zIndex:z==null?"auto":z},extra||{}))}
// текст за «центром великих літер» cy (бокс 1,2×розмір)
function T(p,o){const d=mk(p,{left:px(o.x),top:px(o.cy-o.size*.6),width:px(o.w||400),height:px(o.size*1.2),lineHeight:px(o.size*1.2),fontSize:px(o.size*(o.fs||FS)),textAlign:o.align||"left",color:o.color||"#fff",fontWeight:o.weight||900,zIndex:o.z==null?"auto":o.z},"t");d.style.webkitTextStrokeWidth=px((o.sw||0)*2);d.innerHTML=o.text;return d}
const studSvg=(()=>{const c=40,s=c*.62,o=(c-s)/2,d=s*.12,r=s*.16;return"url(\"data:image/svg+xml;utf8,"+encodeURIComponent(`<svg xmlns='http://www.w3.org/2000/svg' width='40' height='40'><rect x='${o-d/2}' y='${o+d/2}' width='${s}' height='${s}' rx='${r}' fill='#868b92'/><rect x='${o+d/2}' y='${o-d/2}' width='${s}' height='${s}' rx='${r}' fill='#b3b8bf' stroke='#c8ccd1' stroke-width='1'/></svg>`)+"\")"})();
// вікно: тінь, темний обідок, світла лінія, панель зі studs і затіненням (як ForgeWindow)
function windowFrame(p,x,y,w,h,z,dim){
  const root=mk(p,{left:px(x),top:px(y),width:px(w),height:px(h),zIndex:z});
  box(root,0,dim||14,w,h,"rgba(0,0,0,.35)",0);
  const win=box(root,0,0,w,h,"linear-gradient(#5d636b,#3c4047)",1,{boxShadow:"0 0 0 5px "+INK});
  box(win,6,6,w-12,h-12,"transparent",1,{boxShadow:"inset 0 0 0 1.5px rgba(106,112,120,.9)"});
  const pw=w-36,ph=h-36;
  const pan=box(win,18,18,pw,ph,"#a9aeb5",2,{overflow:"hidden",boxShadow:"0 0 0 4px "+INK});
  const nx=Math.floor(pw/40),ny=Math.floor(ph/40);
  box(pan,0,0,pw,ph,studSvg,1,{backgroundSize:"40px 40px",backgroundPosition:((pw-nx*40)/2)+"px "+((ph-ny*40)/2)+"px"});
  box(pan,0,0,pw,ph,"linear-gradient(rgba(0,0,0,.26) 0,rgba(0,0,0,0) 7%,rgba(0,0,0,0) 93%,rgba(255,255,255,.18) 100%)",2);
  const content=box(win,0,0,w,h,"transparent",3);
  return {root,win,content};
}
// ===== StyleA =====
const O=4,B=3,LIP=12,LINE=4;
function faceRect(w,h){const k=h/100,e=(O+B)*k;return[e,e,w-2*e,h-(O+LIP+LINE)*k-e]}
function sa(p,o){
  const w=o.w,h=o.h,[fx,fy,fw,fh]=faceRect(w,h),s=h/200;
  const state={color:o.color,half:!!o.half,enabled:true};
  let shadow=null;
  if(o.shadowDy)shadow=box(p,o.x,o.y+o.shadowDy,w,h,"rgba(0,0,0,.3)",o.z||0);
  const root=mk(p,{left:px(o.x),top:px(o.y),width:px(w),height:px(h),zIndex:(o.z||0)+1,
    borderWidth:`${14*s}px ${14*s}px ${40*s}px ${14*s}px`,borderImageSlice:"14 14 40 14 fill",borderImageWidth:`${14*s}px ${14*s}px ${40*s}px ${14*s}px`,borderImageRepeat:"stretch"},"sa"+(o.clickable?"":" nc"));
  // border-width уже займе місце: компенсуємо, щоб розмір кореня = w×h
  root.style.boxSizing="border-box";
  const face=mk(root,{left:px(fx-14*s),top:px(fy-14*s),width:px(fw),height:px(fh)},"face");
  const cell=fh/(o.rows||(h>=70?4:3)),t=2*cell,ox=(fw%cell)/2-t;
  const tile=mk(face,{left:px(ox),top:0,width:px(fw-ox),height:px(fh),backgroundSize:px(t)+" "+px(t)},"tile");
  let icon=null,label=null;
  const api={root,shadow,face,state,w,h,fx,fy,fw,fh};
  api.setColor=c=>{state.color=c;root.style.borderImageSource=`url(${A["base_"+c]})`;tile.style.backgroundImage=`url(${A["tile_"+c+(state.half?"_half":"")]||A["tile_"+c]||A["tile_"+c+"_half"]})`;if(sh)sh.style.display=(c==="gray")?"none":""};
  let sh=null;
  if(o.shine){sh=mk(face,{},"shine")}
  api.setColor(o.color);
  if(o.icon){const m=(o.iconPad||0)*fh;icon=mk(face,{left:px(m),top:px(m),width:px(fw-2*m),height:px(fh-2*m),objectFit:"contain",pointerEvents:"none",zIndex:2},"","img");icon.src=o.icon;icon.draggable=false;api.icon=icon}
  if(o.text!=null||o.size){const ts=o.size||Math.floor(fh*.52+.5);label=T(face,{x:0,cy:fh/2,w:fw,size:ts,align:"center",text:o.text||"",sw:o.sw!=null?o.sw:ts*.08,z:4});label.style.top=px(0);label.style.height=px(fh);label.style.lineHeight=px(fh);api.label=label}
  api.setText=txt=>{if(label)label.innerHTML=txt};
  api.shake=()=>{root.animate([{transform:"translateX(0)"},{transform:"translateX(-10px)"},{transform:"translateX(10px)"},{transform:"translateX(-7px)"},{transform:"translateX(7px)"},{transform:"translateX(-3px)"},{transform:"translateX(0)"}],{duration:300,easing:"linear"})};
  api.setEnabled=(en,txtColor)=>{state.enabled=en;api.setColor(en?(o.enabledColor||"green"):"gray");if(sh)sh.style.display=en?"":"none"};
  // hover 1.04 / press 0.92
  if(o.clickable){
    let hov=false,dn=false;const upd=()=>{root.style.transform=`scale(${dn?.92:hov?1.04:1})`};
    root.addEventListener("pointerenter",()=>{hov=true;upd()});root.addEventListener("pointerleave",()=>{hov=false;dn=false;upd()});
    root.addEventListener("pointerdown",e=>{dn=true;upd()});root.addEventListener("pointerup",()=>{dn=false;upd()});
    root.addEventListener("click",e=>{if(o.onClick)o.onClick(api,e)});
  }
  return api;
}
function raw(p,x,y,w,txt,sz,col,sw,al,wt){return T(p,{x,cy:y,w,size:sz,text:txt,color:col,sw,align:al||"left",weight:wt})}
