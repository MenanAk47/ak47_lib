local activeBars = {}
local isLoopActive = false
local barCounter = 0

-- =========================================================================
--                                 HELPERS
-- =========================================================================

local function GetUniqueId()
    barCounter = barCounter + 1
    return string.format("pb_%s_%s", GetGameTimer(), barCounter)
end

local function StartGlobalLoop()
    if isLoopActive then return end
    isLoopActive = true
    
    CreateThread(function()
        while isLoopActive do
            if next(activeBars) == nil then
                isLoopActive = false
                break
            end
            
            local ped = PlayerPedId()
            local plyCoords = GetEntityCoords(ped)
            
            for id, bar in pairs(activeBars) do
                if bar.data.is3d then
                    local targetCoords = bar.data.coords
                    local dist = #(plyCoords - targetCoords)
                    local maxDist = bar.data.distance or 10.0
                    
                    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(targetCoords.x, targetCoords.y, targetCoords.z)
                    local isVisible = onScreen and (dist <= maxDist) and (screenX >= -0.1 and screenX <= 1.1) and (screenY >= -0.1 and screenY <= 1.1)

                    if isVisible then
                         SendNUIMessage({
                            action = "progressbar",
                            command = "updatePosition",
                            id = id,
                            x = screenX,
                            y = screenY,
                            visible = true
                        })
                    else
                        if bar.lastVisible then
                            SendNUIMessage({
                                action = "progressbar",
                                command = "updatePosition",
                                id = id,
                                visible = false
                            })
                        end
                    end
                    
                    bar.lastVisible = isVisible
                end
            end
            
            Wait(0)
        end
    end)
end

-- =========================================================================
--                           INTERNAL CLASS
-- =========================================================================

local ProgressObject = {}
ProgressObject.__index = ProgressObject

function ProgressObject:show()
    if self.active then return self end
    self.active = true
    self.invoked = GetInvokingResource()
    
    activeBars[self.id] = self
    
    local ped = PlayerPedId()
    local data = self.data

    if data.prop then
        local props = data.prop
        if props.model then props = { props } end
        
        for _, propData in pairs(props) do
            local model = type(propData.model) == 'number' and propData.model or GetHashKey(propData.model)
            if IsModelInCdimage(model) then
                RequestModel(model)
                while not HasModelLoaded(model) do Wait(0) end

                local pObj = CreateObject(model, 0.0, 0.0, 0.0, true, true, true)
                local boneIndex = GetPedBoneIndex(ped, propData.bone or 60309)
                local pos = propData.pos or vector3(0,0,0)
                local rot = propData.rot or vector3(0,0,0)
                
                AttachEntityToEntity(pObj, ped, boneIndex, 
                    pos.x, pos.y, pos.z, 
                    rot.x, rot.y, rot.z, 
                    true, true, false, true, propData.rotOrder or 0, true
                )
                SetModelAsNoLongerNeeded(model)
                table.insert(self.propObjects, pObj)
            end
        end
    end

    if data.anim then
        if data.anim.dict then
            RequestAnimDict(data.anim.dict)
            while not HasAnimDictLoaded(data.anim.dict) do Wait(0) end
            TaskPlayAnim(ped, data.anim.dict, data.anim.clip, 
                data.anim.blendIn or 3.0, 
                data.anim.blendOut or 1.0, 
                data.anim.duration or -1, 
                data.anim.flag or 49, 
                0, false, false, false
            )
        elseif data.anim.scenario then
            TaskStartScenarioInPlace(ped, data.anim.scenario, 0, true)
        end
    end

    local initX, initY = 0.5, 0.5
    local initVisible = true 

    if data.is3d then
        local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(data.coords.x, data.coords.y, data.coords.z)
        local dist = #(GetEntityCoords(ped) - data.coords)
        local maxDist = data.distance or 10.0

        initX = screenX
        initY = screenY

        local isVisible = onScreen and (dist <= maxDist) and (screenX >= -0.1 and screenX <= 1.1) and (screenY >= -0.1 and screenY <= 1.1)
        initVisible = isVisible
        StartGlobalLoop()
    end

    SendNUIMessage({
        action = "progressbar",
        command = "create",
        id = self.id,
        label = data.label,
        duration = data.duration,
        type = data.type,
        manual = data.manual,
        initial = data.initial or (data.reverse and 100 or 0),
        is3d = data.is3d,
        x = initX,
        y = initY,
        visible = initVisible
    })

    return self
end

function ProgressObject:update(value)
    if not self.active then return self end
    if value < 0 then value = 0 end
    if value > 100 then value = 100 end
    
    SendNUIMessage({
        action = "progressbar",
        command = "update",
        id = self.id,
        value = value
    })
    return self
end

function ProgressObject:destroy()
    if not self.active then return nil end
    
    for _, prop in pairs(self.propObjects) do
        if DoesEntityExist(prop) then
            DetachEntity(prop, true, true)
            DeleteObject(prop)
        end
    end
    self.propObjects = {}
    
    if self.data.anim then
        ClearPedTasks(PlayerPedId())
    end

    SendNUIMessage({
        action = "progressbar",
        command = "remove",
        id = self.id
    })

    activeBars[self.id] = nil
    self.active = false
    return nil
