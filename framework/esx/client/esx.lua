if Config.Framework == 'auto' and GetResourceState('es_extended') == 'missing' then return end
if Config.Framework ~= 'auto' and Config.Framework ~= 'esx' then return end
Config.Framework = 'esx'
Lib47.Framework = 'esx'

print(string.format("^2['FRAMEWORK']: %s^0", Config.Framework))

ESX = exports['es_extended']:getSharedObject()

-- ====================================================================================
--                                     CORE
-- ====================================================================================

Lib47.GetCoreConfig = function(key)
    return ESX.GetConfig and ESX.GetConfig(key) or {}
end

-- ====================================================================================
--                                     EVENTS
-- ====================================================================================

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    Lib47.PlayerData = xPlayer
    Lib47.PlayerData.job = Functions.FormatJobData(Lib47.PlayerData.job)
    Lib47.PlayerLoaded = true
    TriggerEvent('ak47_lib:OnPlayerLoaded', Lib47.PlayerData)
    TriggerEvent('ak47_bridge:OnPlayerLoaded', Lib47.PlayerData) -- will be removed soon
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    TriggerEvent('ak47_lib:OnPlayerUnload')
end)

RegisterNetEvent('esx:setJob', function(job)
    Lib47.PlayerData.job = Functions.FormatJobData(job)
    TriggerEvent('ak47_lib:OnJobUpdate', Lib47.PlayerData.job)
    TriggerEvent('ak47_bridge:OnJobUpdate', Lib47.PlayerData.job) -- will be removed soon
end)

RegisterNetEvent('esx:updatePlayerData', function(key, value)
    if not Lib47.PlayerData then return end
    TriggerEvent('ak47_lib:OnPlayerDataUpdate', Lib47.PlayerData)
    TriggerEvent('ak47_bridge:OnPlayerDataUpdate', Lib47.PlayerData) -- will be removed soon
end)

AddEventHandler('esx:setPlayerData', function(key, value, oldData)
    if not Lib47.PlayerData then return end
    if key == 'job' then
        Lib47.PlayerData.job = Functions.FormatJobData(value)
    else
        Lib47.PlayerData[key] = value
    end
    TriggerEvent('ak47_lib:OnPlayerDataUpdate', Lib47.PlayerData)
    TriggerEvent('ak47_bridge:OnPlayerDataUpdate', Lib47.PlayerData) -- will be removed soon
end)

AddEventHandler('esx:restoreLoadout', function()
    -- Optional: Handle loadout restoration if needed for your specific script
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        local data = ESX.GetPlayerData()
        if data and data.job then
            Lib47.PlayerData = data
            Lib47.PlayerData.job = Functions.FormatJobData(Lib47.PlayerData.job)
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
    Lib47.PlayerData = ESX.GetPlayerData()
    return Lib47.PlayerData
end

-- Returns client job data formatted like QBCore for consistency
Lib47.GetJob = function()
    if not Lib47.PlayerData or not Lib47.PlayerData.job then return nil end
    return Lib47.PlayerData.job
end

Lib47.AddStress = function(amount)
    TriggerEvent('esx_status:add', 'stress', amount * 10000)
end

Lib47.RemoveStress = function(amount)
    TriggerEvent('esx_status:remove', 'stress', amount * 10000)
end

Lib47.GetIdentifier = function()
    return Lib47.PlayerData and Lib47.PlayerData.identifier
end

Lib47.GetCharacterName = function()
    if Lib47.PlayerData and Lib47.PlayerData.firstName and Lib47.PlayerData.lastName then
        return Lib47.PlayerData.firstName .. ' ' .. Lib47.PlayerData.lastName
    end
    return GetPlayerName(PlayerId())
end

