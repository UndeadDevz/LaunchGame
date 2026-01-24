--!strict
-- LOCATION: StarterPlayerScripts/TrashController

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- [ WAIT FOR ASSETS ]
local Events = ReplicatedStorage:WaitForChild("Events")
local DropEvent = Events:WaitForChild("RequestDropItem") -- Event name remains the same
local CollectionZone = Workspace:WaitForChild("CollectionZone")

-- [ UI REFERENCES ]
local gui = playerGui:WaitForChild("GUI")
local hud = gui:WaitForChild("HUD")
local trashButton = hud:WaitForChild("Trash") :: TextButton -- ## RENAMED HERE ##

print("[TrashController] Loaded & Linked to Button")

-- [ CONFIG ]
local CHECK_RATE = 0.1
local lastCheck = 0

-- [ HELPER: Is Position Inside Part? ]
local function isInsideZone(position: Vector3, zonePart: BasePart): boolean
	local relativePos = zonePart.CFrame:PointToObjectSpace(position)
	local size = zonePart.Size

	-- Check if the relative position is within the box bounds
	return  math.abs(relativePos.X) <= size.X / 2 and
		math.abs(relativePos.Y) <= size.Y / 2 and
		math.abs(relativePos.Z) <= size.Z / 2
end

-- [ BUTTON ACTION ]
trashButton.MouseButton1Click:Connect(function()
	if trashButton.Visible then
		-- Fire the server event to clear inventory
		DropEvent:FireServer()
	end
end)

-- [ MAIN LOOP ]
RunService.Heartbeat:Connect(function()
	local now = tick()
	if now - lastCheck < CHECK_RATE then return end
	lastCheck = now

	local character = player.Character
	if not character then 
		trashButton.Visible = false
		return 
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not rootPart then 
		trashButton.Visible = false
		return 
	end

	-- Perform the Math Check
	local inside = isInsideZone(rootPart.Position, CollectionZone)

	if inside then
		if not trashButton.Visible then
			trashButton.Visible = true
		end
	else
		if trashButton.Visible then
			trashButton.Visible = false
		end
	end
end)