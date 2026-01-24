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
local customForceValues: {[Player]: number} = {}
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

	-- Obtener Force del jugador (usar custom si existe, sino el máximo)
	local maxForce = ForceSystem and ForceSystem.GetForce(player) or 1
	local force = customForceValues[player] or maxForce
	-- Asegurar que no exceda el máximo
	if force > maxForce then force = maxForce end
	if force < 1 then force = 1 end
	local launchPower = getLaunchPower(force)

	-- Activar PlatformStand para evitar que el Humanoid interfiera durante el vuelo
	humanoid.PlatformStand = true

	-- Posicionar con orientación fija (mirando hacia -X) y lanzar
	rootPart.CFrame = CFrame.new(CONFIG.launchPosition) * CFrame.Angles(0, math.rad(90), 0)
	rootPart.AssemblyAngularVelocity = Vector3.zero -- Sin rotación
	rootPart.AssemblyLinearVelocity = Vector3.new(-launchPower, launchPower * CONFIG.verticalMultiplier, 0)
	print("[LaunchController] Player launched with power:", launchPower)

	-- Trackear distancia
	local startPos = rootPart.Position.X
	local lastPos = startPos
	local bestDistance = DataManager.GetStat(player, "BestDistance") or 0

	local distanceEvent = ReplicatedStorage:FindFirstChild("DistanceUpdateEvent")
	local heartbeatConnection
	local touchConnection
	local hasLanded = false
	local canLand = false -- No puede aterrizar hasta que esté en el aire
	local launchTime = tick()

	-- Función para aterrizar
	local function land()
		if hasLanded or not canLand then return end
		hasLanded = true

		if heartbeatConnection then heartbeatConnection:Disconnect() end
		if touchConnection then touchConnection:Disconnect() end

		-- Cancelar toda la física inmediatamente
		rootPart.Anchored = true
		task.wait() -- Un frame para que se aplique
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		rootPart.Anchored = false

		-- Desactivar PlatformStand para que pueda caminar
		humanoid.PlatformStand = false

		local finalDistance = startPos - lastPos
		if distanceEvent then
			distanceEvent:FireClient(player, finalDistance, false)
		end

		launchingPlayers[player] = nil
	end

	-- Detectar contacto con Touched (inmediato)
	touchConnection = rootPart.Touched:Connect(function(hit)
		if not canLand then return end
		-- Ignorar partes del propio personaje
		if hit:IsDescendantOf(character) then return end
		-- Ignorar partes no canCollide
		if not hit.CanCollide then return end
		land()
	end)

	local fixedZ = CONFIG.launchPosition.Z -- Mantener Z fija

	heartbeatConnection = RunService.Heartbeat:Connect(function()
		if not character or not character.Parent then
			canLand = true
			land()
			return
		end

		-- Mantener el vuelo recto: fijar Z y eliminar rotación
		local pos = rootPart.Position
		if math.abs(pos.Z - fixedZ) > 0.1 then
			rootPart.CFrame = CFrame.new(pos.X, pos.Y, fixedZ) * CFrame.Angles(0, math.rad(90), 0)
		end
		rootPart.AssemblyAngularVelocity = Vector3.zero

		local currentPos = rootPart.Position.X

		-- Permitir aterrizar después de:
		-- 1. Viajar cierta distancia y empezar a caer, O
		-- 2. Pasar cierto tiempo (timeout de seguridad), O
		-- 3. Velocidad muy baja (ya frenó)
		if not canLand then
			local distanceTraveled = startPos - currentPos
			local isFalling = rootPart.AssemblyLinearVelocity.Y < 0
			local timePassed = tick() - launchTime
			local velocityMag = rootPart.AssemblyLinearVelocity.Magnitude

			if (distanceTraveled > 20 and isFalling) or timePassed > 1 or velocityMag < 10 then
				canLand = true
			end
		end

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

		-- Fallback: si cae muy bajo
		if rootPart.Position.Y < CONFIG.minHeightThreshold then
			canLand = true
			land()
		end

		-- Timeout absoluto: forzar aterrizaje después de 30 segundos
		if tick() - launchTime > 30 then
			canLand = true
			land()
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

	-- Crear evento en Events folder para SetCustomForce
	local Events = ReplicatedStorage:WaitForChild("Events")
	local setCustomForceEvent = Events:FindFirstChild("SetCustomForce")
	if not setCustomForceEvent then
		setCustomForceEvent = Instance.new("RemoteEvent")
		setCustomForceEvent.Name = "SetCustomForce"
		setCustomForceEvent.Parent = Events
	end

	-- Conectar evento de lanzamiento
	launchEvent.OnServerEvent:Connect(function(player)
		LaunchController.Launch(player)
	end)

	-- Conectar evento de Force personalizado
	setCustomForceEvent.OnServerEvent:Connect(function(player, force)
		if typeof(force) == "number" then
			local maxForce = ForceSystem and ForceSystem.GetForce(player) or 1
			-- Validar que no exceda el máximo ni sea menor a 1
			force = math.clamp(force, 1, maxForce)
			customForceValues[player] = force
		end
	end)

	-- Limpieza cuando el jugador sale
	Players.PlayerRemoving:Connect(function(player)
		LaunchController.CleanupPlayer(player)
		customForceValues[player] = nil
	end)

	print("[LaunchController] Initialized")
end

return LaunchController
