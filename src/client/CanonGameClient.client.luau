--[[
	Cannon Game Client Script

	Maneja el input del jugador para lanzamiento
	y muestra la distancia durante el vuelo.
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
print("[Client] PlayerGui found")

-- RemoteEvents
local launchEvent = ReplicatedStorage:WaitForChild("LaunchEvent")
print("[Client] LaunchEvent found")
local distanceUpdateEvent = ReplicatedStorage:WaitForChild("DistanceUpdateEvent")
print("[Client] DistanceUpdateEvent found")

-- Referencia al botón existente en GUI
local gui = playerGui:WaitForChild("GUI")
print("[Client] GUI found")
local launchButton = gui:WaitForChild("LaunchButton")
print("[Client] LaunchButton found:", launchButton:GetFullName())

-- Estado de vuelo
local isFlying = false
local flyingDistanceLabel = nil
local flyingDistanceTextLabel = nil

-- Crear label de distancia (billboard sobre el personaje)
local function createFlyingDistanceLabel()
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "FlyingDistanceLabel"
	billboardGui.Size = UDim2.new(0, 200, 0, 50)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Enabled = false

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Parent = billboardGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 1, 0)
	label.Position = UDim2.new(0, 5, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = "0 studs"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = frame

	return billboardGui, label
end

flyingDistanceLabel, flyingDistanceTextLabel = createFlyingDistanceLabel()

-- Lanzar
local function launch()
	print("[Client] launch() called, firing LaunchEvent")
	launchEvent:FireServer()
end

-- Conexión del botón
print("[Client] Connecting LaunchButton:", launchButton:GetFullName())
launchButton.MouseButton1Click:Connect(launch)
print("[Client] LaunchButton connected")

-- Atajo de teclado (E)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.E then
		launch()
	end
end)

-- Actualización de distancia en tiempo real
distanceUpdateEvent.OnClientEvent:Connect(function(distance, isFlyingUpdate)
	if isFlyingUpdate then
		if not isFlying then
			isFlying = true
			local character = player.Character or player.CharacterAdded:Wait()
			local head = character:WaitForChild("Head")
			flyingDistanceLabel.Parent = head
			flyingDistanceLabel.Enabled = true
		end
		flyingDistanceTextLabel.Text = math.floor(distance) .. " studs"
	else
		isFlying = false
		flyingDistanceLabel.Enabled = false
		flyingDistanceLabel.Parent = nil
	end
end)

print("CannonGameClient loaded")
