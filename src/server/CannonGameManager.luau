-- Cannon Launch Game Manager (+ Gacha System)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- [NUEVO] Gacha Configuration
-- Chance: Probabilidad (mientras más bajo el número, más difícil)
-- Multiplier: Por cuánto multiplica las monedas (1.5 = +50%)
local petConfig = {
	{name = "Pet1", displayName = "Gato Común", chance = 40, multiplier = 1.1}, -- 40%
	{name = "Pet2", displayName = "Perro Leal", chance = 30, multiplier = 1.2}, -- 30%
	{name = "Pet3", displayName = "Conejo Veloz", chance = 15, multiplier = 1.4}, -- 15%
	{name = "Pet4", displayName = "Oso Fuerte", chance = 8, multiplier = 1.6},  -- 8%
	{name = "Pet5", displayName = "Zorro Astuto", chance = 4, multiplier = 2.0},  -- 4%
	{name = "Pet6", displayName = "Dragón Bebe", chance = 2, multiplier = 3.0},  -- 2%
	{name = "Pet7", displayName = "Fénix Dorado", chance = 0.9, multiplier = 5.0}, -- 0.9%
	{name = "Pet8", displayName = "Alien Mítico", chance = 0.1, multiplier = 10.0} -- 0.1%
}
local GACHA_COST = 500 -- Precio por tirar el Gacha

-- Clean up existing events first
local function cleanEvent(name)
	local e = ReplicatedStorage:FindFirstChild(name)
	if e then e:Destroy() end
end
cleanEvent("LaunchEvent")
cleanEvent("UpgradeEvent")
cleanEvent("CoinUpdateEvent")
cleanEvent("DistanceUpdateEvent")
cleanEvent("RebirthEvent")
cleanEvent("GachaEvent") -- [NUEVO]

-- Create RemoteEvents
local launchEvent = Instance.new("RemoteEvent")
launchEvent.Name = "LaunchEvent"
launchEvent.Parent = ReplicatedStorage

local upgradeEvent = Instance.new("RemoteEvent")
upgradeEvent.Name = "UpgradeEvent"
upgradeEvent.Parent = ReplicatedStorage

local coinUpdateEvent = Instance.new("RemoteEvent")
coinUpdateEvent.Name = "CoinUpdateEvent"
coinUpdateEvent.Parent = ReplicatedStorage

local distanceUpdateEvent = Instance.new("RemoteEvent")
distanceUpdateEvent.Name = "DistanceUpdateEvent"
distanceUpdateEvent.Parent = ReplicatedStorage

local rebirthEvent = Instance.new("RemoteEvent")
rebirthEvent.Name = "RebirthEvent"
rebirthEvent.Parent = ReplicatedStorage

-- [NUEVO] Evento para comprar mascotas
local gachaEvent = Instance.new("RemoteEvent")
gachaEvent.Name = "GachaEvent"
gachaEvent.Parent = ReplicatedStorage

-- Player data storage
local playerData = {}

-- Game configuration
local config = {
	baseLaunchPower = 500,
	upgradeCostBase = 10,
	upgradeMultiplier = 1.5,
	speedIncreasePerUpgrade = 50,
	coinMultiplier = 0.1,
	rebirthCost = 1000,
	rebirthMultiplier = 0.5
}

-- Initialize player data
local function initializePlayerData(player)
	if not playerData[player.UserId] then
		playerData[player.UserId] = {
			coins = 0,
			speedLevel = 1,
			totalDistance = 0,
			bestDistance = 0,
			isLaunching = false,
			rebirths = 0,
			-- [NUEVO] Datos de mascotas
			equippedPet = nil, -- Guardará el índice de la tabla petConfig (ej: 1, 5, 8)
			ownedPets = {} -- Lista de mascotas obtenidas
		}
	end
end

-- [NUEVO] Función para calcular el multiplicador total de la mascota
local function getPetMultiplier(player)
	local data = playerData[player.UserId]
	if data and data.equippedPet then
		local petInfo = petConfig[data.equippedPet]
		if petInfo then
			return petInfo.multiplier
		end
	end
	return 1 -- Si no tiene mascota, multiplica por 1 (neutral)
end

