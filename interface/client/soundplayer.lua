local activeSounds = {}
local isLoopActive = false
local soundCounter = 0
local pendingPromises = {}

-- Gizmo State
local isGizmoOpen = false
local isGizmoFocused = false

-- Visuals
local gizmoEntity = nil
local currentGizmoData = {
    coords = vector3(0,0,0),
    rot = vector3(0,0,0),
    maxDistance = 10.0
}

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

-- =========================================================================
--                                 HELPERS
-- =========================================================================

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

local function EnsureGizmoEntity(coords, rot)
    if not isGizmoOpen then 
        if gizmoEntity and DoesEntityExist(gizmoEntity) then DeleteEntity(gizmoEntity) end
        gizmoEntity = nil
        return 
    end

    -- Create Prop if missing
    if not gizmoEntity or not DoesEntityExist(gizmoEntity) then
        local model = `prop_speaker_05`
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end
        gizmoEntity = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
        SetEntityCollision(gizmoEntity, false, false) -- No collision
        SetEntityAlpha(gizmoEntity, 200, false)
    end

    -- Update Position & Rotation
    SetEntityCoords(gizmoEntity, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityRotation(gizmoEntity, rot.x, rot.y, rot.z + 180.0, 2, true)
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
    cb('ok')
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
                camRot = { x = camRot.x, y = camRot.y, z = camRot.z }, -- NEW: Send raw rotation
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
                            sleep = 50
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
            if isGizmoOpen then
                sleep = 1
            end
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
        
        -- Resolve orientation for NUI
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
            orientation = orientation, 
            maxDistance = self.maxDistance,
            loop = self.loop,
        })
        StartAudioLoop()
        if self.global and not self.isReplicated then
            TriggerServerEvent('ak47_bridge:server:PlaySound', {
                soundId = self.soundId,
                url = self.url,
                coords = self.coords,
                maxVolume = self.volume,
                maxDistance = self.maxDistance,
                is3d = self.is3d,
                setting3d = self.setting3d,
                interiorEffect = self.interiorEffect,
                global = true,
                rate = self.rate,
                loop = self.loop,
            })
        end
    else
        SendNUIMessage({ action = "resumeSound", soundId = self.soundId })
        if self.global and not self.isReplicated then
            TriggerServerEvent('ak47_bridge:server:ResumeSound', self.soundId)
        end
    end
    return self
end

function SoundObject:pause()
    self.isPlaying = false
    SendNUIMessage({ action = "pauseSound", soundId = self.soundId })
    if self.global and not self.isReplicated then
        TriggerServerEvent('ak47_bridge:server:PauseSound', self.soundId)
    end
    return self
end

function SoundObject:destroy()
    self.isPlaying = false
    self.isInitialized = false
    activeSounds[self.soundId] = nil
    SendNUIMessage({ action = "stopSound", soundId = self.soundId })
    if self.global and not self.isReplicated then
        TriggerServerEvent('ak47_bridge:server:StopSound', self.soundId)
    end
    return nil
end

function SoundObject:setVolume(volume)
    self.volume = volume
    if self.isInitialized then
        SendNUIMessage({ action = "updateVolume", soundId = self.soundId, volume = volume })
    end
    return self
end

function SoundObject:setRate(rate)
    self.rate = rate
    if self.isInitialized then
        SendNUIMessage({ action = "updateRate", soundId = self.soundId, rate = rate })
    end
    if self.global and not self.isReplicated then
        TriggerServerEvent('ak47_bridge:server:SyncState', self.soundId, 'rate', rate)
    end
    return self
end

function SoundObject:setMaxDistance(dist)
    self.maxDistance = dist
    if self.isInitialized then
        SendNUIMessage({ action = "updateMaxDistance", soundId = self.soundId, maxDistance = dist })
    end
    return self
end

function SoundObject:updateCoords(coords)
    self.coords = coords
    self.interiorId = GetInteriorFromCollision(coords.x, coords.y, coords.z)
    if self.isInitialized then
        SendNUIMessage({
            action = "updateSoundCoords",
            soundId = self.soundId,
            coords = { x = coords.x, y = coords.y, z = coords.z }
        })
    end
    if self.global and not self.isReplicated then
        TriggerServerEvent('ak47_bridge:server:UpdateSoundCoords', self.soundId, coords)
    end
    return self
end

