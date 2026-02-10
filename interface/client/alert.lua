local alertPromise = nil
local alertState = { visible = false, invoked = nil }

Interface.ShowAlert = function(data)
    if alertPromise then 
        return 'cancel' 
    end

    alertState.invoked = GetInvokingResource()
    alertState.visible = true

    data = data or {}

    if data.colors == nil then 
        data.colors = Config.Defaults.AlertDialog.colors 
    end

    if data.borders == nil then 
        data.borders = Config.Defaults.AlertDialog.borders 
    end

    if data.size == nil then 
        data.size = Config.Defaults.AlertDialog.size 
    end
    
    SetNuiFocus(true, true)

    alertPromise = promise.new()

    SendNUIMessage({
        action = 'OPEN_ALERT_DIALOG',
        data = data
    })

    local result = Citizen.Await(alertPromise)

    SetNuiFocus(false, false)
    alertPromise = nil

    alertState.visible = false
    alertState.invoked = nil

    return result or 'cancel'
end

Interface.HideAlert = function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'CLOSE_ALERT_DIALOG' })
    if alertPromise then alertPromise:resolve('cancel') end
end

RegisterNUICallback('alertConfirm', function(_, cb)
    if alertPromise then 
        alertPromise:resolve('confirm') 
    end
    cb('ok')
end)

RegisterNUICallback('alertCancel', function(_, cb)
    if alertPromise then 
        alertPromise:resolve('cancel') 
    end
    cb('ok')
end)

exports('ShowAlert', Interface.ShowAlert)
exports('HideAlert', Interface.HideAlert)

AddEventHandler('onResourceStop', function(resourceName)
    if alertState.visible and alertState.invoked == resourceName then
        Interface.HideAlert()
    end
end)

--[[
RegisterCommand('testalert', function()
    local alert = Interface.ShowAlert({
        header = 'System Warning',
        content = 'This is a standalone alert.\nIt uses **independent CSS** and supports [Markdown](https://google.com)',
        centered = true,
        cancel = true,
        size = 'sm',
        colors = {
            colorPrimary = '#1F1F1F', -- Flat dark grey
            colorSecondary = '#FF5555', -- Red accent
            colorText = '#FFFFFF'
        },
        borders = {'bottom'},
        labels = { confirm = 'Understood', cancel = 'Ignore' }
    })
    print('Alert Result:', alert)
end)
]]