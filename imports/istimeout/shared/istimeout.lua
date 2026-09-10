Lib47.IsTimeOut = function(timeout)
    local startTime = GetGameTimer()
    if not timeout or type(timeout) ~= 'number' then
        timeout = 30 * 1000
    end
    return function()
        return (GetGameTimer() - startTime) > timeout
    end
end

Lib47.WaitUntil = function(condition, timeout, interval)
    if type(condition) ~= "function" then
        return false, nil
    end

    timeout = (type(timeout) == "number" and timeout > 0) and timeout or 10000
    interval = (type(interval) == "number" and interval >= 0) and interval or 1000

    local startTime = GetGameTimer()
    
    while (GetGameTimer() - startTime) < timeout do
        local success, result = pcall(condition)

        if not success then
            return false, nil
        end

        if result then
            return true, result
        end

        Wait(interval)
    end

    return false, nil
end