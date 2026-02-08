Lib47.GetTargetMetaValue = function(targetServerId, metaKey)
    return lib.callback.await('ak47_lib:callback:server:GetTargetMetaValue', nil, targetServerId, metaKey)
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
