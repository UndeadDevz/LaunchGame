--!strict
-- LOCATION: StarterPlayerScripts/EggPreviewController

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- [ MODULES ]
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Utilities = require(Modules:WaitForChild("Utilities"))
local Multipliers = require(Modules:WaitForChild("Multipliers"))

-- [ PLAYER DATA ]
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

local data = player:WaitForChild("Data")
local autoDeleteFolder = data:WaitForChild("AutoDelete")
local nonSaveValues = player:WaitForChild("NonSaveValues")
local isOpeningEgg = nonSaveValues:WaitForChild("IsOpeningEgg")

-- [ ASSETS ]
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PetAssets = ReplicatedStorage:WaitForChild("Pets")
local EggAssets = ReplicatedStorage:WaitForChild("Eggs")
local MapEggs = workspace:WaitForChild("Map"):WaitForChild("Eggs")

-- [ UI REFERENCES ]
local gui = player:WaitForChild("PlayerGui"):WaitForChild("GUI")
local previewFrame = gui:WaitForChild("PreviewFrame")
local currentTarget = previewFrame:WaitForChild("CurrentTarget")
local eggInfoFrame = previewFrame:WaitForChild("EggInfo")
local petChancesList = previewFrame:WaitForChild("PetChances"):WaitForChild("List")
local buttonsFrame = previewFrame:WaitForChild("Buttons")

-- [ CONFIG ]
local MAX_DISTANCE = 12
local DEFAULT_SIZE = UDim2.fromScale(0.4, 0.4) -- Ajusta según tu diseño original
local CLOSED_SIZE = UDim2.fromScale(0.2, 0.2)
local TWEEN_SPEED = 0.15

-- [ STATE ]
local isClosing = false
local camera = workspace.CurrentCamera

-- [ HELPER FUNCTIONS ]

local function getClosestEgg(): Model?
	local closestEgg = nil
	local shortestDistance = MAX_DISTANCE

	for _, egg in MapEggs:GetChildren() do
		if not egg:IsA("Model") then continue end
		
		local distance = (egg:GetPivot().Position - humanoidRootPart.Position).Magnitude
		if distance <= shortestDistance then
			closestEgg = egg
			shortestDistance = distance
		end
	end
	return closestEgg
end

local function cleanViewport(container: GuiObject)
	for _, child in container:GetChildren() do
		if child:IsA("Model") or child:IsA("Camera") then
			child:Destroy()
		end
	end
end

-- [ UI LOGIC ]

local function updatePreviewContent()
	local eggName = currentTarget.Value
	if eggName == "None" then return end

	local eggSettings = EggAssets:FindFirstChild(eggName)
	if not eggSettings then 
		warn("No settings found for: " .. eggName)
		return 
	end

	-- 1. Info Básica y Precio
	eggInfoFrame.EggName.Text = eggName
	local isRobux = eggSettings:FindFirstChild("ProductId") ~= nil
	local pricePrefix = isRobux and "\u{E002}" or "" -- Icono Robux
	eggInfoFrame.Price.Text = "Costs " .. pricePrefix .. Utilities.Short.en(eggSettings.Cost.Value)

	buttonsFrame.Triple.Visible = not isRobux
	buttonsFrame.Auto.Visible = not isRobux

	-- 2. Cálculo de Probabilidades (Luck)
	local pets = {}
	for _, pet in eggSettings.Pets:GetChildren() do
		table.insert(pets, {Name = pet.Name, Weight = pet.Value})
	end

	table.sort(pets, function(a, b) return a.Weight > b.Weight end)

	local baseChance = pets[1].Weight
	local luckMult = Multipliers.GetLuckMultiplier(player)
	local totalWeight = 0

	for _, p in pets do
		p.Weight = math.min(p.Weight * luckMult, baseChance)
		totalWeight += p.Weight
	end

	-- 3. Renderizar Lista de Pets
	for i = 1, 9 do
		local slot = petChancesList:FindFirstChild("Pet" .. i) :: Frame
		local petData = pets[i]

		if not slot then continue end

		if not petData then
			slot.Visible = false
			continue
		end

		slot.Visible = true
		local petName = petData.Name
		local petSettings = PetAssets:FindFirstChild(petName).Settings
		
		slot.Rarity.Text = petSettings.Rarity.Value
		slot.Percentage.Text = string.format("%.2f%%", (petData.Weight / totalWeight) * 100)
		slot.PetName.Value = petName
		
		-- Check AutoDelete
		local autoDeleteVal = autoDeleteFolder:FindFirstChild(petName)
		slot.Delete.Visible = if autoDeleteVal then autoDeleteVal.Value else false

		-- Viewport Render
		cleanViewport(slot.Pet)
		local petModel = PetAssets[petName]:Clone()
		petModel.Parent = slot.Pet
		
		local mainPart = petModel:FindFirstChild("MainPart") :: BasePart
		local vpCamera = Instance.new("Camera")
		slot.Pet.CurrentCamera = vpCamera
		
		petModel:PivotTo(petModel:GetPivot() * CFrame.Angles(0, math.rad(180), 0))
		vpCamera.CFrame = CFrame.new(mainPart.Position + (petModel:GetExtentsSize().X * 1.5) * Vector3.new(1, 0, 1), mainPart.Position)
	end
