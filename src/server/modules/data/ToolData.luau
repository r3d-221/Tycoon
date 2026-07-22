local public = {}

public.upgrades = {
	range = 5,
	speed = 0.2,
	damage = 5,
	chargeRate = 0.05,
	capacity = 10,
	scanRadius = 5,
	cooldown = 0.1,
}

public.vacummCleaner = {
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
}

return public