// Рендер PNG-скріншотів clay_golem.html (playwright + swiftshader). Запуск: node render_shots.js [three_dir]
// three_dir — локальна копія пакета three@0.128.0 (CDN підміняється, якщо мережа недоступна).
const { chromium } = require('playwright');
const path = require('path'), fs = require('fs');
const OUT = path.resolve(__dirname, '..');
const THREE_DIR = process.argv[2];
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const page = await browser.newPage({ viewport: { width: 1500, height: 1000 }, deviceScaleFactor: 1 });
  if (THREE_DIR) {
    await page.route('**/three.min.js', r => r.fulfill({ path: path.join(THREE_DIR, 'build/three.min.js'), contentType: 'application/javascript' }));
    await page.route('**/OrbitControls.js', r => r.fulfill({ path: path.join(THREE_DIR, 'examples/js/controls/OrbitControls.js'), contentType: 'application/javascript' }));
  }
  page.on('console', m => { if (m.type() === 'error') console.log('console:', m.text()); });
  page.on('pageerror', e => console.log('pageerror:', e.message));
  await page.goto('file://' + path.join(OUT, 'clay_golem.html'));
  await page.waitForFunction(() => window.api);
  await page.evaluate(() => { api.shot(true); api.setTurntable(false); });
  await page.setViewportSize({ width: 1240, height: 1250 });
  await page.evaluate(() => { document.getElementById('stage').style.height = '1000px'; api.shot(true); });
  const stage = page.locator('#stage');
  const shot = async (name, cls, view, anim = 'idle', t = 0.3) => {
    await page.evaluate(([c, v, a, tt]) => { api.setClass(c); api.setAnim(a); api.setView(v); api.freeze(tt); }, [cls, view, anim, t]);
    await page.waitForTimeout(450);
    await stage.screenshot({ path: path.join(OUT, name) });
    console.log('saved', name);
  };
  await shot('clay_front.png', 'none', 'front');
  await shot('clay_34.png', 'none', 'q');
  await shot('clay_side.png', 'none', 'side');
  await shot('clay_back.png', 'none', 'back');
  await shot('clay_miner.png', 'miner', 'qL');
  await shot('clay_carrier.png', 'carrier', 'qL');
  await shot('clay_warrior.png', 'warrior', 'qL');
  await shot('clay_miner_swing.png', 'miner', 'side', 'action', 0.42 / 0.9);
  await shot('clay_miner_hit.png', 'miner', 'side', 'action', 0.70 / 0.9);
  await shot('clay_walk.png', 'none', 'q', 'walk', 0.35);
  await page.evaluate(() => { document.getElementById('items').style.height = '420px'; api.shot(true); api.itemsAngle(-0.7); });
  await page.waitForTimeout(400);
  await page.locator('#items').screenshot({ path: path.join(OUT, 'clay_items.png') });
  console.log('saved clay_items.png');
  // UI
  await page.evaluate(() => { api.shot(false); document.getElementById('stage').style.height = ''; document.getElementById('items').style.height = ''; api.freeze(1.0); api.setClass('miner'); api.setAnim('idle'); api.setView('q'); });
  await page.setViewportSize({ width: 1440, height: 1100 });
  await page.waitForTimeout(500);
  await page.screenshot({ path: path.join(OUT, 'clay_page_ui.png'), fullPage: true });
  console.log('saved clay_page_ui.png');
  await browser.close();
})();
