--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Modules.Types)

type Rarity = Types.Rarity

export type DistrictId = "starter" | "left"
export type DisctrictData = {
	rarity: { min: Rarity, max: Rarity },
	incidentCooldown: number,
}

local public: { [DistrictId]: DisctrictData } = {
	starter = {
		rarity = { min = "common", max = "common" },
		incidentCooldown = 400,
		-- other info
	},
	left = {
		rarity = { min = "common", max = "rare" },
		incidentCooldown = 430,
	},
}

return public
