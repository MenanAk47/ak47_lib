local activeSounds = {}
local isLoopActive = false
local soundCounter = 0
local pendingPromises = {}

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

RegisterNUICallback('audioDataResult', function(data, cb)
    if data.reqId and pendingPromises[data.reqId] then
        pendingPromises[data.reqId]:resolve(data)
        pendingPromises[data.reqId] = nil
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
            if next(activeSounds) == nil then
                isLoopActive = false
                break
            end

            local playerPed = PlayerPedId()
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            local forward = RotationToDirection(camRot)
            local playerInterior = GetInteriorFromEntity(playerPed)
            
            -- Update Listener Position (Camera)
            SendNUIMessage({
                action = "updateListener",
                camCoords = { x = camCoords.x, y = camCoords.y, z = camCoords.z },
                camForward = { x = forward.x, y = forward.y, z = forward.z },
                camUp = { x = 0.0, y = 0.0, z = 1.0 }
            })

            local sleep = 1000

            -- Update Occlusion and Distances
            for id, sound in pairs(activeSounds) do
                if sound.is3d and sound.isPlaying then
                    if sound.maxDistance and #(GetEntityCoords(playerPed) - sound.coords) <= sound.maxDistance then
                        sleep = 50
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
            Wait(sleep)
        end
    end)
end

-- =========================================================================
--                           SOUND OBJECT CLASS
-- =========================================================================

local SoundObject = {}
SoundObject.__index = SoundObject

-- 1. PLAY / RESUME
function SoundObject:play()
    self.isPlaying = true
    
    if not self.isInitialized then
        -- First time play: Create the sound in NUI
        self.isInitialized = true
        activeSounds[self.soundId] = self

        SendNUIMessage({
            action = "playSound",
            soundId = self.soundId,
            url = self.url,
            coords = self.coords and { x = self.coords.x, y = self.coords.y, z = self.coords.z } or nil,
            volume = self.volume,
            rate = self.rate,
            is3d = self.is3d,
            maxDistance = self.maxDistance
        })

        StartAudioLoop()

        -- Handle Global Sync (Create on other clients)
        if self.global and not self.isReplicated then
            TriggerServerEvent('ak47_bridge:server:PlaySound', {
                soundId = self.soundId,
                url = self.url,
                coords = self.coords,
                maxVolume = self.volume, -- sync current volume as max
                maxDistance = self.maxDistance,
                is3d = self.is3d,
                interiorEffect = self.interiorEffect,
                global = true,
                rate = self.rate
            })
        end
    else
        -- Resume: Just unpause in NUI
        SendNUIMessage({ action = "resumeSound", soundId = self.soundId })
        
        -- Handle Global Sync (Resume)
        if self.global and not self.isReplicated then
            TriggerServerEvent('ak47_bridge:server:ResumeSound', self.soundId)
        end
    end
    
    return self
end

-- 2. PAUSE
function SoundObject:pause()
    self.isPlaying = false
    SendNUIMessage({ action = "pauseSound", soundId = self.soundId })
    
    if self.global and not self.isReplicated then
        TriggerServerEvent('ak47_bridge:server:PauseSound', self.soundId)
    end
    return self
end

-- 3. DESTROY / STOP
function SoundObject:destroy()
    self.isPlaying = false
    self.isInitialized = false
    activeSounds[self.soundId] = nil
    
    SendNUIMessage({ action = "stopSound", soundId = self.soundId })
    
    if self.global and not self.isReplicated then
        TriggerServerEvent('ak47_bridge:server:StopSound', self.soundId)
    end
    return nil -- Return nil so user can do: sound = sound:destroy()
end

-- 4. SETTERS
function SoundObject:setVolume(volume)
    self.volume = volume
    if self.isInitialized then
        SendNUIMessage({ action = "updateVolume", soundId = self.soundId, volume = volume })
    end
    -- Usually volume is local preference, but if you want global volume sync:
    -- if self.global then TriggerServerEvent(...) end
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

