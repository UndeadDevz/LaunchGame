 -- Cannon Game Client Script
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Get RemoteEvents
local launchEvent = ReplicatedStorage:WaitForChild("LaunchEvent")
local upgradeEvent = ReplicatedStorage:WaitForChild("UpgradeEvent")
local coinUpdateEvent = ReplicatedStorage:WaitForChild("CoinUpdateEvent")
local distanceUpdateEvent = ReplicatedStorage:WaitForChild("DistanceUpdateEvent")
local rebirthEvent = ReplicatedStorage:WaitForChild("RebirthEvent")

local player = Players.LocalPlayer

-- Create GUI
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CannonGameGUI"
    screenGui.ResetOnSpawn = false  -- This keeps GUI after respawn!
	screenGui.Parent = player:WaitForChild("PlayerGui")
	screenGui.IgnoreGuiInset = true
    
    -- Top indicators frame (coins and speed)
    local topFrame = Instance.new("Frame")
    topFrame.Name = "TopFrame"
    topFrame.Size = UDim2.new(0, 320, 0, 40)
    topFrame.Position = UDim2.new(0.5, -160, 0, 10)
    topFrame.BackgroundTransparency = 1
    topFrame.BorderSizePixel = 0
    topFrame.Parent = screenGui
    
    local topCorner = Instance.new("UICorner")
    topCorner.CornerRadius = UDim.new(0, 6)
    topCorner.Parent = topFrame
    
    -- Coins display with icon
    local coinsFrame = Instance.new("Frame")
    coinsFrame.Name = "CoinsFrame"
    coinsFrame.Size = UDim2.new(0, 90, 0, 30)
    coinsFrame.Position = UDim2.new(0, 10, 0, 5)
    coinsFrame.BackgroundColor3 = Color3.new(0.5, 0, 1)
    coinsFrame.BorderSizePixel = 0
    coinsFrame.Parent = topFrame
    
    local coinsCorner = Instance.new("UICorner")
    coinsCorner.CornerRadius = UDim.new(0, 4)
    coinsCorner.Parent = coinsFrame
    
    -- Coins icon (using image)
    local coinsIcon = Instance.new("ImageLabel")
    coinsIcon.Name = "CoinsIcon"
    coinsIcon.Size = UDim2.new(0, 20, 0, 20)
    coinsIcon.Position = UDim2.new(0, 5, 0, 5)
    coinsIcon.BackgroundTransparency = 1
    coinsIcon.Image = "http://www.roblox.com/asset/?id=595987284"
    coinsIcon.Parent = coinsFrame
    
    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "CoinsLabel"
    coinsLabel.Size = UDim2.new(0, 80, 0, 20)
    coinsLabel.Position = UDim2.new(0, 30, 0, 5)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.Text = "Coins: 0"
    coinsLabel.TextColor3 = Color3.new(1, 1, 1)
    coinsLabel.TextStrokeTransparency = 0
    coinsLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    coinsLabel.TextSize = 12
    coinsLabel.Font = Enum.Font.SourceSansBold
    coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
    coinsLabel.Parent = coinsFrame
    
    -- Speed display with icon
    local speedFrame = Instance.new("Frame")
    speedFrame.Name = "SpeedFrame"
    speedFrame.Size = UDim2.new(0, 90, 0, 30)
    speedFrame.Position = UDim2.new(0, 115, 0, 5)
    speedFrame.BackgroundColor3 = Color3.new(0, 0.5, 1)
    speedFrame.BorderSizePixel = 0
    speedFrame.Parent = topFrame
    
    local speedCorner = Instance.new("UICorner")
    speedCorner.CornerRadius = UDim.new(0, 4)
    speedCorner.Parent = speedFrame
    
    -- Speed icon (using emoji)
    local speedIcon = Instance.new("TextLabel")
    speedIcon.Name = "SpeedIcon"
    speedIcon.Size = UDim2.new(0, 20, 0, 20)
    speedIcon.Position = UDim2.new(0, 5, 0, 5)
    speedIcon.BackgroundTransparency = 1
    speedIcon.Text = "🚀"
    speedIcon.TextSize = 14
    speedIcon.Font = Enum.Font.SourceSans
    speedIcon.TextStrokeTransparency = 0
    speedIcon.TextStrokeColor3 = Color3.new(0, 0, 0)
    speedIcon.Parent = speedFrame
    
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Name = "SpeedLabel"
    speedLabel.Size = UDim2.new(0, 80, 0, 20)
    speedLabel.Position = UDim2.new(0, 25, 0, 5)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "Speed: 1"
    speedLabel.TextColor3 = Color3.new(1, 1, 1)
    speedLabel.TextStrokeTransparency = 0
    speedLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    speedLabel.TextSize = 12
    speedLabel.Font = Enum.Font.SourceSansBold
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedLabel.Parent = speedFrame
    
    -- Rebirths display with icon (separate frame)
    local rebirthsTopFrame = Instance.new("Frame")
    rebirthsTopFrame.Name = "RebirthsTopFrame"
    rebirthsTopFrame.Size = UDim2.new(0, 90, 0, 30)
    rebirthsTopFrame.Position = UDim2.new(0, 220, 0, 5)
    rebirthsTopFrame.BackgroundColor3 = Color3.new(0.8, 0.2, 0.8)
    rebirthsTopFrame.BorderSizePixel = 0
    rebirthsTopFrame.Parent = topFrame
    
    local rebirthsTopCorner = Instance.new("UICorner")
    rebirthsTopCorner.CornerRadius = UDim.new(0, 4)
    rebirthsTopCorner.Parent = rebirthsTopFrame
    
    -- Rebirths icon (using crown emoji)
    local rebirthsTopIcon = Instance.new("TextLabel")
    rebirthsTopIcon.Name = "RebirthsTopIcon"
    rebirthsTopIcon.Size = UDim2.new(0, 20, 0, 20)
    rebirthsTopIcon.Position = UDim2.new(0, 5, 0, 5)
    rebirthsTopIcon.BackgroundTransparency = 1
    rebirthsTopIcon.Text = "👑"
    rebirthsTopIcon.TextSize = 14
    rebirthsTopIcon.Font = Enum.Font.SourceSans
    rebirthsTopIcon.TextStrokeTransparency = 0
    rebirthsTopIcon.TextStrokeColor3 = Color3.new(0, 0, 0)
    rebirthsTopIcon.Parent = rebirthsTopFrame
    
    local rebirthsTopLabel = Instance.new("TextLabel")
    rebirthsTopLabel.Name = "RebirthsTopLabel"
    rebirthsTopLabel.Size = UDim2.new(0, 80, 0, 20)
    rebirthsTopLabel.Position = UDim2.new(0, 25, 0, 5)
    rebirthsTopLabel.BackgroundTransparency = 1
    rebirthsTopLabel.Text = "Rebirths: 0"
    rebirthsTopLabel.TextColor3 = Color3.new(1, 1, 1)
    rebirthsTopLabel.TextStrokeTransparency = 0
    rebirthsTopLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    rebirthsTopLabel.TextSize = 12
    rebirthsTopLabel.Font = Enum.Font.SourceSansBold
    rebirthsTopLabel.TextXAlignment = Enum.TextXAlignment.Left
    rebirthsTopLabel.Parent = rebirthsTopFrame
    
    -- Left side controls frame
    local leftFrame = Instance.new("Frame")
    leftFrame.Name = "LeftFrame"
    leftFrame.Size = UDim2.new(0, 100, 0, 110)
    leftFrame.Position = UDim2.new(0, 10, 0, 60)
    leftFrame.BackgroundTransparency = 1
    leftFrame.BorderSizePixel = 0
    leftFrame.Parent = screenGui
    
    local leftCorner = Instance.new("UICorner")
    leftCorner.CornerRadius = UDim.new(0, 6)
    leftCorner.Parent = leftFrame
    
    -- Launch button with icon
    local launchButton = Instance.new("TextButton")
    launchButton.Name = "LaunchButton"
    launchButton.Size = UDim2.new(0, 80, 0, 30)
    launchButton.Position = UDim2.new(0, 10, 0, 10)
    launchButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    launchButton.BorderSizePixel = 0
    launchButton.Text = "🚀 LAUNCH"
    launchButton.TextColor3 = Color3.new(1, 1, 1)
    launchButton.TextStrokeTransparency = 0
    launchButton.TextStrokeColor3 = Color3.new(0, 0, 0)
    launchButton.TextSize = 10
    launchButton.Font = Enum.Font.SourceSansBold
    launchButton.Parent = leftFrame
    
    local launchCorner = Instance.new("UICorner")
    launchCorner.CornerRadius = UDim.new(0, 4)
    launchCorner.Parent = launchButton
    
    -- Upgrade button with icon
    local upgradeButton = Instance.new("TextButton")
    upgradeButton.Name = "UpgradeButton"
    upgradeButton.Size = UDim2.new(0, 80, 0, 30)
    upgradeButton.Position = UDim2.new(0, 10, 0, 50)
    upgradeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    upgradeButton.BorderSizePixel = 0
    upgradeButton.Text = "⬆️ UPGRADE (10)"
    upgradeButton.TextColor3 = Color3.new(1, 1, 1)
    upgradeButton.TextStrokeTransparency = 0
    upgradeButton.TextStrokeColor3 = Color3.new(0, 0, 0)
    upgradeButton.TextSize = 10
    upgradeButton.Font = Enum.Font.SourceSansBold
    upgradeButton.Parent = leftFrame
    
    local upgradeCorner = Instance.new("UICorner")
    upgradeCorner.CornerRadius = UDim.new(0, 4)
    upgradeCorner.Parent = upgradeButton
    

    
    -- Instructions
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Size = UDim2.new(0, 300, 0, 60)
    instructions.Position = UDim2.new(0.5, -150, 1, -70)
    instructions.BackgroundTransparency = 1
    instructions.Text = "Stand on launching pad & press E to launch!\nPress R or UPGRADE to increase speed.\nPress T or REBIRTH to reset for coin boost!\nFurther = more coins!"
    instructions.TextColor3 = Color3.new(1, 1, 1)
    instructions.TextSize = 10
    instructions.Font = Enum.Font.SourceSans
    instructions.TextStrokeTransparency = 0
    instructions.TextStrokeColor3 = Color3.new(0, 0, 0)
    instructions.Parent = screenGui
    
    -- Rebirth button with icon
    local rebirthButton = Instance.new("TextButton")
    rebirthButton.Name = "RebirthButton"
    rebirthButton.Size = UDim2.new(0, 80, 0, 30)
    rebirthButton.Position = UDim2.new(0, 10, 0, 90)
    rebirthButton.BackgroundColor3 = Color3.new(1, 0.5, 0)
    rebirthButton.BorderSizePixel = 0
    rebirthButton.Text = "✨ REBIRTH (1000)"
    rebirthButton.TextColor3 = Color3.new(1, 1, 1)
    rebirthButton.TextStrokeTransparency = 0
    rebirthButton.TextStrokeColor3 = Color3.new(0, 0, 0)
    rebirthButton.TextSize = 10
    rebirthButton.Font = Enum.Font.SourceSansBold
    rebirthButton.Parent = leftFrame
    
    local rebirthCorner = Instance.new("UICorner")
    rebirthCorner.CornerRadius = UDim.new(0, 4)
    rebirthCorner.Parent = rebirthButton
    

    
    return screenGui, topFrame, leftFrame, coinsLabel, speedLabel, launchButton, upgradeButton, rebirthButton, rebirthsTopLabel
