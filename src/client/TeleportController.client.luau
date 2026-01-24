--!strict
-- LOCATION: StarterPlayerScripts/TeleportController

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- [ WAIT FOR ASSETS ]
local Events = ReplicatedStorage:WaitForChild("Events")
local LandPlatforms = Workspace:WaitForChild("LandPlatforms")
local Destination = Workspace:WaitForChild("Destination") :: BasePart

-- [ CREATE OR GET TELEPORT EVENT ]
local TeleportEvent = Events:FindFirstChild("RequestTeleportHome")
if not TeleportEvent then
	TeleportEvent = Instance.new("RemoteEvent")
	TeleportEvent.Name = "RequestTeleportHome"
	TeleportEvent.Parent = Events
end

-- [ UI REFERENCES ]
local gui = playerGui:WaitForChild("GUI")
local hud = gui:WaitForChild("HUD")
local teleportButton = hud:WaitForChild("TeleportHome") :: TextButton

print("[TeleportController] Loaded & Linked to Button")

-- [ CONFIG ]
local CHECK_RATE = 0.1
local lastCheck = 0

-- [ HELPER: Is Position Inside Any Platform? ]
local function isInsideAnyPlatform(position: Vector3): boolean
	for _, platform in ipairs(LandPlatforms:GetChildren()) do
		if platform:IsA("BasePart") then
			local relativePos = platform.CFrame:PointToObjectSpace(position)
			local size = platform.Size
			local margin = 5

			local inside = math.abs(relativePos.X) <= (size.X / 2) + margin and
				math.abs(relativePos.Z) <= (size.Z / 2) + margin and
				relativePos.Y >= -margin and relativePos.Y <= size.Y + margin

			if inside then
				return true
			end
		end
	end
	return false
end

-- [ BUTTON ACTION ]
teleportButton.MouseButton1Click:Connect(function()
	if teleportButton.Visible then
		TeleportEvent:FireServer()
	end
end)

-- [ MAIN LOOP ]
RunService.Heartbeat:Connect(function()
	local now = tick()
	if now - lastCheck < CHECK_RATE then return end
	lastCheck = now

	local character = player.Character
	if not character then
		teleportButton.Visible = false
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not rootPart then
		teleportButton.Visible = false
		return
	end

	local inside = isInsideAnyPlatform(rootPart.Position)
	teleportButton.Visible = inside
end)
