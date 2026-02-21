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

local GlobalInteractions = {} 
local ActiveInteractions = {}

local GlobalThreadActive = false
local CullingThreadActive = false
local CULLING_DISTANCE = 30.0

local function GenerateID(data)
    local x = math.floor(data.coords.x * 100) / 100
    local y = math.floor(data.coords.y * 100) / 100
    local z = math.floor(data.coords.z * 100) / 100
    return string.format("%s_%s_%s", x, y, z)
end

local function DrawInteract(id, interact, plyCoords, camCoords, camForward, dist, isPaused)
    local data = interact.data
    local coords = data.coords
    
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)

    if isPaused then
        onScreen = false
    end

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
        local validOptions = {}
        local nuiOptions = {}

        for i, opt in ipairs(options) do
            if opt.isVisible and opt.isVisible() then
                table.insert(validOptions, { index = i, opt = opt })
            end
        end

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

        local triggeredOption = nil 

        if mode == "full" then
            for _, v in ipairs(validOptions) do
                local i = v.index
                local opt = v.opt
                
                opt.progress = 0 
                opt.activeBump = false 

                local canInteract = true
                if type(opt.canInteract) == "function" then
                    canInteract = opt.canInteract()
                elseif opt.canInteract ~= nil then
                    canInteract = opt.canInteract
                end

                if opt.key and canInteract then
                    if opt.hold and opt.hold > 0 then
                        local holdTimeMs = opt.hold * 1000
                        
                        if IsControlPressed(0, opt.key) then
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
                                            
                                            CreateThread(function()
                                                Wait(250) 
                                                if opt.action then
                                                    opt.action()
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
                        if IsControlJustReleased(0, opt.key) then
                            triggeredOption = opt
                            opt.activeBump = true 
                        end
                    end
                end

                local keyName = opt.keyName
                if not keyName and Lib47.Keys and Lib47.Keys[opt.key] then
                    keyName = Lib47.Keys[opt.key].keyboard
                end

                table.insert(nuiOptions, {
                    label = opt.label,
                    key = keyName,
                    progress = opt.progress,
                    activeBump = opt.activeBump,
                    disabled = not canInteract
                })
            end
        else
            if holdState.ownerId == id then
                holdState.active = false
                holdState.completed = false
                holdState.ownerId = nil
            end

            for _, v in ipairs(validOptions) do
                local opt = v.opt
                local keyName = opt.keyName
                if not keyName and Lib47.Keys and Lib47.Keys[opt.key] then
                    keyName = Lib47.Keys[opt.key].keyboard
                end
                
                table.insert(nuiOptions, {
                    label = opt.label,
                    key = keyName
                })
            end
        end

        SendNUIMessage({
            action = "display",
            id = id,
            x = screenX,
            y = screenY,
            options = nuiOptions,
            mode = mode,
            arc = data.arc or false,
            scale = data.scale or 1.0
        })

        if triggeredOption then
            triggeredOption.activeBump = false
            if triggeredOption.action then
                CreateThread(function()
                    Wait(100)
                    triggeredOption.action()
                end)
            end
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

-- === NEW: SLOW CULLING LOOP === --
local function CullingLoop()
    CullingThreadActive = true
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
                    if not GlobalThreadActive then
                        CreateThread(InteractionsLoop)
                    end
                end
            else
                if ActiveInteractions[id] then
                    ActiveInteractions[id] = nil
                    
                    if not interact.offScreen then
                        SendNUIMessage({ action = "hide", id = id })
                        interact.offScreen = true
                    end

                    if holdState.ownerId == id then
                        holdState.active = false
                        holdState.completed = false
                        holdState.ownerId = nil
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

-- === FAST LOOP === --
function InteractionsLoop()
    GlobalThreadActive = true
    while true do
        local count = 0
        local itemsToRemove = {} 
        
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

        local isPaused = IsPauseMenuActive()

        if next(ActiveInteractions) then
            for id, interact in pairs(ActiveInteractions) do
                count = count + 1
                local dist = #(plyCoords - interact.data.coords)
                local maxDist = interact.data.maxDistance or 5.0

                if maxDist < interact.data.distance then
                    maxDist = interact.data.distance + 2.0
                end

                if dist <= maxDist then
                    DrawInteract(id, interact, plyCoords, camCoords, camForward, dist, isPaused)
                else
                    if interact.static then
                        if not interact.offScreen then
                            SendNUIMessage({ action = "hide", id = id })
                            interact.offScreen = true
                        end
                        interact.keysReleased = false
                    else
                        table.insert(itemsToRemove, id)
                    end
                end
            end
        end

        for _, id in ipairs(itemsToRemove) do
            Interface.HideTextUi3d(id, true)
        end

        if count == 0 then
            GlobalThreadActive = false
            break 
        end
        
        Wait(0)
    end
end

Interface.ShowTextUi3d = function(data, static)
    local invoked = GetInvokingResource()
    local id = GenerateID(data)

    if GlobalInteractions[id] then
        GlobalInteractions[id].data = data
        GlobalInteractions[id].static = static
        GlobalInteractions[id].invoked = invoked
    else
        GlobalInteractions[id] = {
            data = data,
            static = static,
            invoked = invoked,
            offScreen = true,
            keysReleased = false
        }
    end

    local dist = #(GetEntityCoords(PlayerPedId()) - data.coords)
    if dist <= CULLING_DISTANCE then
        ActiveInteractions[id] = GlobalInteractions[id]
        if not GlobalThreadActive then
            CreateThread(InteractionsLoop)
        end
    end

    if not CullingThreadActive then
        CreateThread(CullingLoop)
    end

    return id
end

Interface.HideTextUi3d = function(id, force)
    if id and GlobalInteractions[id] then
        local interact = GlobalInteractions[id]
        
        if interact.static and not force then
            if not interact.offScreen then
                SendNUIMessage({ action = "hide", id = id })
                interact.offScreen = true
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

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        GlobalInteractions = {}
        ActiveInteractions = {}
        SendNUIMessage({ action = "hideAll" })
    else
        for i, v in pairs(GlobalInteractions) do
            if v.invoked == resourceName then
                Interface.RemoveTextUi3d(i, true)
            end
        end
    end
end)

--[[
local intId = Interface.RegisterTextUi3d({
    coords = vector3(target.x, target.y, target.z),
    distance = 6.0,
    maxDistance = 10.0,
    scale = 0.9,
    options = {
        { 
            key = 38,
            keyName = 'E',
            label = 'Shipment',
            isVisible = function() -- if not defined then default is true
                return true
            end,
            canInteract = function()  -- if not defined then default is true
                return true
            end,
            action = function()
                -- if visible and canInteract and control IsControlJustReleased
            end
        },
    }
}
]]