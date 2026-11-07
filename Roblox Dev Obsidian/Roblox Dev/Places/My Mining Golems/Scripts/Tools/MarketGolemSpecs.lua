--!strict
-- Специфікації пост-обробки для MarketGolemPost.build (ексклюзиви Marketplace).
-- Перебудова всіх трьох: require(NicheTools.MarketGolemSpecs:Clone()).rebuildAll()
local S = {}

S.list = {
	{ name = "Cyborg", kind = "cyborg", X = -1053.2 },
	{ name = "LampMiner", kind = "lampminer", X = -1043.2 },
	{ name = "Spartan", kind = "spartan", X = -1033.2 },
}

S.spec = {
	Cyborg = [[{"mats":{},"shapes":{},"lights":[{"part":"ReactorCore","kind":"PointLight","color":"#5ff0ff","range":9,"brightness":1.6},{"part":"AntennaTip","kind":"PointLight","color":"#ff3550","range":5,"brightness":1.5,"max":1.5}],"particles":[{"part":"ThrusterFlame_R","preset":"jet"},{"part":"ThrusterFlame_L","preset":"jet"}],"itemAttrs":{"Cell1":{"FxHue":true,"FxY":0.0},"Cell2":{"FxHue":true,"FxY":0.15},"Cell3":{"FxHue":true,"FxY":0.3},"HeadCore":{"FxHue":true,"FxY":0.5},"GearHub":{"FxHue":true,"FxY":0.5},"Pick4":{"FxHue":true,"FxY":0.8},"PickEdge1":{"FxHue":true,"FxY":0.6},"PickEdge2":{"FxHue":true,"FxY":0.7},"SpikeTip":{"FxHue":true,"FxY":0.4},"Gear":{"FxSpin":[1,0,0],"FxSpeed":5},"Gear2":{"FxSpin":[1,0,0],"FxSpeed":5},"Halo1":{"FxSpin":[0,1,0],"FxSpeed":3,"FxHue":true},"Halo2":{"FxSpin":[0,1,0],"FxSpeed":3,"FxHue":true},"SwordBlade":{"FxHue":true,"FxY":0.2},"SwordTip":{"FxHue":true,"FxY":0.6}},"boxAttrs":{}}]],
	LampMiner = [[{"mats":{},"shapes":{"Bedroll":"Cylinder","WheelRF":"Cylinder","WheelRB":"Cylinder","WheelLF":"Cylinder","WheelLB":"Cylinder"},"lights":[{"part":"LampLens","kind":"SpotLight","color":"#fff1c4","range":20,"brightness":3,"angle":50,"face":"Back","max":3},{"part":"LanternGlass","kind":"PointLight","color":"#ffb04a","range":7,"brightness":1.4,"max":1.4},{"part":"CartLanternGlass","kind":"PointLight","color":"#ffb04a","range":6,"brightness":1.6,"box":true}],"particles":[{"part":"LampBeam","preset":"dust"}],"itemAttrs":{},"boxAttrs":{"CartLanternGlass":{"FxBlink":1.7,"LightMax":1.6}}}]],
	Spartan = [[{"mats":{},"shapes":{},"lights":[{"part":"Emblem","kind":"PointLight","color":"#ffd36a","range":6,"brightness":0.8}],"particles":[{"part":"BladeEdgeTip","preset":"glint","item":"Sword"}],"itemAttrs":{"BladeEdge":{"FxHue":true,"FxY":0.0},"BladeEdgeTip":{"FxHue":true,"FxY":0.3},"Ribbon1":{"WobbleAxis":[1,0,0],"WobbleAmp":0.12,"WobbleSpeed":7},"Ribbon2":{"WobbleAxis":[1,0,0],"WobbleAmp":0.22,"WobbleSpeed":7,"WobblePhase":1.2}},"boxAttrs":{}}]],
}

function S.rebuildAll(): string
	local P = require((game.ServerStorage :: any).NicheTools.MarketGolemPost:Clone()) :: any
	local out = {}
	for _, t in S.list do
		local ok, r = pcall(P.build, t.name, t.kind, t.X, S.spec[t.name])
		table.insert(out, t.name .. ": " .. tostring(ok) .. " " .. tostring(r))
		task.wait()
	end
	return table.concat(out, "\n")
end

return S
