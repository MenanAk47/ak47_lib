local math_rad = math.rad
local math_cos = math.cos
local math_sin = math.sin
local math_abs = math.abs
local math_sqrt = math.sqrt
local math_floor = math.floor
local string_format = string.format
local table_insert = table.insert
local table_wipe = table.wipe or function(t) for k in pairs(t) do t[k] = nil end end

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
local STATE_CHECK_INTERVAL = 200 -- ms between isVisible / canInteract evaluations
local UI_CHECK_INTERVAL = 150    -- ms between global UI active checks
local POS_DELTA_THRESHOLD = 0.0002 -- Minimum screen coordinate delta to trigger NUI update

local FocusedInteraction = nil
local isActionLocked = false
local customUIActive = false
local cachedUIActive = false
local lastUICheckTime = 0

local function GenerateID(data)
    if data.id then return tostring(data.id) end
    local x = math_floor(data.coords.x * 100) / 100
    local y = math_floor(data.coords.y * 100) / 100
    local z = math_floor(data.coords.z * 100) / 100
    return string_format("%s_%s_%s", x, y, z)
end

local function ResetHoldState(targetId)
    if targetId == nil or holdState.ownerId == targetId then
        holdState.active = false
        holdState.completed = false
        holdState.ownerId = nil
        holdState.keyIndex = nil
        holdState.lastProgress = -1
    end
end

local function HideInteractionUI(id, interact)
    if not interact.offScreen then
        SendNUIMessage({ action = "hide", id = id })
        interact.offScreen = true
        interact.displayed = false
        interact.lastMode = nil
        interact.lastScreenX = -1.0
        interact.lastScreenY = -1.0
    end
    interact.keysReleased = false
    ResetHoldState(id)
end

