Lib47.Creation = {
    Cam = {},
    Render = {},
    Builders = {},
}

local defaultLocales = {
    add_point = "Add Point",
    undo_last = "Undo Last",
    zone_height = "Zone Height",
    rotate_cam = "Rotate Cam",
    move = "Move",
    go_up_down = "Go Up/Down",
    next_step = "Next Step",
    cancel = "Cancel",
    zone_control = "Zone Control",
    cam_controls = "Camera Controls",
    navigation = "Navigation",
    zone_creation = "Zone Creation",
    error_poly_min = "A minimum of 3 points is required to create a polygon",
    set_point = "Set Point",
    rotate = "Rotate",
    precision = "Precision",
    move_up = "Move Up",
    move_down = "Move Down",
    go_back = "Go Back",
    placement = "Placement",
    setup_point = "Setup Point"
}

local function L(locales, key)
    if locales and locales[key] then return locales[key] end
    return defaultLocales[key] or key
end

-- =============================================================================
-- RENDER & GEOMETRY UTILS
-- =============================================================================
Lib47.Creation.Render.GetEntityBoundingBox = function(entity)
    local min, max = GetModelDimensions(GetEntityModel(entity))
    local pad = 0.001
    return {
        [1] = GetOffsetFromEntityInWorldCoords(entity, min.x - pad, min.y - pad, min.z - pad),
        [2] = GetOffsetFromEntityInWorldCoords(entity, max.x + pad, min.y - pad, min.z - pad),
        [3] = GetOffsetFromEntityInWorldCoords(entity, max.x + pad, max.y + pad, min.z - pad),
        [4] = GetOffsetFromEntityInWorldCoords(entity, min.x - pad, max.y + pad, min.z - pad),
        [5] = GetOffsetFromEntityInWorldCoords(entity, min.x - pad, min.y - pad, max.z + pad),
        [6] = GetOffsetFromEntityInWorldCoords(entity, max.x + pad, min.y - pad, max.z + pad),
        [7] = GetOffsetFromEntityInWorldCoords(entity, max.x + pad, max.y + pad, max.z + pad),
        [8] = GetOffsetFromEntityInWorldCoords(entity, min.x - pad, max.y + pad, max.z + pad),
    }
end

Lib47.Creation.Render.GetBoundingBoxPolyMatrix = function(box)
    return {
        [1] = {[1] = box[3], [2] = box[2], [3] = box[1]},
        [2] = {[1] = box[4], [2] = box[3], [3] = box[1]},
        [3] = {[1] = box[5], [2] = box[6], [3] = box[7]},
        [4] = {[1] = box[5], [2] = box[7], [3] = box[8]},
        [5] = {[1] = box[3], [2] = box[4], [3] = box[7]},
        [6] = {[1] = box[8], [2] = box[7], [3] = box[4]},
        [7] = {[1] = box[1], [2] = box[2], [3] = box[5]},
        [8] = {[1] = box[6], [2] = box[5], [3] = box[2]},
        [9] = {[1] = box[2], [2] = box[3], [3] = box[6]},
        [10] = {[1] = box[3], [2] = box[7], [3] = box[6]},
        [11] = {[1] = box[5], [2] = box[8], [3] = box[4]},
        [12] = {[1] = box[5], [2] = box[4], [3] = box[1]},
    }
end

Lib47.Creation.Render.GetBoundingBoxEdgeMatrix = function(box)
    return {
        [1] = {[1] = box[1], [2] = box[2]},
        [2] = {[1] = box[2], [2] = box[3]},
        [3] = {[1] = box[3], [2] = box[4]},
        [4] = {[1] = box[4], [2] = box[1]},
        [5] = {[1] = box[5], [2] = box[6]},
        [6] = {[1] = box[6], [2] = box[7]},
        [7] = {[1] = box[7], [2] = box[8]},
        [8] = {[1] = box[8], [2] = box[5]},
        [9] = {[1] = box[1], [2] = box[5]},
        [10] = {[1] = box[2], [2] = box[6]},
        [11] = {[1] = box[3], [2] = box[7]},
        [12] = {[1] = box[4], [2] = box[8]},
    }
