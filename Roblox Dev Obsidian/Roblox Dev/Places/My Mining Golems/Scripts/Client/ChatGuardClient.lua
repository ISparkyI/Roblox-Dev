--!nonstrict
-- ChatGuardClient — попередження антиспаму в чаті (сервер — ServerScriptService/ChatGuard, Remotes/ChatGuardNotice).
-- Показує системне повідомлення в RBXGeneral (бачить лише цей гравець). Текст — через Shared/Loc (таблиця локалізації).
local RS = game:GetService("ReplicatedStorage")
local TCS = game:GetService("TextChatService")
local Loc = require(RS:WaitForChild("Shared"):WaitForChild("Loc"))

local TEXT = {
	slow = "Slow down! Wait {1}s before your next message.",
	newbie = "New players can send 1 message every {1}s.",
	dup = "Don't repeat the same message.",
	link = "Links and Robux offers are not allowed in chat.",
	spam = "That message looks like spam.",
	muted = "You can't chat for {1} min.",
}

local ev = RS:WaitForChild("Remotes"):WaitForChild("ChatGuardNotice")
ev.OnClientEvent:Connect(function(code: string, n: number?)
	local tpl = TEXT[code]
	if not tpl then return end
	local msg = Loc.f(tpl, n or 1)
	local chans = TCS:FindFirstChild("TextChannels")
	local ch = chans and (chans:FindFirstChild("RBXGeneral") or chans:FindFirstChild("RBXSystem"))
	if ch and ch:IsA("TextChannel") then
		pcall(function() ch:DisplaySystemMessage('<font color="#ff9a5c">' .. msg .. "</font>") end)
	end
end)
