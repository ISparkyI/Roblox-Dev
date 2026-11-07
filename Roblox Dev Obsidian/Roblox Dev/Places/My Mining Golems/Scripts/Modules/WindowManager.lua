--!strict
-- WindowManager — «на екрані лише одне вікно» (GDD - Interface, 27.10.2026). Лише клієнт.
-- Де: ReplicatedStorage/Shared/WindowManager (ModuleScript). Кожне повноекранне вікно (Inventory, Index, PLOT N, Forge, Sell):
--   WindowManager.register(name, isOpen, close) — один раз: коли відкривається ІНШЕ вікно, це закривається (своєю анімацією);
--   WindowManager.opened(name) — на початку свого open(): закриває всі інші зареєстровані вікна.
-- Працює для будь-якого способу відкриття (клавіші B / ~ / R, кнопки HUD, кола Forge / Sell). Хотбар — не вікно, лишається.

local M = {}
local ev = Instance.new("BindableEvent")
M.current = nil :: string?
local reg: { [string]: () -> boolean } = {} -- 07.11.2026: зареєстровані вікна (для openList — SPECTATE в адмінці)

function M.opened(name: string)
	M.current = name
	ev:Fire(name)
end

function M.register(name: string, isOpen: () -> boolean, close: () -> ())
	reg[name] = isOpen
	ev.Event:Connect(function(other: string)
		if other ~= name and isOpen() then close() end
	end)
end

-- 07.11.2026: які вікна зараз відкриті (імена реєстрації, за алфавітом) — шле SpecFeedClient адміну, що стежить
function M.openList(): { string }
	local out = {}
	for n, f in reg do
		local ok, r = pcall(f)
		if ok and r then table.insert(out, n) end
	end
	table.sort(out)
	return out
end

return M
