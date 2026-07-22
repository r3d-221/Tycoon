return {
	smallSlimeOutbreak = {
		hazardCount = 2, -- obstecles the player needs to clean
		civilianRange = {1, 4}, -- how many people can be in the incident
		contaminationOnSpawn = 10,
		safetyOnSpawn = -5,
		failDamage = 10, -- the damage it will do to the surreounding buildings if not resolved
		ratingThresholds = {S = 140, A = 200, B = 260, C = 320}, -- time in seconds
		unresolvedTime = 400,
		completionTime = 360,
		escalationDelay = 10,
		completionType = "hazardCleared",
		rangeRadius = 20,
		rarity = "common",
		securingSteps = {},
		taskTypes = {"clearArea"},
		enemy = "slime",
	},
	
	largeSlimeOutbreak = {
		hazardCount = 5, -- obstecles the player needs to clean
		civilianRange = {1, 15}, -- how many people can be in the incident
		contaminationOnSpawn = 25,
		safetyOnSpawn = -20,
		failDamage = 25, -- the damage it will do to the surreounding buildings if not resolved
		ratingThresholds = {S = 180, A = 240, B = 300, C = 360}, -- time in seconds
		unresolvedTime = 450,
		completionTime = 420,
		escalationDelay = 220,
		completionType = "hazardCleared",
		rangeRadius = 30,
		rarity = "rare",
		securingSteps = {"closeRoad"},
		taskTypes = {"clearArea"},
		enemy = "slime",
	},
	
	robotMalfunction = {
		hazardCount = 2,
		civilianRange = {5, 10},
		contaminationOnSpawn = 0,
		safetyOnSpawn = -25,
		failDamage = 35,
		ratingThresholds = {S = 200, A = 260, B = 320, C = 380},
		unresolvedTime = 520,
		completionTime = 460,
		escalationDelay = 210,
		completionType = "componentDisabled",
		rangeRadius = 25,
		rarity = "rare",
		securingSteps = {"disableElectricity", "closeRoad"},
		taskTypes = {"clearArea", "connectWires"},
		enemy = "robot",
	},
}