local ServerScriptService = game:GetService("ServerScriptService")

local Signal = require(ServerScriptService.modules.Signal)

local public = {}
local private = {}

public.__index = public

export type statName =
	"population" | "happiness" | "governmentTrust" | "safetyRating"
| "economicStrength" | "contamination" | "electricity" | "water"
| "reputation" | "performance" | "damage"

---- Sources ----
-- unresolved threats
-- weather
-- disasters
-- depertments
-- contamination
-- city damage

---- Stats ----
-- happiness
-- reputation
-- electricity
-- water
-- population
-- safety
-- performance
-- economy
-- passive income

-- stats are added to the base -> base + sum(modifiers)
-- the base doesnt change

-- need to clamp the value so some values dont go over 100

-- need to do oop since it will track each player

-- not sure if the data should be here and if it sghould be saved directly to player data after change
local STATS: {[statName]: number} = {
	population = 500,
	happiness = 60,
	governmentTrust = 50,
	safetyRating = 40,
	economicStrength = 50,
	contamination = 0
}

local STAT_RANGE = {
	population = {0, 100_000},
	happiness = {0, 100},
	governmentTrust = {0, 100},
	safetyRating = {0, 100},
	economicStrength = {0, 100},
	contamination = {0, 100}
}

---- Main ----

-- will be called per player, once
function public.new(data)
	local self = setmetatable({}, public)
	
	self.base = {}
	self.modifiers = {}
	self.cache = {}
	self.unCalculated = {}
	
	for stat, defaultValue in pairs(STATS) do
		local value = (data and data[stat]) or defaultValue
		self.base[stat] = value
		self.modifiers[stat] = {}
		self.cache[stat] = value
		self.unCalculated[stat] = false
	end
	
	self.statChanged = Signal.new() -- creates a new instance
	
	return self
end

-- _ means it will be for each instance but shouldnt be used everywhere
function public:_recompute(stat: string): number?
	local total = self.base[stat]
	for source, amount in self.modifiers[stat] do
		total += amount
	end
	total = private.clamp(total, stat)

	local old = self.cache[stat]
	self.cache[stat] = total
	self.unCalculated[stat] = false

	if total ~= old then
		self.statChanged:Fire(stat, total, old)
	end

	return total
end

---- Data Change ----

-- temp change
function public:addModifier(stat: statName, source: string, amount: number)
	assert(self.modifiers[stat], "Unknown stat: " .. tostring(stat)) -- will stop the code
	self.modifiers[stat][source] = amount
	self.unCalculated[stat] = true
end

function public:removeModifier(stat: string, source: string)
	if self.modifiers[stat] then
		self.modifiers[stat][source] = nil
		self.unCalculated[stat] = true
	end
end

function public:listModifiers(stat: string): {}
	return self.modifiers[stat] or {}
end	

-- permanent change
function public:addToBaseData(stat: string, amount: number)
	assert(self.base[stat] ~= nil, "Unknown stat: " .. tostring(stat))
	self.base[stat] += amount
	self.unCalculated[stat] = true
end

---- calculations ----

-- calculates when happiness, reputation, etc. will drop
-- will run every few seconds
function public:calculateSideEffects()
	local safety = self:getStat("safetyRating")
	local contamination = self:getStat("contamination")
	local economy = self:getStat("economicStrength")
	local population = self:getStat("population")

	-- low safety lowers happiness
	if safety < 40 then
		self:addModifier("happiness", "low_safety_penalty", -(40 - safety) * 0.5)
	else
		self:removeModifier("happiness", "low_safety_penalty")
	end
	
	-- high contamination lowers safety
	if contamination > 30 then
		self:addModifier("safetyRating", "contamination_penalty", -(contamination - 30) * 0.4)
	else
		self:removeModifier("safetyRating", "contamination_penalty")
	end
	
	-- lower economic strength will lower population
	self:addModifier("economicStrength", "population_bonus", math.clamp(population / 200, 0, 15))

	-- economic strength influences trust slightly
	self:addModifier("governmentTrust", "economy_bonus", (economy - 50) * 0.1)
	
	-- water
	-- electricity
end

-- will generate income per few seconds
function public:calculatePassiveIncome(districtCount: number, baseIncome: number): number
	local population = self:getStat("population")
	local trust = self:getStat("governmentTrust")
	local safety = self:getStat("safetyRating")
	local economy = self:getStat("economicStrength")
	local happiness = self:getStat("happiness")

	local trustMultiplier = trust / 100
	local safetyMultiplier = safety / 100
	local economyMultiplier = economy / 100
	local happinessMultiplier = 0.5 + (happiness / 200) -- happiness matters less than trust and safety

	local districtMultiplier = math.max(districtCount, 1)
	local populationScale = math.clamp(population / 1000, 0.2, 5) -- highest population multiplier is x5 and lowest is x0.2

	local income = baseIncome * populationScale * trustMultiplier * safetyMultiplier * economyMultiplier * happinessMultiplier

	return math.floor(income)
end

---- Misc ----

function public:getStat(stat: statName): number
	assert(self.base[stat] ~= nil, "Unknown stat: " .. tostring(stat)) -- will stop the code
	if self.unCalculated[stat] then
		return self:_recompute(stat)
	end
	
	return self.cache[stat]
end

function public:getAllStats(): {}
	local current = {}
	for stat in pairs(self.base) do
		current[stat] = self:getStat(stat)
	end
	return current
end

function private.clamp(value: number, stat: statName): number?
	local range: {number} = STAT_RANGE[stat]
	if not range then
		return
	end
	
	return math.clamp(value, range[1], range[2])
end

function public:serialize()
	return {
		base = self.base,
		modifiers = self.modifiers,
	}
end

return public