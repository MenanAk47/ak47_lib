-- =========================================================================
--             AK47_LIB: ADVANCED GIZMO & OBJECT PLACEMENT BUILDER
-- =========================================================================

Lib47 = Lib47 or {}
Lib47.Creation = Lib47.Creation or {}
Lib47.Creation.Cam = Lib47.Creation.Cam or {}
Lib47.Creation.Render = Lib47.Creation.Render or {}
Lib47.Creation.Builders = Lib47.Creation.Builders or {}
Lib47.Gizmo = Lib47.Gizmo or {}

-- =========================================================================
--                             LOCAL STATE
-- =========================================================================
local isGizmoOpen = false
local isGizmoFocused = false
local isHoldingRMB = false
local isHoldingLMB = false
local currentGizmoEntity = nil
local isSpawnedDummy = false
local activeCallback = nil
local lastGizmoData = nil
local lastCamCoords = nil
local initialGizmoData = nil
local initialPedCoords = nil
local initialPedHeading = nil
local currentGizmoMode = 'translate'
local currentGizmoSpace = 'local'
local gizmoResultPromise = nil

-- Default Locales
local defaultLocales = {
    placement = "Object Placement",
    cam_controls = "Camera Controls",
    navigation = "Navigation",
    move_with_cam = "Move with Cam <m>1<m> + <m>2<m>",
    raycast_drag = "Drag / Place <m>1<m>",
    gizmo_handles = "3D Gizmo Handles <m><m>",
    cam_orbit = "Look / Orbit <m>2<m> + <m><m>",
    cam_pan = "Fly / Pan <m>2<m> + <k>W<k><k>A<k><k>S<k><k>D<k>",
    precision = "Precision <k>SHIFT<k>",
    confirm = "Confirm <k>ENTER<k>",
    cancel = "Cancel <k>DEL<k>",
}

local function L(locales, key)
    if locales and locales[key] then return locales[key] end
    return defaultLocales[key] or key
end

local function ToVector3(val)
    if not val then return nil end
    if type(val) == 'vector3' then return val end
    if type(val) == 'table' then
        if val.x and val.y and val.z then
            return vector3(tonumber(val.x) or 0.0, tonumber(val.y) or 0.0, tonumber(val.z) or 0.0)
        elseif val[1] and val[2] and val[3] then
            return vector3(tonumber(val[1]) or 0.0, tonumber(val[2]) or 0.0, tonumber(val[3]) or 0.0)
        end
    end
    return nil
end

