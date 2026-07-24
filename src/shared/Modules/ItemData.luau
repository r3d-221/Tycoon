--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Modules.Types)

type Rarity = Types.Rarity
type ItemId = Types.ItemId

export type ItemData = {
	discription: string,
	image: string,
	rarity: Rarity,
	type: string,
}

local public: { [ItemId]: ItemData } = {
	slimeRemains = {
		discription = "The remains collected from the slimes",
		image = "id",
		rarity = "common",
		type = "material",
	},
}

return public
