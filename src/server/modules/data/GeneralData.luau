--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Types = require(ReplicatedStorage.Shared.Modules.Types)
local ThreatDataModule = require(ServerScriptService.Server.Modules.Data.ThreatData)

type Rarity = Types.Rarity

export type ThreatRarity = {
	common: number,
	rare: number,
	epic: number,
	legendary: number,
	mythic: number,
	secret: number,
}

export type RarityIndex = {
	common: number,
	rare: number,
	epic: number,
	legendary: number,
	mythic: number,
	secret: number,
}

export type GeneralData = {
	threatRarity: ThreatRarity,
	rarityIndex: RarityIndex,
	rarityColor: {},
	itemRarity: {},
	threatsList: { [string]: { string } },
}

local threatsList: { [string]: { string } } = {}

for threatType: string, config: any in pairs(ThreatDataModule :: any) do
	local rarity: string = config.rarity

	if not threatsList[rarity] then
		threatsList[rarity] = {}
	end
	table.insert(threatsList[rarity], threatType)
end

local public: GeneralData = {
	threatRarity = {
		common = 0.62,
		rare = 0.23,
		epic = 0.1029,
		legendary = 0.045,
		mythic = 0.002,
		secret = 0.0001,
	},

	rarityIndex = {
		common = 1,
		rare = 2,
		epic = 3,
		legendary = 4,
		mythic = 5,
		secret = 6,
	},

	rarityColor = {
		-- not done
	},

	itemRarity = {
		-- not done
	},

	threatsList = threatsList,
}

return public