-- ====================================================================
-- Smart Throttled State Evaluator (isVisible & canInteract Caching)
-- ====================================================================
local function EvaluateInteractionState(interact, now, forceFullCheck)
    if not forceFullCheck and (now - interact.lastStateCheck) < STATE_CHECK_INTERVAL then
        return interact.cachedVisible
    end

    interact.lastStateCheck = now
    local data = interact.data

    -- 1. Evaluate root visibility
    local isVis = true
    if data.isVisible then
        isVis = data.isVisible() and true or false
    end

    if not isVis then
        interact.cachedVisible = false
        return false
    end

    interact.cachedVisible = true

    -- 2. Evaluate options visibility & canInteract
    local options = data.options
    if options then
        local optVisible = interact.optVisible
        local optCanInteract = interact.optCanInteract
        local dirty = false

        for i = 1, #options do
            local opt = options[i]

            local vis = true
            if opt.isVisible ~= nil then
                vis = opt.isVisible() and true or false
            end

            local canInt = true
            if vis and opt.canInteract ~= nil then
                canInt = opt.canInteract() and true or false
            end

            if optVisible[i] ~= vis or optCanInteract[i] ~= canInt then
                dirty = true
                optVisible[i] = vis
                optCanInteract[i] = canInt
            end
        end

        if dirty then
            interact.stateDirty = true
        end
    end

    return true
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
-- Isolated Input Dispatcher (Uses Cached State + Final Verification)
-- ====================================================================
local function ProcessInteractionInput(id, interact, now)
    if isActionLocked or not interact then return end

    local data = interact.data
    local options = data.options
    if not options then return end

    local optVisible = interact.optVisible
    local optCanInteract = interact.optCanInteract

    for i = 1, #options do
        local opt = options[i]
        -- Use cached visibility and canInteract to avoid per-frame callback execution
        if opt.key and optVisible[i] ~= false and optCanInteract[i] ~= false then
            if opt.hold and opt.hold > 0 then
                local holdTimeMs = opt.hold * 1000
                
                if holdState.ownerId == id and holdState.keyIndex == i then
                    if holdState.completed then
                        if not IsControlPressed(0, opt.key) then
                            ResetHoldState(id)
                            SendNUIMessage({ action = "progress", id = id, index = i, progress = 0 })
                        end
                    elseif holdState.active then
                        if IsControlPressed(0, opt.key) then
                            local elapsed = now - holdState.startTime
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
                                    -- Final verification right before executing action
                                    if opt.action and (opt.canInteract == nil or opt.canInteract()) then
                                        opt.action()
                                    end
                                    isActionLocked = false
                                end)
                            end
                        else
                            ResetHoldState(id)
                            SendNUIMessage({ action = "progress", id = id, index = i, progress = 0 })
                        end
                    end
                else
                    if IsControlJustPressed(0, opt.key) then
                        if holdState.ownerId == nil or holdState.ownerId == id then
                            -- Verify canInteract once at the start of the hold
                            if opt.canInteract == nil or opt.canInteract() then
                                holdState.active = true
                                holdState.keyIndex = i
                                holdState.ownerId = id
                                holdState.startTime = now
                                holdState.duration = holdTimeMs
                                holdState.completed = false
                                holdState.lastProgress = 0
                                SendNUIMessage({ action = "progress", id = id, index = i, progress = 0 })
                            else
                                optCanInteract[i] = false
                                interact.stateDirty = true
                            end
                        end
                    end
                end
            else
                -- Non-hold button: Debounce locked execution
                if IsControlJustReleased(0, opt.key) then
                    -- Verify canInteract once on release before firing
                    if opt.canInteract == nil or opt.canInteract() then
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
                    else
                        optCanInteract[i] = false
                        interact.stateDirty = true
                    end
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
                    HideInteractionUI(id, interact)

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
    local itemsToRemove = {}
    local onScreenCandidates = {}

    while true do
        local count = 0
        local anyNearMaxDist = false
        local now = GetGameTimer()

        table_wipe(itemsToRemove)
        table_wipe(onScreenCandidates)

        -- Throttle global UI checks to every 150ms instead of every frame
        if (now - lastUICheckTime) >= UI_CHECK_INTERVAL then
            lastUICheckTime = now
            local isPaused = IsPauseMenuActive()
            local isNpcActive = (Interface.IsNpcInteractActive and Interface.IsNpcInteractActive()) or false
            local isContextActive = (Interface.GetOpenMenu and Interface.GetOpenMenu() ~= nil) or false
            local isInputActive = (Interface.IsInputOpen and Interface.IsInputOpen()) or false
            local isAlertActive = (Interface.IsAlertOpen and Interface.IsAlertOpen()) or false
            local isCustomActive = customUIActive or (Interface.IsCustomActive and Interface.IsCustomActive()) or false
            cachedUIActive = isPaused or isNpcActive or isContextActive or isInputActive or isAlertActive or isCustomActive
        end

        local ped = PlayerPedId()
        local plyCoords = GetEntityCoords(ped)

        local camCoords, camForwardX, camForwardY, camForwardZ
        local camInitialized = false

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

                if dist <= (maxDist + 3.0) then
                    anyNearMaxDist = true
                end

                if dist <= maxDist then
                    -- Check UI & throttled visibility BEFORE calling world-to-screen native
                    local isVisible = (not cachedUIActive) and EvaluateInteractionState(interact, now, false)
                    local onScreen, screenX, screenY = false, 0.0, 0.0

                    if isVisible then
                        onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
                    end

                    if onScreen then
                        -- Lazy-init camera vectors only when at least 1 interaction is on screen
                        if not camInitialized then
                            camInitialized = true
                            camCoords = GetGameplayCamCoord()
                            local camRot = GetGameplayCamRot(2)
                            local radX = math_rad(camRot.x)
                            local radZ = math_rad(camRot.z)
                            local absCosX = math_abs(math_cos(radX))

                            camForwardX = -math_sin(radZ) * absCosX
                            camForwardY = math_cos(radZ) * absCosX
                            camForwardZ = math_sin(radX)
                        end

                        local toCamX = coords.x - camCoords.x
                        local toCamY = coords.y - camCoords.y
                        local toCamZ = coords.z - camCoords.z
                        local toCamLen = math_sqrt(toCamX * toCamX + toCamY * toCamY + toCamZ * toCamZ)
                        
                        local alignment = 0.0
                        if toCamLen > 0.0001 then
                            alignment = (camForwardX * toCamX + camForwardY * toCamY + camForwardZ * toCamZ) / toCamLen
                        end
                        
                        local inFocusRange = (dist <= distNear and (data.ignoreFocus or alignment > 0.98))

                        table_insert(onScreenCandidates, {
                            id = id,
                            interact = interact,
                            screenX = screenX,
                            screenY = screenY,
                            dist = dist,
                            distNear = distNear,
                            alignment = alignment,
                            inFocusRange = inFocusRange
                        })
                    else
                        HideInteractionUI(id, interact)
                    end
                else
                    -- Out of max distance
                    if interact.static then
                        HideInteractionUI(id, interact)
                    else
                        table_insert(itemsToRemove, id)
                    end
                end
            end
        end

        for i = 1, #itemsToRemove do
            Interface.HideTextUi3d(itemsToRemove[i], true)
        end

        -- Find the single best focused candidate
        local bestTargetId = nil
        local bestAlignment = -1.0
        local bestDist = 999999.0
        local bestInteract = nil
        local bestIsDirectFocus = false

        for i = 1, #onScreenCandidates do
            local cand = onScreenCandidates[i]
            if cand.inFocusRange then
                local isDirect = cand.alignment > 0.98
                if isDirect then
                    if not bestIsDirectFocus or cand.alignment > bestAlignment then
                        bestIsDirectFocus = true
                        bestAlignment = cand.alignment
                        bestDist = cand.dist
                        bestTargetId = cand.id
                        bestInteract = cand.interact
                    end
                elseif not bestIsDirectFocus then
                    if cand.dist < bestDist then
                        bestDist = cand.dist
                        bestAlignment = cand.alignment
                        bestTargetId = cand.id
                        bestInteract = cand.interact
                    end
                end
            end
        end

        local batchedPositions = nil
        local hasPositions = false

        -- Process all on-screen candidates for UI display
        for i = 1, #onScreenCandidates do
            local cand = onScreenCandidates[i]
            local id = cand.id
            local interact = cand.interact
            local data = interact.data
            local options = data.options
            local optVisible = interact.optVisible
            local optCanInteract = interact.optCanInteract

            local distNear = cand.distNear or data.distance or 2.5
            local isIgnoredFocus = data.ignoreFocus and cand.dist <= distNear
            local mode = (id == bestTargetId or isIgnoredFocus) and "full" or "mini"

            -- Ensure controls are released before accepting inputs in full mode
            if mode == "full" then
                if id == bestTargetId then
                    if not interact.keysReleased then
                        local isHoldingAny = false
                        if options then
                            for idx = 1, #options do
                                local opt = options[idx]
                                if optVisible[idx] ~= false and opt.key and IsControlPressed(0, opt.key) then
                                    isHoldingAny = true
                                    break
                                end
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
            else
                interact.keysReleased = false
            end

            local modeChanged = (interact.lastMode ~= mode)

            -- If switching into full mode, force an immediate state refresh so options are 100% up-to-date
            if modeChanged and mode == "full" then
                EvaluateInteractionState(interact, now, true)
            end

            local needsDisplay = (not interact.displayed) or interact.offScreen or modeChanged or interact.stateDirty

            if needsDisplay then
                local nuiOptions = {}
                if options then
                    for idx = 1, #options do
                        if optVisible[idx] ~= false then
                            local opt = options[idx]
                            local keyName = opt.keyName
                            if not keyName and opt.key and Lib47.Keys and Lib47.Keys[opt.key] then
                                keyName = Lib47.Keys[opt.key].keyboard
                            end

                            table_insert(nuiOptions, {
                                originalIndex = idx,
                                label = opt.label,
                                key = keyName,
                                progress = (holdState.ownerId == id and holdState.keyIndex == idx and holdState.lastProgress > 0) and holdState.lastProgress or 0,
                                activeBump = false,
                                disabled = (optCanInteract[idx] == false),
                                hold = opt.hold or 0
                            })
                        end
                    end
                end

                SendNUIMessage({
                    action = "display",
                    id = id,
                    x = cand.screenX,
                    y = cand.screenY,
                    options = nuiOptions,
                    mode = mode,
                    arc = data.arc or false,
                    scale = data.scale or 0.8
                })

                interact.displayed = true
                interact.offScreen = false
                interact.lastMode = mode
                interact.stateDirty = false
                interact.lastScreenX = cand.screenX
                interact.lastScreenY = cand.screenY
            else
                -- Only batch position updates if screen coordinates actually changed
                if math_abs(cand.screenX - interact.lastScreenX) > POS_DELTA_THRESHOLD or math_abs(cand.screenY - interact.lastScreenY) > POS_DELTA_THRESHOLD then
                    interact.lastScreenX = cand.screenX
                    interact.lastScreenY = cand.screenY
                    if not batchedPositions then batchedPositions = {} end
                    batchedPositions[id] = { x = cand.screenX, y = cand.screenY }
                    hasPositions = true
                end
            end
        end

        -- Send batched screen positions to NUI ONLY when coordinates moved
        if hasPositions then
            SendNUIMessage({
                action = "updatePositions",
                positions = batchedPositions
            })
        end

        -- Clean up hold state if losing focus
        if FocusedInteraction and FocusedInteraction ~= bestTargetId then
            ResetHoldState(FocusedInteraction)
        end
        FocusedInteraction = bestTargetId

        -- Process input ONLY for the single best focused target
        if bestTargetId and bestInteract and bestInteract.keysReleased then
            ProcessInteractionInput(bestTargetId, bestInteract, now)
        end

        if count == 0 then
            GlobalThreadActive = false
            FocusedInteraction = nil
            break 
        end

        -- Adaptive sleep: if no active interaction is near maxDistance, sleep 250ms instead of running every frame
        if anyNearMaxDist then
            Wait(0)
        else
            Wait(250)
        end
    end
