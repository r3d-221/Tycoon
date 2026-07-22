local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local Incident = require(modules.sources.Incident)
local DistrictData = require(modules.data.DistrictData)
local HazardSpawner = require(modules.city.HazardSpawner)
local SecuringManager = require(modules.city.SecuringManager)
local IncidentSpawner = require(modules.sources.IncidentSpawner)
local EnemyManager = require(modules.enemy.EnemyManager)

local public = {}
local private = {}
local incidents = {}
local incidentsById = {}
local cooldowns = {}
local MAX_INCIDENTS = 4
type State = Incident.State

function public.trySpawn(player: Player, cityState: {})
	local districtId = IncidentSpawner.pickDistrict(player)
	if not districtId then
		return nil
	end

	if not public.canSpawn(player, districtId) then
		return nil
	end

	local threatType = IncidentSpawner.selectThreatType(districtId)
	if not threatType then
		warn("[Manager] trySpawn: no eligible threat type for district: " .. districtId)
		return nil
	end

	local location = IncidentSpawner.pickLocation(player, districtId)
	if not location then
		warn("[Manager] trySpawn: no location for district: " .. districtId)
		return nil
	end

	return public.spawn(player, threatType, districtId, cityState, location)
end

function public.spawn(player: Player, threatType: string, districtId: string, cityState: {}, location: Vector3)
	if not public.canSpawn(player, districtId) then
		print("[Manager] spawn: canSpawn -> false, aborting construction")
		return nil
	end

	incidents[player] = incidents[player] or {}
	cooldowns[player] = cooldowns[player] or {}
	cooldowns[player][districtId] = os.clock()

	local incident = Incident.new(player, threatType, districtId, cityState, location)
	incidents[player][incident.id] = incident
	incidentsById[incident.id] = incident

	-- TEMP
	task.delay(4, function()
		if incident:getState() == "hidden" then
			incident:onDetected()
		end
	end)

	incident.stateChanged:Connect(function(newState: State)
		if newState == "active" then
			local hazards = HazardSpawner.spawn(incident)
			EnemyManager.spawn(incident, hazards)
		elseif newState == "escalated" then
			local hazard = HazardSpawner.spawnEscalation(incident)
			incident.progressTarget += 1
			if hazard then
				EnemyManager.spawn(incident, {hazard})
			end
		elseif newState == "cleared" or newState == "destroyed" then
			HazardSpawner.clearHazards(incident.id)
			SecuringManager.clearIncident(incident.id)
			EnemyManager.clearBatch(incident.id)
			private.untrack(player, incident.id)
		end
	end)

	return incident
end

function public.canSpawn(player: Player, districtId: string): boolean
	local activeCount = public.getActiveCount(player)
	if activeCount >= MAX_INCIDENTS then
		return false
	end

	local districtInfo = DistrictData[districtId]
	if not districtInfo then
		warn("[Manager] canSpawn: no DistrictData for " .. tostring(districtId))
		return false
	end

	local playerCooldowns = cooldowns[player]
	if not playerCooldowns or not playerCooldowns[districtId] then
		return true
	end

	local elapsed = os.clock() - playerCooldowns[districtId]
	return elapsed >= districtInfo.incidentCooldown
end

function public.getActiveIncidents(player: Player): {[string]: any}
	return incidents[player] or {}
end

function public.getActiveCount(player: Player): number
	local playerIncidents = incidents[player]
	if not playerIncidents then
		return 0
	end
	local count = 0
	for _ in pairs(playerIncidents) do
		count += 1
	end
	return count
end

function public.getIncidentById(incidentId: string)
	return incidentsById[incidentId]
end

function public.clearPlayer(player: Player)
	local playerIncidents = incidents[player]
	if playerIncidents then
		for _, incident in pairs(playerIncidents) do
			local state = incident:getState()
			if state ~= "cleared" and state ~= "failed" then
				local ok, err = pcall(function()
					incident:onFailed()
				end)
				if not ok then
					warn("Error failing incident on cleanup: " .. tostring(err))
				end
			end
			incident:destroy()
		end
	end
	incidents[player] = nil
	cooldowns[player] = nil
end

function private.untrack(player: Player, incidentId: string)
	if incidents[player] then
		incidents[player][incidentId] = nil
	end
	incidentsById[incidentId] = nil
end

return public