-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
-- Modules > ModuleLoader
local ModuleScripts = script.Parent



local modules = {

	PlotModule = ModuleScripts.PlotModule,
	EventBus = ModuleScripts.EventBus,
	DataHandler = ModuleScripts.DataHandler,
	CropStatsModule = ModuleScripts.CropStatsModule,
	InventoryModule = ModuleScripts.InventoryModule,
	StoreModule = ModuleScripts.StoreModule,
	ShopConfig = ModuleScripts.ShopConfig,

}

local ModuleLoader = {}

function ModuleLoader:Get(moduleName)
	if modules[moduleName] then
		return require(modules[moduleName])
	end
	error("Module not found: " .. moduleName)
end

return ModuleLoader