local function RotationToDirection(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

local function VecDist(v1, v2)
    if not v1 or not v2 or not v1.x or not v2.x then return 0.0 end
    local dx = (v1.x or 0) - (v2.x or 0)
    local dy = (v1.y or 0) - (v2.y or 0)
    local dz = (v1.z or 0) - (v2.z or 0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function ClampVecLength(v, maxLength)
    local sqMag = (v.x * v.x) + (v.y * v.y) + (v.z * v.z)
    if sqMag > (maxLength * maxLength) then
        local len = math.sqrt(sqMag)
        if len > 1e-5 then
            return vector3((v.x / len) * maxLength, (v.y / len) * maxLength, (v.z / len) * maxLength)
        end
    end
    return v
end

-- 3D Bounding Box Drawing
local function DrawEntityBoundingBox(entity, r, g, b, a)
    if not entity or not DoesEntityExist(entity) then return end
    local min, max = GetModelDimensions(GetEntityModel(entity))
    local pad = 0.02
    min = vector3(min.x - pad, min.y - pad, min.z - pad)
    max = vector3(max.x + pad, max.y + pad, max.z + pad)

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

    -- Connectors
    DrawLine(c1.x, c1.y, c1.z, c5.x, c5.y, c5.z, r, g, b, a)
    DrawLine(c2.x, c2.y, c2.z, c6.x, c6.y, c6.z, r, g, b, a)
    DrawLine(c3.x, c3.y, c3.z, c7.x, c7.y, c7.z, r, g, b, a)
    DrawLine(c4.x, c4.y, c4.z, c8.x, c8.y, c8.z, r, g, b, a)
end

-- =========================================================================
--                       RAYCAST & OBJECT MOVEMENT
-- =========================================================================
local function RaycastFromCam(distance, ignoreEntity)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local forward = RotationToDirection(camRot)
    local targetCoords = camCoords + (forward * (distance or 60.0))

    local ray = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, targetCoords.x, targetCoords.y, targetCoords.z, 1, ignoreEntity or 0, 5000)
    local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(ray)
    return hit ~= 0, endCoords, surfaceNormal, entityHit, camCoords, forward
end

local function HandleRaycastObjectMove(entity, updateHeading)
    if not entity or not DoesEntityExist(entity) then return end

    local hit, endCoords, surfaceNormal, entityHit, camCoords, forward = RaycastFromCam(60.0, entity)
    local targetPos = nil

    if hit and endCoords then
        local min, max = GetModelDimensions(GetEntityModel(entity))
        local offX, offY, offZ = 0.0, 0.0, 0.0

        if surfaceNormal.x > 0.5 then offX = offX + max.x end
        if surfaceNormal.x < -0.5 then offX = offX + min.x end
        if surfaceNormal.y > 0.5 then offY = offY + max.y end
        if surfaceNormal.y < -0.5 then offY = offY + min.y end
        if surfaceNormal.z > 0.5 then offZ = offZ - min.z end
        if surfaceNormal.z < -0.5 then offZ = offZ - max.z end

        targetPos = vector3(endCoords.x + offX, endCoords.y + offY, endCoords.z + offZ)
    else
        targetPos = camCoords + (forward * 5.0)
    end

    if targetPos then
        SetEntityCoordsNoOffset(entity, targetPos.x, targetPos.y, targetPos.z)
        lastGizmoData.x = targetPos.x
        lastGizmoData.y = targetPos.y
        lastGizmoData.z = targetPos.z

        if updateHeading then
            local camRot = GetGameplayCamRot(2)
            lastGizmoData.rotZ = camRot.z
            SetEntityRotation(entity, lastGizmoData.rotX or 0.0, lastGizmoData.rotY or 0.0, lastGizmoData.rotZ or 0.0, 2, true)
        end

        SendNUIMessage({
            action = "updateGizmoConfig",
            coords = { x = lastGizmoData.x, y = lastGizmoData.y, z = lastGizmoData.z },
            rot = { x = lastGizmoData.rotX or 0.0, y = lastGizmoData.rotY or 0.0, z = lastGizmoData.rotZ or 0.0 }
        })
    end
end

-- =========================================================================
--                             SNAP TO GROUND
-- =========================================================================
local function SnapObjectToGround(entity)
    if not entity or not DoesEntityExist(entity) then return end
    local curCoords = GetEntityCoords(entity)
    local success, groundZ = GetGroundZFor_3dCoord(curCoords.x, curCoords.y, curCoords.z + 100.0, false)
    if not success then
        success, groundZ = GetGroundZFor_3dCoord(curCoords.x, curCoords.y, curCoords.z + 2.0, false)
    end

    if success then
        local min, max = GetModelDimensions(GetEntityModel(entity))
        local finalZ = groundZ - min.z
        SetEntityCoordsNoOffset(entity, curCoords.x, curCoords.y, finalZ)
        
        lastGizmoData.z = finalZ
        SendNUIMessage({
            action = "updateGizmoCoords",
            coords = { x = curCoords.x, y = curCoords.y, z = finalZ }
        })
    end
end

-- =========================================================================
--                        SHOW OBJECTIVE INSTRUCTION
-- =========================================================================
local function ShowGizmoObjective(locales)
    Lib47.ShowObjective({
        {
            Title = L(locales, 'placement'),
            List = {
                L(locales, 'move_with_cam'),
                L(locales, 'raycast_drag'),
                L(locales, 'gizmo_handles'),
            },
        },
        {
            Title = L(locales, 'cam_controls'),
            List = {
                L(locales, 'cam_orbit'),
                L(locales, 'cam_pan'),
                L(locales, 'precision'),
            },
        },
        {
            Title = L(locales, 'navigation'),
            List = {
                L(locales, 'confirm'),
                L(locales, 'cancel'),
            },
        },
    }, L(locales, 'placement'))
end

-- =========================================================================
--                          CORE GIZMO START & STOP
-- =========================================================================

--- Start generic gizmo with custom options & callback
--- @param options table Configuration options (model, entity, coords, rot, hideCopy, hideBottom)
--- @param callback function Optional callback receiving result table
function Lib47.Gizmo.Start(options, callback)
    if isGizmoOpen then return end
    isGizmoOpen = true
    isGizmoFocused = true
    isHoldingRMB = false
    isHoldingLMB = false
    activeCallback = callback
    currentGizmoMode = options.mode or 'translate'
    currentGizmoSpace = options.space or 'local'

    local plyPed = PlayerPedId()
    local plyCoords = GetEntityCoords(plyPed)
    local plyHeading = GetEntityHeading(plyPed)
    
    initialPedCoords = plyCoords
    initialPedHeading = plyHeading

    SetEntityVisible(plyPed, false, false)
    SetEntityCollision(plyPed, false, false)
    FreezeEntityPosition(plyPed, true)
    SetEntityInvincible(plyPed, true)

    local targetEntity = nil
    isSpawnedDummy = false

    -- 1. Determine entity or spawn dummy
    if options.entity and DoesEntityExist(options.entity) then
        targetEntity = options.entity
        isSpawnedDummy = false
        SetEntityCollision(targetEntity, false, false)
        SetEntityAlpha(targetEntity, 204, false)
    elseif options.handle and DoesEntityExist(options.handle) then
        targetEntity = options.handle
        isSpawnedDummy = false
        SetEntityCollision(targetEntity, false, false)
        SetEntityAlpha(targetEntity, 204, false)
    elseif options.model then
        local modelHash = type(options.model) == 'string' and joaat(options.model) or options.model
        Lib47.RequestModel(modelHash)
        
        local spawnPos = ToVector3(options.coords) or options.coords
        if not spawnPos then
            local fwdPos = plyCoords + (GetEntityForwardVector(plyPed) * 3.0)
            local foundGround, groundZ = GetGroundZFor_3dCoord(fwdPos.x, fwdPos.y, fwdPos.z + 2.0, false)
            if not foundGround then
                foundGround, groundZ = GetGroundZFor_3dCoord(fwdPos.x, fwdPos.y, fwdPos.z + 50.0, false)
            end
            if foundGround then
                local min, max = GetModelDimensions(modelHash)
                spawnPos = vector3(fwdPos.x, fwdPos.y, groundZ - min.z)
            else
                spawnPos = fwdPos
            end
        end

        targetEntity = CreateObject(modelHash, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false)
        SetEntityCollision(targetEntity, false, false)
        SetEntityAlpha(targetEntity, 204, false)
        isSpawnedDummy = true
    end

    currentGizmoEntity = targetEntity

    -- 2. Setup Coords & Rotation
    local initialCoords = ToVector3(options.coords) or options.coords
    local initialRot = ToVector3(options.rot) or options.rot

    if targetEntity and DoesEntityExist(targetEntity) then
        if not initialCoords then
            initialCoords = GetEntityCoords(targetEntity)
        else
            SetEntityCoordsNoOffset(targetEntity, initialCoords.x, initialCoords.y, initialCoords.z)
        end

        if not initialRot then
            initialRot = GetEntityRotation(targetEntity, 2)
        else
            SetEntityRotation(targetEntity, initialRot.x, initialRot.y, initialRot.z, 2, true)
        end
    else
        initialCoords = initialCoords or (plyCoords + GetEntityForwardVector(plyPed) * 3.0)
        initialRot = initialRot or vector3(0.0, 0.0, plyHeading)
    end

    initialGizmoData = {
        x = initialCoords.x,
        y = initialCoords.y,
        z = initialCoords.z,
        rotX = initialRot.x or 0.0,
        rotY = initialRot.y or 0.0,
        rotZ = initialRot.z or 0.0
    }

    lastGizmoData = json.decode(json.encode(initialGizmoData))

    -- 3. Point camera to object if camCoords provided
    local initialCamCoords = ToVector3(options.camCoords or options.cam)
    if initialCamCoords and initialCoords then
        SetEntityCoordsNoOffset(plyPed, initialCamCoords.x, initialCamCoords.y, initialCamCoords.z)

        local dx = initialCoords.x - initialCamCoords.x
        local dy = initialCoords.y - initialCamCoords.y
        local dz = initialCoords.z - initialCamCoords.z
        local dist2d = math.sqrt(dx * dx + dy * dy)

        local heading = plyHeading
        if math.abs(dx) > 0.001 or math.abs(dy) > 0.001 then
            heading = GetHeadingFromVector_2d(dx, dy)
        end
        local pitch = dist2d > 0.001 and math.deg(math.atan2(dz, dist2d)) or 0.0
        pitch = math.max(-85.0, math.min(85.0, pitch))

        SetEntityHeading(plyPed, heading)
        SetGameplayCamRelativeHeading(0.0)
        SetGameplayCamRelativePitch(pitch, 1.0)

        lastCamCoords = initialCamCoords
    else
        lastCamCoords = GetGameplayCamCoord()
    end

    -- 4. Show Objective HUD if requested or in builder mode
    if options.showObjective ~= false then
        ShowGizmoObjective(options.locales)
    end

    -- 5. Open React NUI Gizmo
    SendNUIMessage({
        action = "toggleGizmo",
        show = true,
        hideCopy = options.hideCopy,
        hideBottom = options.hideBottom,
        mode = currentGizmoMode,
        space = currentGizmoSpace,
        spawnCoords = { x = lastGizmoData.x, y = lastGizmoData.y, z = lastGizmoData.z },
        spawnRot = { x = lastGizmoData.rotX, y = lastGizmoData.rotY, z = lastGizmoData.rotZ }
    })

    SetNuiFocus(true, true)

    -- 6. Main Camera & Input Loop Thread
    local invokingResource = GetInvokingResource()

    Citizen.CreateThread(function()
        while isGizmoOpen do
            Wait(0)

            -- Invoking resource crash / restart protection
            if invokingResource and GetResourceState(invokingResource) ~= 'started' then
                Lib47.Gizmo.Stop(true)
                break
            end

            local frameTime = GetFrameTime()
            local isShift = IsDisabledControlPressed(0, 21) or IsControlPressed(0, 21)
            local speedMultiplier = isShift and 0.2 or 1.0

            -- Keep player ped hidden and stationary
            SetEntityVisible(PlayerPedId(), false, false)

            -- RMB State Handling (Mouse Look / Cam Orbit)
            if isHoldingRMB then
                DisableControlAction(0, 25, true)  -- Disable RMB aim
                DisableControlAction(0, 177, true) -- Disable RMB cellphone cancel
                DisablePlayerFiring(PlayerId(), true)

                -- Check if user lets go of RMB
                if IsDisabledControlJustReleased(0, 25) then
                    isHoldingRMB = false
                    SetNuiFocus(true, true)
                    SetNuiFocusKeepInput(false)
                    SendNUIMessage({ action = "regainGizmoFocus" })
                end
            end

            -- LMB State Tracking
            if IsDisabledControlPressed(0, 24) or IsControlPressed(0, 24) then
                isHoldingLMB = true
            else
                isHoldingLMB = false
            end

            -- =============================================================
            -- FEATURE: HOLD LMB + RMB TO MOVE OBJECT WITH CAMERA VIEW
            -- =============================================================
            if isHoldingRMB and isHoldingLMB then
                if currentGizmoEntity and DoesEntityExist(currentGizmoEntity) then
                    HandleRaycastObjectMove(currentGizmoEntity, true)
                end
            end

            -- =============================================================
            -- KEYBOARD NUDGE / SHORTCUTS (When RMB is held or cursor is free)
            -- =============================================================
            if isHoldingRMB then
                -- Camera Pan with RMB + WASD / QE
                local plyPed = PlayerPedId()
                local camRot = GetGameplayCamRot(2)
                local fwd = RotationToDirection(camRot)
                local right = vector3(fwd.y, -fwd.x, 0.0)
                local up = vector3(0.0, 0.0, 1.0)
                local moveDelta = 6.0 * speedMultiplier * frameTime

                if IsDisabledControlPressed(0, 32) then -- W
                    SetEntityCoordsNoOffset(plyPed, GetEntityCoords(plyPed) + (fwd * moveDelta))
                elseif IsDisabledControlPressed(0, 33) then -- S
                    SetEntityCoordsNoOffset(plyPed, GetEntityCoords(plyPed) - (fwd * moveDelta))
                end

                if IsDisabledControlPressed(0, 35) then -- D (Right)
                    SetEntityCoordsNoOffset(plyPed, GetEntityCoords(plyPed) + (right * moveDelta))
                elseif IsDisabledControlPressed(0, 34) then -- A (Left)
                    SetEntityCoordsNoOffset(plyPed, GetEntityCoords(plyPed) - (right * moveDelta))
                end

                if IsDisabledControlPressed(0, 52) then -- Q (Up)
                    SetEntityCoordsNoOffset(plyPed, GetEntityCoords(plyPed) + (up * moveDelta))
                elseif IsDisabledControlPressed(0, 51) then -- E (Down)
                    SetEntityCoordsNoOffset(plyPed, GetEntityCoords(plyPed) - (up * moveDelta))
                end
            end

            -- =============================================================
            -- CONFIRM & CANCEL HOTKEYS
            -- =============================================================
            -- Confirm: ENTER (191) / NUMPAD ENTER (201)
            if IsDisabledControlJustPressed(0, 191) or IsControlJustPressed(0, 191) or IsDisabledControlJustPressed(0, 201) or IsControlJustPressed(0, 201) then
                Lib47.Gizmo.Stop(false)
                break
            end

            -- Cancel: DEL (178) / BACKSPACE (194) / ESC (200 / 322)
            -- NOTE: Do NOT check 177 here as 177 triggers on Mouse Right Click (RMB) in GTA V!
            if IsDisabledControlJustPressed(0, 178) or IsControlJustPressed(0, 178) or IsDisabledControlJustPressed(0, 194) or IsControlJustPressed(0, 194) or IsDisabledControlJustPressed(0, 200) or IsControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 322) or IsControlJustPressed(0, 322) then
                Lib47.Gizmo.Stop(true)
                break
            end

            -- =============================================================
            -- UPDATE REACT CAMERA & RENDER BOUNDING BOX
            -- =============================================================
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            local forward = RotationToDirection(camRot)
            lastCamCoords = camCoords

            SendNUIMessage({
                action = "updateGizmoCamera",
                camCoords = { x = camCoords.x, y = camCoords.y, z = camCoords.z },
                camRot = { x = camRot.x, y = camRot.y, z = camRot.z },
                camFov = GetGameplayCamFov(),
                camForward = { x = forward.x, y = forward.y, z = forward.z },
                camUp = { x = 0.0, y = 0.0, z = 1.0 }
            })

            if currentGizmoEntity and DoesEntityExist(currentGizmoEntity) then
                DrawEntityBoundingBox(currentGizmoEntity, 255, 0, 0, 200)
            end
        end

        -- Guarantee player ped visibility and physics are fully restored when loop ends
        local plyPed = PlayerPedId()
        SetEntityVisible(plyPed, true, 0)
        SetEntityCollision(plyPed, true, true)
        FreezeEntityPosition(plyPed, false)
        SetEntityInvincible(plyPed, false)
        ResetEntityAlpha(plyPed)
        SetLocalPlayerVisibleLocally(true)
    end)