end

-- =========================================================================
--                            INTERFACE / EXPORTS
-- =========================================================================

Interface.CreateProgress = function(data)
    local id = data.id or GetUniqueId()
    
    data.duration = data.duration or 3000
    data.label = data.label or "Progress"
    data.type = data.type or "capsule"
    data.manual = data.manual == true
    data.reverse = data.reverse == true
    data.is3d = data.is3d == true
    
    if data.useWhileDead == nil then data.useWhileDead = false end
    if data.allowSwimming == nil then data.allowSwimming = false end
    if data.allowFalling == nil then data.allowFalling = false end
    if data.allowRagdoll == nil then data.allowRagdoll = false end
    
    if data.is3d then
        if not data.coords then data.coords = GetEntityCoords(PlayerPedId()) end
        data.distance = data.distance or 10.0
    end

    local internalInstance = setmetatable({
        id = id,
        data = data,
        active = false,
        propObjects = {},
        lastVisible = false
    }, ProgressObject)

    local publicWrapper = {
        id = id,
        show = function(self) internalInstance:show() return self end,
        update = function(self, val) internalInstance:update(val) return self end,
        destroy = function(self) internalInstance:destroy() return nil end
    }

    return publicWrapper
end

Interface.ShowProgress = function(data, onFinish, onCancel)
    for _, v in pairs(activeBars) do
        if not v.data.is3d then 
            return nil 
        end
    end
    
    local bar = Interface.CreateProgress(data)
    bar.show()

    CreateThread(function()
        local startTime = GetGameTimer()
        local cancelled = false
        local completed = false
        local ped = PlayerPedId()
        
        while activeBars[bar.id] do
            if not data.manual then
                if (GetGameTimer() - startTime) >= data.duration then
                    completed = true
                    break
                end
            end
            
            if data.canCancel and IsControlJustPressed(0, 73) then 
                cancelled = true
                break
            end
            
            if data.useWhileDead == false and IsEntityDead(ped) then cancelled = true break end
            if data.allowSwimming == false and IsPedSwimming(ped) then cancelled = true break end
            if data.allowFalling == false and IsPedFalling(ped) then cancelled = true break end
            if data.allowRagdoll == false and IsPedRagdoll(ped) then cancelled = true break end

            if data.disable then
                if data.disable.move then
                    DisableControlAction(0, 30, true) -- Move LR
                    DisableControlAction(0, 31, true) -- Move UD
                    DisableControlAction(0, 22, true) -- Jump
                    DisableControlAction(0, 44, true) -- Cover
                end
                if data.disable.mouse then
                    DisableControlAction(0, 1, true) -- Look LR
                    DisableControlAction(0, 2, true) -- Look UD
                end
                if data.disable.combat then
                    DisableControlAction(0, 24, true) -- Attack
                    DisableControlAction(0, 25, true) -- Aim
                    DisableControlAction(0, 47, true) -- Weapon
                    DisableControlAction(0, 58, true) -- Weapon
                    DisablePlayerFiring(PlayerId(), true)
                end
                if data.disable.car then
                    DisableControlAction(0, 75, true) -- Exit Vehicle
                    DisableControlAction(0, 23, true) -- Enter Vehicle
                end
                if data.disable.sprint then
                    DisableControlAction(0, 21, true) -- Sprint
                end
            end

            Wait(0)
        end
        
        bar.destroy()
        
        if cancelled then
            if onCancel then onCancel() end
        elseif completed then
            if onFinish then onFinish() end
        end
    end)
    
    return bar
end

Interface.CancelProgress = function()
    for id, pObject in pairs(activeBars) do
        if not pObject.data.is3d then
            pObject:destroy()
        end
    end
end

exports('CreateProgress', Interface.CreateProgress)
exports('ShowProgress', Interface.ShowProgress)
exports('CancelProgress', Interface.CancelProgress)

Lib47.CreateProgress = Interface.CreateProgress

AddEventHandler('onResourceStop', function(resourceName)
    for i, v in pairs(activeBars) do
        if v.invoked == resourceName then
            v:destroy()
        end
    end
end)

-- =========================================================================
--                             COMMANDS
-- =========================================================================

RegisterCommand('pbar_wrapper_test', function()
    local pCoords = GetEntityCoords(PlayerPedId())
    
    -- 1. Create via Interface
    local bar = Interface.CreateProgress({
        label = "Wrapper Test",
        is3d = true,
        coords = pCoords + vector3(2.0, 2.0, 0.0),
        manual = true
    })
    
    -- 2. Show
    bar.show()
    
    -- 3. Update Loop
    CreateThread(function()
        local val = 0
        while val < 100 do
            val = val + 1
            bar.update(val)
            Wait(50)
        end
        bar.destroy()
    end)
end)