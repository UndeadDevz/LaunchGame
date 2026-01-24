--!strict
-- LOCATION: StarterPlayerScripts/CustomSpeedController

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local NumberFormatter = require(ReplicatedStorage.Modules.NumberFormatter)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui = playerGui:WaitForChild("GUI")
local hud = gui:WaitForChild("HUD")

-- [ UI REFERENCES ]
-- Ensure this path matches your UI hierarchy. 
-- Based on your snippet: HUD -> Right -> CustomSpeed
local rightFrame = hud:WaitForChild("Right")
local customSpeedFrame = rightFrame:WaitForChild("CustomSpeed")

local enterSpeedBox = customSpeedFrame:WaitForChild("EnterSpeed") :: TextBox
local maxSpeedLabel = customSpeedFrame:WaitForChild("MaxSpeed") :: TextLabel

-- [ STATE ]
local isMaxSpeedMode = true 

-- [ LOGIC ]

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local function applySpeed(speed: number)
	local char = player.Character
	if char then
		local hum = char:FindFirstChild("Humanoid")
		if hum then
			hum.WalkSpeed = speed
		end
	end
end

local function updateDisplay()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local speedStat = leaderstats:FindFirstChild("Speed") :: IntValue
	if not speedStat then return end

	local maxSpeed = speedStat.Value

	-- Update Label
	maxSpeedLabel.Text = "MAX: " .. NumberFormatter.Format(maxSpeed)

	-- If user hasn't typed a custom number, keep them synced to Max
	if isMaxSpeedMode then
		enterSpeedBox.Text = tostring(maxSpeed)
		applySpeed(maxSpeed)
	else
		-- Ensure custom speed doesn't exceed new max (e.g. if they lost speed)
		local currentInput = tonumber(enterSpeedBox.Text) or maxSpeed
		if currentInput > maxSpeed then
			currentInput = maxSpeed
			isMaxSpeedMode = true
			enterSpeedBox.Text = tostring(currentInput)
		end
		applySpeed(currentInput)
	end
end

-- [ INPUT HANDLING ]

enterSpeedBox.FocusLost:Connect(function(enterPressed)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local speedStat = leaderstats:FindFirstChild("Speed") :: IntValue
	local maxSpeed = speedStat.Value
	local inputNum = tonumber(enterSpeedBox.Text)

	-- If invalid input, reset to max
	if not inputNum then 
		inputNum = maxSpeed 
	end

	-- Logic: If they type a number >= Max, they go back to "Auto-Max" mode
	if inputNum >= maxSpeed then
		inputNum = maxSpeed
		isMaxSpeedMode = true
	else
		-- If they type a lower number, we lock it there
		if inputNum < 0 then inputNum = 0 end
		isMaxSpeedMode = false
	end

	enterSpeedBox.Text = tostring(inputNum)
	applySpeed(inputNum)
end)

-- [ INIT ]

local function init()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats then
		local speedStat = leaderstats:WaitForChild("Speed") :: IntValue

		-- Listen for upgrades/changes to update the UI
		speedStat.Changed:Connect(updateDisplay)

		-- Also ensure we re-apply speed if the character resets
		player.CharacterAdded:Connect(function()
			task.wait(0.5) -- Wait for server to apply default speed first
			updateDisplay()
		end)

		updateDisplay()
	end

	print("[CustomSpeedController] Loaded")
end

init()