--[[
Code system originally made by Croissant God, on roblox @DemonicMakesGames
Adapted to use PlayerController Money system
]]

local Codes = {
	["100CASH"] = {100, "Money"},
	["500CASH"] = {500, "Money"},
	["1000CASH"] = {1000, "Money"},
}

--------- Main Script ---------

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")

--// Modules
local PlayerController = require(ServerScriptService.Controllers.PlayerController)

--// Variables
local CodeStore = DataStoreService:GetDataStore("CodesStore_v2")

--// Main
ReplicatedStorage.Remotes.RedeemCode.OnServerEvent:Connect(function(Player, Code)
	if not Codes[Code] then return end -- code doesnt exist

	local isRedeemed = pcall(function()
		return CodeStore:GetAsync(Code.."_"..tostring(Player.UserId))
	end)

	if isRedeemed then return end -- Already redeemed

	local codeData = Codes[Code]

	if type(codeData[1]) == "number" and codeData[2] == "Money" then
		PlayerController:AddMoney(Player, codeData[1])

		local Events = ReplicatedStorage:FindFirstChild("Events")
		local notif = Events and Events:FindFirstChild("ShowNotification")
		if notif then
			notif:FireClient(Player, "Code Redeemed! +$" .. codeData[1], "Success")
		end

		pcall(function()
			CodeStore:SetAsync(Code.."_"..tostring(Player.UserId), true)
		end)
	end
end)
