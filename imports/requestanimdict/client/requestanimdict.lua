Lib47.RequestAnimDict = function( dict, timeout )
    if not dict then 
        error(("No anim dict provided by %s"):format(GetInvokingResource()))
    end

    if HasAnimDictLoaded(dict) then 
        return dict 
    end

    timeout = timeout or 30 * 1000

    RequestAnimDict(dict)

    local isTimerFinished = Lib47.IsTimeOut(timeout)

    while not HasAnimDictLoaded(dict) and not isTimerFinished() do 
        Wait(10) 
    end

    if not HasAnimDictLoaded(dict) then
        error(("Anim dict request timed out: %s"):format(dict))
    end

    return dict
end

