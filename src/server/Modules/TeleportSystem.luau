--!strict
-- LOCATION: ServerScriptService/Modules/TeleportSystem

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TeleportSystem = {}

local CarrySystem -- Lazy loaded
local initialized = false

function TeleportSystem:Init()
	if initialized then return end
	initialized = true

	-- Cargar CarrySystem
	CarrySystem = require(ServerScriptService.Modules.CarrySystem)

	local Events = ReplicatedStorage:WaitForChild("Events")

	-- Crear evento si no existe
	local TeleportEvent = Events:FindFirstChild("RequestTeleportHome")
	if not TeleportEvent then
		TeleportEvent = Instance.new("RemoteEvent")
		TeleportEvent.Name = "RequestTeleportHome"
		TeleportEvent.Parent = Events
	end

	TeleportEvent.OnServerEvent:Connect(function(player)
		-- Usar CarrySystem para convertir items y teleportar
		CarrySystem.DeliverAndTeleport(player)

		-- Notificar
		local notif = Events:FindFirstChild("ShowNotification")
		if notif then
			notif:FireClient(player, "Teleported home!", "Success")
		end
	end)

	print("[TeleportSystem] Initialized")
end

return TeleportSystem
