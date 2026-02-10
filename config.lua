Config = {}

-- 'esx', 'qb', 'qbx'
Config.Framework = 'auto'

-- 'default', ox', 'esx', 'qb', 'qbx', 'custom'
Config.Notify = 'default'

-- 'default', 'ox', 'esx', 'qb', 'qbx', 'custom'
Config.Progressbar = 'default'

-- 'default', 'ox'
Config.InputDialog = 'default'

-- 'default', 'ox'
Config.AlertDialog = 'default'

-- 'ak47_garage', 'ak47_qb_garage', 'cd_garage', 'okokGarage' 
-- 'jg-advancedgarages', 'loaf_garage', 'qb-garages', 'qbx_garages' 'custom'
Config.Garage = 'auto'

-- 'ak47_vehiclekeys', 'ak47_qb_vehiclekeys', 'wasabi_carlock' 
-- 'qs-vehiclekeys', 'cd_garage', 'qb-vehiclekeys', 'qbx_vehiclekeys', 'custom'
Config.VehicleKey = 'auto'

-- 'LegacyFuel', 'ox_fuel', 'ps-fuel', 'rcore_fuel', 'custom'
Config.FuelScript = 'auto'

-- 'ak47_inventory', 'ak47_qb_inventory', 'ox_inventory', 'qs-inventory'
-- 'qb-inventory', 'qb-inventory-old', 'ps-inventory', 'lj-inventory', 'codem-inventory'
-- 'origen_inventory', 'tgiann-inventory', 'custom'
Config.Inventory = 'auto'

-- 'qb-banking', 'okokBanking', 'Renewed-Banking'
Config.Banking = 'auto'




-- Default Config
Config.Defaults = {
	Notify = {
		-- 'inform', 'success', 'warning', 'error'
		type = 'inform',

		-- 'top-left', 'top-right', 'top-center',
		-- 'bottom-left', 'bottom-right', 'bottom-center',
		-- 'center-left', 'center-right',
		position = 'top-center', 

		-- 'minimal', 'frost', 'frost-fade', 'glass', 'glow-dot', 'vertical-line'
		style = 'minimal',

		duration = 5 * 1000, -- 5 seconds
		sound = true,
		volume = 0.2,
		nightEffect = true, -- different background color at night time
	},
	Checklist = {
		title = 'Checklist',

		-- 'top', 'center', 'bottom'
		position = 'center', 

		nightEffect = true, -- less dark background at night time
	},
	Objective = {
		title = 'Objective',

		-- 'top', 'center', 'bottom'
		position = 'center', 

		nightEffect = true, -- less dark background at night time
	},
	InputDialog = {
		colors = {
			colorPrimary = "rgba(15, 15, 20, 0.85)", 
            colorSecondary = "#FFD700" ,
            colorText = "#ffffff",
		},

		-- 'left', 'right', 'top', 'bottom' (can be combined)
		borders = {'left', 'right'},

		-- "xs", "sm", "md", "lg", "xl"
		size = 'sm'
	},
	AlertDialog = {
		colors = {
			colorPrimary = "rgba(15, 15, 20, 0.85)", 
            colorSecondary = "#FFD700" ,
            colorText = "#ffffff",
		},

		-- 'left', 'right', 'top', 'bottom' (can be combined)
		borders = {'top'},

		-- "xs", "sm", "md", "lg", "xl"
		size = 'sm'
	},

	CallbackTimeout = 15 -- seconds
}

