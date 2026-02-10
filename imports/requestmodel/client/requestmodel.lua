Lib47.RequestModel = function( model, timeout )
    if not model then 
        error(("No model provided by %s"):format(GetInvokingResource()))
        return false 
    end

    model = type(model) == 'number' and model or joaat(model)
    timeout = timeout or 30 * 1000

    if HasModelLoaded(model) then 
        return model 
    end

    if not IsModelValid(model) and not IsModelInCdimage(model) then
        error(("Invalid model: %s"):format(model))
    end

    RequestModel(model)

    local isTimerFinished = Lib47.IsTimeOut(timeout)

    while not HasModelLoaded(model) and not isTimerFinished() do 
        Wait(10) 
    end

    if not HasModelLoaded(model) then
        error(("Model request timed out: %s"):format(model))
    end

    return model
end

