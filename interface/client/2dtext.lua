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

Interface.HideTextUi = function()
    if ActiveTextUI then
        ActiveTextUI = nil
        SendNUIMessage({ action = "hide", id = NUI_ID })
    end
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
                label = 'Just some text',
            }
        }
    })
end)

RegisterCommand('hide2dtext', function()
    Lib47.HideTextUi()
end)