-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
--// DataHandler.lua
--// Handles cell data storage, retrieval, and saving
local DataHandler = {}
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- DataStore setup
local USE_DATASTORE = true -- Set to true when you want to use real DataStore
local PlayerDataStore = DataStoreService:GetDataStore("PlayerFarmData")

-- In-memory storage (backup/cache)
local PlayerData = {}

-- Initialize default player data (center 3x3 as purchased/soil)
local function CreateDefaultCellData(gridWidth, gridHeight)
	local cells = {}
	local centerCol = math.ceil(gridWidth / 2)   -- 11 for 21x21
	local centerRow = math.ceil(gridHeight / 2)  -- 11 for 21x21

	for row = 1, gridHeight do
		for col = 1, gridWidth do
			-- Check if within the 3x3 center zone
			local isPurchased = (col >= centerCol - 1 and col <= centerCol + 1)
				and (row >= centerRow - 1 and row <= centerRow + 1)

			table.insert(cells, {
				Row = row,
				Column = col,
				Purchased = isPurchased,
				CurrentCrop = "",
				CropData = "",
				CropGrowthTime = 0,
				CurrentCropGrowthTime = 0,
				Watered = false,
				WateredTimeLeft = 0,
				Fertilized = false,
				FertilizedTimeLeft = 0
			})
		end
	end

	return cells
end

