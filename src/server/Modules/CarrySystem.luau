--!strict
--[[
	CarrySystem Module

	Gestiona el sistema de recolección de ítems temporales.
	Se activa exclusivamente por contacto con partes dentro del Folder LandPlatforms.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")

local CarrySystem = {}

-- [ MODULES ]
local ItemConfigurations = require(ReplicatedStorage.Modules.ItemConfigurations)
local PlayerController = require(ServerScriptService.Controllers.PlayerController)
local ItemManager -- Lazy Loaded

-- [ ASSETS ]
local LandPlatforms = Workspace:WaitForChild("LandPlatforms")
local Destination = Workspace:WaitForChild("Destination") :: BasePart
local Templates = ReplicatedStorage:WaitForChild("Templates")
local CarryGUI_Template = Templates:WaitForChild("CarryGUI")
local Events = ReplicatedStorage:WaitForChild("Events")
local GlobalSounds = Workspace:WaitForChild("Sounds")

-- [ DATA ]
local carryingData: {[Player]: {any}} = {}
local activeSequence: {[Player]: {
	startTime: number,
	thread: thread?,
}} = {}

-- [ CONFIG ]
local SEQUENCE_DURATION = 5000

-- [ HELPERS ]

local function getCarryGUI(player: Player): BillboardGui?
	if not player.Character then return nil end
	local head = player.Character:FindFirstChild("Head")
	if not head then return nil end
	return head:FindFirstChild("CarryGUI") :: BillboardGui
end

local function updateCarryGUI(player: Player)
	local gui = getCarryGUI(player)
	if not gui then return end

	local items = carryingData[player] or {}
	local count = #items

	local profile = PlayerController:GetProfile(player)
	local limit = profile and profile.Data.MaxCarry or 1

	local limitLabel = gui:FindFirstChild("CarryLimit") :: TextLabel
	if limitLabel then
		limitLabel.Text = tostring(count) .. "/" .. tostring(limit)
	end

	local imagesFrame = gui:FindFirstChild("ItemImages")
	if imagesFrame then
		local folder = imagesFrame:FindFirstChild("Template")
		local template = folder and folder:FindFirstChild("ImageTemplate")

		if template then
			for _, child in ipairs(imagesFrame:GetChildren()) do
				if child:IsA("ImageLabel") and child ~= template then
					child:Destroy()
				end
			end

			for _, item in ipairs(items) do
				local conf = ItemConfigurations.GetItemData(item.Name)
				if conf then
					local newIcon = template:Clone()
					newIcon.Image = conf.ImageId or ""
					newIcon.Visible = true
					newIcon.Parent = imagesFrame
				end
			end
		end
	end
end

local function showCarryGUI(player: Player)
	if not player.Character then return end
	local head = player.Character:FindFirstChild("Head")
	if not head then return end

	if not head:FindFirstChild("CarryGUI") then
		local gui = CarryGUI_Template:Clone()
		gui.Name = "CarryGUI"
		gui.Adornee = head
		gui.Parent = head
		updateCarryGUI(player)
	end
end

local function hideCarryGUI(player: Player)
	if not player.Character then return end
	local head = player.Character:FindFirstChild("Head")
	if head then
		local gui = head:FindFirstChild("CarryGUI")
		if gui then gui:Destroy() end
	end
end

-- [ SEQUENCE LOGIC ]

local function cancelSequence(player: Player)
	local sequence = activeSequence[player]
	if not sequence then return end

	if sequence.thread then
		task.cancel(sequence.thread)
	end
	activeSequence[player] = nil

	-- Entregar ítems si tiene (sin teletransporte)
	local items = carryingData[player]
	if items and #items > 0 then
		carryingData[player] = {}

		for _, itemData in ipairs(items) do
			ItemManager.GiveItemToPlayer(player, itemData.Name, itemData.Mutation, itemData.Rarity, 1)
		end

		local successSound = GlobalSounds:FindFirstChild("Success")
		if successSound and successSound:IsA("Sound") then
			local newSound = successSound:Clone()
			newSound.Parent = player:WaitForChild("PlayerGui")
			newSound:Play()
			Debris:AddItem(newSound, newSound.TimeLength + 1)
		end
	end

	hideCarryGUI(player)
end

local function completeDelivery(player: Player)
	-- Operación atómica: capturar datos antes de limpiar
	local items = carryingData[player]
	local character = player.Character

	if not character then
		cancelSequence(player)
		return
	end

	-- Limpiar datos inmediatamente para evitar duplicados
	carryingData[player] = {}
	activeSequence[player] = nil

	-- Teletransportar al jugador
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if rootPart then
		local destinationCFrame = Destination.CFrame + Vector3.new(0, 3, 0)
		rootPart.CFrame = destinationCFrame
	end

	-- Entregar ítems
	if items and #items > 0 then
		for _, itemData in ipairs(items) do
			ItemManager.GiveItemToPlayer(player, itemData.Name, itemData.Mutation, itemData.Rarity, 1)
		end

		-- Sonido de éxito
		local successSound = GlobalSounds:FindFirstChild("Success")
		if successSound and successSound:IsA("Sound") then
			local newSound = successSound:Clone()
			newSound.Parent = player:WaitForChild("PlayerGui")
			newSound:Play()
			Debris:AddItem(newSound, newSound.TimeLength + 1)
		end
	end

	-- Destruir CarryGUI
	hideCarryGUI(player)
end

local function startSequence(player: Player)
	-- Si ya está en una secuencia activa, no hacer nada (tiempo inamovible)
	if activeSequence[player] then
		return
	end

	local startTime = tick()

	local sequenceThread = task.spawn(function()
		-- TODO: Actualizar CarryGUI con countdown visual durante los 5 segundos
		task.wait(SEQUENCE_DURATION)

		-- Verificar que la secuencia no fue cancelada
		if not activeSequence[player] then
			return
		end

		-- Secuencia completada: teletransportar y entregar
		completeDelivery(player)
	end)

	activeSequence[player] = {
		startTime = startTime,
		thread = sequenceThread,
	}
end

local function onPlayerTouchedPlatform(player: Player)
	startSequence(player)
end

local function setupPlatformDetection(platform: BasePart)
	platform.Touched:Connect(function(otherPart: BasePart)
		local character = otherPart.Parent
		if not character then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		onPlayerTouchedPlatform(player)
	end)
end

-- [ PUBLIC API ]

function CarrySystem.CanCarryMore(player: Player): boolean
	local current = carryingData[player] or {}
	local profile = PlayerController:GetProfile(player)
	local limit = profile and profile.Data.MaxCarry or 1
	return #current < limit
end

function CarrySystem.AddItemToCarry(player: Player, name: string, mutation: string, rarity: string): boolean
	if not carryingData[player] then
		carryingData[player] = {}
	end

	if CarrySystem.CanCarryMore(player) then
		table.insert(carryingData[player], {
			Name = name,
			Mutation = mutation,
			Rarity = rarity
		})
		showCarryGUI(player)
		updateCarryGUI(player)
		return true
	end
	return false
end

function CarrySystem.GetCarryingItems(player: Player): {any}
	return carryingData[player] or {}
end

function CarrySystem.RefreshGUI(player: Player)
	updateCarryGUI(player)
end

function CarrySystem.IsInSequence(player: Player): boolean
	return activeSequence[player] ~= nil
end

-- Llamar desde el sensor de salida para cancelar la secuencia si el jugador sale caminando
function CarrySystem.CancelSequence(player: Player)
	cancelSequence(player)
end

-- [ INIT & START ]

function CarrySystem:Init()
	print("[CarrySystem] Initialized")
	local Modules = ServerScriptService:WaitForChild("Modules")
	ItemManager = require(Modules:WaitForChild("ItemManager"))

	local dropEvent = Events:FindFirstChild("RequestDropItem")
	if not dropEvent then
		dropEvent = Instance.new("RemoteEvent")
		dropEvent.Name = "RequestDropItem"
		dropEvent.Parent = Events
	end

	dropEvent.OnServerEvent:Connect(function(player)
		-- Limpiar items (sin cancelar el timer)
		carryingData[player] = {}
		updateCarryGUI(player)

		local notif = Events:FindFirstChild("ShowNotification")
		if notif then notif:FireClient(player, "Items Dropped", "Success") end
	end)
end

function CarrySystem:Start()
	-- Configurar detección para todas las plataformas existentes
	for _, platform in ipairs(LandPlatforms:GetChildren()) do
		if platform:IsA("BasePart") then
			setupPlatformDetection(platform)
		end
	end

	-- Escuchar nuevas plataformas añadidas dinámicamente
	LandPlatforms.ChildAdded:Connect(function(child)
		if child:IsA("BasePart") then
			setupPlatformDetection(child)
		end
	end)

	-- Sensor de salida: cancela secuencia y entrega ítems si el jugador sale caminando
	local exitSensor = Workspace:FindFirstChild("ExitSensor") :: BasePart?
	if exitSensor then
		exitSensor.Touched:Connect(function(otherPart: BasePart)
			local character = otherPart.Parent
			if not character then return end

			local player = Players:GetPlayerFromCharacter(character)
			if player and activeSequence[player] then
				cancelSequence(player)
			end
		end)
	else
		warn("[CarrySystem] ExitSensor not found in Workspace")
	end

	-- Limpieza cuando un jugador sale
	Players.PlayerRemoving:Connect(function(player)
		cancelSequence(player)
		carryingData[player] = nil
	end)
end

return CarrySystem
