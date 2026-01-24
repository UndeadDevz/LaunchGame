--!strict
-- LOCATION: StarterPlayerScripts/IndexController

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Modules
local ItemConfigurations = require(ReplicatedStorage.Modules.ItemConfigurations)
local MutationConfigurations = require(ReplicatedStorage.Modules.MutationConfigurations)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Assets
local Templates = ReplicatedStorage:WaitForChild("Templates")
local IndexTemplate = Templates:WaitForChild("IndexTemplate")
local Events = ReplicatedStorage:WaitForChild("Events")

-- UI References
local mainGui = playerGui:WaitForChild("GUI")
local frames = mainGui:WaitForChild("Frames")
local indexFrame = frames:WaitForChild("Index")
local scrolling = indexFrame:WaitForChild("Scrolling")
local buttonsFolder = indexFrame:WaitForChild("Buttons")

-- State
local currentMutation = "Normal"
local discoveredCache = {}

-- [ DATA FETCHING ]
local GetIndexDataFunction = Events:WaitForChild("GetIndexData", 10)

-- [ HELPER: Button Logic ]
local function updateButtonVisuals()
	for _, btn in ipairs(buttonsFolder:GetChildren()) do
		if btn:IsA("GuiButton") then
			if btn.Name == currentMutation then
				-- Selected Color (Light Grey)
				btn.BackgroundColor3 = Color3.fromRGB(200, 200, 200) 
			else
				-- Unselected Color (Dark Grey)
				btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50) 
			end
		end
	end
end

local function setupTabButtons()
	for _, btn in ipairs(buttonsFolder:GetChildren()) do
		if btn:IsA("GuiButton") then
			btn.MouseButton1Click:Connect(function()
				currentMutation = btn.Name
				updateButtonVisuals()
				UpdateIndexUI(false) -- Standard update
			end)
		end
	end
	updateButtonVisuals() -- Ensure visuals are set immediately
end

-- [ CORE LOGIC ]
function UpdateIndexUI(forceFetch: boolean)
	-- 1. Fetch Data
	if GetIndexDataFunction then
		-- Only fetch from server if forced or cache is empty
		if forceFetch or not next(discoveredCache) then
			local data = GetIndexDataFunction:InvokeServer()
			if data then
				discoveredCache = data
			end
		end
	end

	-- 2. Clear Old Items
	for _, child in ipairs(scrolling:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	-- 3. Get Mutation Config (For Colors)
	local mutConfig = MutationConfigurations[currentMutation]
	local strokeColor = mutConfig and mutConfig.StrokeColor or Color3.new(1, 1, 1)
	local gradientColor = mutConfig and mutConfig.GradientColor

	-- 4. Get Items & Sort
	local itemsToShow = {}
	for itemName, data in pairs(ItemConfigurations.Items) do
		table.insert(itemsToShow, {Name = itemName, Data = data})
	end
	table.sort(itemsToShow, function(a, b) return a.Name < b.Name end)

	-- 5. Populate List
	for _, entry in ipairs(itemsToShow) do
		local itemName = entry.Name
		local itemData = entry.Data
		local key = currentMutation .. "_" .. itemName 

		local isUnlocked = discoveredCache[key] == true

		local template = IndexTemplate:Clone()
		template.Name = itemName
		template.Parent = scrolling
		template.Visible = true

		-- Setup Name
		local nameLabel = template:FindFirstChild("Name") :: TextLabel
		if nameLabel then 
			nameLabel.Text = itemName 
		end

		-- Setup Image
		local imageLabel = template:FindFirstChild("Image") :: ImageLabel
		if imageLabel then
			imageLabel.Image = itemData.ImageId

			if isUnlocked then
				imageLabel.ImageColor3 = Color3.new(1, 1, 1) -- White (Unlocked)
				imageLabel.ImageTransparency = 0
			else
				imageLabel.ImageColor3 = Color3.new(0, 0, 0) -- Black (Locked)
				imageLabel.ImageTransparency = 0.5 
			end
		end

		-- Apply Mutation Colors
		local stroke = template:FindFirstChild("Stroke") :: UIStroke
		if stroke then
			stroke.Color = strokeColor
			stroke.Enabled = true
		end

		local gradient = template:FindFirstChild("Gradient") :: UIGradient
		if gradient then
			if gradientColor then
				gradient.Color = gradientColor
				gradient.Enabled = true
			else
				gradient.Enabled = false 
			end
		end
	end
end

-- [ INIT ]
setupTabButtons()

local refreshEvent = Events:FindFirstChild("RefreshIndex")
if refreshEvent then
	refreshEvent.OnClientEvent:Connect(function()
		UpdateIndexUI(true) -- Force fetch on update
	end)
end

-- [FIX] Retry Logic for Initial Load
task.spawn(function()
	-- Try immediately
	UpdateIndexUI(true)

	-- Wait 2 seconds (for server profile to load) and try again
	task.wait(2)
	UpdateIndexUI(true)
end)

print("[IndexController] Loaded")