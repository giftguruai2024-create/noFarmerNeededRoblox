-- @ScriptType: LocalScript

-- @ScriptType: LocalScript

-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ModuleLoader = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModuleLoader"))
local EventBus = ModuleLoader:Get("EventBus")

print("✨ [SelectionClient] Initializing...")
EventBus.Initialize()

-------------------------------------------------------
-- CONFIGURATION
-------------------------------------------------------
local CONFIG = {
	-- Visual Settings
	CELL_COLOR = Color3.fromRGB(0, 255, 150),
	PURCHASE_COLOR = Color3.fromRGB(255, 200, 50),

	LINE_THICKNESS = 0.08,
	SURFACE_TRANSPARENCY = 0.7,

	-- Animation Settings
	TWEEN_TIME = 0.15,
}

-------------------------------------------------------
-- SELECTION MODES
-------------------------------------------------------
local SelectionMode = {
	NONE = "None",
	CELL = "CellSelection",
	PURCHASE = "PurchaseCellSelection",
}

-------------------------------------------------------
-- STATE
-------------------------------------------------------
local playerPlotFolder = nil
local currentTarget = nil
local isTransitioning = false
local currentMode = SelectionMode.NONE

-------------------------------------------------------
-- CREATE SELECTION BOX
-------------------------------------------------------
local selectionBox = Instance.new("SelectionBox")
selectionBox.LineThickness = CONFIG.LINE_THICKNESS
selectionBox.SurfaceTransparency = CONFIG.SURFACE_TRANSPARENCY
selectionBox.Adornee = nil
selectionBox.Color3 = CONFIG.CELL_COLOR
selectionBox.Visible = false
selectionBox.Parent = workspace

-------------------------------------------------------
-- GET UI
-------------------------------------------------------
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local modeUI = playerGui:WaitForChild("SelectionModeUI")

-------------------------------------------------------
-- UI UPDATE
-------------------------------------------------------
local function updateButtonStates()
	local container = modeUI:FindFirstChild("Container")
	if not container then return end

	for _, button in ipairs(container:GetChildren()) do
		if button:IsA("TextButton") then
			local buttonMode = button:GetAttribute("Mode")
			local isActive = (currentMode == buttonMode)

			local stroke = button:FindFirstChild("Stroke")
			local icon = button:FindFirstChild("Icon")
			local title = button:FindFirstChild("Title")

			if isActive then
				-- Active state
				local colorHex = button:GetAttribute("ActiveColor")
				local color = Color3.fromHex(colorHex)

				TweenService:Create(button, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				}):Play()

				if stroke then
					TweenService:Create(stroke, TweenInfo.new(0.2), {
						Color = color,
						Thickness = 3
					}):Play()
				end

				if icon then
					TweenService:Create(icon, TweenInfo.new(0.2), {
						TextColor3 = color
					}):Play()
				end

				if title then
					TweenService:Create(title, TweenInfo.new(0.2), {
						TextColor3 = Color3.fromRGB(255, 255, 255)
					}):Play()
				end
			else
				-- Inactive state
				TweenService:Create(button, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				}):Play()

				if stroke then
					TweenService:Create(stroke, TweenInfo.new(0.2), {
						Color = Color3.fromRGB(80, 80, 80),
						Thickness = 2
					}):Play()
				end

				if icon then
					TweenService:Create(icon, TweenInfo.new(0.2), {
						TextColor3 = Color3.fromRGB(200, 200, 200)
					}):Play()
				end

				if title then
					TweenService:Create(title, TweenInfo.new(0.2), {
						TextColor3 = Color3.fromRGB(200, 200, 200)
					}):Play()
				end
			end
		end
	end
end

-------------------------------------------------------
-- MODE MANAGEMENT
-------------------------------------------------------
local function setMode(newMode)
	if currentMode == newMode then
		-- Toggle off if same mode
		currentMode = SelectionMode.NONE
		print("🔴 [SelectionClient] Mode deactivated")
	else
		-- Switch to new mode
		currentMode = newMode

		if currentMode == SelectionMode.CELL then
			print("🟢 [SelectionClient] Cell Selection Mode (Purchased Only)")
		elseif currentMode == SelectionMode.PURCHASE then
			print("🟢 [SelectionClient] Purchase Cell Mode (Unpurchased Only)")
		end
	end

	-- Update UI
	updateButtonStates()

	-- Clear selection when changing modes
	if currentMode == SelectionMode.NONE then
		animateSelection(nil, false)
		currentTarget = nil
	end
end

-------------------------------------------------------
-- UI BUTTON CONNECTIONS
-------------------------------------------------------
local function connectButtons()
	local container = modeUI:FindFirstChild("Container")
	if not container then return end

	for _, button in ipairs(container:GetChildren()) do
		if button:IsA("TextButton") then
			button.MouseButton1Click:Connect(function()
				local mode = button:GetAttribute("Mode")
				setMode(mode)
			end)

			-- Hover effects
			button.MouseEnter:Connect(function()
				if currentMode ~= button:GetAttribute("Mode") then
					TweenService:Create(button, TweenInfo.new(0.1), {
						BackgroundColor3 = Color3.fromRGB(50, 50, 50)
					}):Play()
				end
			end)

			button.MouseLeave:Connect(function()
				if currentMode ~= button:GetAttribute("Mode") then
					TweenService:Create(button, TweenInfo.new(0.1), {
						BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					}):Play()
				end
			end)
		end
	end