end

Lib47.Creation.Render.DrawPolyMatrix = function(polyCollection, r, g, b, a)
    for k = 1, #polyCollection, 1 do
        local v = polyCollection[k]
        DrawPoly(v[1].x, v[1].y, v[1].z, v[2].x, v[2].y, v[2].z, v[3].x, v[3].y, v[3].z, r, g, b, a)
    end
end

Lib47.Creation.Render.DrawEdgeMatrix = function(linesCollection, r, g, b, a)
    for k = 1, #linesCollection, 1 do
        local v = linesCollection[k]
        DrawLine(v[1].x, v[1].y, v[1].z, v[2].x, v[2].y, v[2].z, r, g, b, a)
    end
end

Lib47.Creation.Render.DrawBoundingBox = function(box, r, g, b, a)
    local polyMatrix = Lib47.Creation.Render.GetBoundingBoxPolyMatrix(box)
    local edgeMatrix = Lib47.Creation.Render.GetBoundingBoxEdgeMatrix(box)
    Lib47.Creation.Render.DrawPolyMatrix(polyMatrix, r, g, b, a)
    Lib47.Creation.Render.DrawEdgeMatrix(edgeMatrix, 255, 255, 255, 255)
end

Lib47.Creation.Render.DrawEntityBoundingBox = function(entity, r, g, b, a)
    local box = Lib47.Creation.Render.GetEntityBoundingBox(entity)
    Lib47.Creation.Render.DrawBoundingBox(box, r, g, b, a)
end

-- =============================================================================
-- CAMERA & CONTROLS MODULE
-- =============================================================================
Lib47.Creation.Cam.Create = function(typeof, pos, rot, render, pointAt)
    local camera = CreateCamWithParams(typeof, pos.x, pos.y, pos.z, 0, 0, 0, 50 * 1.0)
    SetCamCoord(camera, pos.x, pos.y, pos.z)
    SetCamRot(camera, rot.x, rot.y, rot.z, 2)
    if render then
        SetCamActive(camera, true)
        RenderScriptCams(true, false, 0, true, false)
    end
    if pointAt then
        PointCamAtEntity(camera, pointAt)
    end
    return camera
end

