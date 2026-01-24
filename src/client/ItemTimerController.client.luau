--!strict
-- LOCATION: StarterPlayerScripts/ItemTimerController

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

print("[ItemTimerController] Initialized")

local function formatTime(seconds: number): string
	if seconds < 0 then return "00:00" end
	local m = math.floor(seconds / 60)
	local s = math.floor(seconds % 60)
	return string.format("%02d:%02d", m, s)
end

-- Optimize: We scan for GUIs inside the ItemSpawners folder
local spawnersFolder = Workspace:WaitForChild("ItemSpawners")

RunService.Heartbeat:Connect(function()
	local now = Workspace:GetServerTimeNow()

	-- Loop through all spawners
	for _, spawner in ipairs(spawnersFolder:GetChildren()) do
		-- Loop through items in spawner
		for _, item in ipairs(spawner:GetChildren()) do
			if item:IsA("Model") and item:GetAttribute("IsSpawnedItem") then

				local expiresAt = item:GetAttribute("ExpiresAt")
				if expiresAt then
					local infoGui = item:FindFirstChild("InfoGUI")
					if infoGui then
						local labels = infoGui:FindFirstChild("TextLabels")
						local timerLabel = labels and labels:FindFirstChild("Timer") :: TextLabel

						if timerLabel then
							local timeLeft = expiresAt - now
							if timeLeft > 0 then
								timerLabel.Text = formatTime(timeLeft)

								-- Optional: Color Feedback
								if timeLeft <= 10 then
									timerLabel.TextColor3 = Color3.fromRGB(255, 85, 85) -- Red urgency
								else
									timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White
								end
							else
								timerLabel.Text = "Refreshing..."
							end
						end
					end
				end

			end
		end
	end
end)