end

connectButtons()

-------------------------------------------------------
-- INPUT HANDLING (Keyboard shortcuts)
-------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.One then
		setMode(SelectionMode.CELL)

	elseif input.KeyCode == Enum.KeyCode.Two then
		setMode(SelectionMode.PURCHASE)
	end
end)

-------------------------------------------------------
-- HANDLE PLOT LOADED EVENT
-------------------------------------------------------
EventBus.On("PlotLoaded", function(plotFolder)
	if not plotFolder then
		warn("⚠️ [SelectionClient] Received PlotLoaded but folder is NIL")
		return
	end
	playerPlotFolder = plotFolder
	print("✅ [SelectionClient] Plot loaded successfully:", plotFolder.Name)
end)

-- Wait for plot assignment
task.spawn(function()
	local waitTime = 0
	while not playerPlotFolder do
		task.wait(0.1)
		waitTime = waitTime + 0.1
		if waitTime > 10 then
			warn("⚠️ [SelectionClient] Plot took too long to load!")
			break
		end
	end
	if playerPlotFolder then
		print("🎮 [SelectionClient] Selection system ready!")
		print("💡 Use buttons or press 1/2 for quick mode switching")
	end
end)

-------------------------------------------------------
-- HELPER FUNCTIONS
-------------------------------------------------------
local function isValidCell(target)
	if not playerPlotFolder then return false end

	local placedCellsFolder = playerPlotFolder:FindFirstChild("PlacedCells")
	if not placedCellsFolder then return false end

	if not target:IsDescendantOf(placedCellsFolder) then return false end

	-- Check if purchased attribute is TRUE
	local isPurchased = target:GetAttribute("Purchased")
	return isPurchased == true
end

local function isValidPurchaseCell(target)
	if not playerPlotFolder then return false end

	local placedCellsFolder = playerPlotFolder:FindFirstChild("PlacedCells")
	if not placedCellsFolder then return false end

	if not target:IsDescendantOf(placedCellsFolder) then return false end

	-- Check if purchased attribute is FALSE
	local isPurchased = target:GetAttribute("Purchased")
	return isPurchased == false
end

local function isValidTarget(target)
	if currentMode == SelectionMode.CELL then
		return isValidCell(target)
	elseif currentMode == SelectionMode.PURCHASE then
		return isValidPurchaseCell(target)
	end
	return false
end

local function getSelectionColor()
	if currentMode == SelectionMode.CELL then
		return CONFIG.CELL_COLOR
	elseif currentMode == SelectionMode.PURCHASE then
		return CONFIG.PURCHASE_COLOR
	end
	return CONFIG.CELL_COLOR
end

function animateSelection(target, show)
	if isTransitioning then return end
	isTransitioning = true

	if show and target then
		-- Smooth fade in
		selectionBox.Adornee = target
		selectionBox.Color3 = getSelectionColor()
		selectionBox.Transparency = 1
		selectionBox.Visible = true

		local tween = TweenService:Create(
			selectionBox,
			TweenInfo.new(CONFIG.TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Transparency = 0}
		)
		tween:Play()
		tween.Completed:Wait()
	else
		-- Smooth fade out
		local tween = TweenService:Create(
			selectionBox,
			TweenInfo.new(CONFIG.TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Transparency = 1}
		)
		tween:Play()
		tween.Completed:Wait()

		selectionBox.Visible = false
		selectionBox.Adornee = nil
	end

	isTransitioning = false
end

-------------------------------------------------------
-- SELECTION LOOP
-------------------------------------------------------
RunService.RenderStepped:Connect(function()
	-- Only run if a mode is active
	if currentMode == SelectionMode.NONE then
		if selectionBox.Visible then
			animateSelection(nil, false)
			currentTarget = nil
		end
		return
	end

	if not playerPlotFolder then return end

	local target = Mouse.Target

	-- Check if we're hovering over a valid target for current mode
	if target and isValidTarget(target) then
		-- New target detected
		if currentTarget ~= target then
			currentTarget = target

			-- Update selection box smoothly
			if not isTransitioning then
				selectionBox.Adornee = target
				selectionBox.Color3 = getSelectionColor()

				if not selectionBox.Visible then
					animateSelection(target, true)
				end
			end
		end
	else
		-- No valid target
		if currentTarget then
			currentTarget = nil
			if selectionBox.Visible and not isTransitioning then
				animateSelection(nil, false)
			end
		end
	end
end)

print("✅ [SelectionClient] Ready!")
print("💡 Click mode buttons or press 1/2 to toggle selection modes")