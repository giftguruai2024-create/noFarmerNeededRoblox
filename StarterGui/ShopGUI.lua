-- @ScriptType: LocalScript

-- @ScriptType: LocalScript
--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Get player and modules
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--// Load modules
local ModuleLoader = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModuleLoader"))
local CropStats = ModuleLoader:Get("CropStatsModule")
local EventBus = ModuleLoader:Get("EventBus")

--// Configuration
local SHOP_CONFIG = {
	Colors = {
		Primary = Color3.fromRGB(20, 25, 35),
		Secondary = Color3.fromRGB(35, 45, 60),
		Accent = Color3.fromRGB(76, 175, 80),
		AccentDark = Color3.fromRGB(56, 155, 60),
		TabActive = Color3.fromRGB(76, 175, 80),
		TabInactive = Color3.fromRGB(70, 80, 95),
		TabHover = Color3.fromRGB(85, 95, 110),
		Text = Color3.fromRGB(255, 255, 255),
		TextSecondary = Color3.fromRGB(200, 200, 200),
		ItemBg = Color3.fromRGB(40, 50, 65),
		ItemHover = Color3.fromRGB(55, 70, 90),
		Gold = Color3.fromRGB(255, 193, 7),
		Success = Color3.fromRGB(76, 175, 80),
		Danger = Color3.fromRGB(244, 67, 54)
	},
	ItemSize = UDim2.new(0, 140, 0, 200)
}

--// Get existing ScreenGui from PlayerGui
local shopGui = playerGui:WaitForChild("ShopGui")

--// Reference to existing main shop frame
local mainFrame = shopGui:WaitForChild("MainFrame")

--// Reference existing title bar
local titleBar = mainFrame:WaitForChild("TitleBar")
local titleText = titleBar:WaitForChild("TitleText")
local closeButton = titleBar:WaitForChild("CloseButton")

--// Reference existing tab frame
local tabFrame = mainFrame:WaitForChild("TabFrame")

--// Reference existing content frame
local contentFrame = mainFrame:WaitForChild("ContentFrame")
local contentLayout = contentFrame:WaitForChild("UIGridLayout")

--// Tab data
local tabs = {
	{name = "Seeds", displayName = "🌱 Seeds"},
	{name = "Tools", displayName = "🔧 Tools"},
	{name = "Drones", displayName = "🚁 Drones"}
}

--// Reference existing tabs
local tabButtons = {}
local currentTab = "Seeds"

-- Wait for existing tab buttons
for _, tabData in ipairs(tabs) do
	local tabButton = tabFrame:WaitForChild(tabData.name .. "Tab")

	tabButtons[tabData.name] = {
		button = tabButton,
		stroke = tabButton:FindFirstChild("UIStroke"),
		data = tabData
	}

	--// Tab hover effects
	tabButton.MouseEnter:Connect(function()
		if currentTab ~= tabData.name then
			tabButton.BackgroundColor3 = SHOP_CONFIG.Colors.TabHover
		end
	end)

	tabButton.MouseLeave:Connect(function()
		if currentTab ~= tabData.name then
			tabButton.BackgroundColor3 = SHOP_CONFIG.Colors.TabInactive
		end
	end)

	--// Tab click handler
	tabButton.MouseButton1Click:Connect(function()
		currentTab = tabData.name
		updateTabButtons()
		loadTabContent(tabData.name)
	end)
end

--// Update tab button appearances
function updateTabButtons()
	for tabName, tabInfo in pairs(tabButtons) do
		if tabName == currentTab then
			tabInfo.button.BackgroundColor3 = SHOP_CONFIG.Colors.TabActive
			tabInfo.button.TextColor3 = SHOP_CONFIG.Colors.Text
			tabInfo.stroke.Color = SHOP_CONFIG.Colors.Accent
			tabInfo.stroke.Thickness = 2
		else
			tabInfo.button.BackgroundColor3 = SHOP_CONFIG.Colors.TabInactive
			tabInfo.button.TextColor3 = SHOP_CONFIG.Colors.TextSecondary
			tabInfo.stroke.Color = SHOP_CONFIG.Colors.TabInactive
			tabInfo.stroke.Thickness = 1.5
		end
	end
end

