/**
 * My Mining Golems — Google Sheets backend (Apps Script Web App)
 *
 * API (all responses are JSON):
 *   GET  ?action=updates&key=SECRET
 *   GET  ?action=codes&key=SECRET
 *   GET  ?action=ping&key=SECRET
 *   GET  ?action=redeem&key=..&code=..&userId=..&name=..            (same as POST redeem)
 *   GET  ?action=feedback&key=..&userId=..&text=..&category=..       (same as POST feedback)
 *   GET  ?data=<URL-encoded JSON {"action":"redeem"|"feedback","key":...,...}>  (alternative)
 *   POST {"action":"redeem",  "key":..., "code":..., "userId":..., "name":...}
 *   POST {"action":"feedback","key":..., "userId":..., "name":..., "category":..., "text":...,
 *         "map":..., "money":..., "version":..., "placeId":..., "jobId":..., "device":...}
 *
 * Secret: Project Settings -> Script properties -> SECRET
 * Columns are found by HEADER NAME (row 1), so columns may be reordered freely.
 * After editing this script: Deploy -> Manage deployments -> Edit (pencil) -> Version: New version -> Deploy.
 */

// ===================== CONFIG =====================
var SHEET_UPDATES = 'Updates';
var SHEET_CODES = 'Codes';
var SHEET_FEEDBACK = 'Feedback';
var SHEET_REDEEMLOG = 'RedeemLog';

var CACHE_SECONDS = 30;          // cache for updates/codes lists (0 = disabled)
var FEEDBACK_COOLDOWN_SEC = 60;  // 1 feedback per userId per N seconds
var FEEDBACK_MAX_TEXT = 1000;
var VALID_REWARDS = ['Diamonds', 'Tickets', 'Money', 'Potion', 'Golem'];
var VALID_POTIONS = ['Luck', 'Speed', 'Money', 'Strength'];
var VALID_CATEGORIES = ['Bug', 'Idea', 'Other'];

var HEADERS = {
  Updates: ['ID', 'Active', 'Pinned', 'Date', 'Version', 'Title', 'Title Color', 'Text', 'Text Color', 'Image', 'Note'],
  Codes: ['Code', 'Active', 'Reward', 'Amount', 'Item', 'Expires', 'Max Uses', 'Uses', 'Note'],
  Feedback: ['Time', 'UserId', 'Name', 'Category', 'Text', 'Map', 'Money', 'Version', 'Device', 'PlaceId', 'JobId', 'Status', 'Note'],
  RedeemLog: ['Time', 'Code', 'UserId', 'Name']
};

// ===================== ENTRY POINTS =====================
function doGet(e) {
  try {
    var p = (e && e.parameter) || {};
    // Write actions may also come via GET (Roblox PostAsync breaks on the Apps Script 302 redirect -> 405).
    // Fields come either from ?data=<URL-encoded JSON with all fields> or from separate query params.
    var body = p;
    if (p.data) {
      var parsed;
      try { parsed = JSON.parse(p.data); } catch (parseErr) { return json_({ ok: false, error: 'bad_json' }); }
      if (!parsed || typeof parsed !== 'object') return json_({ ok: false, error: 'bad_json' });
      body = parsed;
    }
    var key = body.key != null ? body.key : p.key;
    if (!checkKey_(key)) return json_({ ok: false, error: 'auth' });
    var action = String(body.action || p.action || '').toLowerCase();
    if (action === 'updates') return json_({ ok: true, updates: cached_('updates', getUpdates_) });
    if (action === 'codes') return json_({ ok: true, codes: cached_('codes', getCodes_) });
    if (action === 'ping') return json_({ ok: true, time: new Date().toISOString() });
    if (action === 'redeem') return json_(redeem_(body));
    if (action === 'feedback') return json_(feedback_(body));
    return json_({ ok: false, error: 'unknown_action' });
  } catch (err) {
    return json_({ ok: false, error: 'server: ' + errMsg_(err) });
  }
}

