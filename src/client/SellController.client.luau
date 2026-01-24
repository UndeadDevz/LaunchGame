--!strict
-- LOCATION: StarterPlayerScripts/SellController

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- [ NPC REFERENCES ]
local sellNPC = Workspace:WaitForChild("SellNPC")
local proxPart = sellNPC:WaitForChild("ProxPart")
local prompt = proxPart:WaitForChild("ProximityPrompt") :: ProximityPrompt

-- [ CONFIG ]
local MAX_DISTANCE = prompt.MaxActivationDistance + 5 
local CHECK_RATE = 0.2

-- [ UI SETUP ]
local sourceGui = sellNPC:WaitForChild("SellGUI") 

local SellGUI = playerGui:FindFirstChild("SellGUI") :: BillboardGui
if not SellGUI then
	SellGUI = sourceGui:Clone()
	SellGUI.Parent = playerGui
	SellGUI.Adornee = proxPart 
end

sourceGui.Enabled = false 

-- [ BUTTON REFERENCES ]
local closeBtn = SellGUI:WaitForChild("Close") :: ImageButton
local sellEquippedBtn = SellGUI:WaitForChild("SellEquipped") :: ImageButton
local sellInventoryBtn = SellGUI:WaitForChild("SellInventory") :: ImageButton

-- [ EVENTS ]
local Events = ReplicatedStorage:WaitForChild("Events")
local SellEvent = Events:WaitForChild("RequestSell")

-- [ ANIMATION CONFIG ]
local HOVER_SCALE = 1.1
local CLICK_SCALE = 0.95
local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- [ HELPER: Button Animation ]
local function setupButtonAnimation(button: GuiButton)
	local uiScale = button:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Name = "AnimationScale"
		uiScale.Parent = button
	end

	uiScale.Scale = 1

	button.MouseEnter:Connect(function() TweenService:Create(uiScale, TWEEN_INFO, {Scale = HOVER_SCALE}):Play() end)
	button.MouseLeave:Connect(function() TweenService:Create(uiScale, TWEEN_INFO, {Scale = 1}):Play() end)
	button.MouseButton1Down:Connect(function() TweenService:Create(uiScale, TWEEN_INFO, {Scale = CLICK_SCALE}):Play() end)
	button.MouseButton1Up:Connect(function() TweenService:Create(uiScale, TWEEN_INFO, {Scale = HOVER_SCALE}):Play() end)
end

-- [ STATE ]
local isMenuOpen = false

-- [ LOGIC ]

local function closeSellMenu()
	-- Always reset GUI state
	SellGUI.Enabled = false
	isMenuOpen = false

	-- ## FIX: Robust Re-Enable Logic ##
	-- Disable prompt momentarily to prevent double-trigger, then ensure it comes back
	prompt.Enabled = false
	task.delay(0.5, function()
		prompt.Enabled = true
	end)
end

local function openSellMenu()
	if isMenuOpen then return end
	isMenuOpen = true

	SellGUI.Enabled = true
	prompt.Enabled = false 

	-- Reset buttons scale
	for _, btn in pairs({closeBtn, sellEquippedBtn, sellInventoryBtn}) do
		local scale = btn:FindFirstChild("AnimationScale") :: UIScale
		if scale then scale.Scale = 1 end
	end

	-- Auto-Close Loop
	task.spawn(function()
		while isMenuOpen do
			task.wait(CHECK_RATE)

			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")

			if not root or not proxPart then
				closeSellMenu()
				break
			end

			local distance = (root.Position - proxPart.Position).Magnitude

			if distance > MAX_DISTANCE then
				closeSellMenu()
				break
			end
		end
	end)
end

-- [ CONNECTIONS ]

prompt.Triggered:Connect(openSellMenu)

-- 1. Close Button
closeBtn.MouseButton1Click:Connect(closeSellMenu)
setupButtonAnimation(closeBtn)

-- 2. Sell Equipped -> Close
sellEquippedBtn.MouseButton1Click:Connect(function()
	SellEvent:FireServer("Equipped")
	closeSellMenu() 
end)
setupButtonAnimation(sellEquippedBtn)

-- 3. Sell Inventory -> Close
sellInventoryBtn.MouseButton1Click:Connect(function()
	SellEvent:FireServer("Inventory")
	closeSellMenu() 
end)
setupButtonAnimation(sellInventoryBtn)

-- Init State
SellGUI.Enabled = false
prompt.Enabled = true

print("[SellController] Loaded - Clutter Fix & Logic Fix Applied")