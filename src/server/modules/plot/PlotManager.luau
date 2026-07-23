local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PLOT_TAG = "Plot"
local ITEMS_FOLDER_NAME = "items"
local DISTRICTS_FOLDER_NAME = "districts"
local REPLACEABLE_FOLDER_NAME = "replaceable"
local RESPAWN_TIMER = 2
local PLOT_ID = "playerId"

local templatePlotFolder = ReplicatedStorage:FindFirstChild("plot_template")
local templatePlotItems = templatePlotFolder.items
local templateDistrictsFolder = templatePlotFolder.districts

local PlotModelData = require(ServerScriptService.Server.modules.data.PlotModelData)

local public = {}
local private = {}

---- EXAMPLE TABLES FOR THE DATA ----

data = {
	items = {
		part1 = true,
		part2 = false,
	},

	districts = {
		starter = {
			replaceable = {
				build2 = true,
			},
		},
		left = {
			replaceable = {},
		},
	},
}

function public.onStart(player: Player)
	private.assignPlot(player)
end

-- finds the assigned plot of the player
function public.getPlotFolder(player: Player): Instance?
	for _, plot in CollectionService:GetTagged(PLOT_TAG) do
		local plotId = plot:GetAttribute(PLOT_ID)
		if plotId == player.UserId then
			return plot.Parent
		end
	end
	return nil
end

-- creates an item
function public.createItem(model: Model | BasePart, folder: Folder)
	local itemFolder = folder:FindFirstChild(ITEMS_FOLDER_NAME)
	local plot = folder:WaitForChild("plot", 5)
	if not plot then
		warn("plot part never appeared under " .. folder:GetFullName())
		return
	end
	local plotCFrame = plot:GetPivot()
	local templateCFrame = templatePlotFolder.plot.CFrame

	local modelCFrame
	if model:IsA("Model") then
		modelCFrame = model:GetPivot()
	else
		modelCFrame = model.CFrame
	end

	local relativeCFrame = templateCFrame:ToObjectSpace(modelCFrame)
	local worldCFrame = plotCFrame:ToWorldSpace(relativeCFrame)

	local newModel = model:Clone()

	if newModel:IsA("Model") then
		newModel:PivotTo(worldCFrame)
	else
		newModel.CFrame = worldCFrame
	end

	newModel.Parent = itemFolder
end

function public.createDistrictItem(model: Model | BasePart, folder: Folder, districtName: string)
	local districtsFolder = folder:FindFirstChild(DISTRICTS_FOLDER_NAME)
	local districtFolder = districtsFolder:WaitForChild(districtName, 5)
	if not districtsFolder then
		warn("District folder not found for: " .. folder:GetFullName())
		return
	end
	local districtCFrame = districtFolder.area:GetPivot()
	local templateDistrict = templateDistrictsFolder:FindFirstChild(districtName)
	local templateCFrame = templateDistrict.area.CFrame

	local modelCFrame
	if model:IsA("Model") then
		modelCFrame = model:GetPivot()
	else
		modelCFrame = model.CFrame
	end

	local relativeCFrame = templateCFrame:ToObjectSpace(modelCFrame)
	local worldCFrame = districtCFrame:ToWorldSpace(relativeCFrame)

	local newModel = model:Clone()

	if newModel:IsA("Model") then
		newModel:PivotTo(worldCFrame)
	else
		newModel.CFrame = worldCFrame
	end

	newModel.Parent = districtFolder:FindFirstChild(REPLACEABLE_FOLDER_NAME)
	CollectionService:AddTag(newModel, "Replaceable")
end

-- clears the plot on player leave
function public.clearPlot(folder: Folder)
	local plot = folder:FindFirstChild("plot")
	local itemFolder = folder:FindFirstChild(ITEMS_FOLDER_NAME)
	local districtsFolder = folder:FindFirstChild(DISTRICTS_FOLDER_NAME)

	private.clearItems(itemFolder)

	if districtsFolder then
		for _, districtFolder in districtsFolder:GetChildren() do
			local replaceableFolder = districtFolder:FindFirstChild(REPLACEABLE_FOLDER_NAME)
			private.clearReplaceableItems(replaceableFolder)
		end
	end

	plot:SetAttribute(PLOT_ID, nil)
end

-- set the spawn of the player on the plot
function private.setSpawn(player: Player, folder: Folder)
	local spawnPart = folder:FindFirstChild("spawn_part")

	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
		humanoidRootPart.CFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)

		if humanoid then
			humanoid.Died:Connect(function()
				task.wait(RESPAWN_TIMER)
				player:LoadCharacterAsync()
			end)
		end
	end)

	player:LoadCharacterAsync()
