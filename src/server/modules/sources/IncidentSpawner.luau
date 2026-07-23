local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.Server.modules
local PlotManager = require(modules.plot.PlotManager)
local DistrictData = require(modules.data.DistrictData)
local GeneralData = require(modules.data.GeneralData)

local public = {}
local private = {}

function public.pickDistrict(player): string?
	local owned = {}
	for districtId in pairs(DistrictData) do
		table.insert(owned, districtId)
	end
	if #owned == 0 then
		return nil
	end
	return owned[math.random(1, #owned)]
end

function public.selectThreatType(districtId: string): string?
	local districtInfo = DistrictData[districtId]
	if not districtInfo then
		warn("[Spawner] selectThreatType: no DistrictData for " .. districtId)
		return nil
	end
	local minIndex = GeneralData.rarityIndex[districtInfo.rarity.min]
	local maxIndex = GeneralData.rarityIndex[districtInfo.rarity.max]
	local eligibleWeights = {}
	local totalWeight = 0
	for rarity, weight in pairs(GeneralData.threatRarity) do
		local index = GeneralData.rarityIndex[rarity]
		local hasThreats = GeneralData.threatsList[rarity] and #GeneralData.threatsList[rarity] > 0
		if index >= minIndex and index <= maxIndex and hasThreats then
			eligibleWeights[rarity] = weight
			totalWeight += weight
		end
	end
	if totalWeight == 0 then
		warn("[Spawner] selectThreatType: totalWeight is 0 -- no eligible rarity had threats")
		return nil
	end
	local roll = math.random() * totalWeight
	local cumulative = 0
	local chosenRarity
	for rarity, weight in pairs(eligibleWeights) do
		cumulative += weight
		if roll <= cumulative then
			chosenRarity = rarity
			break
		end
	end
	local pool = GeneralData.threatsList[chosenRarity]
	return pool[math.random(1, #pool)]
end

function public.getThreatTypes(): { [string]: { string } }
	return GeneralData.threatsList
end

function public.pickLocation(player, districtId: string): BasePart?
	local plotFolder = PlotManager.getPlotFolder(player)
	if not plotFolder then
		warn("[Spawner] pickLocation: PlotManager.getPlotFolder returned nil for " .. player.Name)
		return nil
	end
	local districtsFolder = plotFolder:FindFirstChild("districts")
	if not districtsFolder then
		warn("[Spawner] pickLocation: no 'districts' folder under plotFolder")
		return nil
	end
	local districtFolder = districtsFolder:FindFirstChild(districtId)
	if not districtFolder then
		warn("[Spawner] pickLocation: no district folder named '" .. districtId .. "' under districts")
		return nil
	end
	local locationsFolder = districtFolder:FindFirstChild("locations")
	if not locationsFolder then
		warn("[Spawner] pickLocation: no 'locations' folder for district: " .. districtId)
		return nil
	end
	local markers = locationsFolder:GetChildren()
	if #markers == 0 then
		return nil
	end
	return markers[math.random(1, #markers)]
end

return public
