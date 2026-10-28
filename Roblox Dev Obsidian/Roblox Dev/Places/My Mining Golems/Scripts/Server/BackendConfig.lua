-- BackendConfig — налаштування зв'язку з Google Таблицею (Apps Script Web App). Лише сервер (ServerStorage — клієнти його не бачать).
-- Читає ServerScriptService/BackendService. Атрибути URL / SECRET / VERSION на цьому ModuleScript (якщо задані) мають перевагу над полями нижче.
--   URL     — адреса розгорнутого Web App, закінчується на /exec (Deploy → Web app → URL);
--   SECRET  — той самий секретний ключ, що в Apps Script (параметр key);
--   VERSION — версія гри для відгуків (порожньо — game.PlaceVersion).
-- Поки URL або SECRET порожні — бекенд вимкнено: Updates показує запасний список, Codes — «Codes are offline»,
--   Feedback — «Can't send right now». Також треба ввімкнути Game Settings → Security → Allow HTTP Requests.
return {
	URL = "",
	SECRET = "",
	VERSION = "",
}