end

-- loads all items for the plot
function private.loadItems(player: Player, folder: Folder)
	local itemFolder = folder:FindFirstChild(ITEMS_FOLDER_NAME)
	if not itemFolder then
		itemFolder = Instance.new("Folder")
		itemFolder.Parent = folder
		itemFolder.Name = ITEMS_FOLDER_NAME
	end

	private.clearItems(itemFolder)

	for id, obtained in pairs(data.items) do
		if not obtained then
			continue
		end

		local item = PlotModelData[id]
		item.onPurchase(player)

		local model = templatePlotItems:FindFirstChild(id)
		if model then
			public.createItem(model, folder)
		else
			warn("Couldn't find " .. id .. " in template")
		end
	end
end

function private.positionDistrict(newDistrict: Folder, templateDistrict: Folder, folder: Folder)
	local plot = folder:FindFirstChild("plot")
	local plotCFrame = plot:GetPivot()
	local templatePlotCFrame = templatePlotFolder.plot.CFrame

	local area = templateDistrict:FindFirstChild("area")
	local templateAreaCFrame = area.CFrame
	local relativeCFrame = templatePlotCFrame:ToObjectSpace(templateAreaCFrame)
	local targetAreaCFrame = plotCFrame:ToWorldSpace(relativeCFrame)

	local mewArea = newDistrict:FindFirstChild("area")
	local currentAreaCFrame = mewArea.CFrame
	local delta = targetAreaCFrame * currentAreaCFrame:Inverse()

	for _, descendant in newDistrict:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CFrame = delta * descendant.CFrame
		end
	end

	mewArea.CFrame = delta * currentAreaCFrame
end

function private.loadDistricts(folder: Folder)
	local districtsFolder = folder:FindFirstChild(DISTRICTS_FOLDER_NAME)
	if not districtsFolder then
		districtsFolder = Instance.new("Folder")
		districtsFolder.Parent = folder
		districtsFolder.Name = DISTRICTS_FOLDER_NAME
	end

	for district, info in pairs(data.districts) do
		local templateDistrict = templateDistrictsFolder:FindFirstChild(district)

		if templateDistrict and district == templateDistrict.Name then
			local districtFolder = districtsFolder:FindFirstChild(district)

			if not districtFolder then
				districtFolder = private.createDistrict(templateDistrict, folder)
			end

			for id, obtained in pairs(info.replaceable) do
				if obtained then
					local districtItem = templateDistrict:FindFirstChild(REPLACEABLE_FOLDER_NAME):FindFirstChild(id)
					if districtItem then
						public.createDistrictItem(districtItem, folder, district)
					else
						warn("Couldn't find " .. id .. " for " .. district .. " district")
					end
				end
			end
		else
			warn("No folder found for the name: " .. district)
		end
	end
end

function private.createDistrict(templateDistrict: Folder, folder: Folder): Folder
	local districtsFolder = folder:FindFirstChild(DISTRICTS_FOLDER_NAME)

	local newDistrict = templateDistrict:Clone()
	private.positionDistrict(newDistrict, templateDistrict, folder)

	local replaceableFolder = newDistrict:FindFirstChild(REPLACEABLE_FOLDER_NAME)
	if replaceableFolder then
		replaceableFolder:ClearAllChildren()
	end

	newDistrict.Parent = districtsFolder
	return newDistrict
end

-- assigns a plot to the player
function private.assignPlot(player: Player)
	for _, plot in CollectionService:GetTagged(PLOT_TAG) do
		local id = plot:GetAttribute(PLOT_ID)
		if id then
			--print("[PlotManager] Plot booked. Looking for another one for: " .. player.Name) -- debug
			continue
		else
			--print("[PlotManager] Found a plot for: " .. player.Name) -- debug
			plot:SetAttribute(PLOT_ID, player.UserId)
			local plotFolder = plot.Parent
			plotFolder.Name = player.Name

			private.setSpawn(player, plotFolder)
			private.loadItems(player, plotFolder)
			private.loadDistricts(plotFolder)
			break
		end
	end
end

-- clears all items on the plot
function private.clearItems(itemFolder: Folder)
	if not itemFolder then
		return
	end
	for _, item in itemFolder:GetChildren() do
		if item:IsA("Model") then
			item:Destroy()
		end
	end
end

function private.clearReplaceableItems(replaceableFolder: Folder)
	if not replaceableFolder then
		return
	end
	for _, item in replaceableFolder:GetChildren() do
		item:Destroy()
	end
end

return public
