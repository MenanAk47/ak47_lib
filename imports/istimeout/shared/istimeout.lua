Lib47.IsTimeOut = function(timeout)
    local startTime = GetGameTimer()
    
    return function()
        return (GetGameTimer() - startTime) > timeout
    end
end