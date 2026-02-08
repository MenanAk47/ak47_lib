if Config.Framework == 'auto' and GetResourceState('es_extended') == 'missing' then return end
if Config.Framework ~= 'auto' and Config.Framework ~= 'esx' then return end
Config.Framework = 'esx'

print(string.format("^2['FRAMEWORK']: %s^0", Config.Framework))

ESX = exports['es_extended']:getSharedObject()

-- ====================================================================================
--                                     EVENTS
-- ====================================================================================

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    Lib47.PlayerData = xPlayer
    Lib47.PlayerLoaded = true
    TriggerEvent('ak47_lib:OnPlayerLoaded', PlayerData)
end)

RegisterNetEvent('esx:setJob', function(job)
    Lib47.PlayerData.job = job
    TriggerEvent('ak47_lib:OnJobUpdate', job)
end)

RegisterNetEvent('esx:updatePlayerData', function(key, value)
    Lib47.PlayerData[key] = value
    TriggerEvent('ak47_lib:OnPlayerDataUpdate', Lib47.PlayerData)
end)

AddEventHandler('esx:restoreLoadout', function()
    -- Optional: Handle loadout restoration if needed for your specific script
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        local data = ESX.GetPlayerData()
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
    Lib47.PlayerData = ESX.GetPlayerData()
    return Lib47.PlayerData
end

-- Returns client job data formatted like QBCore for consistency
Lib47.GetJob = function()
    if not Lib47.PlayerData or not Lib47.PlayerData.job then return nil end

    local job = {}
    job.name = Lib47.PlayerData.job.name
    job.label = Lib47.PlayerData.job.label
    job.payment = Lib47.PlayerData.job.grade_salary
    
    job.isboss = Lib47.PlayerData.job.grade_name == 'boss'

    job.grade = {}
    job.grade.name = Lib47.PlayerData.job.grade_label
    job.grade.level = Lib47.PlayerData.job.grade

    return job
end