end

-- [ CORE LOOP ]

local function onHeartbeat()
	-- Validar estado del jugador
	if not humanoidRootPart or humanoid.Health <= 0 then 
		previewFrame.Visible = false
		return 
	end

	local closestEgg = getClosestEgg()
	local shouldBeVisible = closestEgg ~= nil and not isOpeningEgg.Value
	
	if shouldBeVisible and closestEgg then
		-- Actualizar Posición y Target
		local screenPos, onScreen = camera:WorldToScreenPoint(closestEgg:GetPivot().Position)
		
		if onScreen then
			previewFrame.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)
			currentTarget.Value = closestEgg.Name
			
			if not previewFrame.Visible then
				previewFrame.Visible = true
				local cameraRatio = ((camera.CFrame.Position - camera.Focus.Position).Magnitude) / 11
				local targetSize = UDim2.new(
					DEFAULT_SIZE.X.Scale / cameraRatio, DEFAULT_SIZE.X.Offset,
					DEFAULT_SIZE.Y.Scale / cameraRatio, DEFAULT_SIZE.Y.Offset
				)
				Utilities.Tween.Tween(previewFrame, {Speed = TWEEN_SPEED}, {Size = targetSize})
			end
		else
			shouldBeVisible = false
		end
	else
		if previewFrame.Visible and not isClosing then
			isClosing = true
			currentTarget.Value = "None"
			
			task.spawn(function()
				Utilities.Tween.Tween(previewFrame, {Speed = TWEEN_SPEED}, {Size = CLOSED_SIZE})
				task.wait(TWEEN_SPEED)
				previewFrame.Visible = false
				isClosing = false
			end)
		end
	end
end

-- [ INITIALIZATION ]

-- Setup AutoDelete Buttons
for _, slot in petChancesList:GetChildren() do
	if slot:IsA("Frame") and slot:FindFirstChild("Button") then
		slot.Button.MouseButton1Click:Connect(function()
			local petName = slot.PetName.Value
			local success = Remotes.AutoDelete:InvokeServer(petName)
			slot.Delete.Visible = success
			
		end)
	end
end

-- Conexiones de apertura de huevo
buttonsFrame.Single.Click.MouseButton1Click:Connect(function()
	Remotes.Egg:InvokeServer("Open", currentTarget.Value, 1)
	
end)

currentTarget.Changed:Connect(updatePreviewContent)
RunService.Heartbeat:Connect(onHeartbeat)

-- Actualizar si cambia el personaje (respawn)
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
	humanoid = newChar:WaitForChild("Humanoid")
end)

print("[EggPreviewController] Loaded")