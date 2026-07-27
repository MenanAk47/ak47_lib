local activeSounds = {}
local attachedSounds = {}
local pendingAttachments = {}
local resourceTracker = {} 
local isLoopActive = false
local soundCounter = 0
local pendingPromises = {}

-- Gizmo State
local isGizmoOpen = false
local isGizmoFocused = false
local gizmoEntity = nil

local PlayerPedId = PlayerPedId
local GetEntityCoords = GetEntityCoords
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetInteriorFromEntity = GetInteriorFromEntity
local GetInteriorFromCollision = GetInteriorFromCollision
local SendNUIMessage = SendNUIMessage
local Wait = Wait
local math_sin = math.sin
local math_cos = math.cos
local math_abs = math.abs
local math_pi = math.pi
local vector3 = vector3

local DEFAULT_EQ = { sub = 0, bass = 0, mid = 0, high = 0, air = 0 }

-- =========================================================================
--                                 HELPERS
-- =========================================================================

AddEventHandler('ak47_lib:OnPlayerLoaded', function()
    TriggerServerEvent('ak47_lib:server:RequestSoundPlayerSync')
end)

local function RotationToDirection(rotation)
    local x = (math_pi / 180) * rotation.x
    local z = (math_pi / 180) * rotation.z
    local num = math_abs(math_cos(x))
    return vector3(-math_sin(z) * num, math_cos(z) * num, math_sin(x))
end

local function GetUniqueId()
    soundCounter = soundCounter + 1
    return "sound_" .. GetGameTimer() .. "_" .. soundCounter
end

RegisterNUICallback('audioDataResult', function(data, cb)
    if data.reqId and pendingPromises[data.reqId] then
        pendingPromises[data.reqId]:resolve(data)
        pendingPromises[data.reqId] = nil
    end
    cb('ok')
end)

RegisterNUICallback('soundEnded', function(data, cb)
    local sId = data.soundId
    if activeSounds[sId] then
        activeSounds[sId].isPlaying = false
        activeSounds[sId].isInitialized = false
        activeSounds[sId] = nil
    end
    attachedSounds[sId] = nil
    cb('ok')
end)

-- =========================================================================
--                     ATTACHED ENTITY TRACKING LOOP
-- =========================================================================

