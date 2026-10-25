// Ore chunks + bars, block style (Roblox parts: b = Part Block, w = WedgePart, c = CornerWedgePart).
// Units = studs. Pivot: bottom centre (y = 0). Each part: {t, s:[x,y,z], m:Matrix4 elements (column-major), c:'hex'}
// WedgePart: bottom full, tall edge at +Z top (slope faces -Z/up). CornerWedgePart: apex over corner (+X, top, -Z).
(function (root) {
  const THREE = root.THREE || require('three');
  const D = Math.PI / 180;
  const M = (p = [0, 0, 0], r = [0, 0, 0]) => new THREE.Matrix4().compose(new THREE.Vector3(p[0], p[1], p[2]),
    new THREE.Quaternion().setFromEuler(new THREE.Euler(r[0] * D, r[1] * D, r[2] * D, 'XYZ')), new THREE.Vector3(1, 1, 1));

  const PAL = {
    rock: '7f8a96', rockD: '5f6974',
    coal: { main: '2f343c', core: '1b1e23', glint: 'aab3bd' },
    copper: { main: 'ff7a2e', core: 'b8481a', glint: 'fff1e0', patina: '58c2a0' },
    iron: { main: 'dcb08c', core: '9c6b4c', glint: 'fff6ec' },
    barCu: { main: 'f07a35', dark: 'b4501f', glint: 'ffd2a8' },
    barFe: { main: 'c3c9d1', dark: '868e98', glint: 'f4f7fa' },
    // злитки з «намальованим світлом»: верх, довгі схили, торці (+ кути), підошва
    barCuL: { top: 'ff9150', side: 'e66d2c', end: 'c2561d', sole: '96401a' },
    barCuF: { top: 'ffa066', pz: 'f47f3a', px: 'e06a2c', nz: 'cc5c24', nx: 'b84f1b', sole: 'e56223' },
    barFeF: { top: 'd6dce4', pz: 'cbd2db', px: 'b8c0cb', nz: 'a5aebb', nx: '949eab', sole: 'b2c2d8' },
    barFeL: { top: 'd9dee5', side: 'b4bcc7', end: '939dab', sole: '6f7987' },
    briq: { main: '2c2f35', dark: '17191d', glint: '5d646e' },
  };

  class Build {
    constructor() { this.parts = []; }
    add(t, s, p, r, c, parent) {
      const m = parent ? parent.clone().multiply(M(p, r)) : M(p, r);
      this.parts.push({ t, s: s.slice(), m: m.elements.slice(), c });
      return m;
    }
    b(s, p, r, c, P) { return this.add('b', s, p, r, c, P); }
    w(s, p, r, c, P) { return this.add('w', s, p, r, c, P); }
    cw(s, p, r, c, P) { return this.add('c', s, p, r, c, P); }
    frame(p, r, P) { return P ? P.clone().multiply(M(p, r)) : M(p, r); }
  }

  // mass + rounder (same mass, smaller in XZ, 0.1 inside on top & bottom, turned ~42 deg) -> octagon-ish silhouette
  function lump(B, P, s, c, opt = {}) {
    const m = B.b(s, [0, s[1] / 2, 0], [0, 0, 0], c, P);
    const k = opt.k || 0.86;
    B.b([s[0] * k, s[1] - 0.2, s[2] * k], [0, s[1] / 2, 0], [0, opt.turn || 42, 0], c, P);
    return m;
  }
  // face frames of a block (host local): z of the frame points out of the face
  const FACE = {
    '+z': (h) => M([0, 0, h[2] / 2], [0, 0, 0]), '-z': (h) => M([0, 0, -h[2] / 2], [0, 180, 0]),
    '+x': (h) => M([h[0] / 2, 0, 0], [0, 90, 0]), '-x': (h) => M([-h[0] / 2, 0, 0], [0, -90, 0]),
    '+y': (h) => M([0, h[1] / 2, 0], [-90, 0, 0]),
  };
  // ore patch: main plate (out 0.1), core (out 0.2), optional glint (out 0.3). u,v - offset on the face, roll - deg
  function patch(B, hostM, hostS, face, u, v, w, h, roll, pal, o = {}) {
    const F = hostM.clone().multiply(FACE[face](hostS)).multiply(M([u, v, 0], [0, 0, roll]));
    const t = o.t || 0.2;
    B.b([w, h, t], [0, 0, 0.1 - t / 2], [0, 0, 0], pal.main, F);
    if (o.core !== false) {
      const cw = w * (o.ck || 0.5), ch = h * (o.ck || 0.5);
      B.b([cw, ch, t], [o.cu || w * 0.12, o.cv || -h * 0.1, 0.2 - t / 2], [0, 0, o.croll || 0], pal.core, F);
    }
    if (o.glint !== false) {
      const g = o.g || 0.12;
      B.b([g, g, t], [o.gu != null ? o.gu : -w * 0.25, o.gv != null ? o.gv : h * 0.22, 0.3 - t / 2], [0, 0, 45], pal.glint, F);
    }
    return F;
  }


  // зрізана піраміда (трапеція з усіх боків): тіло l×H×w (колір top) + 4 клини + 4 кутові клини (колір side).
  // низ L×W на y=0 рамки P. Повертає рамки граней для плит: top (блок) і схили '+z','-z','+x','-x' (клини)
  function frustum(B, P, L, W, H, l, w, side, top) {
    const dx = (L - l) / 2, dz = (W - w) / 2, y = H / 2, cx = l / 2 + dx / 2, cz = w / 2 + dz / 2;
    const r = { top: B.b([l, H, w], [0, y, 0], [0, 0, 0], top || side, P), topS: [l, H, w], sl: {} };
    r.sl['+z'] = [B.w([l, H, dz], [0, y, cz], [0, 180, 0], side, P), [l, H, dz]];
    r.sl['-z'] = [B.w([l, H, dz], [0, y, -cz], [0, 0, 0], side, P), [l, H, dz]];
    r.sl['+x'] = [B.w([w, H, dx], [cx, y, 0], [0, -90, 0], side, P), [w, H, dx]];
    r.sl['-x'] = [B.w([w, H, dx], [-cx, y, 0], [0, 90, 0], side, P), [w, H, dx]];
    B.cw([dx, H, dz], [-cx, y, cz], [0, 0, 0], side, P);
    B.cw([dz, H, dx], [cx, y, cz], [0, 90, 0], side, P);
    B.cw([dx, H, dz], [cx, y, -cz], [0, 180, 0], side, P);
    B.cw([dz, H, dx], [-cx, y, -cz], [0, -90, 0], side, P);
    return r;
  }
  // піраміда з 4 кутових клинів (вершина в центрі над основою s×s, висота h)
  function pyramid(B, P, s, h, c) {
    const q = s / 4;
    B.cw([s / 2, h, s / 2], [-q, h / 2, q], [0, 0, 0], c, P);
    B.cw([s / 2, h, s / 2], [q, h / 2, q], [0, 90, 0], c, P);
    B.cw([s / 2, h, s / 2], [q, h / 2, -q], [0, 180, 0], c, P);
    B.cw([s / 2, h, s / 2], [-q, h / 2, -q], [0, -90, 0], c, P);
  }
  // октаедр: дві піраміди основа до основи (центр рамки — центр октаедра)
  function octa(B, P, s, h, cTop, cBot) {
    pyramid(B, P, s, h, cTop);
    pyramid(B, P.clone().multiply(M([0, 0, 0], [180, 0, 0])), s, h, cBot || cTop);
  }
  // кругляк: маса + округлювач + шапка з округлювачем (4 блоки) — «галька»
  function pebble(B, P, s, c, capK = 0.62, capH = 0.42) {
    const m = lump(B, P, s, c, { turn: 42 });
    const cs = [s[0] * capK, s[1] * capH + 0.1, s[2] * capK];
    const Pc = B.frame([0, s[1] - 0.1, 0], [0, 18, 0], P);
    lump(B, Pc, cs, c, { turn: 45 });
    return m;
  }
  // плита на схилі клина (u — вздовж ребра, v — вгору по схилу)
  function slopePatch(B, wm, ws, u, v, w, h, roll, pal, o = {}) {
    const [, H, d] = ws, L = Math.hypot(H, d);
    const n = new THREE.Vector3(0, d / L, -H / L), up = new THREE.Vector3(0, H / L, d / L), x = new THREE.Vector3().crossVectors(up, n);
    const F = wm.clone().multiply(new THREE.Matrix4().makeBasis(x, up, n)).multiply(M([u, v, 0], [0, 0, roll]));
    return layers(B, F, w, h, pal, o);
  }
  function layers(B, F, w, h, pal, o) {
    const t = o.t || 0.2;
    B.b([w, h, t], [0, 0, 0.1 - t / 2], [0, 0, 0], pal.main, F);
    if (o.core !== false) B.b([w * (o.ck || 0.5), h * (o.ck || 0.5), t], [o.cu != null ? o.cu : w * 0.12, o.cv != null ? o.cv : -h * 0.1, 0.2 - t / 2], [0, 0, o.croll || 0], pal.core, F);
    if (o.glint !== false) { const g = o.g || 0.12; B.b([g, g, t], [o.gu != null ? o.gu : -w * 0.25, o.gv != null ? o.gv : h * 0.22, 0.3 - t / 2], [0, 0, 45], pal.glint, F); }
    return F;
  }
  function patch(B, hostM, hostS, face, u, v, w, h, roll, pal, o = {}) {
    return layers(B, hostM.clone().multiply(FACE[face](hostS)).multiply(M([u, v, 0], [0, 0, roll])), w, h, pal, o);
  }
  // опора моделі: нижня точка на y = 0 (правило GDD)
  function ground(parts) {
    let minY = Infinity;
    for (const p of parts) {
      const m = new THREE.Matrix4().fromArray(p.m), [x, y, z] = p.s.map(v => v / 2);
      // справжні вершини: блок 8, клин 6 (без верхнього переднього ребра), кутовий клин 5 (низ + вершина над (+x, -z))
      const V = p.t === 'b' ? [[-1,-1,-1],[1,-1,-1],[1,1,-1],[-1,1,-1],[-1,-1,1],[1,-1,1],[1,1,1],[-1,1,1]]
        : p.t === 'w' ? [[-1,-1,-1],[1,-1,-1],[1,-1,1],[-1,-1,1],[-1,1,1],[1,1,1]] : [[-1,-1,-1],[1,-1,-1],[1,-1,1],[-1,-1,1],[1,1,-1]];
      for (const v of V) minY = Math.min(minY, new THREE.Vector3(v[0] * x, v[1] * y, v[2] * z).applyMatrix4(m).y);
    }
    // клини/кутові клини мають вершини лише на частині кутів бокса, але нижні кути завжди є — тож мінімум коректний
    for (const p of parts) p.m[13] -= minY;
    return parts;
  }
  const G = f => () => ground(f());

  // ================= V1 «Грані»: чиста руда, гранені форми з клинів =================
  const V1 = {};
  V1.coal = G(() => { // антрацит: гранена трапеція + сколотий гребінь, блиск на ребрах
    const B = new Build(), c = PAL.coal, P = M([0, 0, 0], [0, 12, 0]);
    frustum(B, P, 1.16, 0.94, 0.4, 0.76, 0.58, c.main, c.main);
    const R = B.frame([0.04, 0.3, 0.0], [0, -14, 4], P);
    B.w([0.66, 0.34, 0.3], [0, 0.17, -0.15], [0, 0, 0], c.main, R);
    B.w([0.56, 0.24, 0.26], [0.02, 0.12, 0.13], [0, 180, 0], c.core, R);
    B.b([0.2, 0.06, 0.06], [-0.08, 0.32, 0.0], [0, 0, 0], c.glint, R);
    const S = B.frame([-0.44, 0.24, 0.22], [0, 50, 22], P);
    B.w([0.34, 0.26, 0.24], [0, 0, 0], [0, 0, 0], c.core, S);
    B.b([0.07, 0.07, 0.36], [0.47, 0.26, 0.0], [0, 0, 0], c.glint, P);
    B.b([0.1, 0.1, 0.1], [-0.24, 0.47, -0.16], [45, 20, 45], c.glint, P);
    return B.parts;
  });
  V1.copper = G(() => { // самородок: восьмигранна основа + гранований купол + маленький наріст
    const B = new Build(), c = PAL.copper, P = M([0, 0, 0], [0, -12, 0]);
    const s1 = [0.96, 0.32, 0.86]; const m1 = lump(B, P, s1, c.main, { turn: 42 });
    const f = frustum(B, B.frame([0, 0.22, 0], [0, 22, 0], P), 0.78, 0.7, 0.3, 0.44, 0.38, c.main, c.main);
    const P2 = B.frame([0.5, 0.0, 0.26], [0, 30, -6], P); lump(B, P2, [0.44, 0.34, 0.42], c.main, { turn: 44 });
    patch(B, m1, s1, '+z', -0.2, -0.02, 0.28, 0.16, 6, { main: c.core, core: c.patina }, { glint: false, ck: 0.45, cu: 0.0, cv: 0 });
    slopePatch(B, f.sl['-x'][0], f.sl['-x'][1], 0.04, 0.0, 0.22, 0.12, 0, { main: c.core }, { core: false, glint: false });
    B.b([0.12, 0.12, 0.12], [0.06, 0.62, 0.0], [45, 0, 45], c.glint, P);
    B.b([0.09, 0.09, 0.09], [0.52, 0.42, 0.28], [45, 30, 45], c.glint, P);
    return B.parts;
  });
  V1.iron = G(() => { // октаедри (як магнетит): великий кристал лежить на грані, менший проріс збоку
    const B = new Build(), c = PAL.iron, P = M([0, 0, 0], [0, 10, 0]);
    octa(B, B.frame([0, 0.42, 0], [34, 20, 10], P), 0.8, 0.46, c.main, c.core);
    octa(B, B.frame([0.42, 0.3, 0.28], [-18, 60, 26], P), 0.46, 0.27, c.core, c.main);
    B.b([0.12, 0.12, 0.12], [-0.08, 0.86, 0.06], [45, 10, 45], c.glint, P);
    B.b([0.09, 0.09, 0.09], [0.5, 0.6, 0.3], [45, 40, 45], c.glint, P);
    return B.parts;
  });

  // ================= V2 «Уламок жили»: сірий камінь із рудними плитами, як на жилах =================
  const V2 = {};
  V2.coal = G(() => { // плаский уламок: на верху велика плита вугілля, ще дві на схилах
    const B = new Build(), c = PAL.coal, P = M([0, 0, 0], [0, 8, 0]);
    const f = frustum(B, P, 1.22, 0.96, 0.36, 0.86, 0.62, PAL.rock, PAL.rock);
    patch(B, f.top, f.topS, '+y', -0.02, 0.02, 0.62, 0.42, 10, c, { ck: 0.55, gu: -0.18, gv: 0.1 });
    slopePatch(B, f.sl['+z'][0], f.sl['+z'][1], 0.18, 0.0, 0.42, 0.14, -4, c, { glint: false, ck: 0.5 });
    slopePatch(B, f.sl['-x'][0], f.sl['-x'][1], -0.06, 0.0, 0.34, 0.14, 6, c, { core: false, glint: false });
    B.b([0.24, 0.18, 0.22], [-0.64, 0.09, 0.4], [0, 30, 0], PAL.rockD, P);
    return B.parts;
  });
  V2.copper = G(() => { // круглий валун з шапкою, мідь трьома плитами
    const B = new Build(), c = PAL.copper, P = M([0, 0, 0], [0, -6, 0]);
    const s1 = [1.0, 0.5, 0.9]; const m1 = pebble(B, P, s1, PAL.rock, 0.64, 0.46);
    patch(B, m1, s1, '+z', 0.08, 0.0, 0.54, 0.3, -10, c, { ck: 0.5 });
    patch(B, m1, s1, '+x', -0.06, -0.02, 0.42, 0.28, 14, c, { gu: 0.1, gv: 0.06 });
    patch(B, m1, s1, '-x', 0.1, 0.0, 0.32, 0.22, -8, c, { glint: false });
    B.b([0.42, 0.22, 0.26], [-0.34, 0.11, -0.44], [0, -18, 0], PAL.rockD, P);
    B.b([0.13, 0.13, 0.13], [0.02, 0.8, 0.04], [45, 0, 45], c.main, P);
    return B.parts;
  });
  V2.iron = G(() => { // високий кутастий уламок, нахилений; залізо на схилах і верху
    const B = new Build(), c = PAL.iron, P = M([0, 0, 0], [0, 14, 6]);
    const f = frustum(B, P, 0.96, 0.84, 0.6, 0.6, 0.5, PAL.rock, PAL.rockD);
    slopePatch(B, f.sl['+z'][0], f.sl['+z'][1], -0.04, 0.0, 0.42, 0.34, 6, c, { ck: 0.5, gu: -0.1, gv: 0.06 });
    slopePatch(B, f.sl['+x'][0], f.sl['+x'][1], 0.04, 0.02, 0.34, 0.3, -8, c, { glint: false });
    patch(B, f.top, f.topS, '+y', 0.0, 0.0, 0.34, 0.28, 24, c, { core: false, gu: 0.0, gv: 0.0 });
    B.b([0.4, 0.3, 0.34], [-0.5, 0.15, -0.3], [0, 30, 0], PAL.rock, P);
    return B.parts;
  });

  // ================= V3 «Друза»: кристали ростуть із пласкої кам'яної основи =================
  const V3 = {};
  const crystal = (B, P, w, h, d, c, tip) => {
    B.b([w, h, d], [0, h / 2, 0], [0, 0, 0], c.main, P);
    B.w([w, tip, d / 2], [0, h + tip / 2 - 0.1, -d / 4], [0, 0, 0], c.main, P);
    B.w([w, tip, d / 2], [0, h + tip / 2 - 0.1, d / 4], [0, 180, 0], c.core, P);
  };
  V3.coal = G(() => { // вугільний пласт: шари вугілля й породи, косий злам
    const B = new Build(), P = M([0, 0, 0], [0, 6, 0]), c = PAL.coal;
    B.b([1.1, 0.2, 0.82], [0, 0.1, 0], [0, 0, 0], PAL.rockD, P);
    B.b([1.0, 0.24, 0.72], [0.02, 0.29, 0.0], [0, 4, 0], c.main, P);
    B.b([0.86, 0.12, 0.62], [0.06, 0.45, -0.02], [0, 9, 0], PAL.rock, P);
    B.b([0.74, 0.22, 0.54], [0.08, 0.6, -0.04], [0, 14, 0], c.main, P);
    B.w([0.6, 0.24, 0.3], [0.1, 0.8, 0.06], [0, 194, 0], c.core, P);
    B.b([0.44, 0.07, 0.07], [0.02, 0.31, 0.4], [0, 4, 0], c.glint, P);
    B.b([0.3, 0.07, 0.07], [0.14, 0.62, 0.3], [0, 14, 0], c.glint, P);
    B.b([0.24, 0.18, 0.22], [-0.56, 0.36, 0.2], [0, 30, 10], c.core, P);
    return B.parts;
  });
  V3.copper = G(() => { // мідні кристали віялом із каменю
    const B = new Build(), P = M([0, 0, 0], [0, -8, 0]);
    frustum(B, P, 1.0, 0.84, 0.26, 0.7, 0.56, PAL.rockD, PAL.rock);
    crystal(B, B.frame([0, 0.12, 0], [0, 10, 0], P), 0.3, 0.62, 0.3, PAL.copper, 0.28);
    crystal(B, B.frame([0.28, 0.1, 0.14], [0, 40, -24], P), 0.24, 0.48, 0.24, PAL.copper, 0.22);
    crystal(B, B.frame([-0.26, 0.1, -0.08], [12, -20, 26], P), 0.22, 0.42, 0.22, PAL.copper, 0.2);
    crystal(B, B.frame([0.02, 0.12, 0.3], [-30, 70, 0], P), 0.18, 0.3, 0.18, PAL.copper, 0.16);
    B.b([0.1, 0.1, 0.1], [0.06, 0.55, 0.17], [45, 0, 45], PAL.copper.glint, P);
    return B.parts;
  });
  V3.iron = G(() => { // «залізна троянда»: віяло пласких плит на камені
    const B = new Build(), P = M([0, 0, 0], [0, 4, 0]), c = PAL.iron;
    frustum(B, P, 0.98, 0.84, 0.24, 0.7, 0.56, PAL.rockD, PAL.rock);
    const plates = [[0, 0.5, 0, 0, 0, 0.62, 0.5], [0.04, 0.48, 0.02, 0, 60, 0.56, 0.46], [0.02, 0.46, -0.02, 0, 120, 0.58, 0.42],
      [0.24, 0.4, 0.1, 0, 25, 0.4, 0.34], [-0.24, 0.4, -0.08, 0, 95, 0.38, 0.32]];
    plates.forEach((q, i) => {
      const m = B.b([q[5], q[6], 0.12], [q[0], q[1] - 0.08 + q[6] / 2 - 0.25, q[2]], [i % 2 ? 8 : -8, q[4], i % 2 ? -6 : 6], i < 3 ? c.main : c.core, P);
      if (i < 3) B.b([q[5] * 0.5, q[6] * 0.4, 0.32], [0.04, q[6] * 0.12, 0], [0, 0, 0], c.core, m);
    });
    B.b([0.1, 0.1, 0.1], [0.08, 0.66, 0.06], [45, 0, 45], c.glint, P);
    return B.parts;
  });

  // ================= V4 «Друза 2»: та сама ідея, кристали з пірамідальними вершинами =================
  const V4 = {};
  const rockBase = (B, P, s) => { lump(B, P, s, PAL.rockD, { turn: 40 }); B.b([0.26, 0.16, 0.22], [-s[0] / 2 + 0.06, 0.08, s[2] / 2 - 0.04], [0, 28, 0], PAL.rock, P); };
  // кристал: призма-ромб + піраміда на вершині (4 кутові клини, основа = верх призми — грані дивляться одна на одну)
  const xtal = (B, P, a, h, tip, c, cTip) => {
    B.b([a, h, a], [0, h / 2, 0], [0, 0, 0], c, P);
    pyramid(B, B.frame([0, h, 0], [0, 0, 0], P), a, tip, cTip || c);
  };
  V4.coal = G(() => { // вугільний пласт: гранений шар вугілля на камені, прошарок породи, сколотий гребінь
    const B = new Build(), c = PAL.coal, P = M([0, 0, 0], [0, 6, 0]);
    rockBase(B, P, [1.12, 0.22, 0.9]);
    const f = frustum(B, B.frame([0, 0.12, 0], [0, 4, 0], P), 1.04, 0.82, 0.3, 0.74, 0.54, c.main, c.main);
    lump(B, B.frame([0.04, 0.32, 0.0], [0, 16, 0], P), [0.72, 0.12, 0.54], PAL.rock, { turn: 44 }); // прошарок породи
    const R = B.frame([0.06, 0.34, 0.0], [0, 18, 0], P);
    B.w([0.6, 0.3, 0.26], [0, 0.15, -0.13], [0, 0, 0], c.main, R);
    B.w([0.5, 0.22, 0.22], [0.02, 0.11, 0.11], [0, 180, 0], c.core, R);
    slopePatch(B, f.sl['+z'][0], f.sl['+z'][1], 0.12, 0.0, 0.42, 0.06, 0, { main: c.glint }, { core: false, glint: false, t: 0.12 });
    B.b([0.1, 0.1, 0.1], [-0.18, 0.62, -0.06], [45, 18, 45], c.glint, P);
    return B.parts;
  });
  V4.copper = G(() => { // три кристали-ромби з гострими вершинами, віялом з каменю
    const B = new Build(), c = PAL.copper, P = M([0, 0, 0], [0, -8, 0]);
    rockBase(B, P, [1.0, 0.24, 0.86]);
    xtal(B, B.frame([-0.02, 0.1, -0.02], [6, 45, -4], P), 0.32, 0.5, 0.3, c.main);
    xtal(B, B.frame([0.26, 0.08, 0.18], [0, 20, -28], P), 0.26, 0.36, 0.24, c.main);
    xtal(B, B.frame([-0.28, 0.08, 0.14], [22, 60, 18], P), 0.22, 0.28, 0.2, c.core, c.main);
    B.b([0.1, 0.1, 0.1], [0.04, 0.5, 0.2], [45, 0, 45], c.glint, P);
    return B.parts;
  });
  V4.iron = G(() => { // «залізна троянда»: пелюстки-пластини навколо центру, темні ромби-ядра
    const B = new Build(), c = PAL.iron, P = M([0, 0, 0], [0, 10, 0]);
    rockBase(B, P, [0.98, 0.22, 0.86]);
    const petal = (yaw, r, tilt, w, h, col) => {
      const F = B.frame([0, 0.14, 0], [0, yaw, 0], P).multiply(M([0, 0, r], [-tilt, 0, 0]));
      const m = B.b([w, h, 0.12], [0, h / 2, 0], [0, 0, 0], col, F);
      B.b([w * 0.42, h * 0.42, 0.32], [0, 0.02, 0], [0, 0, 45], c.core, m);
    };
    [0, 90, 180, 270].forEach((y, i) => petal(y + 20, 0.24, 38, 0.56, 0.42, c.main));
    petal(65, 0.02, 8, 0.46, 0.54, c.main);
    B.b([0.1, 0.1, 0.1], [0.02, 0.7, 0.04], [45, 0, 45], c.glint, P);
    return B.parts;
  });

  // ================= V5 «Друза 3»: вугілля без каменю, шестикутні підставки =================
  // прямокутний клин-трикутник у площині XZ, висота H по Y. p0 — прямий кут, p1/p2 — кінці катетів ([x, z])
  function triWedge(B, P, p0, p1, p2, y0, H, c) {
    const u = new THREE.Vector3(p1[0] - p0[0], 0, p1[1] - p0[1]), v = new THREE.Vector3(p2[0] - p0[0], 0, p2[1] - p0[1]);
    const ey = v.clone().normalize(), ez = u.clone().normalize().negate(), ex = new THREE.Vector3().crossVectors(ey, ez);
    const ctr = new THREE.Vector3(p0[0], y0 + H / 2, p0[1]).add(u.clone().multiplyScalar(0.5)).add(v.clone().multiplyScalar(0.5));
    const m = (P ? P.clone() : new THREE.Matrix4()).multiply(new THREE.Matrix4().makeBasis(ex, ey, ez).setPosition(ctr));
    B.parts.push({ t: 'w', s: [H, v.length(), u.length()], m: m.elements.slice(), c });
  }
  // шестикутна призма (плоскі грані по ±Z): центральний брусок s×F + 4 клини-трикутники. Верхи урівень, але не накладаються
  function hexPrism(B, P, F, y0, H, c) {
    const s = F / Math.sqrt(3);
    B.b([s, H, F], [0, y0 + H / 2, 0], [0, 0, 0], c, P);
    for (const sx of [1, -1]) for (const sz of [1, -1])
      triWedge(B, P, [sx * s / 2, 0], [sx * s / 2, sz * F / 2], [sx * s, 0], y0, H, c);
  }
  // підставка: широка шестикутна плита + вужча зверху (відступ 0.12 — правило 0.1)
  function hexStand(B, P, F) {
    hexPrism(B, P, F, 0, 0.16, PAL.rockD);
    hexPrism(B, B.frame([0, 0, 0], [0, 30, 0], P), F - 0.22, 0.1, 0.18, PAL.rock); // верхній ярус повернутий на 30° — жодної паралельної бічної грані
    return 0.28; // висота верху
  }
  const V5 = {};
  V5.coal = G(() => { // тільки вугілля: гранений шмат, на ньому темніший сколотий гребінь і менший уламок, блиск
    const B = new Build(), c = PAL.coal, P = M([0, 0, 0], [0, 8, 0]);
    const f = frustum(B, P, 1.12, 0.9, 0.34, 0.78, 0.58, c.main, c.main);
    const f2 = frustum(B, B.frame([0.05, 0.24, -0.02], [0, 24, 3], P), 0.74, 0.56, 0.24, 0.46, 0.32, c.core, c.main);
    B.w([0.34, 0.24, 0.3], [-0.5, 0.12, 0.3], [0, 130, 0], c.core, P);   // відбитий уламок-клин поруч
    slopePatch(B, f.sl['+z'][0], f.sl['+z'][1], 0.14, 0.0, 0.4, 0.06, 0, { main: c.glint }, { core: false, glint: false, t: 0.12 });
    slopePatch(B, f.sl['-x'][0], f.sl['-x'][1], 0.0, 0.0, 0.26, 0.06, 0, { main: c.glint }, { core: false, glint: false, t: 0.12 });
    B.b([0.1, 0.1, 0.1], [-0.14, 0.66, 0.0], [45, 20, 45], c.glint, P);
    return B.parts;
  });
  V5.copper = G(() => { // кристали-ромби з пірамідальними вершинами на шестикутній підставці
    const B = new Build(), c = PAL.copper, P = M([0, 0, 0], [0, -8, 0]);
    const top = hexStand(B, P, 0.96);
    xtal(B, B.frame([-0.02, top - 0.12, -0.04], [6, 45, -4], P), 0.32, 0.5, 0.3, c.main);
    xtal(B, B.frame([0.24, top - 0.12, 0.16], [0, 20, -28], P), 0.26, 0.36, 0.24, c.main);
    xtal(B, B.frame([-0.26, top - 0.12, 0.14], [22, 60, 18], P), 0.22, 0.28, 0.2, c.core, c.main);
    return B.parts;
  });
  V5.iron = G(() => { // «залізна троянда» на шестикутній підставці
    const B = new Build(), c = PAL.iron, P = M([0, 0, 0], [0, 10, 0]);
    const top = hexStand(B, P, 0.96);
    const petal = (yaw, r, tilt, w, h) => {
      const F = B.frame([0, top - 0.08, 0], [0, yaw, 0], P).multiply(M([0, 0, r], [-tilt, 0, 0]));
      const m = B.b([w, h, 0.12], [0, h / 2, 0], [0, 0, 0], c.main, F);
      B.b([w * 0.42, h * 0.42, 0.32], [0, 0.02, 0], [0, 0, 45], c.core, m);
    };
    [0, 90, 180, 270].forEach(y => petal(y + 20, 0.22, 38, 0.52, 0.4));
    petal(65, 0.02, 8, 0.44, 0.52);
    return B.parts;
  });

  // ================= V6: вугілля-додекаедр =================
  // Точний додекаедр з деталей Roblox: куб + 6 «вальмових дахів» (кожен = 2 клини + 4 кутові клини).
  // Кожна п'ятикутна грань = трапеція одного даху + трикутник сусіднього (в одній площині, але впритул, без накладання).
  function basisPart(B, P, t, s, ex, ey, ez, ctr, c) {
    const m = (P ? P.clone() : new THREE.Matrix4()).multiply(new THREE.Matrix4().makeBasis(ex, ey, ez).setPosition(ctr));
    B.parts.push({ t, s, m: m.elements.slice(), c });
  }
  function dodeca(B, P, k, c) {
    const phi = (1 + Math.sqrt(5)) / 2, h = (phi - 1) * k, rl = k / phi, hip = k - rl;
    B.b([2 * k, 2 * k, 2 * k], [0, 0, 0], [0, 0, 0], c, P);
    const X = new THREE.Vector3(1, 0, 0), Y = new THREE.Vector3(0, 1, 0), Z = new THREE.Vector3(0, 0, 1);
    // [нормаль грані, напрям гребеня]: z → гребінь по y, x → по z, y → по x (циклічно, як у вершин (0, ±1/φ, ±φ))
    const roofs = [[Z, Y], [X, Z], [Y, X]];
    for (const [n0, r0] of roofs) for (const sg of [1, -1]) {
      const up = n0.clone().multiplyScalar(sg), bh = r0.clone(), ah = new THREE.Vector3().crossVectors(bh, up); // (a, b, up) — правий базис
      const base = up.clone().multiplyScalar(k);
      for (const sa of [1, -1]) { // призма під гребенем: два клини
        const ez = ah.clone().multiplyScalar(-sa), ex = new THREE.Vector3().crossVectors(up, ez);
        const ctr = base.clone().add(up.clone().multiplyScalar(h / 2)).add(ah.clone().multiplyScalar(sa * k / 2));
        basisPart(B, P, 'w', [2 * rl, h, k], ex, up, ez, ctr, c);
      }
      for (const sa of [1, -1]) for (const sb of [1, -1]) { // вальмові кінці: кутові клини, вершина над кінцем гребеня
        const da = ah.clone().multiplyScalar(-sa), db = bh.clone().multiplyScalar(-sb); // напрямки «до вершини»
        let ex = da, ez = db.clone().negate(), size = [k, h, hip];
        if (new THREE.Vector3().crossVectors(ex, up).dot(ez) < 0) { ex = db; ez = da.clone().negate(); size = [hip, h, k]; }
        const ctr = base.clone().add(up.clone().multiplyScalar(h / 2)).add(ah.clone().multiplyScalar(sa * k / 2)).add(bh.clone().multiplyScalar(sb * (rl + hip / 2)));
        basisPart(B, P, 'c', size, ex, up, ez, ctr, c);
      }
    }
  }
  const V6 = {};
  V6.coal = G(() => { // три додекаедри впритул: великий, менший у 1,5 раза і менший у 2 рази; кожен лежить на грані
    const B = new Build(), c = PAL.coal, phi = (1 + Math.sqrt(5)) / 2;
    const n = new THREE.Vector3(0, 1, phi).normalize();
    const rest = new THREE.Matrix4().makeRotationFromQuaternion(new THREE.Quaternion().setFromUnitVectors(n, new THREE.Vector3(0, -1, 0)));
    const RI = phi / Math.sqrt(3 - phi), RS = 1.47; // вписаний радіус (у k) і «радіус дотику» для розстановки
    const put = (k, x, z, yaw) => dodeca(B, M([x, RI * k, z], [0, yaw, 0]).multiply(rest), k, c.main);
    const k1 = 0.32, k2 = k1 / 1.5, k3 = k1 / 2;
    const dist = (ka, kb) => { const r = RS * (ka + kb), dv = RI * (ka - kb); return Math.sqrt(r * r - dv * dv); };
    const d12 = dist(k1, k2), d13 = dist(k1, k3), d23 = dist(k2, k3);
    // 1 — у центрі, 2 — праворуч, 3 — спереду між ними (торкається обох): кут з теореми косинусів
    const ang = Math.acos((d12 * d12 + d13 * d13 - d23 * d23) / (2 * d12 * d13));
    put(k1, 0, 0, 18);
    put(k2, d12, 0, 47);
    put(k3, d13 * Math.cos(ang), d13 * Math.sin(ang), 83);
    return B.parts;
  });

  // ================= ЗЛИТКИ (однакова форма, свій колір) і брикети вугілля =================
  function barA(pal) { // класичний трапецієвидний злиток + клеймо
    const B = new Build();
    const f = frustum(B, M([0, 0.1, 0]), 1.8, 0.9, 0.4, 1.42, 0.56, pal.main, pal.main);
    B.b([1.8, 0.2, 0.9], [0, 0.0, 0], [0, 0, 0], pal.dark);        // підошва (верх урівень з низом схилів — грані дивляться одна на одну)
    B.b([0.8, 0.2, 0.32], [0, 0.5, 0], [0, 0, 0], pal.dark);        // клеймо: виступ 0.1 над верхом
    B.b([0.42, 0.2, 0.08], [-0.06, 0.6, 0.02], [0, 0, 0], pal.glint);
    return ground(B.parts);
  }
  function barA2(pal) { // той самий злиток; клеймо пласке (виступ 0.1 — мінімум за GDD), блиск лежить поруч, а не зверху
    const B = new Build();
    frustum(B, M([0, 0.1, 0]), 1.8, 0.9, 0.4, 1.42, 0.56, pal.main, pal.main);
    B.b([1.8, 0.2, 0.9], [0, 0.0, 0], [0, 0, 0], pal.dark);
    B.b([0.86, 0.2, 0.22], [0, 0.5, -0.02], [0, 0, 0], pal.dark);       // клеймо: верх на 0.1 над злитком
    B.b([0.46, 0.2, 0.07], [-0.08, 0.5, 0.125], [0, 0, 0], pal.glint);  // блиск: на тій самій висоті, впритул до клейма
    return ground(B.parts);
  }
  function barA3(pal) { // злиток A без клейма й блиску: чиста зрізана піраміда на підошві
    const B = new Build();
    frustum(B, M([0, 0.1, 0]), 1.8, 0.9, 0.4, 1.42, 0.56, pal.main, pal.main);
    B.b([1.8, 0.2, 0.9], [0, 0.0, 0], [0, 0, 0], pal.dark);
    return ground(B.parts);
  }
  function barA4(L) { // гладкий злиток, грані тоновані як від світла згори-спереду
    const B = new Build(), P = M([0, 0.1, 0]);
    const Lx = 1.8, W = 0.9, H = 0.4, l = 1.42, w = 0.56;
    const dx = (Lx - l) / 2, dz = (W - w) / 2, y = H / 2, cx = l / 2 + dx / 2, cz = w / 2 + dz / 2;
    B.b([l, H, w], [0, y, 0], [0, 0, 0], L.top, P);
    B.w([l, H, dz], [0, y, cz], [0, 180, 0], L.side, P);
    B.w([l, H, dz], [0, y, -cz], [0, 0, 0], L.side, P);
    B.w([w, H, dx], [cx, y, 0], [0, -90, 0], L.end, P);
    B.w([w, H, dx], [-cx, y, 0], [0, 90, 0], L.end, P);
    B.cw([dx, H, dz], [-cx, y, cz], [0, 0, 0], L.end, P);   // кути — тоном торця: торець читається шестикутником
    B.cw([dz, H, dx], [cx, y, cz], [0, 90, 0], L.end, P);
    B.cw([dx, H, dz], [cx, y, -cz], [0, 180, 0], L.end, P);
    B.cw([dz, H, dx], [-cx, y, -cz], [0, -90, 0], L.end, P);
    B.b([1.8, 0.2, 0.9], [0, 0.0, 0], [0, 0, 0], L.sole);
    return ground(B.parts);
  }
  // злиток з окремих пластин: кожна площина (верх, 2 довгі схили, 2 торці) — свій відтінок, кути не змішують кольори.
  // Трапеція = прямокутна пластина + 2 пластини-трикутники (тонкі клини). Зовнішні поверхні точно лягають на зрізану піраміду.
  function plateRect(B, p0, e1, e2, n, t, c) {
    const ex = e1.clone().normalize(), ey = n.clone(), ez = new THREE.Vector3().crossVectors(ex, ey);
    const ctr = p0.clone().add(e1.clone().multiplyScalar(0.5)).add(e2.clone().multiplyScalar(0.5)).add(n.clone().multiplyScalar(-t / 2));
    basisPart(B, null, 'b', [e1.length(), t, e2.length()], ex, ey, ez, ctr, c);
  }
  function plateTri(B, pR, l1, l2, n, t, c) { // pR — прямий кут, l1/l2 — катети
    const ey = l1.clone().normalize(), ez = l2.clone().normalize().negate(), ex = new THREE.Vector3().crossVectors(ey, ez);
    const ctr = pR.clone().add(l1.clone().multiplyScalar(0.5)).add(l2.clone().multiplyScalar(0.5)).add(n.clone().multiplyScalar(-t / 2));
    basisPart(B, null, 'w', [t, l1.length(), l2.length()], ex, ey, ez, ctr, c);
  }
  function barA5(C) {
    const B = new Build(), V = (x, y, z) => new THREE.Vector3(x, y, z), t = 0.2, y0 = 0.2;
    const L = 1.8, W = 0.9, H = 0.4, l = 1.42, w = 0.56, dx = (L - l) / 2, dz = (W - w) / 2;
    B.b([L, 0.2, W], [0, 0.1, 0], [0, 0, 0], C.sole);                                   // підошва
    plateRect(B, V(-l / 2, y0 + H, -w / 2), V(l, 0, 0), V(0, 0, w), V(0, 1, 0), t, C.top); // 1 — верх
    for (const s of [1, -1]) { // довгі схили (±z)
      const n = V(0, dz, s * H).normalize(), c = s > 0 ? C.pz : C.nz;
      const b0 = V(-l / 2, y0, s * W / 2), up = V(0, H, -s * dz);
      plateRect(B, b0, V(l, 0, 0), up, n, t, c);
      plateTri(B, V(l / 2, y0, s * W / 2), up, V(dx, 0, 0), n, t, c);
      plateTri(B, V(-l / 2, y0, s * W / 2), up, V(-dx, 0, 0), n, t, c);
    }
    for (const s of [1, -1]) { // торці (±x)
      const n = V(s * H, dx, 0).normalize(), c = s > 0 ? C.px : C.nx;
      const b0 = V(s * L / 2, y0, -w / 2), up = V(-s * dx, H, 0);
      plateRect(B, b0, V(0, 0, w), up, n, t, c);
      plateTri(B, V(s * L / 2, y0, w / 2), up, V(0, 0, dz), n, t, c);
      plateTri(B, V(s * L / 2, y0, -w / 2), up, V(0, 0, -dz), n, t, c);
    }
    return ground(B.parts);
  }
  function barB(pal) { // брусок із фасками по довгих ребрах
    const B = new Build();
    const L = 1.8, W = 0.84, H = 0.42, ch = 0.18;
    B.b([L, H, W - 2 * ch], [0, H / 2, 0], [0, 0, 0], pal.main);
    B.b([L - 0.2, H - ch, W], [0, (H - ch) / 2, 0], [0, 0, 0], pal.main);
    B.w([L - 0.2, ch, ch], [0, H - ch / 2, W / 2 - ch / 2], [0, 180, 0], pal.main);
    B.w([L - 0.2, ch, ch], [0, H - ch / 2, -W / 2 + ch / 2], [0, 0, 0], pal.main);
    B.b([L * 0.5, 0.2, (W - 2 * ch) * 0.6], [0, H, 0], [0, 0, 0], pal.dark);
    B.b([L * 0.26, 0.2, 0.07], [-0.06, H + 0.1, 0.02], [0, 0, 0], pal.glint);
    return ground(B.parts);
  }
  function barC(pal) { // «човник»: схили різного тону + поздовжній гребінь
    const B = new Build();
    const L = 1.76, W = 0.86, H = 0.46, l = 1.36, w = 0.6, dx = (L - l) / 2, dz = (W - w) / 2;
    B.b([l, H, w], [0, H / 2, 0], [0, 0, 0], pal.main);
    B.w([l, H, dz], [0, H / 2, w / 2 + dz / 2], [0, 180, 0], pal.dark);
    B.w([l, H, dz], [0, H / 2, -w / 2 - dz / 2], [0, 0, 0], pal.main);
    B.w([w, H, dx], [l / 2 + dx / 2, H / 2, 0], [0, -90, 0], pal.main);
    B.w([w, H, dx], [-l / 2 - dx / 2, H / 2, 0], [0, 90, 0], pal.dark);
    B.b([l + 0.2, 0.2, w - 0.24], [0, H, 0], [0, 0, 0], pal.main);
    B.b([0.5, 0.2, 0.08], [-0.2, H + 0.1, 0.0], [0, 0, 0], pal.glint);
    return ground(B.parts);
  }
  function briqA() { // «подушка»: дві зрізані піраміди основа до основи — гострий шов посередині
    const B = new Build(), p = PAL.briq;
    frustum(B, M([0, 0.22, 0]), 1.3, 0.9, 0.28, 0.92, 0.52, p.main, p.main);
    frustum(B, M([0, 0.22, 0], [180, 0, 0]), 1.2, 0.8, 0.22, 0.86, 0.46, p.dark, p.dark);
    B.b([0.4, 0.2, 0.08], [-0.12, 0.5, 0.06], [0, 16, 0], p.glint);
    return ground(B.parts);
  }
  function briqB() { // «піні-кей»: шестигранна колода з отвором
    const B = new Build(), p = PAL.briq;
    const F = 0.62, s = F / Math.sqrt(3), L = 1.5;
    const P = M([0, F / 2, 0], [0, 0, 0]);
    B.b([L, F, s], [0, 0, 0], [0, 0, 0], p.main, P);
    B.b([L - 0.2, F, s], [0, 0, 0], [60, 0, 0], p.main, P);
    B.b([L - 0.2, F, s], [0, 0, 0], [120, 0, 0], p.main, P);
    // два темні пояски-обручі навколо колоди (шестигранник трохи більший, виступ 0.1)
    [-0.42, 0.42].forEach(x => { for (let k = 0; k < 3; k++) B.b([0.16, F + 0.2, s + 0.12], [x, 0, 0], [60 * k, 0, 0], p.dark, P); });
    B.b([0.3, 0.2, 0.08], [0, F / 2 + 0.06, 0.04], [0, 0, 0], p.glint, P);
    return ground(B.parts);
  }
  function briqC() { // цеглинка з ребрами
    const B = new Build(), p = PAL.briq;
    const L = 1.3, W = 0.66, H = 0.36, ch = 0.14;
    B.b([L, H - ch, W], [0, (H - ch) / 2, 0], [0, 0, 0], p.main);
    B.b([L - 0.2, H, W - 2 * ch], [0, H / 2, 0], [0, 0, 0], p.main);
    B.w([L - 0.2, ch, ch], [0, H - ch / 2, W / 2 - ch / 2], [0, 180, 0], p.main);
    B.w([L - 0.2, ch, ch], [0, H - ch / 2, -W / 2 + ch / 2], [0, 0, 0], p.main);
    for (let i = -1; i <= 1; i++) B.b([0.12, 0.2, W - 2 * ch + 0.2], [i * 0.34, H, 0], [0, 0, 0], p.dark);
    B.b([0.08, 0.2, 0.2], [0.16, H + 0.04, -0.06], [0, 0, 0], p.glint);
    return ground(B.parts);
  }

  const VARIANTS = {
    F: { name: 'C4 · вугілля-додекаедр', note: 'Вугілля — три додекаедри впритул (великий, у 1,5 і у 2 рази менші), кожен зібраний з куба й шести «вальмових дахів» із клинів. Мідь і залізо — на шестикутних підставках. Злиток — з окремих пластин: верх, кожен схил і торець свого відтінку.',
      coal: V6.coal, copper: V5.copper, iron: V5.iron, bar: p => barA5(p === PAL.barCu ? PAL.barCuF : PAL.barFeF), barName: 'Трапецієвидний злиток' },
    E: { name: 'C3 · попередня', note: 'Попередня версія: вугілля — гранений шмат.',
      coal: V5.coal, copper: V5.copper, iron: V5.iron, bar: barA3, barName: 'Трапецієвидний злиток' },
  };
  const out = { VARIANTS, PAL, M };
  if (typeof module !== 'undefined') module.exports = out; else root.ORE_MODELS = out;
})(typeof window !== 'undefined' ? window : globalThis);
