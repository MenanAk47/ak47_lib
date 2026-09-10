Lib47.ShowTextUi = function(data)
    if type(data) == 'string' then
        data = { options = { { label = data } } }
    end

    if Config.TextUI == 'default' then
        return Interface.ShowTextUi(data)
    elseif Config.TextUI == 'ox' then
        local text = ''
        local options = data.options or {}
        for i, v in ipairs(options) do
            local keyName = v.keyName
            if not keyName and v.key and Lib47.Keys and Lib47.Keys[v.key] then
                keyName = Lib47.Keys[v.key].keyboard
            end
            
            local keyStr = keyName and ('['..keyName..'] - ') or ''
            local line = keyStr .. (v.label or '')
            
            if text == '' then
                text = line
            else
                text = text .. '  \n' .. line
            end
        end
        return exports['ox_lib']:showTextUI(text)
    elseif Config.TextUI == 'custom' then
        -- your custom code below

    end
end

Lib47.HideTextUi = function(key)
    if Config.TextUI == 'default' then
        Interface.HideTextUi(key)
    elseif Config.TextUI == 'ox' then
        exports['ox_lib']:hideTextUI()
    elseif Config.TextUI == 'custom' then
        -- your custom code below

    end
end

exports('ShowTextUi', Lib47.ShowTextUi)
exports('HideTextUi', Lib47.HideTextUi)