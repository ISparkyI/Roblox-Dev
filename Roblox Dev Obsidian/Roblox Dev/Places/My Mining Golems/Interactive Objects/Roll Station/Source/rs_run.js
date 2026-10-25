const THREE = require('/tmp/three/node_modules/three'); global.THREE = THREE;
const { build } = require('./roll_station.js'); const ck = require('./check.js');
ck.setThreshold(0.1);
const SC = 0.8; // уся станція менша на 20 % — між нею й підставками лишається прохід
const parts = build().map(p => { p.s = p.s.map(v => v * SC); p.m[12] *= SC; p.m[13] *= SC; p.m[14] *= SC; return p; }); const before = ck.check(parts).length; const r = ck.fix(parts); const left = ck.check(parts);
console.log('parts', parts.length, 'before', before, 'fixes', r.log.length, 'left', left.length);
if (left.length) console.log(left.slice(0, 8).join('\n'));
require('fs').writeFileSync('rs_parts.json', JSON.stringify(parts.map(p => ({ t: p.t, s: p.s.map(x => +x.toFixed(4)), m: p.m.map(x => +x.toFixed(5)), c: p.c, tag: p.tag }))));
