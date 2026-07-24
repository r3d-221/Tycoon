local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local remotes = ReplicatedStorage.remotes
local HazardTaskCompleted = remotes:FindFirstChild("HazardTaskCompleted")
local StartHazardTask = remotes:FindFirstChild("StartHazardTask")

local taskTemplate = ReplicatedStorage.task_template

local animate = ReplicatedStorage.Animate

local enemyTag = "Enemy"

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local screen = PlayerGui:WaitForChild("ScreenGui")

StartHazardTask.OnClientEvent:Connect(function(Task: string, taskId: string)
	print("[Client] recieved call to start the hazard task for: " .. player.Name)
	local new = taskTemplate:Clone()
	local text = new:FindFirstChild("text")
	local button = new:FindFirstChild("button")

	text.Text = Task
	new.Parent = screen

	button.MouseButton1Click:Connect(function()
		HazardTaskCompleted:FireServer(taskId, true)
		new:Destroy()
	end)
end)

local function applyAnimate(object)
	if not object:IsDescendantOf(workspace) then
		return
	end
	if object:FindFirstChild("Animate") then
		return
	end

	local humanoid = object:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local newAnimate = animate:Clone()
	newAnimate.Parent = object
	newAnimate.Enabled = true
end

for _, object in CollectionService:GetTagged(enemyTag) do
	applyAnimate(object)
end
