function Callback.Register(name, cb)
    if registeredCallbacks[name] then 
        return print(("^1[ak47_lib] Duplicate Server Callback: %s^7"):format(name)) 
    end
    registeredCallbacks[name] = true

    RegisterNetEvent(getCallbackEvent(name), function(requestId, ...)
        local src = source
        local results = { pcall(cb, src, ...) }
        
        if not results[1] then
            callbackResponse(table.unpack(results))
            return TriggerClientEvent(getCallbackEvent(requestId), src, nil)
        end

        table.remove(results, 1)
        TriggerClientEvent(getCallbackEvent(requestId), src, table.unpack(results))
    end)
end

function Callback.Await(name, target, ...)
    if not GetPlayerName(target) then return nil end

    local p = promise.new()
    requestCount = requestCount + 1
    local requestId = ('req_%s_%s'):format(name, requestCount)
    local eventName = getCallbackEvent(requestId)

    local handler = RegisterNetEvent(eventName, function(...)
        if p.state == 0 then
            p:resolve({...})
        end
    end)

    TriggerClientEvent(getCallbackEvent(name), target, requestId, ...)

    local timeout = Config.Defaults.CallbackTimeout * 1000
    local startTime = GetGameTimer()

    while p.state == 0 and (GetGameTimer() - startTime) < timeout do
        Citizen.Wait(0)
    end

    if p.state == 0 then
        p:resolve(nil)
        print(("^1[ak47_lib] Callback '%s' timed out after 15s. Client failed to respond.^7"):format(name))
    end

    local result = Citizen.Await(p)
    RemoveEventHandler(handler)
    return result and table.unpack(result) or nil
end

Lib47.Callback = Callback