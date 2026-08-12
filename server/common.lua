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

Lib47.HasPermission = function(source, Admin, notify)
    local function grantPermission(method)
        if notify then
            local invokedResource = GetInvokingResource() or "Unknown"
            print(string.format("^7[^5%s^7] [^3%s^7]^0 ^2Permission Granted via %s^0", invokedResource, source, method))
        end
        return true
    end

    if Admin.WithAce and Lib47.IsAdmin(source) then
        return grantPermission("Ace")
    end

    if Admin.WithLicense and Admin.WithLicense[GetPlayerIdentifierByType(source, 'license')] then
        return grantPermission("License")
    end

    if Admin.WithIdentifier and Admin.WithIdentifier[Lib47.GetIdentifier(source)] then
        return grantPermission("Identifier")
    end

    if Admin.WithGroup then
        for group, enabled in pairs(Admin.WithGroup) do
            if enabled and Lib47.HasGroupPermission(source, group) then
                return grantPermission("Group")
            end
        end
    end

    return false
end

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