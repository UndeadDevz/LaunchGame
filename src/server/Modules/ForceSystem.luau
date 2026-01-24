--!strict
-- LOCATION: ServerScriptService/Modules/ForceSystem

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForceSystem = {}

-- [ MODULES ]
local PlayerController
local NumberFormatter = require(ReplicatedStorage.Modules.NumberFormatter)

-- [ CONFIGURATION ]
local BASE_PRICE = 100
local PRICE_MULTIPLIER = 1.3
local BASE_FORCE = 1

-- [ HELPER: CUMULATIVE PRICE ]
local function getBulkPrice(currentForce: number, amount: number): number
	local totalPrice = 0
	local tempForce = currentForce

	for i = 1, amount do
		local upgradesBought = math.max(0, tempForce - BASE_FORCE)
		local cost = BASE_PRICE * (PRICE_MULTIPLIER ^ upgradesBought)
		totalPrice += cost
		tempForce += 1
	end

	return math.floor(totalPrice)
end

-- [ INTERNAL: APPLY FORCE ]
local function applyForceUpgrade(player: Player, amount: number, profile: any)
	local currentForce = profile.Data.Force or BASE_FORCE
	local newForce = currentForce + amount
	profile.Data.Force = newForce

	-- Update Leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local forceStat = leaderstats:FindFirstChild("Force")
		if forceStat then
			forceStat.Value = newForce
		end
	end

	-- Refresh UI
	ForceSystem.UpdateClientUI(player)
end

-- [ PUBLIC API ]

-- Called by Client (Money Purchase)
function ForceSystem.PurchaseUpgrade(player: Player, amount: number)
	if amount ~= 1 and amount ~= 5 and amount ~= 10 then return end

	local profile = PlayerController:GetProfile(player)
	if not profile then return end

	local currentForce = profile.Data.Force or BASE_FORCE
	local price = getBulkPrice(currentForce, amount)

	if PlayerController:DeductMoney(player, price) then
		applyForceUpgrade(player, amount, profile)

		local Events = ReplicatedStorage:FindFirstChild("Events")
		local notif = Events and Events:FindFirstChild("ShowNotification")
		if notif then notif:FireClient(player, "+" .. amount .. " Force Upgraded!", "Success") end
	else
		local Events = ReplicatedStorage:FindFirstChild("Events")
		local notif = Events and Events:FindFirstChild("ShowNotification")
		if notif then notif:FireClient(player, "Not enough money!", "Error") end
	end
end

-- Called by MonetizationController (Robux Purchase)
function ForceSystem.GrantForce(player: Player, amount: number)
	local profile = PlayerController:GetProfile(player)
	if not profile then return end

	applyForceUpgrade(player, amount, profile)
end

function ForceSystem.UpdateClientUI(player: Player)
	local profile = PlayerController:GetProfile(player)
	if not profile then return end

	local currentForce = profile.Data.Force or BASE_FORCE

	local priceData = {
		["1"] = getBulkPrice(currentForce, 1),
		["5"] = getBulkPrice(currentForce, 5),
		["10"] = getBulkPrice(currentForce, 10)
	}

	local Events = ReplicatedStorage:FindFirstChild("Events")
	local updateEvent = Events and Events:FindFirstChild("UpdateForceUI")

	if updateEvent then
		updateEvent:FireClient(player, priceData, currentForce)
	end
end

function ForceSystem.GetForce(player: Player): number
	local profile = PlayerController:GetProfile(player)
	if not profile then return BASE_FORCE end
	return profile.Data.Force or BASE_FORCE
end

-- [ INIT ]
function ForceSystem:Init(controllers)
	print("[ForceSystem] Initialized")
	PlayerController = controllers.PlayerController

	local Events = ReplicatedStorage:WaitForChild("Events")

	if not Events:FindFirstChild("PurchaseForce") then
		local re = Instance.new("RemoteEvent"); re.Name = "PurchaseForce"; re.Parent = Events
	end
	if not Events:FindFirstChild("UpdateForceUI") then
		local re = Instance.new("RemoteEvent"); re.Name = "UpdateForceUI"; re.Parent = Events
	end

	Events.PurchaseForce.OnServerEvent:Connect(function(player, amount)
		ForceSystem.PurchaseUpgrade(player, amount)
	end)
end

function ForceSystem:Start()
	local function onPlayerAdded(player)
		task.wait(1)
		ForceSystem.UpdateClientUI(player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, p) end
end

return ForceSystem
