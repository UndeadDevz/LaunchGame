--!strict
-- LOCATION: StarterPlayerScripts/CodesController

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- [ ASSETS ]
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RedeemCodeEvent = Remotes:WaitForChild("RedeemCode") -- Cambiado a RemoteFunction si esperas respuesta

-- [ UI REFERENCES ]
local gui = playerGui:WaitForChild("GUI")
local frames = gui:WaitForChild("Frames")
local codesFrame = frames:WaitForChild("Codes")

local inputField = codesFrame:WaitForChild("CodesBox") :: TextBox
local redeemBtn = codesFrame:WaitForChild("Redeem") :: GuiButton

-- [ STATE ]
local isRedeeming = false

-- [ LOGIC ]

local function showFeedback(text: string, color: Color3)
   return
end

local function onRedeemClicked()
    if isRedeeming then return end
    
    local codeText = inputField.Text
    -- Limpieza básica del texto
    codeText = string.gsub(codeText, "%s+", "") -- Elimina espacios
    
    if #codeText < 1 then
        showFeedback("ENTER A CODE!", Color3.fromRGB(255, 100, 100))
        return 
    end

    isRedeeming = true
    redeemBtn.Active = false
    
    -- Usamos InvokeServer si el servidor devuelve un mensaje de éxito/error
    -- Si es un RemoteEvent, simplemente usamos FireServer
    local success, responseMessage = RedeemCodeEvent:FireServer(codeText)
    
    if success then
        showFeedback(responseMessage or "SUCCESS!", Color3.fromRGB(100, 255, 100))
        inputField.Text = "" -- Limpiamos el input
    else
        showFeedback(responseMessage or "INVALID CODE!", Color3.fromRGB(255, 80, 80))
    end
    
    task.wait(1) -- Debounce de 1 segundo
    isRedeeming = false
    redeemBtn.Active = true
end

-- [ CONNECTIONS ]

redeemBtn.MouseButton1Click:Connect(onRedeemClicked)

-- Opcional: Permitir redimir al presionar "Enter" en el teclado
inputField.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        onRedeemClicked()
    end
end)

print("[CodesController] Loaded")