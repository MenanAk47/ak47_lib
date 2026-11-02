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
    undo_node = "Undo Node",
    rotate_veh = "Rotate Vehicle",
    rotate_sign = "Rotate Sign",
    rotate_basket = "Rotate Basket",
    rotate_ped = "Rotate Ped",
    place_sign = "Place Sign",
    add_node = "Add Node",
    toggle_wait = "Toggle Wait (Stoppage)",
    toggle_action = "Toggle Action (Checkout)",
    complete_path = "Complete Path",
    skip_step = "Skip Step",
    finish_queue = "Finish Queue",
    save_queue = "Save Queue",
    save_changes = "Save Changes",
    cancel_edits = "Cancel Edits",
    path_nodes = "Path Nodes",
    node_types = "Node Types",
    queue_nodes = "Queue Nodes",
    mode_current = "Current Mode",
    mode_walk = "Walk",
    mode_checkout = "Checkout (Action)",
    mode_stoppage = "Stoppage (Wait)",
    path_blocked = "Path Blocked",
    error_min_checkout = "At least one checkout/action point is required",
    error_min_stoppage = "At least one stoppage/wait point is required",
    confirm_pos = "Confirm Position",
    marker_creation = "Marker Placement",
    wall_obj_creation = "Wall Object Placement",
    npc_nav = "NPC Navigation",
    queue_line = "Queue Line",
}

local function L(locales, key)
    if type(locales) == 'table' and locales[key] then return locales[key] end
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

Lib47.Creation.Render.DrawText3D = function(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 100)
    end
end

Lib47.Creation.Render.DrawLineVector = function(startPos, direction, length, r, g, b, a)
    local endPoint = {
        x = startPos.x + direction.x * length,
        y = startPos.y + direction.y * length,
        z = startPos.z + direction.z * length
    }
    DrawLine(startPos.x, startPos.y, startPos.z, endPoint.x, endPoint.y, endPoint.z, r, g, b, a)
end

Lib47.Creation.Render.GetHeadingFromVector_2d = function(dx, dy)
    local angle = math.atan(dy, dx) * 180 / math.pi
    local heading = angle - 90
    if heading < 0 then heading = heading + 360 end
    return heading
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
        SetFocusArea(pos.x, pos.y, pos.z, 0.0, 0.0, 0.0)
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
    
    if didMove then
        SetCamCoord(cam, camPos)
        SetFocusArea(camPos.x, camPos.y, camPos.z, 0.0, 0.0, 0.0)
    end
    if didRot then SetCamRot(cam, camRot, 2) end
    
    if boundPos and boundDist then
        local dist = #(camPos - boundPos)
        if dist > boundDist then
            local boundDir = norm(camPos - boundPos)
            camPos = boundPos + (boundDir * boundDist)
            SetCamCoord(cam, camPos)
            SetFocusArea(camPos.x, camPos.y, camPos.z, 0.0, 0.0, 0.0)
        end
    end
    return camPos, camRot
end

Lib47.Creation.Cam.Destroy = function(cam)
    SetCamActive(cam, false)
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(cam)
    ClearFocus()
    SetFocusEntity(PlayerPedId())
end

-- =============================================================================
-- BUILDER MODULES
-- =============================================================================

Lib47.Creation.Builders.PolyZone = function(existingData, locales, validateFn, options)
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

    local objectiveTitle = (locales and (locales.title or locales.zone_creation)) or L(locales, 'zone_creation')
    local navList = {
        L(locales, 'next_step') .. " <k>ENTER<k>",
    }
    if options and options.canBack then
        table.insert(navList, L(locales, 'go_back') .. " <k>BACKSPACE<k>")
    end
    table.insert(navList, L(locales, 'cancel') .. " <k>DEL<k>")

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
            List = navList,
        },
    }, objectiveTitle)
    
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
            if options and options.returnStatus then
                return { status = 'cancel' }
            end
            return nil
        end

        -- Back (BACKSPACE)
        if options and options.canBack and IsDisabledControlJustPressed(0, 194) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            if polyZone then polyZone:destroy() end
            Lib47.HideObjective()
            return {
                status = 'back',
                data = { points = points, minZ = (polyZone and polyZone.minZ), maxZ = (polyZone and polyZone.maxZ) }
            }
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
                if options and options.returnStatus then
                    return {
                        status = 'next',
                        data = { points = exportPoints, minZ = finalMinZ, maxZ = finalMaxZ }
                    }
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

