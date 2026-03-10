local registeredMenus = {}
local activeMenuId = nil
local contextState = { visible = false, invoked = nil }
local menuHistoryStack = {}
local keyboardOnly = true
local keyboardThreadActive = false

-- ==========================================
-- DATA SANITIZER FOR NUI
-- ==========================================
local function SanitizeForNUI(data)
    local t = type(data)
    if t == 'function' then return nil end
    if t ~= 'table' then return data end
    
    local res = {}
    for k, v in pairs(data) do
        local val = SanitizeForNUI(v)
        if val ~= nil then
            res[k] = val
        end
    end
    return res
end

-- ==========================================
-- KEYBOARD THREAD (LUA NUI NAVIGATION)
-- ==========================================
local function StartKeyboardThread(disableInput)
    if keyboardThreadActive then return end
    keyboardThreadActive = true

    CreateThread(function()
        while contextState.visible and keyboardOnly do
            Wait(0)
            
            if disableInput then
                DisableAllControlActions(0)
            else
                DisableControlAction(0, 24, true) -- Attack
                DisableControlAction(0, 257, true) -- Attack 2
            end
            
            if IsDisabledControlJustPressed(0, 172) then SendNUIMessage({ action = 'CONTEXT_CONTROL', key = 'ArrowUp' }) end
            if IsDisabledControlJustPressed(0, 173) then SendNUIMessage({ action = 'CONTEXT_CONTROL', key = 'ArrowDown' }) end
            if IsDisabledControlJustPressed(0, 174) then SendNUIMessage({ action = 'CONTEXT_CONTROL', key = 'ArrowLeft' }) end
            if IsDisabledControlJustPressed(0, 175) then SendNUIMessage({ action = 'CONTEXT_CONTROL', key = 'ArrowRight' }) end
            
            if IsDisabledControlJustPressed(0, 176) or IsDisabledControlJustPressed(0, 18) then
                SendNUIMessage({ action = 'CONTEXT_CONTROL', key = 'Enter' })
            end
            
            if IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 194) or IsDisabledControlJustPressed(0, 200) then
                SendNUIMessage({ action = 'CONTEXT_CONTROL', key = 'Backspace' })
            end
        end
        keyboardThreadActive = false
    end)
end

-- ==========================================
-- CORE REGISTRATION
-- ==========================================
Interface.RegisterContext = function(data)
    if not data or type(data) ~= 'table' or not data.id then 
        print("^1[Lib47] RegisterContext failed: Missing menu ID.^7")
        return 
    end
    registeredMenus[data.id] = data
end

Interface.RegisterMenu = function(data, cb)
    if not data or type(data) ~= 'table' or not data.id then return end
    
    data.isMenuType = true
    data.cb = cb 
    
    if data.options then
        for _, opt in ipairs(data.options) do
            if opt.defaultIndex then
                opt.defaultIndex = opt.defaultIndex - 1 
            end
        end
    end

    registeredMenus[data.id] = data
end

-- ==========================================
-- CORE DISPLAY LOGIC
-- ==========================================
Interface.ShowContext = function(id, keyOnly, navOpts)
    navOpts = navOpts or {}
    keyboardOnly = keyOnly
    
    local menuConfig = registeredMenus[id]
    if not menuConfig then 
        print("^1[Lib47] ShowMenu failed: Menu ID '" .. tostring(id) .. "' not found.^7")
        return 
    end

    contextState.invoked = GetInvokingResource()
    contextState.visible = true
    activeMenuId = id

    if keyboardOnly then
        SetNuiFocus(false, false)
        StartKeyboardThread(menuConfig.disableInput)
    else
        SetNuiFocus(true, true)
    end

    local config = keyboardOnly and Config.Defaults.MobileMenu or Config.Defaults.ContextMenu
    
    local title = menuConfig.title or config.title
    local position = menuConfig.position or (menuConfig.isMenuType and 'top-left' or config.position)
    local canClose = menuConfig.canClose
    if canClose == nil then canClose = config.canClose end

    local size = menuConfig.size or config.size
    local borders = menuConfig.borders or config.borders
    local colors = menuConfig.colors or config.colors

    local nuiData = {
        id = menuConfig.id,
        isMenuType = menuConfig.isMenuType,
        title = title,
        position = position,
        size = size,
        borders = borders,
        colors = colors,
        menu = menuConfig.menu,
        canClose = canClose,
        focusIndex = navOpts.focusIndex, 
        keyboardOnly = keyboardOnly,
        options = SanitizeForNUI(menuConfig.options or {})
    }

    SendNUIMessage({
        action = 'OPEN_CONTEXT_MENU',
        data = nuiData
    })