function doPost(e) {
  try {
    var body = {};
    if (e && e.postData && e.postData.contents) {
      try {
        body = JSON.parse(e.postData.contents);
      } catch (parseErr) {
        return json_({ ok: false, error: 'bad_json' });
      }
    }
    if (!body || typeof body !== 'object') body = {};
    var p = (e && e.parameter) || {};
    var key = body.key != null ? body.key : p.key;
    if (!checkKey_(key)) return json_({ ok: false, error: 'auth' });
    var action = String(body.action || p.action || '').toLowerCase();
    if (action === 'redeem') return json_(redeem_(body));
    if (action === 'feedback') return json_(feedback_(body));
    return json_({ ok: false, error: 'unknown_action' });
  } catch (err) {
    return json_({ ok: false, error: 'server: ' + errMsg_(err) });
  }
}

// ===================== UPDATES =====================
function getUpdates_() {
  var t = readTable_(SHEET_UPDATES);
  var out = [];
  t.rows.forEach(function (r) {
    if (!toBool_(r.get('Active'))) return;
    var title = str_(r.get('Title'));
    var text = str_(r.get('Text'));
    if (!title && !text) return;
    var date = toYmd_(r.get('Date'));
    var version = versionStr_(r.get('Version'));
    var id = str_(r.get('ID'));
    if (!id) id = (version || 'row' + r.rowNumber) + '_' + (date || 'nodate');
    out.push({
      id: id,
      version: version,
      date: date,
      title: title,
      titleColor: toColor_(r.get('Title Color')),
      text: text,
      textColor: toColor_(r.get('Text Color')),
      image: toAssetId_(r.get('Image')),
      pinned: toBool_(r.get('Pinned')),
      _row: r.rowNumber
    });
  });
  out.sort(function (a, b) {
    if (a.pinned !== b.pinned) return a.pinned ? -1 : 1;
    if (a.date !== b.date) return a.date < b.date ? 1 : -1; // newest first ("" goes last)
    return b._row - a._row; // same date: lower row in the sheet = newer
  });
  out.forEach(function (u) { delete u._row; });
  return out;
}

// ===================== CODES =====================
function getCodes_() {
  var t = readTable_(SHEET_CODES);
  var out = [];
  t.rows.forEach(function (r) {
    var c = codeFromRow_(r);
    if (c) out.push(c);
  });
  return out;
}

function codeFromRow_(r) {
  var code = normCode_(r.get('Code'));
  if (!code) return null;
  var reward = normReward_(r.get('Reward'));
  return {
    code: code,
    reward: reward,
    amount: toNum_(r.get('Amount'), reward === 'Golem' || reward === 'Potion' ? 1 : 0),
    item: normItem_(reward, r.get('Item')),
    expires: toYmd_(r.get('Expires')),
    maxUses: Math.max(0, Math.floor(toNum_(r.get('Max Uses'), 0))),
    uses: Math.max(0, Math.floor(toNum_(r.get('Uses'), 0))),
    active: toBool_(r.get('Active'))
  };
}

function redeem_(body) {
  var code = normCode_(body.code);
  if (!code) return { ok: false, error: 'notfound' };
  var lock = LockService.getScriptLock();
  try {
    lock.waitLock(10000);
  } catch (e) {
    return { ok: false, error: 'busy' };
  }
  try {
    var t = readTable_(SHEET_CODES);
    var row = null;
    for (var i = 0; i < t.rows.length; i++) {
      if (normCode_(t.rows[i].get('Code')) === code) { row = t.rows[i]; break; }
    }
    if (!row) return { ok: false, error: 'notfound' };
    var c = codeFromRow_(row);
    if (!c.active) return { ok: false, error: 'inactive' };
    if (c.expires && todayYmd_() > c.expires) return { ok: false, error: 'expired' };
    if (c.maxUses > 0 && c.uses >= c.maxUses) return { ok: false, error: 'limit' };

    var usesCol = t.col('Uses');
    if (!usesCol) return { ok: false, error: 'server: no Uses column' };
    t.sheet.getRange(row.rowNumber, usesCol).setValue(c.uses + 1);

    var log = ensureSheet_(SHEET_REDEEMLOG, HEADERS.RedeemLog, true);
    appendByHeaders_(log, {
      'Time': new Date(),
      'Code': code,
      'UserId': safeCell_(str_(body.userId)),
      'Name': safeCell_(str_(body.name).slice(0, 50))
    });
    SpreadsheetApp.flush();
    clearCache_();
    return { ok: true };
  } finally {
    lock.releaseLock();
  }
}

