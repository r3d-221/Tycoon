local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ServerScriptService.Server.Modules
local ThreatData = require(Modules.Data.ThreatData)
local Signal = require(Modules.Signal)

local public = {}
local private = {}
public.__index = public

local TICK = 1
local DRAIN_TICK = 2
local ESCALATION_TICK = 10

---- Info ----
-- Passive drain -> Increases the contamination and lowers population. Increases in serverity overtime
-- Escaltion -> After a timer, makes the threat harder to clear
-- Unresolved -> If the threat is completely ignored, it will do damage and eventually count as a fail and expire
-- Completed -> Player gets rewards if completed in time
-- Expired -> On failed or unresolved, the threat gets removed

export type State = "hidden" | "detected" | "active" | "cleared" | "failed" | "destroyed" | "escalated"

function private.safeCancel(thread)
	if thread and thread ~= coroutine.running() then
		task.cancel(thread)
	end
end

function public.new(player: Player, threatType: string, districtId: string, cityState: {}, locationMarker: BasePart)
	local self = setmetatable({}, public)

	local config = ThreatData[threatType]

	self.player = player
	self.threatType = threatType
	self.districtId = districtId
	self.config = config
	self.cityState = cityState
	self.locationMarker = locationMarker
	self.location = locationMarker.Position

	self.state = "hidden" :: State
	self.id = `incident_{districtId}_{threatType}_{os.clock()}`
	self.sourceId = `district{districtId}_{threatType}_{self.id}`

	self.progress = 0
	self.progressTarget = config.hazardCount

	self.drainSeverity = 0

	self.timers = {
		unresolved = nil,
		completion = nil,
		threat = nil,
	}

	self.connections = {}
	self.stateEnteredAt = {}

	self.stateChanged = Signal.new()

	self:_setIncident()

	return self
end

function public:_setIncident()
	self:onHidden()
end

---- States ----

function public:onHidden()
	self.state = "hidden"
	self.stateEnteredAt.hidden = os.clock()
	self.stateChanged:Fire("hidden")

	self.connections.drain = task.spawn(function()
		while not self._destroyed and (self.state == "hidden" or self.state == "detected") do
			self:tickPassiveDrain()
			task.wait(DRAIN_TICK)
		end
	end)

	self.connections.escalation = task.spawn(function()
		while not self._destroyed and (self.state == "hidden" or self.state == "detected") do
			self:tickEscalation()
			task.wait(ESCALATION_TICK)
		end
	end)

	self.timers.unresolved = task.delay(self.config.unresolvedTime, function()
		if self.state == "hidden" or self.state == "detected" then
			self:onUnresolved()
		end
	end)

	-- code for detection system will go here
end

function public:onDetected()
	self.state = "detected"
	self.stateEnteredAt.detected = os.clock()
	self.stateChanged:Fire("detected")

	self.connections.rangeCheck = task.spawn(function()
		while not self._destroyed and self.state == "detected" do
			if self:_isPlayerInRange() then
				self:onActive()
				break
			end
			task.wait(TICK)
		end
	end)
end

function public:onActive()
	if self.timers.unresolved then
		private.safeCancel(self.timers.unresolved)
		self.timers.unresolved = nil
	end

	self.connections.rangeCheck = nil

	self.state = "active"
	self.stateEnteredAt.active = os.clock()
	self.stateChanged:Fire("active")

	self.timers.completion = task.delay(self.config.completionTime, function()
		if self.state == "active" then
			self:onCompletionExpired()
		end
	end)
end

function public:onCleared()
	if self.timers.completion then
		private.safeCancel(self.timers.completion)
		self.timers.completion = nil
	end

	self.state = "cleared"
	self.stateEnteredAt.cleared = os.clock()
	self.stateChanged:Fire("cleared")

	local elapsed = self:getElapsedTime("active")
	local rating = self.wasFailed and "F" or self:_calculateRating(elapsed)

	self:destroy()
end

function private.applyFailureEffects(self)
	self.state = "failed"
	self.stateEnteredAt.failed = os.clock()
	self.stateChanged:Fire("failed")

	self.cityState:addToBaseData("economicStrength", -self.config.failDamage * 0.1)
	self.cityState:addToBaseData("safetyRating", -self.config.failDamage * 0.2)
end

---- Timers ----

function public:onUnresolved()
	private.applyFailureEffects(self)

	self.timers.threat = task.delay(self.config.threatDuration or 300, function()
		self:onThreatExpired()
	end)
end

function public:onCompletionExpired()
	self.wasFailed = true
	private.applyFailureEffects(self)
end

function public:onFailed()
	self:onUnresolved()
end

function public:onThreatExpired()
	self:destroy()
end

---- Ticks ----

function public:tickPassiveDrain()
	self.drainSeverity += 1

	local contamination = (self.config.contaminationOnSpawn or 0) * 0.1 * self.drainSeverity
	local safety = (self.config.safetyOnSpawn or 0) * 0.1 * self.drainSeverity

	self.cityState:addModifier("contamination", self.sourceId .. "_drain", contamination)
	self.cityState:addModifier("safetyRating", self.sourceId .. "_drain", safety)
	self.cityState:addModifier("population", self.sourceId .. "_drain", -self.drainSeverity * 2)
end

function public:tickEscalation()
	if self.hasEscalated then
		return
	end

	local elapsed = os.clock() - self.stateEnteredAt.hidden
	if elapsed >= (self.config.escalationDelay or 60) then
		self.hasEscalated = true
		self.stateChanged:Fire("escalated")
	end
end

---- Progress ----

function public:registerProgress(amount: number, actionType: string)
	if actionType ~= self.config.completionType then
		return
	end
	if self.state ~= "active" and self.state ~= "failed" then
		return
	end

	self.progress = math.min(self.progress + amount, self.progressTarget)
	self.stateChanged:Fire("progress", self.progress, self.progressTarget)

	if self.progress >= self.progressTarget then
		self:onCleared()
	end
end

function public:getRemainingProgress(): number
	return self.progressTarget - self.progress
end

---- Getters ----

function public:getState(): State
	return self.state
end

function public:getElapsedTime(stateName: string): number
	local enteredAt = self.stateEnteredAt[stateName]
	if not enteredAt then
		return 0
	end
	return os.clock() - enteredAt
end

function public:getThreatLocation(): Vector3?
	return self.location
end

---- Misc ----

function private.calculateRating(config, elapsed: number): string
	local thresholds = config.ratingThresholds
	if elapsed <= thresholds.S then
		return "S"
	elseif elapsed <= thresholds.A then
		return "A"
	elseif elapsed <= thresholds.B then
		return "B"
	elseif elapsed <= thresholds.C then
		return "C"
	end
	return "F"
end

function public:_calculateRating(elapsed: number): string
	return private.calculateRating(self.config, elapsed)
end

function public:destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true

	for _, timer in pairs(self.timers) do
		private.safeCancel(timer)
	end

	self.cityState:removeModifier("contamination", self.sourceId .. "_drain")
	self.cityState:removeModifier("safetyRating", self.sourceId .. "_drain")
	self.cityState:removeModifier("population", self.sourceId .. "_drain")

	self.stateChanged:Fire("destroyed")
end

function public:_isPlayerInRange(): boolean
	if not self.location then
		return false
	end

	local character = self.player.Character
	if not character or not character.PrimaryPart then
		return false
	end

	local distance = (character.PrimaryPart.Position - self.location).Magnitude
	return distance <= (self.config.rangeRadius or 15)
end

return public
