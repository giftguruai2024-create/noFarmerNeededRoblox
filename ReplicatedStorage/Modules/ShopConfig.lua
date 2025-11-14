-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
--// ShopConfig.lua
--// Defines all shop items, prices, and categories

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopConfig = {}

-- Load CropStatsModule to get seed prices
local CropStatsModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CropStatsModule"))

-- Dynamically generate Seeds items from CropStatsModule
local function GenerateSeedsFromCropStats()
	local seedsTable = {}

	for cropName, cropData in pairs(CropStatsModule.Crops) do
		table.insert(seedsTable, {
			Name = cropName,
			DisplayName = cropName .. " Seeds",
			Price = cropData.seedCost,  -- Use seedCost from CropStatsModule
			Description = string.format("Grows in %ds, Sells for $%d", cropData.growthTime, cropData.sellPrice),
			Icon = "🌾",  -- Default seed icon
			InventoryType = "Seeds"
		})
	end

	return seedsTable
end

-- Shop items organized by category
ShopConfig.Items = {
	Seeds = GenerateSeedsFromCropStats(),

	Drones = {
		{
			Name = "BasicDrone",
			DisplayName = "Basic Drone",
			Price = 10,
			Description = "Automates basic farming tasks",
			Icon = "rbxassetid://0",  -- Replace with actual icon ID
			InventoryType = "Drones"
		},
		{
			Name = "AdvancedDrone",
			DisplayName = "Advanced Drone",
			Price = 25,
			Description = "Faster and more efficient",
			Icon = "rbxassetid://0",  -- Replace with actual icon ID
			InventoryType = "Drones"
		},
		{
			Name = "MegaDrone",
			DisplayName = "Mega Drone",
			Price = 50,
			Description = "Top-tier automation",
			Icon = "rbxassetid://0",  -- Replace with actual icon ID
			InventoryType = "Drones"
		},
	},

	Tools = {
		{
			Name = "BasicHoe",
			DisplayName = "Basic Hoe",
			Price = 5,
			Description = "Essential farming tool",
			Icon = "rbxassetid://0",  -- Replace with actual icon ID
			InventoryType = "Tools"
		},
		{
			Name = "WateringCan",
			DisplayName = "Watering Can",
			Price = 8,
			Description = "Keep crops hydrated",
			Icon = "rbxassetid://0",  -- Replace with actual icon ID
			InventoryType = "Tools"
		},
		{
			Name = "Fertilizer",
			DisplayName = "Fertilizer",
			Price = 6,
			Description = "Speed up crop growth",
			Icon = "rbxassetid://0",  -- Replace with actual icon ID
			InventoryType = "Tools"
		},
	}
}

-- Get all items in a specific category
function ShopConfig:GetCategory(category)
	return self.Items[category] or {}
end

-- Get all categories
function ShopConfig:GetCategories()
	local categories = {}
	for categoryName, _ in pairs(self.Items) do
		table.insert(categories, categoryName)
	end
	return categories
end

-- Find an item by name across all categories
function ShopConfig:FindItem(itemName)
	for category, items in pairs(self.Items) do
		for _, item in ipairs(items) do
			if item.Name == itemName then
				return item
			end
		end
	end
	return nil
end

-- Get total number of items
function ShopConfig:GetTotalItemCount()
	local count = 0
	for _, items in pairs(self.Items) do
		count = count + #items
	end
	return count
end

return ShopConfig
