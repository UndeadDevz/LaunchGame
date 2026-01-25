--!strict
-- LOCATION: StarterPlayerScripts/EggHatchingController

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- [ MODULES / CONFIG ]
local ProductConfigurations = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProductConfigurations"))

-- [ ASSETS ]
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EggsFolder = workspace:WaitForChild("Map"):WaitForChild("Eggs")
local PetsFolder = ReplicatedStorage:WaitForChild("Pets")

-- [ UI REFERENCES ]
local gui = playerGui:WaitForChild("GUI")
local frames = gui:WaitForChild("Frames")
local uiOpenEgg = gui:WaitForChild("OpenEgg")
local hud = gui:WaitForChild("HUD")
-- Asumimos que GameSettings.ButtonSide es "Left" o "Right"
local sideButtons = hud:WaitForChild("Left")

local previewFrame = gui:WaitForChild("PreviewFrame") -- Ajusta según tu jerarquía real
local currentTarget = previewFrame:WaitForChild("CurrentTarget")

-- [ STATE ]
local isAutoOpening = false
local isHatching = false

-- [ CONSTANTS ]
local OPENING_TIME = 3
local TWEEN_INFO_BACK = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- [ CORE LOGIC ]

local function hatchEgg(eggName: string, petResult: string, offset: number)
    local openingTime = OPENING_TIME
    
    -- UI Preparation
    local newViewport = gui:WaitForChild("EggViewport"):Clone()
    newViewport.Parent = uiOpenEgg
    
    player.CameraMinZoomDistance = 15
    frames.Visible = false
    sideButtons.Visible = false

    -- Egg Model Setup
    local eggModelTemplate = EggsFolder:FindFirstChild(eggName):FindFirstChild("EggModel")
    if not eggModelTemplate then return end
    
    local eggClone = eggModelTemplate:Clone()
    eggClone:ScaleTo(0.5)
    eggClone.Parent = workspace

    -- Animation Values
    local rotVal = Instance.new("NumberValue")
    local xVal = Instance.new("NumberValue")
    local yVal = Instance.new("NumberValue")
    local zVal = Instance.new("NumberValue")
    
    rotVal.Value = 30
    zVal.Value = -4
    xVal.Value = 10

    local light = Instance.new("PointLight")
    light.Shadows = false
    light.Range = 4
    light.Brightness = 3
    light.Parent = eggClone:FindFirstChild("Egg") or eggClone.PrimaryPart

    -- Camera Binding
    local function updatePivot()
        local cf = camera:GetRenderCFrame() * CFrame.new(xVal.Value, yVal.Value, zVal.Value)
        eggClone:PivotTo(cf * CFrame.Angles(0, 0, math.rad(rotVal.Value)))
    end

    local conn1 = RunService.Heartbeat:Connect(updatePivot)
    local conn2 = camera:GetPropertyChangedSignal("CFrame"):Connect(updatePivot)

    -- Intro Tween
    TweenService:Create(xVal, TWEEN_INFO_BACK, {Value = offset}):Play()
    TweenService:Create(rotVal, TWEEN_INFO_BACK, {Value = 0}):Play()
    
    task.wait(openingTime * 0.2)

    -- Wobble Animation
    local eggDelay = 0.075
    for i = 1, (openingTime * 1.5) do
        TweenService:Create(rotVal, TweenInfo.new(eggDelay, Enum.EasingStyle.Back), {Value = 6}):Play()
        task.wait(eggDelay)
        TweenService:Create(rotVal, TweenInfo.new(eggDelay, Enum.EasingStyle.Back), {Value = -6}):Play()
        task.wait(eggDelay)
        eggDelay = math.max(0.02, eggDelay - 0.005)
    end

    -- Cleanup Egg
    conn1:Disconnect()
    conn2:Disconnect()
    eggClone:Destroy()

    -- Pet Reveal
    local petTemplate = PetsFolder:FindFirstChild(petResult)
    if not petTemplate then return end
    
    local petModel = petTemplate:Clone()
    petModel:ScaleTo(0.6)
    petModel.Parent = workspace

    -- Update Viewport UI
    local petSettings = petTemplate:FindFirstChild("Settings")
    newViewport:WaitForChild("PetName").Text = petResult
    newViewport:WaitForChild("PetName").Visible = true
    if petSettings then
        newViewport:WaitForChild("PetRarity").Text = petSettings.Rarity.Value
        newViewport:WaitForChild("PetRarity").Visible = true
    end

    xVal.Value = offset
    yVal.Value = 0
    zVal.Value = -4
    rotVal.Value = 175

    local function updatePetPivot()
        local cf = camera:GetRenderCFrame() * CFrame.new(xVal.Value, yVal.Value, zVal.Value)
        petModel:PivotTo(cf * CFrame.Angles(0, math.rad(rotVal.Value), 0))
    end

    local conn3 = RunService.Heartbeat:Connect(updatePetPivot)
    local conn4 = camera:GetPropertyChangedSignal("CFrame"):Connect(updatePetPivot)

    task.wait(openingTime * 0.25)

    -- Outro Animation
    newViewport:TweenPosition(UDim2.new(newViewport.Position.X.Scale, 0, newViewport.Position.Y.Scale + 10, 0), "InOut", "Quad", openingTime * 0.1)
    TweenService:Create(yVal, TweenInfo.new(openingTime * 0.15, Enum.EasingStyle.Back), {Value = -5}):Play()
    
    task.wait(openingTime * 0.15)

    -- Final Cleanup
    conn3:Disconnect()
    conn4:Disconnect()
    xVal:Destroy(); yVal:Destroy(); zVal:Destroy(); rotVal:Destroy()
    petModel:Destroy()
    newViewport:Destroy()

    player.CameraMinZoomDistance = 0.5
    sideButtons.Visible = true
    frames.Visible = true
