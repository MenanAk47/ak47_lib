local math_rad = math.rad
local math_cos = math.cos
local math_sin = math.sin
local math_abs = math.abs

local holdState = {
    active = false,
    keyIndex = nil,
    startTime = 0,
    duration = 0,
    completed = false,
    ownerId = nil
}

local ActiveInteractions = {}
local GlobalThreadActive = false

local function GenerateID(data)
    local x = math.floor(data.coords.x * 100) / 100
    local y = math.floor(data.coords.y * 100) / 100
    local z = math.floor(data.coords.z * 100) / 100
    return string.format("%s_%s_%s", x, y, z)
end

local function DrawInteract(id, interact, plyCoords, camCoords, camForward, dist)
    local data = interact.data
    local callback = interact.callback
    local coords = data.coords
    
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)

    if onScreen then
        interact.offScreen = false

        local distNear = data.distance or 2.5

        local toTarget = coords - camCoords
        local toTargetNormalized = toTarget / #toTarget
        local alignment = (camForward.x * toTargetNormalized.x) + (camForward.y * toTargetNormalized.y) + (camForward.z * toTargetNormalized.z)
        
        local focusAngle = 0.98 
        local mode = "mini"
        
        if dist <= distNear and alignment > focusAngle then
            mode = "full"
        end

        local options = data.options or {}

        -- [[ INPUT SAFETY CHECK START ]] --
        -- If we are about to show the interaction, ensure the user isn't already holding the button
        if mode == "full" then
            if not interact.keysReleased then
                local isHoldingAny = false
                for _, opt in ipairs(options) do
                    if opt.control and IsControlPressed(0, opt.control) then
                        isHoldingAny = true
                        break
                    end
                end

                if isHoldingAny then
                    -- User is holding a key from previous interaction/gameplay
                    -- Force mode to mini so it doesn't pop up or trigger
                    mode = "mini"
                else
                    -- User is 'clean', allow interaction
                    interact.keysReleased = true
                end
            end
        else
            -- Reset safety if we look away or walk away
            interact.keysReleased = false
        end
        -- [[ INPUT SAFETY CHECK END ]] --

        local triggeredOption = nil 

        if mode == "full" then
            for i, opt in ipairs(options) do
                opt.progress = 0 
                opt.activeBump = false 

                if opt.control then
                    if opt.hold and opt.hold > 0 then
                        local holdTimeMs = opt.hold * 1000
                        
                        if IsControlPressed(0, opt.control) then
                            if holdState.ownerId == nil or holdState.ownerId == id then
                                if holdState.completed and holdState.keyIndex == i then
                                    opt.progress = 1.0
                                else
                                    if not holdState.active then
                                        holdState.active = true
                                        holdState.keyIndex = i
                                        holdState.ownerId = id
                                        holdState.startTime = GetGameTimer()
                                        holdState.duration = holdTimeMs
                                        holdState.completed = false
                                    end

                                    if holdState.active and holdState.keyIndex == i then
                                        local elapsed = GetGameTimer() - holdState.startTime
                                        local progress = elapsed / holdState.duration
                                        if progress >= 1.0 then progress = 1.0 end
                                        
                                        opt.progress = progress

                                        if progress >= 1.0 then
                                            opt.activeBump = true 
                                            holdState.active = false 
                                            holdState.completed = true 
                                            
                                            -- Previous Fix: Wait for bump before callback
                                            CreateThread(function()
                                                Wait(250) 
                                                if callback then
                                                    callback(opt)
                                                end
                                            end)
                                        end
                                    end
                                end
                            end
                        else
                            if (holdState.active or holdState.completed) and holdState.keyIndex == i and holdState.ownerId == id then
                                holdState.active = false
                                holdState.completed = false
                                holdState.ownerId = nil
                                opt.progress = 0
                            end
                        end
                    else
                        if IsControlJustReleased(0, opt.control) then
                            triggeredOption = opt
                            opt.activeBump = true 
                        end
                    end
                end
            end
        else
            if holdState.ownerId == id then
                holdState.active = false
                holdState.completed = false
                holdState.ownerId = nil
            end
        end

        SendNUIMessage({
            action = "display",
            id = id,
            x = screenX,
            y = screenY,
            options = options,
            mode = mode,
            arc = data.arc or false,
            scale = data.scale or 1.0
        })

        if triggeredOption and callback then
            callback(triggeredOption)
        end
        if triggeredOption then
            triggeredOption.activeBump = false
        end
    else
        if not interact.offScreen then
            SendNUIMessage({ action = "hide", id = id })
            interact.offScreen = true
            
            if holdState.ownerId == id then
                holdState.active = false
                holdState.completed = false
                holdState.ownerId = nil
            end
        end
    end