-- [NUEVO] Sistema de Visualización de la Mascota (Seguimiento)
local function spawnPetVisual(player)
	local data = playerData[player.UserId]
	if not data or not data.equippedPet then return end

	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Borrar mascota anterior si existe
	local oldPet = character:FindFirstChild("ActivePet")
	if oldPet then oldPet:Destroy() end

	local petInfo = petConfig[data.equippedPet]

	-- Buscar modelo en ReplicatedStorage
	local petModel
	local storageFolder = ReplicatedStorage:FindFirstChild("PetModels")
	if storageFolder and storageFolder:FindFirstChild(petInfo.name) then
		petModel = storageFolder[petInfo.name]:Clone()
	else
		-- Si no existe el modelo, crear un bloque genérico (para evitar errores)
		petModel = Instance.new("Part")
		petModel.Size = Vector3.new(2,2,2)
		petModel.Color = Color3.fromRGB(255, 170, 0)
		petModel.Material = Enum.Material.Neon
	end

	petModel.Name = "ActivePet"
	petModel.CanCollide = false

	-- Asegurar que es un modelo o parte manejable
	if petModel:IsA("Model") then
		if not petModel.PrimaryPart then
			petModel.PrimaryPart = petModel:FindFirstChildWhichIsA("BasePart")
		end
		-- Soldar las partes del modelo para que no se desarme
		for _, part in pairs(petModel:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Massless = true
			end
		end
	else
		petModel.Massless = true
	end

	petModel.Parent = character

	-- Posicionamiento inicial
	local startCFrame = rootPart.CFrame * CFrame.new(3, 3, 3)
	if petModel:IsA("Model") then
		petModel:SetPrimaryPartCFrame(startCFrame)
	else
		petModel.CFrame = startCFrame
	end

	-- [LÓGICA DE SEGUIMIENTO FÍSICO]
	-- Usamos AlignPosition y AlignOrientation para un movimiento suave
	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "PetAttachment"
	attachment0.Position = Vector3.new(3, 4, 2) -- La mascota flota arriba a la derecha
	attachment0.Parent = rootPart

	local attachment1 = Instance.new("Attachment")
	attachment1.Parent = petModel:IsA("Model") and petModel.PrimaryPart or petModel

	local alignPos = Instance.new("AlignPosition")
	alignPos.Mode = Enum.PositionAlignmentMode.TwoAttachment
	alignPos.Attachment0 = attachment0
	alignPos.Attachment1 = attachment1
	alignPos.Responsiveness = 15 -- Qué tan rápido sigue al jugador
	alignPos.MaxForce = 100000
	alignPos.Parent = petModel

	local alignRot = Instance.new("AlignOrientation")
	alignRot.Mode = Enum.OrientationAlignmentMode.TwoAttachment
	alignRot.Attachment0 = attachment0
	alignRot.Attachment1 = attachment1
	alignRot.Responsiveness = 20
	alignRot.MaxTorque = 100000
	alignRot.Parent = petModel
end

local function getUpgradeCost(level)
	return math.floor(config.upgradeCostBase * (config.upgradeMultiplier ^ (level - 1)))
end

local function getLaunchPower(level)
	return config.baseLaunchPower + (config.speedIncreasePerUpgrade * (level - 1))
end

-- [MODIFICADO] Calculate coins earned with rebirth AND PET multiplier
local function calculateCoins(distance, rebirths, player)
	local baseCoins = math.floor(distance * config.coinMultiplier)
	local rebirthMult = 1 + (rebirths * config.rebirthMultiplier)

	-- Obtener multiplicador de mascota
	local petMult = getPetMultiplier(player)

	-- Fórmula final: Base * Rebirth * Mascota
	return math.floor(baseCoins * rebirthMult * petMult)
end

-- Launch player
local function launchPlayer(player)
	local data = playerData[player.UserId]
	if not data or data.isLaunching then return end

	data.isLaunching = true
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then return end

	-- [IMPORTANTE] Escondemos la mascota al lanzar para que no estorbe la física
	local pet = character:FindFirstChild("ActivePet")
	if pet then pet.Parent = nil end -- La guardamos en el limbo un momento

	rootPart.CFrame = CFrame.new(-35, 15, 0)
	local launchPower = getLaunchPower(data.speedLevel)
	rootPart.AssemblyLinearVelocity = Vector3.new(launchPower, launchPower * 0.3, 0)

	local startPos = rootPart.Position.X
	local lastPos = startPos
	local connection

	connection = RunService.Heartbeat:Connect(function()
		if not character or not character.Parent then
			connection:Disconnect()
			return
		end

		local currentPos = rootPart.Position.X
		if currentPos > lastPos then
			local distance = currentPos - startPos
			data.totalDistance = distance
			if distance > data.bestDistance then data.bestDistance = distance end
			distanceUpdateEvent:FireClient(player, distance, true)
			lastPos = currentPos
		end

		if rootPart.AssemblyLinearVelocity.Magnitude < 5 or rootPart.Position.Y < -100 then
			connection:Disconnect()
			distanceUpdateEvent:FireClient(player, data.totalDistance, false)

			-- [MODIFICADO] Pasamos 'player' para calcular el bono de mascota
			local coinsEarned = calculateCoins(data.totalDistance, data.rebirths, player)
			data.coins += coinsEarned

			coinUpdateEvent:FireClient(player, data.coins, data.totalDistance, data.bestDistance, data.rebirths)

			task.wait(2)
			data.isLaunching = false
			data.totalDistance = 0
			player:LoadCharacter() -- Esto respawnea y vuelve a llamar a CharacterAdded -> spawnPetVisual
		end
	end)
end

local function handleUpgrade(player)
	local data = playerData[player.UserId]
	if not data then return end
	local cost = getUpgradeCost(data.speedLevel)
	if data.coins >= cost then
		data.coins -= cost
		data.speedLevel += 1
		coinUpdateEvent:FireClient(player, data.coins, data.totalDistance, data.bestDistance, data.rebirths)
		return true, data.speedLevel, getUpgradeCost(data.speedLevel)
	end
	return false
end

local function handleRebirth(player)
	local data = playerData[player.UserId]
	if not data then return end
	if data.coins >= config.rebirthCost then
		data.coins = 0
		data.speedLevel = 1
		data.totalDistance = 0
		data.bestDistance = 0
		data.rebirths = data.rebirths + 1
		coinUpdateEvent:FireClient(player, data.coins, data.totalDistance, data.bestDistance, data.rebirths)
		return true, data.rebirths
	end
	return false
end

-- [NUEVO] Lógica del Gacha (Sorteo)
local function handleGacha(player)
	print('Gacha')
	local data = playerData[player.UserId]
	print(data)
	if not data then return end

	-- 1. Verificar dinero
	if data.coins < GACHA_COST then
		return false, "No hay suficientes monedas"
	end
	-- 2. Restar dinero
	data.coins -= GACHA_COST

	-- 3. Calcular Probabilidades (Weighted Random)
	local totalChance = 0
	for _, pet in ipairs(petConfig) do
		totalChance += pet.chance
	end

	local randomVal = math.random() * totalChance
	local currentSum = 0
	local wonPetIndex = 1

	for i, pet in ipairs(petConfig) do
		currentSum += pet.chance
		if randomVal <= currentSum then
			wonPetIndex = i
			break
		end
	end
	print(wonPetIndex)
	-- 4. Guardar Mascota
	-- (Por simplicidad, equipamos automáticamente la nueva mascota)
	data.equippedPet = wonPetIndex
	table.insert(data.ownedPets, wonPetIndex)

	-- 5. Actualizar Visuales
	spawnPetVisual(player)

	-- 6. Actualizar Cliente
	coinUpdateEvent:FireClient(player, data.coins, data.totalDistance, data.bestDistance, data.rebirths)

	local petWon = petConfig[wonPetIndex]
	return true, petWon.displayName, petWon.multiplier
end

-- Event handlers
launchEvent.OnServerEvent:Connect(function(player)
	initializePlayerData(player)
	launchPlayer(player)
end)

upgradeEvent.OnServerEvent:Connect(function(player)
	initializePlayerData(player)
	local success, newLevel, nextCost = handleUpgrade(player)
	upgradeEvent:FireClient(player, success, newLevel, nextCost)
end)

rebirthEvent.OnServerEvent:Connect(function(player)
	initializePlayerData(player)
	local success, newRebirthCount = handleRebirth(player)
	rebirthEvent:FireClient(player, success, newRebirthCount)
end)

-- [NUEVO] Conexión del evento Gacha
gachaEvent.OnServerEvent:Connect(function(player)
	initializePlayerData(player)
	local success, petName, multiplier = handleGacha(player)
	gachaEvent:FireClient(player, success, petName, multiplier)
end)

-- Initialize players when they join
Players.PlayerAdded:Connect(function(player)
	initializePlayerData(player)

	-- [NUEVO] Cuando el personaje aparece, mostrar su mascota
	player.CharacterAdded:Connect(function(character)
		-- Esperar un poco a que cargue todo
		task.wait(1)
		spawnPetVisual(player)
	end)
end)

for _, player in Players:GetPlayers() do
	initializePlayerData(player)
	-- Para jugadores que ya estaban al reiniciar el script
	if player.Character then
		spawnPetVisual(player)
	end
end


print("CannonGameManager + Gacha script loaded successfully!")