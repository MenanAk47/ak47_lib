if Config.Framework == 'auto' and GetResourceState('es_extended') == 'missing' then return end
if Config.Framework ~= 'auto' and Config.Framework ~= 'esx' then return end
Config.Framework = 'esx'

print(string.format("^2['FRAMEWORK']: %s^0", Config.Framework))

ESX = exports['es_extended']:getSharedObject()
Bridge = {}
Integration = {}

PlayerData = {}
PlayerLoaded = false

-- ====================================================================================
--                                     EVENTS
-- ====================================================================================

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    PlayerLoaded = true

    TriggerEvent('ak47_bridge:OnPlayerLoaded', PlayerData)
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = job

    TriggerEvent('ak47_bridge:OnJobUpdate', job)
end)

RegisterNetEvent('esx:updatePlayerData', function(key, value)
    PlayerData[key] = value

    TriggerEvent('ak47_bridge:OnPlayerDataUpdate', PlayerData)
end)

AddEventHandler('esx:restoreLoadout', function()
    -- Optional: Handle loadout restoration if needed for your specific script
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if ESX.PlayerLoaded then
            PlayerData = ESX.GetPlayerData()
            PlayerLoaded = true

            TriggerEvent('ak47_bridge:OnPlayerLoaded', PlayerData)
        end
    end
end)

-- ====================================================================================
--                                     FUNCTIONS
-- ====================================================================================

-- Returns client job data formatted like QBCore for consistency
Bridge.GetJob = function()
    if not PlayerData or not PlayerData.job then return nil end

    local job = {}
    job.name = PlayerData.job.name
    job.label = PlayerData.job.label
    job.payment = PlayerData.job.grade_salary
    
    job.isboss = PlayerData.job.grade_name == 'boss'

    job.grade = {}
    job.grade.name = PlayerData.job.grade_label
    job.grade.level = PlayerData.job.grade

    return job
end

Bridge.GetPlayerData = function()
    return PlayerData
end

Bridge.GetTargetMetaValue = function(targetServerId, metaKey)
    return lib.callback.await('ak47_bridge:callback:server:GetTargetMetaValue', nil, targetServerId, metaKey)
end

exports('GetBridge', function()
    return Bridge
end)