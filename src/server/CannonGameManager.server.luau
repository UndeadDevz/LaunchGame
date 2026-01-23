--[[
	CannonGameManager Server Script

	Configura los RemoteEvents y conecta con LaunchController
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local LaunchController = require(ServerScriptService.Modules.LaunchController)

-- Crear RemoteEvents
local function createEvent(name: string): RemoteEvent
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then existing:Destroy() end

	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = ReplicatedStorage
	return event
end

local launchEvent = createEvent("LaunchEvent")
createEvent("DistanceUpdateEvent")

-- Conectar eventos
launchEvent.OnServerEvent:Connect(function(player)
	print("[Server] LaunchEvent received from:", player.Name)
	LaunchController.Launch(player)
end)

Players.PlayerRemoving:Connect(function(player)
	LaunchController.CleanupPlayer(player)
end)

print("CannonGameManager loaded")