// ===================== FEEDBACK =====================
function feedback_(body) {
  var userId = str_(body.userId);
  var text = str_(body.text);
  if (!text) return { ok: false, error: 'empty' };
  if (text.length > FEEDBACK_MAX_TEXT) text = text.slice(0, FEEDBACK_MAX_TEXT);

  var cache = CacheService.getScriptCache();
  var rlKey = 'fb_' + (userId || 'anon');
  if (cache.get(rlKey)) return { ok: false, error: 'rate' };
  cache.put(rlKey, '1', FEEDBACK_COOLDOWN_SEC);

  var cat = str_(body.category);
  var catNorm = 'Other';
  VALID_CATEGORIES.forEach(function (v) { if (v.toLowerCase() === cat.toLowerCase()) catNorm = v; });

  var lock = LockService.getScriptLock();
  try { lock.waitLock(10000); } catch (e) { return { ok: false, error: 'busy' }; }
  try {
    var sh = ensureSheet_(SHEET_FEEDBACK, HEADERS.Feedback, false);
    appendByHeaders_(sh, {
      'Time': new Date(),
      'UserId': safeCell_(userId),
      'Name': safeCell_(str_(body.name).slice(0, 50)),
      'Category': catNorm,
      'Text': safeCell_(text),
      'Map': safeCell_(str_(body.map).slice(0, 100)),
      'Money': numOrStr_(body.money),
      'Version': safeCell_(str_(body.version).slice(0, 30)),
      'Device': safeCell_(str_(body.device).slice(0, 30)),
      'PlaceId': safeCell_(str_(body.placeId)),
      'JobId': safeCell_(str_(body.jobId).slice(0, 80)),
      'Status': 'New',
      'Note': ''
    });
  } finally {
    lock.releaseLock();
  }
  return { ok: true };
}

// ===================== TABLE HELPERS =====================
function normHeader_(h) {
  return String(h == null ? '' : h).toLowerCase().replace(/\(.*?\)/g, '').replace(/[^a-z0-9]/g, '');
}

/** Reads a sheet into rows with header-name access. */
function readTable_(name) {
  var sh = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(name);
  if (!sh) throw new Error('sheet "' + name + '" not found');
  var values = sh.getDataRange().getValues();
  var headers = values.length ? values[0] : [];
  var map = {};
  headers.forEach(function (h, i) {
    var k = normHeader_(h);
    if (k && map[k] === undefined) map[k] = i;
  });
  var rows = [];
  for (var r = 1; r < values.length; r++) {
    (function (arr, rowNumber) {
      var empty = arr.every(function (v) { return v === '' || v === null; });
      if (empty) return;
      rows.push({
        rowNumber: rowNumber,
        get: function (h) {
          var i = map[normHeader_(h)];
          return i === undefined ? '' : arr[i];
        }
      });
    })(values[r], r + 1);
  }
  return {
    sheet: sh,
    rows: rows,
    col: function (h) { var i = map[normHeader_(h)]; return i === undefined ? 0 : i + 1; }
  };
}

function ensureSheet_(name, headers, hidden) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sh = ss.getSheetByName(name);
  if (!sh) {
    sh = ss.insertSheet(name);
    sh.getRange(1, 1, 1, headers.length).setValues([headers]).setFontWeight('bold');
    sh.setFrozenRows(1);
    if (hidden) sh.hideSheet();
  }
  return sh;
}

