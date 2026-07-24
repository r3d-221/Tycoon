local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ServerScriptService.Server.Modules
local HazardSpawnerService = require(Modules.City.HazardSpawnerService)
local HazardTaskData = require(Modules.Data.HazardTaskData)

local remotes = ReplicatedStorage.remotes
local HazardTaskCompleted = remotes.HazardTaskCompleted
local StartHazardTask = remotes.StartHazardTask

local public = {}
local private = {}
local pending = {}

local TIMEOUT_BUFFER = 10

function public.onStart()
	private.onHazardTaskCompleted()
end

function public.startTask(player: Player, hazard, incident)
	if pending[player] then
		return
	end

	local taskName = private.getRandomTask(incident.config.taskTypes)
	local taskConfig = HazardTaskData[taskName]
	local taskId = `hazardTask_{player}_{taskName}_{os.clock()}`

	pending[player] = {
		hazard = hazard,
		incident = incident,
		taskId = taskId,
		startedAt = os.clock(),
	}
	StartHazardTask:FireClient(player, taskName, taskId)

	-- if the event isnt completed in time, it will be cleared and needs to be completed again
	local timeoutDuration = taskConfig.duration + TIMEOUT_BUFFER
	task.delay(timeoutDuration, function()
		if pending[player] and pending[player].taskId == taskId then
			pending[player] = nil
		end
	end)
end

function private.onHazardTaskCompleted()
	HazardTaskCompleted.OnServerEvent:Connect(function(player: Player, taskId: string, success: boolean)
		print("[HazardTaskManager] recieved call from " .. player.Name .. " to clear the hazard")
		local list = pending[player]
		if not list or list.taskId ~= taskId then
			warn("list not found for: " .. player.Name)
			return
		end
		pending[player] = nil

		if success then
			list.incident:registerProgress(1, list.incident.config.completionType)
			HazardSpawnerService.removeHazard(list.incident.id, list.hazard)
			print("[HazardTaskManager] " .. taskId .. " was cleared by: " .. player.Name)
		end
	end)
end

function public.clearPlayer(player: Player)
	pending[player] = nil
end

function private.getRandomTask(tasks: {}): string
	if #tasks == 1 then
		return tasks[1]
	end

	return tasks[math.random(#tasks)]
end

return public
