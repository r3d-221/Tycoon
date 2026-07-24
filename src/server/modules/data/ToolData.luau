--!strict
export type ToolUpgrades = {
	range: number,
	speed: number,
	damage: number,
	chargeRate: number,
	capacity: number,
	scanRadius: number,
	cooldown: number,
}

export type ToolInfo = {
	animations: {
		idle: string,
		using: string,
		cooldown: string,
		reloading: string,
	},
	stats: ToolUpgrades,
	workType: string,
}

export type ToolModuleData = {
	upgrades: ToolUpgrades,
	tools: { [string]: ToolInfo },
}

local public: ToolModuleData = {
	upgrades = {
		range = 5,
		speed = 0.2,
		damage = 5,
		chargeRate = 0.05,
		capacity = 10,
		scanRadius = 5,
		cooldown = 0.1,
	},

	tools = {
		vacummCleaner = {
			animations = {
				idle = " -- animation id -- ",
				using = " -- animation id -- ",
				cooldown = " -- animation id -- ",
				reloading = " -- animation id -- ",
			},
			stats = {
				range = 10,
				speed = 3,
				damage = 10,
				chargeRate = 0.5,
				capacity = 100,
				scanRadius = 15,
				cooldown = 0.5,
			},
			workType = "hazardCleared",
		},
	},
}

return public
