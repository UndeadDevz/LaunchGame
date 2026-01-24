--!strict
-- LOCATION: StarterPlayerScripts/SpeedController

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService") -- ## ADDED ##

-- Modules
local NumberFormatter = require(ReplicatedStorage.Modules.NumberFormatter)
local ProductConfigurations = require(ReplicatedStorage.Modules.ProductConfigurations) -- ## ADDED ##

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Assets
local Templates = ReplicatedStorage:WaitForChild("Templates")
local SpeedTemplate = Templates:WaitForChild("SpeedTemplate")
local Events = ReplicatedStorage:WaitForChild("Events")

local PurchaseEvent = Events:WaitForChild("PurchaseSpeed")
local UpdateEvent = Events:WaitForChild("UpdateSpeedUI") 

-- UI References
local mainGui = playerGui:WaitForChild("GUI")
local speedFrame = mainGui:WaitForChild("Frames"):WaitForChild("Speed")
local scrolling = speedFrame:WaitForChild("Scrolling")
local hudLabel = mainGui:WaitForChild("HUD"):WaitForChild("Labels"):WaitForChild("Speed") :: TextLabel

-- Animation Config
local HOVER_SCALE = 1.05
local CLICK_SCALE = 0.95
local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- State
local options = {} 

print("[SpeedController] Loaded")

-- [ HELPER: Button Animation ]
local function setupButtonAnimation(button: GuiButton)
	local uiScale = button:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale"); uiScale.Name = "AnimationScale"; uiScale.Parent = button
	end
	button.MouseEnter:Connect(function() TweenService:Create(uiScale, TWEEN_INFO, {Scale = HOVER_SCALE}):Play() end)
	button.MouseLeave:Connect(function() TweenService:Create(uiScale, TWEEN_INFO, {Scale = 1}):Play() end)
	button.MouseButton1Down:Connect(function() TweenService:Create(uiScale, TWEEN_INFO, {Scale = CLICK_SCALE}):Play() end)
	button.MouseButton1Up:Connect(function() TweenService:Create(uiScale, TWEEN_INFO, {Scale = HOVER_SCALE}):Play() end)
end

-- [ HELPER: Find Text Label ]
local function findTextLabel(parent: Instance): TextLabel?
	local label = parent:FindFirstChild("Text")
	if label and label:IsA("TextLabel") then return label end
	return parent:FindFirstChildWhichIsA("TextLabel", true)
end

-- [ SETUP UI ]
local function createOption(amount: number)
	local template = SpeedTemplate:Clone()
	template.Name = "Option_" .. amount
	template.Parent = scrolling
	template.Visible = true

	-- 1. Setup Speed Amount Text
	local amountLabel = template:FindFirstChild("Text") :: TextLabel
	if amountLabel then amountLabel.Text = "+" .. amount .. " Speed" end

	local btnContainer = template:FindFirstChild("Buttons")
	if not btnContainer then return end

	-- 2. Setup MONEY Button
	local moneyBtn = btnContainer:FindFirstChild("Money") :: TextButton
	local moneyPriceLabel = nil

	if moneyBtn then
		moneyPriceLabel = findTextLabel(moneyBtn)
		setupButtonAnimation(moneyBtn)
		moneyBtn.MouseButton1Click:Connect(function()
			PurchaseEvent:FireServer(amount) 
		end)
	end

	-- 3. ## ADDED: Setup ROBUX Button ##
	local robuxBtn = btnContainer:FindFirstChild("Robux") :: TextButton

	if robuxBtn then
		setupButtonAnimation(robuxBtn)

		-- Determine Product ID based on amount
		local productKey = "SpeedPlus" .. amount
		local productId = ProductConfigurations.Products[productKey]

		if productId then
			-- A. Click Event
			robuxBtn.MouseButton1Click:Connect(function()
				MarketplaceService:PromptProductPurchase(player, productId)
			end)

			-- B. Fetch Price Async
			task.spawn(function()
				local robuxPriceLabel = findTextLabel(robuxBtn)
				if robuxPriceLabel then
					local success, info = pcall(function()
						return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
					end)
					if success and info then
						robuxPriceLabel.Text = "" .. tostring(info.PriceInRobux)
					else
						robuxPriceLabel.Text = "N/A"
					end
				end
			end)
		else
			warn("Missing Product ID for " .. productKey)
		end
	end

	-- 4. Setup Stats
	local statsFrame = template:FindFirstChild("Stats")
	local beforeFrame = statsFrame and statsFrame:FindFirstChild("Before")
	local afterFrame = statsFrame and statsFrame:FindFirstChild("After")

	local beforeLabel = beforeFrame and beforeFrame:FindFirstChild("Text") :: TextLabel
	local afterLabel = afterFrame and afterFrame:FindFirstChild("Text") :: TextLabel

	-- 5. Store References (Only storing Money Label for updating, Robux price is static)
	options[amount] = {
		MoneyPriceLabel = moneyPriceLabel,
		BeforeLabel = beforeLabel,
		AfterLabel = afterLabel
	}
end

-- [ UPDATES ]
local function onServerUpdate(prices: {[string]: number}, currentSpeed: number)
	if hudLabel then
		hudLabel.Text = "Speed: " .. NumberFormatter.Format(currentSpeed)
	end

	for amount, references in pairs(options) do
		-- Update Money Price
		local price = prices[tostring(amount)]
		if price and references.MoneyPriceLabel then
			references.MoneyPriceLabel.Text = "$" .. NumberFormatter.Format(price)
		end

		-- Update Stats
		if references.BeforeLabel then
			references.BeforeLabel.Text = tostring(currentSpeed)
		end

		if references.AfterLabel then
			references.AfterLabel.Text = tostring(currentSpeed + amount)
		end
	end
end

-- [ INIT ]
for _, child in ipairs(scrolling:GetChildren()) do
	if child:IsA("Frame") then child:Destroy() end
end

createOption(1)
createOption(5)
createOption(10)

UpdateEvent.OnClientEvent:Connect(onServerUpdate)

-- Initial Safety Check
task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats then
		local speedStat = leaderstats:WaitForChild("Speed") :: IntValue
		if hudLabel then hudLabel.Text = "Speed: " .. NumberFormatter.Format(speedStat.Value) end
	end
end)