end

Interface.HideContext = function(runOnExit, keyPressed)
    if runOnExit and activeMenuId then
        local menu = registeredMenus[activeMenuId]
        if menu then
            if menu.onExit then menu.onExit() end
            if menu.onClose then menu.onClose(keyPressed) end
        end
    end

    if not keyboardOnly then
        SetNuiFocus(false, false)
    end
    
    contextState.visible = false
    activeMenuId = nil
    menuHistoryStack = {}
    SendNUIMessage({ action = 'CLOSE_CONTEXT_MENU' })
end

-- ==========================================
-- MENU HELPERS
-- ==========================================
Interface.GetOpenMenu = function()
    return contextState.visible and activeMenuId or nil
end

Interface.SetMenuOptions = function(id, options, index)
    local menu = registeredMenus[id]
    if not menu then return end

    local jsIndex = index and (index - 1) or nil

    if type(options) == 'table' then
        if index then
            if options.defaultIndex then options.defaultIndex = options.defaultIndex - 1 end
            
            if not menu.options[index] then menu.options[index] = {} end
            for k, v in pairs(options) do
                menu.options[index][k] = v
            end
            
            options = menu.options[index]
        else
            for _, opt in ipairs(options) do
                if opt.defaultIndex then opt.defaultIndex = opt.defaultIndex - 1 end
            end
            menu.options = options
        end
    end

    if contextState.visible and activeMenuId == id then
        SendNUIMessage({
            action = 'UPDATE_MENU_OPTIONS',
            data = { index = jsIndex, options = SanitizeForNUI(options) }
        })
    end
end

-- ==========================================
-- NUI CALLBACKS
-- ==========================================
local function injectArgs(opt, args)
    local res = {}
    if args and type(args) == 'table' then
        for k, v in pairs(args) do 
            res[k] = v 
        end
    end
    
    if opt.values and #opt.values > 0 then res.isScroll = true end
    if opt.checked ~= nil then res.isCheck = true end
    
    return res
end

RegisterNUICallback('menuSelected', function(data, cb)
    if not activeMenuId then cb('ok'); return end
    local menu = registeredMenus[activeMenuId]
    if menu and menu.onSelected then
        local idx = data.index + 1
        local secondary = type(data.secondary) == 'number' and (data.secondary + 1) or data.secondary
        menu.onSelected(idx, secondary, injectArgs(menu.options[idx], data.args))
    end
    cb('ok')
end)

RegisterNUICallback('menuSideScroll', function(data, cb)
    if not activeMenuId then cb('ok'); return end
    local menu = registeredMenus[activeMenuId]
    if menu and menu.onSideScroll then
        local idx = data.index + 1
        if menu.options[idx] then menu.options[idx].defaultIndex = data.scrollIndex end
        menu.onSideScroll(idx, data.scrollIndex + 1, injectArgs(menu.options[idx], data.args))
    end
    cb('ok')
end)

RegisterNUICallback('menuCheck', function(data, cb)
    if not activeMenuId then cb('ok'); return end
    local menu = registeredMenus[activeMenuId]
    if menu and menu.onCheck then
        local idx = data.index + 1
        if menu.options[idx] then menu.options[idx].checked = data.checked end
        menu.onCheck(idx, data.checked, injectArgs(menu.options[idx], data.args))
    end
    cb('ok')
end)

RegisterNUICallback('contextAction', function(data, cb)
    if not activeMenuId then cb('ok'); return end
    local menu = registeredMenus[activeMenuId]
    if not menu then cb('ok'); return end

    local index = data.index + 1
    local option = menu.options[index]
    if not option then cb('ok'); return end

    local args = injectArgs(option, option.args)

    if option.onSelect then
        CreateThread(function()
            option.onSelect(args) 
        end)
    end
    
    if option.event then TriggerEvent(option.event, args) end
    if option.serverEvent then TriggerServerEvent(option.serverEvent, args) end

    if menu.cb then
        local scrollIdx = option.values and ((option.defaultIndex or 0) + 1) or nil
        menu.cb(index, scrollIdx, args)
    end

    if option.menu then
        table.insert(menuHistoryStack, { id = activeMenuId, index = data.index })
        Interface.ShowContext(option.menu, keyboardOnly, { isForward = true })
    elseif data.close ~= false and option.close ~= false then
        Interface.HideContext(false) 
    end

    cb('ok')
end)

