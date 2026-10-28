// ===== AdminLog: журнал адмін-дій і SUSPECT з гри (My Mining Golems) =====
// Як підключити:
// 1) Встав цю функцію в той самий проєкт Apps Script (Code.gs), що вже обробляє updates / codes / redeem / feedback.
// 2) У doGet(e), там де розбирається action (поруч із "feedback"), додай гілку:
//      if (action === 'adminlog') return handleAdminLog_(JSON.parse(e.parameter.data || '{}'));
//    (перевірка key — та сама, що вже є для інших дій.)
// 3) Deploy → Manage deployments → Edit → New version (URL лишається той самий).
// Аркуш AdminLog створиться сам. На кожен SUSPECT приходить лист на пошту власника таблиці.

function handleAdminLog_(body) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sh = ss.getSheetByName('AdminLog');
  if (!sh) {
    sh = ss.insertSheet('AdminLog');
    sh.appendRow(['Time (UTC)', 'Type', 'UserId', 'Name', 'Action', 'Details', 'Server', 'PlaceId']);
    sh.setFrozenRows(1);
  }
  var events = (body && body.events) || [];
  var rows = [];
  var suspects = [];
  for (var i = 0; i < events.length; i++) {
    var ev = events[i] || {};
    var t = ev.t ? new Date(ev.t * 1000) : new Date();
    var details = ev.data ? JSON.stringify(ev.data) : (ev.n ? ('attempt #' + ev.n) : '');
    rows.push([t, String(ev.e || ''), String(ev.by || ''), String(ev.name || ''), String(ev.what || ''),
      details, String(ev.job || body.jobId || ''), String(body.placeId || '')]);
    if (ev.e === 'suspect') suspects.push(ev);
  }
  if (rows.length) sh.getRange(sh.getLastRow() + 1, 1, rows.length, rows[0].length).setValues(rows);
  if (suspects.length) {
    var lines = suspects.map(function (s) {
      return 'UserId ' + s.by + ' (' + (s.name || '?') + ') — "' + s.what + '", attempt #' + (s.n || 1) + ', server ' + (s.job || '');
    });
    try {
      MailApp.sendEmail(Session.getEffectiveUser().getEmail(), 'My Mining Golems: SUSPECT admin access',
        'Someone without a role tried to use the admin panel:\n\n' + lines.join('\n'));
    } catch (err) {}
  }
  return ContentService.createTextOutput(JSON.stringify({ ok: true })).setMimeType(ContentService.MimeType.JSON);
}
