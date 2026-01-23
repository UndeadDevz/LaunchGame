--!strict
-- LOCATION: ServerScriptService/Modules/RebirthSystem

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RebirthSystem = {}

-- [ MODULES ]
local PlayerController 
local NumberFormatter = require(ReplicatedStorage.Modules.NumberFormatter)

-- [ CONFIG ]
local BASE_SPEED_COST = 20
local BASE_WALKSPEED = 10

-- [ HELPERS ]
function RebirthSystem.GetInfo(player: Player)
	local profile = PlayerController:GetProfile(player)
	if not profile then return 0, 0, 0 end

	local reb = profile.Data.Rebirths or 0
	local cost = BASE_SPEED_COST * (2 ^ reb)
	local currentMult = 1 + (reb * 0.5)
	local nextMult = 1 + ((reb + 1) * 0.5)

	return cost, currentMult, nextMult
end

-- [ INTERNAL: DO REBIRTH ]
local function executeRebirth(player: Player, profile: any)
	profile.Data.Rebirths += 1
	profile.Data.Speed = BASE_WALKSPEED -- Reset Speed to 16

	-- Update Leaderstats
	if player:FindFirstChild("leaderstats") then
		player.leaderstats.Rebirths.Value = profile.Data.Rebirths
		player.leaderstats.Speed.Value = BASE_WALKSPEED
	end

	-- Reset Character Speed
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		player.Character.Humanoid.WalkSpeed = BASE_WALKSPEED
	end

	-- [FIX] NOTIFICATION
	local Events = ReplicatedStorage:FindFirstChild("Events")
	local notif = Events and Events:FindFirstChild("ShowNotification")
	if notif then 
		notif:FireClient(player, "Rebirth Successful!", "Success") 
	end

	-- Update Client UI
	local updateEvent = Events:FindFirstChild("UpdateRebirthUI")
	if updateEvent then updateEvent:FireClient(player) end

	-- Refresh Speed Prices
	local SpeedSystem = require(ServerScriptService.Modules.SpeedSystem)
	if SpeedSystem and SpeedSystem.UpdateClientUI then
		SpeedSystem.UpdateClientUI(player)
	end
end

-- [ PUBLIC API ]

-- Called by the MonetizationController (Robux)
function RebirthSystem.ForceRebirth(player: Player)
	local profile = PlayerController:GetProfile(player)
	if profile then
		executeRebirth(player, profile)
	end
end

-- Called by the Client Button (Speed Trade)
function RebirthSystem.AttemptRebirth(player: Player)
	local profile = PlayerController:GetProfile(player)
	if not profile then return end

	local currentSpeed = profile.Data.Speed or BASE_WALKSPEED
	local cost, _, _ = RebirthSystem.GetInfo(player)

	if currentSpeed >= cost then
		executeRebirth(player, profile)
	else
		-- FAIL
		local Events = ReplicatedStorage:FindFirstChild("Events")
		local notif = Events and Events:FindFirstChild("ShowNotification")
		if notif then 
			notif:FireClient(player, "Not enough Speed!", "Error") 
		end
	end
end

-- [ INIT ]
function RebirthSystem:Init(controllers)
	print("[RebirthSystem] Initialized")
	PlayerController = controllers.PlayerController

	local Events = ReplicatedStorage:WaitForChild("Events")

	if not Events:FindFirstChild("RequestRebirth") then
		local re = Instance.new("RemoteEvent")
		re.Name = "RequestRebirth"
		re.Parent = Events
	end

	if not Events:FindFirstChild("UpdateRebirthUI") then
		local re = Instance.new("RemoteEvent")
		re.Name = "UpdateRebirthUI"
		re.Parent = Events
	end

	Events.RequestRebirth.OnServerEvent:Connect(function(player)
		RebirthSystem.AttemptRebirth(player)
	end)
end

function RebirthSystem:Start()
	-- No loop needed
end

return RebirthSystem