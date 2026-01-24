--[[
	LaunchController Module

	Responsabilidad única: Lanzar al jugador desde el cañón
	y trackear la distancia durante el vuelo.
--]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataManager = require(ServerScriptService.Data.DataManager)
local ForceSystem -- Lazy loaded

local Players = game:GetService("Players")

local LaunchController = {}

-- Estado de sesión (no persistente)
local launchingPlayers: {[Player]: boolean} = {}
local initialized = false

-- Configuración
local CONFIG = {
	baseLaunchPower = 300,
	powerPerForce = 25,
	launchPosition = Vector3.new(-35, 15, 0),
	verticalMultiplier = 0.3,
	minVelocityThreshold = 5,
	minHeightThreshold = -100,
}

local function getLaunchPower(force: number): number
	return CONFIG.baseLaunchPower + (CONFIG.powerPerForce * (force - 1))
end

function LaunchController.IsLaunching(player: Player): boolean
	return launchingPlayers[player] == true
end

function LaunchController.Launch(player: Player)
	print("[LaunchController] Launch called for:", player.Name)

	if launchingPlayers[player] then
		print("[LaunchController] Player already launching, returning")
		return
	end

	local character = player.Character
	if not character then
		print("[LaunchController] No character found, returning")
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then
		print("[LaunchController] No humanoid or rootPart, returning")
		return
	end

	print("[LaunchController] All checks passed, launching player")
	launchingPlayers[player] = true

	-- Obtener Force del jugador
	local force = ForceSystem and ForceSystem.GetForce(player) or 1
	local launchPower = getLaunchPower(force)

	-- Posicionar y lanzar
	rootPart.CFrame = CFrame.new(CONFIG.launchPosition)
	rootPart.AssemblyLinearVelocity = Vector3.new(-launchPower, launchPower * CONFIG.verticalMultiplier, 0)
	print("[LaunchController] Player launched with power:", launchPower)

	-- Trackear distancia
	local startPos = rootPart.Position.X
	local lastPos = startPos
	local bestDistance = DataManager.GetStat(player, "BestDistance") or 0

	local distanceEvent = ReplicatedStorage:FindFirstChild("DistanceUpdateEvent")
	local connection

	connection = RunService.Heartbeat:Connect(function()
		if not character or not character.Parent then
			connection:Disconnect()
			launchingPlayers[player] = nil
			return
		end

		local currentPos = rootPart.Position.X
		if currentPos < lastPos then
			local distance = startPos - currentPos

			if distance > bestDistance then
				bestDistance = distance
				DataManager.UpdateStat(player, "BestDistance", bestDistance)
			end

			if distanceEvent then
				distanceEvent:FireClient(player, distance, true)
			end

			lastPos = currentPos
		end

		-- Detectar aterrizaje
		local hasLanded = rootPart.AssemblyLinearVelocity.Magnitude < CONFIG.minVelocityThreshold
			or rootPart.Position.Y < CONFIG.minHeightThreshold

		if hasLanded then
			connection:Disconnect()

			local finalDistance = startPos - lastPos
			if distanceEvent then
				distanceEvent:FireClient(player, finalDistance, false)
			end

			launchingPlayers[player] = nil
		end
	end)
end

-- Limpiar cuando el jugador se va
function LaunchController.CleanupPlayer(player: Player)
	launchingPlayers[player] = nil
end

function LaunchController:Init()
	if initialized then return end
	initialized = true

	-- Cargar ForceSystem
	ForceSystem = require(ServerScriptService.Modules.ForceSystem)

	-- Crear RemoteEvents
	local function createEvent(name: string): RemoteEvent
		local existing = ReplicatedStorage:FindFirstChild(name)
		if existing then return existing :: RemoteEvent end

		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = ReplicatedStorage
		return event
	end

	local launchEvent = createEvent("LaunchEvent")
	createEvent("DistanceUpdateEvent")

	-- Conectar evento de lanzamiento
	launchEvent.OnServerEvent:Connect(function(player)
		LaunchController.Launch(player)
	end)

	-- Limpieza cuando el jugador sale
	Players.PlayerRemoving:Connect(function(player)
		LaunchController.CleanupPlayer(player)
	end)

	print("[LaunchController] Initialized")
end

return LaunchController
