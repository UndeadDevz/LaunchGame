-- Multipliers module - reads gamepass data from Player attributes
local Multipliers = {}

function Multipliers.GetMaxPetsEquipped(Player)
	return 5 + (Player:GetAttribute("MorePets1") and 3 or 0)
end

function Multipliers.GetMaxPetsStorage(Player)
	local base = 50
	local storage1 = Player:GetAttribute("MoreStorage1") and 50 or 0
	local storage2 = Player:GetAttribute("MoreStorage2") and 250 or 0
	return base + storage1 + storage2
end

function Multipliers.GetLuckMultiplier(Player)
	return Player:GetAttribute("Lucky") and 2 or 1
end

function Multipliers.HasTripleEgg(Player)
	return Player:GetAttribute("TripleEgg") == true
end

function Multipliers.HasAutoEgg(Player)
	return Player:GetAttribute("AutoEgg") == true
end

return Multipliers
