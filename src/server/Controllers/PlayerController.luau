--!strict
-- LOCATION: ServerScriptService/Controllers/PlayerController

-- Services
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")

-- Modules
local ProfileStoreModule = require(ServerScriptService.Libraries.ProfileStore)
local ItemConfigurations = require(ReplicatedStorage.Modules.ItemConfigurations)
local ProductConfigurations = require(ReplicatedStorage.Modules.ProductConfigurations)
local NumberFormatter = require(ReplicatedStorage.Modules.NumberFormatter)
local ItemManager -- Lazy load
local SlotManager -- Lazy load

-- [ CONFIGURATION ]
local DATA_VERSION = "ProjectData_v19" 

local MAX_OFFLINE_TIME = 8 * 60 * 60 -- 8 Hours
local INCOME_SCALING = 1.125 
local VIP_TAG = "V.I.P" -- Tag for VIP parts

local MUTATION_MULTIPLIERS = {
	["Normal"] = 1,
	["Golden"] = 2,
	["Diamond"] = 3,
	["Ruby"] = 4,
	["Neon"] = 5,
}

-- Data Types
type ItemData = { Name: string, Mutation: string, Rarity: string, Level: number }
type SlotData = { Item: ItemData?, Level: number, Stored: number }
type FloorData = { [string]: SlotData }

type PlayerData = {
	Money: number,
	Speed: number,
	MaxCarry: number,
	Rebirths: number,
	BaseLevel: number,
	LastSaveTime: number,
	Inventory: {ItemData},
	Plots: { [string]: FloorData },
	DiscoveredItems: {[string]: boolean},
	ClaimedPacks: {[string]: boolean}
}

-- [ DATA TEMPLATE ]
local Template: PlayerData = {
	Money = 0,
	Speed = 10,      
	MaxCarry = 1,    
	Rebirths = 0,
	BaseLevel = 0,
	LastSaveTime = 0,
	Inventory = {},
	Plots = { Floor1 = {}, Floor2 = {}, Floor3 = {} },
	DiscoveredItems = {},
	ClaimedPacks = {}
}

local GameProfileStore = ProfileStoreModule.New(DATA_VERSION, Template)

local PlayerController = {}
local profiles: {[Player]: any} = {}
local vipCache: {[Player]: boolean} = {}
local deadPlayers: {[Player]: boolean} = {} -- ## ADDED: Track Death State ##

PlayerController.isShuttingDown = false

-- [ HELPER: GRANT PACK ]
local function grantPackRewards(player: Player, packName: string)
	local profile = profiles[player]
	if not profile then return end

	-- Check if already claimed
	if profile.Data.ClaimedPacks[packName] then return end

	local rewards = ProductConfigurations.PackRewards[packName]
	if not rewards then return end

	-- Mark as claimed immediately
	profile.Data.ClaimedPacks[packName] = true

	-- Give Money
	PlayerController:AddMoney(player, rewards.Money)

	-- Give Items
	if ItemManager then
		for _, item in ipairs(rewards.Items) do
			ItemManager.GiveItemToPlayer(player, item.Name, item.Mutation, item.Rarity, item.Level)
		end
	end

	-- Notify
	local Events = ReplicatedStorage:FindFirstChild("Events")
	local notif = Events and Events:FindFirstChild("ShowNotification")
	if notif then 
		notif:FireClient(player, packName .. " Redeemed!", "Success") 
	end

	print("[PlayerController] Granted Pack: " .. packName .. " to " .. player.Name)
end

-- [ VIP HELPER FUNCTIONS ]
function PlayerController:IsVIP(player: Player)
	return vipCache[player] == true
end

local function checkVIP(player: Player)
	local passId = ProductConfigurations.GamePasses.VIP
	if not passId then return end

	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)

	if success and hasPass then
		vipCache[player] = true
	end
end

