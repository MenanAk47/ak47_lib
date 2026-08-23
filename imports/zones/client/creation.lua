Lib47.Creation = Lib47.Creation or {}
Lib47.Creation.Cam = Lib47.Creation.Cam or {}
Lib47.Creation.Render = Lib47.Creation.Render or {}
Lib47.Creation.Builders = Lib47.Creation.Builders or {}

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
    setup_point = "Setup Point",
    box_controls = "Box Controls",
    box_creation = "Box Zone Creation",
    circle_controls = "Circle Controls",
    circle_creation = "Circle Zone Creation",
    adjust_length = "Length +/-",
    adjust_width = "Width +/-",
    adjust_radius = "Radius +/-",
    change_prop = "Change Prop",
    adjust_heading = "Rotate +/-",
    adjust_center_z = "Center Height +/-",
    adjust_height = "Total Height +/-",
    micro_adjust = "Move Box",
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

Lib47.Creation.Builders.PolyZone = function(existingData, locales, validateFn)
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
    local model = model or GetEntityModel(PlayerPedId())
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
            return point and vector3(point.x, point.y, point.z), entityHeading
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

Lib47.Creation.Builders.BoxZone = function(existingData, locales, validateFn)
    local invokingResource = GetInvokingResource()
    local plyPed = PlayerPedId()
    local fwd, right, up, plyPos = GetEntityMatrix(plyPed)
    local camPos = plyPos + (up * 2)
    local camRot = vector3(-35.0, 0.0, GetEntityHeading(plyPed))

    local camera = Lib47.Creation.Cam.Create("DEFAULT_SCRIPTED_CAMERA", camPos, camRot, true)

    local boxPos = nil
    local length = 2.0
    local width = 2.0
    local boxHeading = 0.0
    local minZ = nil
    local maxZ = nil

    if existingData and (existingData.boxPos or existingData.coords or existingData.x) then
        local rawPos = existingData.boxPos or existingData.coords or existingData
        boxPos = vector3(rawPos.x, rawPos.y, rawPos.z)
        length = existingData.length or (existingData.size and existingData.size.y) or 2.0
        width = existingData.width or (existingData.size and existingData.size.x) or 2.0
        boxHeading = existingData.boxHeading or existingData.heading or existingData.rotation or 0.0
        minZ = existingData.minZ or (boxPos.z - 1.0)
        maxZ = existingData.maxZ or (boxPos.z + 1.0)
    end

    local step = boxPos and 2 or 1

    if step == 1 then
        Lib47.ShowObjective({
            {
                Title = L(locales, 'placement'),
                List = {
                    L(locales, 'set_point') .. " <m>1<m>",
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
                },
            },
        }, L(locales, 'box_creation'))
    else
        Lib47.ShowObjective({
            {
                Title = L(locales, 'box_controls'),
                List = {
                    L(locales, 'adjust_length') .. " <k>↑<k> <k>↓<k>",
                    L(locales, 'adjust_width') .. " <k>←<k> <k>→<k>",
                    L(locales, 'adjust_heading') .. " <m>3<m>",
                    L(locales, 'adjust_center_z') .. " <k>SHIFT<k> + <m>3<m>",
                    L(locales, 'adjust_height') .. " <k>PGUP<k> <k>PGDN<k>",
                    L(locales, 'micro_adjust') .. " <k>SHIFT<k> + <k>↑<k><k>↓<k><k>←<k><k>→<k>",
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
                    L(locales, 'next_step') .. " <k>ENTER<k>",
                    L(locales, 'cancel') .. " <k>DEL<k>",
                },
            },
        }, L(locales, 'box_creation'))
    end

    while true do
        Wait(0)

        if invokingResource and GetResourceState(invokingResource) ~= 'started' then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            Lib47.HideObjective()
            return nil
        end

        -- Cancel (DEL)
        if IsDisabledControlJustPressed(0, 178) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            Lib47.HideObjective()
            return nil
        end

        DisableAllControlActions(0)
        camPos, camRot = Lib47.Creation.Cam.HandleFlyCam(camera)
        local frameTime = GetFrameTime()
        local isShift = IsDisabledControlPressed(0, 21)

        if step == 1 then
            local right, fwd, up, pos = GetCamMatrix(camera)
            local rayHit = StartExpensiveSynchronousShapeTestLosProbe(pos.x, pos.y, pos.z, pos.x + (fwd.x * 100.0), pos.y + (fwd.y * 100.0), pos.z + (fwd.z * 100.0), 1, PlayerPedId(), 4)
            local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHit)

            if hit ~= 0 then
                local r, g = 0, 255
                if validateFn and not validateFn(endCoords) then
                    r, g = 255, 0
                end
                DrawLine(endCoords.x, endCoords.y, endCoords.z, endCoords.x, endCoords.y, endCoords.z + 1.5, r, g, 0, 255)
                DrawMarker(28, endCoords.x, endCoords.y, endCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.4, 0.4, 0.4, r, g, 0, 200, false, false, 0, false, false, false, false)

                if IsDisabledControlJustPressed(0, 24) or IsDisabledControlJustPressed(0, 191) then
                    if not validateFn or validateFn(endCoords) then
                        boxPos = vector3(endCoords.x, endCoords.y, endCoords.z)
                        minZ = boxPos.z - 0.5
                        maxZ = boxPos.z + 1.5
                        step = 2

                        Lib47.ShowObjective({
                            {
                                Title = L(locales, 'box_controls'),
                                List = {
                                    L(locales, 'adjust_length') .. " <k>↑<k> <k>↓<k>",
                                    L(locales, 'adjust_width') .. " <k>←<k> <k>→<k>",
                                    L(locales, 'adjust_heading') .. " <m>3<m>",
                                    L(locales, 'adjust_center_z') .. " <k>SHIFT<k> + <m>3<m>",
                                    L(locales, 'adjust_height') .. " <k>PGUP<k> <k>PGDN<k>",
                                    L(locales, 'micro_adjust') .. " <k>SHIFT<k> + <k>↑<k><k>↓<k><k>←<k><k>→<k>",
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
                                    L(locales, 'next_step') .. " <k>ENTER<k>",
                                    L(locales, 'cancel') .. " <k>DEL<k>",
                                },
                            },
                        }, L(locales, 'box_creation'))
                    end
                end
            end
        else
            -- Done (ENTER)
            if IsDisabledControlJustPressed(0, 191) then
                EnableAllControlActions(0)
                Lib47.Creation.Cam.Destroy(camera)
                Lib47.HideObjective()
                return boxPos, length, width, boxHeading, minZ, maxZ
            end

            local rad = math.rad(boxHeading)
            local fwdX = -math.sin(rad)
            local fwdY = math.cos(rad)
            local rgtX = fwdY
            local rgtY = -fwdX

            -- Length adjustment or forward/back nudge
            if IsDisabledControlJustPressed(0, 172) then -- Arrow Up
                if isShift then
                    boxPos = vector3(boxPos.x + fwdX * 0.1, boxPos.y + fwdY * 0.1, boxPos.z)
                else
                    length = math.min(100.0, length + 0.2)
                end
            elseif IsDisabledControlJustPressed(0, 173) then -- Arrow Down
                if isShift then
                    boxPos = vector3(boxPos.x - fwdX * 0.1, boxPos.y - fwdY * 0.1, boxPos.z)
                else
                    length = math.max(0.2, length - 0.2)
                end
            end

            -- Width adjustment or left/right nudge
            if IsDisabledControlJustPressed(0, 175) then -- Arrow Right
                if isShift then
                    boxPos = vector3(boxPos.x + rgtX * 0.1, boxPos.y + rgtY * 0.1, boxPos.z)
                else
                    width = math.min(100.0, width + 0.2)
                end
            elseif IsDisabledControlJustPressed(0, 174) then -- Arrow Left
                if isShift then
                    boxPos = vector3(boxPos.x - rgtX * 0.1, boxPos.y - rgtY * 0.1, boxPos.z)
                else
                    width = math.max(0.2, width - 0.2)
                end
            end

            -- Rotation (Scroll Up/Down) or Zone Center Height (Shift + Scroll Up/Down)
            local isScrollUp = IsDisabledControlJustPressed(0, 181) or IsDisabledControlJustPressed(0, 241)
            local isScrollDown = IsDisabledControlJustPressed(0, 180) or IsDisabledControlJustPressed(0, 242)

            if isScrollUp then
                if isShift then
                    local zDelta = 0.1
                    boxPos = vector3(boxPos.x, boxPos.y, boxPos.z + zDelta)
                    minZ = (minZ or (boxPos.z - 0.5)) + zDelta
                    maxZ = (maxZ or (boxPos.z + 1.5)) + zDelta
                else
                    boxHeading = (boxHeading + 5.0) % 360.0
                end
            elseif isScrollDown then
                if isShift then
                    local zDelta = 0.1
                    boxPos = vector3(boxPos.x, boxPos.y, boxPos.z - zDelta)
                    minZ = (minZ or (boxPos.z - 0.5)) - zDelta
                    maxZ = (maxZ or (boxPos.z + 1.5)) - zDelta
                else
                    boxHeading = (boxHeading - 5.0) % 360.0
                end
            end

            -- Zone Total Height Adjustment from Top & Bottom symmetrically (PageUp / PageDown)
            local isPageUp = IsDisabledControlJustPressed(0, 10) or IsDisabledControlJustPressed(0, 208)
            local isPageDown = IsDisabledControlJustPressed(0, 11) or IsDisabledControlJustPressed(0, 207)

            if isPageUp then
                local hDelta = isShift and 0.05 or 0.1
                minZ = (minZ or (boxPos.z - 0.5)) - hDelta
                maxZ = (maxZ or (boxPos.z + 1.5)) + hDelta
            elseif isPageDown then
                local hDelta = isShift and 0.05 or 0.1
                local curMin = minZ or (boxPos.z - 0.5)
                local curMax = maxZ or (boxPos.z + 1.5)
                if (curMax - curMin) > (hDelta * 2 + 0.1) then
                    minZ = curMin + hDelta
                    maxZ = curMax - hDelta
                end
            end

            -- Q/E continuous center height nudge if shift held
            if isShift then
                if IsDisabledControlPressed(0, 52) then -- Q
                    local delta = 2.0 * frameTime
                    boxPos = vector3(boxPos.x, boxPos.y, boxPos.z + delta)
                    minZ = (minZ or (boxPos.z - 0.5)) + delta
                    maxZ = (maxZ or (boxPos.z + 1.5)) + delta
                elseif IsDisabledControlPressed(0, 51) then -- E
                    local delta = 2.0 * frameTime
                    boxPos = vector3(boxPos.x, boxPos.y, boxPos.z - delta)
                    minZ = (minZ or (boxPos.z - 0.5)) - delta
                    maxZ = (maxZ or (boxPos.z + 1.5)) - delta
                end
            end

            -- Calculate 4 bottom & top corners
            local halfL = length / 2
            local halfW = width / 2
            local cosH = math.cos(rad)
            local sinH = math.sin(rad)

            local function getCorner(ox, oy, z)
                local rx = (ox * cosH) - (oy * sinH)
                local ry = (ox * sinH) + (oy * cosH)
                return vector3(boxPos.x + rx, boxPos.y + ry, z)
            end

            local drawMinZ = minZ or (boxPos.z - 0.5)
            local drawMaxZ = maxZ or (boxPos.z + 1.5)

            local b1 = getCorner(-halfW, -halfL, drawMinZ)
            local b2 = getCorner(halfW, -halfL, drawMinZ)
            local b3 = getCorner(halfW, halfL, drawMinZ)
            local b4 = getCorner(-halfW, halfL, drawMinZ)

            local t1 = getCorner(-halfW, -halfL, drawMaxZ)
            local t2 = getCorner(halfW, -halfL, drawMaxZ)
            local t3 = getCorner(halfW, halfL, drawMaxZ)
            local t4 = getCorner(-halfW, halfL, drawMaxZ)

            local r, g, b, a = 0, 255, 0, 100
            if validateFn and not validateFn(boxPos) then
                r, g, b = 255, 0, 0
            end

            -- Bottom frame
            DrawLine(b1.x, b1.y, b1.z, b2.x, b2.y, b2.z, r, g, b, 255)
            DrawLine(b2.x, b2.y, b2.z, b3.x, b3.y, b3.z, r, g, b, 255)
            DrawLine(b3.x, b3.y, b3.z, b4.x, b4.y, b4.z, r, g, b, 255)
            DrawLine(b4.x, b4.y, b4.z, b1.x, b1.y, b1.z, r, g, b, 255)

            -- Top frame
            DrawLine(t1.x, t1.y, t1.z, t2.x, t2.y, t2.z, r, g, b, 255)
            DrawLine(t2.x, t2.y, t2.z, t3.x, t3.y, t3.z, r, g, b, 255)
            DrawLine(t3.x, t3.y, t3.z, t4.x, t4.y, t4.z, r, g, b, 255)
            DrawLine(t4.x, t4.y, t4.z, t1.x, t1.y, t1.z, r, g, b, 255)

            -- Vertical corners
            DrawLine(b1.x, b1.y, b1.z, t1.x, t1.y, t1.z, r, g, b, 255)
            DrawLine(b2.x, b2.y, b2.z, t2.x, t2.y, t2.z, r, g, b, 255)
            DrawLine(b3.x, b3.y, b3.z, t3.x, t3.y, t3.z, r, g, b, 255)
            DrawLine(b4.x, b4.y, b4.z, t4.x, t4.y, t4.z, r, g, b, 255)

            -- 4 Side Poly Faces (2-sided)
            DrawPoly(b1.x, b1.y, b1.z, t1.x, t1.y, t1.z, t2.x, t2.y, t2.z, r, g, b, a)
            DrawPoly(b1.x, b1.y, b1.z, t2.x, t2.y, t2.z, b2.x, b2.y, b2.z, r, g, b, a)
            DrawPoly(t2.x, t2.y, t2.z, t1.x, t1.y, t1.z, b1.x, b1.y, b1.z, r, g, b, a)
            DrawPoly(b2.x, b2.y, b2.z, t2.x, t2.y, t2.z, b1.x, b1.y, b1.z, r, g, b, a)

            DrawPoly(b2.x, b2.y, b2.z, t2.x, t2.y, t2.z, t3.x, t3.y, t3.z, r, g, b, a)
            DrawPoly(b2.x, b2.y, b2.z, t3.x, t3.y, t3.z, b3.x, b3.y, b3.z, r, g, b, a)
            DrawPoly(t3.x, t3.y, t3.z, t2.x, t2.y, t2.z, b2.x, b2.y, b2.z, r, g, b, a)
            DrawPoly(b3.x, b3.y, b3.z, t3.x, t3.y, t3.z, b2.x, b2.y, b2.z, r, g, b, a)

            DrawPoly(b3.x, b3.y, b3.z, t3.x, t3.y, t3.z, t4.x, t4.y, t4.z, r, g, b, a)
            DrawPoly(b3.x, b3.y, b3.z, t4.x, t4.y, t4.z, b4.x, b4.y, b4.z, r, g, b, a)
            DrawPoly(t4.x, t4.y, t4.z, t3.x, t3.y, t3.z, b3.x, b3.y, b3.z, r, g, b, a)
            DrawPoly(b4.x, b4.y, b4.z, t4.x, t4.y, t4.z, b3.x, b3.y, b3.z, r, g, b, a)

            DrawPoly(b4.x, b4.y, b4.z, t4.x, t4.y, t4.z, t1.x, t1.y, t1.z, r, g, b, a)
            DrawPoly(b4.x, b4.y, b4.z, t1.x, t1.y, t1.z, b1.x, b1.y, b1.z, r, g, b, a)
            DrawPoly(t1.x, t1.y, t1.z, t4.x, t4.y, t4.z, b4.x, b4.y, b4.z, r, g, b, a)
            DrawPoly(b1.x, b1.y, b1.z, t1.x, t1.y, t1.z, b4.x, b4.y, b4.z, r, g, b, a)

            -- Top & Bottom Cap Faces
            local topA = math.floor(a * 0.7)
            DrawPoly(t1.x, t1.y, t1.z, t2.x, t2.y, t2.z, t3.x, t3.y, t3.z, r, g, b, topA)
            DrawPoly(t1.x, t1.y, t1.z, t3.x, t3.y, t3.z, t4.x, t4.y, t4.z, r, g, b, topA)
            DrawPoly(t3.x, t3.y, t3.z, t2.x, t2.y, t2.z, t1.x, t1.y, t1.z, r, g, b, topA)
            DrawPoly(t4.x, t4.y, t4.z, t3.x, t3.y, t3.z, t1.x, t1.y, t1.z, r, g, b, topA)

            DrawPoly(b1.x, b1.y, b1.z, b3.x, b3.y, b3.z, b2.x, b2.y, b2.z, r, g, b, topA)
            DrawPoly(b1.x, b1.y, b1.z, b4.x, b4.y, b4.z, b3.x, b3.y, b3.z, r, g, b, topA)

            -- Orientation axes (Forward = Red, Right = Green, Up = Blue)
            DrawLine(boxPos.x, boxPos.y, boxPos.z, boxPos.x + (fwdX * (halfL + 0.5)), boxPos.y + (fwdY * (halfL + 0.5)), boxPos.z, 255, 0, 0, 255)
            DrawLine(boxPos.x, boxPos.y, boxPos.z, boxPos.x + (rgtX * (halfW + 0.5)), boxPos.y + (rgtY * (halfW + 0.5)), boxPos.z, 0, 255, 0, 255)
            DrawLine(boxPos.x, boxPos.y, boxPos.z, boxPos.x, boxPos.y, boxPos.z + 1.0, 0, 0, 255, 255)
        end
    end
