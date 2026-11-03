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
    TriggerEvent('ak47_bridge:OnPlayerLoaded', Lib47.PlayerData) -- will be removed soon
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    Lib47.PlayerLoaded = false
    Lib47.PlayerData = {}
    TriggerEvent('ak47_lib:OnPlayerUnload')
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    Lib47.PlayerData.job = JobInfo
    TriggerEvent('ak47_lib:OnJobUpdate', JobInfo)
    TriggerEvent('ak47_bridge:OnJobUpdate', JobInfo) -- will be removed soon
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    if Lib47.PlayerData then
        Functions.HasAnyItemRemoved(Lib47.PlayerData.items, val.items)
    end
    Lib47.PlayerData = val
    TriggerEvent('ak47_lib:OnPlayerDataUpdate', Lib47.PlayerData)
    TriggerEvent('ak47_bridge:OnPlayerDataUpdate', Lib47.PlayerData) -- will be removed soon
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
    TriggerEvent('ak47_bridge:OnPlayerDataUpdate', updatedState) -- will be removed soon
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
        TriggerEvent('ak47_bridge:OnPlayerLoaded', Lib47.PlayerData, resourceName) -- will be removed soon
    end
end)

-- ====================================================================================
--                                     STATUS
-- ====================================================================================

Lib47.SetHunger = function(amount)
    if not amount then return end
    local val = math.max(0, math.min(100, math.floor(amount)))
    TriggerServerEvent('ak47_lib:server:SetHunger', val)
end

Lib47.AddHunger = function(amount)
    if not amount or amount <= 0 then return end
    local PlayerData = Lib47.GetPlayerData()
    local currentVal = (PlayerData and PlayerData.metadata and PlayerData.metadata.hunger) or 0

    local set = math.min(100, currentVal + amount)
    Lib47.SetHunger(set)
end

Lib47.RemoveHunger = function(amount)
    if not amount or amount <= 0 then return end
    local PlayerData = Lib47.GetPlayerData()
    local currentVal = (PlayerData and PlayerData.metadata and PlayerData.metadata.hunger) or 0

    local set = math.max(0, currentVal - amount)
    Lib47.SetHunger(set)
end

Lib47.SetThirst = function(amount)
    if not amount then return end
    local val = math.max(0, math.min(100, math.floor(amount)))
    TriggerServerEvent('ak47_lib:server:SetThirst', val)
end

Lib47.AddThirst = function(amount)
    if not amount or amount <= 0 then return end
    local PlayerData = Lib47.GetPlayerData()
    local currentVal = (PlayerData and PlayerData.metadata and PlayerData.metadata.thirst) or 0

    local set = math.min(100, currentVal + amount)
    Lib47.SetThirst(set)
end

Lib47.RemoveThirst = function(amount)
    if not amount or amount <= 0 then return end
    local PlayerData = Lib47.GetPlayerData()
    local currentVal = (PlayerData and PlayerData.metadata and PlayerData.metadata.thirst) or 0

    local set = math.max(0, currentVal - amount)
    Lib47.SetThirst(set)
end

Lib47.SetStress = function(amount)
    if not amount then return end
    local val = math.max(0, math.min(100, math.floor(amount)))
    TriggerServerEvent('ak47_lib:server:SetStress', val)
end

Lib47.AddStress = function(amount)
    if not amount or amount <= 0 then return end
    local PlayerData = Lib47.GetPlayerData()
    local currentVal = (PlayerData and PlayerData.metadata and PlayerData.metadata.stress) or 0
    if currentVal >= 100 then return end

    local addAmount = math.min(100 - currentVal, math.floor(amount))
    TriggerServerEvent('hud:server:GainStress', addAmount)
end

Lib47.RemoveStress = function(amount)
    if not amount or amount <= 0 then return end
    local PlayerData = Lib47.GetPlayerData()
    local currentVal = (PlayerData and PlayerData.metadata and PlayerData.metadata.stress) or 0
    if currentVal <= 0 then return end

    local removeAmount = math.min(currentVal, math.floor(amount))
    TriggerServerEvent('hud:server:RelieveStress', removeAmount)
end

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
