-- =========================================================================
--                      AK47_LIB: GENERIC GIZMO MODULE
-- =========================================================================
local isGizmoOpen = false
local isGizmoFocused = false
local isHoldingRMB = false
local gizmoEntity = nil
local activeCallback = nil
local lastGizmoData = nil
local initialGizmoData = nil

Lib47.Gizmo = {}

local function RotationToDirection(rotation)
    local x = (math.pi / 180) * rotation.x
    local z = (math.pi / 180) * rotation.z
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

-- Function to draw a 3D bounding box around our dummy entity
local function DrawEntityBoundingBox(entity, r, g, b, a)
    local min, max = GetModelDimensions(GetEntityModel(entity))
    local pad = 0.05 -- Slight padding so it doesn't clip into the prop
    min = vector3(min.x - pad, min.y - pad, min.z - pad)
    max = vector3(max.x + pad, max.y + pad, max.z + pad)

    -- Calculate the 8 corners in world coordinates
    local c1 = GetOffsetFromEntityInWorldCoords(entity, min.x, min.y, min.z)
    local c2 = GetOffsetFromEntityInWorldCoords(entity, max.x, min.y, min.z)
    local c3 = GetOffsetFromEntityInWorldCoords(entity, max.x, max.y, min.z)
    local c4 = GetOffsetFromEntityInWorldCoords(entity, min.x, max.y, min.z)
    
    local c5 = GetOffsetFromEntityInWorldCoords(entity, min.x, min.y, max.z)
    local c6 = GetOffsetFromEntityInWorldCoords(entity, max.x, min.y, max.z)
    local c7 = GetOffsetFromEntityInWorldCoords(entity, max.x, max.y, max.z)
    local c8 = GetOffsetFromEntityInWorldCoords(entity, min.x, max.y, max.z)

    -- Bottom plane
    DrawLine(c1.x, c1.y, c1.z, c2.x, c2.y, c2.z, r, g, b, a)
    DrawLine(c2.x, c2.y, c2.z, c3.x, c3.y, c3.z, r, g, b, a)
    DrawLine(c3.x, c3.y, c3.z, c4.x, c4.y, c4.z, r, g, b, a)
    DrawLine(c4.x, c4.y, c4.z, c1.x, c1.y, c1.z, r, g, b, a)

    -- Top plane
    DrawLine(c5.x, c5.y, c5.z, c6.x, c6.y, c6.z, r, g, b, a)
    DrawLine(c6.x, c6.y, c6.z, c7.x, c7.y, c7.z, r, g, b, a)
    DrawLine(c7.x, c7.y, c7.z, c8.x, c8.y, c8.z, r, g, b, a)
    DrawLine(c8.x, c8.y, c8.z, c5.x, c5.y, c5.z, r, g, b, a)

    -- Vertical lines connecting top and bottom
    DrawLine(c1.x, c1.y, c1.z, c5.x, c5.y, c5.z, r, g, b, a)
    DrawLine(c2.x, c2.y, c2.z, c6.x, c6.y, c6.z, r, g, b, a)
    DrawLine(c3.x, c3.y, c3.z, c7.x, c7.y, c7.z, r, g, b, a)
    DrawLine(c4.x, c4.y, c4.z, c8.x, c8.y, c8.z, r, g, b, a)
end

