local ServerScriptService = game:GetService("ServerScriptService")
local modules = ServerScriptService.Server.modules
local ThreatData = require(modules.data.ThreatData)

local public = {}
local private = {}

function public.getEnemyType(threatType: string): string?
	local config = ThreatData[threatType]
	if not config then
		return nil
	end
	return config.enemy
end

function public.pickLocation(hazard): CFrame
	local hazardPosition = hazard:IsA("Model") and hazard:GetPivot().Position or hazard.Position
	local angle = math.random() * math.pi * 2
	local offset = Vector3.new(math.cos(angle) * 4, 0, math.sin(angle) * 4)
	return CFrame.new(hazardPosition + offset)
end

return public
