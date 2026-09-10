local ActiveTextUI = nil
local NUI_ID = "2d_text_ui"

Interface.ShowTextUi = function(data)
    if type(data) == 'string' then
        data = { options = { { label = data } } }
    end

    ActiveTextUI = {
        data = data,
        invoked = GetInvokingResource()
    }

    local options = data.options or {}
    local nuiOptions = {}

    for i, opt in ipairs(options) do
        local keyName = opt.keyName
        if not keyName and opt.key and Lib47.Keys and Lib47.Keys[opt.key] then
            keyName = Lib47.Keys[opt.key].keyboard
        end

        table.insert(nuiOptions, {
            originalIndex = i,
            label = opt.label,
            key = keyName,
            progress = 0,
            activeBump = false,
            disabled = false,
            hold = 0
        })
    end

    local pos = data.position or (Config.Defaults.TextUI and Config.Defaults.TextUI.position) or 'center-left'

    SendNUIMessage({
        action = "display",
        id = NUI_ID,
        position = pos,
        options = nuiOptions,
        mode = "full", 
        arc = false, 
        scale = data.scale or 0.8
    })
end

Interface.HideTextUi = function(key)
    if not ActiveTextUI then return end

    local currentUI = ActiveTextUI
    ActiveTextUI = nil

    if key and currentUI.data and currentUI.data.options then
        local targetKeyStr = tostring(key):upper()
        if type(key) == 'number' and Lib47.Keys and Lib47.Keys[key] then
            targetKeyStr = (Lib47.Keys[key].keyboard or ''):upper()
        end

        local nuiOptions = {}
        local found = false

        for i, opt in ipairs(currentUI.data.options) do
            local keyName = opt.keyName
            if not keyName and opt.key and Lib47.Keys and Lib47.Keys[opt.key] then
                keyName = Lib47.Keys[opt.key].keyboard
            end

            local isMatch = false
            if opt.key and opt.key == key then
                isMatch = true
            elseif keyName and keyName:upper() == targetKeyStr then
                isMatch = true
            elseif opt.keyName and opt.keyName:upper() == tostring(key):upper() then
                isMatch = true
            end

            if isMatch then
                found = true
            end

            table.insert(nuiOptions, {
                originalIndex = i,
                label = opt.label,
                key = keyName,
                progress = 0,
                activeBump = isMatch,
                disabled = false,
                hold = 0
            })
        end

        if found then
            local pos = currentUI.data.position or (Config.Defaults.TextUI and Config.Defaults.TextUI.position) or 'center-left'
            SendNUIMessage({
                action = "display",
                id = NUI_ID,
                position = pos,
                options = nuiOptions,
                mode = "full", 
                arc = false, 
                scale = currentUI.data.scale or 0.8
            })
            Wait(250)
        end
    end

    SendNUIMessage({ action = "hide", id = NUI_ID })
end

AddEventHandler('onResourceStop', function(resourceName)
    if ActiveTextUI and ActiveTextUI.invoked == resourceName then
        Interface.HideTextUi()
    end
end)

-- Example Usage (For Testing)
RegisterCommand('test2dtext', function()
    Lib47.ShowTextUi({
        position = 'center-left',
        scale = 0.8,
        options = {
            { 
                key = 38, -- 'E' key
                label = 'Interact',
            },
            {
                key = 74, -- 'H' key
                label = 'Manage',
            },
            {
                keyName = 'DELETE',
                label = 'Delete',
            }
        }
    })
end)

RegisterCommand('hide2dtext', function(source, args)
    local key = args[1]
    if key and tonumber(key) then
        key = tonumber(key)
    end
    Lib47.HideTextUi(key)
end)