/** Appends a row placing values under matching header names (unknown headers stay empty). */
function appendByHeaders_(sh, obj) {
  var lastCol = Math.max(sh.getLastColumn(), 1);
  var headers = sh.getRange(1, 1, 1, lastCol).getValues()[0];
  var used = {};
  var row = headers.map(function (h) {
    var k = normHeader_(h);
    for (var key in obj) {
      if (normHeader_(key) === k && !used[key]) { used[key] = true; return obj[key]; }
    }
    return '';
  });
  // headers missing in the sheet -> add them at the end so no data is lost
  var extra = [];
  for (var key in obj) if (!used[key]) extra.push(key);
  if (extra.length) {
    sh.getRange(1, headers.length + 1, 1, extra.length).setValues([extra]);
    extra.forEach(function (k) { row.push(obj[k]); });
  }
  sh.appendRow(row);
}

// ===================== VALUE HELPERS =====================
function json_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}

function errMsg_(err) { return (err && err.message) ? err.message : String(err); }

function checkKey_(key) {
  var secret = PropertiesService.getScriptProperties().getProperty('SECRET');
  if (!secret) return false; // not configured -> deny everything
  return String(key == null ? '' : key) === String(secret);
}

function str_(v) {
  if (v === null || v === undefined) return '';
  if (isDate_(v)) return toYmd_(v);
  return String(v).trim();
}

function isDate_(v) {
  return Object.prototype.toString.call(v) === '[object Date]' && !isNaN(v.getTime());
}

function tz_() {
  try { return Session.getScriptTimeZone() || 'Etc/UTC'; } catch (e) { return 'Etc/UTC'; }
}

function todayYmd_() { return Utilities.formatDate(new Date(), tz_(), 'yyyy-MM-dd'); }

function pad2_(n) { return (n < 10 ? '0' : '') + n; }

/** Date object | "YYYY-MM-DD" | "DD.MM.YYYY" | "MM/DD/YYYY" | serial number -> "YYYY-MM-DD" or "" */
function toYmd_(v) {
  if (v === null || v === undefined || v === '') return '';
  if (isDate_(v)) return Utilities.formatDate(v, tz_(), 'yyyy-MM-dd');
  if (typeof v === 'number') {
    if (v > 20000 && v < 80000) { // spreadsheet serial date
      var d = new Date(Date.UTC(1899, 11, 30) + Math.round(v * 86400000));
      return d.getUTCFullYear() + '-' + pad2_(d.getUTCMonth() + 1) + '-' + pad2_(d.getUTCDate());
    }
    return '';
  }
  var s = String(v).trim();
  var m = s.match(/^(\d{4})[-.\/](\d{1,2})[-.\/](\d{1,2})/);
  if (m) return m[1] + '-' + pad2_(+m[2]) + '-' + pad2_(+m[3]);
  m = s.match(/^(\d{1,2})\.(\d{1,2})\.(\d{4})$/); // DD.MM.YYYY
  if (m) return m[3] + '-' + pad2_(+m[2]) + '-' + pad2_(+m[1]);
  m = s.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/); // MM/DD/YYYY
  if (m) return m[3] + '-' + pad2_(+m[1]) + '-' + pad2_(+m[2]);
  var d2 = new Date(s);
  return isNaN(d2.getTime()) ? '' : Utilities.formatDate(d2, tz_(), 'yyyy-MM-dd');
}

function toBool_(v) {
  if (v === true) return true;
  if (v === false || v === null || v === undefined) return false;
  if (typeof v === 'number') return v !== 0;
  var s = String(v).trim().toLowerCase();
  return s === 'true' || s === '1' || s === 'yes' || s === 'y' || s === 'так' || s === 'x' || s === '✓';
}

function toNum_(v, dflt) {
  if (typeof v === 'number' && isFinite(v)) return v;
  var s = String(v == null ? '' : v).replace(/[\s,]/g, '');
  if (s === '') return dflt;
  var n = Number(s);
  return isFinite(n) ? n : dflt;
}

function numOrStr_(v) {
  if (v === null || v === undefined || v === '') return '';
  var n = Number(v);
  return (typeof v === 'number' || (String(v).trim() !== '' && isFinite(n))) ? n : safeCell_(String(v).slice(0, 50));
}