end

-- Create the GUI
local screenGui, topFrame, leftFrame, coinsLabel, speedLabel, launchButton, upgradeButton, rebirthButton, rebirthsTopLabel = createGUI()

-- Player data
local playerData = {
    coins = 0,
    speedLevel = 1,
    bestDistance = 0,
    rebirths = 0
}

-- Flying distance display
local flyingDistanceLabel = nil
local isFlying = false

-- Update GUI
local function updateGUI()
    coinsLabel.Text = "Coins: " .. playerData.coins
    speedLabel.Text = "Speed: " .. playerData.speedLevel
    rebirthsTopLabel.Text = "Rebirths: " .. playerData.rebirths
    
    -- Calculate upgrade cost
    local upgradeCost = math.floor(10 * (1.5 ^ (playerData.speedLevel - 1)))
    upgradeButton.Text = "⬆️ UPGRADE (" .. upgradeCost .. ")"
    
    -- Update rebirth button
    rebirthButton.Text = "✨ REBIRTH (1000)"
    
    -- Disable upgrade button if not enough coins
    if playerData.coins < upgradeCost then
        upgradeButton.BackgroundColor3 = Color3.new(0.5, 0.2, 0.2)
    else
        upgradeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    end
    
    -- Disable rebirth button if not enough coins
    if playerData.coins < 1000 then
        rebirthButton.BackgroundColor3 = Color3.new(0.5, 0.25, 0)
    else
        rebirthButton.BackgroundColor3 = Color3.new(1, 0.5, 0)
    end
