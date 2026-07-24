--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Modules.Types)

type LootTableId = Types.LootTableId
type EnemyDrops = Types.EnemyDrops

local LootTables: { [LootTableId]: { EnemyDrops } } = {
	basicSlimeLoot = {
		{
			itemId = "slimeRemains",
			amount = { min = 1, max = 2 },
			dropChance = 1,
		},
	},
	basicRobotLoot = {
		{
			itemId = "parts",
			amount = { min = 1, max = 2 },
			dropChance = 1,
		},
	},
}

return LootTables
