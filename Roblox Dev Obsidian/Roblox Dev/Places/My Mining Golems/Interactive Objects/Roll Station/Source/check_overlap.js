// GDD rule 0.1 checker: for every pair of parts, faces with the same outward normal that lie closer than 0.1
// and overlap in projection -> error. Faces pointing at each other are allowed (hidden inside). Bottom faces on y=0 ignored.
const THREE = require('/tmp/three/node_modules/three');
let TH = 0.1; // поріг правила GDD: 0.1 моделі, 0.5 карти (setThreshold)
function setThreshold(v) { TH = v; }
// дрібні деталі-«пропи» (tag: prop / lamp / sign) між собою — правило моделей 0,1; усе інше — TH
const PROP = { prop: 1, lamp: 1, sign: 1 };
function thOf(a, b) { return (a && b && PROP[a.tag] && PROP[b.tag]) ? Math.min(TH, 0.1) : TH; }
global.THREE = THREE;
const { VARIANTS } = require('./models.js');

function faces(p) {
  const [sx, sy, sz] = p.s.map(v => v / 2);
  const m = new THREE.Matrix4().fromArray(p.m);
  const V = (x, y, z) => new THREE.Vector3(x, y, z).applyMatrix4(m);
  let F;
  if (p.t === 'b') {
    const c = [[-1, -1, -1], [1, -1, -1], [1, 1, -1], [-1, 1, -1], [-1, -1, 1], [1, -1, 1], [1, 1, 1], [-1, 1, 1]].map(a => V(a[0] * sx, a[1] * sy, a[2] * sz));
    F = [[0, 3, 2, 1], [4, 5, 6, 7], [0, 1, 5, 4], [3, 7, 6, 2], [1, 2, 6, 5], [0, 4, 7, 3]].map(f => f.map(i => c[i]));
  } else if (p.t === 'w') {
    const a = V(-sx, -sy, -sz), b = V(sx, -sy, -sz), c = V(sx, -sy, sz), d = V(-sx, -sy, sz), e = V(-sx, sy, sz), f = V(sx, sy, sz);
    F = [[a, d, c, b], [d, e, f, c], [a, b, f, e], [a, e, d], [b, c, f]];
  } else {
    const a = V(-sx, -sy, -sz), b = V(sx, -sy, -sz), c = V(sx, -sy, sz), d = V(-sx, -sy, sz), t = V(sx, sy, -sz);
    F = [[a, d, c, b], [b, c, t], [a, b, t], [a, t, d], [d, t, c]];
  }
  const ctr = new THREE.Vector3();
  return F.map(poly => {
    const n = new THREE.Vector3().subVectors(poly[1], poly[0]).cross(new THREE.Vector3().subVectors(poly[2], poly[0])).normalize();
    // orient outward: normal should point away from part centre
    const all = [...new Set(F.flat())]; const pc = all.reduce((s, v) => s.add(v), new THREE.Vector3()).multiplyScalar(1 / all.length);
    const fc = poly.reduce((s, v) => s.add(v), new THREE.Vector3()).multiplyScalar(1 / poly.length);
    if (n.dot(fc.clone().sub(pc)) < 0) n.negate();
    return { poly, n, d: n.dot(poly[0]) };
  });
}
function clip(subject, clipPoly) { // 2D convex clipping (Sutherland–Hodgman)
  let out = subject;
  for (let i = 0; i < clipPoly.length && out.length; i++) {
    const A = clipPoly[i], B = clipPoly[(i + 1) % clipPoly.length], inp = out; out = [];
    const side = P => (B[0] - A[0]) * (P[1] - A[1]) - (B[1] - A[1]) * (P[0] - A[0]);
    for (let j = 0; j < inp.length; j++) {
      const P = inp[j], Q = inp[(j + 1) % inp.length], sp = side(P), sq = side(Q);
      if (sp >= 0) out.push(P);
      if ((sp >= 0) !== (sq >= 0)) { const t = sp / (sp - sq); out.push([P[0] + t * (Q[0] - P[0]), P[1] + t * (Q[1] - P[1])]); }
    }
  }
  return out;
}

