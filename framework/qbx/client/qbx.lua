if Config.Framework == 'auto' and GetResourceState('qbx_core') == 'missing' then return end
if Config.Framework ~= 'auto' and Config.Framework ~= 'qbx' then return end
Config.Framework = 'qbx'
Lib47.Framework = 'qbx'

print(string.format("^2['FRAMEWORK']: %s^0", Config.Framework))

Lib47.Vehicles = exports.qbx_core:GetVehiclesByName()
Lib47.VehiclesByHash = exports.qbx_core:GetVehiclesByHash()

-- ====================================================================================
--                                     CORE
-- ====================================================================================

Lib47.GetCoreConfig = function()
    local success, coreObject = pcall(function() return exports['qb-core']:GetCoreObject() end)
    if success and coreObject and coreObject.Config then
        return coreObject.Config
    end
    return {}
end

-- ====================================================================================
--                                     EVENTS
-- ====================================================================================

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(math.random(100, 500))
    if Lib47.PlayerLoaded then return end

    Lib47.PlayerLoaded = true
    Lib47.PlayerData = exports.qbx_core:GetPlayerData()
    TriggerEvent('ak47_lib:OnPlayerLoaded', Lib47.PlayerData)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    Lib47.PlayerLoaded = false
    Lib47.PlayerData = {}
    TriggerEvent('ak47_lib:OnPlayerUnload')
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    if not job or not job.name then return end
    Lib47.PlayerData.job = job
    TriggerEvent('ak47_lib:OnJobUpdate', job)
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    if Lib47.PlayerData then
        Functions.HasAnyItemRemoved(Lib47.PlayerData.items, val.items)
    end
    Lib47.PlayerData = val
    TriggerEvent('ak47_lib:OnPlayerDataUpdate', Lib47.PlayerData)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUpdated', function(key, val)
    local currentData = Lib47.PlayerData

    if not currentData and key ~= 'all' then 
        return 
    end

    if key == 'all' or key == 'items' then
        local newItems = (key == 'all') and val.items or val
        if currentData and currentData.items then
            Functions.HasAnyItemRemoved(currentData.items, newItems)
        end
    end

    if key == 'all' then
        Lib47.PlayerData = val
    else
        currentData[key] = val
    end

    local updatedState = Lib47.PlayerData

    TriggerEvent('ak47_lib:OnPlayerDataUpdate', updatedState)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        local data = exports.qbx_core:GetPlayerData()
        if data and data.job then
            Lib47.PlayerData = data
            Lib47.PlayerLoaded = true
        end
    end
    if Lib47.PlayerLoaded then
        TriggerEvent('ak47_lib:OnPlayerLoaded', Lib47.PlayerData, resourceName)
    end
end)

-- ====================================================================================
--                                     FUNCTIONS
-- ====================================================================================

Lib47.GetPlayerData = function()
    Lib47.PlayerData = exports.qbx_core:GetPlayerData()
    return Lib47.PlayerData
end

Lib47.GetJob = function()
    if not Lib47.PlayerData or not Lib47.PlayerData.job then return nil end
    return Lib47.PlayerData.job
end

Lib47.OpenBossMenu = function( jobName )
    TriggerEvent('qb-bossmenu:client:OpenMenu')
end

Lib47.GetIdentifier = function()
    return Lib47.PlayerData and Lib47.PlayerData.citizenid
end

Lib47.GetCharacterName = function()
    if Lib47.PlayerData and Lib47.PlayerData.charinfo then
        return Lib47.PlayerData.charinfo.firstname .. ' ' .. Lib47.PlayerData.charinfo.lastname
    end
    return GetPlayerName(PlayerId())
end

Lib47.GetItems = function()
    return Lib47.Items
end

Lib47.GetWeapons = function()
    return Lib47.Weapons
end

Lib47.GetFrameworkVehicles = function()
    return Lib47.Vehicles
end

Lib47.GetFrameworkVehicleByHash = function(hash)
    return Lib47.VehiclesByHash[hash]
end

Lib47.GetFrameworkVehicleByModel = function(model)
    return Lib47.Vehicles[model]
end

Lib47.GetVehicleSchema = function()
    return {
        name = "player_vehicles",
        owner = "citizenid",
        vehicle = "mods",
        stored = "state",
        garage = "garage",
        pound = "depotprice"
    }
end
