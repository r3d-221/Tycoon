local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local modules = ServerScriptService.Server.modules
local PlotManager = require(modules.plot.PlotManager)

local ProximityPromptManager = require(modules.player.ProximityPromptManager)
local ToolManager = require(modules.player.ToolManager)
local CityStateManager = require(modules.city.CityStateManager)
local HazardTaskManager = require(modules.city.HazardTaskManager)
local IncidentManager = require(modules.sources.IncidentManager)

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
	ProximityPromptManager.onStart()
	HazardTaskManager.onStart()
end

function private.onPlayerAdded()
	Players.PlayerAdded:Connect(function(player)
		--print("[PlotManager] Setting plot for: " .. player.Name)
		PlotManager.onStart(player)
		sessions[player] = CityStateManager.new(data)

		sessions[player].statChanged:Connect(function(stat, newValue, oldValue)
			print(`{stat} changed from {oldValue} to {newValue}`)
		end)

		-- tool equiping
		ToolManager.grant(player, "vacummCleaner")
		ToolManager.equip(player, "vacummCleaner")
		--task.delay(5, function()
		--	ToolManager.unequip(player)
		--end)

		spawnLoops[player] = task.spawn(function()
			print("[SessionManager] spawn loop tick for:", player.Name)
			while sessions[player] do
				task.wait(SPAWN_CHECK_INTERVAL)
				if sessions[player] then
					local incident = IncidentManager.trySpawn(player, sessions[player])
					print("[SessionManager] result:", incident)
				end
			end
		end)
	end)
end

function private.onPlayerRemoved()
	Players.PlayerRemoving:Connect(function(player)
		local plotFolder = PlotManager.getPlotFolder(player)
		if plotFolder then
			PlotManager.clearPlot(plotFolder)
		end

		IncidentManager.clearPlayer(player)
		HazardTaskManager.clearPlayer(player)

		if spawnLoops[player] then
			task.cancel(spawnLoops[player])
			spawnLoops[player] = nil
		end

		sessions[player] = nil
	end)
end

return public
