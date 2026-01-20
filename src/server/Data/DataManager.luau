local DataManager = {}

-- Diccionario donde se guardan los perfiles cargados (Player: Profile)
DataManager.Profiles = {}

--- Obtiene el valor de una estadística específica del perfil
function DataManager.GetStat(player: Player, statName: string)
    local profile = DataManager.Profiles[player]
    if profile and profile.Data[statName] ~= nil then
        return profile.Data[statName]
    end
    return nil
end

--- Actualiza una estadística en la data y en leaderstats (si existe el objeto)
function DataManager.UpdateStat(player: Player, statName: string, newValue: any)
    local profile = DataManager.Profiles[player]
    if not profile then return end

    -- Guardar en el perfil de ProfileStore
    profile.Data[statName] = newValue

    -- Sincronizar con la interfaz de leaderstats de Roblox automáticamente
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local statObject = leaderstats:FindFirstChild(statName)
        if statObject then
            statObject.Value = newValue
        end
    end
end

--- Suma una cantidad a una estadística numérica existente
function DataManager.AddStat(player: Player, statName: string, amount: number)
    local profile = DataManager.Profiles[player]
    if profile and profile.Data[statName] ~= nil then
        local currentValue = profile.Data[statName]
        -- Reutiliza UpdateStat para mantener la sincronización con leaderstats
        DataManager.UpdateStat(player, statName, currentValue + amount)
    end
end

return DataManager