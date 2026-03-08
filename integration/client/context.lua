Lib47.RegisterContext = function(data)
    if Config.ContextMenu == 'default' then
        Interface.RegisterContext(data)
    elseif Config.ContextMenu == 'ox' then
        lib.registerContext(data)
    elseif Config.ContextMenu == 'custom' then
        -- your custom code below

    end
end

Lib47.ShowContext = function(id, keyboardOnly)
    if Config.ContextMenu == 'default' then
        Interface.ShowContext(id, keyboardOnly)
    elseif Config.ContextMenu == 'ox' then
        lib.showContext(id)
    elseif Config.ContextMenu == 'custom' then
        -- your custom code below

    end
end

Lib47.HideContext = function(onExit)
    if Config.ContextMenu == 'default' then
        Interface.HideContext(onExit)
    elseif Config.ContextMenu == 'ox' then
        lib.hideContext(onExit)
    elseif Config.ContextMenu == 'custom' then
        -- your custom code below

    end
end
