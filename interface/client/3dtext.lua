local math_rad = math.rad
local math_cos = math.cos
local math_sin = math.sin
local math_abs = math.abs
local math_sqrt = math.sqrt
local math_floor = math.floor
local string_format = string.format
local table_insert = table.insert

local holdState = {
    active = false,
    keyIndex = nil,
    startTime = 0,
    duration = 0,
    completed = false,
    ownerId = nil,
    lastProgress = -1
}

local GlobalInteractions = {} 
local ActiveInteractions = {}

local GlobalThreadActive = false
local CullingThreadActive = false
local CULLING_DISTANCE = 30.0

local FocusedInteraction = nil
local isActionLocked = false

local function GenerateID(data)
    if data.id then return tostring(data.id) end
    local x = math_floor(data.coords.x * 100) / 100
    local y = math_floor(data.coords.y * 100) / 100
    local z = math_floor(data.coords.z * 100) / 100
    return string_format("%s_%s_%s", x, y, z)
end

local InteractionsLoop
local CullingLoop

local function EnsureInteractionsLoop()
    if not GlobalThreadActive and next(ActiveInteractions) then
        GlobalThreadActive = true
        CreateThread(InteractionsLoop)
    end
end

local function EnsureCullingLoop()
    if not CullingThreadActive and next(GlobalInteractions) then
        CullingThreadActive = true
        CreateThread(CullingLoop)
    end
end

-- ====================================================================
-- Isolated Input Dispatcher (Runs strictly on the single focused target)
-- ====================================================================
local function ProcessInteractionInput(id, interact)
    if isActionLocked or not interact then return end

    local data = interact.data
    local options = data.options or {}

    for i, opt in ipairs(options) do
        if opt.key and (opt.canInteract == nil or (opt.canInteract and opt.canInteract())) then
            if opt.hold and opt.hold > 0 then
                local holdTimeMs = opt.hold * 1000
                
                if holdState.ownerId == id and holdState.keyIndex == i then
                    if holdState.completed then
                        if not IsControlPressed(0, opt.key) then
                            holdState.completed = false
                            holdState.ownerId = nil
                            holdState.lastProgress = -1
                            SendNUIMessage({ action = "progress", id = id, index = i, progress = 0 })
                        end
                    elseif holdState.active then
                        if IsControlPressed(0, opt.key) then
                            local elapsed = GetGameTimer() - holdState.startTime
                            local progress = elapsed / holdState.duration
                            if progress >= 1.0 then progress = 1.0 end

                            if math_abs(progress - holdState.lastProgress) >= 0.01 or progress >= 1.0 then
                                holdState.lastProgress = progress
                                SendNUIMessage({ action = "progress", id = id, index = i, progress = progress })
                            end

                            if progress >= 1.0 then
                                SendNUIMessage({ action = "bump", id = id, index = i })
                                holdState.active = false
                                holdState.completed = true

                                isActionLocked = true
                                CreateThread(function()
                                    Wait(250)
                                    if opt.action then
                                        opt.action()
                                    end
                                    isActionLocked = false
                                end)
                            end
                        else
                            holdState.active = false
                            holdState.ownerId = nil
                            holdState.lastProgress = -1
                            SendNUIMessage({ action = "progress", id = id, index = i, progress = 0 })
                        end
                    end
                else
                    if IsControlJustPressed(0, opt.key) then
                        if holdState.ownerId == nil or holdState.ownerId == id then
                            holdState.active = true
                            holdState.keyIndex = i
                            holdState.ownerId = id
                            holdState.startTime = GetGameTimer()
                            holdState.duration = holdTimeMs
                            holdState.completed = false
                            holdState.lastProgress = 0
                            SendNUIMessage({ action = "progress", id = id, index = i, progress = 0 })
                        end
                    end
                end
            else
                -- Non-hold button: Debounce locked execution
                if IsControlJustReleased(0, opt.key) then
                    isActionLocked = true
                    SendNUIMessage({ action = "bump", id = id, index = i })
                    if opt.action then
                        CreateThread(function()
                            opt.action()
                            Wait(250)
                            isActionLocked = false
                        end)
                    else
                        isActionLocked = false
                    end
                    break
                end
            end
        end
    end
end

-- ====================================================================
-- SLOW CULLING LOOP (30m Range)
-- ====================================================================
CullingLoop = function()
    while true do
        local count = 0
        local ped = PlayerPedId()
        local plyCoords = GetEntityCoords(ped)

        for id, interact in pairs(GlobalInteractions) do
            count = count + 1
            local dist = #(plyCoords - interact.data.coords)
            
            if dist <= CULLING_DISTANCE then
                if not ActiveInteractions[id] then
                    ActiveInteractions[id] = interact
                    EnsureInteractionsLoop()
                end
            else
                if ActiveInteractions[id] then
                    ActiveInteractions[id] = nil
                    
                    if not interact.offScreen then
                        SendNUIMessage({ action = "hide", id = id })
                        interact.offScreen = true
                        interact.displayed = false
                        interact.lastMode = nil
                    end

                    if holdState.ownerId == id then
                        holdState.active = false
                        holdState.completed = false
                        holdState.ownerId = nil
                        holdState.lastProgress = -1
                    end

                    if not interact.static then
                        GlobalInteractions[id] = nil
                    end
                end
            end
        end

        if count == 0 then
            CullingThreadActive = false
            break
        end
        Wait(1000)
    end
