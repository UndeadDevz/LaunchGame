--!strict
local ProductConfigurations = {}

ProductConfigurations.Products = {
	["SkipRebirth"] = 3506794337,--Change
	
	["ItemProduct1"] = 3506831804,--Change
	["ItemProduct2"] = 3506832008,--Change
	["ItemProduct3"] = 3506832254,--Change

	["CashProduct1"] = 3506849309,--Change
	["CashProduct2"] = 3506849459,--Change
	["CashProduct3"] = 3506849720,--Change
	
	["SpeedPlus1"] = 3506884360,--Change
	["SpeedPlus5"] = 3506884534,--Change
	["SpeedPlus10"] = 3506884696,--Change

	["ForcePlus1"] = 3521024791, 
	["ForcePlus5"] = 3521024990, 
	["ForcePlus10"] = 3521025153,

	["CarryUpgrade_Lvl2"] = 3506887975, --Change
	["CarryUpgrade_Lvl3"] = 3506888182,--Change
	["CarryUpgrade_Lvl4"] = 3506888372,--Change
	["CarryUpgrade_Lvl5"] = 3506888680,--Change
	["CarryUpgrade_Lvl6"] = 3506888909,--Change
}

ProductConfigurations.GamePasses = {
	["VIP"] = 1662631309,--Change
	["StarterPack"] = 1663189103,--Change
	["ProPack"] = 1663452898,--Change
}

-- Permanent Products (funcionan como gamepasses pero son developer products)
ProductConfigurations.PermanentProducts = {
	["MoreStorage1"] = 3521275740, 
	["MoreStorage2"] = 3521276232, 
	["MorePets1"] = 3521274764, 
	["TripleEgg"] = 3521275551, 
	["Lucky"] = 3521276969, 
	["AutoEgg"] = 3521276686, 
}

function ProductConfigurations.GetPermanentProductById(id: number)
	for name, productId in pairs(ProductConfigurations.PermanentProducts) do
		if productId == id then return name end
	end
	return nil
end

ProductConfigurations.CarryUpgradeMap = {
	["CarryUpgrade_Lvl2"] = 2,
	["CarryUpgrade_Lvl3"] = 3,
	["CarryUpgrade_Lvl4"] = 4,
	["CarryUpgrade_Lvl5"] = 5,
	["CarryUpgrade_Lvl6"] = 6,
}

ProductConfigurations.PackRewards = {
	["StarterPack"] = {
		Money = 5000,
		Items = {
			{Name = "D1", Mutation = "Normal", Rarity = "Rare", Level = 1},
			{Name = "Zondik", Mutation = "Normal", Rarity = "Rare", Level = 1}
		}
	},
	["ProPack"] = {
		Money = 50000,
		Items = {
			{Name = "HurikZ", Mutation = "Normal", Rarity = "Legendary", Level = 1},
			{Name = "Divviti", Mutation = "Normal", Rarity = "Legendary", Level = 1}
		}
	}
}

ProductConfigurations.ItemProductRewards = {
	["ItemProduct1"] = {Name = "Zondik", Mutation = "Diamond", Rarity = "Rare", Level = 1},
	["ItemProduct2"] = {Name = "HurikZ", Mutation = "Diamond", Rarity = "Legendary", Level = 1},
	["ItemProduct3"] = {Name = "Divviti", Mutation = "Diamond", Rarity = "Legendary", Level = 1},
}

ProductConfigurations.CashProductRewards = {
	["CashProduct1"] = 10000,
	["CashProduct2"] = 100000,
	["CashProduct3"] = 1000000,
}

ProductConfigurations.SpeedProductRewards = {
	["SpeedPlus1"] = 1,
	["SpeedPlus5"] = 5,
	["SpeedPlus10"] = 10,
}

ProductConfigurations.ForceProductRewards = {
	["ForcePlus1"] = 1,
	["ForcePlus5"] = 5,
	["ForcePlus10"] = 10,
}

-- Helper to find name by ID (for the Server Handler)
function ProductConfigurations.GetProductById(id: number)
	for name, productId in pairs(ProductConfigurations.Products) do
		if productId == id then return name end
	end
	return nil
end

function ProductConfigurations.GetGamePassById(id: number)
	for name, passId in pairs(ProductConfigurations.GamePasses) do
		if passId == id then return name end
	end
	return nil
end

return ProductConfigurations