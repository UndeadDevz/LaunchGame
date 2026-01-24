--!strict
-- LOCATION: StarterPlayerScripts/UIEffects

-- Services
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

print("[UIEffects] Initialized (StarterPlayerScripts)")

-- Assets
local Templates = ReplicatedStorage:WaitForChild("Templates")
local shineTemplate: ImageLabel? = Templates:FindFirstChild("ShineEffectTemplate")
local globalSounds = Workspace:WaitForChild("Sounds")

-- Player
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Script State
local activeShineThreads: {[GuiObject]: thread} = {}
local activePulseData: {[GuiObject]: {TweenIn: Tween, TweenOut: Tween, Scale: UIScale, CreatedScale: boolean}} = {}
local sunburstObjects: {[GuiObject]: boolean} = {}
local buttonConnections: {[GuiButton]: {RBXScriptConnection}} = {}

-- Configuration
local SOUND_DEBOUNCE_TIME = 0.05
local lastSoundTime = 0

local HOVER_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local CLICK_TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
local HOVER_SCALE = 1.05
local CLICK_SCALE = 0.95

--================------------------------------------------------
-- ## SOUND LOGIC ##
--================------------------------------------------------
local function playLocalSound(soundName: string)
	local now = tick()
	if now - lastSoundTime < SOUND_DEBOUNCE_TIME then return end
	lastSoundTime = now

	local soundTemplate = globalSounds:FindFirstChild(soundName)
	if soundTemplate and soundTemplate:IsA("Sound") then
		local newSound = soundTemplate:Clone()
		newSound.Parent = playerGui
		newSound:Play()
		Debris:AddItem(newSound, newSound.TimeLength + 0.1)
	end
end

--================------------------------------------------------
-- ## BUTTON ANIMATION LOGIC (Universal) ##
--================------------------------------------------------
local function applyUniversalButtonLogic(button: GuiButton)
	if buttonConnections[button] then return end

	local useUIScale = true

	if button:FindFirstAncestorOfClass("ScrollingFrame") then
		useUIScale = false
	end

	local originalSize = button.Size
	local uiScale: UIScale

	if useUIScale then
		uiScale = button:FindFirstChildOfClass("UIScale")
		if not uiScale then
			uiScale = Instance.new("UIScale")
			uiScale.Name = "EffectScale"
			uiScale.Parent = button
		end
		uiScale.Scale = 1
	end

	local connections = {}

	table.insert(connections, button.MouseEnter:Connect(function()
		playLocalSound("Hover")
		if useUIScale and uiScale then
			TweenService:Create(uiScale, HOVER_TWEEN_INFO, {Scale = HOVER_SCALE}):Play()
		else
			TweenService:Create(button, HOVER_TWEEN_INFO, {
				Size = UDim2.new(originalSize.X.Scale * HOVER_SCALE, originalSize.X.Offset, originalSize.Y.Scale * HOVER_SCALE, originalSize.Y.Offset)
			}):Play()
		end
	end))

	table.insert(connections, button.MouseLeave:Connect(function()
		if useUIScale and uiScale then
			TweenService:Create(uiScale, HOVER_TWEEN_INFO, {Scale = 1}):Play()
		else
			TweenService:Create(button, HOVER_TWEEN_INFO, {Size = originalSize}):Play()
		end
	end))

	table.insert(connections, button.MouseButton1Down:Connect(function()
		playLocalSound("Click")
		if useUIScale and uiScale then
			TweenService:Create(uiScale, CLICK_TWEEN_INFO, {Scale = CLICK_SCALE}):Play()
		else
			TweenService:Create(button, CLICK_TWEEN_INFO, {
				Size = UDim2.new(originalSize.X.Scale * CLICK_SCALE, originalSize.X.Offset, originalSize.Y.Scale * CLICK_SCALE, originalSize.Y.Offset)
			}):Play()
		end
	end))

	table.insert(connections, button.MouseButton1Up:Connect(function()
		if useUIScale and uiScale then
			TweenService:Create(uiScale, CLICK_TWEEN_INFO, {Scale = HOVER_SCALE}):Play()
		else
			TweenService:Create(button, CLICK_TWEEN_INFO, {
				Size = UDim2.new(originalSize.X.Scale * HOVER_SCALE, originalSize.X.Offset, originalSize.Y.Scale * HOVER_SCALE, originalSize.Y.Offset)
			}):Play()
		end
	end))

	buttonConnections[button] = connections
end

local function cleanupButtonLogic(button: GuiButton)
	if buttonConnections[button] then
		for _, conn in ipairs(buttonConnections[button]) do
			conn:Disconnect()
		end
		buttonConnections[button] = nil
	end
end

--================------------------------------------------------
-- ## EFFECTS (Sunburst, Shine, Pulse) ##
--================------------------------------------------------
local SUNBURST_ROTATION_SPEED = 20
local function applySunburstEffect(guiObject: GuiObject) sunburstObjects[guiObject] = true end
local function cleanupSunburstEffect(guiObject: GuiObject) sunburstObjects[guiObject] = nil end

RunService.Heartbeat:Connect(function(dt: number)
	for guiObject, _ in pairs(sunburstObjects) do
		if guiObject.Parent then
			guiObject.Rotation = guiObject.Rotation + SUNBURST_ROTATION_SPEED * dt
		else
			cleanupSunburstEffect(guiObject)
		end
	end
end)