function SoundObject:updateSettings(data)
    self.coords = data.coords or self.coords
    self.maxDistance = data.maxDistance or self.maxDistance
    self.volume = data.volume or self.volume
    self.rate = data.rate or self.rate
    if data.loop ~= nil then self.loop = data.loop end
    if data.interiorEffect ~= nil then self.interiorEffect = data.interiorEffect end
    
    local orientation = nil
    if data.rot then
        orientation = RotationToDirection(data.rot)
        self.orientation = orientation
    end

    if self.isInitialized then
        SendNUIMessage({
            action = "updateSoundSettings",
            soundId = self.soundId,
            coords = self.coords,
            orientation = orientation,
            maxDistance = self.maxDistance,
            volume = self.volume,
            rate = self.rate,
            loop = self.loop,
            coneInnerAngle = data.coneInnerAngle,
            coneOuterAngle = data.coneOuterAngle,
            volumeFadeStarts = data.volumeFadeStarts,
            volumeFadeMultiplier = data.volumeFadeMultiplier,
        })
    end
    return self
end

function SoundObject:getInfo()
    if not self.isInitialized then return { duration = 0, currentTime = 0 } end
    local p = promise.new()
    local reqId = "req_" .. GetGameTimer() .. "_" .. math.random(9999)
    pendingPromises[reqId] = p
    SendNUIMessage({ action = "getInfo", soundId = self.soundId, reqId = reqId })
    local result = Citizen.Await(p)
    return result
end
SoundObject.__tostring = function(self) return self.soundId end

-- =========================================================================
--                            INTERFACE / EXPORTS
-- =========================================================================

Interface.CreateSound = function(data)
    local coords = data.coords
    local is3d = data.is3d
    local interiorId = 0
    if coords then
        if is3d == nil then is3d = true end
        interiorId = GetInteriorFromCollision(coords.x, coords.y, coords.z)
    else
        is3d = false
        coords = vector3(0, 0, 0)
    end
    local id = data.soundId or GetUniqueId()
    local internalInstance = setmetatable({
        soundId = id,
        url = data.url,
        coords = coords,
        is3d = is3d,
        setting3d = {
            volumeFadeStarts = data.volumeFadeStarts and data.setting3d.volumeFadeStarts or 3.0,
            volumeFadeMultiplier = data.volumeFadeMultiplier and data.setting3d.volumeFadeMultiplier or 1.0,
            coneInnerAngle = data.coneInnerAngle and data.setting3d.coneInnerAngle or 360.0,
            coneOuterAngle = data.coneOuterAngle and data.setting3d.coneOuterAngle or 360.0,
            orientation = data.setting3d and data.setting3d.orientation or nil
        },
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
        isOccluded = false,
        orientation = data.setting3d and data.setting3d.orientation or nil
    }, SoundObject)

    local publicWrapper = {
        soundId = id,
        play = function() internalInstance:play() return publicWrapper end,
        pause = function() internalInstance:pause() return publicWrapper end,
        destroy = function() internalInstance:destroy() return nil end,
        setVolume = function(_, vol) local v = type(_) == "number" and _ or vol; internalInstance:setVolume(v); return publicWrapper end,
        setRate = function(_, rate) local r = type(_) == "number" and _ or rate; internalInstance:setRate(r); return publicWrapper end,
        setMaxDistance = function(_, dist) local d = type(_) == "number" and _ or dist; internalInstance:setMaxDistance(d); return publicWrapper end,
        updateCoords = function(_, newCoords) local c = (type(_) == "vector3" or type(_) == "table") and _ or newCoords; internalInstance:updateCoords(c); return publicWrapper end,
        getInfo = function() return internalInstance:getInfo() end
    }
    if data.replicated then internalInstance:play() end
    return publicWrapper
end

RegisterNetEvent('ak47_bridge:client:PlaySound', function(data)
    if activeSounds[data.soundId] then return end
    data.replicated = true 
    Interface.CreateSound(data)
end)
RegisterNetEvent('ak47_bridge:client:PauseSound', function(soundId) if activeSounds[soundId] then activeSounds[soundId]:pause() end end)
RegisterNetEvent('ak47_bridge:client:ResumeSound', function(soundId) if activeSounds[soundId] then activeSounds[soundId]:play() end end)
RegisterNetEvent('ak47_bridge:client:StopSound', function(soundId) if activeSounds[soundId] then activeSounds[soundId]:destroy() end end)
RegisterNetEvent('ak47_bridge:client:UpdateSoundCoords', function(soundId, coords) if activeSounds[soundId] then activeSounds[soundId]:updateCoords(coords) end end)
RegisterNetEvent('ak47_bridge:client:SyncState', function(soundId, key, value) if activeSounds[soundId] and key == 'rate' then activeSounds[soundId]:setRate(value) end end)
exports('CreateSound', Interface.CreateSound)
Bridge.CreateSound = Interface.CreateSound

-- =========================================================================
--                            GIZMO / DEBUGGER
-- =========================================================================

