local public = {}
local private = {}

public.part1 = {
	cost = 100,
	requirement = {type = "cityLevel", value = 5},
	onPurchase = function(player: Player)
		--print("[ItemData] purchased part1 by: "..player.Name)
	end,
}

public.part2 = {
	cost = 430,
	requirement = {type = "special", value = "Slime hunter quest"},
	onPurchase = function(player: Player)
		print("[ItemData] purchased part2 by: "..player.Name)
	end,
}

return public
