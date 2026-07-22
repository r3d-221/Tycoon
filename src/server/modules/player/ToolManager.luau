local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local modules = ServerScriptService.modules
local Tool = require(modules.player.Tool)
local ToolData = require(modules.data.ToolData)

local toolTemplate = ReplicatedStorage:FindFirstChild("tool_template")

type ToolState = Tool.ToolState

local public = {}
local private = {}

--[[
	ownedTools[player][toolName] = {
		battery = number, -- durability
		upgrades = {}, -- the number of updrades on the tool
		stats = {}, -- stats after upgrading
		isEquipped = bool,
	}
]]
local ownedTools = {}
local equippedInstance = {}
local models = {}

function public.onStart()
	Players.PlayerRemoving:Connect(function(player)
		ownedTools[player] = nil
		equippedInstance[player] = nil
	end)
end

function public.grant(player: Player, toolName: string)
	ownedTools[player] = ownedTools[player] or {}
	if ownedTools[player][toolName] then
		return
	end

	local config = ToolData[toolName]
	if not config then
		warn("[ToolManager] no ToolData for: " .. toolName)
		return
	end

	ownedTools[player][toolName] = {
		battery = config.stats.capacity,
		upgrades = {}, -- will be changed to the saved upgrades in player data
		stats = table.clone(config.stats), -- will be changed to the saved upgrades in player data
		isEquipped = false,
	}
end

function public.equip(player: Player, toolName: string)
	local owned = ownedTools[player] and ownedTools[player][toolName]
	if not owned then
		warn("[ToolManager] " .. player.Name .. " doesn't own: " .. toolName)
		return
	end
	
	private.setModel(player, toolName)
	
	if equippedInstance[player] then
		public.unequip(player)
	end

	local config = ToolData[toolName]
	local instance = Tool.new(player, toolName, config)
	equippedInstance[player] = instance
	owned.isEquipped = true
	
	print("[ToolManager] equipped " .. toolName .. " for: " .. player.Name)
end

function public.unequip(player: Player)
	local instance = equippedInstance[player]
	if not instance then
		return
	end
	
	local existing = models[player]
	if not existing then
		return
	end

	local toolName = instance.toolName
	instance:destroy()
	equippedInstance[player] = nil

	local owned = ownedTools[player] and ownedTools[player][toolName]
	if owned then
		owned.isEquipped = false
	end
	
	local character = player.Character
	if character then
		local rightHand = character:FindFirstChild("RightHand")
		if rightHand then
			local motor = rightHand:FindFirstChild("WeaponGrip")
			if motor then
				motor:Destroy()
			end
		end
	end
	
	existing:Destroy()
	models[player] = nil
	print("[ToolManager] unequipped " .. toolName .. " for: " .. player.Name)
end

function public.getEquipped(player: Player)
	return equippedInstance[player]
end


function public.work(player: Player): boolean
	local instance = equippedInstance[player]
	if not instance then
		return false
	end
	return instance:work()
end

function private.setModel(player: Player, toolName: string)
	local character = player.Character
	if not character then
		return
	end

	local rightHand = character:FindFirstChild("RightHand")
	if not rightHand then
		warn("[ToolManager] RightHand not found")
		return
	end

	local modelTemplate = private.getModel(toolName)
	if not modelTemplate then
		warn("[ToolManager] No model found for: " .. toolName)
		return
	end
	
	local model = modelTemplate:Clone()
	model.Anchored = false
	model.CanCollide = false
	model.Parent = character
	
	local offsetVector = model:GetAttribute("offset") or Vector3.zero
	local rotationVector = model:GetAttribute("rotation") or Vector3.zero
	
	local rotationCFrame = CFrame.fromEulerAnglesXYZ(math.rad(rotationVector.X), math.rad(rotationVector.Y), math.rad(rotationVector.Z))

	local motor = Instance.new("Motor6D")
	motor.Name = "WeaponGrip"
	motor.Part0 = rightHand
	motor.Part1 = model
	motor.C0 = CFrame.new(offsetVector) * rotationCFrame
	motor.Parent = rightHand

	models[player] = model
end

function private.getModel(toolName: string): Instance?
	for _, child in toolTemplate:GetChildren() do
		if child.Name == toolName then
			return child
		end
	end
	return nil
end

function private.scan(player: Player)
	-- needs the detection system
end

function private.recharge(player: Player, toolName: string)
	-- needs a recharge station
end

function private.upgrade(player: Player, toolName: string, upgradeType: string)
	-- to do
end

return public