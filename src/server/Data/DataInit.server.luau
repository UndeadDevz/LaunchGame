--[[
	DataInit.server.luau
	Inicializa ProfileStore y maneja la carga/guardado de datos de jugadores.
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

-- ProfileStore
local ProfileStore = require(ServerScriptService.Libraries:WaitForChild("ProfileStore"))

local function GetStoreName()
	return RunService:IsStudio() and "CannonGame_Test" or "CannonGame_Live"
end

local Template = require(ServerScriptService.Data.Template)
local DataManager = require(ServerScriptService.Data.DataManager)

-- Acceder a ProfileStore
local PlayerStore = ProfileStore.New(GetStoreName(), Template)

-- Inicializa leaderstats para el jugador
local function Initialize(player: Player, profile)
	-- Leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local Money = Instance.new("IntValue")
	Money.Name = "Money"
	Money.Value = profile.Data.Money
	Money.Parent = leaderstats

	local SpeedLevel = Instance.new("IntValue")
	SpeedLevel.Name = "Speed"
	SpeedLevel.Value = profile.Data.SpeedLevel
	SpeedLevel.Parent = leaderstats

	local Rebirths = Instance.new("IntValue")
	Rebirths.Name = "Rebirths"
	Rebirths.Value = profile.Data.CannonRebirths
	Rebirths.Parent = leaderstats

	-- Sincronizar cambios de datos con leaderstats
	task.spawn(function()
		while player.Parent == Players and DataManager.Profiles[player] do
			Money.Value = profile.Data.Money
			SpeedLevel.Value = profile.Data.SpeedLevel
			Rebirths.Value = profile.Data.CannonRebirths
			task.wait(1)
		end
	end)
end

-- Cuando un jugador entra
local function PlayerAdded(player)
	-- Iniciar sesion de ProfileStore
	local profile = PlayerStore:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	-- Verificar que el perfil existe
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile() -- Llenar datos faltantes con el Template

		-- Manejar fin de sesion
		profile.OnSessionEnd:Connect(function()
			DataManager.Profiles[player] = nil
			player:Kick("Session ended, please rejoin")
		end)

		if player.Parent == Players then
			DataManager.Profiles[player] = profile
			Initialize(player, profile)
			print("[Data] Profile loaded for " .. player.Name)
		else
			profile:EndSession()
		end
	else
		player:Kick("Could not load data, please rejoin")
	end
end

-- Cuando un jugador sale
local function PlayerRemoving(player)
	local profile = DataManager.Profiles[player]
	if profile then
		profile:EndSession()
		DataManager.Profiles[player] = nil
		print("[Data] Profile saved for " .. player.Name)
	end
end

-- Conectar eventos
Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)

-- Procesar jugadores que ya estan (para hot-reload en Studio)
for _, player in Players:GetPlayers() do
	task.spawn(PlayerAdded, player)
end

print("[Data] DataInit loaded successfully!")