Lib47.Creation.Builders.PlaceModel = function(model, existingData, locales, isWater, validateFn, options)
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
    if IsModelAVehicle(hash) then
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
    local basePos = point or plyPos
    local baseHeading = existingData and (existingData.w or existingData.heading) or GetEntityHeading(PlayerPedId())
    local camPos = basePos + (up * 2)
    local camRot = vector3(-35.0, 0.0, baseHeading)
    local camera = Lib47.Creation.Cam.Create("DEFAULT_SCRIPTED_CAMERA", camPos, camRot, true)

    local objectiveTitle = type(locales) == 'string' and locales or (locales and (locales.title or locales.setup_point)) or L(locales, 'setup_point')
    local setPointLabel = (locales and type(locales) == 'table' and (locales.set_point or locales.title)) or L(locales, 'set_point')
    local rotateLabel = (locales and type(locales) == 'table' and locales.rotate) or (IsModelAVehicle(hash) and L(locales, 'rotate_veh') or L(locales, 'rotate'))
    
    local navList = {}
    if options and options.canBack then
        table.insert(navList, L(locales, 'go_back') .. " <k>BACKSPACE<k>")
    end
    table.insert(navList, L(locales, 'cancel') .. " <k>DEL<k>")

    Lib47.ShowObjective({
        {
            Title = L(locales, 'placement'),
            List = {
                setPointLabel .. " <m>1<m>",
                rotateLabel .. " <m>3<m>",
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
            List = navList,
        },
    }, objectiveTitle)

    while true do
        Wait(0)
        
        if invokingResource and GetResourceState(invokingResource) ~= 'started' then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            DeleteEntity(entity)
            Lib47.HideObjective()
            return nil
        end

        -- Cancel (DEL)
        if IsDisabledControlJustPressed(0, 178) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            DeleteEntity(entity)
            Lib47.HideObjective()
            if options and options.returnStatus then
                return { status = 'cancel' }
            end
            return nil
        end

        -- Back (BACKSPACE)
        if options and options.canBack and IsDisabledControlJustPressed(0, 194) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            DeleteEntity(entity)
            Lib47.HideObjective()
            return { status = 'back', data = existingData }
        end

        -- Done/Place (Mouse 1 or Enter)
        if IsDisabledControlJustPressed(0, 24) or (options and options.useEnter and IsDisabledControlJustPressed(0, 191)) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            DeleteEntity(entity)
            Lib47.HideObjective()
            local res = point and vector4(point.x, point.y, point.z, entityHeading) or nil
            if options and options.returnStatus then
                return { status = 'next', data = res }
            end
            return res
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
            if IsModelAVehicle(hash) then
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
            if objectiveTitle then
                Lib47.Creation.Render.DrawText3D(vector3(endCoords.x, endCoords.y, endCoords.z + (zOffset > 0.0 and zOffset + 0.6 or 1.2)), objectiveTitle)
            end
        end
    end
end

Lib47.Creation.Builders.PlacePed = function(model, existingData, locales, validateFn, options)
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
    local basePos = point or plyPos
    local baseHeading = existingData and (existingData.w or existingData.heading) or GetEntityHeading(PlayerPedId())
    local camPos = basePos + (up * 2)
    local camRot = vector3(-35.0, 0.0, baseHeading)
    local camera = Lib47.Creation.Cam.Create("DEFAULT_SCRIPTED_CAMERA", camPos, camRot, true)

    local objectiveTitle = type(locales) == 'string' and locales or (locales and (locales.title or locales.setup_point)) or L(locales, 'setup_point')
    local setPointLabel = (locales and type(locales) == 'table' and (locales.set_point or locales.title)) or L(locales, 'set_point')
    local rotateLabel = (locales and type(locales) == 'table' and locales.rotate_ped) or L(locales, 'rotate_ped')

    local navList = {}
    if options and options.canBack then
        table.insert(navList, L(locales, 'go_back') .. " <k>BACKSPACE<k>")
    end
    table.insert(navList, L(locales, 'cancel') .. " <k>DEL<k>")

    Lib47.ShowObjective({
        {
            Title = L(locales, 'placement'),
            List = {
                setPointLabel .. " <m>1<m>",
                rotateLabel .. " <m>3<m>",
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
            List = navList,
        },
    }, objectiveTitle)

    while true do
        Wait(0)
        
        if invokingResource and GetResourceState(invokingResource) ~= 'started' then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            DeleteEntity(entity)
            Lib47.HideObjective()
            return nil
        end

        -- Cancel (DEL)
        if IsDisabledControlJustPressed(0, 178) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            DeleteEntity(entity)
            Lib47.HideObjective()
            if options and options.returnStatus then
                return { status = 'cancel' }
            end
            return nil
        end

        -- Back (BACKSPACE)
        if options and options.canBack and IsDisabledControlJustPressed(0, 194) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            DeleteEntity(entity)
            Lib47.HideObjective()
            return { status = 'back', data = existingData }
        end

        -- Done/Place (Mouse 1)
        if IsDisabledControlJustPressed(0, 24) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            DeleteEntity(entity)
            Lib47.HideObjective()
            if options and options.returnStatus then
                return { status = 'next', data = point and vector4(point.x, point.y, point.z, entityHeading) or nil }
            end
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
            if objectiveTitle then
                Lib47.Creation.Render.DrawText3D(vector3(endCoords.x, endCoords.y, endCoords.z + 1.2), objectiveTitle)
            end
        end
    end
end

Lib47.Creation.Builders.BoxZone = function(existingData, locales, validateFn, options)
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
    local objectiveTitle = (locales and (locales.title or locales.box_creation)) or L(locales, 'box_creation')

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
                List = (options and options.canBack) and {
                    L(locales, 'go_back') .. " <k>BACKSPACE<k>",
                    L(locales, 'cancel') .. " <k>DEL<k>",
                } or {
                    L(locales, 'cancel') .. " <k>DEL<k>",
                },
            },
        }, objectiveTitle)
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
                List = (options and options.canBack) and {
                    L(locales, 'next_step') .. " <k>ENTER<k>",
                    L(locales, 'go_back') .. " <k>BACKSPACE<k>",
                    L(locales, 'cancel') .. " <k>DEL<k>",
                } or {
                    L(locales, 'next_step') .. " <k>ENTER<k>",
                    L(locales, 'cancel') .. " <k>DEL<k>",
                },
            },
        }, objectiveTitle)
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
            if options and options.returnStatus then
                return { status = 'cancel' }
            end
            return nil
        end

        -- Back (BACKSPACE)
        if options and options.canBack and IsDisabledControlJustPressed(0, 194) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            Lib47.HideObjective()
            return { status = 'back', data = existingData }
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
                if options and options.returnStatus then
                    return {
                        status = 'next',
                        data = { pos = boxPos, length = length, width = width, heading = boxHeading, minZ = minZ, maxZ = maxZ }
                    }
                end
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

    if existingData then
        if existingData.position or existingData.coords or (type(existingData.x) == 'number') then
            local rawPos = existingData.position or existingData.coords or existingData
            if rawPos and rawPos.x and rawPos.y and rawPos.z then
                point = vector3(rawPos.x, rawPos.y, rawPos.z)
            end
        end
        if existingData.radius then
            radius = tonumber(existingData.radius) or radius
        end
        local targetProp = existingData.prop or existingData.currentProp or existingData.model
        if targetProp and propList then
            local targetModel = type(targetProp) == 'table' and (targetProp.model or targetProp.name) or targetProp
            for i, p in ipairs(propList) do
                local pModel = type(p) == 'table' and (p.model or p.name) or p
                if pModel == targetModel then
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

    local objectiveTitle = (locales and (locales.title or locales.circle_creation)) or L(locales, 'circle_creation')
    Lib47.ShowObjective(getObjectiveControls(), objectiveTitle)

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
                    local currentProp = propList[propId]
                    local currentModel = type(currentProp) == 'table' and (currentProp.model or currentProp.name) or currentProp
                    local hash = GetHashKey(currentModel)
                    if not propEntity or not DoesEntityExist(propEntity) then
                        spawnPreviewProp(hash, endCoords)
                    else
                        SetEntityCoordsNoOffset(propEntity, endCoords.x, endCoords.y, endCoords.z)
                    end

                    -- Change prop
                    if IsDisabledControlJustPressed(0, 181) or IsDisabledControlJustPressed(0, 241) or IsDisabledControlJustPressed(0, 175) then
                        propId = (propId >= #propList) and 1 or (propId + 1)
                        local nextProp = propList[propId]
                        local nextModel = type(nextProp) == 'table' and (nextProp.model or nextProp.name) or nextProp
                        spawnPreviewProp(GetHashKey(nextModel), endCoords)
                    elseif IsDisabledControlJustPressed(0, 180) or IsDisabledControlJustPressed(0, 242) or IsDisabledControlJustPressed(0, 174) then
                        propId = (propId <= 1) and #propList or (propId - 1)
                        local prevProp = propList[propId]
                        local prevModel = type(prevProp) == 'table' and (prevProp.model or prevProp.name) or prevProp
                        spawnPreviewProp(GetHashKey(prevModel), endCoords)
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
                local chosenProp = propList and propList[propId] or nil
                local propName = type(chosenProp) == 'table' and (chosenProp.model or chosenProp.name) or chosenProp
                return point, radius, propId, propName
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


Lib47.Creation.Builders.PlaceWallObject = function(model, existingData, locales, validateFn, options)
    local invokingResource = GetInvokingResource()
    local hash = type(model) == 'string' and GetHashKey(model) or model
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end

    local pedPos = GetEntityCoords(PlayerPedId())
    local prop = CreateObject(hash, pedPos.x, pedPos.y, pedPos.z - 10.0, 0.0, false)
    SetEntityCollision(prop, false, false)
    SetEntityAlpha(prop, 200)

    local manualRotOffset = 0.0
    local point = nil

    if existingData and existingData.x then
        point = vector3(existingData.x, existingData.y, existingData.z)
    end

    local fwd, right, up, plyPos = GetEntityMatrix(PlayerPedId())
    local basePos = point or plyPos
    local baseHeading = existingData and (existingData.w or existingData.heading) or GetEntityHeading(PlayerPedId())
    local camPos = basePos + (up * 2)
    local camRot = vector3(-35.0, 0.0, baseHeading)
    local camera = Lib47.Creation.Cam.Create("DEFAULT_SCRIPTED_CAMERA", camPos, camRot, true)

    local objectiveTitle = (locales and (locales.title or locales.wall_obj_creation)) or L(locales, 'wall_obj_creation')
    local placeLabel = (locales and locales.place_sign) or L(locales, 'place_sign')
    local rotateLabel = (locales and locales.rotate_sign) or L(locales, 'rotate_sign')

    local navList = {}
    if options and options.canBack then
        table.insert(navList, L(locales, 'go_back') .. " <k>BACKSPACE<k>")
    end
    table.insert(navList, L(locales, 'cancel') .. " <k>DEL<k>")

    Lib47.ShowObjective({
        {
            Title = L(locales, 'placement'),
            List = {
                placeLabel .. " <m>1<m>",
                rotateLabel .. " <m>3<m>",
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
            List = navList,
        },
    }, objectiveTitle)

    while true do
        Wait(0)

        if invokingResource and GetResourceState(invokingResource) ~= 'started' then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            DeleteEntity(prop)
            Lib47.HideObjective()
            return nil
        end

        -- Cancel (DEL)
        if IsDisabledControlJustPressed(0, 178) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            DeleteEntity(prop)
            Lib47.HideObjective()
            if options and options.returnStatus then
                return { status = 'cancel' }
            end
            return nil
        end

        -- Back (BACKSPACE)
        if options and options.canBack and IsDisabledControlJustPressed(0, 194) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            DeleteEntity(prop)
            Lib47.HideObjective()
            return { status = 'back', data = existingData }
        end

        -- Place (Mouse 1)
        if IsDisabledControlJustPressed(0, 24) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            local finalPos = point and vector4(point.x, point.y, point.z, GetEntityHeading(prop)) or nil
            DeleteEntity(prop)
            Lib47.HideObjective()
            if options and options.returnStatus then
                return { status = 'next', data = finalPos }
            end
            return finalPos
        end

        -- Rotate (Scroll)
        if IsDisabledControlJustPressed(0, 181) then
            if IsDisabledControlPressed(0, 21) then
                manualRotOffset = manualRotOffset + 2.0
            else
                manualRotOffset = manualRotOffset + 10.0
            end
        end
        if IsDisabledControlJustPressed(0, 180) then
            if IsDisabledControlPressed(0, 21) then
                manualRotOffset = manualRotOffset - 2.0
            else
                manualRotOffset = manualRotOffset - 10.0
            end
        end

        DisableAllControlActions(0)
        camPos, camRot = Lib47.Creation.Cam.HandleFlyCam(camera)
        local right, fwd, up, pos = GetCamMatrix(camera)
        local rayHit = StartExpensiveSynchronousShapeTestLosProbe(pos.x, pos.y, pos.z, pos.x + (fwd.x * 100.0), pos.y + (fwd.y * 100.0), pos.z + (fwd.z * 100.0), 511, PlayerPedId(), 4)
        local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHit)

        if hit ~= 0 then
            point = endCoords
            SetEntityCoordsNoOffset(prop, endCoords.x, endCoords.y, endCoords.z)
            local wallHeading = Lib47.Creation.Render.GetHeadingFromVector_2d(surfaceNormal.x, surfaceNormal.y)
            SetEntityHeading(prop, wallHeading + 180.0 + manualRotOffset)
            local r, g = 0, 255
            if validateFn and not validateFn(point) then
                r, g = 255, 0
            end
            DrawLine(endCoords.x, endCoords.y, endCoords.z, endCoords.x + surfaceNormal.x, endCoords.y + surfaceNormal.y, endCoords.z + surfaceNormal.z, r, g, 0, 255)
            if objectiveTitle then
                Lib47.Creation.Render.DrawText3D(vector3(endCoords.x, endCoords.y, endCoords.z + 0.3), objectiveTitle)
            end
        else
            SetEntityCoordsNoOffset(prop, 0.0, 0.0, -10.0)
        end
    end
end

Lib47.Creation.Builders.PlaceMarker = function(existingData, locales, validateFn, options)
    local invokingResource = GetInvokingResource()
    local point = existingData and vector3(existingData.x, existingData.y, existingData.z) or nil
    local fwd, right, up, plyPos = GetEntityMatrix(PlayerPedId())
    local basePos = point or plyPos
    local camPos = basePos + (up * 2)
    local camRot = vector3(-35.0, 0.0, GetEntityHeading(PlayerPedId()))
    local camera = Lib47.Creation.Cam.Create("DEFAULT_SCRIPTED_CAMERA", camPos, camRot, true)

    local objectiveTitle = (locales and (locales.title or locales.marker_creation)) or L(locales, 'marker_creation')
    local confirmLabel = (locales and locales.confirm_pos) or L(locales, 'confirm_pos')

    local navList = {}
    if options and options.canBack then
        table.insert(navList, L(locales, 'go_back') .. " <k>BACKSPACE<k>")
    end
    table.insert(navList, L(locales, 'cancel') .. " <k>DEL<k>")

    Lib47.ShowObjective({
        {
            Title = L(locales, 'placement'),
            List = {
                confirmLabel .. " <m>1<m>",
            }
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
            List = navList,
        },
    }, objectiveTitle)

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
            if options and options.returnStatus then
                return { status = 'cancel' }
            end
            return nil
        end

        -- Back (BACKSPACE)
        if options and options.canBack and IsDisabledControlJustPressed(0, 194) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            Lib47.HideObjective()
            return { status = 'back', data = existingData }
        end

        -- Place (Mouse 1)
        if IsDisabledControlJustPressed(0, 24) then
            EnableAllControlActions(0)
            Lib47.Creation.Cam.Destroy(camera)
            Lib47.HideObjective()
            if options and options.returnStatus then
                return { status = 'next', data = point }
            end
            return point
        end

        DisableAllControlActions(0)
        camPos, camRot = Lib47.Creation.Cam.HandleFlyCam(camera)
        local right, fwd, up, pos = GetCamMatrix(camera)
        local rayHit = StartExpensiveSynchronousShapeTestLosProbe(pos.x, pos.y, pos.z, pos.x + (fwd.x * 100.0), pos.y + (fwd.y * 100.0), pos.z + (fwd.z * 100.0), 4294967295, PlayerPedId(), 4)
        local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHit)
        if hit ~= 0 then
            point = vector3(endCoords.x, endCoords.y, endCoords.z + 0.8)
            local r, g = 0, 255
            if validateFn and not validateFn(point) then
                r, g = 255, 0
            end
            DrawLine(endCoords.x, endCoords.y, endCoords.z, endCoords.x, endCoords.y, endCoords.z + 1.0, 255, 0, 0, 255)
            DrawMarker(21, endCoords.x, endCoords.y, endCoords.z + 0.8, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.4, 255, 0, 0, 100, 0, 0, 0, 1)
            if objectiveTitle then
                Lib47.Creation.Render.DrawText3D(vector3(endCoords.x, endCoords.y, endCoords.z + 1.0), objectiveTitle)
            end
        end
    end
