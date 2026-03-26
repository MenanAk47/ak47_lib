Config = {}

-- 'esx', 'qb', 'qbx'
Config.Framework = 'auto'

-- 'default', ox', 'esx', 'qb', 'qbx', 'custom'
Config.Notify = 'default'

-- 'default', ox', 
Config.ContextMenu = 'default'

-- 'default', ox', 
Config.MobileMenu = 'default'

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

-- 'ak47_banking', 'qb-banking', 'okokBanking', 'Renewed-Banking'
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

	ContextMenu = {
		title = 'Menu',

		-- 'top-left', 'top-right', 'bottom-left', 'bottom-right'
		position = 'top-right', 

		-- 'left', 'right', 'top', 'bottom' (can be combined)
		borders = {'left'},

		-- Default colors matching your solid background design
		colors = {
			colorPrimary = "rgba(18, 18, 22, 0.9)", 
			colorSecondary = "#FFD700",
			colorText = "#ffffff",
		},

		-- "xs", "sm", "md", "lg", "xl"
		size = 'sm',

		-- Can the user close the menu with ESC by default?
		canClose = true
	},

	MobileMenu = {
		title = 'Menu',

		-- 'top-left', 'top-right', 'bottom-left', 'bottom-right'
		position = 'top-right', 

		-- 'left', 'right', 'top', 'bottom' (can be combined)
		borders = {'left'},

		-- Default colors matching your solid background design
		colors = {
			colorPrimary = "rgba(18, 18, 22, 0.9)", 
			colorSecondary = "#FFD700",
			colorText = "#ffffff",
		},

		-- "xs", "sm", "md", "lg", "xl"
		size = 'sm',

		-- Can the user close the menu with ESC by default?
		canClose = true
	},

	NpcInteract = {
		-- Default colors matching your solid background design
		colors = {
			colorPrimary = "rgba(18, 18, 22, 0.9)", 
			colorSecondary = "#FFD700",
			colorText = "#ffffff",
		},
	},

	Minigame = {
		tension = {
			easy = {
				classic = { fishSpeed = 0.6, jumpChance = 0.01, barSize = 35, gain = 0.6, loss = 0.05 },
				momentum = { fishSpeed = 0.5, jumpChance = 0.01, barSize = 35, gain = 0.6, loss = 0.05, thrust = 0.8, gravity = 0.4, friction = 0.85 },
				shrinking = { fishSpeed = 0.8, jumpChance = 0.01, startSize = 50, minSize = 25, gain = 0.6, loss = 0.05 },
				frenzy = { normSpeed = 0.5, frenzySpeed = 2.0, jumpNorm = 0.01, jumpFrenzy = 0.05, gain = 0.5, lossNorm = 0.02, lossFrenzy = 0.1, barSize = 35 }
			},
			medium = {
				classic = { fishSpeed = 1.0, jumpChance = 0.02, barSize = 25, gain = 0.4, loss = 0.1 },
				momentum = { fishSpeed = 0.8, jumpChance = 0.02, barSize = 25, gain = 0.4, loss = 0.1, thrust = 0.7, gravity = 0.3, friction = 0.90 },
				shrinking = { fishSpeed = 1.2, jumpChance = 0.02, startSize = 45, minSize = 15, gain = 0.4, loss = 0.1 },
				frenzy = { normSpeed = 0.8, frenzySpeed = 3.0, jumpNorm = 0.02, jumpFrenzy = 0.10, gain = 0.3, lossNorm = 0.05, lossFrenzy = 0.2, barSize = 25 }
			},
			hard = {
				classic = { fishSpeed = 1.5, jumpChance = 0.05, barSize = 20, gain = 0.3, loss = 0.15 },
				momentum = { fishSpeed = 1.2, jumpChance = 0.05, barSize = 20, gain = 0.3, loss = 0.15, thrust = 0.6, gravity = 0.4, friction = 0.92 },
				shrinking = { fishSpeed = 1.8, jumpChance = 0.05, startSize = 35, minSize = 10, gain = 0.35, loss = 0.15 },
				frenzy = { normSpeed = 1.0, frenzySpeed = 4.0, jumpNorm = 0.03, jumpFrenzy = 0.12, gain = 0.25, lossNorm = 0.1, lossFrenzy = 0.3, barSize = 20 }
			},
			expert = {
				classic = { fishSpeed = 2.0, jumpChance = 0.06, barSize = 16, gain = 0.25, loss = 0.20 },
				momentum = { fishSpeed = 1.8, jumpChance = 0.06, barSize = 16, gain = 0.25, loss = 0.20, thrust = 0.55, gravity = 0.45, friction = 0.94 },
				shrinking = { fishSpeed = 2.2, jumpChance = 0.06, startSize = 30, minSize = 6, gain = 0.30, loss = 0.20 },
				frenzy = { normSpeed = 1.2, frenzySpeed = 5.0, jumpNorm = 0.04, jumpFrenzy = 0.15, gain = 0.20, lossNorm = 0.15, lossFrenzy = 0.5, barSize = 16 }
			},
			impossible = {
				classic = { fishSpeed = 2.5, jumpChance = 0.08, barSize = 12, gain = 0.2, loss = 0.25 },
				momentum = { fishSpeed = 2.2, jumpChance = 0.08, barSize = 12, gain = 0.2, loss = 0.25, thrust = 0.5, gravity = 0.5, friction = 0.96 },
				shrinking = { fishSpeed = 2.8, jumpChance = 0.08, startSize = 22, minSize = 4, gain = 0.25, loss = 0.25 },
				frenzy = { normSpeed = 1.5, frenzySpeed = 6.0, jumpNorm = 0.06, jumpFrenzy = 0.20, gain = 0.15, lossNorm = 0.2, lossFrenzy = 0.7, barSize = 12 }
			},
		}
	},

	CallbackTimeout = 15 -- seconds
}

