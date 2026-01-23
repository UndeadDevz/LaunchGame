-- Template de datos por defecto para ProfileStore
-- Estos valores se asignan a jugadores nuevos

return {
	-- PlayerData
	Currency = 200,
	Currency2 = 0, -- Gems
	Rebirth = 0,
	Music = true,
	ShowOtherPets = true,
	SpeedLevel = 1,
	BestDistance = 0,

	-- Statistics
	EggsHatched = 0,
	TotalCurrency = 0,

	-- Gem Upgrades
	GemUpgrade1 = 0,
	GemUpgrade2 = 0,

	-- Gamepasses (se verifican con MarketplaceService pero se cachean aqui)
	Gamepasses = {
		DoubleCurrency = false,
		MoreStorage1 = false,
		MoreStorage2 = false,
		MorePets1 = false,
		TripleEgg = false,
		Lucky = false,
		AutoEgg = false,
	},

	-- Pets: tabla de mascotas {[id] = {PetName = string, Equipped = bool}}
	Pets = {},

	-- AutoDelete: tabla de nombres de pets que se eliminan automaticamente
	AutoDelete = {},
}
