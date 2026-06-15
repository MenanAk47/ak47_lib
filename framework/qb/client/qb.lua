if Config.Framework == 'auto' and GetResourceState('qb-core') == 'missing' then return end
if Config.Framework ~= 'auto' and Config.Framework ~= 'qb' then return end
Config.Framework = 'qb'
Lib47.Framework = 'qb'

print(string.format("^2['FRAMEWORK']: %s^0", Config.Framework))

QBCore = exports['qb-core']:GetCoreObject()

-- ====================================================================================
--                                     CORE
-- ====================================================================================

Lib47.GetCoreConfig = function()
    return QBCore.Config or {}
end

-- ====================================================================================
--                                     EVENTS
-- ====================================================================================

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Lib47.PlayerData = QBCore.Functions.GetPlayerData()
    Lib47.PlayerLoaded = true
    TriggerEvent('ak47_lib:OnPlayerLoaded', Lib47.PlayerData)
    TriggerEvent('ak47_bridge:OnPlayerLoaded', Lib47.PlayerData) -- will be removed soon
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
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
        local data = QBCore.Functions.GetPlayerData()
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
--                                     FUNCTIONS
-- ====================================================================================

Lib47.GetPlayerData = function()
    Lib47.PlayerData = QBCore.Functions.GetPlayerData()
    return Lib47.PlayerData
end

Lib47.GetJob = function()
    if not Lib47.PlayerData or not Lib47.PlayerData.job then return nil end
    return Lib47.PlayerData.job
end

Lib47.AddStress = function(amount)
    TriggerServerEvent('hud:server:GainStress', amount)
end

Lib47.RemoveStress = function(amount)
    TriggerServerEvent('hud:server:RelieveStress', amount)
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