--// Item click handler - sends purchase request to server
function onItemClicked(itemName, itemCost, itemTab)
	print("Attempting to purchase: " .. itemName .. " | Cost: " .. itemCost .. " | Tab: " .. itemTab)

	-- Send purchase request to server via EventBus
	EventBus.FireServer("PurchaseFromShop", {
		ItemName = itemName,
		Quantity = 1,  -- Purchase 1 item at a time
		Category = itemTab
	})
end

--// Load tab content
function loadTabContent(tabName)
	--// Clear current content
	for _, child in ipairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	if tabName == "Seeds" then
		--// Load seeds from CropStats
		for cropName, cropData in pairs(CropStats.Crops) do
			createShopItem(cropName, cropData.seedCost, "Seeds", "🌾")
		end

	elseif tabName == "Tools" then
		--// Load tools (example items - customize as needed)
		local tools = {
			{name = "Watering Can", cost = 50, icon = "💧"},
			{name = "Hoe", cost = 75, icon = "⛏️"},
			{name = "Harvester", cost = 150, icon = "🔗"},
			{name = "Planter", cost = 100, icon = "🌱"}
		}
		for _, tool in ipairs(tools) do
			createShopItem(tool.name, tool.cost, "Tools", tool.icon)
		end

	elseif tabName == "Drones" then
		--// Load drones (example items - customize as needed)
		local drones = {
			{name = "Scout Drone", cost = 500, icon = "🚁"},
			{name = "Carrier Drone", cost = 1000, icon = "🚀"},
			{name = "Advanced Drone", cost = 2000, icon = "👾"},
			{name = "Mega Drone", cost = 5000, icon = "🛸"}
		}
		for _, drone in ipairs(drones) do
			createShopItem(drone.name, drone.cost, "Drones", drone.icon)
		end
	end

	--// Update canvas size
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
end

--// Create individual shop item
function createShopItem(itemName, itemCost, itemTab, icon)
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = itemName
	itemFrame.Size = SHOP_CONFIG.ItemSize
	itemFrame.BackgroundColor3 = SHOP_CONFIG.Colors.ItemBg
	itemFrame.BorderSizePixel = 0
	itemFrame.Parent = contentFrame

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 10)
	itemCorner.Parent = itemFrame

	local itemStroke = Instance.new("UIStroke")
	itemStroke.Color = SHOP_CONFIG.Colors.Secondary
	itemStroke.Thickness = 1.5
	itemStroke.Parent = itemFrame

	--// Icon/display area
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "IconLabel"
	iconLabel.Size = UDim2.new(1, 0, 0, 90)
	iconLabel.BackgroundColor3 = SHOP_CONFIG.Colors.Secondary
	iconLabel.TextColor3 = SHOP_CONFIG.Colors.Text
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Text = icon
	iconLabel.BorderSizePixel = 0
	iconLabel.Parent = itemFrame

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 10)
	iconCorner.Parent = iconLabel

	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = SHOP_CONFIG.Colors.Accent
	iconStroke.Thickness = 1
	iconStroke.Parent = iconLabel

	--// Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -12, 0, 35)
	nameLabel.Position = UDim2.new(0, 6, 0, 95)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = SHOP_CONFIG.Colors.Text
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = itemName
	nameLabel.TextWrapped = true
	nameLabel.Parent = itemFrame

	--// Cost label with gold color
	local costLabel = Instance.new("TextLabel")
	costLabel.Name = "CostLabel"
	costLabel.Size = UDim2.new(1, -12, 0, 22)
	costLabel.Position = UDim2.new(0, 6, 0, 130)
	costLabel.BackgroundTransparency = 1
	costLabel.TextColor3 = SHOP_CONFIG.Colors.Gold
	costLabel.TextScaled = true
	costLabel.Font = Enum.Font.GothamBold
	costLabel.Text = "💰 " .. itemCost
	costLabel.Parent = itemFrame

	--// Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Size = UDim2.new(1, -12, 0, 35)
	buyButton.Position = UDim2.new(0, 6, 0, 160)
	buyButton.BackgroundColor3 = SHOP_CONFIG.Colors.Accent
	buyButton.TextColor3 = SHOP_CONFIG.Colors.Text
	buyButton.TextScaled = true
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Text = "BUY"
	buyButton.BorderSizePixel = 0
	buyButton.Parent = itemFrame

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 6)
	buyCorner.Parent = buyButton

	local buyStroke = Instance.new("UIStroke")
	buyStroke.Color = SHOP_CONFIG.Colors.AccentDark
	buyStroke.Thickness = 1.5
	buyStroke.Parent = buyButton

	--// Enhanced button interactions with smooth animation
	local isHovering = false
	buyButton.MouseEnter:Connect(function()
		isHovering = true
		buyButton.BackgroundColor3 = SHOP_CONFIG.Colors.AccentDark
		itemFrame.BackgroundColor3 = SHOP_CONFIG.Colors.ItemHover
		itemStroke.Color = SHOP_CONFIG.Colors.Accent
		itemStroke.Thickness = 2
	end)

	buyButton.MouseLeave:Connect(function()
		isHovering = false
		buyButton.BackgroundColor3 = SHOP_CONFIG.Colors.Accent
		itemFrame.BackgroundColor3 = SHOP_CONFIG.Colors.ItemBg
		itemStroke.Color = SHOP_CONFIG.Colors.Secondary
		itemStroke.Thickness = 1.5
	end)

	buyButton.MouseButton1Click:Connect(function()
		onItemClicked(itemName, itemCost, itemTab)
	end)
