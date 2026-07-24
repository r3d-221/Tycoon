--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Modules.Types)

type HazardTaskType = Types.HazardTaskType

export type HazardTaskData = {
	duration: number,
	difficulty: number,
}

local public: { [HazardTaskType]: HazardTaskData } = {
	connectWires = {
		duration = 6,
		difficulty = 3,
	},
	clearArea = {
		duration = 7,
		difficulty = 1,
	},
}

return public
