local DataManager = {}

-- Diccionario donde se guardan los perfiles cargados (Player: Profile)
DataManager.Profiles = {}

-- Lista de valores de PlayerData que se sincronizan automaticamente
local PlayerDataValues = {
	"Currency", "Rebirth", "Music",
	"ShowOtherPets", "EggsHatched", "TotalCurrency"
}

--- Obtiene el valor de una estadistica especifica del perfil
function DataManager.GetStat(player: Player, statName: string)
	local profile = DataManager.Profiles[player]
	if profile and profile.Data[statName] ~= nil then
		return profile.Data[statName]
	end
	return nil
end

--- Actualiza una estadistica en la data y en leaderstats (si existe el objeto)
function DataManager.UpdateStat(player: Player, statName: string, newValue: any)
	local profile = DataManager.Profiles[player]
	if not profile then return end

	-- Guardar en el perfil de ProfileStore
	profile.Data[statName] = newValue

	-- Sincronizar con la interfaz de leaderstats de Roblox automaticamente
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local statObject = leaderstats:FindFirstChild(statName)
		if statObject then
			statObject.Value = newValue
		end
	end
end

--- Suma una cantidad a una estadistica numerica existente
function DataManager.AddStat(player: Player, statName: string, amount: number)
	local profile = DataManager.Profiles[player]
	if profile and profile.Data[statName] ~= nil then
		local currentValue = profile.Data[statName]
		-- Reutiliza UpdateStat para mantener la sincronizacion con leaderstats
		DataManager.UpdateStat(player, statName, currentValue + amount)
	end
end

--- Configura los listeners para sincronizar cambios de valores con el profile
function DataManager.SetupValueListeners(player: Player, profile)
	local PlayerData = player.Data.PlayerData
	local Gamepasses = player.Data.Gamepasses

	-- Sincronizar valores de PlayerData
	for _, valueName in PlayerDataValues do
		local valueInstance = PlayerData:FindFirstChild(valueName)
		if valueInstance then
			valueInstance.Changed:Connect(function(newValue)
				profile.Data[valueName] = newValue
			end)
		end
	end

	-- Sincronizar valores de Gamepasses
	for _, gpValue in Gamepasses:GetChildren() do
		gpValue.Changed:Connect(function(newValue)
			profile.Data.Gamepasses[gpValue.Name] = newValue
		end)
	end

	-- Sincronizar AutoDelete
	for _, autoDeleteValue in player.Data.AutoDelete:GetChildren() do
		autoDeleteValue.Changed:Connect(function(newValue)
			if newValue then
				profile.Data.AutoDelete[autoDeleteValue.Name] = true
			else
				profile.Data.AutoDelete[autoDeleteValue.Name] = nil
			end
		end)
	end

	-- Sincronizar Pets cuando se agregan/eliminan/modifican
	local PetsFolder = player.Data.Pets

	PetsFolder.ChildAdded:Connect(function(pet)
		local petId = tonumber(pet.Name)
		if petId then
			profile.Data.Pets[petId] = {
				PetName = pet.PetName.Value,
				Equipped = pet.Equipped.Value
			}

			-- Escuchar cambios en Equipped
			pet.Equipped.Changed:Connect(function(newValue)
				if profile.Data.Pets[petId] then
					profile.Data.Pets[petId].Equipped = newValue
				end
			end)
		end
	end)

	PetsFolder.ChildRemoved:Connect(function(pet)
		local petId = tonumber(pet.Name)
		if petId then
			profile.Data.Pets[petId] = nil
		end
	end)

	-- Configurar listeners para pets existentes
	for _, pet in PetsFolder:GetChildren() do
		local petId = tonumber(pet.Name)
		if petId then
			pet.Equipped.Changed:Connect(function(newValue)
				if profile.Data.Pets[petId] then
					profile.Data.Pets[petId].Equipped = newValue
				end
			end)
		end
	end
end

--- Guarda datos dinamicos (Pets, AutoDelete) antes de cerrar sesion
function DataManager.SaveDynamicData(player: Player, profile)
	if not player:FindFirstChild("Data") then return end

	-- Guardar Pets
	profile.Data.Pets = {}
	for _, pet in player.Data.Pets:GetChildren() do
		local petId = tonumber(pet.Name)
		if petId then
			profile.Data.Pets[petId] = {
				PetName = pet.PetName.Value,
				Equipped = pet.Equipped.Value
			}
		end
	end

	-- Guardar AutoDelete
	profile.Data.AutoDelete = {}
	for _, autoDelete in player.Data.AutoDelete:GetChildren() do
		if autoDelete.Value then
			profile.Data.AutoDelete[autoDelete.Name] = true
		end
	end
end

--[[
	DataAccessor Functions
	Wrapper functions for convenient profile data access
--]]

--- Obtiene la tabla Data del perfil del jugador
function DataManager.GetData(player: Player): table?
	local profile = DataManager.Profiles[player]
	return profile and profile.Data
end

--- Guarda el perfil del jugador
function DataManager.SaveData(player: Player)
	local profile = DataManager.Profiles[player]
	if profile then
		profile:Save()
	end
end

--- Obtiene el valor de una key especifica de la data
function DataManager.GetKey(player: Player, key: string): any?
	local data = DataManager.GetData(player)
	return data and data[key]
end

--- Establece el valor de una key especifica en la data
function DataManager.SetKey(player: Player, key: string, value: any)
	local data = DataManager.GetData(player)
	if data then
		data[key] = value
	end
end

return DataManager
