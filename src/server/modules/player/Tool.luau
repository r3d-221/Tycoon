local ServerScriptService = game:GetService("ServerScriptService")

local Signal = require(ServerScriptService.Server.modules.Signal)

local public = {}
local private = {}
public.__index = public

export type ToolState = "idle" | "using" | "cooldown" | "reloading"

function public.new(player: Player, toolName: string, config)
	local self = setmetatable({}, public)

	self.player = player
	self.toolName = toolName
	self.config = config

	self.state = "idle" :: ToolState
	self.battery = config.stats.capacity

	self.stateChanged = Signal.new()

	return self
end

function public:getState(): ToolState
	return self.state
end

function public:work(): boolean
	if self.state ~= "idle" then
		return false
	end

	if self.battery <= 0 then
		self:onReloading()
		return false
	end

	self:onUsing()
	return true
end

function public:onIdle()
	self.state = "idle"
	self.stateChanged:Fire("idle")
end

function public:onUsing()
	self.state = "using"
	self.stateChanged:Fire("using")

	self.battery = math.max(0, self.battery - 1) -- battery draining

	task.delay(self.config.stats.speed, function()
		if self.state == "using" then
			self:onCooldown()
		end
	end)
end

function public:onCooldown()
	self.state = "cooldown"
	self.stateChanged:Fire("cooldown")

	task.delay(self.config.stats.cooldown, function()
		if self.state ~= "cooldown" then
			return
		end
		if self.battery <= 0 then
			self:onReloading()
		else
			self:onIdle()
		end
	end)
end

function public:onReloading()
	self.state = "reloading"
	self.stateChanged:Fire("reloading")

	-- temp
	local rechargeTime = self.config.stats.capacity * self.config.stats.chargeRate
	task.delay(rechargeTime, function()
		if self.state == "reloading" then
			self.battery = self.config.stats.capacity
			self:onIdle()
		end
	end)
end

function public:destroy()
	self.stateChanged:Fire("destroyed")
end

return public
