local GlobalSounds = {}

-- Create a global sound and store its precise start time
RegisterNetEvent('ak47_lib:server:PlaySound', function(data)
    local src = source
    local soundId = data.soundId
    
    data.startTime = os.time()
    data.pauseOffset = 0
    data.isPaused = false
    data.ownerResource = GetInvokingResource() or "external"
    
    GlobalSounds[soundId] = data
    TriggerClientEvent('ak47_lib:client:PlaySound', -1, data)
end)

RegisterNetEvent('ak47_lib:server:PauseSound', function(soundId)
    if GlobalSounds[soundId] and not GlobalSounds[soundId].isPaused then
        GlobalSounds[soundId].isPaused = true
        GlobalSounds[soundId].pauseOffset = GlobalSounds[soundId].pauseOffset + (os.time() - GlobalSounds[soundId].startTime)
        TriggerClientEvent('ak47_lib:client:PauseSound', -1, soundId)
    end
end)

RegisterNetEvent('ak47_lib:server:ResumeSound', function(soundId)
    if GlobalSounds[soundId] and GlobalSounds[soundId].isPaused then
        GlobalSounds[soundId].isPaused = false
        GlobalSounds[soundId].startTime = os.time()
        TriggerClientEvent('ak47_lib:client:ResumeSound', -1, soundId)
    end
end)

RegisterNetEvent('ak47_lib:server:StopSound', function(soundId)
    if GlobalSounds[soundId] then
        GlobalSounds[soundId] = nil
        TriggerClientEvent('ak47_lib:client:StopSound', -1, soundId)
    end
end)

RegisterNetEvent('ak47_lib:server:SeekSound', function(soundId, seekTime)
    if GlobalSounds[soundId] then
        GlobalSounds[soundId].startTime = os.time() - math.floor(seekTime)
        GlobalSounds[soundId].pauseOffset = 0
        TriggerClientEvent('ak47_lib:client:SeekSound', -1, soundId, seekTime)
    end
end)

RegisterNetEvent('ak47_lib:server:UpdateSoundCoords', function(soundId, coords)
    if GlobalSounds[soundId] then
        GlobalSounds[soundId].coords = coords
        TriggerClientEvent('ak47_lib:client:UpdateSoundCoords', -1, soundId, coords)
    end
end)

RegisterNetEvent('ak47_lib:server:AttachEntity', function(soundId, id, aType, offset)
    if GlobalSounds[soundId] then
        GlobalSounds[soundId].attachedData = { id = id, aType = aType, offset = offset }
    end
    TriggerClientEvent('ak47_lib:client:AttachEntity', -1, soundId, id, aType, offset)
end)

RegisterNetEvent('ak47_lib:server:SyncState', function(soundId, key, value)
    if GlobalSounds[soundId] then
        GlobalSounds[soundId][key] = value
        TriggerClientEvent('ak47_lib:client:SyncState', -1, soundId, key, value)
    end
end)

-- Late Joiner Synchronization
RegisterNetEvent('ak47_lib:server:RequestSoundPlayerSync', function()
    local src = source
    local now = os.time()
    
    for soundId, data in pairs(GlobalSounds) do
        local syncData = json.decode(json.encode(data))
        
        if not syncData.isPaused then
            syncData.startSeek = (now - syncData.startTime) + syncData.pauseOffset
        else
            syncData.startSeek = syncData.pauseOffset
        end
        
        TriggerClientEvent('ak47_lib:client:PlaySound', src, syncData)
    end
end)