/** "#FF5A5A" / "ff5a5a" / "#f5a" -> "#ff5a5a"; anything else -> "" */
function toColor_(v) {
  var s = str_(v).toLowerCase().replace(/^#/, '');
  if (/^[0-9a-f]{3}$/.test(s)) s = s[0] + s[0] + s[1] + s[1] + s[2] + s[2];
  return /^[0-9a-f]{6}$/.test(s) ? '#' + s : '';
}

/** 123456 / "123456" / "rbxassetid://123456" / "...?id=123456" -> 123456 (number) or "" */
function toAssetId_(v) {
  if (typeof v === 'number' && isFinite(v) && v > 0) return Math.floor(v);
  var m = str_(v).match(/(\d{3,})/);
  return m ? Number(m[1]) : '';
}

function versionStr_(v) {
  if (typeof v === 'number') return String(v);
  return str_(v);
}

function normCode_(v) { return str_(v).toUpperCase().replace(/\s+/g, ''); }

function normReward_(v) {
  var s = str_(v).toLowerCase();
  for (var i = 0; i < VALID_REWARDS.length; i++) if (VALID_REWARDS[i].toLowerCase() === s) return VALID_REWARDS[i];
  return str_(v);
}

function normItem_(reward, v) {
  var s = str_(v);
  if (reward === 'Potion') {
    for (var i = 0; i < VALID_POTIONS.length; i++) if (VALID_POTIONS[i].toLowerCase() === s.toLowerCase()) return VALID_POTIONS[i];
    return s;
  }
  if (reward === 'Golem') return s.toLowerCase().replace(/\s+/g, '');
  return '';
}

/** Prevents formula injection from player-supplied text. */
function safeCell_(s) {
  s = String(s == null ? '' : s);
  return /^[=+\-@]/.test(s) ? "'" + s : s;
}

// ===================== CACHE =====================
function cached_(name, fn) {
  if (!CACHE_SECONDS) return fn();
  var cache = CacheService.getScriptCache();
  var key = 'list_' + name;
  var hit = cache.get(key);
  if (hit) {
    try { return JSON.parse(hit); } catch (e) { /* fall through */ }
  }
  var data = fn();
  var s = JSON.stringify(data);
  if (s.length < 90000) cache.put(key, s, CACHE_SECONDS); // CacheService value limit is 100 KB
  return data;
}

function clearCache_() {
  try { CacheService.getScriptCache().removeAll(['list_updates', 'list_codes']); } catch (e) {}
}

// ===================== SHEET UI (menu, colors, checkboxes) =====================
/** Adds the "Golems" menu when the spreadsheet is opened. */
function onOpen() {
  SpreadsheetApp.getUi().createMenu('⛏ Golems')
    .addItem('Налаштувати таблицю (чекбокси, кольори)', 'setupSheets')
    .addItem('Розфарбувати кольорові клітинки', 'paintColorCells')
    .addItem('Очистити кеш API', 'clearCacheMenu')
    .addItem('Згенерувати SECRET', 'generateSecret')
    .addToUi();
}

/** Simple trigger: repaints color cells and clears API cache when Updates/Codes are edited. */
function onEdit(e) {
  try {
    if (!e || !e.range) return;
    var sh = e.range.getSheet();
    var name = sh.getName();
    if (name === SHEET_UPDATES || name === SHEET_CODES) clearCache_();
    if (name === SHEET_UPDATES) paintColorCells_(sh, e.range.getRow(), e.range.getNumRows());
  } catch (err) { /* ignore */ }
}

function paintColorCells() {
  var sh = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_UPDATES);
  if (sh) paintColorCells_(sh, 2, Math.max(sh.getLastRow() - 1, 1));
}