-- [ TOUCH PROMPT LOGIC ]
local function setupVIPTouch(part: BasePart)
	if part:GetAttribute("TouchConnected") then return end
	part:SetAttribute("TouchConnected", true)

	part.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and not vipCache[player] then
			if not player.Character:GetAttribute("PromptDebounce") then
				player.Character:SetAttribute("PromptDebounce", true)
				local passId = ProductConfigurations.GamePasses.VIP
				if passId then
					MarketplaceService:PromptGamePassPurchase(player, passId)
				end
				task.wait(2)
				if player.Character then player.Character:SetAttribute("PromptDebounce", nil) end
			end
		end
	end)
end

-- [ HELPERS ] ------------------------------------------------

local function calculateOfflineEarnings(player: Player, profile: any)
	local lastTime = profile.Data.LastSaveTime
	if not lastTime or lastTime == 0 then return end

	local now = os.time()
	local diff = now - lastTime

	if diff < 60 then return end 

	local timeToCalc = math.min(diff, MAX_OFFLINE_TIME)
	local totalEarned = 0

	for floorName, floorData in pairs(profile.Data.Plots) do
		for slotName, slotData in pairs(floorData) do
			if slotData.Item then
				local itemConf = ItemConfigurations.GetItemData(slotData.Item.Name)
				if itemConf then
					local base = itemConf.Income
					local mutMult = MUTATION_MULTIPLIERS[slotData.Item.Mutation] or 1
					local level = slotData.Level or 1
					local levelMult = INCOME_SCALING ^ (level - 1)
					local reb = profile.Data.Rebirths or 0
					local rebMult = 1 + (reb * 0.5)

					local rate = base * mutMult * levelMult * rebMult
					local earnings = rate * timeToCalc

					if type(slotData.Stored) ~= "number" then slotData.Stored = 0 end
					slotData.Stored += earnings
					totalEarned += earnings
				end
			end
		end
	end

	if totalEarned > 0 then
		task.delay(4, function() 
			if player and player.Parent then
				local events = ReplicatedStorage:FindFirstChild("Events")
				local notif = events and events:FindFirstChild("ShowNotification")
				if notif then
					notif:FireClient(player, "Collect your offline earnings!", "Success")
				end
			end
		end)
	end
end

-- [ CONTROLLER METHODS ] -------------------------------------

function PlayerController:GetProfile(player: Player) return profiles[player] end

function PlayerController:DeductMoney(player: Player, amount: number): boolean
	local profile = profiles[player]
	if not profile then return false end
	if profile.Data.Money >= amount then
		profile.Data.Money -= amount
		player.leaderstats.Money.Value = profile.Data.Money
		return true
	end
	return false
end

function PlayerController:AddMoney(player: Player, amount: number)
	local profile = profiles[player]
	if profile then
		profile.Data.Money += amount
		player.leaderstats.Money.Value = profile.Data.Money
	end
end

function PlayerController:IncrementBaseLevel(player: Player)
	local profile = profiles[player]
	if profile then profile.Data.BaseLevel += 1; return profile.Data.BaseLevel end
	return 0
end

function PlayerController:SetupSharedInstances()
	local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
	if not eventsFolder then 
		eventsFolder = Instance.new("Folder"); eventsFolder.Name = "Events"; eventsFolder.Parent = ReplicatedStorage
	end
	local function createRemote(type: "RemoteEvent", name: string)
		if not eventsFolder:FindFirstChild(name) then
			local r = Instance.new(type); r.Name = name; r.Parent = eventsFolder
		end
	end
	createRemote("RemoteEvent", "ShowNotification") 
	createRemote("RemoteEvent", "RequestBaseUpgrade")
	createRemote("RemoteEvent", "RequestRebirth")
	createRemote("RemoteEvent", "UpdateRebirthUI")
	createRemote("RemoteEvent", "RefreshIndex")
end

-- [ INVENTORY LOGIC ] ------------------------------------------------

