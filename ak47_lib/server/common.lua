Lib47.Notify = function(source, msg, type, duration)
    TriggerClientEvent('ak47_lib:client:Notify', source, msg, type, duration)
end

Lib47.IsItemTypeWeapon = function(name)
    if not name then return false end
    return name:lower():find('weapon_')
end

Lib47.Callback.Register('ak47_lib:callback:server:GetTargetMetaValue', function( source, target, type )
    return Lib47.GetPlayerMetaValue(target, type)
end)

exports('GetLibObject', function()
    return Lib47
end)

-- backward compatibility with ak47_bridge

local function oldExport(exportName, func)
    AddEventHandler(('__cfx_export_ak47_bridge_%s'):format(exportName), function(setCB)
        setCB(func)
    end)
end

oldExport('GetBridge', function() 
    return Lib47
end)