local SHINE_MIN_DELAY = 1; local SHINE_MAX_DELAY = 4
local SHINE_FADE_IN_TIME = 0.3; local SHINE_FADE_OUT_TIME = 0.7
local SHINE_MAX_ROTATION = 45; local SHINE_MAX_SIZE_SCALE = 1.5

local function applyShineEffect(guiObject: GuiObject)
	if not shineTemplate then return end
	local shineThread = coroutine.wrap(function()
		while guiObject.Parent do
			task.wait(math.random() * (SHINE_MAX_DELAY - SHINE_MIN_DELAY) + SHINE_MIN_DELAY)
			if not guiObject.Parent then break end
			local newShine = shineTemplate:Clone()
			newShine.Position = UDim2.fromScale(math.random(), math.random())
			newShine.ImageTransparency = 1
			newShine.Rotation = math.random(-SHINE_MAX_ROTATION, SHINE_MAX_ROTATION)
			newShine.Parent = guiObject
			local originalSize = newShine.Size
			local targetSize = UDim2.fromOffset(originalSize.X.Offset * SHINE_MAX_SIZE_SCALE, originalSize.Y.Offset * SHINE_MAX_SIZE_SCALE)
			local fadeInTween = TweenService:Create(newShine, TweenInfo.new(SHINE_FADE_IN_TIME, Enum.EasingStyle.Quad), { ImageTransparency = 0, Rotation = math.random(-SHINE_MAX_ROTATION, SHINE_MAX_ROTATION), Size = targetSize })
			local fadeOutTween = TweenService:Create(newShine, TweenInfo.new(SHINE_FADE_OUT_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { ImageTransparency = 1, Rotation = math.random(-SHINE_MAX_ROTATION, SHINE_MAX_ROTATION), Size = originalSize })
			fadeInTween:Play(); fadeInTween.Completed:Wait()
			if not newShine.Parent then break end
			fadeOutTween:Play(); fadeOutTween.Completed:Wait(); newShine:Destroy()
		end
	end)()
	activeShineThreads[guiObject] = shineThread
end
local function cleanupShineEffect(guiObject: GuiObject)
	if activeShineThreads[guiObject] then task.cancel(activeShineThreads[guiObject]); activeShineThreads[guiObject] = nil end
end

local PULSE_SCALE = 1.1; local PULSE_DURATION = 0.8
local PULSE_INFO = TweenInfo.new(PULSE_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local function applyPulseEffect(guiObject: GuiObject)
	if activePulseData[guiObject] then return end
	local uiScale = guiObject:FindFirstChildOfClass("UIScale")
	local createdScale = false
	if not uiScale then uiScale = Instance.new("UIScale"); uiScale.Name="EffectScale"; uiScale.Parent = guiObject; createdScale = true end
	local pulseTween = TweenService:Create(uiScale, PULSE_INFO, {Scale = PULSE_SCALE})
	pulseTween:Play()
	activePulseData[guiObject] = {TweenIn = pulseTween, TweenOut = pulseTween, Scale = uiScale, CreatedScale = createdScale}
end
local function cleanupPulseEffect(guiObject: GuiObject)
	local data = activePulseData[guiObject]
	if data then
		if data.TweenIn then data.TweenIn:Cancel() end
		if data.Scale and data.Scale.Parent then data.Scale.Scale = 1 end
		if data.CreatedScale and data.Scale then data.Scale:Destroy() end
		activePulseData[guiObject] = nil
	end
end

--================--------------------------------================
-- ## INITIALIZATION & MONITORS ##
--================================================================
local function setupTag(tagName: string, applyFunction: (Instance) -> (), cleanupFunction: (Instance) -> ())
	for _, instance in ipairs(CollectionService:GetTagged(tagName)) do coroutine.wrap(applyFunction)(instance) end
	CollectionService:GetInstanceAddedSignal(tagName):Connect(function(instance: Instance) coroutine.wrap(applyFunction)(instance) end)
	CollectionService:GetInstanceRemovedSignal(tagName):Connect(function(instance: Instance) coroutine.wrap(cleanupFunction)(instance) end)
end

setupTag("SunburstEffect", applySunburstEffect, cleanupSunburstEffect)
setupTag("ShineEffect", applyShineEffect, cleanupShineEffect)
setupTag("PulseEffect", applyPulseEffect, cleanupPulseEffect)

local function processGuiElement(element: Instance)
	if element:IsA("TextButton") or element:IsA("ImageButton") then
		task.defer(function()
			if element and element.Parent then
				applyUniversalButtonLogic(element)
			end
		end)
	end
end

-- 1. Scan PlayerGui (2D UI)
for _, child in ipairs(playerGui:GetDescendants()) do processGuiElement(child) end
playerGui.DescendantAdded:Connect(processGuiElement)
playerGui.DescendantRemoving:Connect(function(element)
	if element:IsA("GuiButton") then cleanupButtonLogic(element) end
end)

-- 2. Scan Player's Plot (SurfaceGui Buttons)
local function monitorPlotUI()
	local plotName = "Plot_" .. player.Name
	local plot = Workspace:WaitForChild(plotName, 5)
	if not plot then return end

	-- Function to check new parts added to plot
	local function onPlotDescendantAdded(descendant: Instance)
		if descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
			task.wait() -- Allow attributes/properties to replicate
			applyUniversalButtonLogic(descendant)
		end
	end

	plot.DescendantAdded:Connect(onPlotDescendantAdded)

	-- Scan existing
	for _, child in ipairs(plot:GetDescendants()) do
		onPlotDescendantAdded(child)
	end
end

task.spawn(monitorPlotUI)