-- Helper: Converts a Tool instance to Data Table
local function toolToData(tool: Tool): ItemData?
	local name = tool:GetAttribute("OriginalName")
	if name then
		return {
			Name = name,
			Mutation = tool:GetAttribute("Mutation") or "Normal",
			Rarity = tool:GetAttribute("Rarity") or "Common",
			Level = tool:GetAttribute("Level") or 1
		}
	end
	return nil
end

-- ## LIVE SYNC LOGIC ##
local function syncInventoryData(player: Player)
	local profile = profiles[player]
	if not profile then return end

	-- ## CRITICAL FIX ## 
	-- If player is flagged as dead, STOP. 
	-- This prevents saving an empty backpack when Roblox destroys tools on death.
	if deadPlayers[player] then
		return 
	end

	local inventoryData = {}

	-- Scan Backpack
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") then
				local data = toolToData(item)
				if data then table.insert(inventoryData, data) end
			end
		end
	end

	-- Scan Equipped
	if player.Character then
		local equipped = player.Character:FindFirstChildWhichIsA("Tool")
		if equipped then
			local data = toolToData(equipped)
			if data then table.insert(inventoryData, data) end
		end
	end

	profile.Data.Inventory = inventoryData
end

local function loadInventory(player: Player, profile: any)
	if not ItemManager then return end

	-- Reset death flag on load
	deadPlayers[player] = false

	-- Clear existing backpack first to prevent dupes
	local backpack = player:FindFirstChild("Backpack")
	if backpack then backpack:ClearAllChildren() end

	local savedInv = profile.Data.Inventory or {}
	for _, itemData in ipairs(savedInv) do
		ItemManager.GiveItemToPlayer(player, itemData.Name, itemData.Mutation, itemData.Rarity, itemData.Level)
	end
end

local function createLeaderstats(player: Player, data: PlayerData)
	local ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = player
	local m = Instance.new("IntValue"); m.Name = "Money"; m.Value = data.Money; m.Parent = ls
	local s = Instance.new("IntValue"); s.Name = "Speed"; s.Value = data.Speed; s.Parent = ls
	local r = Instance.new("IntValue"); r.Name = "Rebirths"; r.Value = data.Rebirths; r.Parent = ls

	m.Changed:Connect(function(v) data.Money = v end)
	s.Changed:Connect(function(v) data.Speed = v end)
	r.Changed:Connect(function(v) data.Rebirths = v end)
end

-- [ PLAYER ADDED ]
local function onPlayerAdded(player: Player)
	checkVIP(player)

	-- Initialize Death Flag
	deadPlayers[player] = false

	local profile = GameProfileStore:StartSessionAsync(tostring(player.UserId), {
		Cancel = function() return player.Parent ~= Players end
	})

	if not profile then 
		warn("[PlayerController] FAILED to load profile for:", player.Name)
		player:Kick("Data load failed. Please rejoin.") 
		return 
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile() 

	if profile.Data.DiscoveredItems == nil then profile.Data.DiscoveredItems = {} end
	if profile.Data.ClaimedPacks == nil then profile.Data.ClaimedPacks = {} end

	profile.OnSessionEnd:Connect(function() 
		profiles[player] = nil
		player:Kick("Session released") 
	end)

	if player.Parent == Players then
		profiles[player] = profile
		createLeaderstats(player, profile.Data)

		-- ## INVENTORY TRACKING SETUP ##
		local function setupBackpackTracking(backpack: Backpack)
			-- Sync immediately when something is added
			backpack.ChildAdded:Connect(function() syncInventoryData(player) end)
			-- Sync when removed (only if not dead)
			backpack.ChildRemoved:Connect(function() syncInventoryData(player) end)
		end
		local bp = player:WaitForChild("Backpack")
		setupBackpackTracking(bp)

		-- ## CHARACTER LIFECYCLE ##
		player.CharacterAdded:Connect(function(char)
			-- Reset flag
			deadPlayers[player] = false

			-- Load items
			task.wait(0.2)
			loadInventory(player, profile)

			-- Listen for DEATH to prevent wiping inventory
			local hum = char:WaitForChild("Humanoid", 10)
			if hum then
				hum.Died:Connect(function()
					deadPlayers[player] = true
					print("[PlayerController] Player died. Inventory sync paused.")
				end)
			end

			-- Listen for tool swaps
			char.ChildAdded:Connect(function(child) if child:IsA("Tool") then syncInventoryData(player) end end)
			char.ChildRemoved:Connect(function(child) if child:IsA("Tool") then syncInventoryData(player) end end)
		end)

		-- Initial Load
		if player.Character then
			deadPlayers[player] = false
			loadInventory(player, profile)

			local hum = player.Character:FindFirstChild("Humanoid")
			if hum then
				hum.Died:Connect(function() deadPlayers[player] = true end)
			end
		end

		task.spawn(function()
			for packName, passId in pairs(ProductConfigurations.GamePasses) do
				if packName == "StarterPack" or packName == "ProPack" then
					if not profile.Data.ClaimedPacks[packName] then
						local success, hasPass = pcall(function()
							return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
						end)
						if success and hasPass then
							grantPackRewards(player, packName)
						end
					end
				end
			end
		end)

		calculateOfflineEarnings(player, profile)
	else
		profile:EndSession()
	end
