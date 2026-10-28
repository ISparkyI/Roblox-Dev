--!strict
-- WindowManager — «на екрані лише одне вікно» (GDD - Interface, 27.10.2026). Лише клієнт.
-- Де: ReplicatedStorage/Shared/WindowManager (ModuleScript). Кожне повноекранне вікно (Inventory, Index, PLOT N, Forge, Sell):
--   WindowManager.register(name, isOpen, close) — один раз: коли відкривається ІНШЕ вікно, це закривається (своєю анімацією);
--   WindowManager.opened(name) — на початку свого open(): закриває всі інші зареєстровані вікна.
-- Працює для будь-якого способу відкриття (клавіші B / ~ / R, кнопки HUD, кола Forge / Sell). Хотбар — не вікно, лишається.

local M = {}
local ev = Instance.new("BindableEvent")
M.current = nil :: string?

function M.opened(name: string)
	M.current = name
	ev:Fire(name)
end

function M.register(name: string, isOpen: () -> boolean, close: () -> ())
	ev.Event:Connect(function(other: string)
		if other ~= name and isOpen() then close() end
	end)
end

return M
