--!strict
-- LOCATION: StarterPlayerScripts/CustomForceController

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local NumberFormatter = require(ReplicatedStorage.Modules.NumberFormatter)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui = playerGui:WaitForChild("GUI")
local hud = gui:WaitForChild("HUD")

-- [ UI REFERENCES ]
local rightFrame = hud:WaitForChild("Right")
local customForceFrame = rightFrame:WaitForChild("CustomForce")

local enterForceBox = customForceFrame:WaitForChild("EnterForce") :: TextBox
local maxForceLabel = customForceFrame:WaitForChild("MaxForce") :: TextLabel

-- [ EVENTS ]
local Events = ReplicatedStorage:WaitForChild("Events")
local SetCustomForceEvent = Events:WaitForChild("SetCustomForce")

-- [ STATE ]
local isMaxForceMode = true

-- [ LOGIC ]

local function applyForce(force: number)
	-- Enviar al servidor el valor de Force personalizado
	SetCustomForceEvent:FireServer(force)
end

local function updateDisplay()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local forceStat = leaderstats:FindFirstChild("Force") :: IntValue
	if not forceStat then return end

	local maxForce = forceStat.Value

	-- Update Label
	maxForceLabel.Text = "MAX: " .. NumberFormatter.Format(maxForce)

	-- If user hasn't typed a custom number, keep them synced to Max
	if isMaxForceMode then
		enterForceBox.Text = tostring(maxForce)
		applyForce(maxForce)
	else
		-- Ensure custom force doesn't exceed new max
		local currentInput = tonumber(enterForceBox.Text) or maxForce
		if currentInput > maxForce then
			currentInput = maxForce
			isMaxForceMode = true
			enterForceBox.Text = tostring(currentInput)
		end
		applyForce(currentInput)
	end
end

-- [ INPUT HANDLING ]

enterForceBox.FocusLost:Connect(function(enterPressed)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local forceStat = leaderstats:FindFirstChild("Force") :: IntValue
	if not forceStat then return end

	local maxForce = forceStat.Value
	local inputNum = tonumber(enterForceBox.Text)

	-- If invalid input, reset to max
	if not inputNum then
		inputNum = maxForce
	end

	-- Logic: If they type a number >= Max, they go back to "Auto-Max" mode
	if inputNum >= maxForce then
		inputNum = maxForce
		isMaxForceMode = true
	else
		-- If they type a lower number, we lock it there
		if inputNum < 1 then inputNum = 1 end
		isMaxForceMode = false
	end

	enterForceBox.Text = tostring(inputNum)
	applyForce(inputNum)
end)

-- [ INIT ]

local function init()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats then
		local forceStat = leaderstats:WaitForChild("Force", 5) :: IntValue
		if forceStat then
			-- Listen for upgrades/changes to update the UI
			forceStat.Changed:Connect(updateDisplay)

			-- Also ensure we re-apply force if the character resets
			player.CharacterAdded:Connect(function()
				task.wait(0.5)
				updateDisplay()
			end)

			updateDisplay()
		end
	end

	print("[CustomForceController] Loaded")
end

init()