CreateThread(function()
    while true do
        local sleep = 500
        if next(attachedSounds) then
            sleep = 16 
            for soundId, sound in pairs(attachedSounds) do
                local targetCoords = nil
                local entity = nil

                if sound.attachedType == 'entity' and sound.attachedNetId then
                    if NetworkDoesNetworkIdExist(sound.attachedNetId) then
                        entity = NetworkGetEntityFromNetworkId(sound.attachedNetId)
                    end
                elseif sound.attachedType == 'player' and sound.attachedServerId then
                    local playerIndex = GetPlayerFromServerId(sound.attachedServerId)
                    if playerIndex ~= -1 then
                        entity = GetPlayerPed(playerIndex)
                    end
                end

                if entity and entity ~= 0 and DoesEntityExist(entity) then
                    sound.entityHadExisted = true
                    if sound.offset then
                        targetCoords = GetOffsetFromEntityInWorldCoords(entity, sound.offset.x, sound.offset.y, sound.offset.z)
                    else
                        targetCoords = GetEntityCoords(entity)
                    end

                    if not sound.coords or #(sound.coords - targetCoords) > 0.05 then
                        sound.coords = targetCoords
                        sound.interiorId = GetInteriorFromEntity(entity)
                        if sound.isInitialized then
                            SendNUIMessage({ action = "updateSoundCoords", soundId = soundId, coords = { x = targetCoords.x, y = targetCoords.y, z = targetCoords.z }})
                        end
                        if sound.global and not sound.isReplicated and not attachedSounds[soundId] then
                            TriggerServerEvent('ak47_lib:server:UpdateSoundCoords', soundId, { x = targetCoords.x, y = targetCoords.y, z = targetCoords.z })
                        end
                    end
                else
                    if not sound.isReplicated and sound.entityHadExisted then
                        sound:destroy()
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- =========================================================================
--                                 MAIN LOOP
-- =========================================================================

function StartAudioLoop()
    if isLoopActive then return end
    isLoopActive = true
    
    Citizen.CreateThread(function()
        while isLoopActive do
            if next(activeSounds) == nil and not isGizmoOpen then
                isLoopActive = false
                break
            end

            local playerPed = PlayerPedId()
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            local forward = RotationToDirection(camRot)
            local playerInterior = GetInteriorFromEntity(playerPed)
            
            SendNUIMessage({
                action = "updateListener",
                camCoords = { x = camCoords.x, y = camCoords.y, z = camCoords.z },
                camRot = { x = camRot.x, y = camRot.y, z = camRot.z },
                camFov = GetGameplayCamFov(),
                camForward = { x = forward.x, y = forward.y, z = forward.z },
                camUp = { x = 0.0, y = 0.0, z = 1.0 }
            })

            local sleep = 1000
            local playerCoords = GetEntityCoords(playerPed)

            for id, sound in pairs(activeSounds) do
                if sound.isPlaying then
                    if sound.coords and sound.maxDistance then
                        if #(playerCoords - sound.coords) <= sound.maxDistance then
                            sleep = 10
                        end
                    end

                    local shouldOcclude = false
                    if sound.interiorEffect then
                        shouldOcclude = (playerInterior ~= sound.interiorId)
                    end

                    if sound.isOccluded ~= shouldOcclude then
                        sound.isOccluded = shouldOcclude
                        SendNUIMessage({
                            action = "updateOcclusion",
                            soundId = id,
                            occluded = shouldOcclude
                        })
                    end
                end
            end
            if isGizmoOpen then sleep = 1 end
            Wait(sleep)
        end
    end)
end

-- =========================================================================
--                           SOUND OBJECT CLASS
-- =========================================================================

local SoundObject = {}
SoundObject.__index = SoundObject

function SoundObject:play()
    if self.isPlaying and self.isInitialized then return self end
    self.isPlaying = true
    if not self.isInitialized then
        self.isInitialized = true
        activeSounds[self.soundId] = self
        
        local orientation = self.orientation
        if not orientation and self.setting3d and self.setting3d.orientation then
            orientation = self.setting3d.orientation
        end

        SendNUIMessage({
            action = "playSound",
            soundId = self.soundId,
            url = self.url,
            coords = self.coords and { x = self.coords.x, y = self.coords.y, z = self.coords.z } or nil,
            volume = self.volume,
            rate = self.rate,
            is3d = self.is3d,
            setting3d = self.setting3d,
            eq = self.eq,
            orientation = orientation, 
            maxDistance = self.maxDistance,
            loop = self.loop,
            interiorEffect = self.interiorEffect,
            interiorId = self.interiorId,
            startSeek = self.startSeek or 0
        })
        StartAudioLoop()
        if self.global and not self.isReplicated then
            local attachedData = nil
            if self.attachedType then
                attachedData = {
                    aType = self.attachedType,
                    id = (self.attachedType == 'entity') and self.attachedNetId or self.attachedServerId,
                    offset = self.offset and { x = self.offset.x, y = self.offset.y, z = self.offset.z } or nil
                }
            end

            TriggerServerEvent('ak47_lib:server:PlaySound', {
                soundId = self.soundId,
                url = self.url,
                coords = self.coords and { x = self.coords.x, y = self.coords.y, z = self.coords.z } or nil,
                maxVolume = self.volume,
                volume = self.volume,
                maxDistance = self.maxDistance,
                is3d = self.is3d,
                setting3d = self.setting3d,
                eq = self.eq,
                interiorEffect = self.interiorEffect,
                global = true,
                rate = self.rate,
                loop = self.loop,
                startSeek = self.startSeek,
                attachedData = attachedData
            })
        end
    else
        SendNUIMessage({ action = "resumeSound", soundId = self.soundId })
        if self.global and not self.isReplicated then TriggerServerEvent('ak47_lib:server:ResumeSound', self.soundId) end
    end
    return self
end

function SoundObject:setEqualizer(eqTable)
    self.eq = eqTable or DEFAULT_EQ
    if self.isInitialized then
        SendNUIMessage({
            action = "updateEqualizer",
            soundId = self.soundId,
            eq = self.eq
        })
    end
    if self.global and not self.isReplicated then
        TriggerServerEvent('ak47_lib:server:SyncState', self.soundId, 'eq', self.eq)
    end
    return self
end

function SoundObject:setEqualizerGlobal(eqTable)
    return self:setEqualizer(eqTable)
end

function SoundObject:pause()
    self.isPlaying = false
    SendNUIMessage({ action = "pauseSound", soundId = self.soundId })
    if self.global and not self.isReplicated then TriggerServerEvent('ak47_lib:server:PauseSound', self.soundId) end
    return self
end

function SoundObject:destroy()
    self.isPlaying = false
    self.isInitialized = false
    activeSounds[self.soundId] = nil
    attachedSounds[self.soundId] = nil
    SendNUIMessage({ action = "stopSound", soundId = self.soundId })
    if self.global and not self.isReplicated then TriggerServerEvent('ak47_lib:server:StopSound', self.soundId) end
    return nil
end

function SoundObject:seek(seconds)
    SendNUIMessage({ action = "seekSound", soundId = self.soundId, time = seconds })
    if self.global and not self.isReplicated then
        TriggerServerEvent('ak47_lib:server:SeekSound', self.soundId, seconds)
    end
    return self
end

function SoundObject:setVolume(volume)
    self.volume = volume
    if self.isInitialized then SendNUIMessage({ action = "updateVolume", soundId = self.soundId, volume = volume }) end
    return self
end

function SoundObject:setVolumeGlobal(volume)
    self:setVolume(volume)
    if self.global and not self.isReplicated then
        TriggerServerEvent('ak47_lib:server:SyncState', self.soundId, 'volume', volume)
    end
    return self
end

function SoundObject:setRate(rate)
    self.rate = rate
    if self.isInitialized then SendNUIMessage({ action = "updateRate", soundId = self.soundId, rate = rate }) end
    if self.global and not self.isReplicated then TriggerServerEvent('ak47_lib:server:SyncState', self.soundId, 'rate', rate) end
    return self
end

function SoundObject:setMaxDistance(dist)
    self.maxDistance = dist
    if self.isInitialized then SendNUIMessage({ action = "updateMaxDistance", soundId = self.soundId, maxDistance = dist }) end
    return self
end

function SoundObject:updateCoords(coords)
    self.coords = coords
    self.interiorId = GetInteriorFromCollision(coords.x, coords.y, coords.z)
    if self.isInitialized then
        SendNUIMessage({ action = "updateSoundCoords", soundId = self.soundId, coords = { x = coords.x, y = coords.y, z = coords.z }})
    end
    if self.global and not self.isReplicated and not attachedSounds[self.soundId] then
        local flatCoords = coords and { x = coords.x, y = coords.y, z = coords.z } or nil
        TriggerServerEvent('ak47_lib:server:UpdateSoundCoords', self.soundId, flatCoords)
    end
    return self
end

function SoundObject:updateSettings(settings)
    if settings.volume ~= nil then self.volume = settings.volume end
    if settings.rate ~= nil then self.rate = settings.rate end
    if settings.maxDistance ~= nil then self.maxDistance = settings.maxDistance end
    if settings.loop ~= nil then self.loop = settings.loop end
    if settings.coords ~= nil then 
        self.coords = settings.coords 
        self.interiorId = GetInteriorFromCollision(self.coords.x, self.coords.y, self.coords.z)
    end
    if settings.eq ~= nil then self.eq = settings.eq end

    if self.isInitialized then
        SendNUIMessage({
            action = "updateSoundSettings",
            soundId = self.soundId,
            volume = self.volume,
            rate = self.rate,
            maxDistance = self.maxDistance,
            loop = self.loop,
            coords = self.coords and { x = self.coords.x, y = self.coords.y, z = self.coords.z } or nil,
            eq = self.eq,
            coneInnerAngle = settings.coneInnerAngle,
            coneOuterAngle = settings.coneOuterAngle,
            volumeFadeStarts = settings.volumeFadeStarts,
            volumeFadeMultiplier = settings.volumeFadeMultiplier
        })
    end
    return self
end

function SoundObject:attachToEntity(netId, offset)
    self.attachedType = 'entity'
    self.attachedNetId = netId
    self.offset = offset or vector3(0, 0, 0)
    attachedSounds[self.soundId] = self
    if self.global and not self.isReplicated then
        TriggerServerEvent('ak47_lib:server:AttachEntity', self.soundId, netId, 'entity', self.offset)
    end
    return self
end

function SoundObject:attachToPlayer(serverId, offset)
    self.attachedType = 'player'
    self.attachedServerId = serverId
    self.offset = offset or vector3(0, 0, 0)
    attachedSounds[self.soundId] = self
    if self.global and not self.isReplicated then
        TriggerServerEvent('ak47_lib:server:AttachEntity', self.soundId, serverId, 'player', self.offset)
    end
    return self
end

function SoundObject:detach()
    attachedSounds[self.soundId] = nil
    self.attachedType = nil
    self.attachedNetId = nil
    self.attachedServerId = nil
    return self
end

function SoundObject:getInfo()
    if not self.isInitialized then return { duration = 0, currentTime = 0 } end
    local p = promise.new()
    local reqId = "req_" .. GetGameTimer() .. "_" .. math.random(9999)
    pendingPromises[reqId] = p
    SendNUIMessage({ action = "getInfo", soundId = self.soundId, reqId = reqId })
    return Citizen.Await(p)
end

-- =========================================================================
--                            INTERFACE / EXPORTS
-- =========================================================================

local Interface = {}
Interface.CreateSound = function(data)
    local coords = data.coords
    if type(coords) == 'table' and coords.x then
        coords = vector3(coords.x, coords.y, coords.z)
    end
    
    local is3d = data.is3d
    local interiorId = 0
    if coords then
        if is3d == nil then is3d = true end
        interiorId = GetInteriorFromCollision(coords.x, coords.y, coords.z)
    else
        is3d = false
    end
    local id = data.soundId or GetUniqueId()
    
    local invoker = GetInvokingResource() or 'ak47_lib'
    if not resourceTracker[invoker] then resourceTracker[invoker] = {} end
    table.insert(resourceTracker[invoker], id)

    local internalInstance = setmetatable({
        soundId = id,
        url = data.url,
        coords = coords,
        is3d = is3d,
        setting3d = data.setting3d or {},
        eq = data.eq or DEFAULT_EQ,
        maxDistance = data.maxDistance or 20.0,
        volume = data.volume or data.maxVolume or 0.5,
        rate = data.rate or 1.0,
        interiorEffect = data.interiorEffect,
        interiorId = interiorId,
        global = data.global,
        loop = data.loop or false,
        isInitialized = false,
        isPlaying = false,
        isReplicated = data.replicated or false,
        startSeek = data.startSeek or 0,
        isOccluded = false,
        orientation = data.setting3d and data.setting3d.orientation or nil
    }, SoundObject)

    local attachInfo = data.attachedData or pendingAttachments[id]
    if attachInfo then
        local offset = attachInfo.offset
        if type(offset) == 'table' and offset.x then
            offset = vector3(offset.x, offset.y, offset.z)
        end
        if attachInfo.aType == 'entity' then
            internalInstance:attachToEntity(attachInfo.id, offset)
        elseif attachInfo.aType == 'player' then
            internalInstance:attachToPlayer(attachInfo.id, offset)
        end
        pendingAttachments[id] = nil
    end

    local publicWrapper = {
        soundId = id,
        play = function() internalInstance:play() return publicWrapper end,
        pause = function() internalInstance:pause() return publicWrapper end,
        destroy = function() internalInstance:destroy() return nil end,
        seek = function(_, time) internalInstance:seek(time); return publicWrapper end,
        setVolume = function(_, vol) internalInstance:setVolume(vol); return publicWrapper end,
        setVolumeGlobal = function(_, vol) internalInstance:setVolumeGlobal(vol); return publicWrapper end,
        setRate = function(_, rate) internalInstance:setRate(rate); return publicWrapper end,
        setEqualizer = function(_, eqTable) internalInstance:setEqualizer(eqTable); return publicWrapper end,
        setEqualizerGlobal = function(_, eqTable) internalInstance:setEqualizerGlobal(eqTable); return publicWrapper end,
        setMaxDistance = function(_, dist) internalInstance:setMaxDistance(dist); return publicWrapper end,
        updateCoords = function(_, newCoords) internalInstance:updateCoords(newCoords); return publicWrapper end,
        updateSettings = function(_, settings) internalInstance:updateSettings(settings); return publicWrapper end,
        attachToEntity = function(_, netId, offset) internalInstance:attachToEntity(netId, offset); return publicWrapper end,
        attachToPlayer = function(_, serverId, offset) internalInstance:attachToPlayer(serverId, offset); return publicWrapper end,
        detach = function() internalInstance:detach(); return publicWrapper end,
        getInfo = function() return internalInstance:getInfo() end
    }
    
    if data.replicated then internalInstance:play() end
    return publicWrapper
end

-- =========================================================================
--                           RESOURCE SWEEPER
-- =========================================================================
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        SendNUIMessage({ action = "stopAll" })
        return
    end

    if resourceTracker[resourceName] then
        for _, sId in ipairs(resourceTracker[resourceName]) do
            if activeSounds[sId] then activeSounds[sId]:destroy() end
        end
        resourceTracker[resourceName] = nil
    end
end)

