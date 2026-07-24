--!strict
local public = {}

export type ItemId = "slimeRemains" | "parts"
export type EnemyId = "slime" | "robot"
export type LootTableId = "basicSlimeLoot" | "basicRobotLoot"
export type Rarity = "common" | "rare" | "epic" | "legendary" | "mythic" | "secret"
export type HazardTaskType = "clearArea" | "connectWires"

export type EnemyDrops = {
	itemId: ItemId,
	amount: { min: number, max: number },
	dropChance: number,
}

export type CylinderHitbox = {
	type: "cylinder",
	windUp: number,
	active: number,
	recovery: number,
	radius: number,
	height: number,
	distance: number,
}
export type ArcHitbox = {
	type: "arc",
	windUp: number,
	active: number,
	recovery: number,
	range: number,
	angle: number,
}
export type Hitbox = CylinderHitbox | ArcHitbox

return public
