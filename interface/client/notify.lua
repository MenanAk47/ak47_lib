-- Configuration: Default Titles mapped to Types
local defaultTitles = {
    inform = "INFO",
    success = "SUCCESS",
    warning = "WARNING",
    error = "ERROR"
}

-- Configuration: Default Icons mapped to Types
local defaultIcons = {
    inform = "fa-circle-info",
    success = "fa-circle-check",
    warning = "fa-triangle-exclamation",
    error = "fa-circle-xmark"
}

-- Valid Positions Lookup
local validPositions = {
    ['top-left'] = true, ['top-right'] = true, ['top-center'] = true,
    ['bottom-left'] = true, ['bottom-right'] = true, ['bottom-center'] = true,
    ['center-left'] = true, ['center-right'] = true
}

local function playNotificationSound(soundData)
    if not soundData then return end
    if soundData.name and soundData.set then
        PlaySoundFrontend(-1, soundData.name, soundData.set, true)
    elseif soundData.name then
        PlaySoundFrontend(-1, soundData.name, "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
end

local function SendNotification(data)
    if not data then data = {} end

    -- 1. Validate Type (Default: 'inform')
    local msgType = data.type
    if not msgType or not defaultTitles[msgType] then
        msgType = 'inform'
    end

    -- 2. Validate/Set Default Title
    local title = data.title
    if not title or title == "" then
        title = defaultTitles[msgType]
    end

    -- 3. Validate/Set Default Icon
    local icon = data.icon
    if not icon or icon == "" then
        icon = defaultIcons[msgType]
    end

    -- 4. Validate Position (Default: 'top-right')
    local position = data.position
    if not position or not validPositions[position] then
        position = 'center-right'
    end

    -- 5. Validate Duration (Default: 3000)
    local duration = tonumber(data.duration)
    if not duration then duration = 8000 end

    -- 6. Handle Style (String vs Table)
    local styleName = 'minimal'
    local customStyle = nil

    if type(data.style) == 'string' then
        styleName = data.style
    elseif type(data.style) == 'table' then
        customStyle = data.style
        styleName = 'minimal' -- Fallback base class if custom CSS is passed
    end

    -- Construct Final Payload
    local payload = {
        id = data.id,
        title = title,
        description = data.description,
        duration = duration,
        showDuration = (data.showDuration ~= false),
        position = position,
        type = msgType,
        styleName = styleName,
        style = customStyle,
        icon = icon,
        iconColor = data.iconColor,
        iconAnimation = data.iconAnimation,
        alignIcon = data.alignIcon or 'center'
    }

    -- Play Sound
    if data.sound then
        playNotificationSound(data.sound)
    end

    -- Send to React
    SendNUIMessage({
        action = 'notification',
        data = payload
    })
end

-- Export
exports('Notify', SendNotification)

-- Event
RegisterNetEvent('notify:client:send')
AddEventHandler('notify:client:send', function(data)
    SendNotification(data)
end)

-- Test Command
RegisterCommand('testnotify', function()
    -- This test has no Title and no Icon. 
    -- It should default to Title: "WARNING" and Icon: "fa-triangle-exclamation"
    exports[GetCurrentResourceName()]:Notify({
        description = "Battery level critical.",
        type = "warning",
        style = "minimal",
        duration = 5000,
    })
end)