-- =========================================================================
--                            NETWORK EVENTS
-- =========================================================================
RegisterNetEvent('ak47_lib:client:PlaySound', function(data)
    if activeSounds[data.soundId] then return end
    data.replicated = true 
    Interface.CreateSound(data)
end)

RegisterNetEvent('ak47_lib:client:PauseSound', function(soundId) if activeSounds[soundId] and activeSounds[soundId].isReplicated then activeSounds[soundId]:pause() end end)
RegisterNetEvent('ak47_lib:client:ResumeSound', function(soundId) if activeSounds[soundId] and activeSounds[soundId].isReplicated then activeSounds[soundId]:play() end end)
RegisterNetEvent('ak47_lib:client:StopSound', function(soundId) if activeSounds[soundId] and activeSounds[soundId].isReplicated then activeSounds[soundId]:destroy() end end)
RegisterNetEvent('ak47_lib:client:SeekSound', function(soundId, time) if activeSounds[soundId] and activeSounds[soundId].isReplicated then activeSounds[soundId]:seek(time) end end)
RegisterNetEvent('ak47_lib:client:UpdateSoundCoords', function(soundId, coords) if activeSounds[soundId] and activeSounds[soundId].isReplicated then activeSounds[soundId]:updateCoords(coords) end end)

RegisterNetEvent('ak47_lib:client:AttachEntity', function(soundId, id, aType, offset)
    if activeSounds[soundId] then 
        if not activeSounds[soundId].isReplicated then return end
        if aType == 'entity' then activeSounds[soundId]:attachToEntity(id, offset)
        else activeSounds[soundId]:attachToPlayer(id, offset) end
    else
        pendingAttachments[soundId] = { id = id, aType = aType, offset = offset }
    end 
end)