function Lib47.Gizmo.Start(options, callback)
    if isGizmoOpen then return end
    isGizmoOpen = true
    isGizmoFocused = true
    isHoldingRMB = false
    activeCallback = callback
    
    initialGizmoData = {
        x = options.coords.x, 
        y = options.coords.y, 
        z = options.coords.z,
        rotX = options.rot and options.rot.x or 0.0,
        rotY = options.rot and options.rot.y or 0.0,
        rotZ = options.rot and options.rot.z or 0.0
    }
    
    -- Clone initial to last
    lastGizmoData = json.decode(json.encode(initialGizmoData))

    -- 1. Tell OUR NUI to open internally
    SendNUIMessage({
        action = "toggleGizmo",
        show = true,
        spawnCoords = { x = lastGizmoData.x, y = lastGizmoData.y, z = lastGizmoData.z },
        spawnRot = { x = lastGizmoData.rotX, y = lastGizmoData.rotY, z = lastGizmoData.rotZ }
    })

    -- 2. Spawn Dummy Prop if requested
    if options.model then
        local model = type(options.model) == 'string' and joaat(options.model) or options.model
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end
        gizmoEntity = CreateObject(model, options.coords.x, options.coords.y, options.coords.z, false, false, false)
        SetEntityCollision(gizmoEntity, false, false)
        SetEntityAlpha(gizmoEntity, 200, false)
        
        if options.rot then
            SetEntityRotation(gizmoEntity, options.rot.x, options.rot.y, options.rot.z, 2, true)
        end
    end

    SetNuiFocus(true, true)

    -- Generic Camera & Input Loop
    Citizen.CreateThread(function()
        while isGizmoOpen do
            -- Handling RMB Free Cam Movement
            if isHoldingRMB then
                DisableControlAction(0, 25, true) -- Disable aim
                DisablePlayerFiring(PlayerId(), true) -- Disable shooting
                
                -- When user lets go of RMB
                if IsDisabledControlJustReleased(0, 25) then
                    isHoldingRMB = false
                    SetNuiFocus(true, true)
                    SetNuiFocusKeepInput(false)
                    SendNUIMessage({ action = "regainGizmoFocus" })
                end
            end

            -- Update React Camera
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            local forward = RotationToDirection(camRot)

            SendNUIMessage({
                action = "updateGizmoCamera",
                camCoords = { x = camCoords.x, y = camCoords.y, z = camCoords.z },
                camRot = { x = camRot.x, y = camRot.y, z = camRot.z },
                camFov = GetGameplayCamFov(),
                camForward = { x = forward.x, y = forward.y, z = forward.z },
                camUp = { x = 0.0, y = 0.0, z = 1.0 }
            })

            -- Render Bounding Box around entity
            if gizmoEntity and DoesEntityExist(gizmoEntity) then
                DrawEntityBoundingBox(gizmoEntity, 255, 255, 255, 200)
            end

            Wait(0)
        end

        if gizmoEntity and DoesEntityExist(gizmoEntity) then
            DeleteEntity(gizmoEntity)
            gizmoEntity = nil
        end
    end)
end

function Lib47.Gizmo.Stop(isCancel)
    if not isGizmoOpen then return end
    isGizmoOpen = false
    isGizmoFocused = false
    isHoldingRMB = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    
    SendNUIMessage({ action = "toggleGizmo", show = false })
    
    if activeCallback then 
        if isCancel and initialGizmoData then
            activeCallback({ 
                event = 'cancelled',
                coords = vector3(initialGizmoData.x, initialGizmoData.y, initialGizmoData.z),
                rot = vector3(initialGizmoData.rotX, initialGizmoData.rotY, initialGizmoData.rotZ)
            }) 
        elseif not isCancel and lastGizmoData then
            activeCallback({ 
                event = 'closed',
                coords = vector3(lastGizmoData.x, lastGizmoData.y, lastGizmoData.z),
                rot = vector3(lastGizmoData.rotX, lastGizmoData.rotY, lastGizmoData.rotZ)
            }) 
        end
    end
    
    activeCallback = nil
    lastGizmoData = nil
    initialGizmoData = nil
end

-- =========================================================================
--                            NUI CALLBACKS
-- =========================================================================
RegisterNUICallback('gizmoUpdate', function(data, cb)
    lastGizmoData = {
        x = data.x, y = data.y, z = data.z,
        rotX = data.rotX, rotY = data.rotY, rotZ = data.rotZ
    }

    if gizmoEntity and DoesEntityExist(gizmoEntity) then
        SetEntityCoords(gizmoEntity, data.x, data.y, data.z, false, false, false, false)
        SetEntityRotation(gizmoEntity, data.rotX, data.rotY, data.rotZ, 2, true) -- Removed arbitrary +180.0
    end
    
    if activeCallback then
        data.event = 'update'
        activeCallback(data)
    end
    cb('ok')
end)

