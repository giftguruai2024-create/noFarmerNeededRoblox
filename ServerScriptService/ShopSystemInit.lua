-- @ScriptType: Script

-- @ScriptType: Script
--// ShopSystemInit.lua
--// Initializes the complete shop system: DataHandler, Inventory, EventBus, and Store

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ModuleLoader = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModuleLoader"))

print("🚀 Initializing Shop System...")

--//////////////////////////////////////////////////////////
-- LOAD MODULES
--//////////////////////////////////////////////////////////

local DataHandler = require(ReplicatedStorage.Modules.DataHandler)
local InventoryModule = ModuleLoader:Get("InventoryModule")
local EventBus = ModuleLoader:Get("EventBus")
local ShopConfig = ModuleLoader:Get("ShopConfig")
local StoreModule = ModuleLoader:Get("StoreModule")

print("✅ All modules loaded")

--//////////////////////////////////////////////////////////
-- INITIALIZE SYSTEMS
--//////////////////////////////////////////////////////////

-- Initialize EventBus (creates all RemoteEvents)
EventBus.Initialize()
print("✅ EventBus initialized")

-- Link InventoryModule with DataHandler
InventoryModule:SetDataHandler(DataHandler)
print("✅ InventoryModule linked to DataHandler")

-- Initialize StoreModule with all dependencies
StoreModule:Initialize(DataHandler, InventoryModule, EventBus, ShopConfig)
print("✅ StoreModule initialized")

--//////////////////////////////////////////////////////////
-- PLAYER MANAGEMENT
--//////////////////////////////////////////////////////////

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	print(string.format("👤 Player joined: %s", player.Name))

	-- Load player data (includes cells, inventory, and currency)
	local playerData = DataHandler:LoadPlayerData(player)

	-- Initialize inventory
	InventoryModule:InitializeInventory(player)

	-- Send initial currency to client
	task.wait(1)  -- Wait for client to load
	local currency = DataHandler:GetCurrency(player)
	EventBus.Fire("CurrencyUpdated", player, {
		Currency = currency
	})

	print(string.format("✅ %s initialized with $%d", player.Name, currency))
end)

-- Handle player leaving (save data)
Players.PlayerRemoving:Connect(function(player)
	print(string.format("👋 Player leaving: %s", player.Name))

	-- Save player data
	DataHandler:SavePlayerData(player, nil)

	print(string.format("💾 Saved data for %s", player.Name))
end)

-- Auto-save all player data every 5 minutes
task.spawn(function()
	while true do
		task.wait(300)  -- 5 minutes
		print("💾 Auto-saving all player data...")

		for _, player in ipairs(Players:GetPlayers()) do
			DataHandler:SavePlayerData(player, nil)
		end

		print("✅ Auto-save complete")
	end
end)

--//////////////////////////////////////////////////////////
-- ADMIN COMMANDS (Optional - for testing)
--//////////////////////////////////////////////////////////

-- Admin command to give currency
-- Usage in server console: game:GetService("ReplicatedStorage").AdminCommands.GiveMoney:Fire(player, amount)
local adminFolder = Instance.new("Folder")
adminFolder.Name = "AdminCommands"
adminFolder.Parent = ReplicatedStorage

-- You can add BindableEvents here for admin commands if needed

print("✅ Shop System fully initialized and ready!")
print("💡 Players can press 'B' to open the shop")