function insidePart(p, w) {
  const m = new THREE.Matrix4().fromArray(p.m); const l = w.clone().applyMatrix4(m.clone().invert());
  const [hx, hy, hz] = p.s.map(v => v / 2), e = -1e-4;
  if (Math.abs(l.x) > hx + e || Math.abs(l.y) > hy + e || Math.abs(l.z) > hz + e) return false;
  if (p.t === 'w') return l.y <= -hy + (l.z + hz) / p.s[2] * p.s[1];
  if (p.t === 'c') return l.y <= -hy + p.s[1] * Math.min((l.x + hx) / p.s[0], (hz - l.z) / p.s[2]);
  return true;
}
function hidden(parts, i, j, a, b, inter, e1, e2) {
  const c = inter.reduce((s, q) => [s[0] + q[0] / inter.length, s[1] + q[1] / inter.length], [0, 0]);
  const d = Math.max(a.d, b.d) + 0.02;
  const w = e1.clone().multiplyScalar(c[0]).add(e2.clone().multiplyScalar(c[1])).add(a.n.clone().multiplyScalar(d - 0)); // point in plane basis
  // e1,e2 orthonormal in plane, n normal: reconstruct = c0*e1 + c1*e2 + d*n
  for (let k = 0; k < parts.length; k++) if (k !== i && k !== j && insidePart(parts[k], w)) return true;
  return false;
}
const area = P => { let a = 0; for (let i = 0; i < P.length; i++) { const p = P[i], q = P[(i + 1) % P.length]; a += p[0] * q[1] - q[0] * p[1]; } return a / 2; };
function ccw(P) { return area(P) < 0 ? P.slice().reverse() : P; }
function check(parts) {
  const fs = parts.map(faces), errs = [];
  for (let i = 0; i < parts.length; i++) for (let j = i + 1; j < parts.length; j++) {
    for (const a of fs[i]) for (const b of fs[j]) {
      if (a.n.dot(b.n) < 0.9995) continue;
      const gap = Math.abs(a.d - b.d);
      if (gap >= thOf(parts[i], parts[j]) - 1e-4) continue;
      if (a.n.y < -0.99 && Math.abs(a.d) < 1e-3 && Math.abs(b.d) < 1e-3) continue; // обидва дна на землі
      // project to plane basis
      const u = Math.abs(a.n.x) < 0.9 ? new THREE.Vector3(1, 0, 0) : new THREE.Vector3(0, 1, 0);
      const e1 = u.sub(a.n.clone().multiplyScalar(u.dot(a.n))).normalize(), e2 = a.n.clone().cross(e1);
      const pr = poly => ccw(poly.map(v => [v.dot(e1), v.dot(e2)]));
      const inter = clip(pr(a.poly), pr(b.poly));
      if (inter.length > 2 && Math.abs(area(inter)) > 1e-4 && !hidden(parts, i, j, a, b, inter, e1, e2)) errs.push(`${i}/${j} n=(${a.n.x.toFixed(2)},${a.n.y.toFixed(2)},${a.n.z.toFixed(2)}) gap=${gap.toFixed(3)} area=${Math.abs(area(inter)).toFixed(3)}`);
    }
  }
  return errs;
}
module.exports = { check };
if (require.main === module) {
  for (const [k, v] of Object.entries(VARIANTS)) for (const item of ['coal', 'copper', 'iron', 'briq']) {
    const parts = v[item](); const e = check(parts);
    console.log(k, item, 'parts=' + parts.length, e.length ? 'ERR ' + e.length + '\n   ' + e.join('\n   ') : 'ok');
  }
  for (const [k, v] of Object.entries(VARIANTS)) { const parts = v.bar({ main: '1', dark: '2', glint: '3' }); const e = check(parts); console.log(k, 'bar', 'parts=' + parts.length, e.length ? 'ERR ' + e.length + '\n   ' + e.join('\n   ') : 'ok'); }
}

// ---- auto-fix (GDD: рухаємо дрібнішу деталь: зовні/нарівні → висунути на 0.1, трохи всередині → втопити на 0.1) ----
function vol(p) { return p.s[0] * p.s[1] * p.s[2] * (p.t === 'b' ? 1 : p.t === 'w' ? 0.5 : 1 / 3); }
function firstErr(parts) {
  const fs = parts.map(faces);
  for (let i = 0; i < parts.length; i++) for (let j = i + 1; j < parts.length; j++) for (const a of fs[i]) for (const b of fs[j]) {
    if (a.n.dot(b.n) < 0.9995) continue;
    const gap = Math.abs(a.d - b.d); if (gap >= thOf(parts[i], parts[j]) - 1e-4) continue;
    if (a.n.y < -0.99 && Math.abs(a.d) < 1e-3 && Math.abs(b.d) < 1e-3) continue;
    const u = Math.abs(a.n.x) < 0.9 ? new THREE.Vector3(1, 0, 0) : new THREE.Vector3(0, 1, 0);
    const e1 = u.sub(a.n.clone().multiplyScalar(u.dot(a.n))).normalize(), e2 = a.n.clone().cross(e1);
    const pr = poly => ccw(poly.map(v => [v.dot(e1), v.dot(e2)]));
    const inter = clip(pr(a.poly), pr(b.poly));
    if (inter.length > 2 && Math.abs(area(inter)) > 1e-4 && !hidden(parts, i, j, a, b, inter, e1, e2)) return { i, j, a, b };
  }
  return null;
}
function moveFace(p, n, change) { // block only: move the face whose outward normal is n by `change` along n
  const m = new THREE.Matrix4().fromArray(p.m);
  const R = new THREE.Matrix3().setFromMatrix4(m); const ln = n.clone().applyMatrix3(R.clone().transpose());
  const ax = [Math.abs(ln.x), Math.abs(ln.y), Math.abs(ln.z)]; const k = ax.indexOf(Math.max(...ax));
  if (ax[k] < 0.999) return false;
  if (p.s[k] + change < 0.06) return false;
  p.s[k] += change; p.m[12] += n.x * change / 2; p.m[13] += n.y * change / 2; p.m[14] += n.z * change / 2;
  return true;
}
function fix(parts, log = []) {
  for (let it = 0; it < 400; it++) {
    const e = firstErr(parts); if (!e) return { ok: true, log };
    const cand = [[e.i, e.a, e.b], [e.j, e.b, e.a]].filter(c => parts[c[0]].t === 'b').sort((x, y) => vol(parts[x[0]]) - vol(parts[y[0]]));
    let done = false;
    for (const [idx, own, oth] of cand) {
      const delta = own.d - oth.d; // >0: own face is outside
      const th = thOf(parts[e.i], parts[e.j]);
      const target = delta >= -0.03 ? th : -th;
      if (moveFace(parts[idx], own.n, target - delta)) { log.push(`part ${idx}: ${(target - delta).toFixed(3)}`); done = true; break; }
      if (moveFace(parts[idx], own.n, -th - delta)) { log.push(`part ${idx}: sink ${(-0.1 - delta).toFixed(3)}`); done = true; break; }
    }
    if (!done) return { ok: false, log, stuck: e };
  }
  return { ok: false, log };
}
module.exports.fix = fix;
module.exports.setThreshold = setThreshold;
