--!strict
-- LOCATION: ServerScriptService/Controllers/MonetizationController

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local MonetizationController = {}

-- [ MODULES ]
local ProductConfigurations = require(ReplicatedStorage.Modules.ProductConfigurations)
local RebirthSystem
local ItemManager
local PlayerController
local SpeedSystem
local ForceSystem
local CarryUpgradeSystem

-- [ ROBUX EGG HELPERS ]
local function GetPet(SelectedEgg)
	local TotalWeight = 0
	for _, v in SelectedEgg:GetChildren() do
		TotalWeight += v.Value
	end

	local Chance = Random.new():NextNumber(0.0001, TotalWeight)
	local Counter = 0

	for _, v in SelectedEgg:GetChildren() do
		Counter += v.Value
		if Counter >= Chance then
			return v.Name
		end
	end
	return nil
end

local function RandomID(Folder)
	local Chance = math.random(1, 10000)
	if Folder:FindFirstChild(tostring(Chance)) then
		return RandomID(Folder)
	end
	return tostring(Chance)
end

local function ProcessRobuxEgg(player, eggName)
	local EggInfo = ReplicatedStorage:FindFirstChild("Eggs") and ReplicatedStorage.Eggs:FindFirstChild(eggName)
	if not EggInfo then return nil end

	local ChosenPet = GetPet(EggInfo.Pets)
	if ChosenPet then
		-- Set opening state
		local nonSaveValues = player:FindFirstChild("NonSaveValues")
		if nonSaveValues and nonSaveValues:FindFirstChild("IsOpeningEgg") then
			nonSaveValues.IsOpeningEgg.Value = true
			task.delay(3, function()
				if nonSaveValues and nonSaveValues:FindFirstChild("IsOpeningEgg") then
					nonSaveValues.IsOpeningEgg.Value = false
				end
			end)
		end

		-- Invoke client for animation
		local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local EggRemote = Remotes and Remotes:FindFirstChild("Egg")
		if EggRemote then
			EggRemote:InvokeClient(player, eggName, ChosenPet, 0)
		end

		-- Create pet in Player.Data.Pets (DataManager syncs to ProfileStore)
		local playerData = player:FindFirstChild("Data")
		local petsFolder = playerData and playerData:FindFirstChild("Pets")
		if petsFolder then
			local Assets = ReplicatedStorage:FindFirstChild("Assets")
			local PetTemplate = Assets and Assets:FindFirstChild("PetTemplate")
			if PetTemplate then
				local NewPet = PetTemplate:Clone()
				NewPet.Name = RandomID(petsFolder)
				NewPet.PetName.Value = ChosenPet
				NewPet.Parent = petsFolder
			end
		end

		return ChosenPet
	end
	return nil
end

function MonetizationController.ProcessReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local productId = receiptInfo.ProductId
	local productName = ProductConfigurations.GetProductById(productId)
	local Events = ReplicatedStorage:FindFirstChild("Events")
	local notif = Events and Events:FindFirstChild("ShowNotification")

	-- 1. REBIRTH SKIP
	if productName == "SkipRebirth" then
		if not RebirthSystem then RebirthSystem = require(ServerScriptService.Modules.RebirthSystem) end
		RebirthSystem.ForceRebirth(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	-- 3. SPEED PRODUCTS
	local speedAmount = ProductConfigurations.SpeedProductRewards[productName]
	if speedAmount then
		if not SpeedSystem then SpeedSystem = require(ServerScriptService.Modules.SpeedSystem) end
		SpeedSystem.GrantSpeed(player, speedAmount)
		if notif then notif:FireClient(player, "+" .. speedAmount .. " Speed Purchased!", "Success") end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- 4. FORCE PRODUCTS
	local forceAmount = ProductConfigurations.ForceProductRewards[productName]
	if forceAmount then
		if not ForceSystem then ForceSystem = require(ServerScriptService.Modules.ForceSystem) end
		ForceSystem.GrantForce(player, forceAmount)
		if notif then notif:FireClient(player, "+" .. forceAmount .. " Force Purchased!", "Success") end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- 5. CARRY UPGRADES
	local targetLevel = ProductConfigurations.CarryUpgradeMap[productName]
	if targetLevel then
		if not CarryUpgradeSystem then CarryUpgradeSystem = require(ServerScriptService.Modules.CarryUpgradeSystem) end

		-- Use the Grant Function
		local success = CarryUpgradeSystem.GrantUpgrade(player, targetLevel)

		if success then
			if notif then notif:FireClient(player, "Carry Capacity Upgraded!", "Success") end
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			-- If they somehow bought an upgrade for a level they already have or isn't next
			-- We grant it anyway to avoid taking money for nothing, or we can handle logic inside GrantUpgrade to force next level
			-- For now, we assume GrantUpgrade handles it gracefully.
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	-- 5. ITEM PRODUCTS
	local itemReward = ProductConfigurations.ItemProductRewards[productName]
	if itemReward then
		if not ItemManager then ItemManager = require(ServerScriptService.Modules.ItemManager) end
		ItemManager.GiveItemToPlayer(player, itemReward.Name, itemReward.Mutation, itemReward.Rarity, itemReward.Level)
		if notif then notif:FireClient(player, itemReward.Name .. " Purchased!", "Success") end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- 6. CASH PRODUCTS
	local cashAmount = ProductConfigurations.CashProductRewards[productName]
	if cashAmount then
		if not PlayerController then PlayerController = require(ServerScriptService.Controllers.PlayerController) end
		PlayerController:AddMoney(player, cashAmount)
		local NumberFormatter = require(ReplicatedStorage.Modules.NumberFormatter)
		if notif then notif:FireClient(player, "$" .. NumberFormatter.Format(cashAmount) .. " Purchased!", "Success") end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- 7. PERMANENT PRODUCTS (Developer Products que funcionan como Gamepasses)
	local permanentName = ProductConfigurations.GetPermanentProductById(productId)
	if permanentName then
		if not PlayerController then PlayerController = require(ServerScriptService.Controllers.PlayerController) end
		PlayerController:SetGamepass(player, permanentName, true)

		if notif then notif:FireClient(player, permanentName .. " Purchased!", "Success") end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- 8. ROBUX EGGS
	local EggsFolder = ReplicatedStorage:FindFirstChild("Eggs")
	if EggsFolder then
		for _, EggInfo in EggsFolder:GetChildren() do
			local ProductIdValue = EggInfo:FindFirstChild("ProductId")
			if ProductIdValue and tonumber(ProductIdValue.Value) == productId then
				local petChosen = ProcessRobuxEgg(player, EggInfo.Name)
				if petChosen then
					return Enum.ProductPurchaseDecision.PurchaseGranted
				end
			end
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationController:Init(controllers)
	print("[MonetizationController] Initialized")
end

function MonetizationController:Start()
	MarketplaceService.ProcessReceipt = MonetizationController.ProcessReceipt
end

return MonetizationController