RegisterNUICallback('rightClickDown', function(data, cb)
    isHoldingRMB = true
    SetNuiFocus(true, false) -- Hide cursor
    SetNuiFocusKeepInput(true) -- Allow inputs to pass to game so player can move mouse
    cb('ok')
end)

RegisterNUICallback('gizmoReleaseFocus', function(data, cb)
    isGizmoFocused = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('gizmoClose', function(data, cb)
    Lib47.Gizmo.Stop(false)
    cb('ok')
end)

RegisterNUICallback('gizmoCancel', function(data, cb)
    -- Reset prop position just before deleting in case visual flash occurs
    if gizmoEntity and DoesEntityExist(gizmoEntity) and initialGizmoData then
        SetEntityCoords(gizmoEntity, initialGizmoData.x, initialGizmoData.y, initialGizmoData.z, false, false, false, false)
        SetEntityRotation(gizmoEntity, initialGizmoData.rotX, initialGizmoData.rotY, initialGizmoData.rotZ, 2, true)
    end
    Lib47.Gizmo.Stop(true)
    cb('ok')
end)

RegisterNUICallback('gizmoSnapToGround', function(data, cb)
    local success, groundZ = GetGroundZFor_3dCoord(data.x, data.y, data.z + 100.0, false)
    
    if success then
        lastGizmoData.z = groundZ
        
        -- Move the entity immediately
        if gizmoEntity and DoesEntityExist(gizmoEntity) then
            SetEntityCoords(gizmoEntity, data.x, data.y, groundZ, false, false, false, false)
        end
        
        -- Seamlessly update React state without re-toggling the whole UI
        SendNUIMessage({
            action = "updateGizmoCoords",
            coords = { x = data.x, y = data.y, z = groundZ }
        })
    end
    cb('ok')
end)

-- =========================================================================
--                            EXPORTS
-- =========================================================================
exports('StartGizmo', Lib47.Gizmo.Start)
exports('StopGizmo', Lib47.Gizmo.Stop)

--================ Example ===============


-- Example: Using the Gizmo export in another resource
local isPlacingObject = false
local finalCoords = nil
local finalRotation = nil

function StartPlacingProp(modelName)
    if isPlacingObject then return end
    isPlacingObject = true
    
    local playerPed = PlayerPedId()
    local startCoords = GetEntityCoords(playerPed) + GetEntityForwardVector(playerPed) * 2.0
    
    -- Call the export from your lib resource
    exports['ak47_lib']:StartGizmo({
        model = modelName,
        coords = startCoords,
        rot = vector3(0.0, 0.0, GetEntityHeading(playerPed))
    }, function(result)
        
        -- Handle real-time movement updates if you need to do distance checks, etc.
        if result.event == 'update' then
            -- Optional: print(result.x, result.y, result.z)
            return
        end
        
        -- Handle the final placement when the user closes the gizmo
        if result.event == 'closed' then
            isPlacingObject = false
            finalCoords = result.coords
            finalRotation = result.rot
            
            print("Finished placing prop!")
            print("Final Coords:", finalCoords)
            print("Final Rotation:", finalRotation)
            
            -- Now you can spawn the ACTUAL server-side object or save it to your database
            SpawnFinalNetworkedObject(modelName, finalCoords, finalRotation)
        end
    end)
end

function SpawnFinalNetworkedObject(model, coords, rot)
    local hash = type(model) == 'string' and joaat(model) or model
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    
    local obj = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false)
    SetEntityRotation(obj, rot.x, rot.y, rot.z, 2, true)
    FreezeEntityPosition(obj, true)
end

-- Command to test it in-game
RegisterCommand('testgizmo', function()
    StartPlacingProp('prop_bench_01a')
end, false)
