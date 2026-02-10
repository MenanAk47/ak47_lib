Lib47.ShowInput = function(heading, rows, options)
    if Config.InputDialog == 'default' then
        return Interface.ShowInput(heading, rows, options)
    elseif Config.InputDialog == 'ox' then
        return lib.inputDialog(heading, rows, options)
    elseif Config.InputDialog == 'custom' then
        -- your custom code below

    end
end

Lib47.HideInput = function()
    if Config.InputDialog == 'default' then
        Interface.HideInput()
    elseif Config.InputDialog == 'ox' then
        lib.closeInputDialog()
    elseif Config.InputDialog == 'custom' then
        -- your custom code below

    end
end