--!nonstrict
-- ChatTags — тег перед ніком у чаті (06.11.2026). Де: StarterPlayer/StarterPlayerScripts/ChatTags (LocalScript).
-- Стандартний TextChatService: OnIncomingMessage додає до PrefixText золотий [VIP], якщо в автора куплений геймпас VIP
--   (атрибут гравця Pass_VIP — реплікується всім). Інші теги — додати в TAGS.
local Players = game:GetService("Players")
local TCS = game:GetService("TextChatService")

local TAGS = {
	{ pass = "Pass_VIP", text = "[VIP]", color = "ffc23a" },
}

TCS.OnIncomingMessage = function(msg: TextChatMessage)
	local props = Instance.new("TextChatMessageProperties")
	local src = msg.TextSource
	local p = src and Players:GetPlayerByUserId(src.UserId)
	if p then
		local pre = ""
		for _, t in TAGS do
			if p:GetAttribute(t.pass) == true then pre ..= '<font color="#' .. t.color .. '"><b>' .. t.text .. "</b></font> " end
		end
		if pre ~= "" then props.PrefixText = pre .. msg.PrefixText end
	end
	return props
end
