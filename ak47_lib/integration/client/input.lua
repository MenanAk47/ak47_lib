Lib47.ShowInput = function(title, data)
    if Config.InputDialog == 'default' then
        return Interface.ShowInput(title, data)
    elseif Config.InputDialog == 'ox' then
        return lib.inputDialog(title, data)
    elseif Config.InputDialog == 'custom' then
        -- your custom code below

    end
end

Lib47.HideInput = function(data)
    if Config.InputDialog == 'default' then
        Interface.HideInput()
    elseif Config.InputDialog == 'ox' then
        lib.closeInputDialog()
    elseif Config.InputDialog == 'custom' then
        -- your custom code below

    end
end