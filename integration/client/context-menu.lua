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

Lib47.ShowContext = function(id, keyboardOnly)
    if Config.ContextMenu == 'default' then
        Interface.ShowContext(id, keyboardOnly)
    elseif Config.ContextMenu == 'ox' then
        exports['ox_lib']:showContext(id)
    elseif Config.ContextMenu == 'custom' then
        -- your custom code below

    end
end

Lib47.HideContext = function(onExit)
    if Config.ContextMenu == 'default' then
        Interface.HideContext(onExit)
    elseif Config.ContextMenu == 'ox' then
        exports['ox_lib']:hideContext(onExit)
    elseif Config.ContextMenu == 'custom' then
        -- your custom code below

    end
end

-- ============== menu ============

Lib47.RegisterMenu = function(data)
    if Config.MobileMenu == 'default' then
        Interface.RegisterMenu(data)
    elseif Config.MobileMenu == 'ox' then
        exports['ox_lib']:registerMenu(data)
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

