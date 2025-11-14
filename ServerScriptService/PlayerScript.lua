-- @ScriptType: Script

-- @ScriptType: Script

-- @ScriptType: Script
--// PlayerPlotHandler.lua
--// Handles player join events, initializes data storage, and assigns plots
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Get ModuleLoader
local ModuleLoader = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModuleLoader"))

--// Load modules via ModuleLoader
local PlotModule = ModuleLoader:Get("PlotModule")
local DataHandler = ModuleLoader:Get("DataHandler")
local EventBus = ModuleLoader:Get("EventBus")
local CropStats = ModuleLoader:Get("CropStatsModule")

--// Wait for Plots folder
local plotsFolder = workspace:WaitForChild("Plots")

--// Track player plot assignments
local PlayerPlots = {}

--// Assign a player to an open plot
local function AssignPlotToPlayer(player)
	task.wait(1) -- short wait to ensure models are loaded

	-- Find the first open plot
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plot:IsA("Folder") or plot:IsA("Model") then
			if string.find(plot.Name, "(Open)", 1, true) then
				print("🟢 Found open plot:", plot.Name)

				-- Load player data (will create default if no saved data exists)
				DataHandler:LoadPlayerData(player)

				-- Retrieve player's cell data
				local cellData = DataHandler:GetPlayerCellData(player)

				-- Generate the plot for the player
				PlotModule.GeneratePlot(player, plot, cellData)

				-- Store the plot assignment
				PlayerPlots[player.UserId] = plot

				return
			end
		end
	end

	warn("⚠️ No open plots available for " .. player.Name)
end

--// Player joins
Players.PlayerAdded:Connect(function(player)
	print("👤 Player joined:", player.Name)
	AssignPlotToPlayer(player)
end)

--// Player leaves
Players.PlayerRemoving:Connect(function(player)
	print("👋 Player left:", player.Name)

	-- Get the player's plot
	local plotFolder = PlayerPlots[player.UserId]

	-- Save player data with their plot
	DataHandler:SavePlayerData(player, plotFolder)

	-- Clean up the plot assignment
	PlayerPlots[player.UserId] = nil
end)



EventBus.Initialize()
print("✅ PlayerPlotHandler running and waiting for players...")