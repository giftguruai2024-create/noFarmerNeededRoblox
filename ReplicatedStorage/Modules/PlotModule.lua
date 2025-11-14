-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
--// PlotModule.lua
--// Handles assigning plots, generating grid, and placing cells
local PlotModule = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleLoader = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModuleLoader"))
local EventBus = ModuleLoader:Get("EventBus")
-- Grid Settings
local GRID_WIDTH = 21
local GRID_HEIGHT = 21
local CELL_SPACING = 5
local POINT_SIZE = Vector3.new(1, 1, 1)
-- Cell Templates
local gridCellsFolder = ReplicatedStorage:WaitForChild("GridCells")
local grassTemplate = gridCellsFolder:WaitForChild("GrassCell")
local soilTemplate = gridCellsFolder:WaitForChild("SoilCell")
-- Private: Generate grid points
local function GenerateGrid(gridFolder)
	local startPoint = gridFolder:FindFirstChild("StartingGridPoint")
	if not startPoint then
		warn("⚠️ No StartingGridPoint found in " .. gridFolder:GetFullName())
		return
	end
	local origin = startPoint.Position
	for row = 1, GRID_HEIGHT do
		for col = 1, GRID_WIDTH do
			local newX = origin.X + ((col - 1) * CELL_SPACING)
			local newZ = origin.Z + ((row - 1) * CELL_SPACING)
			local newY = origin.Y
			local newPoint = startPoint:Clone()
			newPoint.Name = string.format("GridPoint (%d,%d)", col, row)
			newPoint.Size = POINT_SIZE
			newPoint.Position = Vector3.new(newX, newY, newZ)
			newPoint.Parent = gridFolder
			newPoint.Transparency = 1
		end
	end
	startPoint:Destroy()
end
-- Private: Place cell objects on grid points
-- Private: Place cell objects on grid points
-- Private: Place cell objects on grid points
local function PlaceCells(plotFolder, cellData, playerName)
	local gridFolder = plotFolder:WaitForChild("GridPoints")
	local placedFolder = Instance.new("Folder")
	placedFolder.Name = "PlacedCells"
	placedFolder.Parent = plotFolder

	for _, cellInfo in ipairs(cellData) do
		local col, row = cellInfo.Column, cellInfo.Row
		local pointName = string.format("GridPoint (%d,%d)", col, row)
		local point = gridFolder:FindFirstChild(pointName)

		if point then
			-- Determine cell type based on Purchased attribute
			local isPurchased = cellInfo.Purchased or false
			local template = isPurchased and soilTemplate or grassTemplate
			local cellType = isPurchased and "SoilCell" or "GrassCell"

			if template then
				local newCell = template:Clone()
				newCell.Name = string.format("%s (%d,%d)", cellType, col, row)
				newCell.Position = point.Position

				-- Set Attributes from saved data
				newCell:SetAttribute("Row", row)
				newCell:SetAttribute("Column", col)
				newCell:SetAttribute("Owner", playerName)
				newCell:SetAttribute("Purchased", isPurchased)
				newCell:SetAttribute("CurrentCrop", cellInfo.CurrentCrop or "")
				newCell:SetAttribute("CropData", cellInfo.CropData or "")
				newCell:SetAttribute("CropGrowthTime", cellInfo.CropGrowthTime or 0)
				newCell:SetAttribute("CurrentCropGrowthTime", cellInfo.CurrentCropGrowthTime or 0)
				newCell:SetAttribute("Watered", cellInfo.Watered or false)
				newCell:SetAttribute("WateredTimeLeft", cellInfo.WateredTimeLeft or 0)
				newCell:SetAttribute("Fertilized", cellInfo.Fertilized or false)
				newCell:SetAttribute("FertilizedTimeLeft", cellInfo.FertilizedTimeLeft or 0)

				newCell.Parent = placedFolder
			end
		end
	end

	print("✅ Placed " .. #cellData .. " cell objects for plot:", plotFolder.Name)
end
-- Main Function: Generate Plot
function PlotModule.GeneratePlot(player, plotFolder, cellData)
	if not player or not plotFolder then
		warn("❌ Missing player or plotFolder in GeneratePlot call.")
		return
	end
	-- Step 1: Rename Plot
	local plotNumber = string.match(plotFolder.Name, "%d+") or "?"
	plotFolder.Name = string.format("Plot(%s)(%s)", plotNumber, player.Name)
	-- Step 2: Update Plot Sign UI
	local plotSign = plotFolder:FindFirstChild("PlotSign")
	if plotSign then
		local sign = plotSign:FindFirstChild("Sign")
		if sign then
			local surfaceGui = sign:FindFirstChildOfClass("SurfaceGui")
			if surfaceGui then
				local frame = surfaceGui:FindFirstChild("Frame")
				if frame then
					local nameLabel = frame:FindFirstChild("PlayerName")
					local imageLabel = frame:FindFirstChild("PlayerImage")
					if nameLabel then nameLabel.Text = player.Name end
					if imageLabel then
						local thumb, _ = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
						imageLabel.Image = thumb
					end
				end
			end
		end
	end
	-- Step 3: Generate Grid Points
	local gridFolder = plotFolder:FindFirstChild("GridPoints")
	if gridFolder then
		GenerateGrid(gridFolder)
	end
	-- Step 4: Place Cells using player cell data
	if cellData then
		PlaceCells(plotFolder, cellData, player.Name)
	else
		warn("⚠️ No cellData provided to GeneratePlot for", player.Name)
	end
	-- Step 5: Teleport player to grid center
	local character = player.Character
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp and gridFolder then
			local startPoint = gridFolder:FindFirstChild(string.format("GridPoint (%d,%d)", 1, 1))
			if startPoint then
				local origin = startPoint.Position
				local centerX = origin.X + ((GRID_WIDTH - 1) / 2) * CELL_SPACING
				local centerZ = origin.Z + ((GRID_HEIGHT - 1) / 2) * CELL_SPACING
				local centerY = origin.Y + 5
				hrp.CFrame = CFrame.new(centerX, centerY, centerZ)
			end
		end
	end
	print("✅ Plot setup complete for", player.Name)
	EventBus.Fire("PlotLoaded", player, plotFolder)
end
return PlotModule