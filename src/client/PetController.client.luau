--!strict
-- LOCATION: StarterPlayerScripts/PetUIController

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- [ TYPES ]
type PetEntry = {
	ID: string,
	Multiplier: number
}

-- [ MODULES ]
-- Supongamos que Utilities y Multipliers están en ReplicatedStorage.Modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Utilities = require(Modules:WaitForChild("Utilities"))
local Multipliers = require(Modules:WaitForChild("Multipliers"))

-- [ PLAYER DATA ]
local player = Players.LocalPlayer
local data = player:WaitForChild("Data")
local petsFolder = data:WaitForChild("Pets")
local nonSaveValues = player:WaitForChild("NonSaveValues")
local petsEquipped = nonSaveValues:WaitForChild("PetsEquipped")

-- [ ASSETS ]
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PetRemote = Remotes:WaitForChild("Pet")
local PetAssets = ReplicatedStorage:WaitForChild("Pets")

-- [ UI REFERENCES ]
local gui = player:WaitForChild("PlayerGui"):WaitForChild("GUI")
local petFrame = gui:WaitForChild("Frames"):WaitForChild("Pets")
local mainFrame = petFrame:WaitForChild("MainFrame")
local objectHolder = mainFrame:WaitForChild("ObjectHolder")
local sideFrame = petFrame:WaitForChild("SideFrame")
local sideFrameBlocker = petFrame:WaitForChild("SideFrameBlocker")
local inventoryCounters = petFrame:WaitForChild("InventoryCounters")

local petTemplate = script.Parent.Client:WaitForChild("PetTemplate")

-- [ STATE ]
local PetInventory: {PetEntry} = {}
local SelectedForDelete: {number} = {}
local IsMultiDeleting = false
local CurrentlySelectedID: number? = nil

-- [ HELPER FUNCTIONS ]

local function updateCounters()
	inventoryCounters.Storage.Text = #petsFolder:GetChildren() .. "/" .. Multipliers.GetMaxPetsStorage(player)
	inventoryCounters.Equipped.Text = petsEquipped.Value .. "/" .. Multipliers.GetMaxPetsEquipped(player)
end

local function sortInventory()
	table.sort(PetInventory, function(a, b)
		if a.Multiplier ~= b.Multiplier then
			return a.Multiplier > b.Multiplier
		end
		return a.ID > b.ID
	end)

	for order, info in PetInventory do
		local petUI = objectHolder:FindFirstChild(info.ID)
		local petValue = petsFolder:FindFirstChild(info.ID)
		
		if petUI and petValue then
			-- Si está equipado, va al principio (0), si no, al final (1000)
			local isEquipped = petValue:WaitForChild("Equipped").Value
			petUI.LayoutOrder = order + (isEquipped and 0 or 1000)
		end
	end
end

local function updateSideFrame(petInstance: Instance)
	CurrentlySelectedID = tonumber(petInstance.Name)
	sideFrameBlocker.Visible = false

	local petName = petInstance:WaitForChild("PetName").Value
	local isEquipped = petInstance:WaitForChild("Equipped").Value
	local multiplier = PetAssets[petName].Settings.Multiplier.Value

	sideFrame.Title.Text = petName
	sideFrame.Equip.Title.Text = isEquipped and "Unequip" or "Equip"
	sideFrame.Equip.BackgroundColor3 = isEquipped and Color3.fromRGB(36, 136, 2) or Color3.fromRGB(56, 218, 3)
	sideFrame.Multiplier.Amount.Text = "x" .. Utilities.Short.en(multiplier)

	-- Actualizar Modelo 3D
	if sideFrame.Display:FindFirstChild("PetModel") then
		sideFrame.Display.PetModel:Destroy()
	end

	local petModel = PetAssets[petName]:Clone()
	petModel.Name = "PetModel"
	petModel.Parent = sideFrame.Display

	local mainPart = petModel:FindFirstChild("MainPart") :: BasePart
	local camera = Instance.new("Camera")
	sideFrame.Display.CurrentCamera = camera
	
	petModel:PivotTo(petModel:GetPivot() * CFrame.Angles(0, math.rad(180), 0))
	camera.CFrame = CFrame.new(mainPart.Position + (petModel:GetExtentsSize().X * 1.5) * Vector3.new(1, 0, 1), mainPart.Position)
end

-- [ MAIN LOGIC ]