end

local function InteractionsLoop()
    GlobalThreadActive = true
    while true do
        local count = 0
        local itemsToRemove = {} -- 1. Create a list for deletions
        
        local ped = PlayerPedId()
        local plyCoords = GetEntityCoords(ped)
        local camCoords = GetGameplayCamCoord()
        local camRot = GetGameplayCamRot(2)
        
        local radX = math_rad(camRot.x)
        local radZ = math_rad(camRot.z)
        local cosX = math_cos(radX)

        local camForward = vector3(
            -math_sin(radZ) * math_abs(cosX),
            math_cos(radZ) * math_abs(cosX),
            math_sin(radX)
        )

        if next(ActiveInteractions) then
            for id, interact in pairs(ActiveInteractions) do
                count = count + 1
                local dist = #(plyCoords - interact.data.coords)
                local maxDist = interact.data.maxDistance or 5.0

                if maxDist < interact.data.distance then
                    maxDist = interact.data.distance + 2.0
                end

                if dist <= maxDist then
                    DrawInteract(id, interact, plyCoords, camCoords, camForward, dist)
                else
                    if interact.static then
                        Interface.HideTextUi3d(id)
                    else
                        table.insert(itemsToRemove, id)
                    end
                end
            end
        end

        for _, id in ipairs(itemsToRemove) do
            Interface.HideTextUi3d(id)
        end

        if count == 0 then
            GlobalThreadActive = false
            break 
        end
        
        Wait(0)
    end
end

Interface.ShowTextUi3d = function(data, callback, static)
    local invoked = GetInvokingResource()
    local id = GenerateID(data)

    if ActiveInteractions[id] then
        ActiveInteractions[id].data = data
        ActiveInteractions[id].callback = callback
        ActiveInteractions[id].static = static
        ActiveInteractions[id].invoked = invoked
    else
        ActiveInteractions[id] = {
            data = data,
            callback = callback,
            static = static,
            invoked = invoked,
            offScreen = true,
            keysReleased = false
        }
    end

    if not GlobalThreadActive then
        CreateThread(InteractionsLoop)
    end

    return id
end

Interface.HideTextUi3d = function(id, force)
    if id and ActiveInteractions[id] then
        if ActiveInteractions[id].static and not force then
            if not ActiveInteractions[id].offScreen then
                SendNUIMessage({ action = "hide", id = id })
                ActiveInteractions[id].offScreen = true
            end
            ActiveInteractions[id].keysReleased = false
        else
            ActiveInteractions[id] = nil
        end 
        
        if holdState.ownerId == id then
            holdState.active = false
            holdState.completed = false
            holdState.ownerId = nil
        end

        Wait(10)
        SendNUIMessage({ action = "hide", id = id })
    end
end

function Interface.RegisterTextUi3d(data, callback)
    return Interface.ShowTextUi3d(data, callback, true)
end

function Interface.RemoveTextUi3d(id)
    Interface.HideTextUi3d(id, true)
end

Bridge.RegisterTextUi3d = Interface.RegisterTextUi3d
Bridge.RemoveTextUi3d = Interface.RemoveTextUi3d

Bridge.ShowTextUi3d = Interface.ShowTextUi3d
Bridge.HideTextUi3d = Interface.HideTextUi3d

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        ActiveInteractions = {}
        SendNUIMessage({ action = "hideAll" })
    else
        for i, v in pairs(ActiveInteractions) do
            if v.invoked == resourceName then
                Interface.RemoveTextUi3d(i, true)
            end
        end
    end
end)