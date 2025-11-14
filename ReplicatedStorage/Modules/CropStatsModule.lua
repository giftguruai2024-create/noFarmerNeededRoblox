-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript

-- @ScriptType: ModuleScript
local CropStatsModule = {}

--[[
    STAT DEFINITIONS
    -----------------
    seedCost          = Cost to buy 1 seed
    sellPrice         = Price for selling 1 harvested crop
    growthTime        = Seconds required for crop to fully grow
    harvestAmount     = {min, max} - Random range of harvested crops
    seedReturnRate    = Chance (%) to get 1 seed back on harvest
    extraSeedChance   = Chance (%) to get an extra seed (in addition to return rate)
--]]

CropStatsModule.Crops = {

	Wheat = {
		seedCost = 5,
		sellPrice = 8,
		growthTime = 20,
		harvestAmount = {1, 3},
		seedReturnRate = 70,     -- 40% chance to return a seed
		extraSeedChance = 10     -- 10% chance for an extra seed
	},

	Corn = {
		seedCost = 10,
		sellPrice = 18,
		growthTime = 35,
		harvestAmount = {2, 4},
		seedReturnRate = 30,
		extraSeedChance = 8
	},

	Tomato = {
		seedCost = 8,
		sellPrice = 14,
		growthTime = 30,
		harvestAmount = {2, 5},
		seedReturnRate = 35,
		extraSeedChance = 12
	},

	Carrot = {
		seedCost = 6,
		sellPrice = 9,
		growthTime = 18,
		harvestAmount = {1, 3},
		seedReturnRate = 45,
		extraSeedChance = 15
	},

	Pumpkin = {
		seedCost = 20,
		sellPrice = 40,
		growthTime = 60,
		harvestAmount = {1, 2},
		seedReturnRate = 20,
		extraSeedChance = 5
	}

}

-- Optional helper function:
function CropStatsModule.GetCropData(cropName)
	return CropStatsModule.Crops[cropName]
end

return CropStatsModule