RegisterNetEvent('ak47_lib:client:SyncState', function(soundId, key, value) 
    if activeSounds[soundId] then 
        if not activeSounds[soundId].isReplicated then return end
        if key == 'rate' then activeSounds[soundId]:setRate(value) 
        elseif key == 'volume' then activeSounds[soundId]:setVolume(value)
        elseif key == 'eq' then activeSounds[soundId]:setEqualizer(value) end
    end 
end)

-- Export Registrations
exports('CreateSound', Interface.CreateSound)
exports('AttachToEntity', function(sId, netId, offset) if activeSounds[sId] then activeSounds[sId]:attachToEntity(netId, offset) end end)
exports('Seek', function(sId, time) if activeSounds[sId] then activeSounds[sId]:seek(time) end end)
exports('SetVolumeGlobal', function(sId, vol) if activeSounds[sId] then activeSounds[sId]:setVolumeGlobal(vol) end end)
exports('SetEqualizer', function(sId, eqTable) if activeSounds[sId] then activeSounds[sId]:setEqualizer(eqTable) end end)
exports('SetEqualizerGlobal', function(sId, eqTable) if activeSounds[sId] then activeSounds[sId]:setEqualizerGlobal(eqTable) end end)
exports('Destroy', function(sId) if activeSounds[sId] then activeSounds[sId]:destroy() end end)

