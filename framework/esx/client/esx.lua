if Config.Framework == 'auto' and GetResourceState('es_extended') == 'missing' then return end
if Config.Framework ~= 'auto' and Config.Framework ~= 'esx' then return end
Config.Framework = 'esx'

print(string.format("^2['FRAMEWORK']: %s^0", Config.Framework))

ESX = exports['es_extended']:getSharedObject()

-- ====================================================================================
--                                     EVENTS
-- ====================================================================================

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    Bridge.PlayerData = xPlayer
    Bridge.PlayerLoaded = true
    TriggerEvent('ak47_bridge:OnPlayerLoaded', PlayerData)
end)

RegisterNetEvent('esx:setJob', function(job)
    Bridge.PlayerData.job = job
    TriggerEvent('ak47_bridge:OnJobUpdate', job)
end)

RegisterNetEvent('esx:updatePlayerData', function(key, value)
    Bridge.PlayerData[key] = value
    TriggerEvent('ak47_bridge:OnPlayerDataUpdate', Bridge.PlayerData)
end)

AddEventHandler('esx:restoreLoadout', function()
    -- Optional: Handle loadout restoration if needed for your specific script
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        local data = ESX.GetPlayerData()
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
    Bridge.PlayerData = ESX.GetPlayerData()
    return Bridge.PlayerData
end

-- Returns client job data formatted like QBCore for consistency
Bridge.GetJob = function()
    if not Bridge.PlayerData or not Bridge.PlayerData.job then return nil end

    local job = {}
    job.name = Bridge.PlayerData.job.name
    job.label = Bridge.PlayerData.job.label
    job.payment = Bridge.PlayerData.job.grade_salary
    
    job.isboss = Bridge.PlayerData.job.grade_name == 'boss'

    job.grade = {}
    job.grade.name = Bridge.PlayerData.job.grade_label
    job.grade.level = Bridge.PlayerData.job.grade

    return job
end

