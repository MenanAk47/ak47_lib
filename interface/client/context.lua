local registeredMenus = {}
local activeMenuId = nil
local contextState = { visible = false, invoked = nil }
local menuHistoryStack = {}
local keyboardOnly = true
local keyboardThreadActive = false

-- ==========================================
-- KEYBOARD THREAD (LUA NUI NAVIGATION)
-- ==========================================
local function StartKeyboardThread()
    if keyboardThreadActive then return end
    keyboardThreadActive = true

    CreateThread(function()
        while contextState.visible and keyboardOnly do
            Wait(0)
            
            -- Disable some specific game controls if you want to prevent attacking/pausing 
            -- while the menu is open (Optional but recommended)
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 257, true) -- Attack 2
            
            -- Arrow Up (172 / INPUT_CELLPHONE_UP)
            if IsControlJustPressed(0, 172) then
                SendNUIMessage({ action = 'CONTEXT_CONTROL', key = 'ArrowUp' })
            end
            
            -- Arrow Down (173 / INPUT_CELLPHONE_DOWN)
            if IsControlJustPressed(0, 173) then
                SendNUIMessage({ action = 'CONTEXT_CONTROL', key = 'ArrowDown' })
            end
            
            -- Enter / Select (176 / INPUT_CELLPHONE_SELECT or 18 / INPUT_ENTER)
            if IsControlJustPressed(0, 176) or IsControlJustPressed(0, 18) then
                SendNUIMessage({ action = 'CONTEXT_CONTROL', key = 'Enter' })
            end
            
            -- Back / Cancel (177 / INPUT_CELLPHONE_CANCEL or 200 / INPUT_FRONTEND_PAUSE_ALTERNATE or 194)
            if IsControlJustPressed(0, 177) or IsControlJustPressed(0, 194) or IsControlJustPressed(0, 200) then
                SendNUIMessage({ action = 'CONTEXT_CONTROL', key = 'Backspace' })
            end
        end
        keyboardThreadActive = false
    end)
end

Interface.RegisterContext = function(data)
    if not data or type(data) ~= 'table' or not data.id then 
        print("^1[Lib47] RegisterContext failed: Missing menu ID.^7")
        return 
    end
    registeredMenus[data.id] = data
end

Interface.ShowContext = function(id, keyOnly, navOpts)
    navOpts = navOpts or {}
    keyboardOnly = keyOnly
    
    local menuConfig = registeredMenus[id]
    if not menuConfig then 
        print("^1[Lib47] ShowContext failed: Menu ID '" .. tostring(id) .. "' not found.^7")
        return 
    end

    contextState.invoked = GetInvokingResource()
    contextState.visible = true
    activeMenuId = id

    if keyboardOnly then
        SetNuiFocus(false, false)
        StartKeyboardThread()
    else
        SetNuiFocus(true, true)
    end

    local title = menuConfig.title or Config.Defaults.ContextMenu.title
    local position = menuConfig.position or Config.Defaults.ContextMenu.position
    local canClose = menuConfig.canClose
    if canClose == nil then canClose = Config.Defaults.ContextMenu.canClose end
    
    local colors = menuConfig.colors or Config.Defaults.ContextMenu.colors
    local borders = menuConfig.borders or Config.Defaults.ContextMenu.borders
    local size = menuConfig.size or Config.Defaults.ContextMenu.size

    local nuiData = {
        id = menuConfig.id,
        title = title,
        position = position,
        menu = menuConfig.menu,
        canClose = canClose,
        colors = colors,
        borders = borders,
        size = size,
        focusIndex = navOpts.focusIndex, 
        isForward = navOpts.isForward,   
        keyboardOnly = keyboardOnly, -- ADDED: Pass this to React so it auto-focuses
        options = {}
    }

    for i, opt in ipairs(menuConfig.options) do
        nuiData.options[i] = {
            title = opt.title,
            description = opt.description,
            disabled = opt.disabled,
            readOnly = opt.readOnly,
            menu = opt.menu,
            icon = opt.icon,
            iconColor = opt.iconColor,
            iconAnimation = opt.iconAnimation,
            progress = opt.progress,
            colorScheme = opt.colorScheme,
            arrow = opt.arrow,
            image = opt.image,
            metadata = opt.metadata
        }
    end

    SendNUIMessage({
        action = 'OPEN_CONTEXT_MENU',
        data = nuiData
    })
end

Interface.HideContext = function()
    if not keyboardOnly then
        SetNuiFocus(false, false)
    end
    contextState.visible = false
    activeMenuId = nil
    menuHistoryStack = {}
    SendNUIMessage({ action = 'CLOSE_CONTEXT_MENU' })
end