end

-- Button handlers
launchButton.MouseButton1Click:Connect(function()
    print("Launch button clicked!")
    launchEvent:FireServer()
end)

upgradeButton.MouseButton1Click:Connect(function()
    print("Upgrade button clicked!")
    upgradeEvent:FireServer()
end)

rebirthButton.MouseButton1Click:Connect(function()
    print("Rebirth button clicked!")
    rebirthEvent:FireServer()
end)

-- Keyboard shortcuts
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.E then
        print("E key pressed - launching!")
        launchEvent:FireServer()
    elseif input.KeyCode == Enum.KeyCode.R then
        print("R key pressed - upgrading!")
        upgradeEvent:FireServer()
    elseif input.KeyCode == Enum.KeyCode.T then
        print("T key pressed - rebirthing!")
        rebirthEvent:FireServer()
    end
end)

-- Handle server updates
coinUpdateEvent.OnClientEvent:Connect(function(coins, distance, bestDistance, rebirths)
    print("Received coin update:", coins, distance, bestDistance, rebirths)
    playerData.coins = coins
    playerData.bestDistance = bestDistance
    if rebirths ~= nil then
        playerData.rebirths = rebirths
    end
    updateGUI()
end)

upgradeEvent.OnClientEvent:Connect(function(success, newLevel, nextCost)
    print("Received upgrade response:", success, newLevel, nextCost)
    if success then
        playerData.speedLevel = newLevel
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[SUCCESS] Upgraded to Speed Level " .. newLevel;
            Color = Color3.new(0, 1, 0);
            Font = Enum.Font.SourceSansBold;
        })
    else
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[ERROR] Not enough coins for upgrade!";
            Color = Color3.new(1, 0, 0);
            Font = Enum.Font.SourceSansBold;
        })
    end
    updateGUI()
