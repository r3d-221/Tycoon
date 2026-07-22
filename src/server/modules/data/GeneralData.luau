local ServerScriptService = game:GetService("ServerScriptService")

local ThreatData = require(ServerScriptService.modules.data.ThreatData)

local public = {}

public.threatRarity = {
	common = 0.62,
	rare = 0.23,
	epic = 0.1029,
	legendary = 0.045,
	mythic = 0.002,
	secret = 0.0001
}

public.rarityIndex = {
	common =1,
	rare = 2,
	epic = 3,
	legendary = 4,
	mythic = 5,
	secret = 6
}

public.rarityColor = {
	-- not done
}

public.itemRarity = {
	-- not done
}

local threatsList = {}
for threatType, config in pairs(ThreatData) do
	local rarity = config.rarity
	threatsList[rarity] = threatsList[rarity] or {}
	table.insert(threatsList[rarity], threatType)
end
public.threatsList = threatsList

return public
