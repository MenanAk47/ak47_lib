-- ============== context ============

Lib47.RegisterContext = function(data)
    if Config.ContextMenu == 'default' then
        Interface.RegisterContext(data)
    elseif Config.ContextMenu == 'ox' then
        exports['ox_lib']:registerContext(data)
    elseif Config.ContextMenu == 'custom' then
        -- your custom code below

    end
end

Lib47.ShowContext = function(id, keyboardOnly, navOpts)
    if Config.ContextMenu == 'default' then
        Interface.ShowContext(id, keyboardOnly, navOpts)
    elseif Config.ContextMenu == 'ox' then
        exports['ox_lib']:showContext(id)
    elseif Config.ContextMenu == 'custom' then
        -- your custom code below

    end
end

Lib47.HideContext = function(onExit, keyPressed, suspend)
    if Config.ContextMenu == 'default' then
        Interface.HideContext(onExit, keyPressed, suspend)
    elseif Config.ContextMenu == 'ox' then
        exports['ox_lib']:hideContext(onExit)
    elseif Config.ContextMenu == 'custom' then
        -- your custom code below

    end
end

-- ============== menu ============

Lib47.RegisterMenu = function(data, cb)
    if Config.MobileMenu == 'default' then
        Interface.RegisterMenu(data, cb)
    elseif Config.MobileMenu == 'ox' then
        exports['ox_lib']:registerMenu(data, cb)
    elseif Config.MobileMenu == 'custom' then
        -- your custom code below

    end
end

Lib47.ShowMenu = function(id)
    if Config.MobileMenu == 'default' then
        Interface.ShowMenu(id)
    elseif Config.MobileMenu == 'ox' then
        exports['ox_lib']:showMenu(id)
    elseif Config.MobileMenu == 'custom' then
        -- your custom code below

    end
end

Lib47.HideMenu = function(onExit)
    if Config.MobileMenu == 'default' then
        Interface.HideMenu(onExit)
    elseif Config.MobileMenu == 'ox' then
        exports['ox_lib']:hideMenu(onExit)
    elseif Config.MobileMenu == 'custom' then
        -- your custom code below

    end
end

Lib47.GetOpenMenu = function()
    if Config.MobileMenu == 'default' or Config.ContextMenu == 'default' then
        return Interface.GetOpenMenu()
    elseif Config.MobileMenu == 'ox' or Config.ContextMenu == 'ox' then
        return exports['ox_lib']:getOpenMenu()
    elseif Config.MobileMenu == 'custom' or Config.ContextMenu == 'custom' then
        -- your custom code below

    end
end

Lib47.SetMenuOptions = function(id, options, index)
    if Config.MobileMenu == 'default' or Config.ContextMenu == 'default' then
        return Interface.SetMenuOptions(id, options, index)
    elseif Config.MobileMenu == 'ox' or Config.ContextMenu == 'ox' then
        return exports['ox_lib']:setMenuOptions(id, options, index)
    elseif Config.MobileMenu == 'custom' or Config.ContextMenu == 'custom' then
        -- your custom code below

    end
end

exports('RegisterContext', Lib47.RegisterContext)
exports('ShowContext', Lib47.ShowContext)
exports('HideContext', Lib47.HideContext)
exports('RegisterMenu', Lib47.RegisterMenu)
exports('ShowMenu', Lib47.ShowMenu)
exports('HideMenu', Lib47.HideMenu)
exports('GetOpenMenu', Lib47.GetOpenMenu)
exports('SetMenuOptions', Lib47.SetMenuOptions)