end

--- Stop gizmo and resolve/finalize
--- @param isCancel boolean True if placement was cancelled
function Lib47.Gizmo.Stop(isCancel)
    if not isGizmoOpen then return end
    isGizmoOpen = false
    isGizmoFocused = false
    isHoldingRMB = false
    isHoldingLMB = false

    local finalCamCoords = lastCamCoords or GetGameplayCamCoord()

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    EnableAllControlActions(0)

    -- Restore player ped visibility, collision, invincibility, and position
    local plyPed = PlayerPedId()
    SetEntityVisible(plyPed, true, 0)
    SetEntityCollision(plyPed, true, true)
    FreezeEntityPosition(plyPed, false)
    SetEntityInvincible(plyPed, false)
    ResetEntityAlpha(plyPed)
    SetLocalPlayerVisibleLocally(true)
    if initialPedCoords then
        SetEntityCoordsNoOffset(plyPed, initialPedCoords.x, initialPedCoords.y, initialPedCoords.z)
        SetEntityHeading(plyPed, initialPedHeading or 0.0)
    end
    initialPedCoords = nil
    initialPedHeading = nil

    SendNUIMessage({ action = "toggleGizmo", show = false })
    Lib47.HideObjective()

    local finalCoords = nil
    local finalRot = nil

    if isCancel then
        -- Cancelled: Reset entity or delete dummy
        if currentGizmoEntity and DoesEntityExist(currentGizmoEntity) then
            if isSpawnedDummy then
                DeleteEntity(currentGizmoEntity)
                currentGizmoEntity = nil
            else
                -- Restore original position and rotation for existing entity
                if initialGizmoData then
                    SetEntityCoordsNoOffset(currentGizmoEntity, initialGizmoData.x, initialGizmoData.y, initialGizmoData.z)
                    SetEntityRotation(currentGizmoEntity, initialGizmoData.rotX, initialGizmoData.rotY, initialGizmoData.rotZ, 2, true)
                end
                SetEntityCollision(currentGizmoEntity, true, true)
                ResetEntityAlpha(currentGizmoEntity)
            end
        end
    else
        -- Confirmed
        if lastGizmoData then
            finalCoords = vector3(lastGizmoData.x, lastGizmoData.y, lastGizmoData.z)
            finalRot = vector3(lastGizmoData.rotX or 0.0, lastGizmoData.rotY or 0.0, lastGizmoData.rotZ or 0.0)
        end

        if currentGizmoEntity and DoesEntityExist(currentGizmoEntity) then
            if isSpawnedDummy then
                DeleteEntity(currentGizmoEntity)
                currentGizmoEntity = nil
            else
                SetEntityCoordsNoOffset(currentGizmoEntity, finalCoords.x, finalCoords.y, finalCoords.z)
                SetEntityRotation(currentGizmoEntity, finalRot.x, finalRot.y, finalRot.z, 2, true)
                SetEntityCollision(currentGizmoEntity, true, true)
                ResetEntityAlpha(currentGizmoEntity)
            end
        end
    end

    -- Callback execution
    if activeCallback then
        if isCancel then
            activeCallback({
                event = 'cancelled',
                coords = initialGizmoData and vector3(initialGizmoData.x, initialGizmoData.y, initialGizmoData.z) or nil,
                rot = initialGizmoData and vector3(initialGizmoData.rotX, initialGizmoData.rotY, initialGizmoData.rotZ) or nil,
                camCoords = finalCamCoords,
            })
        else
            activeCallback({
                event = 'closed',
                coords = finalCoords,
                rot = finalRot,
                camCoords = finalCamCoords,
            })
        end
        activeCallback = nil
    end

    -- Resolve promise if invoked as synchronous builder
    if gizmoResultPromise then
        if isCancel then
            gizmoResultPromise:resolve(nil)
        else
            gizmoResultPromise:resolve({ coords = finalCoords, rot = finalRot, camCoords = finalCamCoords })
        end
        gizmoResultPromise = nil
    end

    lastGizmoData = nil
    initialGizmoData = nil
    lastCamCoords = nil
