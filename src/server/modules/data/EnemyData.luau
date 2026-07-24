--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Modules.Types)

type Hitbox = Types.Hitbox
type EnemyId = Types.EnemyId
type LootTableId = Types.LootTableId

export type Enemy = {
	hitbox: Hitbox,
	lootTable: LootTableId?,
	animation: {
		idle: string,
		chase: string,
		attack: string,
		dead: string,
	},
	walkspeed: number,
	damage: number,
	cooldown: number,
	health: number,
	attackRange: number,
	minAggroRange: number,
	maxAggroRange: number,
}

local public: { [EnemyId]: Enemy } = {
	slime = {
		hitbox = {
			type = "cylinder",
			windUp = 0.4,
			active = 0.15,
			recovery = 0.6,
			radius = 10,
			height = 2,
			distance = 10,
		},
		animation = { idle = "", chase = "", attack = "", dead = "" },
		lootTable = "basicSlimeLoot",
		walkspeed = 12,
		damage = 10,
		cooldown = 2,
		health = 100,
		attackRange = 20,
		minAggroRange = 25,
		maxAggroRange = 35,
	},
	robot = {
		hitbox = {
			type = "arc",
			windUp = 0.4,
			active = 0.15,
			recovery = 0.6,
			range = 10,
			angle = 75,
		},
		animation = { idle = "", chase = "", attack = "", dead = "" },
		lootTable = "basicRobotLoot",
		walkspeed = 14,
		damage = 12,
		cooldown = 3,
		health = 150,
		attackRange = 23,
		minAggroRange = 29,
		maxAggroRange = 36,
	},
}

return public