RegisterNUICallback('contextAction', function(data, cb)
    if not activeMenuId then cb('ok'); return end

    local menu = registeredMenus[activeMenuId]
    if not menu then cb('ok'); return end

    local index = data.index + 1
    local option = menu.options[index]

    if not option then cb('ok'); return end

    if option.onSelect then option.onSelect(option.args) end
    if option.event then TriggerEvent(option.event, option.args) end
    if option.serverEvent then TriggerServerEvent(option.serverEvent, option.args) end

    -- Navigation routing
    if option.menu then
        table.insert(menuHistoryStack, { id = activeMenuId, index = data.index })
        Interface.ShowContext(option.menu, keyboardOnly, { isForward = true })
    else
        Interface.HideContext()
    end

    cb('ok')
end)

RegisterNUICallback('contextExit', function(_, cb)
    if activeMenuId then
        local menu = registeredMenus[activeMenuId]
        if menu and menu.onExit then
            menu.onExit()
        end
    end
    Interface.HideContext()
    cb('ok')
end)

RegisterNUICallback('contextBack', function(_, cb)
    if activeMenuId then
        local menu = registeredMenus[activeMenuId]
        if menu then
            if menu.onBack then menu.onBack() end
            if menu.menu then
                local prevHistory = table.remove(menuHistoryStack)
                local focusIndex = nil
                
                if prevHistory and prevHistory.id == menu.menu then
                    focusIndex = prevHistory.index
                else
                    menuHistoryStack = {}
                end

                Interface.ShowContext(menu.menu, keyboardOnly, { focusIndex = focusIndex })
            end
        end
    end
    cb('ok')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if contextState.visible and contextState.invoked == resourceName then
        Interface.HideContext()
    end
end)

exports('RegisterContext', Interface.RegisterContext)
exports('ShowContext', Interface.ShowContext)
exports('HideContext', Interface.HideContext)

--================== Example ====================

RegisterNetEvent('my_custom_client_event', function(args)
    print("Client Event Triggered!")
    print("Received Weapon:", args.weapon)
    print("Received Ammo:", args.ammo)
end)

RegisterNetEvent('my_custom_server_event', function(args)
    print("Server Event Triggered with ID:", args.id)
end)

Lib47.RegisterContext({
    id = 'main_context_menu',
    title = 'Player Actions', 
    position = 'top-right',
    canClose = true,
    onExit = function()
        print("User closed the main menu with ESC")
    end,
    options = {
        {
            title = 'Heal Player',
            description = 'Restores health to **100%**',
            icon = 'heart',
            iconColor = '#ff5555',
            onSelect = function() print("Heal button pressed!") end
        },
        {
            title = 'Vehicle Management',
            description = 'Open vehicle options menu',
            icon = 'car',
            menu = 'sub_context_menu',
            arrow = true
        },
        {
            title = 'Downloading Data...',
            description = 'Extracting files from server',
            icon = 'spinner',
            iconAnimation = 'spin',
            progress = 65,
            colorScheme = '#00a8ff',
            readOnly = true 
        },
        {
            title = 'Admin Panel',
            description = 'You do not have permission',
            icon = 'lock',
            disabled = true 
        },
        {
            title = 'Give Weapon',
            description = 'Triggers a client event to give a weapon',
            icon = 'nui://ak47_qb_inventory/web/build/images/weapon_pistol.png', 
            event = 'my_custom_client_event',
            args = { weapon = 'WEAPON_PISTOL', ammo = 250 }
        },
        {
            title = 'Pay Parking Ticket',
            description = 'Deducts $500 via server event',
            icon = 'file-invoice-dollar',
            iconColor = '#4cd137',
            serverEvent = 'my_custom_server_event',
            args = { id = 101, amount = 500 }
        },
        {
            title = 'Inspect Vehicle Details',
            description = 'Hover to view vehicle statistics',
            icon = 'magnifying-glass',
            image = 'https://docs.fivem.net/vehicles/t20.webp',
            metadata = {
                { label = 'Model', value = 'T20' },
                { label = 'Plate', value = 'LIB47DEV' },
                { label = 'Engine Health', value = '85%', progress = 85, colorScheme = '#fbc531' },
                { label = 'Fuel Level', value = '20%', progress = 20, colorScheme = '#e84118' }
            },
            onSelect = function() print("Inspected vehicle!") end
        },
    }
})

Lib47.RegisterContext({
    id = 'sub_context_menu',
    title = 'Vehicle Options',
    position = 'top-right',
    menu = 'main_context_menu', 
    onBack = function() print("User clicked the back arrow to return to Player Actions") end,
    options = {
        {
            title = 'Toggle Engine',
            icon = 'power-off',
            iconColor = '#e1b12c',
            onSelect = function() print("Engine toggled!") end
        },
        {
            title = 'Lock Doors',
            icon = 'key',
            onSelect = function() print("Doors locked!") end
        }
    }
})

RegisterCommand('testmenu', function()
    -- Set keyboardOnly to true to test the arrow keys without mouse focus
    Lib47.ShowContext('main_context_menu')
end)