end

Lib47.Creation.Builders.NavPoints = function(existingPoints, locales, options)
    local invokingResource = GetInvokingResource()
    local navs = {}
    if existingPoints and #existingPoints > 0 then
        for i = 1, #existingPoints do
            local item = existingPoints[i]
            local pos = item.position or item
            local posVec = vector4(pos.x, pos.y, pos.z, pos.w or pos.h or pos.heading or 0.0)
            table.insert(navs, {
                position = posVec,
                stoppage = item.stoppage or false,
                checkout = item.checkout or false
            })
        end
    end

    local walkDict, walkClip = "move_m@confident", 'walk'
    local giveDict, giveClip = "mp_common", "givetake1_a"
    RequestAnimDict(walkDict); while not HasAnimDictLoaded(walkDict) do Wait(0) end
    RequestAnimDict(giveDict); while not HasAnimDictLoaded(giveDict) do Wait(0) end

    local ped = ClonePed(PlayerPedId(), false)
    SetEntityAlpha(ped, 200)
    SetEntityCollision(ped, false, false)
    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, true)

    local startPos = GetEntityCoords(PlayerPedId())
    local pedHeading = 0.0
    if #navs > 0 then
        startPos = vector3(navs[#navs].position.x, navs[#navs].position.y, navs[#navs].position.z)
        pedHeading = navs[#navs].position.w
    end

    local fwd, right, up, plyPos = GetEntityMatrix(ped)
    local camPos = startPos + (up * 2)
    local camRot = vector3(-35.0, 0.0, GetEntityHeading(PlayerPedId()))
    local camera = Lib47.Creation.Cam.Create("DEFAULT_SCRIPTED_CAMERA", camPos, camRot, true)

    local navPeds = {}
    local function spawnExistingPeds()
        for i = 1, #navs do
            local v = navs[i]
            local p = ClonePed(ped, false)
            SetEntityCoords(p, v.position.x, v.position.y, v.position.z - 1.0)
            SetEntityHeading(p, v.position.w)
            SetEntityAlpha(p, 255)
            FreezeEntityPosition(p, true)
            if v.checkout then
                TaskPlayAnim(p, giveDict, giveClip, 8.0, 8.0, -1, 1)
            elseif not v.stoppage then
                TaskPlayAnim(p, walkDict, walkClip, 8.0, 8.0, -1, 1)
            end
            table.insert(navPeds, p)
        end
    end
    spawnExistingPeds()

    local checkout, stoppage = false, false
    local point = nil

    local function updateNavUI()
        local currentMode = L(locales, 'mode_walk')
        if checkout then currentMode = L(locales, 'mode_checkout')
        elseif stoppage then currentMode = L(locales, 'mode_stoppage') end

        local navList = {
            (L(locales, 'complete_path') or L(locales, 'save_changes')) .. " <k>ENTER<k>",
        }
        if options and options.canSkip then
            table.insert(navList, L(locales, 'skip_step') .. " <k>TAB<k>")
        end
        if options and options.canBack then
            table.insert(navList, L(locales, 'go_back') .. " <k>BACKSPACE<k>")
        end
        table.insert(navList, L(locales, 'cancel') .. " <k>DEL<k>")

        Lib47.ShowObjective({
            {
                Title = L(locales, 'mode_current') .. ": " .. currentMode,
                List = {}
            },
            {
                Title = L(locales, 'path_nodes'),
                List = {
                    L(locales, 'add_node') .. " <m>1<m>",
                    L(locales, 'undo_node') .. " <m>2<m>",
                    L(locales, 'rotate_ped') .. " <m>3<m>",
                    L(locales, 'precision') .. " <k>SHIFT<k>",
                },
            },
            {
                Title = L(locales, 'node_types'),
                List = {
                    L(locales, 'toggle_wait') .. " <k>F<k>",
                    L(locales, 'toggle_action') .. " <k>G<k>",
                },
            },
            {
                Title = L(locales, 'navigation'),
                List = navList,
            },
            {
                Title = L(locales, 'cam_controls'),
                List = {
                    "<m><m> <k>W<k> <k>A<k> <k>S<k> <k>D<k>",
                    L(locales, 'move_up') .. " <k>Q<k>",
                    L(locales, 'move_down') .. " <k>E<k>",
                },
            },
        }, (locales and (locales.title or locales.npc_nav)) or L(locales, 'npc_nav'))
    end

    updateNavUI()

    local function cleanup()
        EnableAllControlActions(0)
        Lib47.Creation.Cam.Destroy(camera)
        DeleteEntity(ped)
        for _, v in pairs(navPeds) do DeleteEntity(v) end
        Lib47.HideObjective()
    end

    while true do
        Wait(0)
        local stopCount, checkCount = 0, 0

        if invokingResource and GetResourceState(invokingResource) ~= 'started' then
            cleanup()
            return nil
        end

        -- Cancel (DEL)
        if IsDisabledControlJustPressed(0, 178) then
            cleanup()
            if options and options.returnStatus then
                return { status = 'cancel' }
            end
            return nil
        end

        -- Draw nodes and connections
        for i = 1, #navs do
            local pos = navs[i].position
            if navs[i].stoppage then stopCount = stopCount + 1 end
            if navs[i].checkout then checkCount = checkCount + 1 end
            Lib47.Creation.Render.DrawText3D(vector3(pos.x, pos.y, pos.z + 2.1), "Node " .. i)
            if i > 1 then
                local prevPos = navs[i-1].position
                DrawLine(prevPos.x, prevPos.y, prevPos.z, pos.x, pos.y, pos.z, 0, 255, 0, 255)
            end
            if navPeds[i] and DoesEntityExist(navPeds[i]) then
                if navs[i].checkout then
                    if not IsEntityPlayingAnim(navPeds[i], giveDict, giveClip, 3) then TaskPlayAnim(navPeds[i], giveDict, giveClip, 8.0, 8.0, -1, 1) end
                elseif not navs[i].stoppage and not IsEntityPlayingAnim(navPeds[i], walkDict, walkClip, 3) then
                    TaskPlayAnim(navPeds[i], walkDict, walkClip, 8.0, 8.0, -1, 1)
                end
            end
        end

        -- Draw other paths if provided in options.otherPaths
        if options and options.otherPaths then
            for pIdx = 1, #options.otherPaths do
                local oPath = options.otherPaths[pIdx]
                for j = 1, #oPath do
                    local oPos = oPath[j].position or oPath[j]
                    if j > 1 then
                        local prev = oPath[j-1].position or oPath[j-1]
                        DrawLine(prev.x, prev.y, prev.z, oPos.x, oPos.y, oPos.z, 100, 100, 100, 150)
                    end
                end
            end
        end

        -- Back (BACKSPACE)
        if options and options.canBack and IsDisabledControlJustPressed(0, 194) then
            cleanup()
            return { status = 'back', data = navs }
        end

        -- Skip (TAB)
        if options and options.canSkip and IsDisabledControlJustPressed(0, 37) then
            cleanup()
            if options.returnStatus then
                return { status = 'next', data = {} }
            end
            return {}
        end

        -- Done (ENTER)
        if IsDisabledControlJustPressed(0, 191) then
            local reqCheck = (options and options.requireCheckout ~= nil) and options.requireCheckout or true
            local reqStop = (options and options.requireStoppage ~= nil) and options.requireStoppage or true
            if reqCheck and checkCount < 1 then
                Lib47.Notify(L(locales, 'error_min_checkout'), 'error')
            elseif reqStop and stopCount < 1 then
                Lib47.Notify(L(locales, 'error_min_stoppage'), 'error')
            else
                cleanup()
                if options and options.returnStatus then
                    return { status = 'next', data = navs }
                end
                return navs
            end
        end

        -- Add node (Mouse 1)
        if IsDisabledControlJustPressed(0, 24) and point then
            local tempPed = ClonePed(ped, false)
            SetEntityAlpha(tempPed, 255)
            SetEntityCollision(tempPed, false, false)
            SetEntityHeading(tempPed, pedHeading)
            FreezeEntityPosition(tempPed, true)

            if checkout then TaskPlayAnim(tempPed, giveDict, giveClip, 8.0, 8.0, -1, 1)
            elseif not stoppage then TaskPlayAnim(tempPed, walkDict, walkClip, 8.0, 8.0, -1, 1) end

            table.insert(navPeds, tempPed)
            table.insert(navs, {position = vector4(point.x, point.y, point.z, pedHeading), stoppage = stoppage, checkout = checkout})
            stoppage = false
            checkout = false
            updateNavUI()
        end

        -- Undo node (Mouse 2)
        if IsDisabledControlJustPressed(0, 25) then
            if #navPeds > 0 then
                DeleteEntity(navPeds[#navPeds])
                table.remove(navPeds, #navPeds)
                table.remove(navs, #navs)
            end
        end

        -- Heading rotate
        if IsDisabledControlJustPressed(0, 181) then
            if IsDisabledControlPressed(0, 21) then pedHeading = pedHeading + 2.0 else pedHeading = pedHeading + 10.0 end
        end
        if IsDisabledControlJustPressed(0, 180) then
            if IsDisabledControlPressed(0, 21) then pedHeading = pedHeading - 2.0 else pedHeading = pedHeading - 10.0 end
        end

        -- Stoppage toggle (F / 23)
        if IsDisabledControlJustPressed(0, 23) then
            stoppage = not stoppage
            if stoppage then checkout = false end
            ClearPedTasks(ped)
            updateNavUI()
        end

        -- Checkout toggle (G / 47)
        if IsDisabledControlJustPressed(0, 47) then
            checkout = not checkout
            if checkout then stoppage = false end
            ClearPedTasks(ped)
            updateNavUI()
        end

        if checkout then
            if not IsEntityPlayingAnim(ped, giveDict, giveClip, 3) then TaskPlayAnim(ped, giveDict, giveClip, 8.0, 8.0, -1, 1) end
        elseif not stoppage then
            if not IsEntityPlayingAnim(ped, walkDict, walkClip, 3) then TaskPlayAnim(ped, walkDict, walkClip, 8.0, 8.0, -1, 1) end
        else
            if IsEntityPlayingAnim(ped, walkDict, walkClip, 3) or IsEntityPlayingAnim(ped, giveDict, giveClip, 3) then ClearPedTasks(ped) end
        end

        DisableAllControlActions(0)
        camPos, camRot = Lib47.Creation.Cam.HandleFlyCam(camera)
        local right, fwd, up, pos = GetCamMatrix(camera)
        local rayHit = StartExpensiveSynchronousShapeTestLosProbe(pos.x, pos.y, pos.z, pos.x + (fwd.x * 100.0), pos.y + (fwd.y * 100.0), pos.z + (fwd.z * 100.0), 1, PlayerPedId(), 4)
        local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHit)
        point = vector3(endCoords.x, endCoords.y, endCoords.z + 1.0)

        SetEntityCoordsNoOffset(ped, endCoords.x, endCoords.y, endCoords.z + 1.0, false, false, false)
        SetEntityHeading(ped, pedHeading)

        if #navs > 0 then
            local lastPos = vector3(navs[#navs].position.x, navs[#navs].position.y, navs[#navs].position.z)
            local currentPedCoords = GetEntityCoords(ped)
            local dirVector = currentPedCoords - lastPos
            local dist = #(dirVector)
            local rightVector = vector3(1.0, 0.0, 0.0)
            if dist > 0.1 then
                local dirNorm = dirVector / dist
                rightVector = vector3(dirNorm.y, -dirNorm.x, 0.0)
            else
                local _, rVec, _, _ = GetEntityMatrix(ped)
                rightVector = rVec
            end
            local widthOffset = 0.25
            local checkLines = {
                { startP = lastPos, endP = currentPedCoords },
                { startP = lastPos - (rightVector * widthOffset), endP = currentPedCoords - (rightVector * widthOffset) },
                { startP = lastPos + (rightVector * widthOffset), endP = currentPedCoords + (rightVector * widthOffset) }
            }
            local isBlocked = false
            for i = 1, #checkLines do
                local line = checkLines[i]
                local lineHit = StartExpensiveSynchronousShapeTestLosProbe(line.startP.x, line.startP.y, line.startP.z, line.endP.x, line.endP.y, line.endP.z, 511, ped, 4)
                local _, lHit, _, _, _ = GetShapeTestResult(lineHit)
                if lHit ~= 0 then isBlocked = true end
            end
            local r, g, b = 0, 255, 0
            if isBlocked then
                r, g, b = 255, 0, 0
                Lib47.Creation.Render.DrawText3D(vector3(endCoords.x, endCoords.y, endCoords.z + 1.25), L(locales, 'path_blocked'))
            end
            for i = 1, #checkLines do
                local line = checkLines[i]
                DrawLine(line.startP.x, line.startP.y, line.startP.z, line.endP.x, line.endP.y, line.endP.z, r, g, b, 255)
            end
        end
    end
end

Lib47.Creation.Builders.QueuePoints = function(existingQueue, locales, options)
    local invokingResource = GetInvokingResource()
    local queuePoints = {}
    if existingQueue and #existingQueue > 0 then
        for i = 1, #existingQueue do
            local item = existingQueue[i]
            local pos = vector4(item.x, item.y, item.z, item.w or item.h or item.heading or 0.0)
            table.insert(queuePoints, pos)
        end
    end

    local ped = ClonePed(PlayerPedId(), false)
    SetEntityAlpha(ped, 200)
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)

    local pedHeading = 0.0
    local point = nil

    local startPos = GetEntityCoords(PlayerPedId())
    if #queuePoints > 0 then
        startPos = vector3(queuePoints[#queuePoints].x, queuePoints[#queuePoints].y, queuePoints[#queuePoints].z)
        pedHeading = queuePoints[#queuePoints].w
    end

    local fwd, right, up, plyPos = GetEntityMatrix(ped)
    local camPos = startPos + (up * 2)
    local camRot = vector3(-35.0, 0.0, GetEntityHeading(PlayerPedId()))
    local camera = Lib47.Creation.Cam.Create("DEFAULT_SCRIPTED_CAMERA", camPos, camRot, true)

    local navList = {
        (L(locales, 'finish_queue') or L(locales, 'save_queue')) .. " <k>ENTER<k>",
    }
    if options and options.canBack then
        table.insert(navList, L(locales, 'go_back') .. " <k>BACKSPACE<k>")
    end
    table.insert(navList, L(locales, 'cancel') .. " <k>DEL<k>")

    Lib47.ShowObjective({
        {
            Title = L(locales, 'queue_nodes'),
            List = {
                L(locales, 'add_node') .. " <m>1<m>",
                L(locales, 'undo_node') .. " <m>2<m>",
                L(locales, 'rotate_ped') .. " <m>3<m>",
                L(locales, 'precision') .. " <k>SHIFT<k>",
            },
        },
        {
            Title = L(locales, 'navigation'),
            List = navList,
        },
        {
            Title = L(locales, 'cam_controls'),
            List = {
                "<m><m> <k>W<k> <k>A<k> <k>S<k> <k>D<k>",
                L(locales, 'move_up') .. " <k>Q<k>",
                L(locales, 'move_down') .. " <k>E<k>",
            },
        },
    }, (locales and (locales.title or locales.queue_line)) or L(locales, 'queue_line'))

    local queuePeds = {}
    local function refreshQueuePeds()
        for _, v in pairs(queuePeds) do DeleteEntity(v) end
        queuePeds = {}
        for _, pos in ipairs(queuePoints) do
            local p = ClonePed(ped, false)
            SetEntityAlpha(p, 200)
            SetEntityCollision(p, false, false)
            SetEntityCoords(p, pos.x, pos.y, pos.z - 1.0)
            SetEntityHeading(p, pos.w)
            FreezeEntityPosition(p, true)
            table.insert(queuePeds, p)
        end
    end
    refreshQueuePeds()

    local function cleanup()
        EnableAllControlActions(0)
        Lib47.Creation.Cam.Destroy(camera)
        DeleteEntity(ped)
        for _, v in pairs(queuePeds) do DeleteEntity(v) end
        Lib47.HideObjective()
    end

    while true do
        Wait(0)

        if invokingResource and GetResourceState(invokingResource) ~= 'started' then
            cleanup()
            return nil
        end

        -- Cancel (DEL)
        if IsDisabledControlJustPressed(0, 178) then
            cleanup()
            if options and options.returnStatus then
                return { status = 'cancel' }
            end
            return nil
        end

        -- Back (BACKSPACE)
        if options and options.canBack and IsDisabledControlJustPressed(0, 194) then
            cleanup()
            return { status = 'back', data = queuePoints }
        end

        -- Done (ENTER)
        if IsDisabledControlJustPressed(0, 191) then
            cleanup()
            if options and options.returnStatus then
                return { status = 'next', data = queuePoints }
            end
            return queuePoints
        end

        -- Add node (Mouse 1)
        if IsDisabledControlJustPressed(0, 24) and point then
            table.insert(queuePoints, vector4(point.x, point.y, point.z, pedHeading))
            refreshQueuePeds()
        end

        -- Undo node (Mouse 2)
        if IsDisabledControlJustPressed(0, 25) then
            if #queuePoints > 0 then
                table.remove(queuePoints, #queuePoints)
                refreshQueuePeds()
            end
        end

        -- Heading rotate
        if IsDisabledControlJustPressed(0, 181) then
            if IsDisabledControlPressed(0, 21) then pedHeading = pedHeading + 2.0 else pedHeading = pedHeading + 10.0 end
        end
        if IsDisabledControlJustPressed(0, 180) then
            if IsDisabledControlPressed(0, 21) then pedHeading = pedHeading - 2.0 else pedHeading = pedHeading - 10.0 end
        end

        DisableAllControlActions(0)
        camPos, camRot = Lib47.Creation.Cam.HandleFlyCam(camera)
        local right, fwd, up, pos = GetCamMatrix(camera)
        local rayHit = StartExpensiveSynchronousShapeTestLosProbe(pos.x, pos.y, pos.z, pos.x + (fwd.x * 100.0), pos.y + (fwd.y * 100.0), pos.z + (fwd.z * 100.0), 1, PlayerPedId(), 4)
        local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHit)
        point = vector3(endCoords.x, endCoords.y, endCoords.z + 1.0)

        SetEntityCoordsNoOffset(ped, endCoords.x, endCoords.y, endCoords.z + 1.0)
        SetEntityHeading(ped, pedHeading)

        for i, v in ipairs(queuePoints) do
            Lib47.Creation.Render.DrawText3D(vector3(v.x, v.y, v.z + 1.0), "Q" .. i)
            if i > 1 then
                local prev = queuePoints[i-1]
                DrawLine(prev.x, prev.y, prev.z, v.x, v.y, v.z, 200, 200, 0, 150)
            end
        end
    end
end

Lib47.Creation.Builders.PolyPoints = Lib47.Creation.Builders.PolyZone