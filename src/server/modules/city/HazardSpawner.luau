local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local HAZARD_TAG = "Hazard"
local HAZARD_SPREAD_RADIUS = 15
local MAX_PLACEMENT_ATTEMPTS = 12
local GROUND_RAY_HEIGHT = 50

local modules = ServerScriptService.modules
local hazardTemplate = ReplicatedStorage.hazard_template
local escalationTemplate = ReplicatedStorage.escalation_template
local EnemyManager = require(modules.enemy.EnemyManager)

local public = {}
local private = {}

local active = {}
local usedSpotIndex = {}

function public.spawn(incident)
	local threatType = incident.threatType
	local template = hazardTemplate and hazardTemplate:FindFirstChild(threatType)
	if not template then
		warn("No hazard template found for: " .. threatType)
		return
	end

	print("[HazardSpawner] spawning hazard for: " .. incident.threatType)
	active[incident.id] = active[incident.id] or {}

	for i = 1, incident.config.hazardCount do
		local hazard = private.createHazard(template, incident, i)
		table.insert(active[incident.id], hazard)
	end

	return active[incident.id]
end

function public.spawnEscalation(incident)
	local threatType = incident.threatType
	local template = escalationTemplate and escalationTemplate:FindFirstChild(threatType)
	if not template then
		warn("No escalation template found for: " .. threatType)
		return
	end

	print("[HazardSpawner] spawning escalation hazard for: " .. incident.threatType)
	active[incident.id] = active[incident.id] or {}
	local index = #active[incident.id] + 1
	local hazard = private.createHazard(template, incident, index)
	table.insert(active[incident.id], hazard)
	return hazard
end
function public.addHazard(incident)
	local threatType = incident.threatType
	local template = hazardTemplate and hazardTemplate:FindFirstChild(threatType)
	if not template then
		warn("No hazard template found for: " .. threatType)
		return
	end

	active[incident.id] = active[incident.id] or {}
	local index = #active[incident.id] + 1
	local hazard = private.createHazard(template, incident, index)
	table.insert(active[incident.id], hazard)
	return hazard
end

function public.getHazards(incidentId: string): { Instance }
	return active[incidentId] or {}
end

function public.removeHazard(incidentId: string, hazard: Instance)
	local list = active[incidentId]
	if not list then
		return
	end
	for i, h in ipairs(list) do
		if h == hazard then
			table.remove(list, i)
			break
		end
	end
	EnemyManager.killBatch(hazard)
	hazard:Destroy()
end

function public.clearHazards(incidentId: string)
	local list = active[incidentId]
	if not list then
		return
	end
	for _, hazard in ipairs(list) do
		if hazard.Parent then
			hazard:Destroy()
		end
	end
	active[incidentId] = nil
	usedSpotIndex[incidentId] = nil
end

function private.createHazard(template: Instance, incident, index: number): Instance
	local hazard = template:Clone()

	local position = private.getPredefinedSpot(incident)
	local usedFallback = false

	if not position then
		usedFallback = true
		local size = private.getSize(hazard)
		local found
		position, found = private.findValidPosition(incident, size)
		if not found then
			warn(
				"[HazardSpawner] no clear spot found for hazard "
					.. index
					.. " of "
					.. incident.id
					.. " -- placing anyway"
			)
		end
	end

	local primaryPart
	if hazard:IsA("Model") then
		primaryPart = hazard.PrimaryPart or hazard:FindFirstChildWhichIsA("BasePart", true)
		hazard:PivotTo(CFrame.new(position))
	else
		primaryPart = hazard
		hazard.CFrame = CFrame.new(position)
	end

	hazard:SetAttribute("incidentId", incident.id)
	hazard:SetAttribute("hazardIndex", index)
	hazard:SetAttribute("cleared", false)
	CollectionService:AddTag(hazard, HAZARD_TAG)

	if primaryPart then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Clear"
		prompt.ObjectText = incident.threatType
		prompt.HoldDuration = 1
		prompt.MaxActivationDistance = 10
		prompt.Enabled = true
		prompt.Parent = primaryPart
	else
		warn("Hazard template for " .. incident.threatType .. " has no BasePart to attach a prompt to")
	end

	hazard.Parent = Workspace.hazards

	return hazard
end

function private.getPredefinedSpot(incident): Vector3?
	local marker = incident.locationMarker
	if not marker then
		return nil
	end

	local spotsFolder = marker:FindFirstChild("hazardSpots")
	if not spotsFolder then
		return nil
	end

	if not private.shuffledSpots then
		private.shuffledSpots = {}
	end
	if not private.shuffledSpots[incident.id] then
		local spots = spotsFolder:GetChildren()
		for i = #spots, 2, -1 do
			local j = math.random(i)
			spots[i], spots[j] = spots[j], spots[i]
		end
		private.shuffledSpots[incident.id] = spots
	end

	local spots = private.shuffledSpots[incident.id]
	local nextIndex = (usedSpotIndex[incident.id] or 0) + 1

	if nextIndex > #spots then
		return nil
	end

	usedSpotIndex[incident.id] = nextIndex
	return spots[nextIndex].Position
end

function private.getSize(instance: Instance): Vector3
	if instance:IsA("Model") then
		local _, size = instance:GetBoundingBox()
		return size
	elseif instance:IsA("BasePart") then
		return instance.Size
	end
	return Vector3.new(2, 2, 2)
end

function private.findValidPosition(incident, size: Vector3): (Vector3, boolean)
	for _ = 1, MAX_PLACEMENT_ATTEMPTS do
		local offset = private.randomOffset(HAZARD_SPREAD_RADIUS)
		local candidateXZ = incident.location + offset

		local groundPosition = private.raycastGround(candidateXZ)
		if groundPosition then
			local checkPosition = groundPosition + Vector3.new(0, size.Y / 2, 0)
			if not private.isObstructed(checkPosition, size) then
				return checkPosition, true
			end
		end
	end

	return incident.location, false
end

function private.raycastGround(position: Vector3): Vector3?
	local rayOrigin = position + Vector3.new(0, GROUND_RAY_HEIGHT, 0)
	local rayDirection = Vector3.new(0, -GROUND_RAY_HEIGHT * 2, 0)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { Workspace.hazards }

	local result = Workspace:Raycast(rayOrigin, rayDirection, params)
	if result then
		return result.Position
	end
	return nil
end

function private.isObstructed(position: Vector3, size: Vector3): boolean
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {}

	local parts = Workspace:GetPartBoundsInBox(CFrame.new(position), size, params)

	for _, part in parts do
		if part.CanCollide then
			return true
		end
	end
	return false
end

function private.randomOffset(radius: number): Vector3
	local angle = math.random() * math.pi * 2
	local distance = math.random() * radius
	return Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
end

return public
