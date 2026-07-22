local public = {}

-- maybe added later
--public.class = {
--	large = {},
--	small = {},
	
--}

public.slime = {
	hitbox = {
		type = "cylinder",
		windUp = 0.4,
		active = 0.15,
		recovery = 0.6,
		radius = 10,
		height = 2,
		distance = 10,
	},
	animation = {
		idle = "",
		chase = "",
		attack = "",
		dead = "",
	},
	drops = {
		slimeRemains = {
			amount = {min = 1, max = 2},
			dropChance = 1,
		}	
	},
	walkspeed = 12,
	damage = 10,
	cooldown = 2,
	health = 100,
	attackRange = 20,
	minAggroRange = 25,
	maxAggroRange = 35,
}

public.robot = {
	hitbox = {
		type = "arc",
		windUp = 0.4,
		active = 0.15,
		recovery = 0.6,
		range = 10,
		angle = 75,
	},
	animation = {
		idle = "",
		chase = "",
		attack = "",
		dead = "",
	},
	walkspeed = 14,
	damage = 12,
	cooldown = 3,
	health = 150,
	attackRange = 23,
	minAggroRange = 29,
	maxAggroRange = 36,
}

return public