function paintColorCells_(sh, startRow, numRows) {
  var t = readTable_(SHEET_UPDATES);
  ['Title Color', 'Text Color'].forEach(function (h) {
    var col = t.col(h);
    if (!col) return;
    var first = Math.max(startRow, 2);
    var n = startRow + numRows - first;
    if (n <= 0) return;
    var rng = sh.getRange(first, col, n, 1);
    var vals = rng.getValues();
    var bgs = [], fcs = [];
    vals.forEach(function (row) {
      var c = toColor_(row[0]);
      bgs.push([c || null]);
      fcs.push([c ? contrast_(c) : null]);
    });
    rng.setBackgrounds(bgs).setFontColors(fcs);
  });
}

function contrast_(hex) {
  var r = parseInt(hex.substr(1, 2), 16), g = parseInt(hex.substr(3, 2), 16), b = parseInt(hex.substr(5, 2), 16);
  return (0.299 * r + 0.587 * g + 0.114 * b) > 150 ? '#000000' : '#ffffff';
}

/** One-time setup after importing the xlsx: checkboxes, dropdowns, hidden log, colors. */
function setupSheets() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var up = ensureSheet_(SHEET_UPDATES, HEADERS.Updates, false);
  var co = ensureSheet_(SHEET_CODES, HEADERS.Codes, false);
  var fb = ensureSheet_(SHEET_FEEDBACK, HEADERS.Feedback, false);
  var log = ensureSheet_(SHEET_REDEEMLOG, HEADERS.RedeemLog, true);
  var cb = SpreadsheetApp.newDataValidation().requireCheckbox().build();
  [[up, ['Active', 'Pinned']], [co, ['Active']]].forEach(function (pair) {
    var sh = pair[0];
    var t = readTable_(sh.getName());
    pair[1].forEach(function (h) {
      var col = t.col(h);
      if (!col) return;
      var rng = sh.getRange(2, col, Math.max(sh.getMaxRows() - 1, 1), 1);
      var vals = rng.getValues().map(function (r) { return [r[0] === '' || r[0] === null ? '' : toBool_(r[0])]; });
      rng.setDataValidation(cb).setValues(vals);
    });
  });
  var tc = readTable_(SHEET_CODES);
  if (tc.col('Reward')) {
    co.getRange(2, tc.col('Reward'), Math.max(co.getMaxRows() - 1, 1), 1).setDataValidation(
      SpreadsheetApp.newDataValidation().requireValueInList(VALID_REWARDS, true).setAllowInvalid(false).build());
  }
  var tf = readTable_(SHEET_FEEDBACK);
  if (tf.col('Status')) {
    fb.getRange(2, tf.col('Status'), Math.max(fb.getMaxRows() - 1, 1), 1).setDataValidation(
      SpreadsheetApp.newDataValidation().requireValueInList(['New', 'Seen', 'Fixed', "Won't fix"], true).build());
  }
  if (!log.isSheetHidden()) log.hideSheet();
  paintColorCells();
  clearCache_();
  ss.toast('Готово: чекбокси, списки та кольори налаштовано.', 'Golems', 5);
}

function clearCacheMenu() {
  clearCache_();
  SpreadsheetApp.getActiveSpreadsheet().toast('Кеш очищено — гра побачить зміни одразу.', 'Golems', 4);
}

/** Generates a random 24-char secret and stores it as SECRET (only if not set yet). */
function generateSecret() {
  var props = PropertiesService.getScriptProperties();
  var cur = props.getProperty('SECRET');
  var ui = SpreadsheetApp.getUi();
  if (cur) { ui.alert('SECRET вже задано:\n\n' + cur + '\n\n(Змінити можна в Project Settings → Script properties.)'); return; }
  var chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
  var s = '';
  for (var i = 0; i < 24; i++) s += chars.charAt(Math.floor(Math.random() * chars.length));
  props.setProperty('SECRET', s);
  ui.alert('Новий SECRET збережено:\n\n' + s + '\n\nСкопіюйте його для гри.');
}

/** Run from the editor (Run ▶) to check that sheets are read correctly. Output: View → Logs. */
function testApi() {
  Logger.log(JSON.stringify({ updates: getUpdates_(), codes: getCodes_() }, null, 2));
}
