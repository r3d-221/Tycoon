local ProximityPromptService = game:GetService("ProximityPromptService")
local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.Server.modules
local IncidentManager = require(modules.sources.IncidentManager)
local ToolManager = require(modules.player.ToolManager)
local SecuringManager = require(modules.city.SecuringManager)
local HazardTaskManager = require(modules.city.HazardTaskManager)

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
	local incident = IncidentManager.getIncidentById(incidentId)
	if not incident then
		warn("[HazardInteraction] no incident found for id: " .. incidentId)
		return
	end

	if incident.player ~= player then
		return
	end

	if not SecuringManager.isSecured(incident) then
		warn("[ProximityPromptManager] " .. player.Name .. " hasn't secured the surrounding area")
		return
	end

	local toolInstance = ToolManager.getEquipped(player)
	if not toolInstance then
		return
	end

	if toolInstance.config.workType ~= incident.config.completionType then
		return
	end

	local accepted = ToolManager.work(player)
	if not accepted then
		return
	end

	HazardTaskManager.startTask(player, hazard, incident)
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
