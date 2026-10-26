--!strict
-- CaveAccess — хто що може в печері збереження големів.
-- Правило: ЗАХОДИТИ і ВИХОДИТИ можуть усі гравці (гості теж), але ІНТЕРАКЦІЇ з печерою — тільки її власник:
--   купівля стендів (PriceBoard), підбір / постановка големів на стенди тощо.
-- Власник печери = власник ніші, з чийого входу (CavePrompt) гравець зайшов.
-- Сервер при вході (ServerScriptService/CaveEntrance) ставить на гравця атрибути:
--   InCave (bool), CaveOwner (UserId власника печери), CaveFrom (ім'я ніші, звідки зайшли — повернення при виході).
-- Нові системи в печері (покупка стенда, підбір голема) ПЕРЕД дією викликають CaveAccess.canInteract(player).

local CaveAccess = {}

-- заходити й виходити можуть усі
function CaveAccess.canEnter(player: Player, nicheOwnerUserId: number?): boolean
	return true
end
function CaveAccess.canExit(player: Player): boolean
	return true
end

-- чи гравець у печері власника (не гість)
function CaveAccess.isOwner(player: Player, ownerUserId: number?): boolean
	local owner = ownerUserId or (player:GetAttribute("CaveOwner") :: number?)
	return owner ~= nil and owner ~= 0 and owner == player.UserId
end

-- купівля стендів, підбір голема зі стенда, будь-які дії зі слотами: тільки власник
function CaveAccess.canInteract(player: Player, ownerUserId: number?): boolean
	if not player:GetAttribute("InCave") then return false end
	return CaveAccess.isOwner(player, ownerUserId)
end

return CaveAccess
