function Callback.Register(name, cb)
    if registeredCallbacks[name] then 
        return print(("^1[ak47_lib] Duplicate Client Callback: %s^7"):format(name)) 
    end
    registeredCallbacks[name] = true

    RegisterNetEvent(getCallbackEvent(name), function(requestId, ...)
        local results = { pcall(cb, ...) }
        
        if not results[1] then
            callbackResponse(table.unpack(results))
            return TriggerServerEvent(getCallbackEvent(requestId), nil)
        end

        table.remove(results, 1)
        TriggerServerEvent(getCallbackEvent(requestId), table.unpack(results))
    end)
end

function Callback.Await(name, _, ...)
    local p = promise.new()
    requestCount = requestCount + 1
    local requestId = ('req_%s_%s'):format(name, requestCount)
    local eventName = getCallbackEvent(requestId)

    local handler = RegisterNetEvent(eventName, function(...)
        if p.state == 0 then 
            p:resolve({...}) 
        end
    end)

    TriggerServerEvent(getCallbackEvent(name), requestId, ...)

    local timeout = Config.Defaults.CallbackTimeout * 1000 
    local startTime = GetGameTimer()

    while p.state == 0 and (GetGameTimer() - startTime) < timeout do
        Citizen.Wait(0)
    end

    if p.state == 0 then
        p:resolve(nil)
        print(("^1[ak47_lib] Callback '%s' timed out after 15s. Server failed to respond.^7"):format(name))
    end

    local result = Citizen.Await(p)
    RemoveEventHandler(handler)
    return result and table.unpack(result) or nil
end

Lib47.Callback = Callback