end

-- ====================================================================
-- FAST RENDER & SPATIAL LOOP
-- ====================================================================
InteractionsLoop = function()
    while true do
        local count = 0
        local itemsToRemove = {}
        local onScreenCandidates = {}
        local batchedPositions = {}
        local hasPositions = false
        
        local ped = PlayerPedId()
        local plyCoords = GetEntityCoords(ped)
        local camCoords = GetGameplayCamCoord()
        local camRot = GetGameplayCamRot(2)
        
        local radX = math_rad(camRot.x)
        local radZ = math_rad(camRot.z)
        local cosX = math_cos(radX)

        local camForwardX = -math_sin(radZ) * math_abs(cosX)
        local camForwardY = math_cos(radZ) * math_abs(cosX)
        local camForwardZ = math_sin(radX)

        local isPaused = IsPauseMenuActive()
        local isNpcActive = (Interface.IsNpcInteractActive and Interface.IsNpcInteractActive()) or false

        if next(ActiveInteractions) then
            for id, interact in pairs(ActiveInteractions) do
                count = count + 1
                local data = interact.data
                local coords = data.coords

                local dx = coords.x - plyCoords.x
                local dy = coords.y - plyCoords.y
                local dz = coords.z - plyCoords.z
                local dist = math_sqrt(dx * dx + dy * dy + dz * dz)

                local maxDist = data.maxDistance or 5.0
                local distNear = data.distance or 2.5
                if maxDist < distNear then
                    maxDist = distNear + 2.0
                end

                if dist <= maxDist then
                    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
                    if isPaused or isNpcActive then
                        onScreen = false
                    end

                    if onScreen then
                        local toCamX = coords.x - camCoords.x
                        local toCamY = coords.y - camCoords.y
                        local toCamZ = coords.z - camCoords.z
                        local toCamLen = math_sqrt(toCamX * toCamX + toCamY * toCamY + toCamZ * toCamZ)
                        
                        local alignment = 0.0
                        if toCamLen > 0.0001 then
                            alignment = (camForwardX * toCamX + camForwardY * toCamY + camForwardZ * toCamZ) / toCamLen
                        end
                        
                        local focusAngle = 0.98
                        local inFocusRange = (dist <= distNear and alignment > focusAngle)

                        table_insert(onScreenCandidates, {
                            id = id,
                            interact = interact,
                            screenX = screenX,
                            screenY = screenY,
                            dist = dist,
                            alignment = alignment,
                            inFocusRange = inFocusRange
                        })
                    else
                        -- Off-screen
                        if not interact.offScreen then
                            SendNUIMessage({ action = "hide", id = id })
                            interact.offScreen = true
                            interact.displayed = false
                            interact.lastMode = nil
                            interact.keysReleased = false
                            
                            if holdState.ownerId == id then
                                holdState.active = false
                                holdState.completed = false
                                holdState.ownerId = nil
                                holdState.lastProgress = -1
                            end
                        end
                    end
                else
                    -- Out of max distance
                    if interact.static then
                        if not interact.offScreen then
                            SendNUIMessage({ action = "hide", id = id })
                            interact.offScreen = true
                            interact.displayed = false
                            interact.lastMode = nil
                            interact.keysReleased = false
                        end
                    else
                        table_insert(itemsToRemove, id)
                    end
                end
            end
        end

        for _, id in ipairs(itemsToRemove) do
            Interface.HideTextUi3d(id, true)
        end

        -- Find the single best focused candidate
        local bestTargetId = nil
        local bestAlignment = -1.0
        local bestInteract = nil
        for _, cand in ipairs(onScreenCandidates) do
            if cand.inFocusRange and cand.alignment > bestAlignment then
                bestAlignment = cand.alignment
                bestTargetId = cand.id
                bestInteract = cand.interact
            end
        end

        -- Process all on-screen candidates for UI display
        for _, cand in ipairs(onScreenCandidates) do
            local id = cand.id
            local interact = cand.interact
            local data = interact.data
            local mode = (id == bestTargetId) and "full" or "mini"

            -- Filter visible options
            local options = data.options or {}
            local validOptions = {}
            for i, opt in ipairs(options) do
                if opt.isVisible == nil or (opt.isVisible and opt.isVisible()) then
                    table_insert(validOptions, { index = i, opt = opt })
                end
            end

            -- Ensure controls are released before accepting inputs in full mode
            if mode == "full" then
                if not interact.keysReleased then
                    local isHoldingAny = false
                    for _, v in ipairs(validOptions) do
                        local opt = v.opt
                        if opt.key and IsControlPressed(0, opt.key) then
                            isHoldingAny = true
                            break
                        end
                    end

                    if isHoldingAny then
                        mode = "mini"
                    else
                        interact.keysReleased = true
                    end
                end
            else
                interact.keysReleased = false
            end

            -- Send full display payload ONLY when mode changes, or when first shown / returning on-screen
            local modeChanged = (interact.lastMode ~= mode)
            local needsDisplay = (not interact.displayed) or interact.offScreen or modeChanged

            if needsDisplay then
                local nuiOptions = {}
                for _, v in ipairs(validOptions) do
                    local i = v.index
                    local opt = v.opt
                    local keyName = opt.keyName
                    if not keyName and opt.key and Lib47.Keys and Lib47.Keys[opt.key] then
                        keyName = Lib47.Keys[opt.key].keyboard
                    end

                    table_insert(nuiOptions, {
                        originalIndex = i,
                        label = opt.label,
                        key = keyName,
                        progress = 0,
                        activeBump = false,
                        disabled = not (opt.canInteract == nil or (opt.canInteract and opt.canInteract())),
                        hold = opt.hold or 0
                    })
                end

                SendNUIMessage({
                    action = "display",
                    id = id,
                    x = cand.screenX,
                    y = cand.screenY,
                    options = nuiOptions,
                    mode = mode,
                    arc = data.arc or false,
                    scale = data.scale or 1.0
                })

                interact.displayed = true
                interact.offScreen = false
                interact.lastMode = mode
            end

            -- Add to batched position update
            batchedPositions[id] = { x = cand.screenX, y = cand.screenY }
            hasPositions = true
        end

        -- Send batched screen positions to NUI in 1 single message for this frame
        if hasPositions then
            SendNUIMessage({
                action = "updatePositions",
                positions = batchedPositions
            })
        end

        -- Clean up hold state if losing focus
        if FocusedInteraction and FocusedInteraction ~= bestTargetId then
            if holdState.ownerId == FocusedInteraction then
                holdState.active = false
                holdState.completed = false
                holdState.ownerId = nil
                holdState.lastProgress = -1
            end
        end
        FocusedInteraction = bestTargetId

        -- Process input ONLY for the single best focused target
        if bestTargetId and bestInteract and bestInteract.keysReleased then
            ProcessInteractionInput(bestTargetId, bestInteract)
        end

        if count == 0 then
            GlobalThreadActive = false
            FocusedInteraction = nil
            break 
        end
        
        Wait(0)
    end
