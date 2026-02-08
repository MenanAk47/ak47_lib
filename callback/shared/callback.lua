registeredCallbacks = {}
requestCount = 0
cbEvent = '__ak47_cb_%s'

function getCallbackEvent(name) 
    return cbEvent:format(name) 
end

function callbackResponse(success, result, ...)
    if not success then
        if result then
            local trace = Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString()) or ''
            print(('\1^1[ak47_lib] SCRIPT ERROR: %s^0\n%s'):format(result, trace))
        end
        return false
    end
    return result, ...
end