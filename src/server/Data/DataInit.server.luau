-- [[ SERVICIOS ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- [[ LIBRERIAS Y MODULOS ]] --
local ProfileStore = require(ServerScriptService.Libraries:WaitForChild("ProfileStore"))
local DataManager = require(ServerScriptService.Data.DataManager)
local Template = require(ServerScriptService.Data.Template)
local PetMultipliers = require(ReplicatedStorage.Modules.PetMultipliers)

-- [[ CONFIGURACION ]] --
local function GetStoreName()
	return RunService:IsStudio() and "DS_Test_01" or "DS_Production_01"
end

local PlayerStore = ProfileStore.New(GetStoreName(), Template)

-- No cargar en servidores privados reservados
if game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0 then return end

--- Crea las carpetas e instancias de valores para el jugador
local function Initialize(player: Player, profile)
	local Data = profile.Data

	-- Carpeta principal
	local MainFolder = Instance.new("Folder")
	MainFolder.Name = "Data"
	MainFolder.Parent = player

	-- Carpeta PlayerData
	local PlayerDataFolder = Instance.new("Folder")
	PlayerDataFolder.Name = "PlayerData"
	PlayerDataFolder.Parent = MainFolder

	-- Valores de PlayerData
	local function CreateValue(valueType, name, value, parent)
		local newValue = Instance.new(valueType)
		newValue.Name = name
		newValue.Value = value
		newValue.Parent = parent
		return newValue
	end

	CreateValue("NumberValue", "Currency", Data.Currency, PlayerDataFolder)
	CreateValue("IntValue", "Rebirth", Data.Rebirth, PlayerDataFolder)
	CreateValue("BoolValue", "Music", Data.Music, PlayerDataFolder)
	CreateValue("BoolValue", "ShowOtherPets", Data.ShowOtherPets, PlayerDataFolder)
	CreateValue("IntValue", "EggsHatched", Data.EggsHatched, PlayerDataFolder)
	CreateValue("IntValue", "TotalCurrency", Data.TotalCurrency, PlayerDataFolder)

	-- Carpeta Gamepasses
	local GamepassesFolder = Instance.new("Folder")
	GamepassesFolder.Name = "Gamepasses"
	GamepassesFolder.Parent = MainFolder

	for gamepassName, owned in Data.Gamepasses do
		CreateValue("BoolValue", gamepassName, owned, GamepassesFolder)
		-- Sync as player attribute for client access
		player:SetAttribute(gamepassName, owned)
	end

	-- Carpeta Pets
	local PetsFolder = Instance.new("Folder")
	PetsFolder.Name = "Pets"
	PetsFolder.Parent = MainFolder

	PetMultipliers.AddPlayer(player.Name)

	for petId, petInfo in Data.Pets do
		local NewPet = ReplicatedStorage.Assets.PetTemplate:Clone()
		NewPet.Name = tostring(petId)
		NewPet.PetName.Value = petInfo.PetName
		NewPet.Equipped.Value = petInfo.Equipped
		NewPet.Parent = PetsFolder

		if petInfo.Equipped then
			PetMultipliers.AddPet(player.Name, NewPet)
		end
	end

	-- Carpeta AutoDelete
	local AutoDeleteFolder = Instance.new("Folder")
	AutoDeleteFolder.Name = "AutoDelete"
	AutoDeleteFolder.Parent = MainFolder

	for _, Pet in ReplicatedStorage.Pets:GetChildren() do
		local autoDeleteValue = Instance.new("BoolValue")
		autoDeleteValue.Name = Pet.Name
		autoDeleteValue.Value = Data.AutoDelete[Pet.Name] or false
		autoDeleteValue.Parent = AutoDeleteFolder
	end

	-- NonSaveValues (no se guardan, solo para el servidor/cliente)
	local NonSaveFolder = Instance.new("Folder")
	NonSaveFolder.Name = "NonSaveValues"
	NonSaveFolder.Parent = player

	CreateValue("BoolValue", "IsOpeningEgg", false, NonSaveFolder)
	CreateValue("IntValue", "PetsEquipped", PetMultipliers.GetPetsEquipped(player.Name), NonSaveFolder)
	CreateValue("BoolValue", "IsTrading", false, NonSaveFolder)
	CreateValue("BoolValue", "IsReady", false, NonSaveFolder)

	-- Sincronizar cambios de valores con el profile
	DataManager.SetupValueListeners(player, profile)
end

--- Logica de carga de datos
local function PlayerAdded(player)
	local profile = PlayerStore:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile.OnSessionEnd:Connect(function()
			DataManager.Profiles[player] = nil
			player:Kick("Sesion de datos cerrada. Por favor, vuelve a entrar.")
		end)

		if player.Parent == Players then
			DataManager.Profiles[player] = profile
			Initialize(player, profile)

			-- Marcar como cargado
			task.wait(1)
			local Loaded = Instance.new("BoolValue")
			Loaded.Name = "Loaded"
			Loaded.Value = true
			Loaded.Parent = player
		else
			profile:EndSession()
		end
	else
		player:Kick("Error critico al cargar datos.")
	end
end

-- [[ EVENTOS ]] --

for _, player in Players:GetPlayers() do
	task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = DataManager.Profiles[player]
	if profile then
		-- Guardar datos de Pets y AutoDelete antes de cerrar
		DataManager.SaveDynamicData(player, profile)
		profile:EndSession()
		DataManager.Profiles[player] = nil
	end

	-- Limpiar PetMultipliers
	PetMultipliers.RemovePlayer(player.Name)
end)