Lib47 = Lib47 or {}
Lib47.CreateSound = Interface.CreateSound

-- =========================================================================
--                            GIZMO / DEBUGGER
-- =========================================================================

RegisterCommand('soundgizmo', function()
    local playerPed = PlayerPedId()
    local pCoords = GetEntityCoords(playerPed)
    local pRot = GetEntityRotation(playerPed, 2)
    
    local forward = RotationToDirection(pRot)
    local spawnCoords = pCoords + (forward * 1.5)
    local spawnRot = vector3(0.0, 0.0, pRot.z + 180.0)    

    if Lib47 and Lib47.Gizmo then
        Lib47.Gizmo.Start({
            coords = spawnCoords,
            rot = spawnRot,
            model = `prop_speaker_05`
        }, function(data)
            if data.event == 'closed' then
                SendNUIMessage({ action = "toggleSoundGizmo", show = false })
            end
        end)
    end

    StartAudioLoop() 
end)

RegisterNUICallback('closeSoundGizmo', function(data, cb)
    if Lib47 and Lib47.Gizmo then Lib47.Gizmo.Stop() end
    cb('ok')
end)

RegisterNUICallback('previewSound', function(data, cb)
    local sId = 'gizmo_preview'
    
    if data.action == 'stop' then
        if activeSounds[sId] then activeSounds[sId]:destroy() end
        cb('ok')
        return
    end

    local current = activeSounds[sId]
    if current and current.url ~= data.url then
        current:destroy()
        current = nil
    end

    local coords = vector3(data.x, data.y, data.z)
    local rot = vector3(data.rotX or 0, data.rotY or 0, data.rotZ or 0)

    if current then
        current:updateSettings({
            coords = coords,
            rot = rot,
            maxDistance = data.maxDistance,
            volume = data.volume,
            rate = data.rate or 1.0,
            loop = data.loop,
            eq = data.eq,
            interiorEffect = data.interiorEffect,
            coneInnerAngle = data.coneInnerAngle,
            coneOuterAngle = data.coneOuterAngle,
            volumeFadeStarts = data.volumeFadeStarts,
            volumeFadeMultiplier = data.volumeFadeMultiplier
        })
        current:setVolume(data.volume)
        current:setEqualizer(data.eq)
        
        if data.action == 'play' and not current.isPlaying then
            current:play()
        end
    else
        local direction = RotationToDirection(rot)
        local sound = Interface.CreateSound({
            soundId = sId,
            url = data.url or 'https://raw.githubusercontent.com/audio-samples/audio-samples.github.io/refs/heads/master/samples/mp3/music/sample-0.mp3',
            coords = coords,
            maxDistance = data.maxDistance,
            volume = data.volume,
            rate = data.rate or 1.0,
            is3d = data.is3d,
            loop = data.loop,
            eq = data.eq or DEFAULT_EQ,
            interiorEffect = data.interiorEffect,
            setting3d = {
                coneInnerAngle = data.coneInnerAngle,
                coneOuterAngle = data.coneOuterAngle,
                orientation = direction,
                volumeFadeStarts = data.volumeFadeStarts,
                volumeFadeMultiplier = data.volumeFadeMultiplier
            }
        })
        sound.orientation = direction 
        if data.action == 'play' then sound:play() end
    end
    cb('ok')
end)