end

-- =========================================================================
--                            NUI CALLBACKS
-- =========================================================================
RegisterNUICallback('gizmoUpdate', function(data, cb)
    lastGizmoData = {
        x = data.x, y = data.y, z = data.z,
        rotX = data.rotX, rotY = data.rotY, rotZ = data.rotZ
    }

    if currentGizmoEntity and DoesEntityExist(currentGizmoEntity) then
        SetEntityCoordsNoOffset(currentGizmoEntity, data.x, data.y, data.z)
        SetEntityRotation(currentGizmoEntity, data.rotX, data.rotY, data.rotZ, 2, true)
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
    SetNuiFocusKeepInput(true) -- Allow inputs to pass to game for smooth mouse look
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
    Lib47.Gizmo.Stop(true)
    cb('ok')
end)

RegisterNUICallback('gizmoSnapToGround', function(data, cb)
    if currentGizmoEntity and DoesEntityExist(currentGizmoEntity) then
        SnapObjectToGround(currentGizmoEntity)
    else
        local success, groundZ = GetGroundZFor_3dCoord(data.x, data.y, data.z + 100.0, false)
        if success then
            lastGizmoData.z = groundZ
            SendNUIMessage({
                action = "updateGizmoCoords",
                coords = { x = data.x, y = data.y, z = groundZ }
            })
        end
    end
    cb('ok')
end)