end

-- ====================================================================
-- Public Interface
-- ====================================================================
Interface.ShowTextUi3d = function(data, static)
    local invoked = GetInvokingResource()
    local id = GenerateID(data)

    if GlobalInteractions[id] then
        GlobalInteractions[id].data = data
        GlobalInteractions[id].static = static
        GlobalInteractions[id].invoked = invoked
        GlobalInteractions[id].displayed = false
    else
        GlobalInteractions[id] = {
            id = id,
            data = data,
            static = static,
            invoked = invoked,
            offScreen = true,
            displayed = false,
            lastMode = nil,
            keysReleased = false
        }
    end

    local dist = #(GetEntityCoords(PlayerPedId()) - data.coords)
    if dist <= CULLING_DISTANCE then
        ActiveInteractions[id] = GlobalInteractions[id]
        EnsureInteractionsLoop()
    end

    EnsureCullingLoop()

    return id
end

Interface.HideTextUi3d = function(id, force)
    if id and GlobalInteractions[id] then
        local interact = GlobalInteractions[id]
        
        if interact.static and not force then
            if not interact.offScreen then
                SendNUIMessage({ action = "hide", id = id })
                interact.offScreen = true
                interact.displayed = false
                interact.lastMode = nil
            end
            interact.keysReleased = false
        else
            GlobalInteractions[id] = nil
            ActiveInteractions[id] = nil
            SendNUIMessage({ action = "hide", id = id })
        end 
        
        if holdState.ownerId == id then
            holdState.active = false
            holdState.completed = false
            holdState.ownerId = nil
            holdState.lastProgress = -1
        end
    end
end

function Interface.RegisterTextUi3d(data)
    return Interface.ShowTextUi3d(data, true)
end

function Interface.RemoveTextUi3d(id)
    Interface.HideTextUi3d(id, true)
end

Lib47.RegisterTextUi3d = Interface.RegisterTextUi3d
Lib47.RemoveTextUi3d = Interface.RemoveTextUi3d
Lib47.ShowTextUi3d = Interface.ShowTextUi3d
Lib47.HideTextUi3d = Interface.HideTextUi3d

exports('RegisterTextUi3d', Interface.RegisterTextUi3d)
exports('RemoveTextUi3d', Interface.RemoveTextUi3d)
exports('ShowTextUi3d', Interface.ShowTextUi3d)
exports('HideTextUi3d', Interface.HideTextUi3d)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        GlobalInteractions = {}
        ActiveInteractions = {}
        FocusedInteraction = nil
        isActionLocked = false
        SendNUIMessage({ action = "hideAll" })
    else
        for i, v in pairs(GlobalInteractions) do
            if v.invoked == resourceName then
                Interface.RemoveTextUi3d(i, true)
            end
        end
    end
end)