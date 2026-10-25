window.__export=function(){
  // ---- поза спокою для експорту: кістки без обертань ----
  anim='rest'; at0=clock; prevPose=null; blendT=1; update(0);
  SP.rotation.set(0,0,0); H.rotation.set(0,0,0);
  HT.position.set(0,2.6,-0.1); HT.rotation.set(0,0,0);
  G.beard.rotation.set(0,0,0); G.mouth.g.scale.set(1,1,1);
  G.mouth.cL.position.y=0.05; G.mouth.cR.position.y=0.05; G.mouth.cL.rotation.set(0,0,0); G.mouth.cR.rotation.set(0,0,0);
  must.forEach(m=>m.rotation.set(0,0,0));
  for(const a of [G.A,G.B]){a.sh.quaternion.identity();a.el.quaternion.identity();a.hand.quaternion.identity();}
  G.eyes.forEach(e=>{e.lid.scale.set(1,1,1);e.lid.position.y=0.29;e.pupil.position.set(0,-0.03,0.04);e.brow.rotation.set(0,0,0);e.brow.position.y=0.52;e.dollar.visible=true;e.pupil.visible=true;});
  beam.rotation.set(0,0,0); pans.forEach(pn=>pn.g.position.set(pn.s*SB,3.0,0));
  bellDome.rotation.set(0,0,0); bellDome.position.set(0,0.15,0);
  beads.forEach(b=>b.m.position.x=b.base);
  G.coin.visible=true; G.coins3.visible=true; heap.forEach(h=>h.visible=true); stacks.forEach(s=>s.coins.forEach(c=>c.visible=true));
  scene.updateMatrixWorld(true);
  const BONES=[['R',R,'Static'],['SP',SP,'R'],['H',H,'SP'],['HT',HT,'H'],['Beard',G.beard,'H'],['Mouth',G.mouth.g,'H'],
    ['MustN',must[0],'H'],['MustP',must[1],'H'],['EyeN',G.eyes[0].e,'H'],['EyeP',G.eyes[1].e,'H'],
    ['AS',G.A.sh,'SP'],['AE',G.A.el,'AS'],['AH',G.A.hand,'AE'],['BS',G.B.sh,'SP'],['BE',G.B.el,'BS'],['BH',G.B.hand,'BE'],
    ['BellDome',bellDome,'Static'],['ScaleBase',scale,'Static'],['Beam',beam,'ScaleBase'],['PanN',pans[0].g,'ScaleBase'],['PanP',pans[1].g,'ScaleBase']];
  const boneOf=new Map(); BONES.forEach(b=>boneOf.set(b[1],b[0]));
  const inv=new T.Matrix4();
  const toArr=(m)=>{const p=new T.Vector3(),q=new T.Quaternion(),s=new T.Vector3();m.decompose(p,q,s);const r=new T.Matrix4().makeRotationFromQuaternion(q).elements;
    return {cf:[p.x,p.y,p.z,r[0],r[4],r[8],r[1],r[5],r[9],r[2],r[6],r[10]].map(v=>+v.toFixed(5)),s:[s.x,s.y,s.z]};};
  const bones=BONES.map(([name,obj,par])=>{let m=obj.matrixWorld.clone(); if(par!=='Static'){const po=BONES.find(b=>b[0]===par)[1]; m=new T.Matrix4().copy(po.matrixWorld).invert().multiply(obj.matrixWorld);} return {name,parent:par,...toArr(m)};});
  const tags=new Map();
  const tag=(o,k,v=true)=>{if(!o)return; const t=tags.get(o)||{}; t[k]=v; tags.set(o,t);};
  stacks[0].coins.forEach((c,i)=>tag(c,'StackCoin',i+1));
  heap.forEach((h,i)=>tag(h,'Heap',i+1));
  beads.forEach(b=>{tag(b.m,'BeadR',b.r);tag(b.m,'BeadB',b.b);});
  tag(G.coin,'HandCoin'); G.coins3.children.forEach(c=>tag(c,'PayCoin'));
  tag(heart,'Heart'); tag(lg,'LampGlass'); tag(nr,'Gui','norefunds'); tag(cbf,'Gui','prices');
  G.eyes.forEach(e=>{tag(e.lid,'Lid');tag(e.pupil,'Pupil');tag(e.brow,'Brow');tag(e.dollar,'EyeDollar');tag(e.dollar,'Gui','eyedollar');});
  tag(G.mouth.dark,'MouthDark'); tag(G.mouth.tooth,'Tooth'); tag(G.mouth.tooth2,'Tooth2'); tag(G.mouth.cL,'MouthC',-1); tag(G.mouth.cR,'MouthC',1);
  tag(pans[0].dish,'PanDish',-1); tag(pans[1].dish,'PanDish',1);
  const parts=[]; const skip=new Set([env,ring,player,scaleLoad]);
  const roots=[stall,cart];
  function bone(o){let q=o.parent;while(q){if(boneOf.has(q))return q;q=q.parent;}return null;}
  function addPart(mesh,geo,extra){
    const b=bone(mesh); const bname=b?boneOf.get(b):'Static';
    let m=mesh.matrixWorld.clone(); if(b) m=new T.Matrix4().copy(b.matrixWorld).invert().multiply(m);
    if(extra&&extra.local) m.multiply(extra.local);
    const a=toArr(m); const sc=a.s;
    const mt=mesh.material; const o={bone:bname,cf:a.cf,tags:tags.get(mesh)||{}};
    // геометрія
    if(geo.type==='box'){o.shape='Block';o.size=[geo.w*sc[0],geo.h*sc[1],geo.d*sc[2]];}
    else if(geo.type==='cyl'){o.shape='Cylinder';o.size=[geo.h*sc[1],2*geo.r*sc[0],2*geo.r*sc[2]];o.cylY=true;}
    else if(geo.type==='ball'){o.shape='Ball';o.size=[2*geo.r*sc[0],2*geo.r*sc[0],2*geo.r*sc[0]];}
    else if(geo.type==='disc'){o.shape='Cylinder';o.size=[0.03,2*geo.r*sc[0],2*geo.r*sc[1]];o.cylZ=true;}
    else if(geo.type==='plane'){o.shape='Block';o.size=[geo.w*sc[0],geo.h*sc[1],0.04];}
    Object.assign(o,extra&&extra.override||{});
    // матеріал
    const lin2s=c=>c.clone().convertLinearToSRGB().getHexString();
    if(mt.isMeshBasicMaterial){o.mat='Neon';o.color=lin2s(mt.color);o.tr=mt.transparent?+(1-mt.opacity).toFixed(2):0;if(mt.map){o.mat='SmoothPlastic';o.tr=1;}}
    else{o.color=lin2s(mt.color);o.mat=mt.map===STUD?'Studs':'SmoothPlastic';
      if(mt.transparent&&mt.opacity<1){o.mat='Glass';o.tr=+(1-mt.opacity*0.6).toFixed(2);}
      if(mt.emissive&&(mt.emissive.r+mt.emissive.g+mt.emissive.b)>0.01){o.mat='Neon';}
      if(mt.metalness>0.3) o.metal=true;
      if(mt.map&&mt.map!==STUD){ if(mt.map===sack){o.color='c9a46a';o.tags={...o.tags,Gui:'sack'};} else if(mt.map===pg){o.color='f4ecd6';o.tags={...o.tags,Gui:'page'};} else o.color='ffffff'; }
    }
    if(mesh.parent===coinBig && geo.type==='plane'){o.tags={...o.tags,Gui:'plaquedollar'};o.tr=1;o.mat='SmoothPlastic';}
    o.cast=mesh.castShadow!==false;
    parts.push(o);
  }
  const walk=(o)=>{ if(skip.has(o)) return;
    if(o.isMesh){const g=o.geometry,p=g.parameters||{};
      if(g.type==='BoxGeometry') addPart(o,{type:'box',w:p.width,h:p.height,d:p.depth});
      else if(g.type==='CylinderGeometry') addPart(o,{type:'cyl',r:Math.max(p.radiusTop,p.radiusBottom),h:p.height});
      else if(g.type==='SphereGeometry') addPart(o,{type:'ball',r:p.radius});
      else if(g.type==='CircleGeometry') addPart(o,{type:'disc',r:p.radius});
      else if(g.type==='PlaneGeometry') addPart(o,{type:'plane',w:p.width,h:p.height});
      else if(g.type==='TorusGeometry'){ // монокль: 12 сегментів
        const N=12, R0=p.radius, th=p.tube*2; for(let i=0;i<N;i++){const a=i/N*Math.PI*2; const loc=new T.Matrix4().compose(new T.Vector3(Math.cos(a)*R0,Math.sin(a)*R0,0),new T.Quaternion().setFromEuler(new T.Euler(0,0,a)),new T.Vector3(1,1,1));
          addPart(o,{type:'box',w:th,h:2*Math.PI*R0/N+0.02,d:th},{local:loc});}
      }
    }
    o.children.forEach(walk);};
  roots.forEach(walk);
  // анімації
  const anims={}; for(const k in ANIMS){const a=ANIMS[k]; anims[k]={len:a.len,loop:!!a.loop,next:a.next||null,keys:a.tr.map(([t,p])=>({t,p}))};}
  return JSON.stringify({bones,parts,anims,special:SPECIAL,base:BASE,rest:{A:REST_A,B:REST_B},consts:{SB,CT,RING_R,ringC:ringC.toArray(),signAnchor:signAnchor.toArray(),
    poleA:[4.5,4.5,-1.5],poleB:[-4.5,4.5,-1.5],L1:G.A.L1,L2:G.A.L2,elY:-2.0,handY:-1.8}});
};
