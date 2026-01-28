Bridge.GetTargetMetaValue = function(targetServerId, metaKey)
    return lib.callback.await('ak47_bridge:callback:server:GetTargetMetaValue', nil, targetServerId, metaKey)
end

exports('GetBridge', function()
    return Bridge
end)