Lib47.Creation.Cam.HandleFlyCam = function(cam, boundPos, boundDist, moveSpeed, climbSpeed, lookSpeedX, lookSpeedY)
    local camPos = GetCamCoord(cam)
    local camRot = GetCamRot(cam, 2)
    local frameTime = GetFrameTime()
    
    local camOpts = (Config and Config.Creation and Config.Creation.CameraOptions) or {}

    moveSpeed = moveSpeed or camOpts.moveSpeed or 10.0
    climbSpeed = climbSpeed or camOpts.climbSpeed or 10.0
    lookSpeedX = lookSpeedX or camOpts.lookSpeedX or 500.0
    lookSpeedY = lookSpeedY or camOpts.lookSpeedY or 500.0

    if IsDisabledControlPressed(0, 21) then
        moveSpeed = moveSpeed * 2.5
        climbSpeed = climbSpeed * 2.5
    end
    
    local mouseX = GetDisabledControlNormal(0, 1)
    local mouseY = GetDisabledControlNormal(0, 2)
    local _right, _fwd, _up, pos = GetCamMatrix(cam)
    local up = vector3(0.0, 0.0, 1.0)
    local right = norm(vector3(_right.x, _right.y, 0.0))
    local fwd = norm(vector3(_fwd.x, _fwd.y, 0.0))
    
    local didMove, didRot = false, false

    -- Q/E up/down
    if IsDisabledControlPressed(0, 52) then
        camPos = camPos + (up * (climbSpeed * frameTime))
        didMove = true
    elseif IsDisabledControlPressed(0, 51) then
        camPos = camPos - (up * (climbSpeed * frameTime))
        didMove = true
    end
    
    -- W/S fwd/back
    if IsDisabledControlPressed(0, 32) then
        camPos = camPos + (fwd * (moveSpeed * frameTime))
        didMove = true
    elseif IsDisabledControlPressed(0, 33) then
        camPos = camPos - (fwd * (moveSpeed * frameTime))
        didMove = true
    end
    
    -- A/D right/left
    if IsDisabledControlPressed(0, 35) then
        camPos = camPos + (right * (moveSpeed * frameTime))
        didMove = true
    elseif IsDisabledControlPressed(0, 34) then
        camPos = camPos - (right * (moveSpeed * frameTime))
        didMove = true
    end
    
    -- Mouse Look
    if mouseY ~= 0.0 then
        local x = math.max(-80.0, math.min(80.0, camRot.x - (mouseY * lookSpeedX * frameTime)))
        camRot = vector3(x, camRot.y, camRot.z)
        didRot = true
    end
    if mouseX ~= 0.0 then
        camRot = vector3(camRot.x, camRot.y, camRot.z - (mouseX * lookSpeedY * frameTime))
        didRot = true
    end
    
    if didMove then SetCamCoord(cam, camPos) end
    if didRot then SetCamRot(cam, camRot, 2) end
    
    if boundPos and boundDist then
        local dist = #(camPos - boundPos)
        if dist > boundDist then
            local boundDir = norm(camPos - boundPos)
            camPos = boundPos + (boundDir * boundDist)
            SetCamCoord(cam, camPos)
        end
    end
    return camPos, camRot
end

Lib47.Creation.Cam.Destroy = function(cam)
    SetCamActive(cam, false)
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(cam)
    SetFocusEntity(PlayerPedId())
end

-- =============================================================================
-- BUILDER MODULES
-- =============================================================================

