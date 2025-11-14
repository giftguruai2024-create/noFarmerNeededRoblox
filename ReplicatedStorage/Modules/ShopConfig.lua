-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
--// ShopConfig.lua
--// Defines all shop items, prices, and categories

local ShopConfig = {}

-- Shop items organized by category
ShopConfig.Items = {
	Seeds = {
		{
			Name = "Wheat",
			DisplayName = "Wheat Seeds",
			Price = 1,
			Description = "Basic crop, grows quickly",
			Icon = "rbxassetid://0",  -- Replace with actual icon ID
			InventoryType = "Seeds"
		},
		{
			Name = "Corn",
			DisplayName = "Corn Seeds",
			Price = 2,
			Description = "Medium-value crop",
			Icon = "rbxassetid://0",  -- Replace with actual icon ID
			InventoryType = "Seeds"
		},
		{
			Name = "Tomato",
			DisplayName = "Tomato Seeds",
			Price = 3,
			Description = "High-value crop",
			Icon = "rbxassetid://0",  -- Replace with actual icon ID
			InventoryType = "Seeds"
		},
		{
			Name = "Carrot",
			DisplayName = "Carrot Seeds",
			Price = 2,
			Description = "Root vegetable, steady profit",
			Icon = "rbxassetid://0",  -- Replace with actual icon ID
			InventoryType = "Seeds"
		},
	},

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
