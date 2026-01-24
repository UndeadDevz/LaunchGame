--!strict
-- LOCATION: StarterPlayerScripts/ShopController

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- [ MODULES ]
local ProductConfigurations = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProductConfigurations"))
local ItemConfigurations = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemConfigurations"))
local NumberFormatter = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("NumberFormatter"))

-- [ UI REFERENCES ]
local gui = playerGui:WaitForChild("GUI")
local frames = gui:WaitForChild("Frames")
local shopFrame = frames:WaitForChild("Shop")
local scrolling = shopFrame:WaitForChild("Scrolling")

-- [ HELPER ]
local function findTextLabel(parent: Instance): TextLabel?
	local label = parent:FindFirstChild("Text")
	if label and label:IsA("TextLabel") then return label end
	return parent:FindFirstChildWhichIsA("TextLabel", true)
end

-- [ LOGIC: PACKS (GamePasses) ]
local function setupPackUI(packName: string, containerName: string)
	local packFrame = scrolling:WaitForChild(containerName, 5)
	if not packFrame then return end

	local passId = ProductConfigurations.GamePasses[packName]
	local rewards = ProductConfigurations.PackRewards[packName]
	if not passId or not rewards then return end

	local buyButton = packFrame:WaitForChild("Buy", 5) :: GuiButton
	if buyButton then
		buyButton.MouseButton1Click:Connect(function()
			MarketplaceService:PromptGamePassPurchase(player, passId)
		end)
		task.spawn(function()
			local priceText = findTextLabel(buyButton)
			if priceText then
				local success, info = pcall(function() return MarketplaceService:GetProductInfo(passId, Enum.InfoType.GamePass) end)
				priceText.Text = if success and info then "" .. tostring(info.PriceInRobux) else "N/A"
			end
		end)
	end

	local reciveFrame = packFrame:WaitForChild("Recive", 5)
	if reciveFrame then
		for i, itemData in ipairs(rewards.Items) do
			local itemFrame = reciveFrame:FindFirstChild("Item" .. i)
			if itemFrame then
				local imgLabel = itemFrame:FindFirstChild("Image") :: ImageLabel
				local nameLabel = findTextLabel(itemFrame)
				if imgLabel then
					local gItem = ItemConfigurations.GetItemData(itemData.Name)
					if gItem then imgLabel.Image = gItem.ImageId end
				end
				if nameLabel then nameLabel.Text = itemData.Name end
			end
		end
		local cashFrame = reciveFrame:FindFirstChild("Cash1")
		if cashFrame then
			local cashLabel = findTextLabel(cashFrame)
			if cashLabel then cashLabel.Text = "$" .. NumberFormatter.Format(rewards.Money) end
		end
	end
end

-- [ LOGIC: ITEMS ONLY (Dev Products) ]
local function setupItemsOnlyUI()
	local container = scrolling:WaitForChild("ItemsOnly", 5)
	if not container then warn("ItemsOnly frame missing") return end

	local recive = container:WaitForChild("Recive", 5)
	if not recive then warn("ItemsOnly.Recive missing") return end

	for i = 1, 3 do
		local productKey = "ItemProduct" .. i
		local productId = ProductConfigurations.Products[productKey]
		local rewardData = ProductConfigurations.ItemProductRewards[productKey]

		local itemFrame = recive:WaitForChild("Item" .. i, 5)

		if itemFrame and productId and rewardData then
			-- Name & Image
			local imgLabel = itemFrame:FindFirstChild("Image") :: ImageLabel
			local nameLabel = itemFrame:FindFirstChild("Name") :: TextLabel

			if nameLabel then nameLabel.Text = rewardData.Name end
			if imgLabel then
				local gItem = ItemConfigurations.GetItemData(rewardData.Name)
				if gItem then imgLabel.Image = gItem.ImageId end
			end

			-- Buy Button
			local buyButton = itemFrame:WaitForChild("Buy") :: GuiButton
			if buyButton then
				buyButton.MouseButton1Click:Connect(function()
					MarketplaceService:PromptProductPurchase(player, productId)
				end)
				task.spawn(function()
					local priceText = findTextLabel(buyButton)
					if priceText then
						local success, info = pcall(function()
							return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
						end)
						priceText.Text = if success and info then "" .. tostring(info.PriceInRobux) else "N/A"
					end
				end)
			end
		end
	end
end

