--!strict
-- WindowFit — одне правило розміру й позиції для всіх вікон (Inventory, Sell, Forge, PlotPlace …).
-- Де: ReplicatedStorage/Shared/WindowFit (ModuleScript). Клієнтський модуль.
--
-- Рамка кожного вікна має однакові пропорції (Inventory 980 × 528, Sell/Forge 1206 × 650 ≈ 1,856), тож на екрані всі
-- вікна 1 в 1 однакові й стоять в одному місці:
--   * блок «заголовок + рамка» займає до TARGET_W ширини і TARGET_H висоти екрана (обведена зона з референсу);
--   * рамка по центру по горизонталі; по вертикалі блок по центру вільної зони між верхньою смугою Roblox і хотбаром;
--   * на малих екранах / телефоні — максимум, що вміщається з полями.
-- Заголовок над рамкою рахується однаково для всіх (TITLE_K висоти рамки), щоб розмір не залежав від макета вікна.
--
-- Використання (у fit() вікна):
--   WindowFit.place(modalRoot, fitScale, { canvasW, canvasH, winX, winY, winW, winH, extraH? })
--   extraH — додаткова висота рамки знизу (Forge: 4-й рядок Money); розмір рахується від базової winH, вікно лише дорастає вниз.
--   leftExtra — що стирчить ліворуч від рамки (SHOP: закладки): враховується в ширину й зсуває рамку правіше, коли тісно.
-- SHRINK (28.10.2026): усі вікна на 5 % менші (айпади: закладки SHOP виходили за екран).

local GuiService = game:GetService("GuiService")
local UIS = game:GetService("UserInputService")

local M = {}

M.TARGET_W = 0.68 -- рамка: частка ширини екрана
M.TARGET_H = 0.72 -- заголовок + рамка: частка висоти екрана
M.TITLE_K = 0.14  -- заголовок над рамкою, частка висоти рамки
M.MAX = 3
M.SHRINK = 0.95 -- усі вікна на 5 % менші

-- хотбар (InventoryUI перезаписує своїми константами): вікна стоять над ним
M.HS = 74
M.HB_W = 9 * 74 + 8 * 8

function M.topInset(): number
	local top = 0
	pcall(function() top = GuiService.TopbarInset.Max.Y end)
	if top <= 0 then top = GuiService:GetGuiInset().Y end
	return top
end

-- висота смуги хотбара знизу (так само, як рахує InventoryUI.fitHotbar)
function M.bottomInset(vw: number, vh: number): number
	local s = vh / 720
	s = math.min(s, (vw - 2 * 370 * (vh / 720)) / M.HB_W, (vw - 24) / M.HB_W)
	s = math.max(0.35, s)
	return (M.HS + 20) * s
end

function M.place(modalRoot: GuiObject, fitScale: UIScale, o: { [string]: number })
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local vw, vh = vs.X, vs.Y
	if vw < 2 or vh < 2 then return end
	local top = M.topInset()
	local bottom = M.bottomInset(vw, vh)
	local H = vh - top - bottom -- вільна висота
	local winW, winH, extra = o.winW, o.winH, o.extraH or 0
	local left = o.leftExtra or 0
	local phone = H < 460 or (UIS.TouchEnabled and not UIS.MouseEnabled)
	-- розмір і місце рахуються від БАЗОВОЇ рамки (без extra) — тож усі вікна однакові й стоять в одному місці;
	-- extra (Forge: рядок Money) лише подовжує вікно вниз. Якщо нижній край виходить за екран — зменшуємо.
	local s: number
	if phone then
		s = math.min((vw - 24) / (winW * 1.08 + left), (H - 8) / (winH * (1 + M.TITLE_K)))
	else
		s = math.min(M.TARGET_W * vw / winW, M.TARGET_H * vh / (winH * (1 + M.TITLE_K)))
		s = math.min(s, (vw - 24) / (winW * 1.08 + left), (H - 12) / (winH * (1 + M.TITLE_K)))
	end
	s = math.clamp(s * M.SHRINK, 0.1, M.MAX)
	local titlePx, blockTop
	for _ = 1, 30 do
		titlePx = winH * M.TITLE_K * s
		blockTop = top + (H - (titlePx + winH * s)) / 2
		if extra <= 0 or blockTop + titlePx + (winH + extra) * s <= vh - 8 or s <= 0.1 then break end
		s *= 0.97
	end
	fitScale.Scale = s
	local frameCX = vw / 2
	-- щоб те, що ліворуч (закладки), вмістилось: лівий край закладок не лівіше 12 px
	if left > 0 then
		local need = 12 + (left + winW / 2) * s
		if frameCX < need then frameCX = math.min(need, vw - 12 - winW * s / 2) end
	end
	local frameCY = blockTop + titlePx + winH * s / 2
	-- ModalRoot (AnchorPoint 0,5; розмір = полотно): зсув центру рамки відносно центру полотна
	local dx = (o.winX + winW / 2 - o.canvasW / 2) * s
	local dy = (o.winY + winH / 2 - o.canvasH / 2) * s
	modalRoot.AnchorPoint = Vector2.new(0.5, 0.5)
	modalRoot.Position = UDim2.fromOffset(frameCX - dx, frameCY - dy)
end

-- старі API (лишились для сумісності)
function M.scale(vw: number, vh: number, availH: number, canvasW: number, canvasH: number, phone: boolean?): number
	return math.clamp(math.min((vw - 24) / canvasW, (availH - 8) / canvasH), 0.1, M.MAX)
end

return M
