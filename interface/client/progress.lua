local isDoingAction = false
local ActionData = {}
local propObjects = {}

Interface.CleanupProgress = function()
    local ped = PlayerPedId()
    if ActionData.anim then
        if ActionData.anim.dict then
            StopAnimTask(ped, ActionData.anim.dict, ActionData.anim.clip, 1.0)
        elseif ActionData.anim.scenario then
            ClearPedTasks(ped)
        end
    end
    
    for _, prop in pairs(propObjects) do
        if DoesEntityExist(prop) then
            DetachEntity(prop, true, true)
            DeleteObject(prop)
        end
    end
    propObjects = {}
    isDoingAction = false
end

local function ValidateProgressData(data)
    if type(data) ~= 'table' then return nil end

    data.duration = (type(data.duration) == 'number' and data.duration > 0) and data.duration or 3000
    data.label = type(data.label) == 'string' and data.label or 'Progress'
    data.useWhileDead = data.useWhileDead == true
    data.allowSwimming = data.allowSwimming == true
    data.allowFalling = data.allowFalling == true
    data.allowRagdoll = data.allowRagdoll == true
    data.canCancel = data.canCancel == true

    if data.anim then
        if type(data.anim) ~= 'table' then
            data.anim = nil
        else
            if data.anim.dict then
                if not data.anim.clip then
                    data.anim = nil
                else
                    data.anim.blendIn = type(data.anim.blendIn) == 'number' and data.anim.blendIn or 3.0
                    data.anim.blendOut = type(data.anim.blendOut) == 'number' and data.anim.blendOut or 1.0
                    data.anim.duration = type(data.anim.duration) == 'number' and data.anim.duration or -1
                    data.anim.flag = type(data.anim.flag) == 'number' and data.anim.flag or 49
                    data.anim.playbackRate = type(data.anim.playbackRate) == 'number' and data.anim.playbackRate or 0.0
                    data.anim.lockX = data.anim.lockX == true
                    data.anim.lockY = data.anim.lockY == true
                    data.anim.lockZ = data.anim.lockZ == true
                end
            elseif data.anim.scenario then
                 data.anim.playEnter = data.anim.playEnter ~= false
            else
                data.anim = nil
            end
        end
    end

    if data.prop then
        if data.prop.model then
            data.prop = { data.prop }
        end

        local validatedProps = {}
        for _, prop in pairs(data.prop) do
            if prop.model then
                prop.bone = type(prop.bone) == 'number' and prop.bone or 60309
                prop.pos = type(prop.pos) == 'vector3' and prop.pos or vec3(0.0, 0.0, 0.0)
                prop.rot = type(prop.rot) == 'vector3' and prop.rot or vec3(0.0, 0.0, 0.0)
                prop.rotOrder = type(prop.rotOrder) == 'number' and prop.rotOrder or 0
                table.insert(validatedProps, prop)
            end
        end
        data.prop = validatedProps
    end

    if data.disable then
        if type(data.disable) ~= 'table' then data.disable = {} end
        data.disable.move = data.disable.move == true
        data.disable.mouse = data.disable.mouse == true
        data.disable.combat = data.disable.combat == true
        data.disable.car = data.disable.car == true
        data.disable.sprint = data.disable.sprint == true
    else
        data.disable = {}
    end

    return data
end

Interface.StartProgress = function(data, onFinish, onCancel)
    if isDoingAction then return end

    data = ValidateProgressData(data)
    if not data then return end

    local ped = PlayerPedId()

    if not data.useWhileDead and IsEntityDead(ped) then return end
    if not data.allowSwimming and IsPedSwimming(ped) then return end
    if not data.allowFalling and IsPedFalling(ped) then return end
    if not data.allowRagdoll and IsPedRagdoll(ped) then return end
    
    isDoingAction = true
    ActionData = data
    propObjects = {}

    if data.anim then
        if data.anim.dict then
            RequestAnimDict(data.anim.dict)
            while not HasAnimDictLoaded(data.anim.dict) do Wait(0) end
            
            TaskPlayAnim(ped, data.anim.dict, data.anim.clip, data.anim.blendIn, data.anim.blendOut, data.anim.duration, data.anim.flag, data.anim.playbackRate, data.anim.lockX, data.anim.lockY, data.anim.lockZ)
        elseif data.anim.scenario then
            TaskStartScenarioInPlace(ped, data.anim.scenario, 0, data.anim.playEnter)
        end
    end

    if data.prop then
        for _, propData in pairs(data.prop) do
            local model = type(propData.model) == 'number' and propData.model or GetHashKey(propData.model)
            RequestModel(model)
            while not HasModelLoaded(model) do Wait(0) end

            local pObj = CreateObject(model, 0.0, 0.0, 0.0, true, true, true)
            AttachEntityToEntity(pObj, ped, GetPedBoneIndex(ped, propData.bone), 
                propData.pos.x, propData.pos.y, propData.pos.z, 
                propData.rot.x, propData.rot.y, propData.rot.z, 
                true, true, false, true, propData.rotOrder, true
            )
            SetModelAsNoLongerNeeded(model)
            table.insert(propObjects, pObj)
        end
    end

    SendNUIMessage({
        action = "progressbar",
        command = "start",
        duration = data.duration,
        label = data.label,
        type = data.type or "capsule"
    })

    local startTime = GetGameTimer()
    local completed = false
    local cancelled = false

    while isDoingAction do
        if (GetGameTimer() - startTime) >= data.duration then
            completed = true
            break
        end

        if data.canCancel and IsControlJustPressed(0, 73) then -- X
            cancelled = true
            break
        end

        if not data.useWhileDead and Lib47.IsIncapacitated() then cancelled = true break end
        if not data.allowRagdoll and IsPedRagdoll(ped) then cancelled = true break end
        if not data.allowSwimming and IsPedSwimming(ped) then cancelled = true break end
        if not data.allowFalling and IsPedFalling(ped) then cancelled = true break end
        
        if data.disable.move then 
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 36, true)
        end
        if data.disable.mouse then 
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 106, true)
        end
        if data.disable.combat then 
            DisablePlayerFiring(PlayerId(), true) 
            DisableControlAction(0, 25, true)
        end
        if data.disable.car then 
            DisableControlAction(0, 63, true)
            DisableControlAction(0, 64, true)
            DisableControlAction(0, 71, true)
            DisableControlAction(0, 72, true)
            DisableControlAction(0, 75, true)
        end
        if data.disable.sprint and not data.disable.move then
            DisableControlAction(0, 21, true)
        end

        Wait(0)
    end

    Interface.CleanupProgress()
    SendNUIMessage({ action = "progressbar", command = "cancel" })

    if cancelled then
        if onCancel then onCancel() end
    elseif completed then
        if onFinish then onFinish() end
    end

    return completed
end

exports('StartProgress', Interface.StartProgress)

RegisterCommand('testbar', function(_, args)
    Interface.StartProgress({
        duration = 10000,
        label = "Drinking",
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, combat = true },
        type = args[1],
    }, function()
        print("Success")
        ClearPedTasks(PlayerPedId())
    end, function()
        print("Cancelled")
        ClearPedTasks(PlayerPedId())
    end)
end)