--!strict
-- MarketExclusiveConfig — ексклюзивні големи на стендах Marketplace (05.11.2026, GDD/Plan - Market Exclusive Golems).
-- Де: ReplicatedStorage/Shared/MarketExclusiveConfig (сервер і клієнт). Сервер — ServerScriptService/MarketExclusiveService, клієнт — MarketExclusiveClient.
-- Кожен запис: стенд (Workspace/Marketplace/Floor/<stand>), голем (GolemCatalog id) і клас, валюта й ціна.
--   cur = "robux"    — Developer Product (productId; 0 — ще не створено в Creator Hub → кнопка «SOON»);
--   cur = "tickets"  — ціна росте глобально: price + step × (скільки вже куплено на всіх серверах), дошка покупців біля стенда;
--   cur = "diamonds" — фіксована ціна.
-- Ліміт: 1 покупка на стенді на гравця (атрибут Pass_MktExcl_<kind>, зберігається як геймпаси). Продавати й купувати на ринку
--   гравців можна без ліміту. Мутувати не можна (GolemCatalog: exclusive).
local C = {}

C.LIST = {
	{ stand = "Exclusive Golem Stand 2", kind = "cyborg", cls = "miner", cur = "robux", price = 1999, productId = 3728400769 }, -- Creator Hub «Cyborg Golem», 05.11.2026
	{ stand = "Exclusive Golem Stand 3", kind = "lampminer", cls = "carrier", cur = "tickets", price = 999, step = 500 }, -- 999, далі +500 за кожну покупку (05.11.2026)
	{ stand = "Exclusive Golem Stand 4", kind = "spartan", cls = "warrior", cur = "diamonds", price = 250000 },
}

C.DISPLAY_SCALE = 1.2   -- голем на стенді × це (поверх GolemCatalog.size); під п'єдестал ⌀ ~15 стад
C.CENTER = Vector3.new(0, 0, -572) -- центр зали Marketplace (куди дивляться стенди)
C.SPIN = 0.45           -- обертання на стенді, рад/с (клієнт)
C.PROMPT_DIST = 16      -- з якої відстані видно кнопку BUY, стад
C.REACH = 22            -- сервер: максимальна відстань гравця до кнопки, стад
C.BOARD_ROWS = 8        -- дошка покупців: скільки останніх покупців показувати
C.STORE = "MarketExclusive_v1" -- DataStore глобального лічильника (у Studio — «_Studio»)
C.TOPIC = "MarketExclusive"    -- MessagingService: оновити ціну й дошку на всіх серверах
C.POLL = 60             -- с: запасне опитування лічильника

-- тексти інтерфейсу (в одному місці — для перекладу)
C.TEXT = {
	buy = "BUY", owned = "OWNED", soon = "SOON",
	exclusive = "MARKET EXCLUSIVE", limit = "LIMIT 1 PER PLAYER",
	cls = { miner = "MINER", carrier = "CARRIER", warrior = "WARRIOR" },
	cur = { robux = "R$", tickets = "TICKETS", diamonds = "DIAMONDS" },
	boardTitle = "RECENT BUYERS", boardPrice = "NEXT PRICE", boardEmpty = "Be the first buyer!", boardSub = "Price grows +%s with every buy",
	done = "%s is yours!", errOwned = "You already bought this golem", errFull = "Inventory is full",
	errTickets = "Not enough Tickets", errDiamonds = "Not enough Diamonds", errSoon = "Coming soon",
	errBusy = "Try again in a moment", errChanged = "Price changed — try again",
}

function C.byKind(kind: string): any
	for _, e in C.LIST do if e.kind == kind then return e end end
	return nil
end
function C.byProduct(id: number): any
	if id == 0 then return nil end
	for _, e in C.LIST do if e.cur == "robux" and e.productId == id then return e end end
	return nil
end
-- ціна з урахуванням глобального лічильника (скільки вже куплено)
function C.priceOf(e: any, sold: number?): number
	return e.price + (e.step or 0) * (sold or 0)
end
-- атрибут «вже купив на стенді»
function C.ownedAttr(kind: string): string
	return "Pass_MktExcl_" .. kind
end

return C
