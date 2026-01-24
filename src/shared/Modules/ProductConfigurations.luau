--!strict
local ProductConfigurations = {}

ProductConfigurations.Products = {
	["SkipRebirth"] = 3506794337,
	
	["ItemProduct1"] = 3506831804,
	["ItemProduct2"] = 3506832008,
	["ItemProduct3"] = 3506832254,

	["CashProduct1"] = 3506849309,
	["CashProduct2"] = 3506849459,
	["CashProduct3"] = 3506849720,
	
	["SpeedPlus1"] = 3506884360,
	["SpeedPlus5"] = 3506884534,
	["SpeedPlus10"] = 3506884696,

	["ForcePlus1"] = 0, -- TODO: Reemplazar con ID real de DevProduct
	["ForcePlus5"] = 0, -- TODO: Reemplazar con ID real de DevProduct
	["ForcePlus10"] = 0, -- TODO: Reemplazar con ID real de DevProduct

	["CarryUpgrade_Lvl2"] = 3506887975, 
	["CarryUpgrade_Lvl3"] = 3506888182,
	["CarryUpgrade_Lvl4"] = 3506888372,
	["CarryUpgrade_Lvl5"] = 3506888680,
	["CarryUpgrade_Lvl6"] = 3506888909,
}

ProductConfigurations.GamePasses = {
	["VIP"] = 1662631309,
	["StarterPack"] = 1663189103,
	["ProPack"] = 1663452898,
}

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