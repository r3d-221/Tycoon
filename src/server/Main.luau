local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.Server.modules
local PlayerSessionManager = require(modules.player.PlayerSessionManager)

PlayerSessionManager.onStart()