-- =========================================================================
--             UNIFIED OBJECT PLACEMENT API
-- =========================================================================

--- Place an object or modify an existing object's placement with full Gizmo & Controls
--- @param modelOrEntity string|number Model name, model hash, entity handle, or options table
--- @param optionsOrData table|function Optional options table or callback
--- @param locales table Optional localization table
--- @param validateFn function Optional validation function(coords, rot, camCoords)
--- @return vector3|nil coords Final position vector3 or nil if cancelled
--- @return vector3|nil rot Final rotation vector3 (rotX, rotY, rotZ) or nil if cancelled
--- @return vector3|nil camCoords Final camera coordinates vector3 or nil if cancelled
Lib47.Gizmo.PlaceObject = function(modelOrEntity, optionsOrData, locales, validateFn)
    local opts = {}

    -- Support callback as 2nd, 3rd, or 4th parameter
    local callback = nil
    if type(optionsOrData) == 'function' then
        callback = optionsOrData
        optionsOrData = {}
    elseif type(locales) == 'function' then
        callback = locales
        locales = nil
    elseif type(validateFn) == 'function' and not locales then
        -- validateFn is validate function
    end

    -- Process first parameter
    if type(modelOrEntity) == 'table' then
        for k, v in pairs(modelOrEntity) do
            opts[k] = v
        end
    elseif type(modelOrEntity) == 'string' or (type(modelOrEntity) == 'number' and not DoesEntityExist(modelOrEntity)) then
        opts.model = modelOrEntity
    elseif type(modelOrEntity) == 'number' and DoesEntityExist(modelOrEntity) then
        opts.entity = modelOrEntity
    end

    -- Merge optionsOrData if table
    if type(optionsOrData) == 'table' then
        for k, v in pairs(optionsOrData) do
            opts[k] = v
        end
    end

    opts.camCoords = opts.camCoords or opts.cam
    opts.locales = locales or opts.locales
    opts.isBuilder = true

    -- If called with a callback, start async
    if callback then
        Lib47.Gizmo.Start(opts, function(result)
            if result.event == 'closed' then
                callback(result.coords, result.rot, result.camCoords)
            elseif result.event == 'cancelled' then
                callback(nil, nil, nil)
            end
        end)
        return
    end

    gizmoResultPromise = promise.new()
    Lib47.Gizmo.Start(opts, nil)

    local result = Citizen.Await(gizmoResultPromise)
    if result and result.coords and result.rot then
        if validateFn and not validateFn(result.coords, result.rot, result.camCoords) then
            return nil, nil, nil
        end
        return result.coords, result.rot, result.camCoords
    end

    return nil, nil, nil
end

Lib47.Creation.Builders.PlaceObject = Lib47.Gizmo.PlaceObject

-- =========================================================================
--                               EXPORTS
-- =========================================================================
exports('PlaceObject', Lib47.Gizmo.PlaceObject)
exports('StartGizmo', Lib47.Gizmo.Start)
exports('StopGizmo', Lib47.Gizmo.Stop)

-- =========================================================================
--                          CLEANUP ON RESOURCE STOP
-- =========================================================================
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isGizmoOpen then
            Lib47.Gizmo.Stop(true)
        end
    end
end)