RegisterNUICallback('contextExit', function(data, cb)
    Interface.HideContext(true, data.key)
    cb('ok')
end)

RegisterNUICallback('contextBack', function(data, cb)
    if activeMenuId then
        local menu = registeredMenus[activeMenuId]
        if menu then
            if menu.onBack then menu.onBack() end
            if menu.onClose then menu.onClose(data.key) end
            
            if menu.menu then
                local prevHistory = table.remove(menuHistoryStack)
                local focusIndex = prevHistory and (prevHistory.id == menu.menu and prevHistory.index or nil) or nil
                if not focusIndex then menuHistoryStack = {} end
                Interface.ShowContext(menu.menu, keyboardOnly, { focusIndex = focusIndex })
            else
                Interface.HideContext(true, data.key)
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

Interface.ShowMenu = function(id)
    Interface.ShowContext(id, true)
end

Interface.HideMenu = function(onExit)
    Interface.HideContext(onExit)
end

exports('RegisterContext', Interface.RegisterContext)
exports('RegisterMenu', Interface.RegisterMenu)
exports('ShowContext', Interface.ShowContext)
exports('ShowMenu', Interface.ShowMenu)
exports('HideContext', Interface.HideContext)
exports('HideMenu', Interface.HideMenu)
exports('GetOpenMenu', Interface.GetOpenMenu)
exports('SetMenuOptions', Interface.SetMenuOptions)


--================== Example ====================

--[[
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

--==============================================

-- Register the comprehensive menu
Lib47.RegisterMenu({
    id = 'comprehensive_test_menu',
    title = 'All Features Showcase',
    position = 'top-left',    -- 'top-left', 'top-right', 'bottom-left', 'bottom-right'
    disableInput = false,     -- Set to true to freeze player movement completely
    canClose = true,          -- Set to false to force the user to make a selection
    
    -- Triggers when the user presses ESC/Backspace to close the menu
    onClose = function(keyPressed)
        print(('Menu closed! Key pressed: %s'):format(keyPressed or 'N/A'))
    end,
    
    -- Triggers every time the user moves their selection up/down the list
    onSelected = function(selected, secondary, args)
        print(('Hovered Item: %s | Secondary Value: %s | Args: %s'):format(selected, tostring(secondary), json.encode(args)))
    end,
    
    -- Triggers instantly when the user presses Left/Right on a side-scroll option
    onSideScroll = function(selected, scrollIndex, args)
        print(('Scrolled Item: %s | New Scroll Index: %s'):format(selected, scrollIndex))
    end,
    
    -- Triggers instantly when the user presses Enter on a Checkbox option
    onCheck = function(selected, checked, args)
        print(('Toggled Checkbox: %s | Is Checked: %s'):format(selected, tostring(checked)))
    end,

    -- The actual menu items
    options = {
        -- 1. Standard Button
        {
            label = 'Basic Button',
            description = 'A standard button with a bottom tooltip description.'
        },
        
        -- 2. Button with Custom Icon Styling
        {
            label = 'Styled Icon',
            description = 'Using FontAwesome with custom color and spin animation.',
            icon = 'gear',
            iconColor = '#3498db',
            iconAnimation = 'spin'
        },
        
        -- 3. Checkbox Button
        {
            label = 'Toggle Godmode',
            description = 'Press Enter to toggle this checkbox.',
            icon = 'shield-halved',
            checked = false, 
            args = { setting = 'godmode' }
        },
        
        -- 4. Simple String Scroll List
        {
            label = 'Select Weapon',
            icon = 'gun',
            values = {'Pistol', 'SMG', 'Rifle', 'Shotgun'},
            defaultIndex = 3, -- Starts on 'Rifle' (Lua uses 1-based indexing, the code auto-converts it to JS 0-based!)
            args = { category = 'weapons' }
        },
        
        -- 5. Object Scroll List (Dynamic Descriptions per item)
        {
            label = 'Graphics Quality',
            icon = 'desktop',
            values = {
                { label = 'Low', description = 'Optimized for potato PCs.' },
                { label = 'Medium', description = 'Balanced performance and visuals.' },
                { label = 'Ultra', description = 'Maximum visual fidelity.' }
            },
            defaultIndex = 2
        },
        
        -- 6. Progress Bar Option (Read Only)
        {
            label = 'Server Load',
            description = 'Displays current server capacity.',
            icon = 'server',
            progress = 85,
            colorScheme = '#e74c3c', -- Red color for high load
            readOnly = true -- Prevents hovering/clicking
        },
        
        -- 7. Persistent Button (Does NOT close the menu)
        {
            label = 'Give $1000 (Keep Open)',
            description = 'Clicking this fires the callback but keeps the menu open.',
            icon = 'sack-dollar',
            iconColor = '#2ecc71',
            close = false, 
            args = { action = 'give_money' }
        },

        -- 8. Metadata Side Panel (Combines your old UI feature seamlessly)
        {
            label = 'View Player Stats',
            description = 'Hover to see the detailed side metadata panel.',
            icon = 'user',
            image = 'https://docs.fivem.net/vehicles/t20.webp', -- Image at top of side panel
            metadata = {
                { label = 'Name', value = 'John Doe' },
                { label = 'Job', value = 'LSPD' },
                { label = 'Hunger', value = '45%', progress = 45, colorScheme = '#f1c40f' },
                { label = 'Thirst', value = '90%', progress = 90, colorScheme = '#3498db' }
            }
        },
        
        -- 9. Disabled Button
        {
            label = 'Admin Actions',
            description = 'You do not have permission to use this.',
            icon = 'lock',
            disabled = true
        }
    }
}, function(selected, scrollIndex, args)
    -- Main Callback when a user PRESSES ENTER on a valid item
    print('--- MENU ITEM SELECTED ---')
    print('Selected Item Index:', selected)
    
    if scrollIndex then
        print('Scroll Index Chosen:', scrollIndex)
    end
    
    if args then
        print('Arguments:', json.encode(args))
        
        -- Example interaction
        if args.action == 'give_money' then
            print("Action triggered: Gave player money without closing the menu!")
        end
    end
end)

-- Command to open the menu
RegisterCommand('testnewmenu', function()
    -- ShowMenu implicitly sets keyboard-navigation to true, matching typical ox_lib behavior
    Lib47.ShowMenu('comprehensive_test_menu')
end)

Lib47.RegisterMenu({
    id = 'some_menu_id',
    title = 'Menu title',
    position = 'top-right',
    onSideScroll = function(selected, scrollIndex, args)
        print("Scroll: ", selected, scrollIndex, args)
    end,
    onSelected = function(selected, secondary, args)
        if not secondary then
            print("Normal button")
        else
            if args.isCheck then
                print("Check button")
            end
 
            if args.isScroll then
                print("Scroll button")
            end
        end
        print(selected, secondary, json.encode(args, {indent=true}))
    end,
    onCheck = function(selected, checked, args)
        print("Check: ", selected, checked, args)
    end,
    onClose = function(keyPressed)
        print('Menu closed')
        if keyPressed then
            print(('Pressed %s to close the menu'):format(keyPressed))
        end
    end,
    options = {
        {label = 'Simple button', description = 'It has a description!'},
        {label = 'Checkbox button', checked = true},
        {label = 'Scroll button with icon', icon = 'arrows-up-down-left-right', values={'hello', 'there'}},
        {label = 'Button with args', args = {someArg = 'nice_button'}},
        {label = 'List button', values = {'You', 'can', 'side', 'scroll', 'this'}, description = 'It also has a description!'},
        {label = 'List button with default index', values = {'You', 'can', 'side', 'scroll', 'this'}, defaultIndex = 5},
        {label = 'List button with args', values = {'You', 'can', 'side', 'scroll', 'this'}, args = {someValue = 3, otherValue = 'value'}},
    }
}, function(selected, scrollIndex, args)
    print(selected, scrollIndex, args)
end)
 
RegisterCommand('testoxmenu', function()
    Lib47.ShowMenu('some_menu_id')
end)

]]