end)

rebirthEvent.OnClientEvent:Connect(function(success, newRebirthCount)
    print("Received rebirth response:", success, newRebirthCount)
    if success then
        playerData.rebirths = newRebirthCount
        playerData.speedLevel = 1
        playerData.bestDistance = 0
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[REBIRTH] You have rebirthed! Now at Rebirth " .. newRebirthCount .. " - 50% more coins!";
            Color = Color3.new(1, 0.5, 0);
            Font = Enum.Font.SourceSansBold;
        })
    else
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[ERROR] Not enough coins for rebirth! Need 1000 coins.";
            Color = Color3.new(1, 0, 0);
            Font = Enum.Font.SourceSansBold;
        })
    end
    updateGUI()
end)

-- Create flying distance display
local function createFlyingDistanceLabel()
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "FlyingDistanceLabel"
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0) -- Position above head
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
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Parent = frame
    
    return billboardGui, label
end

-- Create the flying distance label
flyingDistanceLabel, flyingDistanceTextLabel = createFlyingDistanceLabel()

-- Handle real-time distance updates
distanceUpdateEvent.OnClientEvent:Connect(function(distance, isFlyingUpdate)
    if isFlyingUpdate then
        -- Player is currently flying
        if not isFlying then
            isFlying = true
            -- Attach to character's head
            local character = player.Character or player.CharacterAdded:Wait()
            local head = character:WaitForChild("Head")
            flyingDistanceLabel.Parent = head
            flyingDistanceLabel.Enabled = true
        end
        flyingDistanceTextLabel.Text = math.floor(distance) .. " studs"
    else
        -- Player has landed
        isFlying = false
        flyingDistanceLabel.Enabled = false
        flyingDistanceLabel.Parent = nil
    end
end)

-- Initialize GUI
updateGUI()

print("CannonGameClient script loaded successfully!")