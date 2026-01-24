-- In this module you can find things like Rebirth Multiplier. By using code such as Multipliers.RebirthMultiplier(Player) returns a number which is that player's multiplier. Useful if you have multipliers in multiple scripts

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameSettings = require(ReplicatedStorage.Modules.GameSettings)
local PetMultipliers = require(ReplicatedStorage.Modules.PetMultipliers)

local Multipliers = {}

function Multipliers.RebirthMultiplier(Player)
	local Multi = 1

	if GameSettings.RebirthType == "Linear" then
		Multi *= (Player.Data.PlayerData.Rebirth.Value * GameSettings.RebirthMultiplier + 1) -- so multi = RebirthMulti + 1
	else
		Multi *= (GameSettings.RebirthMultiplier + 0.5) ^ Player.Data.PlayerData.Rebirth.Value
	end

	return Multi
end

function Multipliers.CurrencyMultiplier(Player)
	local Multi = GameSettings.CurrencyMultiplier
	Multi *= (Player.Data.Gamepasses.DoubleCurrency.Value and 2 or 1)
	Multi *= Multipliers.RebirthMultiplier(Player)
	Multi *= PetMultipliers.ReadPlayerMultiplier(Player.Name)

	return Multi
end

function Multipliers.GetMaxPetsEquipped(Player)
	return 5 + (Player.Data.Gamepasses["MorePets1"].Value and 3 or 0)
end

function Multipliers.GetMaxPetsStorage(Player)
	return 50 + (Player.Data.Gamepasses["MoreStorage1"].Value and 50 or 0) + (Player.Data.Gamepasses["MoreStorage2"].Value and 250 or 0)
end

function Multipliers.GetLuckMultiplier(Player)
	return 1 * (Player.Data.Gamepasses.Lucky.Value and 2 or 1)
end

return Multipliers