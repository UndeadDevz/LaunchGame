--!strict
-- LOCATION: StarterPlayerScripts/CarryUpgradeController

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Modules
local NumberFormatter = require(ReplicatedStorage.Modules.NumberFormatter)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Assets
local Templates = ReplicatedStorage:WaitForChild("Templates")
local CarryTemplate = Templates:WaitForChild("CarryTemplate")
local Events = ReplicatedStorage:WaitForChild("Events")
local PurchaseEvent = Events:WaitForChild("PurchaseCarry")
local UpdatePricesEvent = Events:WaitForChild("UpdateCarryPrices")

-- UI References
local mainGui = playerGui:WaitForChild("GUI")
local carryFrame = mainGui:WaitForChild("Frames"):WaitForChild("Carry")
local scrolling = carryFrame:WaitForChild("Scrolling")

-- Animation Config
local HOVER_SCALE = 1.05
local CLICK_SCALE = 0.95
local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- State
local uiRefs = {}
local currentRobuxId: number? = nil

print("[CarryUpgradeController] Loaded")

-- [ HELPER: Button Animation ]
local function setupButtonAnimation(button: GuiButton)
	local uiScale = button:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Name = "AnimationScale"
		uiScale.Parent = button
	end

	button.MouseEnter:Connect(function() TweenService:Create(uiScale, TWEEN_INFO, {Scale = HOVER_SCALE}):Play() end)
	button.MouseLeave:Connect(function() TweenService:Create(uiScale, TWEEN_INFO, {Scale = 1}):Play() end)
	button.MouseButton1Down:Connect(function() TweenService:Create(uiScale, TWEEN_INFO, {Scale = CLICK_SCALE}):Play() end)
	button.MouseButton1Up:Connect(function() TweenService:Create(uiScale, TWEEN_INFO, {Scale = HOVER_SCALE}):Play() end)
end

-- [ SETUP UI ]
local function createUI()
	local template = CarryTemplate:Clone()
	template.Name = "CarryUpgrade"
	template.Parent = scrolling
	template.Visible = true

	local mainLabel = template:FindFirstChild("Text") :: TextLabel
	if mainLabel then mainLabel.Text = "+1 Carry" end

	-- Buttons
	local moneyBtn = nil
	local robuxBtn = nil
	local buttonsFrame = template:FindFirstChild("Buttons")

	if buttonsFrame then
		moneyBtn = buttonsFrame:FindFirstChild("Money") :: TextButton
		robuxBtn = buttonsFrame:FindFirstChild("Robux") :: TextButton
	else
		moneyBtn = template:FindFirstChild("Money") :: TextButton
		robuxBtn = template:FindFirstChild("Robux") :: TextButton
	end

	-- Setup Money
	local priceLabel = nil
	if moneyBtn then
		priceLabel = moneyBtn:FindFirstChild("Text") :: TextLabel
		setupButtonAnimation(moneyBtn)
		moneyBtn.MouseButton1Click:Connect(function() PurchaseEvent:FireServer() end)
	end

	-- Setup Robux
	local robuxPriceLabel = nil
	if robuxBtn then
		robuxPriceLabel = robuxBtn:FindFirstChild("Text") :: TextLabel
		setupButtonAnimation(robuxBtn)
		robuxBtn.MouseButton1Click:Connect(function()
			if currentRobuxId then
				MarketplaceService:PromptProductPurchase(player, currentRobuxId)
			end
		end)
	end

	-- Stats
	local beforeLabel = nil
	local afterLabel = nil
	local statsFrame = template:FindFirstChild("Stats")
	if statsFrame then
		local beforeFrame = statsFrame:FindFirstChild("Before")
		local afterFrame = statsFrame:FindFirstChild("After")
		if beforeFrame then beforeLabel = beforeFrame:FindFirstChild("Text") :: TextLabel end
		if afterFrame then afterLabel = afterFrame:FindFirstChild("Text") :: TextLabel end
	end

	uiRefs = {
		MoneyBtn = moneyBtn,
		RobuxBtn = robuxBtn,
		PriceLabel = priceLabel,
		RobuxPriceLabel = robuxPriceLabel,
		BeforeLabel = beforeLabel,
		AfterLabel = afterLabel
	}
end

-- [ UPDATES ]

local function updateUI(data: {Current: number, NextPrice: number?, NextRobuxId: number?, IsMax: boolean})
	-- 1. Stats
	if uiRefs.BeforeLabel then uiRefs.BeforeLabel.Text = tostring(data.Current) end
	if uiRefs.AfterLabel then
		if data.IsMax then uiRefs.AfterLabel.Text = "MAX" else uiRefs.AfterLabel.Text = tostring(data.Current + 1) end
	end

	-- 2. Money Button
	if uiRefs.PriceLabel and uiRefs.MoneyBtn then
		if data.IsMax then
			uiRefs.PriceLabel.Text = "SOLD OUT"
			uiRefs.MoneyBtn.Active = false
			uiRefs.MoneyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		else
			uiRefs.PriceLabel.Text = "$" .. NumberFormatter.Format(data.NextPrice or 0)
			uiRefs.MoneyBtn.Active = true
			uiRefs.MoneyBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
		end
	end

	-- 3. Robux Button (FIXED LOGIC)
	if uiRefs.RobuxPriceLabel and uiRefs.RobuxBtn then
		if data.IsMax then
			-- PLAYER IS MAX LEVEL
			uiRefs.RobuxPriceLabel.Text = "MAX"
			uiRefs.RobuxBtn.Active = false
			uiRefs.RobuxBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			currentRobuxId = nil

		elseif not data.NextRobuxId then
			-- CONFIG IS MISSING (DEVELOPER ERROR)
			uiRefs.RobuxPriceLabel.Text = "N/A"
			uiRefs.RobuxBtn.Active = false
			uiRefs.RobuxBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			currentRobuxId = nil

		else
			-- PRODUCT IS AVAILABLE
			currentRobuxId = data.NextRobuxId
			uiRefs.RobuxBtn.Active = true
			uiRefs.RobuxBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)

			task.spawn(function()
				local success, info = pcall(function()
					return MarketplaceService:GetProductInfo(data.NextRobuxId, Enum.InfoType.Product)
				end)

				if currentRobuxId == data.NextRobuxId then -- Check if ID changed while fetching
					if success and info then
						uiRefs.RobuxPriceLabel.Text = "" .. tostring(info.PriceInRobux)
					else
						uiRefs.RobuxPriceLabel.Text = "N/A"
					end
				end
			end)
		end
	end
end

-- [ INIT ]

createUI()
UpdatePricesEvent.OnClientEvent:Connect(updateUI)