end

-- [ HANDLERS ]

local function singleEgg()
    if isHatching then return end
    local eggName = currentTarget.Value
    if eggName == "None" then return end

    local eggInfo = ReplicatedStorage.Eggs:FindFirstChild(eggName)
    if not eggInfo then return end

    if not eggInfo:FindFirstChild("ProductId") then
        isHatching = true
        local result = Remotes.Egg:InvokeServer(eggName, 1)
        if result then
            hatchEgg(eggName, result[1], 0)
        end
        isHatching = false
    else
        MarketplaceService:PromptProductPurchase(player, eggInfo.ProductId.Value)
    end
end

local function tripleEgg()
    if isHatching then return end
    local eggName = currentTarget.Value
    if eggName == "None" then return end

    if not player:GetAttribute("TripleEgg") then
        local productId = ProductConfigurations.PermanentProducts.TripleEgg
        MarketplaceService:PromptProductPurchase(player, productId)
        return
    end

    isHatching = true
    local result = Remotes.Egg:InvokeServer(eggName, 3)
    if result then
        for i, petName in ipairs(result) do
            task.spawn(function()
                local positionOffset = (i - 2) * 3
                hatchEgg(eggName, petName, positionOffset)
            end)
        end
        -- Esperamos un poco antes de permitir otra apertura
        task.wait(OPENING_TIME)
    end
    isHatching = false
end

local function autoEgg()
    if isAutoOpening then 
        isAutoOpening = false 
        return 
    end

    local eggName = currentTarget.Value
    if eggName == "None" then return end

    if not player:GetAttribute("AutoEgg") then
        local productId = ProductConfigurations.PermanentProducts.AutoEgg
        MarketplaceService:PromptProductPurchase(player, productId)
        return
    end

    isAutoOpening = true

    task.spawn(function()
        while isAutoOpening do
            if isHatching then task.wait(0.5) continue end
            
            if currentTarget.Value == "None" or currentTarget.Value ~= eggName then
                isAutoOpening = false
                break
            end

            -- Lógica para decidir si abre 1 o 3
            local amount = 1
            local eggInfo = ReplicatedStorage.Eggs:FindFirstChild(eggName)
            if player:GetAttribute("TripleEgg") and eggInfo then
                local money = player.leaderstats.Money.Value
                if money >= eggInfo.Cost.Value * 3 then
                    amount = 3
                end
            end

            local result = Remotes.Egg:InvokeServer(eggName, amount)
            if not result then 
                isAutoOpening = false
                break 
            end

            isHatching = true
            for i, petName in ipairs(result) do
                task.spawn(function()
                    local pos = (amount == 3) and (i - 2) * 3 or 0
                    hatchEgg(eggName, petName, pos)
                end)
            end
            
            task.wait(OPENING_TIME + 0.5)
            isHatching = false
        end
    end)
end

-- [ CONNECTIONS ]

Remotes.Egg.OnClientInvoke = hatchEgg

previewFrame.Buttons.Single.Click.MouseButton1Click:Connect(singleEgg)
previewFrame.Buttons.Triple.Click.MouseButton1Click:Connect(tripleEgg)
previewFrame.Buttons.Auto.Click.MouseButton1Click:Connect(autoEgg)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if UserInputService:GetFocusedTextBox() then return end

    if input.KeyCode == Enum.KeyCode.E then singleEgg() end
    if input.KeyCode == Enum.KeyCode.R then tripleEgg() end
    if input.KeyCode == Enum.KeyCode.T then autoEgg() end
end)

print("[EggHatchingController] Loaded")