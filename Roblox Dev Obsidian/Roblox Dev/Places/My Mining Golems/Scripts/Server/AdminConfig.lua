-- AdminConfig — хто має доступ до адмін-панелі (лише сервер: ServerStorage, клієнт цього файлу не бачить).
-- Де: ServerStorage/AdminConfig (ModuleScript). Читає ServerScriptService/AdminService.
-- ADMINS — userId адмінів. STUDIO_ALL = true — у Studio (тест) панель є в усіх тестових гравців.
-- Панель відкривається клавішею F2. Усі дії сервер перевіряє заново (isAdmin) і пише в журнал GolemRegistry (e = "admin").
return {
	ADMINS = {
		3696478279, -- власник
	},
	STUDIO_ALL = true,
}
