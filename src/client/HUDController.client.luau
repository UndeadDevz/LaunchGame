--!strict
-- LOCATION: StarterPlayerScripts/HUDController

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local NumberFormatter = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("NumberFormatter"))

local player = Players.LocalPlayer

print("[HUDController] Loaded.")

local function setupHUD()
	-- 1. Get UI References
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild("GUI")
	local hud = gui:WaitForChild("HUD")
	local labels = hud:WaitForChild("Labels")

	local moneyLabel = labels:WaitForChild("Money") :: TextLabel
	local speedLabel = labels:WaitForChild("Speed") :: TextLabel
	local forceLabel = labels:FindFirstChild("Force") :: TextLabel?

	-- 2. Get Leaderstats References
	local leaderstats = player:WaitForChild("leaderstats")
	local moneyStat = leaderstats:WaitForChild("Money") :: IntValue
	local speedStat = leaderstats:WaitForChild("Speed") :: IntValue
	local forceStat = leaderstats:FindFirstChild("Force") :: IntValue?

	-- 3. Update Functions
	local function updateMoney()
		moneyLabel.Text = "Money: $" .. NumberFormatter.Format(moneyStat.Value)
	end

	local function updateSpeed()
		speedLabel.Text = "Speed: " .. NumberFormatter.Format(speedStat.Value)
	end

	local function updateForce()
		if forceLabel and forceStat then
			forceLabel.Text = "Force: " .. NumberFormatter.Format(forceStat.Value)
		end
	end

	-- 4. Connect Changes
	moneyStat.Changed:Connect(updateMoney)
	speedStat.Changed:Connect(updateSpeed)
	if forceStat then
		forceStat.Changed:Connect(updateForce)
	end

	-- 5. Initial Update (Run once to set values immediately)
	updateMoney()
	updateSpeed()
	updateForce()
end

-- Re-run setup whenever the character respawns (which reloads the GUI)
player.CharacterAdded:Connect(setupHUD)

if player.Character then
	setupHUD()
end