end

local function onPlayerRemoving(player: Player)
	vipCache[player] = nil
	deadPlayers[player] = nil -- Clean up

	local profile = profiles[player]
	if profile then 
		-- Force a final sync ignoring death flag (saving whatever is currently valid)
		-- Note: We rely on syncInventoryData's checks usually, but on exit we save whatever we have.
		profile.Data.LastSaveTime = os.time()
		profile:EndSession()
		profiles[player] = nil 
	end
end

function PlayerController:Init(controllers)
	local Modules = ServerScriptService:WaitForChild("Modules")
	ItemManager = require(Modules:WaitForChild("ItemManager"))
	SlotManager = require(Modules:WaitForChild("SlotManager"))
	if SlotManager.Init then SlotManager:Init(controllers) end

	local Events = ReplicatedStorage:WaitForChild("Events")
	local getIndexFunc = Events:FindFirstChild("GetIndexData")
	if not getIndexFunc then
		getIndexFunc = Instance.new("RemoteFunction")
		getIndexFunc.Name = "GetIndexData"
		getIndexFunc.Parent = Events
	end

	getIndexFunc.OnServerInvoke = function(player)
		local profile = PlayerController:GetProfile(player)
		if profile then return profile.Data.DiscoveredItems or {} end
		return {}
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
		if wasPurchased then
			if passId == ProductConfigurations.GamePasses.VIP then
				vipCache[player] = true
				local notif = Events:FindFirstChild("ShowNotification")
				if notif then notif:FireClient(player, "VIP Purchased! x1.25 Cash Active!", "Success") end
			end

			local packName = ProductConfigurations.GetGamePassById(passId)
			if packName and (packName == "StarterPack" or packName == "ProPack") then
				grantPackRewards(player, packName)
			end
		end
	end)

	for _, part in ipairs(CollectionService:GetTagged(VIP_TAG)) do
		if part:IsA("BasePart") then
			setupVIPTouch(part)
		end
	end

	CollectionService:GetInstanceAddedSignal(VIP_TAG):Connect(function(part)
		if part:IsA("BasePart") then
			setupVIPTouch(part)
		end
	end)
end

function PlayerController:Start()
	if SlotManager.Start then task.spawn(function() SlotManager:Start() end) end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, p) end

	game:BindToClose(function()
		PlayerController.isShuttingDown = true
		for _, p in ipairs(Players:GetPlayers()) do
			if profiles[p] then 
				profiles[p].Data.LastSaveTime = os.time()
			end
		end
	end)
end

return PlayerController