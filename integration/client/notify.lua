Bridge.Notify = function(msg, type, duration)
    if Config.Notify == 'default' then
        Interface.Notify({
            type = type,
            description = msg,
            duration = duration,
        })
    elseif Config.Notify == 'ox' then
        exports['ox_lib']:notify({
            type = type or 'info',
            description = msg,
            position = 'top',
        })
    elseif Config.Notify == 'esx' and Config.Framework == 'esx' then
        ESX.ShowNotification(msg, type, duration)
    elseif Config.Notify == 'qb' and Config.Framework == 'qb' then
        QBCore.Functions.Notify(msg, type, duration)
    elseif Config.Notify == 'qbx' and Config.Framework == 'qbx' then
        exports.qbx_core:Notify(msg, type, duration)
    elseif Config.Notify == 'custom' then
        -- your custom code below

    end
end

-- Don't change below
RegisterNetEvent('ak47_bridge:client:Notify', Bridge.Notify)