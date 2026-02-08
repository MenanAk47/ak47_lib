if Config.Framework == 'auto' and GetResourceState('qb-core') == 'missing' then return end
if Config.Framework ~= 'auto' and Config.Framework ~= 'qb' then return end
Config.Framework = 'qb'

print(string.format("^2['FRAMEWORK']: %s^0", Config.Framework))

QBCore = exports['qb-core']:GetCoreObject()

-- ====================================================================================
--                                     EVENTS
-- ====================================================================================

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Lib47.PlayerData = QBCore.Functions.GetPlayerData()
    Lib47.PlayerLoaded = true
    TriggerEvent('ak47_lib:OnPlayerLoaded', Lib47.PlayerData)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    Lib47.PlayerData.job = JobInfo
    TriggerEvent('ak47_lib:OnJobUpdate', job)
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    if Lib47.PlayerData then
        Functions.HasAnyItemRemoved(Lib47.PlayerData.items, val.items)
    end
    Lib47.PlayerData = val
    TriggerEvent('ak47_lib:OnPlayerDataUpdate', Lib47.PlayerData)
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
    if not PlayerData or not PlayerData.job then return nil end
    return PlayerData.job
end