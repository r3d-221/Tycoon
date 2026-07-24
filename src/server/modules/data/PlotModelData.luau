--!strict
export type PlotModelId = "part1" | "part2"
export type RequirementType = "cityLevel" | "special"
export type PlotModelData = {
	cost: number,
	requirement: { type: RequirementType, value: number | string },
	onPurchase: (player: Player) -> (),
}

local public: { [PlotModelId]: PlotModelData } = {
	part1 = {
		cost = 100,
		requirement = { type = "cityLevel", value = 5 },
		onPurchase = function(player: Player)
			-- print("[ItemData] purchased part1 by: " .. player.Name)
		end,
	},

	part2 = {
		cost = 430,
		requirement = { type = "special", value = "Slime hunter quest" },
		onPurchase = function(player: Player)
			print("[ItemData] purchased part2 by: " .. player.Name)
		end,
	},
}

return public