-- [ ## ADDED: CASH ONLY LOGIC (Dev Products) ## ]
local function setupCashOnlyUI()
	local container = scrolling:WaitForChild("CashOnly", 5)
	if not container then warn("CashOnly frame missing") return end

	local recive = container:WaitForChild("Recive", 5)
	if not recive then warn("CashOnly.Recive missing") return end

	-- We loop 3 times: Cash1, Cash2, Cash3
	for i = 1, 3 do
		local productKey = "CashProduct" .. i
		local productId = ProductConfigurations.Products[productKey]
		local cashAmount = ProductConfigurations.CashProductRewards[productKey]

		local cashFrame = recive:WaitForChild("Cash" .. i, 5)

		if cashFrame and productId and cashAmount then
			-- Update Amount Text (Not overwriting image)
			local amountLabel = findTextLabel(cashFrame)
			if amountLabel then
				amountLabel.Text = "$" .. NumberFormatter.Format(cashAmount)
			end

			-- Buy Button
			local buyButton = cashFrame:WaitForChild("Buy") :: GuiButton
			if buyButton then
				buyButton.MouseButton1Click:Connect(function()
					MarketplaceService:PromptProductPurchase(player, productId)
				end)

				-- Fetch Price
				task.spawn(function()
					local priceText = findTextLabel(buyButton)
					if priceText then
						local success, info = pcall(function()
							return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
						end)
						priceText.Text = if success and info then "" .. tostring(info.PriceInRobux) else "N/A"
					end
				end)
			end
		end
	end
end

-- [ LOGIC: PERMANENT PRODUCTS (One-time purchases) ]
local PERMANENT_PRODUCT_INFO = {
	{ Key = "MoreStorage1", DisplayName = "+50 Pet Storage" },
	{ Key = "MoreStorage2", DisplayName = "+250 Pet Storage" },
	{ Key = "MorePets1", DisplayName = "+3 Pets Equipped" },
	{ Key = "TripleEgg", DisplayName = "Triple Egg Hatch" },
	{ Key = "Lucky", DisplayName = "2x Luck" },
	{ Key = "AutoEgg", DisplayName = "Auto Egg Hatch" },
}

local function setupPermanentProductsUI()

    local containers = {
        scrolling:FindFirstChild("Upgrades"),
        scrolling:FindFirstChild("Upgrades1")
    }

    -- Verificar si los contenedores existen
    for i, c in ipairs(containers) do
        if not c then 
            warn("⚠️ DEBUG: Contenedor " .. (i == 1 and "Upgrades" or "Upgrades1") .. " NO encontrado en scrolling.")
        else
            print("📂 DEBUG: Contenedor encontrado:", c.Name)
        end
    end

    for _, info in ipairs(PERMANENT_PRODUCT_INFO) do

        local productId = ProductConfigurations.PermanentProducts[info.Key]
        if not productId or productId == 0 then 
            warn("❌ DEBUG: No hay ProductID configurado para la Key:", info.Key)
            continue 
        end

        -- Buscamos el frame en la ruta: Upgrades/Upgrades1 -> Recive -> Key
        local itemFrame = nil
        for _, container in ipairs(containers) do
            if container then
                local recive = container:FindFirstChild("Recive")
                if recive then
                    itemFrame = recive:FindFirstChild(info.Key)
                    if itemFrame then 
                        break 
                    end
                else
                    warn("⚠️ DEBUG: El contenedor", container.Name, "no tiene una carpeta llamada 'Recive'.")
                end
            end
        end

        if not itemFrame then 
            warn("🛑 DEBUG: No se pudo localizar el frame para '" .. info.Key .. "' en ninguno de los contenedores.")
            continue 
        end

        -- Referencias a la UI
        local nameLabel = itemFrame:FindFirstChild("Name") :: TextLabel
        local buyButton = itemFrame:FindFirstChild("Buy") :: TextButton
        local ownedLabel = itemFrame:FindFirstChild("Owned") :: TextLabel

        if nameLabel then
            nameLabel.Text = info.DisplayName
        else
            print("📝 DEBUG: (Opcional) No se encontró el Label 'Name' en", info.Key)
        end

        -- Función para refrescar el estado Visual
        local function updateVisualState()
            local isOwned = player:GetAttribute(info.Key) == true
            if buyButton then buyButton.Visible = not isOwned end
            if ownedLabel then ownedLabel.Visible = isOwned end
        end

        -- Configuración inicial
        updateVisualState()

        -- Lógica de Compra
        if buyButton then
            if not (player:GetAttribute(info.Key) == true) then
                buyButton.MouseButton1Click:Connect(function()
                    MarketplaceService:PromptProductPurchase(player, productId)
                end)

                -- Obtener Precio
                task.spawn(function()
                    local priceText = findTextLabel(buyButton)
                    if priceText then
                        local success, productInfo = pcall(function()
                            return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
                        end)
                        if success and productInfo then
                            priceText.Text = "" .. tostring(productInfo.PriceInRobux)
                        else
                            warn("❌ DEBUG: Error al obtener info del producto", productId)
                            priceText.Text = "N/A"
                        end
                    end
                end)
            end
        else
            warn("⚠️ DEBUG: El item", info.Key, "no tiene un botón llamado 'Buy'.")
        end

        -- Escuchar cambios en los atributos
        player:GetAttributeChangedSignal(info.Key):Connect(function()
            updateVisualState()
        end)
    end
end
-- [ INIT ]
task.spawn(function() setupPackUI("StarterPack", "StarterPack") end)
task.spawn(function() setupPackUI("ProPack", "ProPack") end)
task.spawn(setupItemsOnlyUI)
task.spawn(setupCashOnlyUI)
task.spawn(setupPermanentProductsUI)

print("[ShopController] Loaded")