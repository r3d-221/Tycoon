local ProximityPromptService = game:GetService("ProximityPromptService")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ServerScriptService.Server.Modules
local IncidentService = require(Modules.Sources.IncidentService)
local ToolService = require(Modules.Player.ToolService)
local SecuringService = require(Modules.City.SecuringService)
local HazardTaskService = require(Modules.City.HazardTaskService)

local public = {}
local private = {}

function public.onStart()
	ProximityPromptService.PromptTriggered:Connect(private.onPromptTriggered)
end

function private.onPromptTriggered(prompt: ProximityPrompt, player: Player)
	local hazard = private.findHazardAncestor(prompt)
	if not hazard then
		return
	end

	local incidentId = hazard:GetAttribute("incidentId")
	local incident = IncidentService.getIncidentById(incidentId)
	if not incident then
		warn("[HazardInteraction] no incident found for id: " .. incidentId)
		return
	end

	if incident.player ~= player then
		return
	end

	if not SecuringService.isSecured(incident) then
		warn("[ProximityPromptManager] " .. player.Name .. " hasn't secured the surrounding area")
		return
	end

	local toolInstance = ToolService.getEquipped(player)
	if not toolInstance then
		return
	end

	if toolInstance.config.workType ~= incident.config.completionType then
		return
	end

	local accepted = ToolService.work(player)
	if not accepted then
		return
	end

	HazardTaskService.startTask(player, hazard, incident)
end

function private.findHazardAncestor(instance: Instance): Instance?
	local current = instance
	while current do
		if current:GetAttribute("incidentId") then
			return current
		end
		current = current.Parent
	end
	return nil
end

return public