Lib47.Creation.Builders.PolyPoints = function(existingData, locales, validateFn)
    local invokingResource = GetInvokingResource()
    local points = existingData and existingData.points or {}
    local plyPed = PlayerPedId()
    local fwd, right, up, plyPos = GetEntityMatrix(plyPed)
    local camPos = plyPos + (up * 2)
    local camRot = vector3(-35.0, 0.0, GetEntityHeading(plyPed))
    
    local polyZone
    if #points >= 3 and PolyZone then
        polyZone = PolyZone:Create(points, {
            name = "setup_poly_points",
            minZ = existingData.minZ,
            maxZ = existingData.maxZ,
            debugGrid = true,
            gridDivisions = 25
        })
    end

    local camera = Lib47.Creation.Cam.Create("DEFAULT_SCRIPTED_CAMERA", camPos, camRot, true)

    Lib47.ShowObjective({
        {
            Title = L(locales, 'zone_control'),
            List = {
                L(locales, 'add_point') .. " <m>1<m>",
                L(locales, 'undo_last') .. " <m>2<m>",
                L(locales, 'zone_height') .. " <m>3<m>",
            },
        },
        {
            Title = L(locales, 'cam_controls'),
            List = {
                L(locales, 'rotate_cam') .. " <m><m>",
                L(locales, 'move') .. " <k>W<k> <k>A<k> <k>S<k> <k>D<k>",
                L(locales, 'go_up_down') .. " <k>Q<k> <k>E<k>",
            },
        },
        {
            Title = L(locales, 'navigation'),
            List = {
                L(locales, 'next_step') .. " <k>ENTER<k>",
                L(locales, 'cancel') .. " <k>DEL<k>",
            },
        },
    }, L(locales, 'zone_creation'))
    
    while true do
        Wait(0)
        
        if invokingResource and GetResourceState(invokingResource) ~= 'started' then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            if polyZone then polyZone:destroy() end
            Lib47.HideObjective()
            return nil
        end

        -- Cancel (DEL)
        if IsDisabledControlJustPressed(0, 178) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            if polyZone then polyZone:destroy() end
            Lib47.HideObjective()
            return nil
        end

        -- Done/Next (ENTER)
        if IsDisabledControlJustPressed(0, 191) then
            if #points < 3 then
                Lib47.Notify(L(locales, 'error_poly_min'), "error")
            else
                EnableAllControlActions(0)
                Lib47.Creation.Cam.Destroy(camera)
                local finalMinZ = polyZone and polyZone.minZ or 0.0
                local finalMaxZ = polyZone and polyZone.maxZ or 10.0
                if polyZone then polyZone:destroy() end
                Lib47.HideObjective()
                local exportPoints = {}
                for i = 1, #points do
                    exportPoints[i] = {x = points[i].x, y = points[i].y}
                end
                return exportPoints, finalMinZ, finalMaxZ
            end
        end

        DisableAllControlActions(0)
        camPos, camRot = Lib47.Creation.Cam.HandleFlyCam(camera)
        local frameTime = GetFrameTime()
        local right, fwd, up, pos = GetCamMatrix(camera)
        local rayHit = StartExpensiveSynchronousShapeTestLosProbe(pos.x, pos.y, pos.z, pos.x + (fwd.x * 100.0), pos.y + (fwd.y * 100.0), pos.z + (fwd.z * 100.0), 1, PlayerPedId(), 4)
        local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHit)
        
        local isValid = true
        if endCoords and validateFn then
            isValid = validateFn(endCoords)
        end

        if polyZone then
            -- Height adjustment (Scroll Up/Down or Arrow Up/Down)
            -- Hold Shift (21) to adjust minZ (base height), default adjusts maxZ (top height)
            local isShift = IsDisabledControlPressed(0, 21)
            local step = 15.0 * frameTime

            local isUp = IsDisabledControlPressed(0, 181) or IsDisabledControlJustPressed(0, 181) or IsDisabledControlPressed(0, 241) or IsDisabledControlJustPressed(0, 241) or IsDisabledControlPressed(0, 172)
            local isDown = IsDisabledControlPressed(0, 180) or IsDisabledControlJustPressed(0, 180) or IsDisabledControlPressed(0, 242) or IsDisabledControlJustPressed(0, 242) or IsDisabledControlPressed(0, 173)

            if isUp then
                if isShift then
                    polyZone.minZ = polyZone.minZ + step
                else
                    polyZone.maxZ = polyZone.maxZ + step
                end
            elseif isDown then
                if isShift then
                    polyZone.minZ = polyZone.minZ - step
                else
                    polyZone.maxZ = polyZone.maxZ - step
                end
            end
        end

        -- Add Point (Mouse 1)
        if IsDisabledControlJustPressed(0, 24) then
            if isValid then
                local endPos = {x = endCoords.x, y = endCoords.y}
                table.insert(points, endPos)
                
                local currentMinZ = polyZone and polyZone.minZ or (endCoords.z - 2.0)
                local currentMaxZ = polyZone and polyZone.maxZ or (endCoords.z + 10.0)
                
                if polyZone then
                    if currentMinZ > (endCoords.z - 2.0) then
                        currentMinZ = endCoords.z - 2.0
                    end
                    polyZone:destroy()
                end
                
                if #points >= 3 and PolyZone then
                    polyZone = PolyZone:Create(points, {
                        name = "setup_poly_points",
                        minZ = currentMinZ,
                        maxZ = currentMaxZ,
                        debugGrid = true,
                        gridDivisions = 25
                    })
                else
                    polyZone = nil
                end
            else
                Lib47.Notify(L(locales, 'error_overlap_zone') or "Cannot place point inside an existing polyzone!", "error")
            end
        end

        -- Undo Point (Mouse 2 / Right Click)
        if IsDisabledControlJustPressed(0, 25) then
            if #points > 0 then
                table.remove(points, #points)
                
                local currentMinZ = polyZone and polyZone.minZ or 0.0
                local currentMaxZ = polyZone and polyZone.maxZ or 10.0
                
                if polyZone then polyZone:destroy() end
                if #points >= 3 and PolyZone then
                    polyZone = PolyZone:Create(points, {
                        name = "setup_poly_points",
                        minZ = currentMinZ,
                        maxZ = currentMaxZ,
                        debugGrid = true,
                        gridDivisions = 25
                    })
                else
                    polyZone = nil
                end
            end
        end
        
        local drawMinZ = polyZone and polyZone.minZ or (endCoords and (endCoords.z - 2.0) or 0.0)
        local drawMaxZ = polyZone and polyZone.maxZ or (endCoords and (endCoords.z + 10.0) or 10.0)

        for i = 1, #points do
            local p1 = points[i]
            local p2 = points[i + 1] or (i == #points and #points >= 3 and points[1]) or nil

            DrawLine(p1.x, p1.y, drawMinZ, p1.x, p1.y, drawMaxZ, 0, 255, 0, 255)
            DrawMarker(28, p1.x, p1.y, drawMinZ, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 255, 0, 200, false, false, 0, false, false, false, false)
            DrawMarker(28, p1.x, p1.y, drawMaxZ, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 255, 0, 200, false, false, 0, false, false, false, false)

            if p2 then
                DrawLine(p1.x, p1.y, drawMinZ, p2.x, p2.y, drawMinZ, 0, 255, 0, 255)
                DrawLine(p1.x, p1.y, drawMaxZ, p2.x, p2.y, drawMaxZ, 0, 255, 0, 255)
            end
        end

        if #points > 0 and endCoords then
            local lastP = points[#points]
            DrawLine(lastP.x, lastP.y, drawMinZ, endCoords.x, endCoords.y, drawMinZ, 255, 255, 0, 200)
            DrawLine(lastP.x, lastP.y, drawMaxZ, endCoords.x, endCoords.y, drawMaxZ, 255, 255, 0, 200)
        end

        if endCoords then
            local r, g = 0, 255
            if not isValid then
                r, g = 255, 0
            end
            DrawLine(endCoords.x, endCoords.y, endCoords.z, endCoords.x, endCoords.y, endCoords.z + 10.0, r, g, 0, 255)
            DrawMarker(28, endCoords.x, endCoords.y, endCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, r, g, 0, 200, false, false, 0, false, false, false, false)
        end
    end
end

Lib47.Creation.Builders.PlaceModel = function(model, existingData, locales, isWater, validateFn)
    local invokingResource = GetInvokingResource()
    local hash = type(model) == 'string' and GetHashKey(model) or model
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    
    local point = nil
    local entityHeading = 0.0

    if existingData and existingData.x then
        point = vector3(existingData.x, existingData.y, existingData.z)
        entityHeading = existingData.w or 0.0
    end

    local pedPos = point or GetEntityCoords(PlayerPedId())
    local entity
    if IsThisModelAVehicle(hash) then
        entity = CreateVehicle(hash, pedPos.x, pedPos.y, pedPos.z, entityHeading, false)
    else
        entity = CreateObject(hash, pedPos.x, pedPos.y, pedPos.z, false, false, false)
    end
    
    if not point then 
        SetEntityCoords(entity, pedPos.x, pedPos.y, pedPos.z - 10.0) 
    end

    SetEntityCollision(entity, false, false)
    SetEntityAlpha(entity, 200)

    local fwd, right, up, plyPos = GetEntityMatrix(PlayerPedId())
    local camPos = plyPos + (up * 2)
    local camRot = vector3(-35.0, 0.0, GetEntityHeading(PlayerPedId()))
    local camera = Lib47.Creation.Cam.Create("DEFAULT_SCRIPTED_CAMERA", camPos, camRot, true)

    Lib47.ShowObjective({
        {
            Title = L(locales, 'placement'),
            List = {
                L(locales, 'set_point') .. " <m>1<m>",
                L(locales, 'rotate') .. " <m>3<m>",
                L(locales, 'precision') .. " <k>SHIFT<k>",
            },
        },
        {
            Title = L(locales, 'cam_controls'),
            List = {
                "<m><m> <k>W<k> <k>A<k> <k>S<k> <k>D<k>",
                L(locales, 'move_up') .. " <k>Q<k>",
                L(locales, 'move_down') .. " <k>E<k>",
            },
        },
        {
            Title = L(locales, 'navigation'),
            List = {
                L(locales, 'cancel') .. " <k>DEL<k>",
            }
        },
    }, L(locales, 'setup_point'))

    while true do
        Wait(0)
        
        if invokingResource and GetResourceState(invokingResource) ~= 'started' then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            DeleteEntity(entity)
            Lib47.HideObjective()
            return nil
        end

        -- Cancel
        if IsDisabledControlJustPressed(0, 178) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            DeleteEntity(entity)
            Lib47.HideObjective()
            return nil
        end

        -- Done/Place
        if IsDisabledControlJustPressed(0, 24) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            DeleteEntity(entity)
            Lib47.HideObjective()
            return point and vector4(point.x, point.y, point.z, entityHeading) or nil
        end

        -- Rotate (Scroll)
        if IsDisabledControlJustPressed(0, 181) then
            if IsDisabledControlPressed(0, 21) then
                entityHeading = entityHeading + 2.0 
            else
                entityHeading = entityHeading + 10.0 
            end
        end
        if IsDisabledControlJustPressed(0, 180) then
            if IsDisabledControlPressed(0, 21) then
                entityHeading = entityHeading - 2.0 
            else
                entityHeading = entityHeading - 10.0 
            end
        end

        DisableAllControlActions(0)
        camPos, camRot = Lib47.Creation.Cam.HandleFlyCam(camera)
        local right, fwd, up, pos = GetCamMatrix(camera)
        
        local endCoords
        if isWater then
            local bool, wCoords = TestProbeAgainstAllWater(pos.x, pos.y, pos.z, pos.x + (fwd.x * 100.0), pos.y + (fwd.y * 100.0), pos.z + (fwd.z * 100.0), 128)
            if bool then
                endCoords = wCoords
            end
        else
            local rayHit = StartExpensiveSynchronousShapeTestLosProbe(pos.x, pos.y, pos.z, pos.x + (fwd.x * 100.0), pos.y + (fwd.y * 100.0), pos.z + (fwd.z * 100.0), 1, PlayerPedId(), 4)
            local retval, hit, hitCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHit)
            if hit ~= 0 then
                endCoords = hitCoords
            end
        end
        
        if endCoords then
            -- Depending on if it's a vehicle or not, adjust height
            local zOffset = 0.0
            if IsThisModelAVehicle(hash) then
                -- Get vehicle boundings
                local min, max = GetModelDimensions(hash)
                zOffset = math.abs(min.z)
            end
            
            point = vector3(endCoords.x, endCoords.y, endCoords.z + zOffset)
            
            local r, g = 0, 255
            if validateFn and not validateFn(point) then
                r, g = 255, 0
            end
            
            DrawLine(endCoords.x, endCoords.y, endCoords.z, endCoords.x, endCoords.y, endCoords.z + 2.0, r, g, 0, 255)
            SetEntityCoordsNoOffset(entity, point.x, point.y, point.z)
            SetEntityHeading(entity, entityHeading)
        end
    end
end

Lib47.Creation.Builders.PlacePed = function(model, existingData, locales, validateFn)
    local invokingResource = GetInvokingResource()
    local hash = type(model) == 'string' and GetHashKey(model) or model
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    
    local point = nil
    local entityHeading = 0.0

    if existingData and existingData.x then
        point = vector3(existingData.x, existingData.y, existingData.z)
        entityHeading = existingData.w or 0.0
    end

    local pedPos = point or GetEntityCoords(PlayerPedId())
    local entity = CreatePed(4, hash, pedPos.x, pedPos.y, pedPos.z, entityHeading, false, false)
    if not point then 
        SetEntityCoords(entity, pedPos.x, pedPos.y, pedPos.z - 10.0) 
    end

    SetEntityCollision(entity, false, false)
    SetEntityAlpha(entity, 200)
    FreezeEntityPosition(entity, true)

    local fwd, right, up, plyPos = GetEntityMatrix(PlayerPedId())
    local camPos = plyPos + (up * 2)
    local camRot = vector3(-35.0, 0.0, GetEntityHeading(PlayerPedId()))
    local camera = Lib47.Creation.Cam.Create("DEFAULT_SCRIPTED_CAMERA", camPos, camRot, true)

    Lib47.ShowObjective({
        {
            Title = L(locales, 'placement'),
            List = {
                L(locales, 'set_point') .. " <m>1<m>",
                L(locales, 'rotate') .. " <m>3<m>",
                L(locales, 'precision') .. " <k>SHIFT<k>",
            },
        },
        {
            Title = L(locales, 'cam_controls'),
            List = {
                "<m><m> <k>W<k> <k>A<k> <k>S<k> <k>D<k>",
                L(locales, 'move_up') .. " <k>Q<k>",
                L(locales, 'move_down') .. " <k>E<k>",
            },
        },
        {
            Title = L(locales, 'navigation'),
            List = {
                L(locales, 'cancel') .. " <k>DEL<k>",
            }
        },
    }, L(locales, 'setup_point'))

    while true do
        Wait(0)
        
        if invokingResource and GetResourceState(invokingResource) ~= 'started' then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            DeleteEntity(entity)
            Lib47.HideObjective()
            return nil
        end

        -- Cancel
        if IsDisabledControlJustPressed(0, 178) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            DeleteEntity(entity)
            Lib47.HideObjective()
            return nil
        end

        -- Done/Place
        if IsDisabledControlJustPressed(0, 24) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            DeleteEntity(entity)
            Lib47.HideObjective()
            return point and vector4(point.x, point.y, point.z, entityHeading) or nil
        end

        -- Rotate (Scroll)
        if IsDisabledControlJustPressed(0, 181) then
            if IsDisabledControlPressed(0, 21) then
                entityHeading = entityHeading + 2.0 
            else
                entityHeading = entityHeading + 10.0 
            end
        end
        if IsDisabledControlJustPressed(0, 180) then
            if IsDisabledControlPressed(0, 21) then
                entityHeading = entityHeading - 2.0 
            else
                entityHeading = entityHeading - 10.0 
            end
        end

        DisableAllControlActions(0)
        camPos, camRot = Lib47.Creation.Cam.HandleFlyCam(camera)
        local right, fwd, up, pos = GetCamMatrix(camera)
        
        local rayHit = StartExpensiveSynchronousShapeTestLosProbe(pos.x, pos.y, pos.z, pos.x + (fwd.x * 100.0), pos.y + (fwd.y * 100.0), pos.z + (fwd.z * 100.0), 1, PlayerPedId(), 4)
        local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHit)
        
        if hit ~= 0 then
            -- Default ped Z offset is +1.0 for placement typically, or ground z
            point = vector3(endCoords.x, endCoords.y, endCoords.z + 1.0)
            
            local r, g = 0, 255
            if validateFn and not validateFn(point) then
                r, g = 255, 0
            end
            
            DrawLine(endCoords.x, endCoords.y, endCoords.z, endCoords.x, endCoords.y, endCoords.z + 2.0, r, g, 0, 255)
            SetEntityCoordsNoOffset(entity, point.x, point.y, point.z)
            SetEntityHeading(entity, entityHeading)
        end
    end
end