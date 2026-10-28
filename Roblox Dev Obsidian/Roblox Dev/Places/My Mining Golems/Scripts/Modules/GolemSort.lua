--!strict
-- GolemSort — сортування големів (спільне для InventoryUI і PlotPlaceUI) і кнопка зі списком «SORT BY».
-- Де: ReplicatedStorage/Shared/GolemSort (ModuleScript). Сервер (InventoryService) бере звідси список ключів для перевірки.
-- Макет: веб-макет sort (варіант B, погоджено 26.10.2026).
--
-- Сортування (ключ → порядок; при рівності — порядок отримання):
--   newest   — нові першими (найновіший угорі; у InvGolems новий і повернутий зі стенда голем — у кінці, тому order за спаданням);
--   best     — лише сила (GolemCatalog.power з мутацією), без групування за класом — як у макеті;
--   rarity   — Celestial → Common (Exclusive — найвище), далі сила;
--   mutation — Secret → Normal, далі рідкість і сила;
--   name     — A → Z, далі сила;
--   class    — Miner · Carrier · Warrior, далі сила.
-- Вибране сортування — атрибут гравця InvSort (спільний для інвентаря й плоту), зберігається в секції Inventory (поле sort);
-- клієнт міняє його через Remotes/InventoryAction "Sort".
-- Погоджено користувачем 26.10.2026: Newest — нові першими; Best — без групування за класом.

local GolemSort = {}

GolemSort.ICON = "rbxassetid://120943936939331" -- sort_icon (три смуги + лаймова стрілка; Decal 130374685026836)
GolemSort.DEFAULT = "best"
GolemSort.LIST = {
	{ key = "newest", label = "Newest", hint = "newest first" },
	{ key = "best", label = "Best", hint = "strongest first" },
	{ key = "rarity", label = "Rarity", hint = "Celestial → Common" },
	{ key = "mutation", label = "Mutation", hint = "Secret → Normal" },
	{ key = "name", label = "Name", hint = "A → Z" },
	{ key = "class", label = "Class", hint = "Miner · Carrier · Warrior" },
}
GolemSort.VALID = {}
for _, s in GolemSort.LIST do GolemSort.VALID[s.key] = s end

local CLASS_ORD = { miner = 1, m = 1, carrier = 2, c = 2, warrior = 3, w = 3 }

-- поточне сортування гравця
function GolemSort.current(player: Player): string
	local v = player:GetAttribute("InvSort")
	return (type(v) == "string" and GolemSort.VALID[v]) and v or GolemSort.DEFAULT
end

-- list — масив елементів з полями: order (порядок отримання), power, ri (індекс рідкості), mut, name, cls.
-- Сортує на місці й повертає той самий масив.
function GolemSort.sort(list: { any }, key: string): { any }
	local mixed = false
	local c0 = list[1] and list[1].cls
	for _, it in list do if CLASS_ORD[it.cls] ~= CLASS_ORD[c0] then mixed = true; break end end
	local function cmp(a, b): boolean
		local function num(x, y) return x ~= y, x > y end
		if key == "newest" then return a.order > b.order end
		if key == "best" then
			if a.power ~= b.power then return a.power > b.power end
			return a.order > b.order -- рівна сила — новіший вище
		elseif key == "rarity" then
			local d, r = num(a.ri, b.ri); if d then return r end
		elseif key == "mutation" then
			local d, r = num(a.mut, b.mut); if d then return r end
			d, r = num(a.ri, b.ri); if d then return r end
		elseif key == "name" then
			if a.name ~= b.name then return a.name < b.name end
		elseif key == "class" then
			if CLASS_ORD[a.cls] ~= CLASS_ORD[b.cls] then return (CLASS_ORD[a.cls] or 9) < (CLASS_ORD[b.cls] or 9) end
		end
		-- далі сила; якщо в списку кілька класів — спершу клас (сила носія й майнера в різних одиницях; для Best не застосовується)
		if mixed and CLASS_ORD[a.cls] ~= CLASS_ORD[b.cls] then return (CLASS_ORD[a.cls] or 9) < (CLASS_ORD[b.cls] or 9) end
		if a.power ~= b.power then return a.power > b.power end
		return a.order < b.order
	end
	table.sort(list, cmp)
	return list