-- Visuals & Input Loop
local function StartGizmoLoop()
    Citizen.CreateThread(function()
        while isGizmoOpen do
            -- 1. Input Handling
            if not isGizmoFocused then
                DisableControlAction(0, 19, true) -- Left Alt
                if IsDisabledControlJustReleased(0, 19) then
                    isGizmoFocused = true
                    SetNuiFocus(true, true)
                    SendNUIMessage({ action = "regainFocus" })
                end
            end
            
            -- 2. Visuals (Markers)
            if currentGizmoData and currentGizmoData.coords then
                -- Draw Max Distance Sphere (Type 28)
                DrawMarker(28, 
                    currentGizmoData.coords.x, currentGizmoData.coords.y, currentGizmoData.coords.z, 
                    0.0, 0.0, 0.0, 
                    0.0, 0.0, 0.0, 
                    currentGizmoData.maxDistance, currentGizmoData.maxDistance, currentGizmoData.maxDistance, 
                    66, 135, 245, 100, -- Blueish
                    false, false, 2, nil, nil, false
                )
            end

            Wait(0)
        end
        
        -- Cleanup when loop ends
        if gizmoEntity and DoesEntityExist(gizmoEntity) then 
            DeleteEntity(gizmoEntity) 
            gizmoEntity = nil
        end
    end)
end

RegisterCommand('soundgizmo', function()
    isGizmoOpen = not isGizmoOpen
    isGizmoFocused = isGizmoOpen
    
    SetNuiFocus(isGizmoOpen, isGizmoOpen)

    local playerPed = PlayerPedId()
    local pCoords = GetEntityCoords(playerPed)
    local pRot = GetEntityRotation(playerPed, 2)
    
    -- Calculate Forward Offset (2.0 meters in front)
    local forward = RotationToDirection(pRot)
    local spawnCoords = pCoords + (forward * 1.5)

    -- Calculate Rotation to face the player (Player Rotation + 180 degrees on Z)
    -- We keep X and Y 0 to keep it upright initially
    local spawnRot = vector3(0.0, 0.0, pRot.z + 180.0)

    SendNUIMessage({
        action = "toggleGizmo",
        show = isGizmoOpen,
        playerCoords = { x = pCoords.x, y = pCoords.y, z = pCoords.z }, -- Backup/Reference
        spawnCoords = { x = spawnCoords.x, y = spawnCoords.y, z = spawnCoords.z },
        spawnRot = { x = spawnRot.x, y = spawnRot.y, z = spawnRot.z }
    })
    
    if isGizmoOpen then
        -- Initialize data with the new spawn coordinates
        currentGizmoData.coords = spawnCoords
        StartAudioLoop() 
        StartGizmoLoop()
    end
end)

RegisterNUICallback('closeGizmo', function(data, cb)
    isGizmoOpen = false
    isGizmoFocused = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('releaseFocus', function(data, cb)
    isGizmoFocused = false
    SetNuiFocus(false, false)
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
    
    -- If URL changed, we must recreate the sound
    if current and current.url ~= data.url then
        current:destroy()
        current = nil
    end

    local coords = vector3(data.x, data.y, data.z)
    local rot = vector3(data.rotX or 0, data.rotY or 0, data.rotZ or 0)

    -- Update Gizmo Visuals Data
    currentGizmoData.coords = coords
    currentGizmoData.rot = rot
    currentGizmoData.maxDistance = data.maxDistance
    EnsureGizmoEntity(coords, rot)

    if current then
        -- Update existing sound completely
        current:updateSettings({
            coords = coords,
            rot = rot,
            maxDistance = data.maxDistance,
            volume = data.volume,
            rate = data.rate or 1.0,
            loop = data.loop,
            interiorEffect = data.interiorEffect,
            coneInnerAngle = data.coneInnerAngle,
            coneOuterAngle = data.coneOuterAngle,
            volumeFadeStarts = data.volumeFadeStarts,
            volumeFadeMultiplier = data.volumeFadeMultiplier
        })
        -- FIX: Force volume update (Some players don't update volume via generic settings update)
        current:setVolume(data.volume)
        
        -- Handle Play/Pause State
        if data.action == 'play' and not current.isPlaying then
            current:play()
        elseif data.action == 'update' and current.isPlaying then
             -- Do nothing, let it keep playing
        end
    else
        -- Create new sound
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
        
        -- FIX: Only auto-play if the action is explicitly 'play'
        -- This prevents the sound from auto-starting when just updating config/url
        if data.action == 'play' then
            sound:play()
        else
            -- Ensure it is created but paused/ready
            -- Note: Interface.CreateSound does not auto-play unless replicated=true
        end
    end
    cb('ok')
end)