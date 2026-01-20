--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Variables
local Pets = ReplicatedStorage.Pets

--// Script

-- Start by setting all parts to cancollide = false
for _, Part in ReplicatedStorage.Pets:GetDescendants() do
	if Part:IsA("BasePart") then Part.CanCollide = false end
end