end

Lib47.Creation.Builders.CircleZone = function(existingData, locales, validateFn, propList)
    local invokingResource = GetInvokingResource()
    local plyPed = PlayerPedId()
    local fwd, right, up, plyPos = GetEntityMatrix(plyPed)
    local camPos = plyPos + (up * 2)
    local camRot = vector3(-35.0, 0.0, GetEntityHeading(plyPed))

    local camera = Lib47.Creation.Cam.Create("DEFAULT_SCRIPTED_CAMERA", camPos, camRot, true)

    local point = nil
    local radius = 15.0
    local propId = 1
    local propEntity = nil

    if existingData and (existingData.position or existingData.coords or existingData.x) then
        local rawPos = existingData.position or existingData.coords or existingData
        point = vector3(rawPos.x, rawPos.y, rawPos.z)
        radius = existingData.radius or 15.0
        if existingData.prop and propList then
            for i, p in ipairs(propList) do
                if p == existingData.prop then
                    propId = i
                    break
                end
            end
        end
    end

    local step = point and 2 or 1

    local function spawnPreviewProp(hash, coords)
        if propEntity and DoesEntityExist(propEntity) then
            DeleteObject(propEntity)
            propEntity = nil
        end
        if hash then
            Lib47.RequestModel(hash)
            propEntity = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
            SetEntityCollision(propEntity, false, false)
            SetEntityAlpha(propEntity, 200)
            FreezeEntityPosition(propEntity, true)
        end
    end

    local function getObjectiveControls()
        if step == 1 then
            local list = {
                L(locales, 'set_point') .. " <m>1<m>",
            }
            if propList and #propList > 1 then
                table.insert(list, L(locales, 'change_prop') .. " <m>3<m>")
            end
            return {
                {
                    Title = L(locales, 'placement'),
                    List = list,
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
                    },
                },
            }
        else
            return {
                {
                    Title = L(locales, 'circle_controls'),
                    List = {
                        L(locales, 'adjust_radius') .. " <m>3<m> / <k>↑<k> <k>↓<k>",
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
                        L(locales, 'next_step') .. " <k>ENTER<k>",
                        L(locales, 'cancel') .. " <k>DEL<k>",
                    },
                },
            }
        end
    end

    Lib47.ShowObjective(getObjectiveControls(), L(locales, 'circle_creation'))

    while true do
        Wait(0)

        if invokingResource and GetResourceState(invokingResource) ~= 'started' then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            if propEntity and DoesEntityExist(propEntity) then DeleteObject(propEntity) end
            Lib47.HideObjective()
            return nil
        end

        -- Cancel (DEL)
        if IsDisabledControlJustPressed(0, 178) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            if propEntity and DoesEntityExist(propEntity) then DeleteObject(propEntity) end
            Lib47.HideObjective()
            return nil
        end

        DisableAllControlActions(0)
        camPos, camRot = Lib47.Creation.Cam.HandleFlyCam(camera)
        local isShift = IsDisabledControlPressed(0, 21)

        if step == 1 then
            local right, fwd, up, pos = GetCamMatrix(camera)
            local rayHit = StartExpensiveSynchronousShapeTestLosProbe(pos.x, pos.y, pos.z, pos.x + (fwd.x * 100.0), pos.y + (fwd.y * 100.0), pos.z + (fwd.z * 100.0), 1, PlayerPedId(), 4)
            local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHit)

            if hit ~= 0 then
                local r, g = 0, 255
                if validateFn and not validateFn(endCoords) then
                    r, g = 255, 0
                end

                if propList and #propList > 0 then
                    local hash = GetHashKey(propList[propId])
                    if not propEntity or not DoesEntityExist(propEntity) then
                        spawnPreviewProp(hash, endCoords)
                    else
                        SetEntityCoordsNoOffset(propEntity, endCoords.x, endCoords.y, endCoords.z)
                    end

                    -- Change prop
                    if IsDisabledControlJustPressed(0, 181) or IsDisabledControlJustPressed(0, 241) or IsDisabledControlJustPressed(0, 175) then
                        propId = (propId >= #propList) and 1 or (propId + 1)
                        spawnPreviewProp(GetHashKey(propList[propId]), endCoords)
                    elseif IsDisabledControlJustPressed(0, 180) or IsDisabledControlJustPressed(0, 242) or IsDisabledControlJustPressed(0, 174) then
                        propId = (propId <= 1) and #propList or (propId - 1)
                        spawnPreviewProp(GetHashKey(propList[propId]), endCoords)
                    end
                else
                    DrawMarker(1, endCoords.x, endCoords.y, endCoords.z - 0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.3, r, g, 0, 180, false, false, 0, false, false, false, false)
                end

                DrawLine(endCoords.x, endCoords.y, endCoords.z, endCoords.x, endCoords.y, endCoords.z + 1.5, r, g, 0, 255)

                if IsDisabledControlJustPressed(0, 24) or IsDisabledControlJustPressed(0, 191) then
                    if not validateFn or validateFn(endCoords) then
                        point = vector3(endCoords.x, endCoords.y, endCoords.z)
                        if propEntity and DoesEntityExist(propEntity) then
                            DeleteObject(propEntity)
                            propEntity = nil
                        end
                        step = 2
                        Lib47.ShowObjective(getObjectiveControls(), L(locales, 'circle_creation'))
                    end
                end
            end
        else
            -- Done (ENTER)
            if IsDisabledControlJustPressed(0, 191) then
                EnableAllControlActions(0)
                Lib47.Creation.Cam.Destroy(camera)
                Lib47.HideObjective()
                return point, radius, propId, (propList and propList[propId] or nil)
            end

            -- Radius Adjustments
            local isUp = IsDisabledControlJustPressed(0, 181) or IsDisabledControlJustPressed(0, 241) or IsDisabledControlJustPressed(0, 172)
            local isDown = IsDisabledControlJustPressed(0, 180) or IsDisabledControlJustPressed(0, 242) or IsDisabledControlJustPressed(0, 173)

            local delta = isShift and 0.5 or 2.0
            if isUp then
                radius = math.min(200.0, radius + delta)
            elseif isDown then
                radius = math.max(1.0, radius - delta)
            end

            local r, g, b = 0, 255, 0
            if validateFn and not validateFn(point) then
                r, g, b = 255, 0, 0
            end

            -- Draw sphere / circle marker
            DrawMarker(28, point.x, point.y, point.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, radius * 2.0, radius * 2.0, radius * 2.0, r, g, b, 70, false, false, 2, false, nil, nil, false)
            DrawMarker(1, point.x, point.y, point.z - 0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, radius * 2.0, radius * 2.0, 0.4, r, g, b, 140, false, false, 2, false, nil, nil, false)
            DrawLine(point.x, point.y, point.z, point.x, point.y, point.z + 2.0, r, g, b, 255)
        end
    end
end

Lib47.Creation.Builders.PolyZone = Lib47.Creation.Builders.PolyPoints