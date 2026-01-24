--!strict
-- LOCATION: StarterPlayerScripts/RebirthUIController

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- [ MODULES ]
local ProductConfigurations = require(ReplicatedStorage.Modules.ProductConfigurations)

-- [ ASSETS ]
local Events = ReplicatedStorage:WaitForChild("Events")
local RequestRebirth = Events:WaitForChild("RequestRebirth")
local UpdateEvent = Events:WaitForChild("UpdateRebirthUI")

-- [ UI REFERENCES ]
local gui = playerGui:WaitForChild("GUI")
local hud = gui:WaitForChild("HUD")
local hudLeft = hud:WaitForChild("Left")

-- 1. HUD Button Notification Dot
local hudRebirthBtn = hudLeft:WaitForChild("Rebirth") :: TextButton
local notificationDot = hudRebirthBtn:WaitForChild("Notification") :: Frame

-- 2. Rebirth Menu Frames
local frames = gui:WaitForChild("Frames")
local rebirthFrame = frames:WaitForChild("Rebirth")

local statsFrame = rebirthFrame:WaitForChild("Stats")
local beforeLabel = statsFrame:WaitForChild("Before"):WaitForChild("Money"):WaitForChild("Text") :: TextLabel
local afterLabel = statsFrame:WaitForChild("After"):WaitForChild("Money"):WaitForChild("Text") :: TextLabel

local barFrame = rebirthFrame:WaitForChild("Bar")
local progressFill = barFrame:WaitForChild("Progress") :: Frame
local progressText = barFrame:WaitForChild("Text") :: TextLabel

local rebirthButton = rebirthFrame:FindFirstChild("RebirthButton") :: GuiButton
local skipButton = rebirthFrame:FindFirstChild("SkipButton") :: GuiButton

-- [ CONFIG ]
local BASE_SPEED_COST = 40
local TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- [ HELPER ]
local function getRebirthCost(rebirths: number): number
	return BASE_SPEED_COST * (2 ^ rebirths)
end

-- [ LOGIC ]
local function updateUI()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local speed = leaderstats:WaitForChild("Speed").Value
	local rebirths = leaderstats:WaitForChild("Rebirths").Value

	-- 1. Calculate Values
	local cost = getRebirthCost(rebirths)
	local currentMult = 1 + (rebirths * 0.5)
	local nextMult = 1 + ((rebirths + 1) * 0.5)

	-- 2. Update Multiplier Text
	beforeLabel.Text = "x" .. string.format("%.1f", currentMult)
	afterLabel.Text = "x" .. string.format("%.1f", nextMult)

	-- 3. Update Progress Bar
	local percentage = math.clamp(speed / cost, 0, 1)

	progressText.Text = "Speed " .. tostring(speed) .. "/" .. tostring(cost)
	TweenService:Create(progressFill, TWEEN_INFO, {Size = UDim2.fromScale(percentage, 1)}):Play()

	-- 4. [NEW] Update Notification Dot on HUD
	if speed >= cost then
		notificationDot.Visible = true
	else
		notificationDot.Visible = false
	end
end

-- [ CONNECTIONS ]

if rebirthButton then
	rebirthButton.MouseButton1Click:Connect(function()
		RequestRebirth:FireServer()
	end)
end

if skipButton then
	skipButton.MouseButton1Click:Connect(function()
		local productId = ProductConfigurations.Products["SkipRebirth"]
		if productId then
			MarketplaceService:PromptProductPurchase(player, productId)
		else
			warn("SkipRebirth Product ID is missing in ProductConfigurations!")
		end
	end)
end

-- Update when stats change
local leaderstats = player:WaitForChild("leaderstats")
leaderstats:WaitForChild("Speed").Changed:Connect(updateUI)
leaderstats:WaitForChild("Rebirths").Changed:Connect(updateUI)
UpdateEvent.OnClientEvent:Connect(updateUI)

-- Initial Update
updateUI()

print("[RebirthUIController] Loaded")