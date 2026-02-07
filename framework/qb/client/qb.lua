if Config.Framework == 'auto' and GetResourceState('qb-core') == 'missing' then return end
if Config.Framework ~= 'auto' and Config.Framework ~= 'qb' then return end
Config.Framework = 'qb'

print(string.format("^2['FRAMEWORK']: %s^0", Config.Framework))

QBCore = exports['qb-core']:GetCoreObject()

-- ====================================================================================
--                                     EVENTS
-- ====================================================================================

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Bridge.PlayerData = QBCore.Functions.GetPlayerData()
    Bridge.PlayerLoaded = true
    TriggerEvent('ak47_bridge:OnPlayerLoaded', Bridge.PlayerData)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    Bridge.PlayerData.job = JobInfo
    TriggerEvent('ak47_bridge:OnJobUpdate', job)
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    if Bridge.PlayerData then
        Functions.HasAnyItemRemoved(Bridge.PlayerData.items, val.items)
    end
    Bridge.PlayerData = val
    TriggerEvent('ak47_bridge:OnPlayerDataUpdate', Bridge.PlayerData)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        local data = QBCore.Functions.GetPlayerData()
        if data and data.job then
            Bridge.PlayerData = data
            Bridge.PlayerLoaded = true
        end
    end
    if Bridge.PlayerLoaded then
        TriggerEvent('ak47_bridge:OnPlayerLoaded', Bridge.PlayerData, resourceName)
    end
end)

-- ====================================================================================
--                                     FUNCTIONS
-- ====================================================================================

Bridge.GetPlayerData = function()
    Bridge.PlayerData = QBCore.Functions.GetPlayerData()
    return Bridge.PlayerData
end

Bridge.GetJob = function()
    if not PlayerData or not PlayerData.job then return nil end
    return PlayerData.job
end