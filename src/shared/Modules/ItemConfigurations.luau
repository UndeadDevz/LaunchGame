--!strict
-- LOCATION: ReplicatedStorage/Modules/ItemConfigurations

local ItemConfigurations = {}

-- Definition of Item Data
-- Income: Money per second (Base)
-- ImageId: Texture for GUI (CarrySystem & Inventory)
ItemConfigurations.Items = {
	-- [ Commons ] --
	["Gulf"] =      { Rarity = "Common", Income = 1, ImageId = "rbxassetid://90767557777381" },
	["Supre"] =     { Rarity = "Common", Income = 2, ImageId = "rbxassetid://73047039829998" },
	["BimmerN2"] =  { Rarity = "Common", Income = 3, ImageId = "rbxassetid://129917729206391" },
	["Curvett"] =   { Rarity = "Common", Income = 5, ImageId = "rbxassetid://88676686080774" },
	["TuboS"] =     { Rarity = "Common", Income = 7, ImageId = "rbxassetid://111954243468429" },

	-- [ Uncommons ] --
	["GTI40"] =     { Rarity = "Uncommon", Income = 10, ImageId = "rbxassetid://129986679696131" },
	["RS3GT"] =     { Rarity = "Uncommon", Income = 15, ImageId = "rbxassetid://110784612898637" },
	["Avetedor"] =  { Rarity = "Uncommon", Income = 20, ImageId = "rbxassetid://112818028086384" },

	-- [ Rares ] --
	["D1"] =        { Rarity = "Rare", Income = 35, ImageId = "rbxassetid://99802542369505" },
	["Zondik"] =    { Rarity = "Rare", Income = 45, ImageId = "rbxassetid://75363278973071" },
	["ZondikR"] =   { Rarity = "Rare", Income = 55, ImageId = "rbxassetid://88709937089474" },

	-- [ Epics ] --
	["W2"] =        { Rarity = "Epic", Income = 100, ImageId = "rbxassetid://109107053166528" },
	["Hurik"] =     { Rarity = "Epic", Income = 125, ImageId = "rbxassetid://123829963674376" },
	["Agro"] =      { Rarity = "Epic", Income = 150, ImageId = "rbxassetid://113126526170241" },

	-- [ Legendaries ] --
	["HurikZ"] =    { Rarity = "Legendary", Income = 300, ImageId = "rbxassetid://117853850221110" },
	["Jergo"] =     { Rarity = "Legendary", Income = 350, ImageId = "rbxassetid://73837965197045" },
	["Divviti"] =   { Rarity = "Legendary", Income = 400, ImageId = "rbxassetid://73963296270840" },

	-- [ Mythicals ] --
	["Tribitti"] =  { Rarity = "Mythical", Income = 1000, ImageId = "rbxassetid://120437385397863" },
	["Spali"] =     { Rarity = "Mythical", Income = 1250, ImageId = "rbxassetid://107514259271488" },
}

-- Returns a list of Item Names (Strings) for the Spawner logic
function ItemConfigurations.GetItemsByRarity(rarity: string): {string}
	local foundItems = {}
	for itemName, data in pairs(ItemConfigurations.Items) do
		if data.Rarity == rarity then
			table.insert(foundItems, itemName)
		end
	end
	return foundItems
end

-- Helper to get the full data for a specific item
function ItemConfigurations.GetItemData(itemName: string)
	return ItemConfigurations.Items[itemName]
end

return ItemConfigurations