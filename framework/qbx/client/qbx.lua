if Config.Framework == 'auto' and GetResourceState('qbx_core') == 'missing' then return end
if Config.Framework ~= 'auto' and Config.Framework ~= 'qbx' then return end
Config.Framework = 'qbx'

print(string.format("^2['FRAMEWORK']: %s^0", Config.Framework))

-- ====================================================================================
--                                     EVENTS
-- ====================================================================================

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Bridge.PlayerData = exports.qbx_core:GetPlayerData()
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
        local data = exports.qbx_core:GetPlayerData()
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
    Bridge.PlayerData = exports.qbx_core:GetPlayerData()
    return Bridge.PlayerData
end

Bridge.GetJob = function()
    if not Bridge.PlayerData or not Bridge.PlayerData.job then return nil end
    return Bridge.PlayerData.job
end