-- 5. GETTERS (Async)
function SoundObject:getInfo()
    -- 1. If sound isn't ready, return default immediately
    if not self.isInitialized then 
        return { duration = 0, currentTime = 0 }
    end

    -- 2. Create a Promise
    local p = promise.new()

    -- 3. Create a unique ID for this specific request
    local reqId = "req_" .. GetGameTimer() .. "_" .. math.random(9999)

    -- 4. Store the promise so the NUI Callback can find it
    pendingPromises[reqId] = p

    -- 5. Send the request to JS
    SendNUIMessage({
        action = "getInfo",
        soundId = self.soundId,
        reqId = reqId
    })

    -- 6. PAUSE execution here until JS replies (Async/Await pattern)
    -- This looks synchronous but doesn't freeze the game
    local result = Citizen.Await(p)

    -- 7. Return the data directly
    return result
end

-- Compatibility
SoundObject.__tostring = function(self) return self.soundId end


-- =========================================================================
--                            INTERFACE / EXPORTS
-- =========================================================================

-- The NEW Constructor
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

    local newSound = setmetatable({
        soundId = id,
        url = data.url,
        coords = coords,
        is3d = is3d,
        maxDistance = data.maxDistance or 20.0,
        volume = data.volume or data.maxVolume or 0.5,
        rate = data.rate or 1.0,
        interiorEffect = data.interiorEffect,
        interiorId = interiorId,
        global = data.global,
        
        -- State flags
        isInitialized = false, -- Has not been sent to NUI yet
        isPlaying = false,
        isReplicated = data.replicated or false, -- If true, it came from server
        isOccluded = false,
    }, SoundObject)

    -- If this is a replicated sound (from server), we auto-initialize it
    if data.replicated then
        newSound:play() 
    end

    return newSound
end


-- Legacy/Direct wrapper for backward compatibility or simple usage
Interface.PlaySound = function(data)
    local sound = Interface.CreateSound(data)
    sound:play()
    return sound
end

-- Network Events for Global Sounds
RegisterNetEvent('ak47_bridge:client:PlaySound', function(data)
    data.replicated = true 
    Interface.CreateSound(data) -- CreateSound automatically calls :play() if replicated is true
end)

RegisterNetEvent('ak47_bridge:client:PauseSound', function(soundId)
    if activeSounds[soundId] then activeSounds[soundId]:pause() end
end)

RegisterNetEvent('ak47_bridge:client:ResumeSound', function(soundId)
    if activeSounds[soundId] then activeSounds[soundId]:play() end
end)

RegisterNetEvent('ak47_bridge:client:StopSound', function(soundId)
    if activeSounds[soundId] then activeSounds[soundId]:destroy() end
end)

RegisterNetEvent('ak47_bridge:client:UpdateSoundCoords', function(soundId, coords)
    if activeSounds[soundId] then activeSounds[soundId]:updateCoords(coords) end
end)

RegisterNetEvent('ak47_bridge:client:SyncState', function(soundId, key, value)
    if activeSounds[soundId] then
        if key == 'rate' then activeSounds[soundId]:setRate(value) end
    end
end)

-- Exports
exports('CreateSound', Interface.CreateSound) -- The new OOP way
exports('PlaySound', Interface.PlaySound)     -- The old "Fire and Forget" way

-- Global Access
Bridge.CreateSound = Interface.CreateSound
Bridge.PlaySound = Interface.PlaySound

-- =========================================================================
--                                 TESTING
-- =========================================================================

RegisterCommand('testoop', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local url = 'https://raw.githubusercontent.com/rafaelreis-hotmart/Audio-Sample-files/master/sample.mp3'

    print(" Creating Sound Object...")
    
    -- 1. Create the Object (Nothing plays yet)
    local music = Bridge.CreateSound({
        url = url,
        coords = coords,
        volume = 0.5,
        maxDistance = 15.0,
        is3d = true,
        global = false -- Set to true to test network
    })

    print(" Object Created. ID:", music.soundId)
    Wait(1000)

    print(" Playing...")
    music:play() -- Now it starts

    Wait(3000)
    print(" Pausing...")
    music:pause()

    Wait(2000)
    print(" Changing Settings & Resuming...")
    music:setVolume(0.2)
    music:setRate(1.5)
    music:play()

    Wait(3000)
    print(" Destroying...")
    music:destroy()
end, false)