end

-- ===== кнопка зі списком =====
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local C = Color3.fromHex
local INK = C("14161a")
local WHITE = Color3.new(1, 1, 1)
local LIME = C("c8ff6a")
local MUTED = C("8d96a1")
local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
local XBOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
local PANEL_W, ROW_H, HEAD_H = 236, 36, 30

local function new(class: string, props: any, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in props do (o :: any)[k] = v end
	o.Parent = parent
	return o
end
local function txt(parent, x, cy, w, size, text, color, sw, font, props)
	local t = new("TextLabel", { Position = UDim2.fromOffset(x, cy - size * 0.6), Size = UDim2.fromOffset(w, size * 1.2), BackgroundTransparency = 1,
		FontFace = font or HEAVY, TextSize = size, Text = text, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left }, parent)
	if props then for k, v in props do t[k] = v end end
	if sw > 0 then new("UIStroke", { Color = INK, Thickness = sw, LineJoinMode = Enum.LineJoinMode.Round }, t) end
	return t
end
local function inside(p: Vector3, g: GuiObject): boolean
	if not g.Visible then return false end
	local a, s = g.AbsolutePosition, g.AbsoluteSize
	return p.X >= a.X and p.X <= a.X + s.X and p.Y >= a.Y and p.Y <= a.Y + s.Y
end

-- GolemSort.menu(opt) → api. opt:
--   button  — кнопка StyleA (b.root) зі StyleA.bind; її onClick має викликати api.toggle();
--   w, h    — розмір кнопки (одиниці дизайну);
--   layer   — контейнер для панелі (Pop вікна: поверх усього, той самий масштаб); panelPos — Vector2 верхнього лівого кута в layer;
--   onPick(key) — вибір пункту (кнопка оновлюється сама через refresh(key)).
-- Усе, що належить кнопці (іконка, назва, ▾), — дочірнє b.root (масштабується разом із нею).
function GolemSort.menu(opt: any): any
	local b, w, h = opt.button, opt.w, opt.h
	local UISounds = require(RS:WaitForChild("Shared"):WaitForChild("UISounds"))
	-- вміст кнопки: іконка, коротка назва, ▾ (у межах грані StyleA)
	local fx, fy, fw, fh = 0, 0, w, h
	pcall(function()
		local StyleA = require(RS.Shared:WaitForChild("StyleA"))
		fx, fy, fw, fh = StyleA.faceRect(w, h)
	end)
	local isz = math.floor(fh * 0.92 + 0.5)
	new("ImageLabel", { Name = "SortIcon", BackgroundTransparency = 1, Image = GolemSort.ICON, ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromOffset(fx + 2, fy + (fh - isz) / 2), Size = UDim2.fromOffset(isz, isz), ZIndex = 5 }, b.root)
	local labW = fw - isz - 24
	local lab = txt(b.root, fx + isz + 6, fy + fh / 2, labW, h >= 48 and 20 or 19, "", WHITE, 2.2, HEAVY, { Name = "SortLabel", ZIndex = 6, TextScaled = true })
	new("UITextSizeConstraint", { MaxTextSize = h >= 48 and 20 or 19, MinTextSize = 10 }, lab)
	local caret = txt(b.root, fx + fw - 17, fy + fh / 2 + 1, 14, 14, "▼", WHITE, 1.6, HEAVY, { Name = "SortCaret", ZIndex = 6,
		TextXAlignment = Enum.TextXAlignment.Center })
	-- панель списку (квадратна, темна, обводка #14161a)
	local ph = HEAD_H + #GolemSort.LIST * ROW_H + 8
	local root = new("Frame", { Name = "SortMenu", BackgroundTransparency = 1, Position = UDim2.fromOffset(opt.panelPos.X, opt.panelPos.Y),
		Size = UDim2.fromOffset(PANEL_W, ph), Visible = false, ZIndex = 60 }, opt.layer)
	new("Frame", { Name = "Shadow", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.65, BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 6), Size = UDim2.fromOffset(PANEL_W, ph), ZIndex = 1 }, root)
	local pan = new("Frame", { Name = "Panel", BackgroundColor3 = C("1b1e23"), BorderSizePixel = 0, Size = UDim2.fromOffset(PANEL_W, ph), ZIndex = 2 }, root)
	new("UIStroke", { Color = INK, Thickness = 3, LineJoinMode = Enum.LineJoinMode.Miter }, pan)
	local inner = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(1, 1), Size = UDim2.fromOffset(PANEL_W - 2, ph - 2), ZIndex = 2 }, pan)
	new("UIStroke", { Color = WHITE, Thickness = 1.5, Transparency = 0.92, LineJoinMode = Enum.LineJoinMode.Miter }, inner)
	txt(pan, 14, 17, PANEL_W - 28, 13, "SORT BY", MUTED, 0, XBOLD, { ZIndex = 3 })
	new("Frame", { BackgroundColor3 = WHITE, BackgroundTransparency = 0.92, BorderSizePixel = 0, Position = UDim2.fromOffset(10, 30), Size = UDim2.fromOffset(PANEL_W - 20, 2), ZIndex = 3 }, pan)
	local api: any = {}
	local rows = {}
	local cur = GolemSort.DEFAULT
	for i, s in GolemSort.LIST do
		local r = new("TextButton", { Name = "Row_" .. s.key, Text = "", AutoButtonColor = false, BackgroundColor3 = C("2c323a"), BackgroundTransparency = 1,
			BorderSizePixel = 0, Position = UDim2.fromOffset(4, HEAD_H + 4 + (i - 1) * ROW_H), Size = UDim2.fromOffset(PANEL_W - 8, ROW_H), ZIndex = 4 }, pan)
		r:SetAttribute("NoHoverSound", true) -- звук наведення — свій (нижче), без дубля від автоматичного
		local ck = txt(r, 8, ROW_H / 2, 22, 18, "✓", LIME, 2.2, HEAVY, { ZIndex = 5, TextXAlignment = Enum.TextXAlignment.Center })
		local t = txt(r, 34, ROW_H / 2 - 6.5, PANEL_W - 50, 18, s.label, WHITE, 1.8, HEAVY, { ZIndex = 5 })
		txt(r, 34, ROW_H / 2 + 8.5, PANEL_W - 50, 11.5, s.hint, MUTED, 0, XBOLD, { ZIndex = 5 })
		r.MouseEnter:Connect(function() r.BackgroundTransparency = 0; UISounds.play("hover", 0.05) end)
		r.MouseLeave:Connect(function() r.BackgroundTransparency = 1 end)
		r.Activated:Connect(function()
			UISounds.play("tap", 0.08)
			api.close()
			if s.key ~= cur then
				api.refresh(s.key)
				if opt.onPick then opt.onPick(s.key) end
			end
		end)
		rows[s.key] = { r = r, ck = ck, t = t }
	end
	function api.refresh(key: string)
		cur = GolemSort.VALID[key] and key or GolemSort.DEFAULT
		lab.Text = GolemSort.VALID[cur].label
		for k, row in rows do
			local on = k == cur
			row.ck.Visible = on
			row.t.TextColor3 = on and LIME or WHITE
		end
	end
	function api.isOpen(): boolean return root.Visible end
	function api.open()
		root.Visible = true
		for _, row in rows do row.r.BackgroundTransparency = 1 end
	end
	function api.close() root.Visible = false end
	function api.toggle() if root.Visible then api.close() else api.open() end end
	api.root, api.button, api.rows, api.caret = root, b, rows, caret
	-- клік поза списком і поза кнопкою — закрити (позиція кліку й AbsolutePosition — в одному просторі, без GetGuiInset)
	UIS.InputBegan:Connect(function(inp)
		if not root.Visible then return end
		if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
		if inside(inp.Position, pan) or inside(inp.Position, b.root) then return end
		api.close()
	end)
	api.refresh(cur)
	return api
end

return GolemSort
