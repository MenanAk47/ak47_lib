Lib47.RequestAnimDict = function( dict, timeout )
    if not dict then error(("No anim dict provided by %s"):format(GetInvokingResource())) end
    if not timeout or type(timeout) ~= 'number' then timeout = 30 * 1000 end
    
    if HasAnimDictLoaded(dict) then return dict end
    RequestAnimDict(dict)

    local isTimerFinished = Lib47.IsTimeOut(timeout)
    while not HasAnimDictLoaded(dict) and not isTimerFinished() do Wait(10) end
    if not HasAnimDictLoaded(dict) then error(("Anim dict request timed out: %s"):format(dict)) end
    return dict
end

Lib47.PlayAnim = function(animDict, animName, upperbodyOnly, duration)
    local animPromise = promise.new()
    local flags = upperbodyOnly and 16 or 0
    local runTime = duration or -1
    if runTime == -1 then flags = 49 end
    local ped = PlayerPedId()
    Lib47.RequestAnimDict(animDict)
    TaskPlayAnim(ped, animDict, animName, 8.0, 8.0, runTime, flags, 0, true, true, true)
    local fullDuration = GetAnimDuration(animDict, animName) * 1000
    local waitTime = duration and math.min(duration, fullDuration) or fullDuration
    Wait(waitTime)
    RemoveAnimDict(animDict)
    animPromise:resolve(GetAnimDuration(animDict, animName))
    return animPromise.value
end

Lib47.RequestAnimSet = function(animSet)
    if HasAnimSetLoaded(animSet) then return end
    RequestAnimSet(animSet)
    while not HasAnimSetLoaded(animSet) do Wait(0) end
end