end

--// Reference existing shop button
local shopButton = shopGui:WaitForChild("ShopButton")

--// Shop button interactions
shopButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
	if mainFrame.Visible then
		updateTabButtons()
		loadTabContent(currentTab)
	end
end)

--// Close button hover effects
closeButton.MouseEnter:Connect(function()
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 87, 87)
end)

closeButton.MouseLeave:Connect(function()
	closeButton.BackgroundColor3 = SHOP_CONFIG.Colors.Danger
end)

--// Close button handler
closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)

--//////////////////////////////////////////////////////////
-- EVENT LISTENERS
--//////////////////////////////////////////////////////////

--// Listen for purchase results from server
EventBus.OnClientEvent("ItemPurchased", function(data)
	if data.Success then
		print("✅ Purchase successful: " .. data.Message)

		-- Show success feedback to player (you can add UI notification here)
		local successMessage = Instance.new("TextLabel")
		successMessage.Size = UDim2.new(0, 300, 0, 60)
		successMessage.Position = UDim2.new(0.5, -150, 0.1, 0)
		successMessage.BackgroundColor3 = SHOP_CONFIG.Colors.Success
		successMessage.TextColor3 = SHOP_CONFIG.Colors.Text
		successMessage.Font = Enum.Font.GothamBold
		successMessage.TextScaled = true
		successMessage.Text = "✅ " .. data.Message
		successMessage.BorderSizePixel = 0
		successMessage.Parent = shopGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = successMessage

		-- Fade out and destroy after 3 seconds
		task.delay(3, function()
			successMessage:Destroy()
		end)
	else
		print("❌ Purchase failed: " .. data.Message)

		-- Show error feedback to player
		local errorMessage = Instance.new("TextLabel")
		errorMessage.Size = UDim2.new(0, 300, 0, 60)
		errorMessage.Position = UDim2.new(0.5, -150, 0.1, 0)
		errorMessage.BackgroundColor3 = SHOP_CONFIG.Colors.Danger
		errorMessage.TextColor3 = SHOP_CONFIG.Colors.Text
		errorMessage.Font = Enum.Font.GothamBold
		errorMessage.TextScaled = true
		errorMessage.Text = "❌ " .. data.Message
		errorMessage.BorderSizePixel = 0
		errorMessage.Parent = shopGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = errorMessage

		-- Fade out and destroy after 3 seconds
		task.delay(3, function()
			errorMessage:Destroy()
		end)
	end
end)

--// Listen for currency updates from server
local playerCurrency = 0
EventBus.OnClientEvent("CurrencyUpdated", function(data)
	playerCurrency = data.Currency
	print("💰 Currency updated: $" .. playerCurrency)

	-- Update currency display if you add one to the UI
	-- You can add a currency label to the shop UI here
end)

--//////////////////////////////////////////////////////////
-- INITIALIZATION
--//////////////////////////////////////////////////////////

--// Initialize
updateTabButtons()
loadTabContent("Seeds")

print("Shop GUI loaded successfully!")