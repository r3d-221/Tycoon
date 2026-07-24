local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Modules = ServerScriptService.Server.Modules
local PlotService = require(Modules.Plot.PlotService)

local ProximityPromptService = require(Modules.Player.ProximityPromptService)
local ToolService = require(Modules.Player.ToolService)
local CityStateService = require(Modules.City.CityStateService)
local HazardTaskService = require(Modules.City.HazardTaskService)
local IncidentService = require(Modules.Sources.IncidentService)

local public = {}
local private = {}
local sessions = {}
local spawnLoops = {}

local SPAWN_CHECK_INTERVAL = 15

local data = {
	population = 500,
	happiness = 60,
	governmentTrust = 50,
	safetyRating = 40,
	economicStrength = 50,
	contamination = 0,
}

function public.onStart()
	private.onPlayerAdded()
	private.onPlayerRemoved()
	ProximityPromptService.onStart()
	HazardTaskService.onStart()
end

function private.onPlayerAdded()
	Players.PlayerAdded:Connect(function(player)
		--print("[PlotService] Setting plot for: " .. player.Name)
		PlotService.onStart(player)
		sessions[player] = CityStateService.new(data)

		sessions[player].statChanged:Connect(function(stat, newValue, oldValue)
			print(`{stat} changed from {oldValue} to {newValue}`)
		end)

		-- tool equiping
		ToolService.grant(player, "vacummCleaner")
		ToolService.equip(player, "vacummCleaner")
		--task.delay(5, function()
		--	ToolService.unequip(player)
		--end)

		spawnLoops[player] = task.spawn(function()
			print("[SessionManager] spawn loop tick for:", player.Name)
			while sessions[player] do
				task.wait(SPAWN_CHECK_INTERVAL)
				if sessions[player] then
					local incident = IncidentService.trySpawn(player, sessions[player])
					print("[SessionManager] result:", incident)
				end
			end
		end)
	end)
end

function private.onPlayerRemoved()
	Players.PlayerRemoving:Connect(function(player)
		local plotFolder = PlotService.getPlotFolder(player)
		if plotFolder then
			PlotService.clearPlot(plotFolder)
		end

		IncidentService.clearPlayer(player)
		HazardTaskService.clearPlayer(player)

		if spawnLoops[player] then
			task.cancel(spawnLoops[player])
			spawnLoops[player] = nil
		end

		sessions[player] = nil
	end)
end

return public
