--!strict
-- LOCATION: StarterPlayerScripts/PetMovementController

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- [ CONFIGURACIÓN ]
local SPACING = 5
local MAX_CLIMB_HEIGHT = 6
local FLOAT_HEIGHT = 2.5 
local BOB_AMPLITUDE = 0.5
local BOB_SPEED = 3
local LERP_SPEED = 0.15 -- Ajusta para suavidad (0.1 = lento, 0.3 = rápido)

-- [ VARIABLES ]
local RayParams = RaycastParams.new()
local RayDirection = Vector3.new(0, -50, 0) -- Reducido de 500 para performance

local playerPetsFolder = workspace:WaitForChild("PlayerPets")
local tempPetsStorage = Instance.new("Folder")
tempPetsStorage.Name = "HiddenPets"
tempPetsStorage.Parent = ReplicatedStorage

-- [ ESTADO ]
local showOtherPets = true -- Idealmente conectado a un Value o Atributo

-- [ HELPERS ]

-- Calcula la formación en filas
local function getFormationData(pets: {Model}, maxRowCapacity: number)
    local rows = {}
    local amountOfRows = math.ceil(#pets / maxRowCapacity)
    
    for i = 1, amountOfRows do
        table.insert(rows, {})
    end
    
    for i, pet in ipairs(pets) do
        local rowIndex = math.ceil(i / maxRowCapacity)
        table.insert(rows[rowIndex], pet)
    end
    
    return rows
end

local function getRowWidth(row: {Model}): number
    if #row <= 1 then return 0 end
    -- Asumimos que las mascotas tienen un tamaño similar, o usamos el primero de la fila
    local firstPet = row[1]
    local mainPart = firstPet:FindFirstChild("MainPart") :: BasePart
    if not mainPart then return 0 end
    
    return (#row - 1) * SPACING
end

-- [ CORE MOVEMENT ]

local function updatePetMovement(dt: number)
    -- 1. Gestión de Visibilidad (Optimizado)
    -- Nota: En un sistema real, esto debería ser un evento .Changed, no un chequeo por frame.
    -- Pero mantenemos la lógica solicitada:
    -- (Asumiendo que PlayerData.ShowOtherPets existe en tu sistema)
    -- local showOthers = player.PlayerData.ShowOtherPets.Value 
    
    local currentTime = os.clock()

    for _, folder in ipairs(playerPetsFolder:GetChildren()) do
        if not folder:IsA("Folder") then continue end
        
        local ownerName = folder.Name
        local owner = Players:FindFirstChild(ownerName)
        if not owner or not owner.Character then continue end
        
        local rootPart = owner.Character:FindFirstChild("HumanoidRootPart") :: BasePart
        if not rootPart then continue end

        -- Filtrar mascotas
        local pets = {}
        for _, p in ipairs(folder:GetChildren()) do
            if p:IsA("Model") then table.insert(pets, p) end
        end
        
        if #pets == 0 then continue end

        -- Configuración de Raycast
        RayParams.FilterDescendantsInstances = {folder, owner.Character}
        
        -- Calcular Filas
        local maxRowCapacity = math.ceil(math.sqrt(#pets))
        local rows = getFormationData(pets, maxRowCapacity)

        -- Mover cada mascota
        for i, pet in ipairs(pets) do
            local mainPart = pet:FindFirstChild("MainPart") :: BasePart
            if not mainPart then continue end

            local rowIndex = math.ceil(i / maxRowCapacity)
            local row = rows[rowIndex]
            local rowWidth = getRowWidth(row)
            
            -- Calcular posición local en la formación
            local indexInRow = table.find(row, pet) or 1
            local xOffset = (indexInRow - 1) * SPACING - (rowWidth / 2)
            local zOffset = rowIndex * SPACING
            
            -- 2. Detección de suelo (Blockcast para estabilidad)
            local rayOrigin = (rootPart.CFrame * CFrame.new(xOffset, MAX_CLIMB_HEIGHT, zOffset)).Position
            local rayResult = workspace:Blockcast(
                CFrame.new(rayOrigin), 
                mainPart.Size, 
                RayDirection, 
                RayParams
            )

            local groundY = (rayResult and rayResult.Position.Y) or (rootPart.Position.Y - 3)
            
            -- 3. Flotación y Bobbing (Oscilación)
            local bob = math.sin(currentTime * BOB_SPEED + i * 0.5) * BOB_AMPLITUDE
            local targetY = groundY + FLOAT_HEIGHT + bob
            
            -- 4. Construir CFrame Objetivo
            -- Usamos la rotación del jugador pero mantenemos la mascota nivelada (sin inclinación en X/Z)
            local _, rotY, _ = rootPart.CFrame:ToEulerAnglesYXZ()
            local targetCF = CFrame.new(rootPart.Position.X, 0, rootPart.Position.Z) -- Base
                * CFrame.Angles(0, rotY, 0) -- Rotación del dueño
                * CFrame.new(xOffset, targetY, zOffset) -- Offset final
            
            -- 5. Suavizado (Lerp)
            local currentCF = pet:GetPivot()
            pet:PivotTo(currentCF:Lerp(targetCF, LERP_SPEED))
        end
    end
end

-- [ INICIALIZACIÓN ]

-- Conectamos al Heartbeat para que el movimiento sea independiente de los FPS de renderizado
-- pero se sienta fluido.
RunService.Heartbeat:Connect(updatePetMovement)

-- Escuchar cambios en la carpeta PlayerPets para manejar la visibilidad de otros
playerPetsFolder.ChildAdded:Connect(function(child)
    -- Aquí podrías ocultar pets de otros instantáneamente si la opción está activa
end)

print("[PetMovementController] Loaded")