Lib47.ShowProgress = function(progressData, onSuccess, onCancel)
    local result = false

    if Config.Progressbar == 'default' then
        return Interface.StartProgress(progressData, onSuccess, onCancel)
    elseif Config.Progressbar == 'ox' or Config.Progressbar == 'qbx' then
        if lib.progressCircle({
            label = progressData.label,
            position = progressData.position,
            duration = progressData.duration,
            disable = progressData.disable,
            canCancel = progressData.canCancel,
            useWhileDead = progressData.useWhileDead,
            prop = progressData.prop,
            anim = progressData.anim,
        }) then
            result = true
        else
            result = false
        end

    elseif Config.Progressbar == 'esx' and Config.Framework == 'esx' then
        local p = promise.new()
        
        local animData = {}
        if progressData.anim then
            if progressData.anim.dict then
                animData = {
                    type = 'anim',
                    dict = progressData.anim.dict,
                    lib = progressData.anim.clip
                }
            elseif progressData.anim.scenario then
                animData = {
                    type = 'scenario',
                    scenario = progressData.anim.scenario
                }
            end
        end

        ESX.Progressbar(progressData.label, progressData.duration, {
            FreezePlayer = progressData.disable and (progressData.disable.move or progressData.disable.sprint),
            animation = animData,
            onFinish = function() p:resolve(true) end,
            onCancel = function() p:resolve(false) end
        })

        result = Citizen.Await(p)

    elseif Config.Progressbar == 'qb' and Config.Framework == 'qb' then
        local p = promise.new()
        
        local propData = {}
        if progressData.prop then
            propData = {
                model = progressData.prop.model,
                bone = progressData.prop.bone,
                coords = progressData.prop.pos,
                rotation = progressData.prop.rot
            }
        end

        QBCore.Functions.Progressbar("sw_progress", progressData.label, progressData.duration, progressData.useWhileDead, progressData.canCancel, 
            {
                disableMovement = progressData.disable and (progressData.disable.move or progressData.disable.sprint),
                disableCarMovement = progressData.disable and progressData.disable.car,
                disableMouse = false,
                disableCombat = progressData.disable and progressData.disable.combat,
            }, 
            {
                animDict = progressData.anim and progressData.anim.dict,
                anim = progressData.anim and progressData.anim.clip,
                flags = progressData.anim and progressData.anim.flag,
                task = progressData.anim and progressData.anim.scenario,
            }, 
            propData,
            {},
            function()
                p:resolve(true)
            end, 
            function()
                p:resolve(false)
            end
        )

        result = Citizen.Await(p)

    elseif Config.Progressbar == 'custom' then
        -- your custom code below
        -- Ensure you set result = true (success) or result = false (cancel)

    end

    if result then
        if onSuccess then onSuccess() end
    else
        if onCancel then onCancel() end
    end

    return result
end

-- Don't change below
RegisterNetEvent('ak47_lib:client:ShowProgress', Lib47.ShowProgress)
Lib47.Callback.Register('ak47_lib:callback:client:ShowProgress', Lib47.ShowProgress)