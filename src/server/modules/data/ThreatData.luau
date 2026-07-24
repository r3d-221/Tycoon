--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Modules.Types)

type Rarity = Types.Rarity
type EnemyId = Types.EnemyId
type HazardTaskType = Types.HazardTaskType

export type CompletionType = "hazardCleared" | "componentDisabled"
export type SecuringStep = "closeRoad" | "disableElectricity"

export type RatingThresholds = {
	S: number,
	A: number,
	B: number,
	C: number,
}

export type ThreatInfo = {
	failDamage: number,
	hazardCount: number,
	rangeRadius: number,
	safetyOnSpawn: number,
	unresolvedTime: number,
	completionTime: number,
	escalationDelay: number,
	civilianRange: { number },
	contaminationOnSpawn: number,
	enemy: EnemyId,
	rarity: Rarity,
	taskTypes: { HazardTaskType },
	completionType: CompletionType,
	securingSteps: { SecuringStep },
	ratingThresholds: RatingThresholds,
}

local ThreatData: { [string]: ThreatInfo } = {
	smallSlimeOutbreak = {
		hazardCount = 2,
		civilianRange = { 1, 4 },
		contaminationOnSpawn = 10,
		safetyOnSpawn = -5,
		failDamage = 10,
		ratingThresholds = { S = 140, A = 200, B = 260, C = 320 },
		unresolvedTime = 400,
		completionTime = 360,
		escalationDelay = 10,
		completionType = "hazardCleared",
		rangeRadius = 20,
		rarity = "common",
		securingSteps = {},
		taskTypes = { "clearArea" },
		enemy = "slime",
	},

	largeSlimeOutbreak = {
		hazardCount = 5,
		civilianRange = { 1, 15 },
		contaminationOnSpawn = 25,
		safetyOnSpawn = -20,
		failDamage = 25,
		ratingThresholds = { S = 180, A = 240, B = 300, C = 360 },
		unresolvedTime = 450,
		completionTime = 420,
		escalationDelay = 220,
		completionType = "hazardCleared",
		rangeRadius = 30,
		rarity = "rare",
		securingSteps = { "closeRoad" },
		taskTypes = { "clearArea" },
		enemy = "slime",
	},

	robotMalfunction = {
		hazardCount = 2,
		civilianRange = { 5, 10 },
		contaminationOnSpawn = 0,
		safetyOnSpawn = -25,
		failDamage = 35,
		ratingThresholds = { S = 200, A = 260, B = 320, C = 380 },
		unresolvedTime = 520,
		completionTime = 460,
		escalationDelay = 210,
		completionType = "componentDisabled",
		rangeRadius = 25,
		rarity = "rare",
		securingSteps = { "disableElectricity", "closeRoad" },
		taskTypes = { "clearArea", "connectWires" },
		enemy = "robot",
	},
}

return ThreatData
