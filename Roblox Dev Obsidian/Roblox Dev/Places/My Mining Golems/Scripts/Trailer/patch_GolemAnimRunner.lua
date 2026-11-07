-- patch_GolemAnimRunner — тимчасова латка ReplicatedStorage/Shared/GolemAnimRunner для запису трейлера (07.11.2026).
-- Запускати в командному рядку Studio (Edit). Без неї големи трейлера анімуються з LOD (далекі/чужі застигають, бюджет 40 за кадр).
-- Латка: коли workspace.TrailerLive = true (ставить TrailerDirector), големи з Workspace/TrailerLive анімуються щокадру,
--   без бюджету (поза екраном — рідко). Після запису повернути оригінал (бекап створюється тут же в ServerStorage/NicheBackup).
local mod = game.ReplicatedStorage.Shared.GolemAnimRunner
local bk = game.ServerStorage:FindFirstChild("NicheBackup") or Instance.new("Folder", game.ServerStorage)
bk.Name = "NicheBackup"
if not bk:FindFirstChild("GolemAnimRunner_pre_trailer") then local c = mod:Clone(); c.Name = "GolemAnimRunner_pre_trailer"; c.Parent = bk end
local s = mod.Source
if s:find("TrailerLive", 1, true) then return "already" end
local a1 = "\tif not m:IsDescendantOf(workspace) then e.iv, e.low = 0, false; return end\n"
local add1 = a1 .. [[
	-- 07.11.2026: трейлер (лише Studio, StarterPlayerScripts/TrailerDirector ставить workspace.TrailerLive) — свої големи
	--   трейлера (Workspace/TrailerLive) щокадру без LOD; поза екраном — рідко
	if workspace:GetAttribute("TrailerLive") == true and m:IsDescendantOf(workspace:FindFirstChild("TrailerLive") or m) then
		e.low = false
		if cam then
			local v = cam:WorldToViewportPoint(e.root.Position)
			local vs = cam.ViewportSize
			if v.Z < -6 or v.X < -SCREEN_PAD or v.Y < -SCREEN_PAD or v.X > vs.X + SCREEN_PAD or v.Y > vs.Y + SCREEN_PAD then e.iv = IV.off; return end
		end
		e.iv = 0
		return
	end
]]
local i = s:find(a1, 1, true); assert(i, "a1")
s = s:sub(1, i - 1) .. add1 .. s:sub(i + #a1)
local a2 = "\t\t\t\te.tierT = 0.4 + math.random() * 0.2\n"
local i2 = s:find(a2, 1, true); assert(i2, "a2")
s = s:sub(1, i2 - 1) .. "\t\t\t\te.tierT = if trailer then 0.05 else 0.4 + math.random() * 0.2\n" .. s:sub(i2 + #a2)
local a3 = "\tlocal hp = if hrp and hrp:IsA(\"BasePart\") then hrp.Position else nil\n"
local i3 = s:find(a3, 1, true); assert(i3, "a3")
s = s:sub(1, i3 - 1) .. a3 .. "\tlocal trailer = workspace:GetAttribute(\"TrailerLive\") == true\n" .. s:sub(i3 + #a3)
local a4 = "\tlocal budget = BUDGET\n"
local i4 = s:find(a4, 1, true); assert(i4, "a4")
s = s:sub(1, i4 - 1) .. "\tlocal budget = if trailer then 100000 else BUDGET\n" .. s:sub(i4 + #a4)
s = s:gsub("(%-%- step%(dt, low%))", "-- 07.11.2026: режим трейлера (workspace.TrailerLive, лише Studio) — големи Workspace/TrailerLive щокадру, без бюджету.\n%1", 1)
mod.Source = s
return "patched"