end

-- ====================================================================
-- Public Interface
-- ====================================================================
Interface.ShowTextUi3d = function(data, static)
    local invoked = GetInvokingResource()
    local id = GenerateID(data)

    if GlobalInteractions[id] then
        local interact = GlobalInteractions[id]
        interact.data = data
        interact.static = static
        interact.invoked = invoked
        interact.displayed = false
        interact.lastStateCheck = 0
        interact.stateDirty = true
        table_wipe(interact.optVisible)
        table_wipe(interact.optCanInteract)
    else
        GlobalInteractions[id] = {
            id = id,
            data = data,
            static = static,
            invoked = invoked,
            offScreen = true,
            displayed = false,
            lastMode = nil,
            keysReleased = false,
            cachedVisible = true,
            lastStateCheck = 0,
            stateDirty = false,
            lastScreenX = -1.0,
            lastScreenY = -1.0,
            optVisible = {},
            optCanInteract = {}
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
            HideInteractionUI(id, interact)
        else
            GlobalInteractions[id] = nil
            ActiveInteractions[id] = nil
            SendNUIMessage({ action = "hide", id = id })
            ResetHoldState(id)
        end 
    end
end

function Interface.RegisterTextUi3d(data)
    return Interface.ShowTextUi3d(data, true)
end

function Interface.RemoveTextUi3d(id)
    Interface.HideTextUi3d(id, true)
end

Interface.SetCustomUIActive = function(state)
    customUIActive = state and true or false
    lastUICheckTime = 0
end

Interface.IsCustomActive = function()
    return customUIActive
end

Lib47.RegisterTextUi3d = Interface.RegisterTextUi3d
Lib47.RemoveTextUi3d = Interface.RemoveTextUi3d
Lib47.ShowTextUi3d = Interface.ShowTextUi3d
Lib47.HideTextUi3d = Interface.HideTextUi3d
Lib47.SetCustomUIActive = Interface.SetCustomUIActive
Lib47.IsCustomActive = Interface.IsCustomActive

exports('RegisterTextUi3d', Interface.RegisterTextUi3d)
exports('RemoveTextUi3d', Interface.RemoveTextUi3d)
exports('ShowTextUi3d', Interface.ShowTextUi3d)
exports('HideTextUi3d', Interface.HideTextUi3d)
exports('SetCustomUIActive', Interface.SetCustomUIActive)
exports('IsCustomActive', Interface.IsCustomActive)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        GlobalInteractions = {}
        ActiveInteractions = {}
        FocusedInteraction = nil
        isActionLocked = false
        ResetHoldState(nil)
        SendNUIMessage({ action = "hideAll" })
    else
        for i, v in pairs(GlobalInteractions) do
            if v.invoked == resourceName then
                Interface.RemoveTextUi3d(i, true)
            end
        end
    end
end)