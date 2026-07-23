local ServerScriptService = game:GetService("ServerScriptService")
local modules = ServerScriptService.Server.modules
local Signal = require(modules.Signal)
local EnemyData = require(modules.data.EnemyData)
local HitboxManager = require(modules.player.HitboxManager)
local ItemManager = require(modules.player.ItemManager)

local public = {}
local private = {}
public.__index = public

local ROAM_RANGE = 15
local MAX_IDLE = 1.3
local MIN_IDLE = 0.5
local AGGRO_CHECK_TICK = 0.5

export type State = "idle" | "chase" | "attack" | "dead" | "destroyed"

function private.safeCancel(thread)
	if thread and thread ~= coroutine.running() then
		task.cancel(thread)
	end
end

function private.transition(self, methodName: string)
	task.spawn(function()
		self[methodName](self)
	end)
end

---- ONLY THE PLAYER OF THE INCIDENT CAN INTERACT WITH THE ENEMY ----

function public.new(player: Player, model: Model, hazardId: string?)
	local self = setmetatable({}, public)
	local enemyName = model.Name

	self.target = player
	self.Name = enemyName
	self.config = EnemyData[enemyName]
	self.id = `enemy_{player.Name}_{enemyName}_{os.clock()}`
	self.hazardId = hazardId

	self.model = model
	self.humanoid = model:FindFirstChild("Humanoid")
	self.rootPart = model:FindFirstChild("HumanoidRootPart")
	self.originPosition = self.rootPart.Position
	self.isAttacking = false

	self.connections = {}
	self._destroyed = false

	self.stateChanged = Signal.new()

	local diedConnection
	diedConnection = self.humanoid.Died:Connect(function()
		diedConnection:Disconnect()
		self:onDead()
	end)

	self:onIdle()

	return self
end

---- States ----

function public:onIdle()
	self.state = "idle"
	self.stateChanged:Fire("idle")

	self.connections.roam = task.spawn(function()
		while not self._destroyed and self.state == "idle" do
			local rootPart = self.rootPart
			if not rootPart or not rootPart.Parent then
				break
			end

			local origin = self.originPosition
			local y = rootPart.Position.Y
			local x = math.random(origin.X - ROAM_RANGE, origin.X + ROAM_RANGE)
			local z = math.random(origin.Z - ROAM_RANGE, origin.Z + ROAM_RANGE)

			self.humanoid:MoveTo(Vector3.new(x, y, z))

			local moved = false
			local moveConnection
			moveConnection = self.humanoid.MoveToFinished:Connect(function()
				moved = true
				moveConnection:Disconnect()
			end)

			local elapsed = 0
			while not moved and elapsed < 5 and self.state == "idle" do
				task.wait(0.1)
				elapsed += 0.1
			end
			moveConnection:Disconnect()

			if self.state ~= "idle" then
				break
			end

			local idleTime = math.random() * (MAX_IDLE - MIN_IDLE) + MIN_IDLE
			task.wait(idleTime)
		end
	end)

	self.connections.aggroCheck = task.spawn(function()
		task.wait(AGGRO_CHECK_TICK)
		while not self._destroyed and self.state == "idle" do
			if private.isTargetInRange(self, self.config.minAggroRange) then
				private.transition(self, "onChase")
				break
			end
			task.wait(AGGRO_CHECK_TICK)
		end
	end)
end

function public:onChase()
	self.state = "chase"
	self.stateChanged:Fire("chase")
	self.humanoid.WalkSpeed = self.config.walkspeed or 10

	self.connections.chase = task.spawn(function()
		while not self._destroyed and self.state == "chase" do
			local character = self.target.Character
			if not character or not character:FindFirstChild("HumanoidRootPart") then
				private.transition(self, "onIdle")
				break
			end

			local targetRoot = character.HumanoidRootPart
			local distanceToTarget = (self.rootPart.Position - targetRoot.Position).Magnitude
			local distanceFromOrigin = (targetRoot.Position - self.originPosition).Magnitude

			if distanceToTarget <= self.config.attackRange then
				private.transition(self, "onAttack")
				break
			elseif distanceFromOrigin >= self.config.maxAggroRange then
				private.transition(self, "onIdle")
				break
			else
				self.humanoid:MoveTo(targetRoot.Position)
			end

			task.wait(AGGRO_CHECK_TICK)
		end
	end)
end

function public:onAttack()
	self.state = "attack"
	self.stateChanged:Fire("attack")

	self.connections.attack = task.spawn(function()
		while not self._destroyed and self.state == "attack" do
			local character = self.target.Character
			if not character or not character:FindFirstChild("HumanoidRootPart") then
				private.transition(self, "onIdle")
				break
			end

			local distanceToTarget = (self.rootPart.Position - character.HumanoidRootPart.Position).Magnitude
			if distanceToTarget > self.config.attackRange then
				private.transition(self, "onChase")
				break
			end

			HitboxManager.performAttack(self)
			task.wait(self.config.cooldown)
		end
	end)
end

function public:onDead()
	if self._destroyed then
		return
	end

	self.state = "dead"
	self.stateChanged:Fire("dead")

	self:drops()

	for _, thread in pairs(self.connections) do
		private.safeCancel(thread)
	end

	task.delay(3, function()
		self:destroy()
	end)
end

---- Misc ----

function public:drops()
	if not self.config.drops then
		return
	end
	-- ItemManager.grantDrops(self.target, self.config.drops)
end

function public:destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true

	for _, thread in pairs(self.connections) do
		private.safeCancel(thread)
	end

	if self.model and self.model.Parent then
		self.model:Destroy()
	end

	self.stateChanged:Fire("destroyed")
end

function public:getState(): State
	return self.state
end

function private.isTargetInRange(self, range: number): boolean
	local character = self.target.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return false
	end
	local distance = (self.rootPart.Position - character.HumanoidRootPart.Position).Magnitude
	return distance <= range
end

return public
