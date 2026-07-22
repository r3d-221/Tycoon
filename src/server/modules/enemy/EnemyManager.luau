local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local modules = ServerScriptService.modules
local EnemySpawner = require(modules.enemy.EnemySpawner)
local Enemy = require(modules.enemy.Enemy)

type State = Enemy.State

local enemies = Workspace.enemies
local enemyTemplates = ReplicatedStorage.enemies

local public = {}
local private = {}
local byHazard = {}
local byIncident = {}

function public.spawn(incident, hazards: {Instance})
	local enemyType = EnemySpawner.getEnemyType(incident.threatType)
	if not enemyType then
		return
	end

	local template = enemyTemplates:FindFirstChild(enemyType)
	if not template then
		warn("[EnemyManager] no enemy template for: " .. enemyType)
		return
	end

	byIncident[incident.id] = byIncident[incident.id] or {}

	for _, hazard in hazards do
		if byHazard[hazard] then
			continue
		end

		local model = template:Clone()
		model:PivotTo(EnemySpawner.pickLocation(hazard))
		model.Parent = enemies

		local enemy = Enemy.new(incident.player, model, hazard)
		byHazard[hazard] = enemy
		byIncident[incident.id][hazard] = true

		enemy.stateChanged:Connect(function(newState: State)
			if newState == "destroyed" then
				private.untrack(incident.id, hazard)
			end
		end)
	end
end

function public.killBatch(hazard: Instance)
	local enemy = byHazard[hazard]
	if not enemy then
		return
	end
	if enemy:getState() ~= "dead" then
		enemy.humanoid.Health = 0
	end
end

function public.clearBatch(incidentId: string)
	local hazards = byIncident[incidentId]
	if not hazards then
		return
	end
	for hazard in pairs(hazards) do
		local enemy = byHazard[hazard]
		if enemy and enemy:getState() ~= "dead" then
			enemy:destroy()
		end
	end
	byIncident[incidentId] = nil
end

function public.getEnemyByHazard(hazard: Instance)
	return byHazard[hazard]
end

function public.getActive(incidentId: string): {any}
	local hazards = byIncident[incidentId]
	if not hazards then
		return {}
	end
	local list = {}
	for hazard in pairs(hazards) do
		table.insert(list, byHazard[hazard])
	end
	return list
end

function private.untrack(incidentId: string, hazard: Instance)
	byHazard[hazard] = nil
	if byIncident[incidentId] then
		byIncident[incidentId][hazard] = nil
	end
end

return public