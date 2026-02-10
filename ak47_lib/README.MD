# [Ak47 Lib Documentation](https://docs.menanak47.com/plugins/ak47_lib)

**ak47_lib** is a unified compatibility layer designed to support multiple FiveM frameworks (ESX, QBCore, QBX) and various third-party resources (Inventory, Target, Fuel, etc.) through a single, consistent API. This allows developers to write scripts that work across different server setups without writing complex adaptation code.

## 🌟 Features

* **Multi-Framework Support:** Auto-detects and bridges ESX, QBCore, and QBX.
* **Unified API:** Consistent function calls for Player, Economy, Inventory, and Vehicle management.
* **Auto-Detection:** Automatically configures itself based on started resources (Configurable to 'auto').
* **Extensive Integrations:** Built-in support for popular inventories, fuel scripts, garages, and target systems.
* **Developer Friendly:** Simplifies dependency management for paid or free releases.

## 📋 Requirements

* **FiveM Server** (Artifacts enabling Lua 5.4 recommended)
* **A Supported Framework:**
* ESX Legacy
* QBCore
* QBX Core



## 📦 Installation

1. Download the `ak47_lib` resource.
2. Place the folder into your server's `resources` directory.
3. Add the following to your `server.cfg`:
```cfg
ensure ak47_lib

```



## ⚙️ Configuration

The configuration is handled in `config.lua`. By default, most options are set to `'auto'`, meaning the lib will scan your server resources and select the appropriate integration automatically.

```lua
Config = {}

-- Framework: 'esx', 'qb', 'qbx', 'auto'
Config.Framework = 'auto'

-- Notification System: 'ox', 'esx', 'qb', 'qbx', 'custom'
Config.Notify = 'ox'

-- Progress Bar: 'ox', 'esx', 'qb', 'custom'
Config.Progressbar = 'ox'

-- Garage System: 'ak47_garage', 'cd_garage', 'qb-garages', etc.
Config.Garage = 'auto'

-- Vehicle Keys: 'ak47_vehiclekeys', 'wasabi_carlock', 'qs-vehiclekeys', etc.
Config.VehicleKey = 'auto'

-- Fuel System: 'LegacyFuel', 'ox_fuel', 'ps-fuel', etc.
Config.FuelScript = 'auto'

-- Inventory: 'ox_inventory', 'qs-inventory', 'qb-inventory', etc.
Config.Inventory = 'auto'

-- Banking: 'qb-banking', 'okokBanking', 'Renewed-Banking'
Config.Banking = 'auto'

```


## 📄 License

This project is licensed under the [GNU General Public License v3.0](https://www.google.com/search?q=LICENSE).