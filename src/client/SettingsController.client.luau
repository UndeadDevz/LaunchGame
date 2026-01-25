--!strict
-- LOCATION: StarterPlayerScripts/SettingsController

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- [ MODULES ]
local Utilities = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Utilities"))

-- [ ASSETS ]
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SettingRemote = Remotes:WaitForChild("Setting")

-- [ DATA ]
local player = Players.LocalPlayer
local playerData = player:WaitForChild("Data")

-- [ UI REFERENCES ]
local gui = playerGui:WaitForChild("GUI")
local frames = gui:WaitForChild("Frames")
local settingsScroll = frames:WaitForChild("Settings"):WaitForChild("ObjectHolder")

-- [ MUSIC SETTING ]
local musicSetting = settingsScroll:WaitForChild("Music")
local musicOn = musicSetting.Toggle.On
local musicOff = musicSetting.Toggle.Off

Utilities.ButtonAnimations.Create(musicOn)
Utilities.ButtonAnimations.Create(musicOff)

musicOn.Click.MouseButton1Click:Connect(function()
    SettingRemote:FireServer("Music", true)
end)

musicOff.Click.MouseButton1Click:Connect(function()
    SettingRemote:FireServer("Music", false)
end)

-- Actualización de la música
local function updateMusic()
    local musicValue = playerData:WaitForChild("Music").Value
    SoundService.Music.PlaybackSpeed = musicValue and 1 or 0
end

playerData.Music.Changed:Connect(updateMusic)
updateMusic() -- Estado inicial

-- [ SHOW OTHER PETS ]
local showOtherPetsSetting = settingsScroll:WaitForChild("ShowOtherPets")
local showPetsOn = showOtherPetsSetting.Toggle.On
local showPetsOff = showOtherPetsSetting.Toggle.Off

Utilities.ButtonAnimations.Create(showPetsOn)
Utilities.ButtonAnimations.Create(showPetsOff)

showPetsOn.Click.MouseButton1Click:Connect(function()
    SettingRemote:FireServer("ShowOtherPets", true)
end)

showPetsOff.Click.MouseButton1Click:Connect(function()
    SettingRemote:FireServer("ShowOtherPets", false)
end)

print("[SettingsController] Loaded")