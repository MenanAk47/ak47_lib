Lib47.ShowAlert = function(data)
    if Config.AlertDialog == 'default' then
        return Interface.ShowAlert(data)
    elseif Config.AlertDialog == 'ox' then
        return lib.alertDialog(data)
    elseif Config.AlertDialog == 'custom' then
        -- your custom code below

    end
end

Lib47.HideAlert = function()
    if Config.AlertDialog == 'default' then
        Interface.HideAlert()
    elseif Config.AlertDialog == 'ox' then
        lib.closeAlertDialog()
    elseif Config.AlertDialog == 'custom' then
        -- your custom code below

    end
end