local function addPetUI(petInstance: Instance)
	local petID = petInstance.Name
	local petName = petInstance:WaitForChild("PetName").Value
	local multiplier = PetAssets[petName].Settings.Multiplier.Value

	local newPetUI = petTemplate:Clone()
	newPetUI.Name = petID
	newPetUI.Parent = objectHolder

	-- Setup Viewport
	local petModel = PetAssets[petName]:Clone()
	petModel.Parent = newPetUI.Display
	local mainPart = petModel:FindFirstChild("MainPart") :: BasePart
	
	local camera = Instance.new("Camera")
	newPetUI.Display.CurrentCamera = camera
	petModel:PivotTo(petModel:GetPivot() * CFrame.Angles(0, math.rad(180), 0))
	camera.CFrame = CFrame.new(mainPart.Position + (petModel:GetExtentsSize().X * 1.5) * Vector3.new(1, 0, 1), mainPart.Position)

	-- Actualizar estado inicial de equipado
	newPetUI.Equipped.Visible = petInstance:WaitForChild("Equipped").Value

	-- Conexiones del Slot
	petInstance.Equipped.Changed:Connect(function()
		newPetUI.Equipped.Visible = petInstance.Equipped.Value
		if CurrentlySelectedID == tonumber(petID) then
			updateSideFrame(petInstance)
		end
		sortInventory()
	end)

	newPetUI.Button.MouseButton1Click:Connect(function()
		if not IsMultiDeleting then
			updateSideFrame(petInstance)
		else
			local idNum = tonumber(petID)
			local index = table.find(SelectedForDelete, idNum)
			
			if not index then
				table.insert(SelectedForDelete, idNum)
				newPetUI.Delete.Visible = true
			else
				table.remove(SelectedForDelete, index)
				newPetUI.Delete.Visible = false
			end
		end
		Utilities.Audio.PlayAudio("Click")
	end)

	-- Registrar en tabla de inventario
	table.insert(PetInventory, {ID = petID, Multiplier = multiplier})
	sortInventory()
end

-- [ BUTTON ACTIONS ]

petFrame.Buttons.MultiDelete.Click.MouseButton1Click:Connect(function()
	IsMultiDeleting = not IsMultiDeleting
	
	if not IsMultiDeleting then
		petFrame.Buttons.MultiDelete.Title.Text = "Multi Delete"
		if #SelectedForDelete > 0 then
			PetRemote:FireServer("Delete", SelectedForDelete)
		end
		
		for _, id in SelectedForDelete do
			local ui = objectHolder:FindFirstChild(tostring(id))
			if ui then ui.Delete.Visible = false end
		end
		SelectedForDelete = {}
	else
		petFrame.Buttons.MultiDelete.Title.Text = "Confirm"
	end
	Utilities.Audio.PlayAudio("Click")
end)

petFrame.Buttons.EquipBest.Click.MouseButton1Click:Connect(function()
	local maxEquippable = Multipliers.GetMaxPetsEquipped(player)
	local equipBestList = {}

	-- El inventario ya está sorteado por multiplicador
	for i = 1, maxEquippable do
		if PetInventory[i] then
			table.insert(equipBestList, PetInventory[i].ID)
		end
	end

	PetRemote:FireServer("Equip", equipBestList)
	Utilities.Audio.PlayAudio("Click")
end)

sideFrame.Equip.Click.MouseButton1Click:Connect(function()
	if CurrentlySelectedID then
		PetRemote:FireServer("Equip", CurrentlySelectedID)
		Utilities.Audio.PlayAudio("Click")
	end
end)

sideFrame.Delete.Click.MouseButton1Click:Connect(function()
	if CurrentlySelectedID then
		PetRemote:FireServer("Delete", CurrentlySelectedID)
		sideFrameBlocker.Visible = true
		Utilities.Audio.PlayAudio("Click")
	end
end)

-- [ INITIALIZATION & EVENTS ]

petsFolder.ChildAdded:Connect(function(child)
	updateCounters()
	addPetUI(child)
end)

petsFolder.ChildRemoved:Connect(function(child)
	updateCounters()
	local ui = objectHolder:FindFirstChild(child.Name)
	if ui then ui:Destroy() end
	
	-- Remover de la tabla lógica
	for i, info in PetInventory do
		if info.ID == child.Name then
			table.remove(PetInventory, i)
			break
		end
	end
	sortInventory()
end)

petsEquipped.Changed:Connect(updateCounters)

-- Carga inicial
for _, pet in petsFolder:GetChildren() do
	task.spawn(addPetUI, pet)
end

updateCounters()
print("[PetUIController] Loaded")