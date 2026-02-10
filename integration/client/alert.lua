Lib47.ShowAlert = function(heading, rows, options)
    if Config.AlertDialog == 'default' then
        return Interface.ShowInput(heading, rows, options)
    elseif Config.AlertDialog == 'ox' then
        return lib.AlertDialog(heading, rows, options)
    elseif Config.AlertDialog == 'custom' then
        -- your custom code below

    end
end

Lib47.HideAlert = function()
    if Config.AlertDialog == 'default' then
        Interface.HideInput()
    elseif Config.AlertDialog == 'ox' then
        lib.closeInputDialog()
    elseif Config.AlertDialog == 'custom' then
        -- your custom code below

    end
end