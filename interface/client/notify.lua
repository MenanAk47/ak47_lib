local defaultTitles = {
    inform = "INFO",
    success = "SUCCESS",
    warning = "WARNING",
    error = "ERROR"
}

local defaultIcons = {
    inform = "fa-circle-info",
    success = "fa-circle-check",
    warning = "fa-triangle-exclamation",
    error = "fa-circle-xmark"
}

local validPositions = {
    ['top-left'] = true, ['top-right'] = true, ['top-center'] = true,
    ['bottom-left'] = true, ['bottom-right'] = true, ['bottom-center'] = true,
    ['center-left'] = true, ['center-right'] = true
}

local validStyles = {
    ['minimal'] = true, ['frost'] = true, ['frost-fade'] = true,
    ['glass'] = true, ['glow-dot'] = true, ['vertical-line'] = true,
}

Interface.Notify = function(data)
    if not data then data = {} end
    
    local msgType = data.type
    if not msgType or not defaultTitles[msgType] then
        msgType = Config.Defaults.type
    end

    local title = data.title
    if not title or title == "" then
        title = defaultTitles[msgType]
    end

    local icon = data.icon
    if not icon or icon == "" then
        icon = defaultIcons[msgType]
    end

    local position = data.position
    if not position or not validPositions[position] then
        position = Config.Defaults.position
    end

    local duration = tonumber(data.duration)
    if not duration then 
        duration = Config.Defaults.duration 
    end

    local styleName = Config.Defaults.style
    local customStyle = nil
    if type(data.style) == 'string' then
        styleName = validStyles[data.style] or 'minimal'
    elseif type(data.style) == 'table' then
        customStyle = data.style
        styleName = 'minimal'
    end

    local sound = nil
    if data.sound then
        if type(data.sound) == 'boolean' then
            data.sound = './sounds/notify.mp3'
        end
    end

    local hour = GetClockHours()
    local isNight = Config.Defaults.nightEffect and (hour >= 21 or hour < 6)

    local payload = {
        id = data.id,
        title = title,
        description = data.description,
        duration = duration,
        showDuration = (data.showDuration ~= false),
        position = position,
        type = msgType,
        sound = sound,
        styleName = styleName,
        style = customStyle,
        icon = icon,
        iconColor = data.iconColor,
        iconAnimation = data.iconAnimation,
        alignIcon = data.alignIcon or 'center',
        isNight = isNight,
    }

    SendNUIMessage({
        action = 'notification',
        data = payload
    })

    if data.sound then
        local soundData = Interface.CreateSound({
            url = data.sound,
            volume = 0.2,
        })
        soundData:play()
    end
end

-- Export
exports('Notify', Interface.Notify)

-- Test Command
RegisterCommand('testnotify', function(_, args)
    exports[GetCurrentResourceName()]:Notify({
        description = "This is a multi-line supported test notification modern UI!",
        type = "success",
        style = args[1],
        position = "top-center",
        duration = tonumber(args[2]) or 8000,
        sound = true
    })

    exports[GetCurrentResourceName()]:Notify({
        description = "This is a multi-line supported test notification modern UI!",
        type = "warning",
        style = args[1],
        position = "top-right",
        duration = tonumber(args[2]) or 8000,
        sound = true
    }) 
    exports[GetCurrentResourceName()]:Notify({
        description = "This is a multi-line supported test notification modern UI!",
        type = "warning",
        style = args[1],
        position = "center-right",
        duration = tonumber(args[2]) or 8000,
        sound = true
    })
    exports[GetCurrentResourceName()]:Notify({
        description = "This is a multi-line supported test notification modern UI!",
        type = "warning",
        style = args[1],
        position = "bottom-right",
        duration = tonumber(args[2]) or 8000,
        sound = true
    })

    exports[GetCurrentResourceName()]:Notify({
        description = "This is a multi-line supported test notification modern UI!",
        type = "inform",
        style = args[1],
        position = "top-left",
        duration = tonumber(args[2]) or 8000,
        sound = true
    })
    exports[GetCurrentResourceName()]:Notify({
        description = "This is a multi-line supported test notification modern UI!",
        type = "inform",
        style = args[1],
        position = "center-left",
        duration = tonumber(args[2]) or 8000,
        sound = true
    })
    exports[GetCurrentResourceName()]:Notify({
        description = "This is a multi-line supported test notification modern UI!",
        type = "inform",
        style = args[1],
        position = "bottom-left",
        duration = tonumber(args[2]) or 8000,
        sound = true
    })

    exports[GetCurrentResourceName()]:Notify({
        description = "This is a multi-line supported test notification modern UI!",
        type = "error",
        style = args[1],
        position = "bottom-center",
        duration = tonumber(args[2]) or 8000,
        sound = true
    })
end)