-- GameSettings Module
-- Contains all game configuration settings

local GameSettings = {
	-- UI Settings
	CurrencySide = "RightSide", -- "LeftSide" or "RightSide"
	ButtonSide = "LeftSide", -- "LeftSide" or "RightSide"

	-- Currency Settings
	CurrencyName = "Coins",
	CurrencyMultiplier = 1,

	-- Rebirth Settings
	RebirthType = "Linear", -- "Linear" or "Exponential"
	RebirthBasePrice = 1000,
	RebirthMultiplier = 1,
}

return GameSettings