-- Load player data from DataStore
function DataHandler:LoadPlayerData(player)
	if PlayerData[player.UserId] then 
		print("📦 Data already loaded in memory for", player.Name)
		return PlayerData[player.UserId]
	end

	local loadedData = nil

	if USE_DATASTORE then
		-- Try to load from DataStore
		local success, result = pcall(function()
			return PlayerDataStore:GetAsync(player.UserId)
		end)

		if success and result then
			loadedData = result
			print(string.format("✅ Loaded saved data from DataStore for %s (%d cells)", player.Name, #result.Cells))
		elseif not success then
			warn("❌ Failed to load data for", player.Name, "Error:", result)
		end
	end

	-- If no saved data exists, create default data
	if not loadedData then
		print("📝 No saved data found for", player.Name, "- creating default data (center 3x3 soil)")
		loadedData = {
			Cells = CreateDefaultCellData(21, 21),
			Inventory = {
				Seeds = {},
				Drones = {},
				Tools = {}
			},
			Currency = 5  -- Starting currency for new players
		}
	end

	-- Ensure Inventory exists in loaded data (for backward compatibility)
	if not loadedData.Inventory then
		print("📦 Adding inventory structure to existing player data for", player.Name)
		loadedData.Inventory = {
			Seeds = {},
			Drones = {},
			Tools = {}
		}
	end

	-- Ensure Currency exists in loaded data (for backward compatibility)
	if not loadedData.Currency then
		print("💰 Adding currency to existing player data for", player.Name)
		loadedData.Currency = 5  -- Give existing players starting currency
	end

	-- Store in memory
	PlayerData[player.UserId] = loadedData
	return loadedData
end

-- Retrieve all player cell data
function DataHandler:GetPlayerCellData(player)
	if not PlayerData[player.UserId] then
		self:LoadPlayerData(player)
	end
	return PlayerData[player.UserId].Cells
end

-- Update a specific cell's attributes
function DataHandler:UpdateCellAttributes(player, col, row, attributes)
	local playerCells = self:GetPlayerCellData(player)
	for _, cell in ipairs(playerCells) do
		if cell.Column == col and cell.Row == row then
			for key, value in pairs(attributes) do
				cell[key] = value
			end
			print(string.format("📝 Updated cell (%d,%d) for %s", col, row, player.Name))
			return true
		end
	end
	warn(string.format("⚠️ Cell (%d,%d) not found for %s", col, row, player.Name))
	return false
end

-- Save cell attributes from the plot into PlayerData
function DataHandler:SaveCellData(player, plotFolder)
	if not player or not plotFolder then
		warn("❌ Missing player or plotFolder in SaveCellData")
		return false
	end

	local placedFolder = plotFolder:FindFirstChild("PlacedCells")
	if not placedFolder then
		warn("❌ No PlacedCells folder found for", player.Name)
		return false
	end

	-- Initialize player data if not exists
	if not PlayerData[player.UserId] then
		PlayerData[player.UserId] = { Cells = {} }
	end

	local cells = {}

	-- Extract ONLY attributes from each cell (no models, parts, or names)
	for _, cell in ipairs(placedFolder:GetChildren()) do
		local cellAttributes = {
			Row = cell:GetAttribute("Row"),
			Column = cell:GetAttribute("Column"),
			Purchased = cell:GetAttribute("Purchased"),
			CurrentCrop = cell:GetAttribute("CurrentCrop") or "",
			CropData = cell:GetAttribute("CropData") or "",
			CropGrowthTime = cell:GetAttribute("CropGrowthTime") or 0,
			CurrentCropGrowthTime = cell:GetAttribute("CurrentCropGrowthTime") or 0,
			Watered = cell:GetAttribute("Watered") or false,
			WateredTimeLeft = cell:GetAttribute("WateredTimeLeft") or 0,
			Fertilized = cell:GetAttribute("Fertilized") or false,
			FertilizedTimeLeft = cell:GetAttribute("FertilizedTimeLeft") or 0
		}

		table.insert(cells, cellAttributes)
	end

	-- Update in-memory data with ONLY attributes
	PlayerData[player.UserId].Cells = cells

	print(string.format("💾 Saved %d cell attributes to memory for %s", #cells, player.Name))
	return true
end

-- Get player's current currency
function DataHandler:GetCurrency(player)
	if not PlayerData[player.UserId] then
		self:LoadPlayerData(player)
	end
	return PlayerData[player.UserId].Currency or 0
end

-- Add currency to player's account
function DataHandler:AddCurrency(player, amount)
	if not PlayerData[player.UserId] then
		self:LoadPlayerData(player)
	end

	if type(amount) ~= "number" or amount < 0 then
		warn("❌ Invalid currency amount:", amount)
		return false
	end

	PlayerData[player.UserId].Currency = (PlayerData[player.UserId].Currency or 0) + amount
	print(string.format("💰 Added $%d to %s (Total: $%d)", amount, player.Name, PlayerData[player.UserId].Currency))

	-- Auto-save
	self:SavePlayerData(player, nil)
	return true
end

-- Deduct currency from player's account
function DataHandler:DeductCurrency(player, amount)
	if not PlayerData[player.UserId] then
		self:LoadPlayerData(player)
	end

	if type(amount) ~= "number" or amount < 0 then
		warn("❌ Invalid currency amount:", amount)
		return false
	end

	local currentCurrency = PlayerData[player.UserId].Currency or 0

	if currentCurrency < amount then
		warn(string.format("❌ Insufficient funds for %s (Has: $%d, Needs: $%d)", player.Name, currentCurrency, amount))
		return false
	end

	PlayerData[player.UserId].Currency = currentCurrency - amount
	print(string.format("💸 Deducted $%d from %s (Remaining: $%d)", amount, player.Name, PlayerData[player.UserId].Currency))

	-- Auto-save
	self:SavePlayerData(player, nil)
	return true
end

-- Set currency to a specific amount (useful for admin commands)
function DataHandler:SetCurrency(player, amount)
	if not PlayerData[player.UserId] then
		self:LoadPlayerData(player)
	end

	if type(amount) ~= "number" or amount < 0 then
		warn("❌ Invalid currency amount:", amount)
		return false
	end

	PlayerData[player.UserId].Currency = amount
	print(string.format("💰 Set %s's currency to $%d", player.Name, amount))

	-- Auto-save
	self:SavePlayerData(player, nil)
	return true
end

-- Save player data to DataStore
function DataHandler:SavePlayerData(player, plotFolder)
	if not player then
		warn("❌ No player provided to SavePlayerData")
		return
	end

	-- Save cell attributes first
	if plotFolder then
		self:SaveCellData(player, plotFolder)
	else
		warn("⚠️ No plotFolder provided, using cached data")
	end

	-- Get the data to save (ONLY attributes)
	local dataToSave = PlayerData[player.UserId]

	if not dataToSave then
		warn("❌ No data to save for", player.Name)
		return
	end

	if USE_DATASTORE then
		-- Save ONLY attributes to DataStore
		local success, err = pcall(function()
			PlayerDataStore:SetAsync(player.UserId, dataToSave)
		end)

		if success then
			print(string.format("💾 Saved %d cells to DataStore for %s", #dataToSave.Cells, player.Name))
		else
			warn("❌ Failed to save data for", player.Name, "Error:", err)
		end
	else
		print(string.format("💾 Saved %d cells to memory for %s (DataStore disabled)", #dataToSave.Cells, player.Name))
	end
end

return DataHandler