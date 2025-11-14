-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
--// StoreModule.lua
--// Server-side shop logic: handles purchases, validates funds, updates inventory

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local StoreModule = {}

-- Module references (set via Initialize)
local DataHandler = nil
local InventoryModule = nil
local EventBus = nil
local ShopConfig = nil

-- Purchase request queue to prevent duplicate purchases
local PurchaseInProgress = {}

-- Initialize the store module with required dependencies
function StoreModule:Initialize(dataHandler, inventoryModule, eventBus, shopConfig)
	DataHandler = dataHandler
	InventoryModule = inventoryModule
	EventBus = eventBus
	ShopConfig = shopConfig

	-- Listen for purchase requests from clients
	EventBus.OnServerEvent("PurchaseFromShop", function(player, purchaseData)
		self:ProcessPurchase(player, purchaseData)
	end)

	print("✅ StoreModule initialized and listening for purchases")
end

-- Process a purchase request from a player
function StoreModule:ProcessPurchase(player, purchaseData)
	-- Validate purchase data
	if not purchaseData or type(purchaseData) ~= "table" then
		warn(string.format("❌ Invalid purchase data from %s", player.Name))
		self:SendPurchaseResult(player, false, "Invalid purchase request")
		return
	end

	local itemName = purchaseData.ItemName
	local quantity = purchaseData.Quantity or 1

	-- Check if purchase is already in progress for this player
	local purchaseKey = player.UserId .. "_" .. itemName
	if PurchaseInProgress[purchaseKey] then
		warn(string.format("⚠️ Purchase already in progress for %s buying %s", player.Name, itemName))
		self:SendPurchaseResult(player, false, "Purchase already in progress")
		return
	end

	-- Mark purchase as in progress
	PurchaseInProgress[purchaseKey] = true

	-- Find the item in shop config
	local itemData = ShopConfig:FindItem(itemName)
	if not itemData then
		warn(string.format("❌ Item not found: %s", itemName))
		PurchaseInProgress[purchaseKey] = nil
		self:SendPurchaseResult(player, false, "Item not found")
		return
	end

	-- Calculate total cost
	local totalCost = itemData.Price * quantity

	-- Check if player has enough currency
	local currentCurrency = DataHandler:GetCurrency(player)
	if currentCurrency < totalCost then
		warn(string.format("❌ %s tried to buy %s but has insufficient funds ($%d < $%d)",
			player.Name, itemName, currentCurrency, totalCost))
		PurchaseInProgress[purchaseKey] = nil
		self:SendPurchaseResult(player, false, string.format("Insufficient funds. Need $%d", totalCost))
		return
	end

	-- Deduct currency
	local deductSuccess = DataHandler:DeductCurrency(player, totalCost)
	if not deductSuccess then
		warn(string.format("❌ Failed to deduct currency from %s", player.Name))
		PurchaseInProgress[purchaseKey] = nil
		self:SendPurchaseResult(player, false, "Failed to process payment")
		return
	end

	-- Add item to inventory
	local addSuccess = InventoryModule:AddItem(player, itemData.InventoryType, itemName, quantity)
	if not addSuccess then
		warn(string.format("❌ Failed to add %s to %s's inventory", itemName, player.Name))
		-- Refund the currency since inventory add failed
		DataHandler:AddCurrency(player, totalCost)
		PurchaseInProgress[purchaseKey] = nil
		self:SendPurchaseResult(player, false, "Failed to add item to inventory")
		return
	end

	-- Success!
	print(string.format("✅ %s purchased %d x %s for $%d", player.Name, quantity, itemName, totalCost))
	PurchaseInProgress[purchaseKey] = nil

	-- Notify client of success and updated currency
	self:SendPurchaseResult(player, true, string.format("Purchased %d x %s", quantity, itemData.DisplayName))
	self:SendCurrencyUpdate(player)
end

-- Send purchase result to client
function StoreModule:SendPurchaseResult(player, success, message)
	EventBus.Fire("ItemPurchased", player, {
		Success = success,
		Message = message
	})
end

-- Send currency update to client
function StoreModule:SendCurrencyUpdate(player)
	local currentCurrency = DataHandler:GetCurrency(player)
	EventBus.Fire("CurrencyUpdated", player, {
		Currency = currentCurrency
	})
end

-- Get player's current currency (helper function for admin commands)
function StoreModule:GetPlayerCurrency(player)
	return DataHandler:GetCurrency(player)
end

-- Admin function: Give currency to a player
function StoreModule:GiveCurrency(player, amount)
	local success = DataHandler:AddCurrency(player, amount)
	if success then
		self:SendCurrencyUpdate(player)
	end
	return success
end

-- Admin function: Set player currency
function StoreModule:SetCurrency(player, amount)
	local success = DataHandler:SetCurrency(player, amount)
	if success then
		self:SendCurrencyUpdate(player)
	end
	return success
end

return StoreModule
