-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
--// InventoryModule.lua
--// Manages player inventories (seeds, drones, tools) with automatic data persistence

local InventoryModule = {}
local Players = game:GetService("Players")

-- Reference to DataHandler (will be set via SetDataHandler)
local DataHandler = nil

-- Get default inventory structure
local function CreateDefaultInventory()
	return {
		Seeds = {},      -- { ["SeedName"] = quantity, ... }
		Drones = {},     -- { ["DroneName"] = quantity, ... }
		Tools = {}       -- { ["ToolName"] = quantity, ... }
	}
end

-- Set the DataHandler reference (called from server to inject dependency)
function InventoryModule:SetDataHandler(dataHandlerModule)
	DataHandler = dataHandlerModule
	print("✅ InventoryModule: DataHandler reference set")
end

-- Initialize player inventory (called when player joins)
function InventoryModule:InitializeInventory(player)
	if not DataHandler then
		warn("❌ InventoryModule: DataHandler not set! Call SetDataHandler first.")
		return false
	end

	-- Load player data from DataHandler
	local playerData = DataHandler:LoadPlayerData(player)

	-- If no inventory exists, create default inventory
	if not playerData.Inventory then
		print(string.format("📦 Creating default inventory for %s", player.Name))
		playerData.Inventory = CreateDefaultInventory()

		-- Save the new inventory structure
		DataHandler:SavePlayerData(player, nil)
	else
		print(string.format("📦 Loaded existing inventory for %s", player.Name))
	end

	return true
end

-- Get player's inventory data from DataHandler
local function GetPlayerInventoryData(player)
	if not DataHandler then
		warn("❌ InventoryModule: DataHandler not set!")
		return nil
	end

	-- Ensure player data is loaded
	local playerData = DataHandler:LoadPlayerData(player)

	-- If inventory doesn't exist, create it
	if not playerData.Inventory then
		playerData.Inventory = CreateDefaultInventory()
	end

	return playerData.Inventory
end

-- Validate inventory type
local function IsValidInventoryType(inventoryType)
	return inventoryType == "Seeds" or inventoryType == "Drones" or inventoryType == "Tools"
end

-- Add an item to a player's inventory
function InventoryModule:AddItem(player, inventoryType, itemName, quantity)
	if not IsValidInventoryType(inventoryType) then
		warn(string.format("❌ Invalid inventory type: %s", tostring(inventoryType)))
		return false
	end

	if not itemName or type(itemName) ~= "string" then
		warn("❌ Invalid item name")
		return false
	end

	quantity = quantity or 1
	if type(quantity) ~= "number" or quantity <= 0 then
		warn("❌ Quantity must be a positive number")
		return false
	end

	local inventory = GetPlayerInventoryData(player)
	if not inventory then
		return false
	end

	-- Add or update item quantity
	local currentQuantity = inventory[inventoryType][itemName] or 0
	inventory[inventoryType][itemName] = currentQuantity + quantity

	print(string.format("➕ Added %d x %s to %s's %s inventory (Total: %d)",
		quantity, itemName, player.Name, inventoryType, inventory[inventoryType][itemName]))

	-- Auto-save after change
	DataHandler:SavePlayerData(player, nil)

	return true
end

-- Remove an item from a player's inventory
function InventoryModule:RemoveItem(player, inventoryType, itemName, quantity)
	if not IsValidInventoryType(inventoryType) then
		warn(string.format("❌ Invalid inventory type: %s", tostring(inventoryType)))
		return false
	end

	if not itemName or type(itemName) ~= "string" then
		warn("❌ Invalid item name")
		return false
	end

	quantity = quantity or 1
	if type(quantity) ~= "number" or quantity <= 0 then
		warn("❌ Quantity must be a positive number")
		return false
	end

	local inventory = GetPlayerInventoryData(player)
	if not inventory then
		return false
	end

	-- Check if item exists and has enough quantity
	local currentQuantity = inventory[inventoryType][itemName] or 0

	if currentQuantity < quantity then
		warn(string.format("❌ Not enough %s in inventory (Has: %d, Needs: %d)",
			itemName, currentQuantity, quantity))
		return false
	end

	-- Remove quantity
	inventory[inventoryType][itemName] = currentQuantity - quantity

	-- Remove entry if quantity reaches 0
	if inventory[inventoryType][itemName] <= 0 then
		inventory[inventoryType][itemName] = nil
		print(string.format("➖ Removed all %s from %s's %s inventory",
			itemName, player.Name, inventoryType))
	else
		print(string.format("➖ Removed %d x %s from %s's %s inventory (Remaining: %d)",
			quantity, itemName, player.Name, inventoryType, inventory[inventoryType][itemName]))
	end

	-- Auto-save after change
	DataHandler:SavePlayerData(player, nil)

	return true
end

-- Get the quantity of a specific item in inventory
function InventoryModule:GetItemQuantity(player, inventoryType, itemName)
	if not IsValidInventoryType(inventoryType) then
		warn(string.format("❌ Invalid inventory type: %s", tostring(inventoryType)))
		return 0
	end

	if not itemName or type(itemName) ~= "string" then
		warn("❌ Invalid item name")
		return 0
	end

	local inventory = GetPlayerInventoryData(player)
	if not inventory then
		return 0
	end

	return inventory[inventoryType][itemName] or 0
end

-- Get the entire inventory for a specific type (Seeds, Drones, or Tools)
function InventoryModule:GetInventory(player, inventoryType)
	if not IsValidInventoryType(inventoryType) then
		warn(string.format("❌ Invalid inventory type: %s", tostring(inventoryType)))
		return {}
	end

	local inventory = GetPlayerInventoryData(player)
	if not inventory then
		return {}
	end

	-- Return a copy to prevent external modification
	local inventoryCopy = {}
	for itemName, quantity in pairs(inventory[inventoryType]) do
		inventoryCopy[itemName] = quantity
	end

	return inventoryCopy
end

-- Get all inventories for a player (useful for UI display)
function InventoryModule:GetAllInventories(player)
	local inventory = GetPlayerInventoryData(player)
	if not inventory then
		return CreateDefaultInventory()
	end

	-- Return a deep copy
	return {
		Seeds = self:GetInventory(player, "Seeds"),
		Drones = self:GetInventory(player, "Drones"),
		Tools = self:GetInventory(player, "Tools")
	}
end

-- Check if player has enough of an item
function InventoryModule:HasItem(player, inventoryType, itemName, quantity)
	quantity = quantity or 1
	local currentQuantity = self:GetItemQuantity(player, inventoryType, itemName)
	return currentQuantity >= quantity
end

-- Clear an entire inventory type for a player (useful for admin commands or resets)
function InventoryModule:ClearInventory(player, inventoryType)
	if not IsValidInventoryType(inventoryType) then
		warn(string.format("❌ Invalid inventory type: %s", tostring(inventoryType)))
		return false
	end

	local inventory = GetPlayerInventoryData(player)
	if not inventory then
		return false
	end

	inventory[inventoryType] = {}
	print(string.format("🗑️ Cleared %s inventory for %s", inventoryType, player.Name))

	-- Auto-save after change
	DataHandler:SavePlayerData(player, nil)

	return true
end

return InventoryModule
