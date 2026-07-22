local ServerScriptService = game:GetService("ServerScriptService")

local modules = ServerScriptService.modules
local PlayerSessionManager =  require(modules.player.PlayerSessionManager)

PlayerSessionManager.onStart()